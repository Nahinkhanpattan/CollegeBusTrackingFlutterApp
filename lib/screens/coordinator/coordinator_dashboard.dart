import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/utils/constants.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPendingDrivers();
    _loadBuses();
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
                ),
          
          // Bus Management Tab
          _buses.isEmpty
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
                            Text('Route: ${bus.startPoint} → ${bus.endPoint}'),
                            Text(
                              'Stops: ${bus.stopPoints.join(', ')}',
                              style: const TextStyle(fontSize: 12),
                            ),
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
                ),
          
          // College Info Tab
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