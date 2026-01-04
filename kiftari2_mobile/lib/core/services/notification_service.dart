import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/report_service.dart';
import '../../core/services/token_service.dart';
import '../../features/field_operator/details/field_operator_report_details_screen.dart';
import '../../features/reports/details/report_details_screen.dart';

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
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleRemoteMessage(message);
    });

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationPayload(response.payload);
      },
    );
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

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await _handleRemoteMessage(initialMessage);
    }

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
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }

  static Future<void> _handleRemoteMessage(RemoteMessage message) async {
    if (message.data.isEmpty) return;
    await _handleNotificationData(message.data);
  }

  static Future<void> _handleNotificationPayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        final data = decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        await _handleNotificationData(data);
      }
    } catch (_) {}
  }

  static Future<void> _handleNotificationData(
    Map<String, dynamic> data,
  ) async {
    final reportId = data["reportId"]?.toString();
    if (reportId == null || reportId.isEmpty) return;

    final nav = await _waitForNavigator();
    if (nav == null) return;

    final role = await TokenService.getRole();
    if (role == "field_operator") {
      nav.push(
        MaterialPageRoute(
          builder: (_) => FieldOperatorReportDetailsScreen(
            reportId: reportId,
          ),
        ),
      );
      return;
    }

    try {
      final report = await ReportService.getReportById(reportId);
      if (!report.containsKey("municipality") &&
          report["municipalityId"] != null) {
        report["municipality"] = report["municipalityId"];
      }
      nav.push(
        MaterialPageRoute(
          builder: (_) => ReportDetailsScreen(report: report),
        ),
      );
    } catch (_) {}
  }

  static Future<NavigatorState?> _waitForNavigator() async {
    for (var i = 0; i < 5; i += 1) {
      final nav = appNavigatorKey.currentState;
      if (nav != null) return nav;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return null;
  }
}
