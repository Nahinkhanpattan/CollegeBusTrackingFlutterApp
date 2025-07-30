import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Quick fix for Firebase Phone Auth Play Integrity error
/// Run this to apply the necessary test configuration
class FirebasePhoneAuthFix {
  
  /// Apply test configuration to fix Play Integrity error
  static Future<void> applyTestConfiguration() async {
    try {
      print('🔧 Applying Firebase Phone Auth test configuration...');
      
      // Check if we're in debug mode
      final isDebug = const bool.fromEnvironment('dart.vm.product') == false;
      
      if (isDebug) {
        print('✅ Debug mode detected, applying test settings...');
        
        // Apply test configuration
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: true,
          phoneNumber: "+16505554567",
          smsCode: "123456",
        );
        
        print('✅ Test configuration applied successfully!');
        print('📱 You can now use these test numbers:');
        print('   - +16505554567 (code: 123456)');
        print('   - +919876543210 (code: 123456)');
        
      } else {
        print('⚠️  Release mode detected. Test configuration not applied.');
        print('📝 For production, ensure SHA-1 fingerprint is added to Firebase Console.');
      }
      
    } catch (e) {
      print('❌ Error applying test configuration: $e');
      print('💡 Make sure Firebase is properly initialized');
    }
  }
  
  /// Test phone authentication with test numbers
  static Future<void> testPhoneAuth() async {
    try {
      print('🧪 Testing Firebase Phone Authentication...');
      
      final testNumbers = [
        "+16505554567",
        "+919876543210",
      ];
      
      for (final phoneNumber in testNumbers) {
        print('📞 Testing with: $phoneNumber');
        
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: const Duration(seconds: 10),
          verificationCompleted: (PhoneAuthCredential credential) {
            print('✅ Auto-verification completed for $phoneNumber');
          },
          verificationFailed: (FirebaseAuthException e) {
            print('❌ Verification failed for $phoneNumber: ${e.message}');
            print('Error code: ${e.code}');
          },
          codeSent: (String verificationId, int? resendToken) {
            print('✅ SMS code sent successfully to $phoneNumber');
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            print('⏰ Auto-retrieval timeout for $phoneNumber');
          },
        );
        
        // Wait a bit between tests
        await Future.delayed(const Duration(seconds: 2));
      }
      
      print('✅ Phone authentication test completed!');
      
    } catch (e) {
      print('❌ Phone authentication test failed: $e');
    }
  }
  
  /// Print troubleshooting steps
  static void printTroubleshootingSteps() {
    print('''
🔧 Firebase Phone Auth Troubleshooting Steps:

1. **Add SHA-1 Fingerprint**:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Then add the SHA-1 to Firebase Console → Project Settings → Your Apps → Android App

2. **Add Test Phone Numbers**:
   Go to Firebase Console → Authentication → Settings → Phone numbers for testing
   Add: +16505554567 (code: 123456)
   Add: +919876543210 (code: 123456)

3. **Use Test Numbers Only**:
   - Don't use real phone numbers in development
   - Use the test numbers provided above

4. **Clean and Rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

5. **Check Google Play Services**:
   Ensure your device/emulator has Google Play Services installed

6. **Verify google-services.json**:
   Make sure it's in android/app/google-services.json
   Check that package name matches your app

Common Error Solutions:
- "Missing app identifier": Add SHA-1 fingerprint
- "Play Integrity failed": Use test configuration in debug mode
- "reCAPTCHA failed": Use test phone numbers only

For more details, see: FIREBASE_PHONE_AUTH_TROUBLESHOOTING.md
''');
  }
}

// Run this in your main.dart for testing
void main() {
  FirebasePhoneAuthFix.printTroubleshootingSteps();
  
  // Uncomment to apply test configuration
  // FirebasePhoneAuthFix.applyTestConfiguration();
  
  // Uncomment to test phone auth
  // FirebasePhoneAuthFix.testPhoneAuth();
} 