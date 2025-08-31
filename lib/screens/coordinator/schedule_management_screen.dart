import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/schedule_model.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/utils/constants.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<ScheduleModel> _firstShiftSchedules = [];
  List<ScheduleModel> _secondShiftSchedules = [];
  List<RouteModel> _routes = [];
  List<BusModel> _buses = [];

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

    if (collegeId == null) return;

    firestoreService.getRoutesByCollege(collegeId).listen((routes) {
      if (!mounted) return;
      setState(() => _routes = routes);
    });

    firestoreService.getBusesByCollege(collegeId).listen((buses) {
      if (!mounted) return;
      setState(() => _buses = buses);
    });

    firestoreService.getSchedulesByCollege(collegeId).listen((schedules) {
      if (!mounted) return;
      setState(() {
        _firstShiftSchedules = schedules.where((s) => s.shift == '1st').toList();
        _secondShiftSchedules = schedules.where((s) => s.shift == '2nd').toList();
      });
    });
  }

  void _showCreateScheduleDialog(String shift) {
    RouteModel? selectedRoute;
    BusModel? selectedBus;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Create $shift Shift Timetable'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<RouteModel>(
                      value: selectedRoute,
                      decoration: const InputDecoration(
                        labelText: 'Select Route',
                        border: OutlineInputBorder(),
                      ),
                      items: _routes
                          .map((route) => DropdownMenuItem(
                                value: route,
                                child: Text(
                                  '${route.routeName} (${route.routeType.toUpperCase()})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (route) {
                        setState(() {
                          selectedRoute = route;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<BusModel>(
                      value: selectedBus,
                      decoration: const InputDecoration(
                        labelText: 'Select Bus',
                        border: OutlineInputBorder(),
                      ),
                      items: _buses
                          .map((bus) => DropdownMenuItem(
                                value: bus,
                                child: Text(
                                  'Bus ${bus.busNumber}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (bus) => setState(() => selectedBus = bus),
                    ),
                    const SizedBox(height: 16),
                    if (selectedRoute != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Route Information:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${selectedRoute!.startPoint} → ${selectedRoute!.endPoint}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (selectedRoute!.stopPoints.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Stops: ${selectedRoute!.stopPoints.join(' → ')}',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Type: ${selectedRoute!.routeType.toUpperCase()}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Note:',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'This will create a timetable showing which bus goes to which stops. No specific times are needed.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedRoute != null && selectedBus != null
                      ? () async {
                          final authService = Provider.of<AuthService>(context, listen: false);
                          final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                          
                          // Create stop schedules without specific times
                          final stopSchedules = <StopSchedule>[];
                          final allStops = [
                            selectedRoute!.startPoint,
                            ...selectedRoute!.stopPoints,
                            selectedRoute!.endPoint,
                          ];
                          
                          for (final stop in allStops) {
                            stopSchedules.add(StopSchedule(
                              stopName: stop,
                              arrivalTime: 'As per schedule',
                              departureTime: 'As per schedule',
                            ));
                          }
                          
                          final schedule = ScheduleModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            routeId: selectedRoute!.id,
                            busId: selectedBus!.id,
                            shift: shift,
                            stopSchedules: stopSchedules,
                            collegeId: authService.currentUserModel!.collegeId,
                            createdBy: authService.currentUserModel!.id,
                            createdAt: DateTime.now(),
                          );
                          
                          await firestoreService.createSchedule(schedule);
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$shift shift timetable created successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      : null,
                  child: const Text('Create Timetable'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bus Timetables'),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScheduleTab('1st', _firstShiftSchedules),
          _buildScheduleTab('2nd', _secondShiftSchedules),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final currentShift = _tabController.index == 0 ? '1st' : '2nd';
          _showCreateScheduleDialog(currentShift);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Create Timetable'),
      ),
    );
  }

  Widget _buildScheduleTab(String shift, List<ScheduleModel> schedules) {
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
              'No $shift shift timetables created yet',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            const Text(
              'Tap the + button to create a timetable',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
            stopPoints: const [],
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
              child: Icon(
                shift == '1st' ? Icons.wb_sunny : Icons.nights_stay,
                color: AppColors.onPrimary,
              ),
            ),
            title: Text('Bus ${bus.busNumber}', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Route: ${route.routeName}'),
                Text('Type: ${route.routeType.toUpperCase()}'),
                Text('${route.startPoint} → ${route.endPoint}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Timetable'),
                      content: const Text('Are you sure you want to delete this timetable?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                    await firestoreService.deleteSchedule(schedule.id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Timetable deleted successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bus Stops on this Route:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    
                    // Show route stops in order
                    Column(
                      children: schedule.stopSchedules.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stopSchedule = entry.value;
                        final isStart = index == 0;
                        final isEnd = index == schedule.stopSchedules.length - 1;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isStart 
                                ? AppColors.success.withValues(alpha: 0.1)
                                : isEnd 
                                    ? AppColors.error.withValues(alpha: 0.1)
                                    : AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isStart 
                                  ? AppColors.success
                                  : isEnd 
                                      ? AppColors.error
                                      : AppColors.warning,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isStart 
                                    ? Icons.play_arrow
                                    : isEnd 
                                        ? Icons.stop
                                        : Icons.location_on,
                                color: isStart 
                                    ? AppColors.success
                                    : isEnd 
                                        ? AppColors.error
                                        : AppColors.warning,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stopSchedule.stopName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      isStart 
                                          ? 'Starting Point'
                                          : isEnd 
                                              ? 'End Point'
                                              : 'Bus Stop',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isStart 
                                            ? AppColors.success
                                            : isEnd 
                                                ? AppColors.error
                                                : AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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