import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _emergencyNotificationId = 1001;
  static const String _emergencyChannelId = 'emergency_silent';
  static const String _inviteChannelId = 'invite_alerts';

  static const AndroidNotificationChannel _androidEmergencyChannel =
      AndroidNotificationChannel(
        _emergencyChannelId,
        'Emergency Silent Alerts',
        description: 'Silent ongoing notifications for emergency mode',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      );

  // High-importance channel for audible, popup alerts (e.g., invitations)
  static const AndroidNotificationChannel _androidInviteChannel =
      AndroidNotificationChannel(
        _inviteChannelId,
        'Invitation Alerts',
        description: 'Sound and popup notifications for invitations',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

  static Future<void> initialize() async {
    // Android init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS init
    final darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
      defaultPresentAlert: false,
      defaultPresentSound: false,
      defaultPresentBadge: false,
    );

    // Initialize plugin; do not navigate on tap — let OS resume the app
    await _plugin.initialize(
      InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    // Create Android channel
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidEmergencyChannel);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidInviteChannel);

    // Request permissions where required
    if (!kIsWeb && Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, sound: true, badge: true);
    } else if (!kIsWeb && Platform.isAndroid) {
      // Use permission_handler for Android 13+ notification permission
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }

    // Do not force navigation on cold-start; app should open normally
  }

  static Future<void> silentNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _emergencyChannelId,
      'Emergency Silent Alerts',
      channelDescription: 'Silent ongoing notifications for emergency mode',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      ongoing: true,
      autoCancel: false,
      category: AndroidNotificationCategory.service,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentSound: false,
      presentBadge: false,
    );

    await _plugin.show(
      _emergencyNotificationId,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  // Sound + popup notification for invitations (and similar alerts)
  static Future<void> invitationNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _inviteChannelId,
      'Invitation Alerts',
      channelDescription: 'Sound and popup notifications for invitations',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.call,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    // Use a distinct ID so this doesn't override the emergency notification
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000, // simple unique id
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  static Future<void> cancelEmergencyNotification() async {
    await _plugin.cancel(_emergencyNotificationId);
  }
}
