import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/models/route_model.dart';

class CoordinatorDashboard extends StatefulWidget {
  const CoordinatorDashboard({super.key});

  @override
  State<CoordinatorDashboard> createState() => _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends State<CoordinatorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _pendingDrivers = [];
  List<BusModel> _buses = [];
  List<RouteModel> _routes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPendingDrivers();
    _loadBuses();
    _loadRoutes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingDrivers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    final collegeId = authService.currentUserModel?.collegeId;
    if (collegeId != null) {
      firestoreService.getPendingApprovals(collegeId).listen((users) {
        setState(() {
          _pendingDrivers = users.where((user) => user.role == UserRole.driver).toList();
        });
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
          _buses = buses;
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

  Future<void> _approveDriver(UserModel driver) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    final currentUser = authService.currentUserModel;
    if (currentUser != null) {
      await firestoreService.approveUser(driver.id, currentUser.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${driver.fullName} has been approved as a driver'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _rejectDriver(UserModel driver) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    final currentUser = authService.currentUserModel;
    if (currentUser != null) {
      await firestoreService.rejectUser(driver.id, currentUser.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${driver.fullName} has been rejected'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showCreateOrEditRouteDialog({RouteModel? route}) {
    final isEditing = route != null;
    final TextEditingController startController = TextEditingController(text: route?.startPoint ?? '');
    final TextEditingController endController = TextEditingController(text: route?.endPoint ?? '');
    List<TextEditingController> stopControllers =
        (route?.stopPoints ?? []).map((s) => TextEditingController(text: s)).toList();
    if (stopControllers.isEmpty) stopControllers.add(TextEditingController());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Route' : 'Create Route'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: startController,
                      decoration: const InputDecoration(labelText: 'Start Point'),
                      enabled: !isEditing, // Fixed if editing
                    ),
                    const SizedBox(height: 8),
                    ...stopControllers.asMap().entries.map((entry) {
                      int idx = entry.key;
                      TextEditingController controller = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(labelText: 'Stop ${idx + 1}'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: stopControllers.length > 1
                                ? () {
                                    setState(() {
                                      stopControllers.removeAt(idx);
                                    });
                                  }
                                : null,
                          ),
                        ],
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Stop'),
                        onPressed: () {
                          setState(() {
                            stopControllers.add(TextEditingController());
                          });
                        },
                      ),
                    ),
                    TextField(
                      controller: endController,
                      decoration: const InputDecoration(labelText: 'End Point'),
                      enabled: !isEditing, // Fixed if editing
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final collegeId = authService.currentUserModel?.collegeId;
                    if (collegeId == null) return;
                    final stops = stopControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
                    if (startController.text.trim().isEmpty || endController.text.trim().isEmpty) return;
                    if (isEditing) {
                      await firestoreService.updateRoute(route!.id, {
                        'stopPoints': stops,
                        'updatedAt': DateTime.now().toIso8601String(),
                      });
                    } else {
                      final newRoute = RouteModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        routeName: '${startController.text.trim()} - ${endController.text.trim()}',
                        routeType: 'pickup',
                        startPoint: startController.text.trim(),
                        endPoint: endController.text.trim(),
                        stopPoints: stops,
                        collegeId: collegeId,
                        createdBy: authService.currentUserModel?.id ?? '',
                        isActive: true,
                        createdAt: DateTime.now(),
                        updatedAt: null,
                      );
                      await firestoreService.createRoute(newRoute);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(isEditing ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateRouteDialog() {
    _showCreateOrEditRouteDialog();
  }

  @override
  Widget build(BuildContext context) {
    print('Building CoordinatorDashboard');
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Welcome, ${user?.fullName ?? 'Coordinator'}'),
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
            Tab(text: 'Driver Approvals', icon: Icon(Icons.approval)),
            Tab(text: 'Bus Management', icon: Icon(Icons.directions_bus)),
            Tab(text: 'College Info', icon: Icon(Icons.school)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Driver Approvals Tab
          Builder(builder: (context) { print('Building Driver Approvals Tab'); return _pendingDrivers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: AppSizes.paddingMedium),
                      Text(
                        'No pending driver approvals',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  itemCount: _pendingDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = _pendingDrivers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.drive_eta, color: AppColors.onPrimary),
                        ),
                        title: Text(
                          driver.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driver.email),
                            if (driver.phoneNumber != null && driver.phoneNumber!.isNotEmpty)
                              Text('Phone: ${driver.phoneNumber}'),
                            Text(
                              'Applied:  ${driver.createdAt.toString().substring(0, 10)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: AppColors.success),
                              onPressed: () => _approveDriver(driver),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.error),
                              onPressed: () => _rejectDriver(driver),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ); }),
          // Bus Management Tab
          Builder(builder: (context) { print('Building Bus Management Tab'); return _buses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_bus_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: AppSizes.paddingMedium),
                      Text(
                        'No buses registered yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppSizes.paddingSmall),
                      Text(
                        'Buses will appear here once drivers set them up',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  itemCount: _buses.length,
                  itemBuilder: (context, index) {
                    final bus = _buses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: bus.isActive ? AppColors.success : AppColors.error,
                          child: Icon(
                            Icons.directions_bus,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        title: Text(
                          'Bus ${bus.busNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Builder(builder: (context) {
                              final route = _routes.firstWhere(
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
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Route: ${route.startPoint} → ${route.endPoint}'),
                                  Text(
                                    'Stops: ${route.stopPoints.isNotEmpty ? route.stopPoints.join(', ') : 'N/A'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              );
                            }),
                            Text(
                              'Status: ${bus.isActive ? 'Active' : 'Inactive'}',
                              style: TextStyle(
                                color: bus.isActive ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            bus.isActive ? Icons.pause : Icons.play_arrow,
                            color: bus.isActive ? AppColors.error : AppColors.success,
                          ),
                          onPressed: () async {
                            final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                            await firestoreService.updateBus(bus.id, {
                              'isActive': !bus.isActive,
                              'updatedAt': DateTime.now().toIso8601String(),
                            });
                          },
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ); }),
          // College Info Tab
          Builder(builder: (context) { print('Building College Info Tab'); return Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'College Information',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'College Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        
                        _buildInfoRow('College ID', user?.collegeId ?? 'N/A'),
                        _buildInfoRow('Your Role', user?.role.displayName ?? 'N/A'),
                        _buildInfoRow('Email', user?.email ?? 'N/A'),
                        _buildInfoRow('Status', user?.approved == true ? 'Approved' : 'Pending'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSizes.paddingMedium),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        
                        _buildInfoRow('Total Buses', _buses.length.toString()),
                        _buildInfoRow('Active Buses', _buses.where((b) => b.isActive).length.toString()),
                        _buildInfoRow('Pending Drivers', _pendingDrivers.length.toString()),
                        _buildInfoRow('Total Routes', _routes.length.toString()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ); }),
          
          // Route Management Tab
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Routes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCreateRouteDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Route'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _routes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.route_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: AppSizes.paddingMedium),
                            Text(
                              'No routes created yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: AppSizes.paddingSmall),
                            Text(
                              'Create routes for drivers to select',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                        itemCount: _routes.length,
                        itemBuilder: (context, index) {
                          final route = _routes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: route.routeType == 'pickup' 
                                    ? AppColors.success 
                                    : AppColors.primary,
                                child: Icon(
                                  route.routeType == 'pickup' 
                                      ? Icons.arrow_upward 
                                      : Icons.arrow_downward,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                              title: Text(
                                route.displayName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${route.startPoint} → ${route.endPoint}'),
                                  if (route.stopPoints.isNotEmpty)
                                    Text(
                                      'Stops: ${route.stopPoints.join(', ')}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
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
                                  if (value == 'edit') {
                                    _showCreateOrEditRouteDialog(route: route);
                                  } else if (value == 'delete') {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Route'),
                                        content: Text('Are you sure you want to delete ${route.routeName}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.error,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                                      await firestoreService.deleteRoute(route.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Route deleted successfully'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              isThreeLine: route.stopPoints.isNotEmpty,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}