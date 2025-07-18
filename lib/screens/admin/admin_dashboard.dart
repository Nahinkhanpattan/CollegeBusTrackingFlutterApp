import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_bus_tracker/services/auth_service.dart';
import 'package:college_bus_tracker/services/firestore_service.dart';
import 'package:college_bus_tracker/models/user_model.dart';
import 'package:college_bus_tracker/models/college_model.dart';
import 'package:college_bus_tracker/utils/constants.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _allUsers = [];
  List<CollegeModel> _allColleges = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllUsers();
    _loadAllColleges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    // This would require a more complex query in a real app
    // For now, we'll show a placeholder
    setState(() {
      _allUsers = [];
    });
  }

  Future<void> _loadAllColleges() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    firestoreService.getAllColleges().listen((colleges) {
      setState(() {
        _allColleges = colleges;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Admin Panel - ${user?.fullName ?? 'Admin'}'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.onPrimary,
          unselectedLabelColor: AppColors.onPrimary.withOpacity(0.7),
          indicatorColor: AppColors.onPrimary,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Colleges', icon: Icon(Icons.school)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
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
                        'Total Colleges',
                        _allColleges.length.toString(),
                        Icons.school,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: _buildStatCard(
                        'Verified Colleges',
                        _allColleges.where((c) => c.verified).length.toString(),
                        Icons.verified,
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
                        'Total Users',
                        _allUsers.length.toString(),
                        Icons.people,
                        AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: _buildStatCard(
                        'Pending Approvals',
                        _allUsers.where((u) => u.needsManualApproval).length.toString(),
                        Icons.pending,
                        AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Colleges Tab
          _allColleges.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: AppSizes.paddingMedium),
                      Text(
                        'No colleges registered yet',
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
                  itemCount: _allColleges.length,
                  itemBuilder: (context, index) {
                    final college = _allColleges[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: college.verified ? AppColors.success : AppColors.warning,
                          child: Icon(
                            college.verified ? Icons.verified : Icons.pending,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        title: Text(
                          college.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Domains: ${college.allowedDomains.join(', ')}'),
                            Text(
                              'Status: ${college.verified ? 'Verified' : 'Pending Verification'}',
                              style: TextStyle(
                                color: college.verified ? AppColors.success : AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: !college.verified
                            ? IconButton(
                                icon: const Icon(Icons.check, color: AppColors.success),
                                onPressed: () {
                                  // TODO: Verify college
                                },
                              )
                            : null,
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
          
          // Users Tab
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: AppSizes.paddingMedium),
                Text(
                  'User management coming soon',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppSizes.paddingSmall),
                Text(
                  'This feature will allow you to view and manage all users across colleges',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
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
}