import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kiftari2_updates',
    'KifTari2 Updates',
    description: 'Report updates and account notifications',
    importance: Importance.high,
  );

  static bool _initialized = false;
  static const String _prefsKey = "notifications";

  static Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await FirebaseMessaging.instance.requestPermission();
    final enabled = await _isEnabled();
    await FirebaseMessaging.instance.setAutoInitEnabled(enabled);
    if (!enabled) {
      await FirebaseMessaging.instance.deleteToken();
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {});

    _initialized = true;
  }

  static Future<String?> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
    await FirebaseMessaging.instance.setAutoInitEnabled(enabled);
    if (!enabled) {
      await FirebaseMessaging.instance.deleteToken();
      return null;
    }
    return FirebaseMessaging.instance.getToken();
  }

  static Future<bool> _isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? true;
  }

  static Future<String?> getToken() async {
    await initialize();
    if (!await _isEnabled()) {
      return null;
    }
    return FirebaseMessaging.instance.getToken();
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    if (!await _isEnabled()) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = const DarwinNotificationDetails();

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }
}
