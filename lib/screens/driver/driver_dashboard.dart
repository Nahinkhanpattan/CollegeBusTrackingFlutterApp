import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/services/location_service.dart';
import 'package:collegebus/models/bus_model.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
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

  Future<void> _loadMyBus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    final currentUser = authService.currentUserModel;
    if (currentUser != null) {
      final bus = await firestoreService.getBusByDriver(currentUser.id);
      if (bus != null) {
        setState(() {
          _myBus = bus;
          _busNumberController.text = bus.busNumber;
          _startPointController.text = bus.startPoint;
          _endPointController.text = bus.endPoint;
          
          // Clear existing controllers
          for (var controller in _stopControllers) {
            controller.dispose();
          }
          _stopControllers.clear();
          
          // Add controllers for existing stops
          for (int i = 0; i < bus.stopPoints.length; i++) {
            _stopControllers.add(TextEditingController(text: bus.stopPoints[i]));
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
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bus Information',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                
                CustomInputField(
                  label: 'Bus Number',
                  hint: 'Enter bus number (e.g., ABC-102)',
                  controller: _busNumberController,
                  prefixIcon: const Icon(Icons.directions_bus),
                ),
                
                const SizedBox(height: AppSizes.paddingMedium),
                
                CustomInputField(
                  label: 'Start Point',
                  hint: 'Enter starting location',
                  controller: _startPointController,
                  prefixIcon: const Icon(Icons.location_on),
                ),
                
                const SizedBox(height: AppSizes.paddingMedium),
                
                CustomInputField(
                  label: 'End Point',
                  hint: 'Enter destination',
                  controller: _endPointController,
                  prefixIcon: const Icon(Icons.flag),
                ),
                
                const SizedBox(height: AppSizes.paddingMedium),
                
                // Stop Points with dynamic fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Stop Points',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: _addStopController,
                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                      tooltip: 'Add Stop',
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSizes.paddingSmall),
                
                // Dynamic stop point fields
                ..._stopControllers.asMap().entries.map((entry) {
                  int index = entry.key;
                  TextEditingController controller = entry.value;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomInputField(
                            label: 'Stop ${index + 1}',
                            hint: 'Enter stop name',
                            controller: controller,
                            prefixIcon: const Icon(Icons.stop),
                          ),
                        ),
                        if (_stopControllers.length > 1)
                          IconButton(
                            onPressed: () => _removeStopController(index),
                            icon: const Icon(Icons.remove_circle, color: AppColors.error),
                            tooltip: 'Remove Stop',
                          ),
                      ],
                    ),
                  );
                }).toList(),
                ),
                
                const SizedBox(height: AppSizes.paddingLarge),
                
                CustomButton(
                  text: _myBus == null ? 'Create Bus Route' : 'Update Bus Route',
                  onPressed: _saveBusInfo,
                  icon: Icon(
                    _myBus == null ? Icons.add : Icons.update,
                    color: AppColors.onPrimary,
                  ),
                ),
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