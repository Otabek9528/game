import 'package:url_launcher/url_launcher.dart';

/// Opens a link outside the app: Telegram for t.me, the dialer for tel:,
/// the browser for the rest. Nothing happens when nothing can open it.
Future<void> openExternalLink(Uri uri) async {
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}
