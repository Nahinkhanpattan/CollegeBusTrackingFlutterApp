import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request notification permissions
    await _requestPermissions();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Configure Firebase messaging
    await _configureFCM();
  }

  static Future<void> _requestPermissions() async {
    // Request FCM permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Request local notification permissions
    await Permission.notification.request();
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  static Future<void> _configureFCM() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Handle notification taps when app is terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Check for initial message when app is opened from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    
    // Show local notification when app is in foreground
    await _showLocalNotification(
      title: message.notification?.title ?? 'Bus Tracker',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message - implementation will be added in future updates
  }

  static void _handleNotificationTap(RemoteMessage message) {
    // Handle notification tap - implementation will be added in future updates
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle local notification tap - implementation will be added in future updates
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'bus_tracker_channel',
      'Bus Tracker Notifications',
      channelDescription: 'Notifications for bus tracking updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<String?> getDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      return null;
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      // Topic subscription failed, but app can continue
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      // Topic unsubscription failed, but app can continue
    }
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String receiverToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // This would typically be done through a cloud function
    // For now, we'll just show a local notification
    await _showLocalNotification(
      title: title,
      body: body,
      payload: data?.toString(),
    );
  }
}