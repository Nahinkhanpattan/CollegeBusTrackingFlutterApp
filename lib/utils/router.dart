import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/auth/login_screen.dart';
import 'package:collegebus/auth/register_screen.dart';
import 'package:collegebus/auth/otp_verification.dart';
import 'package:collegebus/screens/student/student_dashboard.dart';
import 'package:collegebus/screens/teacher/teacher_dashboard.dart';
import 'package:collegebus/screens/driver/driver_dashboard.dart';
import 'package:collegebus/screens/coordinator/coordinator_dashboard.dart';
import 'package:collegebus/screens/admin/admin_dashboard.dart';
import 'package:collegebus/utils/constants.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isLoggedIn = authService.currentUserModel != null;
      final isLoginRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/register' ||
                          state.matchedLocation.startsWith('/otp');

      print('Router redirect called:');
      print('  Current location: ${state.matchedLocation}');
      print('  Is logged in: $isLoggedIn');
      print('  Is login route: $isLoginRoute');
      print('  Current user model: ${authService.currentUserModel?.fullName}');
      print('  User role: ${authService.userRole}');

      if (!isLoggedIn && !isLoginRoute) {
        print('  Redirecting to login');
        return '/login';
      }
      
      if (isLoggedIn && isLoginRoute) {
        // Redirect to appropriate dashboard based on user role
        final userRole = authService.userRole;
        print('  User is logged in, redirecting based on role: $userRole');
        switch (userRole) {
          case UserRole.student:
            print('  Redirecting to student dashboard');
            return '/student';
          case UserRole.teacher:
            print('  Redirecting to teacher dashboard');
            return '/teacher';
          case UserRole.driver:
            print('  Redirecting to driver dashboard');
            return '/driver';
          case UserRole.busCoordinator:
            print('  Redirecting to coordinator dashboard');
            return '/coordinator';
          case UserRole.admin:
            print('  Redirecting to admin dashboard');
            return '/admin';
          default:
            print('  Unknown role, redirecting to login');
            return '/login';
        }
      }
      
      print('  No redirect needed');
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
        path: '/otp/:email',
        builder: (context, state) => OtpVerificationScreen(
          email: state.pathParameters['email']!,
        ),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
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
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
    ],
  );
}
