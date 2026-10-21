import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// A notification from the server: what it said, and what to open.
@immutable
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;

  /// `url`: a web page of the app (a place, the notifications page);
  /// `kind`: what it is about (`hikorea`).
  final Map<String, String> data;
}

typedef PushOpened = void Function(PushMessage message);
typedef PushArrived = void Function(PushMessage message);

/// Push notifications to this phone.
abstract interface class PushService {
  /// Asks to show notifications (once; Android 13+ shows a prompt), then
  /// reports this phone's token, now and whenever it changes. Returns whether
  /// notifications are allowed.
  Future<bool> start({
    required void Function(String token) onToken,
    required PushOpened onOpen,
    required PushArrived onForeground,
  });
}

/// The Firebase project's Android app (from google-services.json). Read by
/// the app at start instead of by Gradle, so the build needs no Google
/// plugin. None of it is secret: every installed copy carries it.
const firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyDeN7pAJJHnKik9bxL_5VBngoiM-OwU0wg',
  appId: '1:450113929398:android:016bc085ad55d7064aa617',
  messagingSenderId: '450113929398',
  projectId: 'muslim-vegukin',
  storageBucket: 'muslim-vegukin.firebasestorage.app',
);

class FirebasePushService implements PushService {
  FirebasePushService();

  final _subscriptions = <StreamSubscription<Object?>>[];

  static PushMessage _message(RemoteMessage m) => PushMessage(
        title: m.notification?.title,
        body: m.notification?.body,
        data: {for (final e in m.data.entries) e.key: '${e.value}'},
      );

  @override
  Future<bool> start({
    required void Function(String token) onToken,
    required PushOpened onOpen,
    required PushArrived onForeground,
  }) async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: firebaseOptions);
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      final allowed = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      for (final s in _subscriptions) {
        unawaited(s.cancel());
      }
      // The classic registration token, which the server's FCM v1 sends
      // (message.token) are addressed to. firebase_messaging 17 deprecates it
      // for installation-id "direct send"; switch when the server does.
      _subscriptions
        ..clear()
        // ignore: deprecated_member_use
        ..add(messaging.onTokenRefresh.listen(onToken))
        ..add(FirebaseMessaging.onMessage.listen((m) => onForeground(_message(m))))
        ..add(FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpen(_message(m))));
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) onToken(token);
      // Opened by tapping a notification while the app was closed.
      final initial = await messaging.getInitialMessage();
      if (initial != null) onOpen(_message(initial));
      return allowed;
    } catch (e) {
      // No Google Play services, or no network for the first token: the app
      // works on without notifications.
      debugPrint('Push unavailable: $e');
      return false;
    }
  }
}
