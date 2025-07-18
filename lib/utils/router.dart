import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:college_bus_tracker/services/auth_service.dart';
import 'package:college_bus_tracker/auth/login_screen.dart';
import 'package:college_bus_tracker/auth/register_screen.dart';
import 'package:college_bus_tracker/auth/otp_verification.dart';
import 'package:college_bus_tracker/screens/student/student_dashboard.dart';
import 'package:college_bus_tracker/screens/teacher/teacher_dashboard.dart';
import 'package:college_bus_tracker/screens/driver/driver_dashboard.dart';
import 'package:college_bus_tracker/screens/coordinator/coordinator_dashboard.dart';
import 'package:college_bus_tracker/screens/admin/admin_dashboard.dart';
import 'package:college_bus_tracker/utils/constants.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isLoggedIn = authService.currentUser != null;
      final isLoginRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/register' ||
                          state.matchedLocation.startsWith('/otp');

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