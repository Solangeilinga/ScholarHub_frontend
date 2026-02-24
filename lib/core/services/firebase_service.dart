import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize(ApiClient apiClient) async {
    // Demander permission
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    // Initialiser notifications locales
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Créer le canal Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'scholarhub', 'ScholarHub Notifications',
          description: 'Notifications ScholarHub',
          importance: Importance.high,
        ));

    // Écouter les refresh de token
    _messaging.onTokenRefresh.listen((newToken) {
      apiClient.updateFcmToken(newToken);
    });

    // Notifications en foreground
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // ← Appelé après login/register/check — envoie le token FCM au backend
  static Future<void> onLogin(ApiClient apiClient) async {
    try {
      final settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

      final token = await _messaging.getToken();
      if (token != null) {
        await apiClient.updateFcmToken(token);
      }
    } catch (e) {
      // Silencieux — ne pas bloquer le login
    }
  }

  // ← Appelé avant logout — supprime le token FCM du backend
  static Future<void> onLogout(ApiClient apiClient) async {
    try {
      await _messaging.deleteToken();
      await apiClient.updateFcmToken(null);
    } catch (e) {
      // Silencieux — ne pas bloquer le logout
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scholarhub', 'ScholarHub Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}