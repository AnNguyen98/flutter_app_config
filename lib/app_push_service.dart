import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppPushService {
  AppPushService._();

  static final _instance = AppPushService._();

  factory AppPushService() => _instance;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late AndroidNotificationChannel notificationChannel;

  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      log('User granted provisional permission');
    } else {
      log('User declined or has not accepted permission');
    }

    if (Platform.isIOS) {
      messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    if (Platform.isAndroid) {
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      notificationChannel = const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
      );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(notificationChannel);

      const initializationSettingsAndroid = AndroidInitializationSettings(
        'ic_notification',
      );
      var initializationSettings = const InitializationSettings(
        android: initializationSettingsAndroid,
      );
      flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onSelectNotification: onSelectNotification,
      );
    }

    _setupToken();

    FirebaseMessaging.onMessage.listen((message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
      }
      if (Platform.isAndroid) {
        _handleShowNotificationOnForegroundAndroid(message);
      }
    });

    FirebaseMessaging.onBackgroundMessage(
      (message) async => {
        log('onBackgroundMessage ${message.data}'),
      },
    );
  }

  void onSelectNotification(String? payload) {
    log('onSelectNotification $payload');
  }

  void _handleShowNotificationOnForegroundAndroid(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // If `onMessage` is triggered with a notification, construct our own
    // local notification to show to users using the created channel.

    if (android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification?.title,
        notification?.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannel.id,
            notificationChannel.name,
            channelDescription: notificationChannel.description,
            icon: 'ic_notification',
            priority: Priority.high,
            // other properties...
          ),
        ),
      );
    }
  }

  Future<void> _setupToken() async {
    // Get the token each time the application loads
    String? token = await FirebaseMessaging.instance.getToken();
    log('Token:  $token');

    // final deviceToken = await FirebaseMessaging.instance.getAPNSToken();
    // log('getAPNSToken $deviceToken');

    // Save the initial token to the database
    await _saveTokenToDatabase(token!);
    // Any time the token refreshes, store this in the database too.

    // Send fcm token to server
  }

  Future<void> _saveTokenToDatabase(String token) async {}

  Future<RemoteMessage?> getInitialMessage() async {
    return FirebaseMessaging.instance.getInitialMessage();
  }
}
