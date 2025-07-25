import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:email_validator/email_validator.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/widgets/custom_input_field.dart';
import 'package:collegebus/widgets/custom_button.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/auth/phone_otp_verification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _pendingApprovalMessage;
  String? _lastTriedEmail;
  String? _lastTriedPassword;
  UserRole _selectedRole = UserRole.student;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({String? email, String? password}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _pendingApprovalMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final loginEmail = email ?? _emailController.text.trim();
      final loginPassword = password ?? _passwordController.text;
      _lastTriedEmail = loginEmail;
      _lastTriedPassword = loginPassword;
      print('Attempting login with: $loginEmail');
      
      final result = await authService.loginUser(
        email: loginEmail,
        password: loginPassword,
      );

      print('Login result: $result');

      if (result['success']) {
        print('Login successful, user role: ${authService.userRole}');
        print('Current user model: ${authService.currentUserModel?.fullName}');
        // Force navigation by calling context.go with the appropriate route
        final userRole = authService.userRole;
        String route = '/login'; // default fallback
        
        switch (userRole) {
          case UserRole.student:
            route = '/student';
            break;
          case UserRole.teacher:
            route = '/teacher';
            break;
          case UserRole.driver:
            route = '/driver';
            break;
          case UserRole.busCoordinator:
            route = '/coordinator';
            break;
          case UserRole.admin:
            route = '/admin';
            break;
          case null:
            route = '/login';
            break;
        }
        print('Navigating to: $route');
        context.go(route);
      } else {
        _showErrorSnackBar(result['message']);
        if (result['needsEmailVerification'] == true) {
          _showEmailVerificationDialog();
        }
        if (result['message']?.toLowerCase().contains('pending approval') == true) {
          setState(() {
            _pendingApprovalMessage = result['message'];
          });
        }
      }
    } catch (e) {
      print('Login error: $e');
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Verification Required'),
        content: const Text(
          'Please verify your email address. Check your inbox for a verification link.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.resendEmailVerification();
              Navigator.of(context).pop();
              _showErrorSnackBar('Verification email sent!');
            },
            child: const Text('Resend'),
          ),
        ],
      ),
    );
  }

  void _showDummyCredentials() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Credentials'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Use these credentials to test the app:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _CredentialItem(
                role: 'Student',
                email: 'student@test.com',
                password: '123456',
              ),
              _CredentialItem(
                role: 'Teacher',
                email: 'teacher@test.com',
                password: '123456',
              ),
              _CredentialItem(
                role: 'Driver',
                email: 'driver@test.com',
                password: '123456',
              ),
              _CredentialItem(
                role: 'Bus Coordinator',
                email: 'coordinator@test.com',
                password: '123456',
              ),
              _CredentialItem(
                role: 'Admin',
                email: 'admin@test.com',
                password: '123456',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.paddingXLarge),
                
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                        ),
                        child: const Icon(
                          Icons.directions_bus,
                          size: 40,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingMedium),
                      const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSmall),
                      const Text(
                        AppStrings.loginTitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSizes.paddingXLarge),
                
                // Role selector
                const Text(
                  'Select Your Role',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserRole>(
                      value: _selectedRole,
                      isExpanded: true,
                      items: UserRole.values
                          .where((role) => role != UserRole.admin)
                          .map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.displayName),
                        );
                      }).toList(),
                      onChanged: (UserRole? newRole) {
                        if (newRole != null) {
                          setState(() => _selectedRole = newRole);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                if (_selectedRole == UserRole.driver) ...[
                  CustomInputField(
                    label: 'Phone Number',
                    hint: 'Enter your phone number (e.g. +919876543210)',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (!value.startsWith('+') || value.length < 10) {
                        return 'Enter phone in E.164 format (e.g. +919876543210)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  CustomButton(
                    text: 'Login with OTP',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PhoneOtpVerificationScreen(
                            phoneNumber: _phoneController.text.trim(),
                            onVerified: (user) async {
                              // Optionally, check Firestore for driver user and navigate
                              context.go('/driver');
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                // Email field
                CustomInputField(
                  label: 'Email',
                  hint: AppStrings.emailHint,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!EmailValidator.validate(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSizes.paddingMedium),
                
                // Password field
                CustomInputField(
                  label: 'Password',
                  hint: AppStrings.passwordHint,
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSizes.paddingMedium),
                
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                    },
                    child: const Text(
                      AppStrings.forgotPassword,
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                // Login button
                CustomButton(
                  text: AppStrings.loginButton,
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      AppStrings.dontHaveAccount,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text(
                        AppStrings.signUp,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ], // <-- This closes the else ...[ block for non-driver login
              if (_pendingApprovalMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.info, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _pendingApprovalMessage!,
                          style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        onPressed: _isLoading || _lastTriedEmail == null || _lastTriedPassword == null
                            ? null
                            : () => _handleLogin(email: _lastTriedEmail, password: _lastTriedPassword),
                      ),
                    ],
                  ),
                ),
            ], // <-- This closes the main Column's children
          ), // <-- This closes the main Column
        ), // <-- This closes the Form
      ), // <-- This closes the SingleChildScrollView
    ), // <-- This closes the SafeArea
  ); // <-- This closes the Scaffold
  }
}

class _CredentialItem extends StatelessWidget {
  final String role;
  final String email;
  final String password;

  const _CredentialItem({
    required this.role,
    required this.email,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text('Email: $email'),
          Text('Password: $password'),
        ],
      ),
    );
  }
}