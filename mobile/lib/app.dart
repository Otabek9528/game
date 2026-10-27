import 'dart:async';

import 'package:flutter/material.dart';

import 'app_services.dart';
import 'core/app_language.dart';
import 'core/push.dart';
import 'core/theme.dart';
import 'features/account/inbox_message.dart';
import 'features/account/inbox_screen.dart';
import 'features/home/feature_catalog.dart';
import 'features/home/home_screen.dart';
import 'features/home/sections.dart';
import 'features/onboarding/language_screen.dart';
import 'features/opening/opening.dart';
import 'l10n/app_localizations.dart';

class VegukinApp extends StatefulWidget {
  const VegukinApp({
    super.key,
    required this.services,
    required this.deviceLocales,
  });

  final AppServices services;

  /// The phone's preferred languages, best first.
  final List<Locale> deviceLocales;

  @override
  State<VegukinApp> createState() => _VegukinAppState();
}

class _VegukinAppState extends State<VegukinApp> {
  late final AppLanguage _guess = AppLanguage.guessFrom(widget.deviceLocales);

  // Decided once at launch. Picking a language later must not swap the root
  // screen out from under the navigator; the language screen navigates on.
  late final bool _needsLanguage = !widget.services.locale.hasChosen;

  final _navigator = GlobalKey<NavigatorState>();
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  AppLanguage? _language;

  @override
  void initState() {
    super.initState();
    final services = widget.services;
    // Read now: a lazy read would first happen after the change, and miss it.
    _language = services.locale.language;
    services.locale.addListener(_languageChanged);
    services.account.handlePush(onOpen: _openPush, onForeground: _showPush);
    // The account exists from the first launch, so watches need no sign-in.
    // With it, what was pushed to it (the inbox's badge).
    unawaited(services.account.refreshInbox());
  }

  @override
  void dispose() {
    widget.services.locale.removeListener(_languageChanged);
    super.dispose();
  }

  void _languageChanged() {
    final language = widget.services.locale.language;
    if (language == _language) return;
    _language = language;
    unawaited(widget.services.account.languageChanged());
  }

  /// A notification was tapped: its page; one without a page of its own
  /// (a message, an announcement) opens whole from the inbox.
  void _openPush(PushMessage message) {
    final feature = featureForPush(message.data);
    final inboxId = int.tryParse(message.data['inbox_id'] ?? '');
    final context = _navigator.currentContext;
    if (feature == null && inboxId != null) {
      unawaited(_openMessage(inboxId));
      return;
    }
    unawaited(widget.services.account.refreshInbox());
    if (feature == null || context == null) return;
    openSection(context, feature, widget.services);
  }

  Future<void> _openMessage(int id) async {
    final services = widget.services;
    await services.account.refreshInbox();
    final context = _navigator.currentContext;
    if (context == null || !context.mounted) return;
    final item = services.account.inbox.where((i) => i.id == id).firstOrNull;
    if (item != null) {
      openInboxMessage(context, services, item);
    } else {
      openInbox(context, services);
    }
  }

  /// One arrived while the app was open: Android doesn't show it, so the app does.
  void _showPush(PushMessage message) {
    // The test shows as a real notification, and on the account page.
    if (isTestPush(message)) return;
    unawaited(widget.services.account.refreshInbox());
    final text = [?message.title, ?message.body].join('\n');
    final context = _navigator.currentContext;
    if (text.isEmpty || context == null) return;
    final canOpen = featureForPush(message.data) != null || message.data.containsKey('inbox_id');
    _messenger.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text, maxLines: 4, overflow: TextOverflow.ellipsis),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: canOpen
            ? SnackBarAction(label: AppLocalizations.of(context).pushOpen, onPressed: () => _openPush(message))
            : null,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.services.locale;
    final theme = widget.services.theme;
    return ListenableBuilder(
      listenable: Listenable.merge([locale, theme]),
      builder: (context, _) => MaterialApp(
        title: 'Muslim Vegukin',
        navigatorKey: _navigator,
        scaffoldMessengerKey: _messenger,
        debugShowCheckedModeBanner: false,
        theme: VegukinTheme.light,
        darkTheme: VegukinTheme.dark,
        themeMode: theme.mode,
        locale: (locale.language ?? _guess).locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        // At launch, over whichever screen comes first while it loads.
        builder: (context, child) => Opening(child: child!),
        home: _needsLanguage
            ? LanguageScreen(services: widget.services, initialLanguage: _guess)
            : HomeScreen(services: widget.services),
      ),
    );
  }
}
