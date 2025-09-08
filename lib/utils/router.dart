import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/auth/login_screen.dart';
import 'package:collegebus/auth/register_screen.dart';

import 'package:collegebus/auth/forgot_password_screen.dart';
import 'package:collegebus/screens/student/student_dashboard.dart';
import 'package:collegebus/screens/student/bus_schedule_screen.dart';
import 'package:collegebus/screens/teacher/teacher_dashboard.dart';
import 'package:collegebus/screens/driver/driver_dashboard.dart';
import 'package:collegebus/screens/coordinator/coordinator_dashboard.dart';
import 'package:collegebus/screens/coordinator/schedule_management_screen.dart';
import 'package:collegebus/screens/admin/admin_dashboard.dart';
import 'package:collegebus/utils/constants.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isLoggedIn = authService.currentUserModel != null;
      final isLoginRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/register';

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }
      
      if (isLoggedIn && isLoginRoute) {
        // Redirect to appropriate dashboard based on user role
        final userRole = authService.userRole;
        switch (userRole) {
          case UserRole.student:
            return '/student';
          case UserRole.teacher:
            return '/teacher';
          case UserRole.driver:
            return '/driver';
          case UserRole.busCoordinator:
            return '/coordinator';
          case UserRole.admin:
            return '/admin';
          default:
            return '/login';
        }
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
        routes: [
          GoRoute(
            path: '/schedule',
            builder: (context, state) => const BusScheduleScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboard(),
      ),
      GoRoute(
        path: '/driver',
        builder: (context, state) => const DriverDashboard(),
      ),
      GoRoute(
        path: '/coordinator',
        builder: (context, state) => const CoordinatorDashboard(),
        routes: [
          GoRoute(
            path: '/schedule',
            builder: (context, state) => const ScheduleManagementScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
    ],
  );
}
