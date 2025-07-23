import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/models/notification_model.dart';
import 'package:collegebus/utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Mock data for testing without Firebase
  static final List<BusModel> _mockBuses = [
    BusModel(
      id: 'bus_001',
      busNumber: 'BUS-001',
      driverId: 'mock_driver',
      collegeId: 'test_college',
      startPoint: 'Central Station',
      endPoint: 'University Campus',
      stopPoints: ['City Center', 'Shopping Mall', 'Hospital'],
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    BusModel(
      id: 'bus_002',
      busNumber: 'BUS-002',
      driverId: 'mock_driver2',
      collegeId: 'test_college',
      startPoint: 'Airport',
      endPoint: 'University Campus',
      stopPoints: ['Hotel District', 'Business Park'],
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    BusModel(
      id: 'bus_003',
      busNumber: 'BUS-003',
      driverId: 'mock_driver3',
      collegeId: 'test_college',
      startPoint: 'Suburban Area',
      endPoint: 'University Campus',
      stopPoints: ['Residential Area', 'Park'],
      isActive: false,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];
  
  static final List<CollegeModel> _mockColleges = [
    CollegeModel(
      id: 'test_college',
      name: 'Test University',
      allowedDomains: ['test.com', 'test.edu'],
      verified: true,
      createdBy: 'mock_admin',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    CollegeModel(
      id: 'another_college',
      name: 'Another University',
      allowedDomains: ['another.edu'],
      verified: false,
      createdBy: 'mock_admin',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];
  
  static final List<UserModel> _mockUsers = [
    UserModel(
      id: 'mock_driver',
      fullName: 'Mike Driver',
      email: 'driver@test.com',
      role: UserRole.driver,
      collegeId: 'test_college',
      approved: true,
      emailVerified: true,
      needsManualApproval: false,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    UserModel(
      id: 'mock_driver2',
      fullName: 'John Driver',
      email: 'driver2@test.com',
      role: UserRole.driver,
      collegeId: 'test_college',
      approved: true,
      emailVerified: true,
      needsManualApproval: false,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    UserModel(
      id: 'mock_driver3',
      fullName: 'Sarah Driver',
      email: 'driver3@test.com',
      role: UserRole.driver,
      collegeId: 'test_college',
      approved: false,
      emailVerified: true,
      needsManualApproval: true,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  // User operations
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, userId);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .update(data);
  }

  Stream<List<UserModel>> getUsersByRole(UserRole role, String collegeId) {
    try {
    return _firestore
        .collection(FirebaseCollections.users)
        .where('role', isEqualTo: role.value)
        .where('collegeId', isEqualTo: collegeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
    } catch (e) {
      // Return mock data if Firebase is not available
      return Stream.value(_mockUsers.where((user) => 
        user.role == role && 
        user.collegeId == collegeId
      ).toList());
    }
  }
  
  Stream<List<UserModel>> getAllUsers() {
    try {
      return _firestore
          .collection(FirebaseCollections.users)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      // Return mock data if Firebase is not available
      return Stream.value(_mockUsers);
    }
  }

  Stream<List<UserModel>> getPendingApprovals(String collegeId) {
    try {
    return _firestore
        .collection(FirebaseCollections.users)
        .where('collegeId', isEqualTo: collegeId)
        .where('needsManualApproval', isEqualTo: true)
        .where('approved', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
    } catch (e) {
      // Return mock data if Firebase is not available
      return Stream.value(_mockUsers.where((user) => 
        user.collegeId == collegeId && 
        user.needsManualApproval && 
        !user.approved
      ).toList());
    }
  }

  // College operations
  Future<CollegeModel?> getCollege(String collegeId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.colleges)
          .doc(collegeId)
          .get();
      
      if (doc.exists) {
        return CollegeModel.fromMap(doc.data()!, collegeId);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching college: $e');
    }
  }

  Stream<List<CollegeModel>> getAllColleges() {
    try {
    return _firestore
        .collection(FirebaseCollections.colleges)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CollegeModel.fromMap(doc.data(), doc.id))
            .toList());
    } catch (e) {
      // Return mock data if Firebase is not available
      return Stream.value(_mockColleges);
    }
  }

  // Bus operations
  Future<void> createBus(BusModel bus) async {
    try {
    await _firestore
        .collection(FirebaseCollections.buses)
        .doc(bus.id)
        .set(bus.toMap());
    } catch (e) {
      // In mock mode, just add to mock data
      _mockBuses.add(bus);
    }
  }

  Future<void> updateBus(String busId, Map<String, dynamic> data) async {
    try {
    await _firestore
        .collection(FirebaseCollections.buses)
        .doc(busId)
        .update(data);
    } catch (e) {
      // In mock mode, update mock data
      final index = _mockBuses.indexWhere((bus) => bus.id == busId);
      if (index != -1) {
        final updatedBus = _mockBuses[index].copyWith(
          busNumber: data['busNumber'] ?? _mockBuses[index].busNumber,
          startPoint: data['startPoint'] ?? _mockBuses[index].startPoint,
          endPoint: data['endPoint'] ?? _mockBuses[index].endPoint,
          stopPoints: data['stopPoints'] ?? _mockBuses[index].stopPoints,
          isActive: data['isActive'] ?? _mockBuses[index].isActive,
          updatedAt: DateTime.now(),
        );
        _mockBuses[index] = updatedBus;
      }
    }
  }

  Stream<List<BusModel>> getBusesByCollege(String collegeId) {
    try {
    return _firestore
        .collection(FirebaseCollections.buses)
        .where('collegeId', isEqualTo: collegeId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BusModel.fromMap(doc.data(), doc.id))
            .toList());
    } catch (e) {
      debugPrint('Firebase not available, using mock data: $e');
      // Return mock data if Firebase is not available
      return Stream.value(_mockBuses.where((bus) => bus.collegeId == collegeId).toList());
    }
  }

  Future<BusModel?> getBusByDriver(String driverId) async {
    try {
      final query = await _firestore
          .collection(FirebaseCollections.buses)
          .where('driverId', isEqualTo: driverId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return BusModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      // Return mock data if Firebase is not available
      final mockBus = _mockBuses.where((bus) => 
        bus.driverId == driverId && bus.isActive
      ).firstOrNull;
      return mockBus;
    }
  }

  // Bus location operations
  Future<void> updateBusLocation(String busId, BusLocationModel location) async {
    try {
    await _firestore
        .collection(FirebaseCollections.busLocations)
        .doc(busId)
        .set(location.toMap());
    } catch (e) {
      // In mock mode, just ignore location updates
      // This prevents crashes when Firebase is not configured
    }
  }

  Stream<BusLocationModel?> getBusLocation(String busId) {
    return _firestore
        .collection(FirebaseCollections.busLocations)
        .doc(busId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return BusLocationModel.fromMap(snapshot.data()!, busId);
          }
          return null;
        });
  }

  // Notification operations
  Future<void> sendNotification(NotificationModel notification) async {
    await _firestore
        .collection(FirebaseCollections.notifications)
        .add(notification.toMap());
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection(FirebaseCollections.notifications)
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection(FirebaseCollections.notifications)
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Approval operations
  Future<void> approveUser(String userId, String approverId) async {
    try {
    await _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .update({
          'approved': true,
          'needsManualApproval': false,
          'approverId': approverId,
          'updatedAt': DateTime.now().toIso8601String(),
        });
    } catch (e) {
      // In mock mode, update mock data
      final index = _mockUsers.indexWhere((user) => user.id == userId);
      if (index != -1) {
        final updatedUser = _mockUsers[index].copyWith(
          approved: true,
          needsManualApproval: false,
          approverId: approverId,
          updatedAt: DateTime.now(),
        );
        _mockUsers[index] = updatedUser;
      }
    }
  }

  Future<void> rejectUser(String userId, String approverId) async {
    try {
    await _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .update({
          'approved': false,
          'needsManualApproval': false,
          'approverId': approverId,
          'updatedAt': DateTime.now().toIso8601String(),
        });
    } catch (e) {
      // In mock mode, update mock data
      final index = _mockUsers.indexWhere((user) => user.id == userId);
      if (index != -1) {
        final updatedUser = _mockUsers[index].copyWith(
          approved: false,
          needsManualApproval: false,
          approverId: approverId,
          updatedAt: DateTime.now(),
        );
        _mockUsers[index] = updatedUser;
      }
    }
  }
}
