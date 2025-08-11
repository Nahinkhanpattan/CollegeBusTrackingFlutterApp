import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/services/location_service.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/widgets/custom_button.dart';
import 'package:collegebus/utils/constants.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LatLng? _currentLocation;
  BusModel? _myBus;
  bool _isSharing = false;

  List<RouteModel> _routes = [];
  RouteModel? _selectedRoute;
  List<String> _busNumbers = [];
  String? _selectedBusNumber;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
    _loadRoutes();
    _loadBusNumbers();
    _loadMyBus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final location = await locationService.getCurrentLocation();
    if (location != null) {
      setState(() {
        _currentLocation = location;
      });
    }
  }

  Future<void> _loadBusNumbers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;
    if (collegeId != null) {
      firestoreService.getBusNumbers(collegeId).listen((busNumbers) {
        setState(() {
          _busNumbers = busNumbers;
        });
      });
    }
  }

  Future<void> _loadRoutes() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final currentUser = authService.currentUserModel;
    if (currentUser != null) {
      firestoreService.getRoutesByCollege(currentUser.collegeId).listen((routes) {
        setState(() {
          _routes = routes;
        });
      });
    }
  }

  Future<void> _loadMyBus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    final currentUser = authService.currentUserModel;
    if (currentUser != null) {
      final bus = await firestoreService.getBusByDriver(currentUser.id);
      if (bus != null) {
        setState(() {
          _myBus = bus;
          _selectedBusNumber = bus.busNumber;
          _selectedRoute = _routes.firstWhere(
            (r) => r.id == bus.routeId,
            orElse: () => RouteModel(
              id: '',
              routeName: 'N/A',
              routeType: '',
              startPoint: 'N/A',
              endPoint: 'N/A',
              stopPoints: [],
              collegeId: '',
              createdBy: '',
              isActive: false,
              createdAt: DateTime.now(),
            ),
          );
        });
      }
    }
  }

  Future<void> _toggleLocationSharing() async {
    if (_myBus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set up your bus information first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final locationService = Provider.of<LocationService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    if (_isSharing) {
      // Stop sharing location
      locationService.stopLocationTracking();
      setState(() => _isSharing = false);
    } else {
      // Start sharing location
      await locationService.startLocationTracking(
        onLocationUpdate: (location) async {
          final busLocation = BusLocationModel(
            busId: _myBus!.id,
            currentLocation: location,
            timestamp: DateTime.now(),
          );
          
          await firestoreService.updateBusLocation(_myBus!.id, busLocation);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location shared successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      );
      setState(() => _isSharing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Welcome, ${user?.fullName ?? 'Driver'}'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Notifications will be implemented in future updates
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.onPrimary,
          unselectedLabelColor: AppColors.onPrimary.withValues(alpha: 0.7),
          indicatorColor: AppColors.onPrimary,
          tabs: const [
            Tab(text: 'Bus Setup', icon: Icon(Icons.settings)),
            Tab(text: 'Live Tracking', icon: Icon(Icons.map)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Bus Setup Tab
          Column(
            children: [
              // Location display - Always show this
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                color: _currentLocation != null 
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on, 
                      color: _currentLocation != null ? AppColors.primary : AppColors.warning
                    ),
                    const SizedBox(width: AppSizes.paddingSmall),
                    Expanded(
                      child: Text(
                        _currentLocation != null
                            ? 'Your Location: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}'
                            : 'Location not available. Please enable location services.',
                        style: TextStyle(
                          color: _currentLocation != null ? AppColors.primary : AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bus & Route Selection',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingLarge),
                      if (_myBus == null) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedBusNumber,
                          items: _busNumbers.map((busNumber) => DropdownMenuItem(
                            value: busNumber,
                            child: Text(busNumber),
                          )).toList(),
                          onChanged: (busNumber) {
                            setState(() {
                              _selectedBusNumber = busNumber;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Select Bus Number',
                            border: OutlineInputBorder(),
                            hintText: 'Choose your bus number',
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        DropdownButtonFormField<RouteModel>(
                          value: _selectedRoute,
                          items: _routes.map((route) => DropdownMenuItem(
                            value: route,
                            child: Text('${route.routeName} (${route.routeType.toUpperCase()})'),
                          )).toList(),
                          onChanged: (route) {
                            setState(() {
                              _selectedRoute = route;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Select Route',
                            border: OutlineInputBorder(),
                            hintText: 'Choose your route',
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingLarge),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (_selectedRoute != null && _selectedBusNumber != null)
                                ? () async {
                                    final authService = Provider.of<AuthService>(context, listen: false);
                                    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                                    final currentUser = authService.currentUserModel;
                                    if (currentUser == null) return;
                                    
                                    final newBus = BusModel(
                                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                                      busNumber: _selectedBusNumber!,
                                      driverId: currentUser.id,
                                      routeId: _selectedRoute!.id,
                                      collegeId: currentUser.collegeId,
                                      createdAt: DateTime.now(),
                                    );
                                    
                                    await firestoreService.createBus(newBus);
                                    if (!mounted) return;
                                    setState(() => _myBus = newBus);
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Bus assigned successfully!'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.directions_bus),
                            label: const Text('Assign Bus'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ] else ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.paddingMedium),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bus: ${_myBus!.busNumber}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: AppSizes.paddingSmall),
                                if (_selectedRoute != null) ...[
                                  Text(
                                    'Route: ${_selectedRoute!.routeName}',
                                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    'Type: ${_selectedRoute!.routeType.toUpperCase()}',
                                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    '${_selectedRoute!.startPoint} → ${_selectedRoute!.endPoint}',
                                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                  ),
                                ],
                                const SizedBox(height: AppSizes.paddingMedium),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                                      await firestoreService.deleteBus(_myBus!.id);
                                      if (!mounted) return;
                                      setState(() => _myBus = null);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Bus assignment removed'),
                                          backgroundColor: AppColors.warning,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.remove_circle),
                                    label: const Text('Remove Assignment'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      foregroundColor: AppColors.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Live Tracking Tab
          Column(
            children: [
              // Map
              Expanded(
                child: _currentLocation != null
                    ? GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          // _mapController = controller; // This line was removed
                        },
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation!,
                          zoom: 16.0,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        markers: {
                          if (_currentLocation != null)
                            Marker(
                              markerId: const MarkerId('current_location'),
                              position: _currentLocation!,
                              infoWindow: const InfoWindow(title: 'Bus Location'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                            ),
                        },
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
              
              // Controls
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.radiusLarge),
                    topRight: Radius.circular(AppSizes.radiusLarge),
                  ),
                ),
                child: Column(
                  children: [
                    // Location info
                    if (_currentLocation != null)
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingMedium),
                        margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primary),
                            const SizedBox(width: AppSizes.paddingSmall),
                            Expanded(
                              child: Text(
                                'Your Location: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    if (_myBus != null) ...[
                      Text(
                        'Bus ${_myBus!.busNumber}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      if (_selectedRoute != null) ...[
                        Text(
                          'Route: ${_selectedRoute!.routeName}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Type: ${_selectedRoute!.routeType.toUpperCase()} | ${_selectedRoute!.startPoint} → ${_selectedRoute!.endPoint}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSizes.paddingMedium),
                    ],
                    
                    CustomButton(
                      text: _isSharing ? 'Stop Sharing Location' : 'Start Sharing Location',
                      onPressed: _toggleLocationSharing,
                      backgroundColor: _isSharing ? AppColors.error : AppColors.success,
                      icon: Icon(
                        _isSharing ? Icons.stop : Icons.play_arrow,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    
                    if (_isSharing) ...[
                      const SizedBox(height: AppSizes.paddingMedium),
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingMedium),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.success,
                            ),
                            SizedBox(width: AppSizes.paddingMedium),
                            Expanded(
                              child: Text(
                                'Your location is being shared with students and teachers',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}