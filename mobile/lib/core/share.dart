import 'package:flutter/services.dart';

const _channel = MethodChannel('vegukin/share');

/// Android's share sheet with [text]: Telegram, WhatsApp, messages, copy.
Future<void> shareText(String text) async {
  try {
    await _channel.invokeMethod<void>('text', text);
  } on PlatformException catch (_) {
  } on MissingPluginException catch (_) {}
}
