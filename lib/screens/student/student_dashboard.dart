import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/services/location_service.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/notification_model.dart';
import 'package:collegebus/widgets/custom_button.dart';
import 'package:collegebus/utils/constants.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<BusModel> _allBuses = [];
  List<BusModel> _filteredBuses = [];
  BusModel? _selectedBus;
  LatLng? _currentLocation;
  bool _isTrackingBus = false;
  Set<Polyline> _polylines = {};
  String? _selectedStop;
  String? _selectedBusNumber;
  List<RouteModel> _routes = [];

  // Get unique stops from all buses
  List<String> get _allStops {
    final stops = <String>{};
    for (final bus in _allBuses) {
      final route = _routes.firstWhere(
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
      stops.add(route.startPoint);
      stops.add(route.endPoint);
      stops.addAll(route.stopPoints);
    }
    return stops.toList()..sort();
  }

  // Get unique bus numbers
  List<String> get _allBusNumbers {
    return _allBuses.map((bus) => bus.busNumber).toSet().toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentLocation();
    _loadRoutes();
    _loadBuses();
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
        _updateMarkers();
      });
    }
  }

  Future<void> _loadBuses() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    final collegeId = authService.currentUserModel?.collegeId;
    if (collegeId != null) {
      firestoreService.getBusesByCollege(collegeId).listen((buses) {
        setState(() {
          _allBuses = buses;
          _applyFilters();
          _updateMarkers();
        });
      });
    }
  }

  Future<void> _loadRoutes() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;
    if (collegeId != null) {
      firestoreService.getRoutesByCollege(collegeId).listen((routes) {
        setState(() {
          _routes = routes;
        });
      });
    }
  }

  void _applyFilters() {
    List<BusModel> filtered = List.from(_allBuses);

    // Filter by selected stop
    if (_selectedStop != null) {
      filtered = filtered.where((bus) {
        final route = _routes.firstWhere(
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
        // Show bus if the stop is start, end, or any stop in between
        return route.startPoint == _selectedStop ||
               route.endPoint == _selectedStop ||
               route.stopPoints.contains(_selectedStop);
      }).toList();
    }

    // Filter by selected bus number
    if (_selectedBusNumber != null) {
      filtered = filtered.where((bus) => bus.busNumber == _selectedBusNumber).toList();
    }

    setState(() {
      _filteredBuses = filtered;
    });
  }

  void _updateMarkers() {
    final newMarkers = <Marker>{};

    // Always show current location marker
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

    // Show all filtered buses as markers (even if no bus is selected)
    for (final bus in _filteredBuses) {
      _addBusMarker(bus, newMarkers);
    }

    // If a bus is selected, show its route polyline and stops
    if (_selectedBus != null) {
      _addBusRoutePolyline(_selectedBus!);
    } else {
      setState(() {
        _polylines = {};
      });
    }

    setState(() {
      _markers = newMarkers;
    });
  }
  
  void _addBusRoutePolyline(BusModel bus) {
    if (_selectedBus?.id == bus.id) {
      // Create route polyline for selected bus
      final routePoints = <LatLng>[];
      
      // Add mock coordinates for demonstration
      // In a real app, you'd get actual coordinates for each stop
      final route = _routes.firstWhere(
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
      final startCoord = _getMockCoordinateForLocation(route.startPoint);
      routePoints.add(startCoord);
      
      for (final stop in route.stopPoints) {
        routePoints.add(_getMockCoordinateForLocation(stop));
      }
      
      final endCoord = _getMockCoordinateForLocation(route.endPoint);
      routePoints.add(endCoord);
      
      final polyline = Polyline(
        polylineId: PolylineId('route_${bus.id}'),
        points: routePoints,
        color: AppColors.primary,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      );
      
      setState(() {
        _polylines = {polyline};
      });
      
      // Add stop markers
      for (int i = 0; i < routePoints.length; i++) {
        final stopName = i == 0 ? route.startPoint : 
                        i == routePoints.length - 1 ? route.endPoint :
                        route.stopPoints[i - 1];
        
        _markers.add(
          Marker(
            markerId: MarkerId('stop_${bus.id}_$i'),
            position: routePoints[i],
            infoWindow: InfoWindow(
              title: stopName,
              snippet: i == 0 ? 'Start Point' : 
                      i == routePoints.length - 1 ? 'End Point' : 'Stop',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              i == 0 ? BitmapDescriptor.hueGreen : 
              i == routePoints.length - 1 ? BitmapDescriptor.hueRed :
              BitmapDescriptor.hueOrange
            ),
          ),
        );
      }
    }
  }
  
  LatLng _getMockCoordinateForLocation(String location) {
    // Mock coordinates - in a real app, use geocoding service
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

  void _addBusMarker(BusModel bus, Set<Marker> markers) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final route = _routes.firstWhere(
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
    
    // Listen to real-time location updates for this bus
    firestoreService.getBusLocation(bus.id).listen((location) {
      if (location != null) {
        final marker = Marker(
          markerId: MarkerId('bus_${bus.id}'),
          position: location.currentLocation,
          infoWindow: InfoWindow(
            title: 'Bus ${bus.busNumber} ${bus.isActive ? "(Live)" : "(Not Live)"}',
            snippet: '${route.startPoint} → ${route.endPoint}\nLast updated: ${location.timestamp.toString().substring(11, 16)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _selectedBus?.id == bus.id ? BitmapDescriptor.hueRed : 
            bus.isActive ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
          ),
          onTap: () => _selectBus(bus),
        );

        setState(() {
          _markers.removeWhere((m) => m.markerId.value == 'bus_${bus.id}');
          _markers.add(marker);
        });
      } else {
        // Show bus at start point if no live location
        final startLocation = _getMockCoordinateForLocation(route.startPoint);
        final marker = Marker(
          markerId: MarkerId('bus_${bus.id}'),
          position: startLocation,
          infoWindow: InfoWindow(
            title: 'Bus ${bus.busNumber} (Not Live)',
            snippet: '${route.startPoint} → ${route.endPoint}\nStatus: Offline',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          onTap: () => _selectBus(bus),
        );
        
        setState(() {
          _markers.removeWhere((m) => m.markerId.value == 'bus_${bus.id}');
          _markers.add(marker);
        });
      }
    });
  }

  void _selectBus(BusModel bus) {
    setState(() {
      _selectedBus = bus;
    });
    
    // Move camera to bus location if available
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    firestoreService.getBusLocation(bus.id).listen((location) {
      if (location != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location.currentLocation, 16.0),
        );
      }
    });
  }

  void _onStopSelected(String? stop) {
    setState(() {
      _selectedStop = stop;
      _selectedBusNumber = null; // Clear bus number filter when stop is selected
    });
    _applyFilters();
    _updateMarkers();
  }

  void _onBusNumberSelected(String? busNumber) {
    setState(() {
      _selectedBusNumber = busNumber;
      _selectedStop = null; // Clear stop filter when bus number is selected
    });
    _applyFilters();
    _updateMarkers();
  }

  void _clearFilters() {
    setState(() {
      _selectedStop = null;
      _selectedBusNumber = null;
      _selectedBus = null;
      _polylines.clear();
    });
    _applyFilters();
    _updateMarkers();
  }

  Future<void> _sendWaitNotification() async {
    if (_selectedBus == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    final currentUser = authService.currentUserModel;
    if (currentUser != null) {
      // Send notification to driver
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: currentUser.id,
        receiverId: _selectedBus!.driverId,
        message: '${currentUser.fullName} is waiting for Bus ${_selectedBus!.busNumber}',
        type: 'wait_request',
        timestamp: DateTime.now(),
      );
      
      await firestoreService.sendNotification(notification);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wait notification sent to driver!'),
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
        title: Text('Welcome, ${user?.fullName ?? 'Student'}'),
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
            icon: const Icon(Icons.schedule),
            onPressed: () => context.go('/student/schedule'),
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
            Tab(text: 'Track Buses', icon: Icon(Icons.map)),
            Tab(text: 'Bus List', icon: Icon(Icons.list)),
            Tab(text: 'Bus Info', icon: Icon(Icons.info)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Map Tab
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
              
              // Filter Controls
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                color: AppColors.surface,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStop,
                            decoration: const InputDecoration(
                              labelText: 'Filter by Stop',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Stops'),
                              ),
                              ..._allStops.map((stop) => DropdownMenuItem(
                                value: stop,
                                child: Text(stop),
                              )),
                            ],
                            onChanged: _onStopSelected,
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingMedium),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedBusNumber,
                            decoration: const InputDecoration(
                              labelText: 'Filter by Bus',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Buses'),
                              ),
                              ..._allBusNumbers.map((busNumber) => DropdownMenuItem(
                                value: busNumber,
                                child: Text(busNumber),
                              )),
                            ],
                            onChanged: _onBusNumberSelected,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedStop != null || _selectedBusNumber != null) ...[
                      const SizedBox(height: AppSizes.paddingSmall),
                      Row(
                        children: [
                          Chip(
                            label: Text(_selectedStop ?? _selectedBusNumber ?? ''),
                            onDeleted: _clearFilters,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          ),
                          const SizedBox(width: AppSizes.paddingSmall),
                          Text(
                            '${_filteredBuses.length} bus(es) found',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Map
              Expanded(
                flex: 3,
                child: _currentLocation != null
                    ? GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                        },
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation!,
                          zoom: 14.0,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
              
              // Bus info and controls
              if (_selectedBus != null)
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus ${_selectedBus!.busNumber}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      Text(
                        'Route: ${_routes.firstWhere((r) => r.id == _selectedBus!.routeId, orElse: () => RouteModel(id: '', routeName: 'N/A', routeType: '', startPoint: '', endPoint: '', stopPoints: [], collegeId: '', createdBy: '', isActive: false, createdAt: DateTime.now(),)).startPoint} → ${_routes.firstWhere((r) => r.id == _selectedBus!.routeId, orElse: () => RouteModel(id: '', routeName: 'N/A', routeType: '', startPoint: '', endPoint: '', stopPoints: [], collegeId: '', createdBy: '', isActive: false, createdAt: DateTime.now(),)).endPoint}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      Text(
                        'Status: ${_selectedBus!.isActive ? "Live" : "Not Live"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedBus!.isActive ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if ((_routes.firstWhere((r) => r.id == _selectedBus!.routeId, orElse: () => RouteModel(id: '', routeName: 'N/A', routeType: '', startPoint: '', endPoint: '', stopPoints: [], collegeId: '', createdBy: '', isActive: false, createdAt: DateTime.now(),)).stopPoints.isNotEmpty)) ...[
                        const SizedBox(height: AppSizes.paddingSmall),
                        Text(
                          'Stops: ${_routes.firstWhere((r) => r.id == _selectedBus!.routeId, orElse: () => RouteModel(id: '', routeName: 'N/A', routeType: '', startPoint: '', endPoint: '', stopPoints: [], collegeId: '', createdBy: '', isActive: false, createdAt: DateTime.now(),)).stopPoints.join(' → ')}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSizes.paddingMedium),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Wait for Me',
                              onPressed: _sendWaitNotification,
                              icon: const Icon(Icons.front_hand, color: AppColors.onPrimary),
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingMedium),
                          Expanded(
                            child: CustomButton(
                              text: _isTrackingBus ? 'Stop Tracking' : 'Track Bus',
                              onPressed: () {
                                setState(() {
                                  _isTrackingBus = !_isTrackingBus;
                                });
                              },
                              backgroundColor: _isTrackingBus ? AppColors.error : AppColors.success,
                              icon: Icon(
                                _isTrackingBus ? Icons.stop : Icons.my_location,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          // Bus List Tab
          _filteredBuses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.directions_bus_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),
                      Text(
                        _selectedStop != null || _selectedBusNumber != null
                            ? 'No buses found for selected filter'
                            : 'No buses available',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  itemCount: _filteredBuses.length,
                  itemBuilder: (context, index) {
                    final bus = _filteredBuses[index];
                    final isSelected = _selectedBus?.id == bus.id;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? AppColors.primary : AppColors.success,
                          child: const Icon(
                            Icons.directions_bus,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        title: Text(
                          'Bus ${bus.busNumber}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_routes.firstWhere((r) => r.id == bus.routeId, orElse: () => RouteModel(id: '', routeName: 'N/A', routeType: '', startPoint: '', endPoint: '', stopPoints: [], collegeId: '', createdBy: '', isActive: false, createdAt: DateTime.now(),)).startPoint} → ${_routes.firstWhere((r) => r.id == bus.routeId, orElse: () => RouteModel(id: '', routeName: 'N/A', routeType: '', startPoint: '', endPoint: '', stopPoints: [], collegeId: '', createdBy: '', isActive: false, createdAt: DateTime.now(),)).endPoint}'),
                            if ((_routes.firstWhere((r) => r.id == bus.routeId, orElse: () => RouteModel(id: '', routeName: 'N/A', routeType: '', startPoint: '', endPoint: '', stopPoints: [], collegeId: '', createdBy: '', isActive: false, createdAt: DateTime.now(),)).stopPoints.isNotEmpty))
                              Text(
                                'Stops: ${_routes.firstWhere((r) => r.id == bus.routeId, orElse: () => RouteModel(id: '', routeName: 'N/A', routeType: '', startPoint: '', endPoint: '', stopPoints: [], collegeId: '', createdBy: '', isActive: false, createdAt: DateTime.now(),)).stopPoints.join(', ')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.primary)
                            : const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _selectBus(bus);
                          _tabController.animateTo(0); // Switch to map tab
                        },
                        isThreeLine: _routes.firstWhere((r) => r.id == bus.routeId, orElse: () => RouteModel(id: '', routeName: 'N/A', routeType: '', startPoint: '', endPoint: '', stopPoints: [], collegeId: '', createdBy: '', isActive: false, createdAt: DateTime.now(),)).stopPoints.isNotEmpty,
                      ),
                    );
                  },
                ),
          
          // Bus Info Tab
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Bus Numbers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Expanded(
                  child: _allBusNumbers.isEmpty
                      ? const Center(
                          child: Text(
                            'No bus numbers available',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _allBusNumbers.length,
                          itemBuilder: (context, index) {
                            final busNumber = _allBusNumbers[index];
                            final isAssigned = _allBuses.any((bus) => bus.busNumber == busNumber);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isAssigned ? AppColors.success : AppColors.warning,
                                  child: Icon(
                                    isAssigned ? Icons.check : Icons.directions_bus,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                                title: Text(
                                  busNumber,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  isAssigned ? 'Assigned to driver' : 'Available',
                                  style: TextStyle(
                                    color: isAssigned ? AppColors.success : AppColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                const Text(
                  'All Stops',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Expanded(
                  child: _allStops.isEmpty
                      ? const Center(
                          child: Text(
                            'No stops available',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _allStops.length,
                          itemBuilder: (context, index) {
                            final stop = _allStops[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                                title: Text(
                                  stop,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Bus stop location',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
