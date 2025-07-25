import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/widgets/custom_button.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumber != null) {
      _phoneController.text = widget.phoneNumber!;
    }
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval or instant verification
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          if (widget.onVerified != null) widget.onVerified!(userCredential.user!);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _error = e.message);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _verificationId = verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _verificationId = verificationId);
        },
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _verifyOtp() async {
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
      // Optionally, navigate to dashboard here
      context.go('/driver');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isVerifying = false);
    }
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
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                enabled: _verificationId == null,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              if (_verificationId == null)
                CustomButton(
                  text: 'Send OTP',
                  onPressed: _isSending ? null : _sendOtp,
                  isLoading: _isSending,
                ),
              if (_verificationId != null) ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                CustomButton(
                  text: 'Verify OTP',
                  onPressed: _isVerifying ? null : _verifyOtp,
                  isLoading: _isVerifying,
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