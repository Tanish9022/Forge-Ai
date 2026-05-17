import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  Future<void> init() async {
    try {
      // In a real app with configured flutterfire, this would be:
      // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await Firebase.initializeApp();
      
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await _requestPermission();
      await _getToken();
      
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
        }
      });
      
    } catch (e) {
      debugPrint('Failed to initialize Firebase Messaging: $e');
    }
  }

  Future<void> _requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _getToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM Token: $token');
      // Here we would typically send this token to our backend
      // await _dio.post('/auth/fcm-token', data: {'token': token});
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }
}
