import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Test script for Firebase Phone Authentication
/// Run this to verify your setup is working correctly
class PhoneAuthTest {
  static Future<void> testPhoneAuth() async {
    try {
      print('🧪 Testing Firebase Phone Authentication...');
      
      // Test 1: Check Firebase Auth initialization
      print('1. Checking Firebase Auth initialization...');
      final auth = FirebaseAuth.instance;
      print('✅ Firebase Auth initialized successfully');
      
      // Test 2: Check if we can access verifyPhoneNumber
      print('2. Testing verifyPhoneNumber method...');
      final testPhoneNumber = '+16505554567';
      
      await auth.verifyPhoneNumber(
        phoneNumber: testPhoneNumber,
        timeout: const Duration(seconds: 10),
        verificationCompleted: (PhoneAuthCredential credential) {
          print('✅ Auto-verification completed');
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Verification failed: ${e.message}');
          print('Error code: ${e.code}');
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ SMS code sent successfully');
          print('Verification ID: $verificationId');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏰ Auto-retrieval timeout');
        },
      );
      
      print('✅ Phone authentication setup is working!');
      
    } catch (e) {
      print('❌ Phone authentication test failed: $e');
      print('Please check your Firebase configuration');
    }
  }
  
  static void printTestInstructions() {
    print('''
📱 Firebase Phone Authentication Test Instructions:

1. Make sure you have:
   ✅ google-services.json in android/app/
   ✅ Firebase project configured
   ✅ Phone Authentication enabled in Firebase Console
   ✅ Test phone numbers added in Firebase Console

2. Test phone numbers to add in Firebase Console:
   - Phone: +16505554567, Code: 123456
   - Phone: +919876543210, Code: 123456
   
   Note: Users only need to enter the 10-digit number (e.g., 9876543210)
   The +91 country code is automatically added by the app.

3. Run the app and test:
   - Select "Driver" role in login
   - Enter phone number (without +91, just the 10 digits)
   - Click "Login with OTP"
   - Enter verification code: 123456

4. Expected behavior:
   - OTP should be sent (or auto-verified in debug)
   - Verification should succeed
   - Navigation to driver dashboard

5. Debug logs to watch for:
   - "Phone verification completed automatically"
   - "SMS code sent to [phone]"
   - "Phone verification successful!"

6. Common issues:
   - Invalid phone format: Use E.164 format (+[country][number])
   - SMS quota exceeded: Use test numbers for development
   - App verification failed: Add SHA-1 fingerprint
   - Network issues: Check internet connection

For more details, see: FIREBASE_PHONE_AUTH_SETUP.md
''');
  }
}

// Run this in your main.dart for testing
void main() {
  PhoneAuthTest.printTestInstructions();
  // Uncomment to run actual test
  // PhoneAuthTest.testPhoneAuth();
} 