import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/services/location_service.dart';
import 'package:collegebus/models/bus_model.dart';
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
  String? _selectedStop;
  String? _selectedBusNumber;

  // Get unique stops from all buses
  List<String> get _allStops {
    final stops = <String>{};
    for (final bus in _allBuses) {
      stops.add(bus.startPoint);
      stops.add(bus.endPoint);
      stops.addAll(bus.stopPoints);
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
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
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

  void _applyFilters() {
    List<BusModel> filtered = List.from(_allBuses);

    // Filter by selected stop
    if (_selectedStop != null) {
      filtered = filtered.where((bus) {
        return bus.startPoint == _selectedStop ||
               bus.endPoint == _selectedStop ||
               bus.stopPoints.contains(_selectedStop);
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

    // Add bus markers for filtered buses
    for (final bus in _filteredBuses) {
      _addBusMarker(bus, newMarkers);
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  void _addBusMarker(BusModel bus, Set<Marker> markers) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    // Listen to real-time location updates for this bus
    firestoreService.getBusLocation(bus.id).listen((location) {
      if (location != null) {
        final marker = Marker(
          markerId: MarkerId('bus_${bus.id}'),
          position: location.currentLocation,
          infoWindow: InfoWindow(
            title: 'Bus ${bus.busNumber}',
            snippet: '${bus.startPoint} → ${bus.endPoint}\nLast updated: ${location.timestamp.toString().substring(11, 16)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _selectedBus?.id == bus.id ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
          ),
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
            Tab(text: 'Track Buses', icon: Icon(Icons.map)),
            Tab(text: 'Bus List', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Map Tab
          Column(
            children: [
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
                            backgroundColor: AppColors.primary.withOpacity(0.1),
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
                        'Route: ${_selectedBus!.startPoint} → ${_selectedBus!.endPoint}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (_selectedBus!.stopPoints.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.paddingSmall),
                        Text(
                          'Stops: ${_selectedBus!.stopPoints.join(' → ')}',
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
                      color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
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
                            Text('${bus.startPoint} → ${bus.endPoint}'),
                            if (bus.stopPoints.isNotEmpty)
                              Text(
                                'Stops: ${bus.stopPoints.join(', ')}',
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
                        isThreeLine: bus.stopPoints.isNotEmpty,
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
