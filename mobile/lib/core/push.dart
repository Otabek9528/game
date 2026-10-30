import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

  /// Whether notifications are allowed now: the person may have changed it
  /// in the phone's settings since [start]. False too when the app's
  /// "alerts" channel is muted: allowed, but nothing would show.
  Future<bool> isAllowed();
}

/// The test notification's data: it says it arrived (see AccountController).
bool isTestPush(PushMessage message) => message.data['kind'] == 'test';

/// The Firebase project's Android app (from google-services.json). Read by
/// the app at start instead of by Gradle, so the build needs no Google
/// plugin. None of it is secret: every installed copy carries it.
const firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyDeN7pAJJHnKik9bxL_5VBngoiM-OwU0wg',
  appId: '1:450113929398:android:c0e2df0a8a65abd04aa617',
  messagingSenderId: '450113929398',
  projectId: 'muslim-vegukin',
  storageBucket: 'muslim-vegukin.firebasestorage.app',
);

/// The Firebase project's iOS app (GoogleService-Info.plist: API_KEY and
/// GOOGLE_APP_ID), once it is registered (mobile/ios/IOS.md). Empty: no push
/// on iPhone yet, and the app works on without it.
const firebaseIosApiKey = '';
const firebaseIosAppId = '';

/// The options for this platform; null on an iPhone until the iOS app is set.
FirebaseOptions? get platformFirebaseOptions {
  if (defaultTargetPlatform != TargetPlatform.iOS) return firebaseOptions;
  if (firebaseIosAppId.isEmpty) return null;
  return FirebaseOptions(
    apiKey: firebaseIosApiKey,
    appId: firebaseIosAppId,
    messagingSenderId: firebaseOptions.messagingSenderId,
    projectId: firebaseOptions.projectId,
    storageBucket: firebaseOptions.storageBucket,
    iosBundleId: 'com.vegukin.muslimVegukin',
  );
}

class FirebasePushService implements PushService {
  FirebasePushService();

  final _subscriptions = <StreamSubscription<Object?>>[];

  /// MainActivity's: whether the "alerts" channel shows, and showing one.
  static const _alerts = MethodChannel('vegukin/alerts');

  static Future<bool> _channelShown() async {
    try {
      return await _alerts.invokeMethod<bool>('shown') ?? true;
    } on PlatformException catch (_) {
      return true;
    } on MissingPluginException catch (_) {
      return true;
    }
  }

  /// One arrived while the app is open, which Android doesn't show. The
  /// test is shown as a real notification, so the person sees what one
  /// looks like (and that the channel isn't muted).
  static void _arrived(RemoteMessage m, PushArrived onForeground) {
    final message = _message(m);
    if (isTestPush(message)) {
      unawaited(
        _alerts.invokeMethod<void>('show', {'title': message.title, 'body': message.body}).catchError((Object _) {}),
      );
    }
    onForeground(message);
  }

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
      final options = platformFirebaseOptions;
      if (options == null) return false;
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: options);
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      final allowed =
          (settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional) &&
          await _channelShown();
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
        ..add(FirebaseMessaging.onMessage.listen((m) => _arrived(m, onForeground)))
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

  @override
  Future<bool> isAllowed() async {
    try {
      if (Firebase.apps.isEmpty) return false;
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return (settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional) &&
          await _channelShown();
    } catch (e) {
      return false;
    }
  }
}
