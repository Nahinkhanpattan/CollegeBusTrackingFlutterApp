import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/widgets/custom_button.dart';
import 'package:collegebus/widgets/phone_input_field.dart';
import 'package:collegebus/utils/constants.dart';

class PhoneOtpVerificationScreen extends StatefulWidget {
  final String? phoneNumber;
  final void Function(User user)? onVerified;

  const PhoneOtpVerificationScreen({
    super.key,
    this.phoneNumber,
    this.onVerified,
  });

  @override
  State<PhoneOtpVerificationScreen> createState() => _PhoneOtpVerificationScreenState();
}

class _PhoneOtpVerificationScreenState extends State<PhoneOtpVerificationScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId;
  bool _isSending = false;
  bool _isVerifying = false;
  String? _error;
  
  // Test configuration for development
  static const String _testPhoneNumber = "+16505554567";
  static const String _testVerificationCode = "123456";

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumber != null) {
      _phoneController.text = widget.phoneNumber!;
    }
    
    // Configure Firebase Auth settings for testing
    _configureFirebaseAuthForTesting();
  }

  void _configureFirebaseAuthForTesting() {
    try {
      // Disable app verification for testing (only in debug mode)
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        debugPrint('Configuring Firebase Auth for testing...');
        FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: true,
          phoneNumber: _testPhoneNumber,
          smsCode: _testVerificationCode,
        );
        debugPrint('Firebase Auth test configuration applied successfully');
      }
    } catch (e) {
      debugPrint('Error configuring Firebase Auth for testing: $e');
    }
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isSending = true;
      _error = null;
    });
    
    try {
      final phoneNumber = _phoneController.text.trim();
      
      // Validate phone number
      if (phoneNumber.isEmpty) {
        setState(() => _error = 'Please enter your phone number');
        return;
      }
      
      if (phoneNumber.length < 10) {
        setState(() => _error = 'Please enter a valid 10-digit phone number');
        return;
      }
      
      // Automatically prepend +91 country code
      final fullPhoneNumber = '+91$phoneNumber';
      
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval or instant verification
          debugPrint('Phone verification completed automatically');
          try {
            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            if (widget.onVerified != null) widget.onVerified!(userCredential.user!);
            _showSuccessMessage('Phone verification successful!');
          } catch (e) {
            setState(() => _error = 'Verification failed: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Phone verification failed: ${e.message}');
          String errorMessage = 'Verification failed';
          
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many attempts. Please try again later.';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please try again later.';
              break;
            default:
              errorMessage = e.message ?? 'Verification failed';
          }
          
          setState(() => _error = errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('SMS code sent to ${_phoneController.text}');
          setState(() {
            _verificationId = verificationId;
            _error = null;
          });
          _showSuccessMessage('OTP sent successfully!');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('SMS code auto-retrieval timeout');
          setState(() => _verificationId = verificationId);
        },
      );
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      setState(() => _error = 'Failed to send OTP: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) {
      setState(() => _error = 'Please send OTP first');
      return;
    }
    
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (widget.onVerified != null) widget.onVerified!(userCredential.user!);
      
      _showSuccessMessage('Phone verification successful!');
      
      // Navigate to appropriate dashboard based on user role
      _navigateToDashboard(userCredential.user!);
      
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      setState(() => _error = 'Invalid OTP. Please try again.');
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToDashboard(User user) {
    // You can implement role-based navigation here
    // For now, navigate to driver dashboard
    context.go('/driver');
  }

  void _resendOtp() {
    setState(() {
      _verificationId = null;
      _otpController.clear();
    });
    _sendOtp();
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSizes.paddingXLarge),
              const Icon(Icons.phone_android, size: 80, color: AppColors.primary),
              const SizedBox(height: AppSizes.paddingLarge),
              const Text('Phone Verification', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: AppSizes.paddingMedium),
              // Phone number input with country code
              PhoneInputField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '9876543210',
                enabled: _verificationId == null,
                onChanged: () {
                  // Clear any error when user starts typing
                  if (_error != null) {
                    setState(() => _error = null);
                  }
                },
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              if (_verificationId == null)
                CustomButton(
                  text: 'Send OTP',
                  onPressed: _isSending ? null : _sendOtp,
                  isLoading: _isSending,
                ),
              if (_verificationId != null) ...[
                const SizedBox(height: AppSizes.paddingMedium),
                const Text(
                  'Enter the 6-digit code sent to your phone',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    hintText: '123456',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Verify OTP',
                        onPressed: _isVerifying ? null : _verifyOtp,
                        isLoading: _isVerifying,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    TextButton(
                      onPressed: _isSending ? null : _resendOtp,
                      child: const Text('Resend'),
                    ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSizes.paddingMedium),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 