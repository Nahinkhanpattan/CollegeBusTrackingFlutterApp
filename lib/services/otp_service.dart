import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpService {
  static const int _maxOtpRequestsPerDay = 3;
  static const int _cooldownMinutes = 1;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> canRequestOtp(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      final requestKey = 'otp_requests_$phoneNumber$todayKey';
      final lastRequestKey = 'last_otp_request_$phoneNumber';
      
      // Check daily limit
      final requestCount = prefs.getInt(requestKey) ?? 0;
      if (requestCount >= _maxOtpRequestsPerDay) {
        return {
          'canRequest': false,
          'message': 'Daily OTP limit reached. Try again tomorrow.',
        };
      }
      
      // Check cooldown period
      final lastRequestTime = prefs.getInt(lastRequestKey) ?? 0;
      final lastRequest = DateTime.fromMillisecondsSinceEpoch(lastRequestTime);
      final timeDifference = today.difference(lastRequest).inMinutes;
      
      if (timeDifference < _cooldownMinutes) {
        final remainingTime = _cooldownMinutes - timeDifference;
        return {
          'canRequest': false,
          'message': 'Please wait $remainingTime minute(s) before requesting another OTP.',
        };
      }
      
      return {
        'canRequest': true,
        'message': 'OTP can be requested.',
      };
    } catch (e) {
      return {
        'canRequest': false,
        'message': 'Error checking OTP eligibility.',
      };
    }
  }

  Future<void> recordOtpRequest(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      final requestKey = 'otp_requests_$phoneNumber$todayKey';
      final lastRequestKey = 'last_otp_request_$phoneNumber';
      
      // Increment daily count
      final currentCount = prefs.getInt(requestKey) ?? 0;
      await prefs.setInt(requestKey, currentCount + 1);
      
      // Update last request time
      await prefs.setInt(lastRequestKey, today.millisecondsSinceEpoch);
    } catch (e) {
      // Error recording request, but app can continue
    }
  }

  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      // Check if OTP can be requested
      final canRequest = await canRequestOtp(phoneNumber);
      if (!canRequest['canRequest']) {
        return canRequest;
      }

      // Configure test settings for development
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        await _auth.setSettings(
          appVerificationDisabledForTesting: true,
          phoneNumber: "+16505554567",
          smsCode: "123456",
        );
      }

      final completer = Completer<Map<String, dynamic>>();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed
          completer.complete({
            'success': true,
            'message': 'Phone verification completed automatically',
            'autoVerified': true,
            'credential': credential,
          });
        },
        verificationFailed: (FirebaseAuthException e) {
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
          
          completer.complete({
            'success': false,
            'message': errorMessage,
          });
        },
        codeSent: (String verificationId, int? resendToken) async {
          // Record the OTP request
          await recordOtpRequest(phoneNumber);
          
          completer.complete({
            'success': true,
            'message': 'OTP sent successfully',
            'verificationId': verificationId,
            'resendToken': resendToken,
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout handling
        },
      );

      return await completer.future;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send OTP. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      return {
        'success': true,
        'message': 'Phone verification successful',
        'user': userCredential.user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid OTP. Please try again.',
      };
    }
  }

  Future<int> getRemainingOtpRequests(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      final requestKey = 'otp_requests_$phoneNumber$todayKey';
      
      final requestCount = prefs.getInt(requestKey) ?? 0;
      return _maxOtpRequestsPerDay - requestCount;
    } catch (e) {
      return _maxOtpRequestsPerDay;
    }
  }

  Future<int> getCooldownTimeRemaining(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRequestKey = 'last_otp_request_$phoneNumber';
      final lastRequestTime = prefs.getInt(lastRequestKey) ?? 0;
      
      if (lastRequestTime == 0) return 0;
      
      final lastRequest = DateTime.fromMillisecondsSinceEpoch(lastRequestTime);
      final now = DateTime.now();
      final timeDifference = now.difference(lastRequest).inMinutes;
      
      return _cooldownMinutes - timeDifference > 0 ? _cooldownMinutes - timeDifference : 0;
    } catch (e) {
      return 0;
    }
  }
}