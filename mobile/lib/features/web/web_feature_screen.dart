import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../app_services.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../home/feature_catalog.dart';
import '../prayer/prayer_models.dart';

/// Opens [feature]'s web page inside the app.
void openWebFeature(BuildContext context, Feature feature, AppServices services) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => WebFeatureScreen(feature: feature, services: services),
    ),
  );
}

/// A section of the web app, shown inside the app until it is rebuilt
/// natively.
///
/// The web pages were written for Telegram and talk to it through
/// telegram-web-app.js: its back button, links, pop-ups, vibration. This
/// screen plays Telegram's part, so those keep working here:
///
/// * The page is opened with `#tgWebAppVersion=…`, so the script enables
///   those features instead of treating the page as an old Telegram.
/// * The script sends each request to `window.TelegramWebviewProxy`; the
///   page gets a stand-in that forwards them to this screen
///   ([_onTelegramEvent]), and answers go back through
///   `Telegram.WebView.receiveEvent`.
///
/// What still needs Telegram: anything that signs the user in (posting,
/// reviews, watches). Those pages ask to be opened from the bot.
class WebFeatureScreen extends StatefulWidget {
  const WebFeatureScreen({super.key, required this.feature, required this.services});

  final Feature feature;
  final AppServices services;

  @override
  State<WebFeatureScreen> createState() => _WebFeatureScreenState();
}

/// Version telegram-web-app.js should assume. Below 8.0, so pages use the
/// phone's location directly instead of Telegram's location manager.
const _telegramVersion = '7.10';

/// Installs the stand-in for Telegram's bridge. `VegukinBridge` is the channel
/// this screen adds; it exists from the first line of every page.
const _bridgeScript = '''
(function () {
  if (window.TelegramWebviewProxy || !window.VegukinBridge) return;
  window.TelegramWebviewProxy = {
    postEvent: function (type, data) {
      VegukinBridge.postMessage(JSON.stringify({ type: type, data: data }));
    }
  };
})();
''';

class _WebFeatureScreenState extends State<WebFeatureScreen> {
  late final WebViewController _web;
  late final Uri _base = AppConfig.webBase;

  int _progress = 0;
  bool _failed = false;
  bool _closing = false;

  /// The page has Telegram's back button showing: Back steps inside the page
  /// (closing a sheet, leaving a sub-page) instead of leaving it.
  bool _pageHandlesBack = false;
  bool _canGoBack = false;
  bool _configured = false;

  Uri get _startUrl => _base
      .resolve(widget.feature.path)
      .replace(fragment: 'tgWebAppVersion=$_telegramVersion&tgWebAppPlatform=android');

  @override
  void initState() {
    super.initState();
    _web = WebViewController(onPermissionRequest: _onPermissionRequest)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'VegukinBridge',
        onMessageReceived: (message) => _onTelegramEvent(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigation,
          onPageStarted: (_) {
            _web.runJavaScript(_bridgeScript).catchError((_) {});
            if (mounted) {
              setState(() {
                _failed = false;
                _pageHandlesBack = false;
              });
            }
          },
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onPageFinished: (_) => _afterLoad(),
          onWebResourceError: (error) {
            if ((error.isForMainFrame ?? true) && mounted) setState(() => _failed = true);
          },
        ),
      );

