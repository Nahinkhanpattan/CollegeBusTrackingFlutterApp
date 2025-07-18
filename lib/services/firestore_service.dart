import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:college_bus_tracker/models/user_model.dart';
import 'package:college_bus_tracker/models/bus_model.dart';
import 'package:college_bus_tracker/models/college_model.dart';
import 'package:college_bus_tracker/models/notification_model.dart';
import 'package:college_bus_tracker/utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    return _firestore
        .collection(FirebaseCollections.users)
        .where('role', isEqualTo: role.value)
        .where('collegeId', isEqualTo: collegeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<UserModel>> getPendingApprovals(String collegeId) {
    return _firestore
        .collection(FirebaseCollections.users)
        .where('collegeId', isEqualTo: collegeId)
        .where('needsManualApproval', isEqualTo: true)
        .where('approved', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
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
    return _firestore
        .collection(FirebaseCollections.colleges)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CollegeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Bus operations
  Future<void> createBus(BusModel bus) async {
    await _firestore
        .collection(FirebaseCollections.buses)
        .doc(bus.id)
        .set(bus.toMap());
  }

  Future<void> updateBus(String busId, Map<String, dynamic> data) async {
    await _firestore
        .collection(FirebaseCollections.buses)
        .doc(busId)
        .update(data);
  }

  Stream<List<BusModel>> getBusesByCollege(String collegeId) {
    return _firestore
        .collection(FirebaseCollections.buses)
        .where('collegeId', isEqualTo: collegeId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BusModel.fromMap(doc.data(), doc.id))
            .toList());
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
      throw Exception('Error fetching bus: $e');
    }
  }

  // Bus location operations
  Future<void> updateBusLocation(String busId, BusLocationModel location) async {
    await _firestore
        .collection(FirebaseCollections.busLocations)
        .doc(busId)
        .set(location.toMap());
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
    await _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .update({
          'approved': true,
          'needsManualApproval': false,
          'approverId': approverId,
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }

  Future<void> rejectUser(String userId, String approverId) async {
    await _firestore
        .collection(FirebaseCollections.users)
        .doc(userId)
        .update({
          'approved': false,
          'needsManualApproval': false,
          'approverId': approverId,
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }
}