import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  /// Initialize the notification service
  Future<void> initialize() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          onDidReceiveLocalNotification: onDidReceiveLocalNotification,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onSelectNotification,
    );

    // iOS/macOS permission requests can be handled here if needed.
    // Removed explicit Darwin plugin call to avoid analyzer issues
    // with platform-specific types in this build environment.
  }

  /// Handle notification when app is in foreground (iOS)
  Future<void> onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    // Handle the notification
  }

  /// Handle notification tap
  void onSelectNotification(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('Notification payload: $payload');
    }
  }

  /// Show temperature alert notification
  Future<void> showTemperatureAlert(double temperature) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'temperature_alert_channel',
          'Temperature Alerts',
          channelDescription: 'Alerts for temperature threshold exceeded',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
          enableVibration: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      1,
      'Alerte Température',
      'Température élevée détectée: ${temperature.toStringAsFixed(1)}°C',
      platformChannelSpecifics,
      payload: 'temperature_alert',
    );
  }

  /// Show emergency alert notification
  Future<void> showEmergencyAlert() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'emergency_alert_channel',
          'Emergency Alerts',
          channelDescription: 'Emergency signal from wearable device',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      2,
      'Alerte Urgence',
      'Signal d\'urgence activé!',
      platformChannelSpecifics,
      payload: 'emergency_alert',
    );
  }

  /// Show info notification
  Future<void> showInfoNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'info_channel',
          'Informations',
          channelDescription: 'Information notifications',
          importance: Importance.low,
          priority: Priority.low,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      3,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Cancel a notification
  Future<void> cancel(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
