import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

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
    _loadSavedSelections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserModel?.id;
    
    if (userId != null) {
      final savedBusNumber = prefs.getString('driver_${userId}_bus_number');
      final savedRouteId = prefs.getString('driver_${userId}_route_id');
      
      if (savedBusNumber != null) {
        setState(() => _selectedBusNumber = savedBusNumber);
      }
      
      if (savedRouteId != null) {
        final route = _routes.firstWhere(
          (r) => r.id == savedRouteId,
          orElse: () => RouteModel(
            id: '',
            routeName: '',
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
        if (route.id.isNotEmpty) {
          setState(() => _selectedRoute = route);
        }
      }
    }
  }

  Future<void> _saveSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserModel?.id;
    
    if (userId != null) {
      if (_selectedBusNumber != null) {
        await prefs.setString('driver_${userId}_bus_number', _selectedBusNumber!);
      }
      if (_selectedRoute != null) {
        await prefs.setString('driver_${userId}_route_id', _selectedRoute!.id);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final location = await locationService.getCurrentLocation();
    if (location != null) {
      setState(() {
        _currentLocation = location;
        _updateMarkers();
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
        _updateMarkers();
      }
    }
  }

  void _updateMarkers() {
    final newMarkers = <Marker>{};
    final newPolylines = <Polyline>{};

    // Add current location marker
    if (_currentLocation != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add route markers and polyline if route is selected
    if (_selectedRoute != null && _selectedRoute!.id.isNotEmpty) {
      final routePoints = <LatLng>[];
      
      // Start point (green)
      final startCoord = _getMockCoordinateForLocation(_selectedRoute!.startPoint);
      routePoints.add(startCoord);
      newMarkers.add(
        Marker(
          markerId: const MarkerId('start_point'),
          position: startCoord,
          infoWindow: InfoWindow(title: 'Start: ${_selectedRoute!.startPoint}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
      
      // Stop points (yellow)
      for (int i = 0; i < _selectedRoute!.stopPoints.length; i++) {
        final stopCoord = _getMockCoordinateForLocation(_selectedRoute!.stopPoints[i]);
        routePoints.add(stopCoord);
        newMarkers.add(
          Marker(
            markerId: MarkerId('stop_$i'),
            position: stopCoord,
            infoWindow: InfoWindow(title: 'Stop: ${_selectedRoute!.stopPoints[i]}'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          ),
        );
      }
      
      // End point (red)
      final endCoord = _getMockCoordinateForLocation(_selectedRoute!.endPoint);
      routePoints.add(endCoord);
      newMarkers.add(
        Marker(
          markerId: const MarkerId('end_point'),
          position: endCoord,
          infoWindow: InfoWindow(title: 'End: ${_selectedRoute!.endPoint}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      
      // Add polyline
      if (routePoints.length > 1) {
        newPolylines.add(
          Polyline(
            polylineId: const PolylineId('route_line'),
            points: routePoints,
            color: AppColors.primary,
            width: 4,
          ),
        );
      }
    }

    setState(() {
      _markers = newMarkers;
      _polylines = newPolylines;
    });
  }

  LatLng _getMockCoordinateForLocation(String location) {
    final mockCoords = {
      'Central Station': const LatLng(12.9716, 77.5946),
      'City Center': const LatLng(12.9726, 77.5956),
      'Shopping Mall': const LatLng(12.9736, 77.5966),
      'Hospital': const LatLng(12.9746, 77.5976),
      'University Campus': const LatLng(12.9756, 77.5986),
      'Airport': const LatLng(12.9766, 77.5996),
      'Hotel District': const LatLng(12.9776, 77.6006),
      'Business Park': const LatLng(12.9786, 77.6016),
      'Suburban Area': const LatLng(12.9796, 77.6026),
      'Residential Area': const LatLng(12.9806, 77.6036),
      'Park': const LatLng(12.9816, 77.6046),
    };
    
    return mockCoords[location] ?? _currentLocation ?? const LatLng(12.9716, 77.5946);
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location sharing stopped'),
          backgroundColor: AppColors.warning,
        ),
      );
    } else {
      // Start sharing location
      await locationService.startLocationTracking(
        onLocationUpdate: (location) async {
          print('DEBUG: Driver location update: ${location.latitude}, ${location.longitude}');
          
          final busLocation = BusLocationModel(
            busId: _myBus!.id,
            currentLocation: location,
            timestamp: DateTime.now(),
          );
          
          try {
            await firestoreService.updateBusLocation(_myBus!.id, busLocation);
            print('DEBUG: Location saved to Firestore successfully');
          } catch (e) {
            print('DEBUG: Error saving location to Firestore: $e');
          }
          
          // Update current location and markers
          if (mounted) {
            setState(() {
              _currentLocation = location;
            });
            _updateMarkers();
          }
        },
      );
      setState(() => _isSharing = true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location sharing started'),
          backgroundColor: AppColors.success,
        ),
      );
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
              // Location display
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
                            _updateMarkers();
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
                                    await _saveSelections();
                                    if (!mounted) return;
                                    setState(() => _myBus = newBus);
                                    _updateMarkers();
                                    
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
                                      
                                      // Clear saved selections
                                      final prefs = await SharedPreferences.getInstance();
                                      final authService = Provider.of<AuthService>(context, listen: false);
                                      final userId = authService.currentUserModel?.id;
                                      if (userId != null) {
                                        await prefs.remove('driver_${userId}_bus_number');
                                        await prefs.remove('driver_${userId}_route_id');
                                      }
                                      
                                      if (!mounted) return;
                                      setState(() {
                                        _myBus = null;
                                        _selectedBusNumber = null;
                                        _selectedRoute = null;
                                      });
                                      _updateMarkers();
                                      
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
                          _mapController = controller;
                          print('DEBUG: Driver GoogleMap created successfully');
                        },
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation!,
                          zoom: 16.0,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapType: MapType.normal,
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
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: AppSizes.paddingMedium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your location is being shared with students and teachers',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_currentLocation != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Current: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}',
                                      style: const TextStyle(
                                        color: AppColors.success,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
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