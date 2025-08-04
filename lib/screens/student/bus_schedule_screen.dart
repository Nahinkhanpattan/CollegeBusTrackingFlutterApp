import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/models/schedule_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/utils/constants.dart';

class BusScheduleScreen extends StatefulWidget {
  const BusScheduleScreen({super.key});

  @override
  State<BusScheduleScreen> createState() => _BusScheduleScreenState();
}

class _BusScheduleScreenState extends State<BusScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ScheduleModel> _firstShiftSchedules = [];
  List<ScheduleModel> _secondShiftSchedules = [];
  List<ScheduleModel> _filteredFirstShift = [];
  List<ScheduleModel> _filteredSecondShift = [];
  List<RouteModel> _routes = [];
  List<BusModel> _buses = [];
  
  // Filter variables
  String? _selectedBusNumber;
  String? _selectedRoute;
  String? _selectedStop;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;
    
    if (collegeId != null) {
      // Load routes
      firestoreService.getRoutesByCollege(collegeId).listen((routes) {
        setState(() => _routes = routes);
      });
      
      // Load buses
      firestoreService.getBusesByCollege(collegeId).listen((buses) {
        setState(() => _buses = buses);
      });
      
      // Load schedules
      firestoreService.getSchedulesByCollege(collegeId).listen((schedules) {
        setState(() {
          _firstShiftSchedules = schedules.where((s) => s.shift == '1st').toList();
          _secondShiftSchedules = schedules.where((s) => s.shift == '2nd').toList();
          _applyFilters();
        });
      });
    }
  }

  void _applyFilters() {
    _filteredFirstShift = _filterSchedules(_firstShiftSchedules);
    _filteredSecondShift = _filterSchedules(_secondShiftSchedules);
  }

  List<ScheduleModel> _filterSchedules(List<ScheduleModel> schedules) {
    List<ScheduleModel> filtered = List.from(schedules);

    // Filter by bus number
    if (_selectedBusNumber != null) {
      filtered = filtered.where((schedule) {
        final bus = _buses.firstWhere(
          (b) => b.id == schedule.busId,
          orElse: () => BusModel(
            id: '',
            busNumber: '',
            driverId: '',
            collegeId: '',
            createdAt: DateTime.now(),
          ),
        );
        return bus.busNumber == _selectedBusNumber;
      }).toList();
    }

    // Filter by route
    if (_selectedRoute != null) {
      filtered = filtered.where((schedule) {
        final route = _routes.firstWhere(
          (r) => r.id == schedule.routeId,
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
        return route.displayName == _selectedRoute;
      }).toList();
    }

    // Filter by stop
    if (_selectedStop != null) {
      filtered = filtered.where((schedule) {
        return schedule.stopSchedules.any((stop) => stop.stopName == _selectedStop);
      }).toList();
    }

    return filtered;
  }

  void _clearFilters() {
    setState(() {
      _selectedBusNumber = null;
      _selectedRoute = null;
      _selectedStop = null;
      _applyFilters();
    });
  }

  List<String> get _allBusNumbers {
    return _buses.map((bus) => bus.busNumber).toSet().toList()..sort();
  }

  List<String> get _allRoutes {
    return _routes.map((route) => route.displayName).toSet().toList()..sort();
  }

  List<String> get _allStops {
    final stops = <String>{};
    for (final route in _routes) {
      stops.add(route.startPoint);
      stops.add(route.endPoint);
      stops.addAll(route.stopPoints);
    }
    return stops.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bus Schedules'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.onPrimary,
                          unselectedLabelColor: AppColors.onPrimary.withValues(alpha: 0.7),
          indicatorColor: AppColors.onPrimary,
          tabs: const [
            Tab(text: '1st Shift', icon: Icon(Icons.wb_sunny)),
            Tab(text: '2nd Shift', icon: Icon(Icons.nights_stay)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Panel
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            color: AppColors.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedBusNumber,
                        decoration: const InputDecoration(
                          labelText: 'Bus Number',
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
                        onChanged: (value) {
                          setState(() {
                            _selectedBusNumber = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingSmall),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRoute,
                        decoration: const InputDecoration(
                          labelText: 'Route',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Routes'),
                          ),
                          ..._allRoutes.map((route) => DropdownMenuItem(
                            value: route,
                            child: Text(route),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRoute = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStop,
                        decoration: const InputDecoration(
                          labelText: 'Stop',
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
                        onChanged: (value) {
                          setState(() {
                            _selectedStop = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingSmall),
                    if (_selectedBusNumber != null || _selectedRoute != null || _selectedStop != null)
                      IconButton(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear Filters',
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Schedule Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScheduleList(_filteredFirstShift, '1st'),
                _buildScheduleList(_filteredSecondShift, '2nd'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<ScheduleModel> schedules, String shift) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              shift == '1st' ? Icons.wb_sunny : Icons.nights_stay,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            Text(
              _selectedBusNumber != null || _selectedRoute != null || _selectedStop != null
                  ? 'No schedules match your filters'
                  : 'No $shift shift schedules available',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        final route = _routes.firstWhere(
          (r) => r.id == schedule.routeId,
          orElse: () => RouteModel(
            id: '',
            routeName: 'Unknown Route',
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
        final bus = _buses.firstWhere(
          (b) => b.id == schedule.busId,
          orElse: () => BusModel(
            id: '',
            busNumber: 'Unknown Bus',
            driverId: '',
            collegeId: '',
            createdAt: DateTime.now(),
          ),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                bus.busNumber.replaceAll('Bus ', ''),
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              'Bus ${bus.busNumber}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Route: ${route.displayName}'),
                Text(
                  '${route.startPoint} → ${route.endPoint}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            trailing: ElevatedButton.icon(
              onPressed: () {
                // Navigate to live tracking with this bus selected
                Navigator.of(context).pop();
                // You can pass the bus ID to the tracking screen
              },
              icon: const Icon(Icons.location_on, size: 16),
              label: const Text('Track Live'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stop Timings:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                      },
                      children: [
                        const TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Stop',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Arrival',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Departure',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        ...schedule.stopSchedules.map((stopSchedule) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(stopSchedule.stopName),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  stopSchedule.arrivalTime,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  stopSchedule.departureTime,
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}