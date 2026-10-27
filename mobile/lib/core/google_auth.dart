import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google's account picker, for the server's Google sign-in.
abstract interface class GoogleAuth {
  /// A Google ID token for the server, or null when the person closed the picker.
  Future<String?> idToken();

  Future<void> signOut();
}

/// The Firebase project's OAuth web client (google-services.json,
/// client_type 3). Google issues the ID token for it, and the server checks
/// that it did (APP_GOOGLE_CLIENT_IDS).
const googleServerClientId = '450113929398-oalac2gbfr1mv2b30593anj5djstph7u.apps.googleusercontent.com';

/// The iOS OAuth client (GoogleService-Info.plist: CLIENT_ID), once the iOS
/// app is registered (mobile/ios/IOS.md). Its reversed form is also a URL
/// scheme in ios/Runner/Info.plist. Empty: no Google sign-in on iPhone yet.
const googleIosClientId = '';

/// Whether this platform can offer Google sign-in.
bool get googleSignInAvailable => defaultTargetPlatform != TargetPlatform.iOS || googleIosClientId.isNotEmpty;

class GoogleSignInAuth implements GoogleAuth {
  GoogleSignInAuth();

  Future<void>? _ready;

  Future<void> _init() => _ready ??= GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS ? googleIosClientId : null,
        serverClientId: googleServerClientId,
      );

  @override
  Future<String?> idToken() async {
    await _init();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      debugPrint('Google sign-in failed: ${e.code} ${e.description}');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _init();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Nothing to sign out of.
    }
  }
}
