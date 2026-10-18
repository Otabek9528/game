import 'package:flutter/services.dart';

/// An app on the phone: its package and launcher icon (PNG).
class InstalledApp {
  const InstalledApp(this.package, this.icon);

  final String package;
  final Uint8List? icon;
}

/// This phone and the app, for a bug report.
class DeviceInfo {
  const DeviceInfo({required this.phone, required this.android, required this.version});

  /// "samsung SM-S906N".
  final String phone;
  final String android;

  /// "1.0.0 (1)".
  final String version;
}

/// Other apps on the phone, and the phone itself.
abstract interface class SystemBridge {
  /// Which of [packages] are installed and can be opened.
  Future<List<InstalledApp>> installedApps(List<String> packages);

  /// False when it isn't installed.
  Future<bool> openApp(String package);

  Future<DeviceInfo?> device();
}

class AndroidSystem implements SystemBridge {
  const AndroidSystem();

  static const _channel = MethodChannel('vegukin/system');

  @override
  Future<List<InstalledApp>> installedApps(List<String> packages) async {
    try {
      final found = await _channel.invokeListMethod<Map>('installed', packages) ?? const [];
      return [for (final app in found) InstalledApp('${app['package']}', app['icon'] as Uint8List?)];
    } on PlatformException catch (_) {
      return const [];
    } on MissingPluginException catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> openApp(String package) async {
    try {
      return await _channel.invokeMethod<bool>('open', package) ?? false;
    } on PlatformException catch (_) {
      return false;
    } on MissingPluginException catch (_) {
      return false;
    }
  }

  @override
  Future<DeviceInfo?> device() async {
    try {
      final info = await _channel.invokeMapMethod<String, Object?>('device');
      if (info == null) return null;
      return DeviceInfo(
        phone: '${info['manufacturer']} ${info['model']}',
        android: '${info['android']}',
        version: '${info['version']}',
      );
    } on PlatformException catch (_) {
      return null;
    } on MissingPluginException catch (_) {
      return null;
    }
  }
}
