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
import 'package:collegebus/widgets/custom_input_field.dart';
import 'package:collegebus/utils/constants.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  BusModel? _myBus;
  bool _isSharing = false;

  // Bus setup form controllers
  final _busNumberController = TextEditingController();
  final _startPointController = TextEditingController();
  final _endPointController = TextEditingController();
  List<TextEditingController> _stopControllers = [];

  List<RouteModel> _routes = [];
  RouteModel? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
    _loadRoutes();
    _loadMyBus();
    _addStopController(); // Add initial stop controller
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busNumberController.dispose();
    _startPointController.dispose();
    _endPointController.dispose();
    for (var controller in _stopControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  void _addStopController() {
    setState(() {
      _stopControllers.add(TextEditingController());
    });
  }
  
  void _removeStopController(int index) {
    if (_stopControllers.length > 1) {
      setState(() {
        _stopControllers[index].dispose();
        _stopControllers.removeAt(index);
      });
    }
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
        RouteModel? route;
        if (bus.routeId != null) {
          route = _routes.firstWhere(
            (r) => r.id == bus.routeId,
            orElse: () => RouteModel(
              id: '',
              routeName: 'N/A',
              routeType: '',
              startPoint: '',
              endPoint: '',
              stopPoints: [],
              collegeId: '',
              createdBy: '',
              isActive: false,
              createdAt: DateTime.now(),
            ),
          );
        }
        setState(() {
          _myBus = bus;
          _busNumberController.text = bus.busNumber;
          _selectedRoute = route;
          _startPointController.text = route?.startPoint ?? '';
          _endPointController.text = route?.endPoint ?? '';
          // Clear existing controllers
          for (var controller in _stopControllers) {
            controller.dispose();
          }
          _stopControllers.clear();
          // Add controllers for existing stops
          if (route != null) {
            for (int i = 0; i < route.stopPoints.length; i++) {
              _stopControllers.add(TextEditingController(text: route.stopPoints[i]));
            }
          }
          // Ensure at least one stop controller
          if (_stopControllers.isEmpty) {
            _addStopController();
          }
        });
      }
    }
  }

  Future<void> _saveBusInfo() async {
    if (_busNumberController.text.isEmpty || _selectedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter bus number and select a route'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    final currentUser = authService.currentUserModel;
    if (currentUser != null) {

      if (_myBus == null) {
        // Create new bus
        final newBus = BusModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          busNumber: _busNumberController.text.trim(),
          driverId: currentUser.id,
          routeId: _selectedRoute!.id,
          collegeId: currentUser.collegeId,
          createdAt: DateTime.now(),
        );

        await firestoreService.createBus(newBus);
        setState(() => _myBus = newBus);
      } else {
        // Update existing bus
        await firestoreService.updateBus(_myBus!.id, {
          'busNumber': _busNumberController.text.trim(),
          'routeId': _selectedRoute!.id,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bus information saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
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
              // TODO: Show notifications
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
          unselectedLabelColor: AppColors.onPrimary.withOpacity(0.7),
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
          Padding(
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
                  DropdownButtonFormField<RouteModel>(
                    value: _selectedRoute,
                    items: _routes.map((route) => DropdownMenuItem(
                      value: route,
                      child: Text(route.displayName),
                    )).toList(),
                    onChanged: (route) {
                      setState(() {
                        _selectedRoute = route;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Route',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),
                  CustomButton(
                    text: 'Assign Bus',
                    onPressed: () async {
                      if (_selectedRoute == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a route'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      final authService = Provider.of<AuthService>(context, listen: false);
                      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                      final currentUser = authService.currentUserModel;
                      if (currentUser == null) return;
                      final newBus = BusModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        busNumber: 'Bus for ${currentUser.fullName}',
                        driverId: currentUser.id,
                        routeId: _selectedRoute!.id,
                        collegeId: currentUser.collegeId,
                        createdAt: DateTime.now(),
                      );
                      await firestoreService.createBus(newBus);
                      setState(() => _myBus = newBus);
                    },
                    icon: const Icon(Icons.directions_bus),
                  ),
                ] else ...[
                  Text(
                    'Bus: ${_myBus!.busNumber}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  if (_selectedRoute != null) ...[
                    Text(
                      'Route: ${_selectedRoute!.displayName}',
                      style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${_selectedRoute!.startPoint} → ${_selectedRoute!.endPoint}',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ],
            ),
          ),
          
          // Live Tracking Tab
          Column(
            children: [
              // Map
              Expanded(
                child: _currentLocation != null
                    ? GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
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
                          'Route: ${_selectedRoute!.displayName}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${_selectedRoute!.startPoint} → ${_selectedRoute!.endPoint}',
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
                          color: AppColors.success.withOpacity(0.1),
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