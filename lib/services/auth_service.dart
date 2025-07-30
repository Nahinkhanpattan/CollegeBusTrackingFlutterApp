import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/services/firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;
  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;
  UserRole? get userRole => _currentUserModel?.role;

  AuthService() {
    try {
      // Check if Firebase is properly configured
      final auth = FirebaseAuth.instance;
    _auth.authStateChanges().listen(_onAuthStateChanged);
    } catch (e) {
      debugPrint('Firebase Auth not available: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    try {
    if (user != null) {
      await _loadUserModel(user.uid);
    } else {
      _currentUserModel = null;
    }
    notifyListeners();
    } catch (e) {
      debugPrint('Error in _onAuthStateChanged: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _loadUserModel(String uid) async {
    try {
      final doc = await _firestore.collection(FirebaseCollections.users).doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUserModel = UserModel.fromMap(data, uid);
      } else {
        debugPrint('User document does not exist for UID: $uid');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user model: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String collegeName,
    required UserRole role,
    String? phoneNumber,
    String? rollNumber,
  }) async {
    try {
      // Extract domain from email
      final domain = email.split('@').last;
      
      // Check if college exists and if domain is allowed
      final collegeQuery = await _firestore
          .collection(FirebaseCollections.colleges)
          .where('allowedDomains', arrayContains: domain)
          .get();

      bool needsManualApproval = true;
      String collegeId = '';

      if (collegeQuery.docs.isNotEmpty) {
        // College exists and domain is allowed
        needsManualApproval = false;
        collegeId = collegeQuery.docs.first.id;
      } else {
        // Check if it's an academic domain (.ac.in)
        if (domain.endsWith('.ac.in') && role == UserRole.busCoordinator) {
          // Create new college for coordinator with academic domain
          collegeId = await _createCollege(collegeName, domain, '');
          needsManualApproval = false;
        } else {
          // Use a default college ID or create one
          collegeId = collegeName.toLowerCase().replaceAll(' ', '_');
        }
      }

      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;

      // Create user document in Firestore
      final userModel = UserModel(
        id: user.uid,
        fullName: fullName,
        email: email,
        role: role,
        collegeId: collegeId,
        approved: !needsManualApproval,
        emailVerified: false,
        needsManualApproval: needsManualApproval,
        createdAt: DateTime.now(),
        phoneNumber: phoneNumber,
        rollNumber: rollNumber,
      );

      try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .set(userModel.toMap());
        
      } catch (e) {
        debugPrint('Error creating user document: $e');
        debugPrint('Stack trace: ${StackTrace.current}');
        throw e;
      }

      // Send email verification
      await user.sendEmailVerification();
      return {
        'success': true,
        'needsEmailVerification': true,
        'message': 'Please check your email for verification code.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<String> _createCollege(String name, String domain, String createdBy) async {
    final collegeId = name.toLowerCase().replaceAll(' ', '_');
    final college = CollegeModel(
      id: collegeId,
      name: name,
      allowedDomains: [domain],
      verified: domain.endsWith('.ac.in'),
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(FirebaseCollections.colleges)
        .doc(collegeId)
        .set(college.toMap());

    return collegeId;
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      await _loadUserModel(user.uid);

      if (_currentUserModel == null) {
        return {
          'success': false,
          'message': 'User profile not found. Please register first.',
        };
      }

      final role = _currentUserModel!.role;
      final approved = _currentUserModel!.approved;
      final emailVerified = _currentUserModel!.emailVerified || user.emailVerified;
      final needsManualApproval = _currentUserModel!.needsManualApproval;

      // Admin: Only allow login if approved
      if (role == UserRole.admin) {
        if (!approved) {
          return {
            'success': false,
            'message': 'Your account is pending approval.',
          };
        }
        return {
          'success': true,
          'message': 'Login successful.',
        };
      }

      // For all other roles: require BOTH email verified AND approved
      if (!emailVerified) {
        return {
          'success': false,
          'message': 'Please verify your email address first.',
          'needsEmailVerification': true,
        };
      }
      if (!approved) {
        return {
          'success': false,
          'message': 'Your account is pending approval.',
        };
      }
      return {
        'success': true,
        'message': 'Login successful.',
      };
    } catch (e) {
      debugPrint('Firebase Auth login error: $e');
      String errorMessage = 'Login failed. Please check your credentials.';
      
      if (e.toString().contains('invalid-credentials')) {
        errorMessage = 'Invalid email or password. Please check your credentials.';
      } else if (e.toString().contains('user-not-found')) {
        errorMessage = 'User not found. Please register first.';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Incorrect password. Please try again.';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      await currentUser?.reload();
      if (currentUser?.emailVerified == true) {
        // Update user document
        await _firestore
            .collection(FirebaseCollections.users)
            .doc(currentUser!.uid)
            .update({'emailVerified': true});
        
        await _loadUserModel(currentUser!.uid);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  Future<void> resendEmailVerification() async {
    await currentUser?.sendEmailVerification();
  }

  Future<void> signOut() async {
    try {
    await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
    _currentUserModel = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
