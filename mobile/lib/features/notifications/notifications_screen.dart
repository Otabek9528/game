import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../home/feature_catalog.dart';
import '../home/sections.dart';
import '../places/place_detail.dart' show openPlaceById;
import '../places/places_models.dart';
import '../places/places_parts.dart' show kindColour;
import '../places/places_source.dart';
import 'area_sheet.dart';
import 'notify_models.dart';

/// What happens to places, told as it happens: areas watched (around where
/// one stood, or an address), places watched one by one, and how one is told
/// — the app's notifications, and for a Telegram account the bot as well.
/// A message's "Stop" opens here and stops at once, with an undo.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.services, this.stop});

  final AppServices services;

  /// From a message's "Stop": `place:12` or `area:3`.
  final String? stop;

  /// The stop a link names: "…notifications.html?stop=place:12".
  static String? stopIn(String path) => Uri.tryParse(path)?.queryParameters['stop'];

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  AppServices get _services => widget.services;
  PlacesSource get _source => _services.places;
  String get _lang => _services.locale.language?.code ?? 'uz';

  /// What the page showed last time, kept on the phone: shown at once,
  /// then refreshed. Someone else's (signed in or out since) is not used.
  static const _cacheKey = 'notify_me';
  NotifyMe? _meValue;
  NotifyMe? get _me => _meValue;
  set _me(NotifyMe? me) {
    _meValue = me;
    if (me == null) return;
    unawaited(_services.store.write(_cacheKey, jsonEncode({'user': _services.account.user?.id, ...notifyMeToJson(me)})));
  }

  NotifyMe? _cached() {
    try {
      final json = jsonDecode(_services.store.read(_cacheKey) ?? '');
      if (json is! Map<String, dynamic> || json['user'] != _services.account.user?.id) return null;
      return notifyMeFromJson(json);
    } on FormatException {
      return null;
    }
  }

  bool _refreshing = false;
  bool _failed = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _meValue = _cached();
    unawaited(_load(stop: widget.stop));
  }

  Future<Map<String, String>> _auth() async {
    try {
      await _services.account.headers();
    } catch (_) {}
    return _services.account.authHeaders;
  }

  void _snack(String text, {VoidCallback? undo}) {
    final s = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          action: undo == null ? null : SnackBarAction(label: s.ntUndo, onPressed: undo),
        ),
      );
  }

  Future<void> _load({String? stop}) async {
    setState(() {
      _failed = false;
      _refreshing = true;
    });
    try {
      final auth = await _auth();
      if (stop != null) await _applyStop(auth, stop);
      final me = await _source.notifyMe(auth);
      if (mounted) setState(() => _me = me);
    } on PlacesException {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// "Stop" from a message; already gone counts as stopped.
  Future<void> _applyStop(Map<String, String> auth, String stop) async {
    final m = RegExp(r'^(place|area):(\d+)$').firstMatch(stop);
    if (m == null) return;
    final id = int.parse(m.group(2)!);
    final place = m.group(1) == 'place';
    try {
      place ? await _source.watch(auth, id, on: false, lang: _lang) : await _source.deleteArea(auth, id);
    } on PlacesException catch (e) {
      if (e.code != 'not_found') rethrow;
    }
    if (!mounted) return;
    final s = AppLocalizations.of(context);
    _snack(
      place ? s.ntStoppedPlace : s.ntStoppedArea,
      undo: place
          ? () async {
              try {
                await _source.watch(await _auth(), id, on: true, lang: _lang);
                await _load();
              } on PlacesException catch (e) {
                if (mounted) _snack(notifyError(AppLocalizations.of(context), e));
              }
            }
          : null,
    );
  }

  Future<void> _addArea([NotifyArea? area]) async {
    final s = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    final saved = await showAreaSheet(context, _services, _auth, area: area);
    if (saved == null || !mounted) return;
    _snack(area == null ? s.ntAreaSaved : s.ntAreaUpdated);
    await _load();
  }

  Future<void> _deleteArea(NotifyArea area) async {
    final s = AppLocalizations.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(s.ntDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(s.ntDelete),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    try {
      await _source.deleteArea(await _auth(), area.id);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(
        () => _me = (
          areas: [..._me!.areas]..remove(area),
          watches: _me!.watches,
          delivery: _me!.delivery,
          botBlocked: _me!.botBlocked,
        ),
      );
      _snack(s.ntAreaDeleted);
    } on PlacesException catch (e) {
      if (mounted) _snack(notifyError(s, e));
    }
  }

  Future<void> _unwatch(WatchedPlace place) async {
    final s = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    try {
      await _source.watch(await _auth(), place.id, on: false, lang: _lang);
      if (!mounted) return;
      final me = _me!;
      setState(
        () => _me = (
          areas: me.areas,
          watches: [...me.watches]..remove(place),
          delivery: me.delivery,
          botBlocked: me.botBlocked,
        ),
      );
      _snack(
        s.ntWatchRemoved,
        undo: () async {
          try {
            await _source.watch(await _auth(), place.id, on: true, lang: _lang);
            await _load();
          } on PlacesException catch (e) {
            if (mounted) _snack(notifyError(AppLocalizations.of(context), e));
          }
        },
      );
    } on PlacesException catch (e) {
      if (mounted) _snack(notifyError(s, e));
    }
  }

  Future<void> _setDelivery({required bool telegram, required bool push}) async {
    final s = AppLocalizations.of(context);
    if (!telegram && !push) {
      HapticFeedback.heavyImpact();
      return _snack(s.ntViaOne);
    }
    HapticFeedback.selectionClick();
    final me = _me!;
    final before = me.delivery;
    // At once, as switches do; back if the server says no.
    setState(
      () => _me = (
        areas: me.areas,
        watches: me.watches,
        delivery: NotifyDelivery(telegram: telegram, push: push, canTelegram: true, bot: before.bot),
        botBlocked: me.botBlocked,
      ),
    );
    try {
      await _source.setDelivery(await _auth(), telegram: telegram, push: push, lang: _lang);
    } on PlacesException catch (e) {
      if (!mounted) return;
      setState(() => _me = (areas: me.areas, watches: me.watches, delivery: before, botBlocked: me.botBlocked));
      _snack(notifyError(s, e));
    }
  }

  /// The bot's test message; the person switched back on.
  Future<void> _check() async {
    final s = AppLocalizations.of(context);
    setState(() => _checking = true);
    try {
      await _source.hello(await _auth(), _lang);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      final me = _me!;
      setState(() => _me = (areas: me.areas, watches: me.watches, delivery: me.delivery, botBlocked: false));
      _snack(s.ntHelloSent);
    } on PlacesException catch (e) {
      if (mounted) _snack(notifyError(s, e));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _openList(PlaceKind kind) {
    final feature = featureGrid.firstWhere((f) => f.id == kind.key);
    openSection(context, feature, _services);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final me = _me;
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(
        backgroundColor: p.page,
        surfaceTintColor: Colors.transparent,
        title: Text(s.ntTitle),
        // Refreshing what is already shown: a thin line, not a spinner.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _refreshing && me != null ? const LinearProgressIndicator(minHeight: 2) : const SizedBox(height: 2),
        ),
      ),
      floatingActionButton: me == null || (me.areas.isEmpty && me.watches.isEmpty)
          ? null
          : FloatingActionButton.extended(
              onPressed: _addArea,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: Text(s.ntAreasAdd),
            ),
      body: me == null
          ? Center(
              child: _failed
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_rounded, size: 44, color: p.inkMuted),
                          const SizedBox(height: 10),
                          Text(
                            s.ntLoadError,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: p.inkSoft),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.tonal(onPressed: _load, child: Text(s.ntRetry)),
                        ],
                      ),
                    )
                  : const CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 96 + MediaQuery.paddingOf(context).bottom),
                children: [
                  ListenableBuilder(
                    listenable: _services.account,
                    builder: (context, _) => _DeliveryCard(
                      delivery: me.delivery,
                      pushAllowed: _services.account.pushAllowed,
                      onChanged: _setDelivery,
                      onPushOn: _services.permissions.openAppSettings,
                    ),
                  ),
                  if (me.delivery.telegram && me.botBlocked) ...[
                    const SizedBox(height: 12),
                    _BotBlocked(
                      bot: me.delivery.bot,
                      checking: _checking,
                      onOpenBot: (bot) => _services.openLink(Uri.parse('https://t.me/$bot')),
                      onCheck: _check,
                    ),
                  ],
                  if (me.areas.isEmpty && me.watches.isEmpty)
                    _Empty(onArea: _addArea, onList: _openList)
                  else ...[
                    _Heading(text: s.ntAreasTitle, count: me.areas.length),
                    if (me.areas.isEmpty)
                      _Dashed(icon: Icons.add_location_alt_rounded, text: s.ntEmptyAreaBody, onTap: _addArea)
                    else
                      for (final area in me.areas)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AreaCard(area: area, onEdit: () => _addArea(area), onDelete: () => _deleteArea(area)),
                        ),
                    _Heading(text: s.ntWatchTitle, count: me.watches.length),
                    if (me.watches.isEmpty)
                      _Dashed(icon: Icons.notifications_none_rounded, text: s.ntWatchHint)
                    else ...[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: p.hairline),
                        ),
                        child: Column(
                          children: [
                            for (final (i, place) in me.watches.indexed) ...[
                              if (i > 0) Divider(height: 1, indent: 70, color: p.hairline),
                              _WatchRow(
                                place: place,
                                onOpen: () => openPlaceById(context, _services, place.id),
                                onStop: () => _unwatch(place),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                        child: Text(s.ntWatchHint, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}

/// Where messages arrive: the app, and for a Telegram account the bot too.
class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.delivery,
    required this.pushAllowed,
    required this.onChanged,
    required this.onPushOn,
  });

  final NotifyDelivery delivery;
  final bool pushAllowed;
  final void Function({required bool telegram, required bool push}) onChanged;
  final VoidCallback onPushOn;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    Widget option(IconData icon, Color colour, String title, String body, bool on, ValueChanged<bool> onChange) =>
        SwitchListTile(
          value: on,
          onChanged: onChange,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          secondary: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: colour.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: colour, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w700, color: p.ink),
          ),
          subtitle: Text(body, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
        );
    final pushOff = delivery.push && !pushAllowed;
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              s.ntWhereTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.ink),
            ),
          ),
          if (delivery.canTelegram) ...[
            option(
              Icons.phone_iphone_rounded,
              p.accent,
              s.ntViaApp,
              s.ntViaAppBody,
              delivery.push,
              (v) => onChanged(telegram: delivery.telegram, push: v),
            ),
            option(
              Icons.telegram,
              const Color(0xFF229ED9),
              s.ntViaBot,
              s.ntViaBotBody,
              delivery.telegram,
              (v) => onChanged(telegram: v, push: delivery.push),
            ),
          ] else
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.phone_iphone_rounded, color: p.accent, size: 22),
              ),
              title: Text(
                s.ntAppOnly,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink),
              ),
              subtitle: Text(s.ntAppOnlyHint, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
            ),
          if (pushOff)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              decoration: BoxDecoration(color: const Color(0x1FE0A100), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.notifications_off_rounded, size: 20, color: Color(0xFFB07A00)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.ntPushOff, style: TextStyle(fontSize: 12.5, height: 1.35, color: p.ink)),
                  ),
                  TextButton(onPressed: onPushOn, child: Text(s.ntPushOn)),
                ],
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _BotBlocked extends StatelessWidget {
  const _BotBlocked({required this.bot, required this.checking, required this.onOpenBot, required this.onCheck});

  final String? bot;
  final bool checking;
  final ValueChanged<String> onOpenBot;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final error = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.speaker_notes_off_rounded, color: error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.ntBlocked, style: TextStyle(fontSize: 13.5, height: 1.4, color: p.ink)),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 4,
              children: [
                if (bot != null)
                  TextButton.icon(
                    onPressed: () => onOpenBot(bot!),
                    icon: const Icon(Icons.telegram),
                    label: Text(s.ntOpenBot),
                  ),
                TextButton(onPressed: checking ? null : onCheck, child: Text(s.ntCheck)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nothing watched yet: the two ways in, and what one hears about.
class _Empty extends StatelessWidget {
  const _Empty({required this.onArea, required this.onList});

  final VoidCallback onArea;
  final ValueChanged<PlaceKind> onList;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    Widget way(IconData icon, String title, String body, {VoidCallback? onTap, Widget? below}) => Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.hairline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: p.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: p.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(body, style: TextStyle(fontSize: 13, height: 1.4, color: p.inkSoft)),
                    ?below,
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.chevron_right_rounded, color: p.inkMuted),
            ],
          ),
        ),
      ),
    );
    final whens = [
      (Icons.add_business_rounded, s.ntWhenNew),
      (Icons.block_rounded, s.ntWhenClosed),
      (Icons.call_rounded, s.ntWhenPhone),
      (Icons.edit_rounded, s.ntWhenName),
      (Icons.campaign_rounded, s.ntWhenOwner),
      (Icons.mosque_rounded, s.ntWhenMosque),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 22),
        Text(
          s.ntEmptyTitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.ink),
        ),
        const SizedBox(height: 4),
        Text(
          s.ntEmptyBody,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: p.inkSoft),
        ),
        const SizedBox(height: 16),
        way(Icons.radar_rounded, s.ntEmptyAreaTitle, s.ntEmptyAreaBody, onTap: onArea),
        const SizedBox(height: 10),
        way(
          Icons.notifications_active_rounded,
          s.ntEmptyPlaceTitle,
          s.ntEmptyPlaceBody,
          below: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final kind in PlaceKind.values)
                  ActionChip(
                    avatar: Text(kind.emoji),
                    label: Text(switch (kind) {
                      PlaceKind.mosque => s.ntTypesMosque,
                      PlaceKind.restaurant => s.ntTypesRestaurant,
                      PlaceKind.shop => s.ntTypesShop,
                    }),
                    onPressed: () => onList(kind),
                    backgroundColor: p.page,
                    side: BorderSide(color: p.hairline),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            s.ntWhenTitle,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.ink),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (icon, text) in whens)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.hairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: p.accent),
                    const SizedBox(width: 6),
                    Text(
                      text,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.text, required this.count});

  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.ink),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Dashed extends StatelessWidget {
  const _Dashed({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Material(
      color: p.cardSelected.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.accent.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: p.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text, style: TextStyle(fontSize: 13.5, height: 1.4, color: p.inkSoft)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area, required this.onEdit, required this.onDelete});

  final NotifyArea area;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final title = area.label ?? (area.fromLocation ? s.ntCurrentLocation : '');
    final meta = '${area.fromLocation ? s.ntFromLocation : s.ntRadiusKm(area.radiusKm)} · ${s.ntInside(area.inside)}';
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.hairline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 2, 12),
          child: Row(
            children: [
              _Radar(km: area.radiusKm),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          area.fromLocation ? Icons.my_location_rounded : Icons.place_rounded,
                          size: 16,
                          color: p.accent,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(meta, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final kind in PlaceKind.values)
                          if (area.types.contains(kind))
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: kindColour(context, kind).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                child: Text(
                                  '${kind.emoji} ${switch (kind) {
                                    PlaceKind.mosque => s.ntTypeMosque,
                                    PlaceKind.restaurant => s.ntTypeRestaurant,
                                    PlaceKind.shop => s.ntTypeShop,
                                  }}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: kindColour(context, kind),
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<bool>(
                icon: Icon(Icons.more_vert_rounded, color: p.inkMuted),
                onSelected: (edit) => edit ? onEdit() : onDelete(),
                itemBuilder: (context) => [
                  PopupMenuItem(value: true, child: Text(s.ntEdit)),
                  PopupMenuItem(value: false, child: Text(s.ntDelete)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four rings for 1, 3, 5 and 10 km; the area's solid, its radius under.
class _Radar extends StatelessWidget {
  const _Radar({required this.km});

  final int km;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          SizedBox.square(
            dimension: 50,
            child: CustomPaint(
              painter: _RadarPainter(on: notifyRadii.indexOf(km), accent: p.accent, line: p.hairlineStrong),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$km km',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.accent),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.on, required this.accent, required this.line});

  final int on;
  final Color accent;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = notifyRadii.length - 1; i >= 0; i--) {
      final r = 7 + i * 5.8;
      if (i == on) canvas.drawCircle(c, r, Paint()..color = accent.withValues(alpha: 0.16));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == on ? 2 : 1
          ..color = i == on ? accent : line,
      );
    }
    canvas.drawCircle(c, 3, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.on != on || old.accent != accent;
}

class _WatchRow extends StatelessWidget {
  const _WatchRow({required this.place, required this.onOpen, required this.onStop});

  final WatchedPlace place;
  final VoidCallback onOpen;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final colour = kindColour(context, place.kind);
    final type = switch (place.kind) {
      PlaceKind.mosque => s.ntTypeMosque,
      PlaceKind.restaurant => s.ntTypeRestaurant,
      PlaceKind.shop => s.ntTypeShop,
    };
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: colour.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Text(place.kind.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink),
                  ),
                  Text([type, ?place.city].join(' · '), style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                ],
              ),
            ),
            IconButton(
              onPressed: onStop,
              tooltip: s.ntWatchStop,
              icon: Icon(Icons.notifications_active_rounded, color: p.accent),
            ),
          ],
        ),
      ),
    );
  }
}
