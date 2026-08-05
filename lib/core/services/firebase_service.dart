import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/api_client.dart';
import '../../firebase_options.dart';

// ← Clé VAPID web, obligatoire pour les notifications push sur navigateur.
// Firebase Console > Project Settings > Cloud Messaging > Web Push certificates
// (génère une paire de clés si aucune n'existe encore) — copie la "clé publique".
const String _webVapidKey = 'BNwjmJF3Qbzz0N3m7EskwE2jqeeCgj29pPnS6gzlaIM94La3OCwcaTKAClkwzvaUaaJQLDUmr0XE8Qf7uExisno';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

    // flutter_local_notifications n'a pas d'implémentation web — sur web, les
    // notifications passent uniquement par le service worker Firebase.
    if (!kIsWeb) {
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
    }

    // Écouter les refresh de token
    _messaging.onTokenRefresh.listen((newToken) {
      apiClient.updateFcmToken(newToken);
    });

    // Notifications en foreground (fonctionne aussi sur web, mais sans popup
    // système natif — flutter_local_notifications gère ça sur mobile seulement)
    FirebaseMessaging.onMessage.listen((message) {
      if (!kIsWeb) _showLocalNotification(message);
    });

    // Background handler (mobile uniquement ; sur web c'est le service worker
    // firebase-messaging-sw.js qui prend le relais quand l'onglet est fermé)
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  }

  // ← Appelé après login/register/check — envoie le token FCM au backend
  static Future<void> onLogin(ApiClient apiClient) async {
    try {
      final settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

      // Sur web, getToken() exige la clé VAPID ; sur mobile elle est ignorée.
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? _webVapidKey : null,
      );
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