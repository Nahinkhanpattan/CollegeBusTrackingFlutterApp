import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/college_model.dart';
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
  CollegeModel? _college;
  List<String> _busNumbers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadPendingDrivers();
    _loadBuses();
    _loadRoutes();
    _loadCollege();
    _loadBusNumbers();
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
    if (collegeId == null) {
      print('DEBUG: College ID is null for routes');
      return;
    }
    print('DEBUG: Loading routes for college: $collegeId');
    firestoreService.getRoutesByCollege(collegeId).listen((routes) {
      print('DEBUG: Received ${routes.length} routes');
      setState(() {
        _routes = routes;
      });
    });
  }

  Future<void> _loadCollege() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;
    if (collegeId != null) {
      final college = await firestoreService.getCollege(collegeId);
      setState(() {
        _college = college;
      });
    }
  }

  Future<void> _loadBusNumbers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final collegeId = authService.currentUserModel?.collegeId;
    if (collegeId == null) {
      print('DEBUG: College ID is null');
      return;
    }
    print('DEBUG: Loading bus numbers for college: $collegeId');
    firestoreService.getBusNumbers(collegeId).listen((busNumbers) {
      print('DEBUG: Received ${busNumbers.length} bus numbers');
      setState(() {
        _busNumbers = busNumbers;
      });
    });
  }

  Future<void> _approveDriver(UserModel driver) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    final currentUser = authService.currentUserModel;
    if (currentUser != null) {
      await firestoreService.approveUser(driver.id, currentUser.id);
      if (!mounted) return;
      
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
      if (!mounted) return;
      
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
    final TextEditingController nameController = TextEditingController(text: route?.routeName ?? '');
    final TextEditingController startController = TextEditingController(text: route?.startPoint ?? '');
    final TextEditingController endController = TextEditingController(text: route?.endPoint ?? '');
    String selectedType = route?.routeType ?? 'pickup';
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
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Route Name'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Route Type'),
                      items: const [
                        DropdownMenuItem(value: 'pickup', child: Text('Pickup')),
                        DropdownMenuItem(value: 'drop', child: Text('Drop')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: startController,
                      decoration: const InputDecoration(labelText: 'Start Point'),
                      enabled: !isEditing,
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
                      enabled: !isEditing,
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
                      await firestoreService.updateRoute(route.id, {
                        'routeName': nameController.text.trim(),
                        'routeType': selectedType,
                        'stopPoints': stops,
                        'updatedAt': DateTime.now().toIso8601String(),
                      });
                      if (!mounted) return;
                    } else {
                      final newRoute = RouteModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        routeName: nameController.text.trim().isNotEmpty 
                            ? nameController.text.trim()
                            : '${startController.text.trim()} - ${endController.text.trim()}',
                        routeType: selectedType,
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
                      if (!mounted) return;
                    }
                    if (!mounted) return;
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

  void _showCreateBusNumberDialog() {
    final TextEditingController busNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Bus Number'),
          content: TextField(
            controller: busNumberController,
            decoration: const InputDecoration(
              labelText: 'Bus Number',
              hintText: 'e.g., KA-01-AB-1234',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final busNumber = busNumberController.text.trim();
                if (busNumber.isEmpty) return;

                final authService = Provider.of<AuthService>(context, listen: false);
                final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                final collegeId = authService.currentUserModel?.collegeId;
                
                if (collegeId != null) {
                  await firestoreService.addBusNumber(collegeId, busNumber);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bus number $busNumber added successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // Notifications will be implemented in future updates
            },
          ),
          IconButton(
            icon: const Icon(Icons.schedule),
            onPressed: () => context.go('/coordinator/schedule'),
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
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Driver Approvals', icon: Icon(Icons.approval)),
            Tab(text: 'Routes', icon: Icon(Icons.route)),
            Tab(text: 'Bus Numbers', icon: Icon(Icons.directions_bus)),
            Tab(text: 'College Info', icon: Icon(Icons.school)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overview Tab
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Overview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                
                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Routes',
                        _routes.length.toString(),
                        Icons.route,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: _buildStatCard(
                        'Active Buses',
                        _buses.where((b) => b.isActive).length.toString(),
                        Icons.directions_bus,
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSizes.paddingMedium),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Pending Drivers',
                        _pendingDrivers.length.toString(),
                        Icons.pending,
                        AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: _buildStatCard(
                        'Bus Numbers',
                        _busNumbers.length.toString(),
                        Icons.confirmation_number,
                        AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Driver Approvals Tab
          _pendingDrivers.isEmpty
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
                              'Applied: ${driver.createdAt.toString().substring(0, 10)}',
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
                ),

          // Routes Tab
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
                      onPressed: () => _showCreateOrEditRouteDialog(),
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
                                route.routeName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Type: ${route.routeType.toUpperCase()}'),
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
                                      if (!mounted) return;
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

          // Bus Numbers Tab
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bus Numbers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCreateBusNumberDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Bus Number'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _busNumbers.isEmpty
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
                              'No bus numbers added yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: AppSizes.paddingSmall),
                            Text(
                              'Add bus numbers for drivers to select',
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
                        itemCount: _busNumbers.length,
                        itemBuilder: (context, index) {
                          final busNumber = _busNumbers[index];
                          final isAssigned = _buses.any((bus) => bus.busNumber == busNumber);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
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
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.error),
                                onPressed: () async {
                                  if (isAssigned) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Cannot delete assigned bus number'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Bus Number'),
                                      content: Text('Are you sure you want to delete $busNumber?'),
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
                                    final authService = Provider.of<AuthService>(context, listen: false);
                                    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                                    final collegeId = authService.currentUserModel?.collegeId;
                                    
                                    if (collegeId != null) {
                                      await firestoreService.removeBusNumber(collegeId, busNumber);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Bus number $busNumber deleted'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // College Information Tab
          Padding(
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
                        
                        _buildInfoRow('College Name', _college?.name ?? 'N/A'),
                        _buildInfoRow('College ID', user?.collegeId ?? 'N/A'),
                        _buildInfoRow('Allowed Domains', _college?.allowedDomains.join(', ') ?? 'N/A'),
                        _buildInfoRow('Verification Status', _college?.verified == true ? 'Verified' : 'Pending'),
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
                        
                        _buildInfoRow('Total Routes', _routes.length.toString()),
                        _buildInfoRow('Pickup Routes', _routes.where((r) => r.routeType == 'pickup').length.toString()),
                        _buildInfoRow('Drop Routes', _routes.where((r) => r.routeType == 'drop').length.toString()),
                        _buildInfoRow('Total Buses', _buses.length.toString()),
                        _buildInfoRow('Active Buses', _buses.where((b) => b.isActive).length.toString()),
                        _buildInfoRow('Pending Drivers', _pendingDrivers.length.toString()),
                        _buildInfoRow('Available Bus Numbers', _busNumbers.length.toString()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}