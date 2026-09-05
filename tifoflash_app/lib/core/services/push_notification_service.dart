import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Background message handler for terminated/background FCM notifications
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] Lockscreen notification received: ${message.notification?.title}');
}

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      // 1. Request Notification Permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      // Enable Foreground Presentation for iOS (shows banner, sound, badge even if app is open)
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. Register Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Subscribe to Stadium Topics so all fans get broadcast notifications
      await _fcm.subscribeToTopic('all_fans');
      await _fcm.subscribeToTopic('match_2026_final');
      await _fcm.subscribeToTopic('stadium_all');

      // 4. Handle Foreground Messages (if app is open)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Push received: ${message.notification?.title} - ${message.notification?.body}');
      });

      // 5. Get FCM Token for testing (debug only)
      if (kDebugMode) {
        String? token = await _fcm.getToken();
        debugPrint('[FCM Token] $token');
      }
    } catch (e) {
      debugPrint('[FCM Error] Failed to initialize push notifications: $e');
    }
  }
}