    final android = _web.platform;
    if (android is AndroidWebViewController) {
      android
        ..setMediaPlaybackRequiresUserGesture(false)
        ..setGeolocationPermissionsPromptCallbacks(
          onShowPrompt: (_) async => GeolocationPermissionsResponse(
            allow: await widget.services.prayer.ensureLocationAccess(),
            retain: false,
          ),
        );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configured) return;
    _configured = true;
    _web
      ..setBackgroundColor(VegukinPalette.of(context).page)
      ..loadRequest(_startUrl);
  }

  // ---------------------------------------------------------------- loading

  Future<void> _afterLoad() async {
    if (!mounted) return;
    await _web.runJavaScript(_bridgeScript).catchError((_) {});
    await _web.runJavaScript(_syncScript()).catchError((_) {});
    final canGoBack = await _web.canGoBack();
    if (mounted) setState(() => _canGoBack = canGoBack);
  }

  /// Hands the page the app's language, theme and location (the web app keeps
  /// them in localStorage), reloading once if the language or theme changed.
  /// Also reports whether the page's back button is showing — it was shown
  /// while the page loaded, before the bridge existed to hear about it.
  String _syncScript() {
    final language = widget.services.locale.language?.code ?? 'uz';
    final theme = Theme.of(context).brightness == Brightness.dark ? 'night' : 'day';
    final place = widget.services.prayer.place;
    return '''
(function () {
  var reload = false;
  try {
    if (localStorage.getItem('vegukin_language') !== ${jsonEncode(language)}) {
      localStorage.setItem('vegukin_language', ${jsonEncode(language)});
      reload = true;
    }
    if (localStorage.getItem('theme') !== ${jsonEncode(theme)}) {
      localStorage.setItem('theme', ${jsonEncode(theme)});
      reload = true;
    }
    var place = ${jsonEncode(place?.toJson())};
    if (place) {
      var saved = null;
      try { saved = JSON.parse(localStorage.getItem('userLocation')); } catch (e) {}
      if (!saved || !(saved.timestamp >= place.timestamp)) {
        localStorage.setItem('userLocation', JSON.stringify(place));
        localStorage.setItem('lastLocationUpdate', String(place.timestamp));
      }
    }
  } catch (e) { return; }
  if (reload && !sessionStorage.getItem('vegukinSynced')) {
    sessionStorage.setItem('vegukinSynced', '1');
    location.reload();
    return;
  }
  var back = window.Telegram && Telegram.WebApp && Telegram.WebApp.BackButton;
  if (window.TelegramWebviewProxy) {
    TelegramWebviewProxy.postEvent('web_app_setup_back_button',
      JSON.stringify({ is_visible: !!(back && back.isVisible) }));
  }
})();
''';
  }

  NavigationDecision _onNavigation(NavigationRequest request) {
    if (!request.isMainFrame) return NavigationDecision.navigate;
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    final ownSite = uri.host == _base.host && uri.path.startsWith(_base.path);
    // The web app's home page is this app's home screen.
    if (ownSite && (uri.path == _base.path || uri.path == '${_base.path}index.html')) {
      _close();
      return NavigationDecision.prevent;
    }
    if (ownSite || uri.scheme == 'about' || uri.scheme == 'data' || uri.scheme == 'blob') {
      return NavigationDecision.navigate;
    }
    // Telegram, maps, phone numbers, other sites: their own apps.
    _openExternally(uri);
    return NavigationDecision.prevent;
  }

  Future<void> _openExternally(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _onPermissionRequest(WebViewPermissionRequest request) async {
    // The ingredient scanner uses the camera.
    if (request.types.contains(WebViewPermissionResourceType.camera)) {
      final granted = await Permission.camera.request().isGranted;
      return granted ? request.grant() : request.deny();
    }
    return request.deny();
  }

  // --------------------------------------------------------------- Telegram

  Future<void> _onTelegramEvent(String raw) async {
    final Map<String, dynamic> message;
    try {
      message = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final type = message['type'] as String?;
    final data = _decodeData(message['data']);

    switch (type) {
      case 'web_app_setup_back_button':
        if (mounted) setState(() => _pageHandlesBack = data['is_visible'] == true);
      case 'web_app_open_link':
        final url = Uri.tryParse('${data['url']}');
        if (url != null) await _openExternally(url);
      case 'web_app_open_tg_link':
        await _openExternally(Uri.parse('https://t.me${data['path_full'] ?? ''}'));
      case 'web_app_trigger_haptic_feedback':
        _haptic(data);
      case 'web_app_open_popup':
        await _showPopup(data);
      case 'web_app_request_write_access':
        // Needs a Telegram account; the pages that ask also need sign-in.
        await _sendToPage('write_access_requested', {'status': 'cancelled'});
      case 'web_app_read_text_from_clipboard':
        final clip = await Clipboard.getData(Clipboard.kTextPlain);
        await _sendToPage('clipboard_text_received', {
          'req_id': data['req_id'],
          'data': clip?.text,
        });
      case 'web_app_close':
        await _close();
    }
  }

  /// Telegram passes event data as a JSON string (or an empty string).
  Map<String, dynamic> _decodeData(Object? data) {
    try {
      final decoded = data is String && data.isNotEmpty ? jsonDecode(data) : data;
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  Future<void> _sendToPage(String event, Object? data) => _web
      .runJavaScript(
        'window.Telegram && Telegram.WebView.receiveEvent('
        '${jsonEncode(event)}, ${jsonEncode(data)});',
      )
      .catchError((_) {});

  void _haptic(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'impact':
        switch (data['impact_style']) {
          case 'heavy' || 'rigid':
            HapticFeedback.heavyImpact();
          case 'medium':
            HapticFeedback.mediumImpact();
          default:
            HapticFeedback.lightImpact();
        }
      case 'notification':
        data['notification_type'] == 'error'
            ? HapticFeedback.heavyImpact()
            : HapticFeedback.mediumImpact();
      case 'selection_change':
        HapticFeedback.selectionClick();
    }
  }

  /// Telegram's showAlert / showConfirm / showPopup, as a native dialog.
  Future<void> _showPopup(Map<String, dynamic> data) async {
    final material = MaterialLocalizations.of(context);
    final buttons = (data['buttons'] as List?)?.cast<Map<String, dynamic>>() ??
        const [{'id': '', 'type': 'close'}];

    String label(Map<String, dynamic> b) => switch (b['type']) {
          'ok' => material.okButtonLabel,
          'close' => material.closeButtonLabel,
          'cancel' => material.cancelButtonLabel,
          _ => '${b['text'] ?? ''}',
        };

    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: data['title'] == null ? null : Text('${data['title']}'),
        content: Text('${data['message'] ?? ''}'),
        actions: [
          for (final b in buttons)
            TextButton(
              onPressed: () => Navigator.of(context).pop('${b['id'] ?? ''}'),
              style: b['type'] == 'destructive'
                  ? TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error)
                  : null,
              child: Text(label(b)),
            ),
        ],
      ),
    );
    await _sendToPage('popup_closed', chosen == null ? {} : {'button_id': chosen});
  }

  // ---------------------------------------------------------------- leaving

  /// Back steps inside the page first, like Telegram's back button would.
  Future<void> _back() async {
    if (_pageHandlesBack) {
      await _sendToPage('back_button_pressed', null);
      return;
    }
    if (await _web.canGoBack()) {
      await _web.goBack();
      return;
    }
    await _close();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await _takePrayerSettings();
    if (mounted) Navigator.of(context).pop();
  }

  /// The calculation method and Asr school are chosen on the web prayers
  /// page; the home card follows whatever was picked there.
  Future<void> _takePrayerSettings() async {
    try {
      Object? value = await _web.runJavaScriptReturningResult(
        "localStorage.getItem('prayerSettings') || ''",
      );
      // Android hands back the value JSON-encoded, possibly twice.
      for (var i = 0; i < 2 && value is String && value.isNotEmpty; i++) {
        value = jsonDecode(value);
      }
      if (value is Map<String, dynamic>) {
        unawaited(widget.services.prayer.applySettings(PrayerSettings.fromJson(value)));
      }
    } catch (_) {}
  }

  // -------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final stepsBack = _pageHandlesBack || _canGoBack;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: p.page,
        appBar: AppBar(
          backgroundColor: p.card,
          foregroundColor: p.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: Border(bottom: BorderSide(color: p.hairline)),
          leading: IconButton(
            onPressed: _back,
            tooltip: stepsBack
                ? MaterialLocalizations.of(context).backButtonTooltip
                : MaterialLocalizations.of(context).closeButtonTooltip,
            icon: Icon(stepsBack ? Icons.arrow_back_rounded : Icons.close_rounded),
          ),
          title: Text(
            widget.feature.label(s),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'reload') _web.reload();
                if (value == 'browser') _openExternally(_base.resolve(widget.feature.path));
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'reload', child: Text(s.webReload)),
                PopupMenuItem(value: 'browser', child: Text(s.webOpenInBrowser)),
              ],
            ),
          ],
          bottom: _progress < 100 && !_failed
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    color: p.accent,
                  ),
                )
              : null,
        ),
        body: _failed
            ? _LoadFailed(
                message: s.webLoadFailed,
                retryLabel: s.retry,
                onRetry: () {
                  setState(() => _failed = false);
                  _web.reload();
                },
              )
            : WebViewWidget(controller: _web),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.message, required this.retryLabel, required this.onRetry});

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: p.inkMuted),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: p.inkSoft)),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
