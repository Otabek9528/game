import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

/// The widget as it looks on the home screen: emerald, in light and dark mode
/// alike.
Widget widgetPreview(String size, {double? width}) =>
    Image.asset('assets/widget/$size.webp', width: width, fit: BoxFit.contain);

/// Puts the prayer widget on the home screen, as far as the phone allows:
/// on Android the launcher adds it after the person picks a size (its own
/// dialog, with a preview); an iPhone lets no app do that, so it shows how.
Future<void> showAddWidget(BuildContext context, AppServices services, String offer) async {
  HapticFeedback.selectionClick();
  if (offer == 'guide') services.activity.log('widget_guide');
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: VegukinPalette.of(context).card,
    builder: (sheet) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.paddingOf(sheet).bottom),
      child: offer == 'pin' ? _PickSize(services: services) : const _Guide(),
    ),
  );
}

class _PickSize extends StatelessWidget {
  const _PickSize({required this.services});

  final AppServices services;

  Future<void> _pin(BuildContext context, String size) async {
    final s = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.selectionClick();
    services.activity.log('widget_pin_$size');
    Navigator.pop(context);
    if (!await services.homeWidget.pin(size)) {
      messenger.showSnackBar(SnackBar(content: Text(s.widgetPinFailed), duration: const Duration(seconds: 8)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    Widget option(String size, String label) => InkWell(
          onTap: () => _pin(context, size),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                widgetPreview(size),
                const SizedBox(height: 8),
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink)),
              ],
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.widgetSheetTitle, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink)),
        const SizedBox(height: 6),
        Text(s.widgetSheetPick, style: TextStyle(fontSize: 14, height: 1.4, color: p.inkSoft)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // The previews keep the widgets' proportions: 333 and 160 wide.
            Expanded(flex: 333, child: option('large', s.widgetSizeLarge)),
            const SizedBox(width: 10),
            Expanded(flex: 160, child: option('small', s.widgetSizeSmall)),
          ],
        ),
      ],
    );
  }
}

class _Guide extends StatelessWidget {
  const _Guide();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final steps = [s.widgetGuideStep1, s.widgetGuideStep2, s.widgetGuideStep3];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.widgetSheetTitle, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink)),
        const SizedBox(height: 14),
        Center(child: widgetPreview('large', width: 260)),
        const SizedBox(height: 16),
        for (final (i, step) in steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.14), shape: BoxShape.circle),
                  child: Text('${i + 1}',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.accent)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(step, style: TextStyle(fontSize: 15, height: 1.35, color: p.ink)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        FilledButton(onPressed: () => Navigator.pop(context), child: Text(s.widgetGuideDone)),
      ],
    );
  }
}

/// On the prayers page, for whoever has no widget yet and could have one:
/// what it is, and the way to add it. Closed, it stays closed; Account →
/// "Home-screen widget" still adds one.
class WidgetOfferCard extends StatefulWidget {
  const WidgetOfferCard({super.key, required this.services});

  final AppServices services;

  @override
  State<WidgetOfferCard> createState() => _WidgetOfferCardState();
}

class _WidgetOfferCardState extends State<WidgetOfferCard> with WidgetsBindingObserver {
  static const _closedKey = 'widget_offer_closed';

  /// `pin` or `guide` while there's something to offer.
  String? _offer;

  AppServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the launcher's dialog or the home screen: placed now?
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  Future<void> _check() async {
    if (_services.store.read(_closedKey) != null) return;
    final offer = await _services.homeWidget.offer();
    final placed = offer == null ? const <String>[] : await _services.homeWidget.placed();
    if (mounted) setState(() => _offer = placed.isEmpty ? offer : null);
  }

  void _close() {
    HapticFeedback.selectionClick();
    unawaited(_services.store.write(_closedKey, '1'));
    setState(() => _offer = null);
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    if (offer == null) return const SizedBox.shrink();
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: p.hairline)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widgetPreview('large', width: 104),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.widgetOfferTitle,
                            style: TextStyle(fontSize: 15.5, height: 1.25, fontWeight: FontWeight.w800, color: p.ink)),
                        const SizedBox(height: 4),
                        Text(s.widgetOfferBody, style: TextStyle(fontSize: 13.5, height: 1.35, color: p.inkSoft)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _close,
                    tooltip: s.widgetOfferClose,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close_rounded, size: 20, color: p.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.tonalIcon(
                  onPressed: () => showAddWidget(context, _services, offer),
                  icon: const Icon(Icons.add_to_home_screen_rounded),
                  label: Text(s.widgetOfferAdd),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
