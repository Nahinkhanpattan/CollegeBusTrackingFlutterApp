import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collegebus/models/user_model.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/models/college_model.dart';
import 'package:collegebus/models/notification_model.dart';
import 'package:collegebus/models/schedule_model.dart';
import 'package:collegebus/utils/constants.dart';

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
      throw Exception('Error fetching users by role: $e');
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
      throw Exception('Error fetching all users: $e');
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
      throw Exception('Error fetching pending approvals: $e');
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
      throw Exception('Error fetching all colleges: $e');
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
      throw Exception('Error creating bus: $e');
    }
  }

  Future<void> updateBus(String busId, Map<String, dynamic> data) async {
    try {
    await _firestore
        .collection(FirebaseCollections.buses)
        .doc(busId)
        .update(data);
    } catch (e) {
      throw Exception('Error updating bus: $e');
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
      return Stream.value([]); // No mock data, return empty stream
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
      throw Exception('Error fetching bus by driver: $e');
    }
  }

  // Route operations
  Future<void> createRoute(RouteModel route) async {
    try {
      await _firestore
          .collection(FirebaseCollections.routes)
          .doc(route.id)
          .set(route.toMap());
    } catch (e) {
      throw Exception('Error creating route: $e');
    }
  }

  Future<void> updateRoute(String routeId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(FirebaseCollections.routes)
          .doc(routeId)
          .update(data);
    } catch (e) {
      throw Exception('Error updating route: $e');
    }
  }

  Stream<List<RouteModel>> getRoutesByCollege(String collegeId) {
    try {
      return _firestore
          .collection(FirebaseCollections.routes)
          .where('collegeId', isEqualTo: collegeId)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => RouteModel.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      throw Exception('Error fetching routes by college: $e');
    }
  }

  Future<void> deleteRoute(String routeId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.routes)
          .doc(routeId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Error deleting route: $e');
    }
  }

  // Schedule operations
  Future<void> createSchedule(ScheduleModel schedule) async {
    try {
      await _firestore
          .collection(FirebaseCollections.schedules)
          .doc(schedule.id)
          .set(schedule.toMap());
    } catch (e) {
      throw Exception('Error creating schedule: $e');
    }
  }

  Future<void> updateSchedule(String scheduleId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(FirebaseCollections.schedules)
          .doc(scheduleId)
          .update(data);
    } catch (e) {
      throw Exception('Error updating schedule: $e');
    }
  }

  Stream<List<ScheduleModel>> getSchedulesByCollege(String collegeId) {
    try {
      return _firestore
          .collection(FirebaseCollections.schedules)
          .where('collegeId', isEqualTo: collegeId)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ScheduleModel.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      throw Exception('Error fetching schedules by college: $e');
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.schedules)
          .doc(scheduleId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Error deleting schedule: $e');
    }
  }

  // Bus number operations
  Future<void> addBusNumber(String collegeId, String busNumber) async {
    try {
      await _firestore
          .collection(FirebaseCollections.busNumbers)
          .doc('${collegeId}_$busNumber')
          .set({
        'busNumber': busNumber,
        'collegeId': collegeId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error adding bus number: $e');
    }
  }

  Future<void> removeBusNumber(String collegeId, String busNumber) async {
    try {
      await _firestore
          .collection(FirebaseCollections.busNumbers)
          .doc('${collegeId}_$busNumber')
          .delete();
    } catch (e) {
      throw Exception('Error removing bus number: $e');
    }
  }

  Stream<List<String>> getBusNumbers(String collegeId) {
    try {
      return _firestore
          .collection(FirebaseCollections.busNumbers)
          .where('collegeId', isEqualTo: collegeId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => doc.data()['busNumber'] as String)
              .toList());
    } catch (e) {
      return Stream.value([]);
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
      throw Exception('Error updating bus location: $e');
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
    try {
    await _firestore
        .collection(FirebaseCollections.notifications)
        .add(notification.toMap());
    } catch (e) {
      throw Exception('Error sending notification: $e');
    }
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    try {
    return _firestore
        .collection(FirebaseCollections.notifications)
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
    await _firestore
        .collection(FirebaseCollections.notifications)
        .doc(notificationId)
        .update({'isRead': true});
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
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
      throw Exception('Error approving user: $e');
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
      throw Exception('Error rejecting user: $e');
    }
  }
}