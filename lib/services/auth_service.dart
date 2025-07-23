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

  // Mock authentication for testing without Firebase
  bool _isMockMode = true;
  bool get isMockMode => _isMockMode;

  // Dummy credentials for testing
  static const Map<String, Map<String, dynamic>> _dummyUsers = {
    'student@test.com': {
      'password': '123456',
      'fullName': 'John Student',
      'role': UserRole.student,
      'collegeId': 'test_college',
      'approved': true,
      'emailVerified': true,
    },
    'teacher@test.com': {
      'password': '123456',
      'fullName': 'Dr. Sarah Teacher',
      'role': UserRole.teacher,
      'collegeId': 'test_college',
      'approved': true,
      'emailVerified': true,
    },
    'driver@test.com': {
      'password': '123456',
      'fullName': 'Mike Driver',
      'role': UserRole.driver,
      'collegeId': 'test_college',
      'approved': true,
      'emailVerified': true,
    },
    'coordinator@test.com': {
      'password': '123456',
      'fullName': 'Lisa Coordinator',
      'role': UserRole.busCoordinator,
      'collegeId': 'test_college',
      'approved': true,
      'emailVerified': true,
    },
    'admin@test.com': {
      'password': '123456',
      'fullName': 'Admin User',
      'role': UserRole.admin,
      'collegeId': 'test_college',
      'approved': true,
      'emailVerified': true,
    },
  };

  AuthService() {
    try {
      // Check if Firebase is properly configured
      final auth = FirebaseAuth.instance;
    _auth.authStateChanges().listen(_onAuthStateChanged);
      _isMockMode = false; // Use real Firebase
      debugPrint('AuthService: Using real Firebase authentication');
    } catch (e) {
      debugPrint('Firebase Auth not available: $e');
      _isMockMode = true; // Fallback to mock mode
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    try {
      debugPrint('Auth state changed for user: ${user?.email}');
    if (user != null) {
      await _loadUserModel(user.uid);
    } else {
      _currentUserModel = null;
    }
    notifyListeners();
      debugPrint('Auth state change completed');
    } catch (e) {
      debugPrint('Error in _onAuthStateChanged: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _loadUserModel(String uid) async {
    try {
      debugPrint('Loading user model for UID: $uid');
      final doc = await _firestore.collection(FirebaseCollections.users).doc(uid).get();
      debugPrint('Document exists: ${doc.exists}');
      if (doc.exists) {
        final data = doc.data()!;
        debugPrint('User data: $data');
        _currentUserModel = UserModel.fromMap(data, uid);
        debugPrint('User model loaded: ${_currentUserModel?.fullName}');
      } else {
        debugPrint('User document does not exist for UID: $uid');
      }
    } catch (e) {
      debugPrint('Error loading user model: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  // Mock login method
  Future<Map<String, dynamic>> _mockLogin({
    required String email,
    required String password,
  }) async {
    debugPrint('Mock login started for: $email');
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    if (_dummyUsers.containsKey(email)) {
      final userData = _dummyUsers[email]!;
      debugPrint('Found user data: ${userData['fullName']}');
      
      if (userData['password'] == password) {
        debugPrint('Password matches, creating user model');
        
        _currentUserModel = UserModel(
          id: 'mock_${email.split('@').first}',
          fullName: userData['fullName'],
          email: email,
          role: userData['role'],
          collegeId: userData['collegeId'],
          approved: userData['approved'],
          emailVerified: userData['emailVerified'],
          needsManualApproval: false,
          createdAt: DateTime.now(),
        );
        
        debugPrint('User model created: ${_currentUserModel?.fullName}');
        debugPrint('User role: ${_currentUserModel?.role}');
        
        notifyListeners();
        debugPrint('Notified listeners');
        
        return {
          'success': true,
          'message': 'Login successful.',
        };
      } else {
        debugPrint('Password does not match');
      }
    } else {
      debugPrint('User not found in dummy users');
    }
    
    return {
      'success': false,
      'message': 'Invalid email or password.',
    };
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
    if (_isMockMode) {
      // Mock registration
      await Future.delayed(const Duration(seconds: 1));
      return {
        'success': true,
        'needsOtpVerification': false,
        'message': 'Registration successful. You can now login.',
      };
    }

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

      debugPrint('Creating user document for UID: ${user.uid}');
      debugPrint('User model data: ${userModel.toMap()}');
      
      try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .set(userModel.toMap());
        
        debugPrint('User document created successfully');
      } catch (e) {
        debugPrint('Error creating user document: $e');
        debugPrint('Stack trace: ${StackTrace.current}');
        throw e;
      }

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
    if (_isMockMode) {
      return await _mockLogin(email: email, password: password);
    }

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

      // Driver: Only allow login if approved by coordinator
      if (role == UserRole.driver) {
        if (!approved) {
          return {
            'success': false,
            'message': 'Your account is pending approval from the bus coordinator.',
          };
        }
        return {
          'success': true,
          'message': 'Login successful.',
        };
      }

      // Bus Coordinator, Teacher, Student: Check email verification and approval
      if (role == UserRole.busCoordinator || role == UserRole.teacher || role == UserRole.student) {
        if (!emailVerified && !approved) {
          return {
            'success': false,
            'message': 'Please verify your email address first.',
            'needsEmailVerification': true,
          };
        }
        
        if (emailVerified && !needsManualApproval) {
          return {
            'success': true,
            'message': 'Login successful.',
          };
        }
        
        if (approved) {
          return {
            'success': true,
            'message': 'Login successful.',
          };
        }
        
        if (needsManualApproval && !approved) {
          return {
            'success': false,
            'message': 'Your account is pending approval from administrator.',
          };
        }
      }

      // Default fallback
      return {
        'success': false,
        'message': 'Login failed. Unknown user role.',
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
    debugPrint('Signing out user');
    if (_isMockMode) {
      _currentUserModel = null;
      notifyListeners();
      debugPrint('Mock signout completed');
      return;
    }

    try {
    await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
    _currentUserModel = null;
    notifyListeners();
    debugPrint('Firebase signout completed');
  }

  Future<void> resetPassword(String email) async {
    if (_isMockMode) {
      // Mock password reset
      return;
    }
    await _auth.sendPasswordResetEmail(email: email);
  }
}
