import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:college_bus_tracker/models/user_model.dart';
import 'package:college_bus_tracker/models/college_model.dart';
import 'package:college_bus_tracker/utils/constants.dart';
import 'package:college_bus_tracker/services/firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;
  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;
  UserRole? get userRole => _currentUserModel?.role;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      await _loadUserModel(user.uid);
    } else {
      _currentUserModel = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserModel(String uid) async {
    try {
      final doc = await _firestore.collection(FirebaseCollections.users).doc(uid).get();
      if (doc.exists) {
        _currentUserModel = UserModel.fromMap(doc.data()!, uid);
      }
    } catch (e) {
      debugPrint('Error loading user model: $e');
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String collegeName,
    required UserRole role,
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
      );

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .set(userModel.toMap());

      if (!needsManualApproval) {
        // Send email verification
        await user.sendEmailVerification();
        return {
          'success': true,
          'needsOtpVerification': true,
          'message': 'Please check your email for verification code.',
        };
      } else {
        return {
          'success': true,
          'needsOtpVerification': false,
          'message': 'Registration successful. Awaiting approval from administrator.',
        };
      }
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
          'message': 'User profile not found.',
        };
      }

      if (!_currentUserModel!.approved) {
        return {
          'success': false,
          'message': 'Your account is pending approval.',
        };
      }

      if (!_currentUserModel!.emailVerified && !user.emailVerified) {
        return {
          'success': false,
          'message': 'Please verify your email address.',
          'needsEmailVerification': true,
        };
      }

      return {
        'success': true,
        'message': 'Login successful.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<bool> verifyEmail() async {
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
      debugPrint('Error verifying email: $e');
      return false;
    }
  }

  Future<void> resendEmailVerification() async {
    await currentUser?.sendEmailVerification();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUserModel = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}