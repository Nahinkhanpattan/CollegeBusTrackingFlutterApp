import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/widgets/custom_button.dart';
import 'package:collegebus/utils/constants.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _isChecking = false;

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.resendEmailVerification();
      _showSuccessSnackBar('Verification email sent to ${widget.email}');
    } catch (e) {
      _showErrorSnackBar('Failed to resend email. Please try again.');
    } finally {
      setState(() => _isResending = false);
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isChecking = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isVerified = await authService.checkEmailVerification();
      
      if (isVerified) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar('Email not verified yet. Please check your email and click the verification link.');
      }
    } catch (e) {
      _showErrorSnackBar('Error checking verification status. Please try again.');
    } finally {
      setState(() => _isChecking = false);
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Email Verified'),
        content: const Text('Your email has been successfully verified. You can now login to your account.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('Continue to Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/register'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSizes.paddingXLarge),
              
              // Header
              const Icon(
                Icons.email_outlined,
                size: 80,
                color: AppColors.primary,
              ),
              
              const SizedBox(height: AppSizes.paddingLarge),
              
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: AppSizes.paddingMedium),
              
              Text(
                'We sent a verification link to\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: AppSizes.paddingXLarge),
              
              const Text(
                'Please check your email and click the verification link to verify your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: AppSizes.paddingXLarge),
              
              // Check verification button
              CustomButton(
                text: 'I\'ve Verified My Email',
                onPressed: _checkVerificationStatus,
                isLoading: _isChecking,
              ),
              
              const SizedBox(height: AppSizes.paddingMedium),
              
              // Resend email
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the email?",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: _isResending ? null : _resendVerificationEmail,
                    child: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Resend',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Note
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: AppSizes.iconMedium,
                    ),
                    SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: Text(
                        'Check your email inbox and spam folder for the verification link.',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}