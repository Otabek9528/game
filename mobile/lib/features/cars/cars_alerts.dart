import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_screen.dart';
import 'cars_kit.dart';
import 'cars_models.dart';
import 'cars_parts.dart';
import 'cars_picker.dart';

/// "Tell me when": a new alert (make and model, price, mileage, year, fuel)
/// and the ones set, each deleted with a tap. A new matching listing comes
/// to the phone as a notification. Needs someone signed in.
class CarsAlertsTab extends StatefulWidget {
  const CarsAlertsTab({super.key, required this.kit});

  final CarsKit kit;

  @override
  State<CarsAlertsTab> createState() => _CarsAlertsTabState();
}

class _CarsAlertsTabState extends State<CarsAlertsTab> with AutomaticKeepAliveClientMixin {
  CarsKit get _kit => widget.kit;

  CarPick? _pick;
  final _price = TextEditingController();
  final _mileage = TextEditingController();
  final _year = TextEditingController();
  final _fuels = <String>{};
  bool _busy = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _price.dispose();
    _mileage.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_kit.signedIn) return;
    setState(() => _error = null);
    try {
      await _kit.loadAlerts();
    } on CarsException catch (e) {
      if (mounted) setState(() => _error = e.code);
    }
  }

  Future<void> _signIn() async {
    if (await askToSignIn(context, _kit.services) && mounted) await _load();
  }

  static int? _number(TextEditingController c) {
    final v = int.tryParse(c.text.replaceAll(RegExp(r'\D'), ''));
    return v == null || v == 0 ? null : v;
  }

  Future<void> _create() async {
    final s = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final query = CarQuery(
      pick: _pick,
      priceMax: _number(_price),
      mileageMax: _number(_mileage),
      yearFrom: _number(_year),
      fuels: {..._fuels},
    );
    if (query.params.isEmpty) return showCarsSnack(context, s.carAlertNeedsFilter);
    setState(() => _busy = true);
    try {
      await _kit.addAlert(query);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _price.clear();
      _mileage.clear();
      _year.clear();
      setState(() {
        _pick = null;
        _fuels.clear();
      });
      showCarsSnack(context, s.carAlertCreated);
    } on CarsException catch (e) {
      if (!mounted) return;
      showCarsSnack(context, switch (e.code) {
        'validation_failed' => s.carAlertNeedsFilter,
        'duplicate_alert' => s.carAlertDuplicate,
        'limit_reached' => s.carAlertLimit,
        'offline' => s.carCheckInternet,
        _ => s.carErrorGeneric,
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(CarAlert alert) async {
    final s = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    try {
      await _kit.deleteAlert(alert.id);
      if (mounted) showCarsSnack(context, s.carAlertDeleted);
    } on CarsException {
      if (mounted) showCarsSnack(context, s.carErrorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_kit, _kit.services.account]),
      builder: (context, _) {
        final alerts = _kit.alerts;
        final signedIn = _kit.signedIn;
        return RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              CarsTabBar(
                title: s.carAlertsTitle,
                subtitle: Text(signedIn && alerts != null ? s.carAlertsActive('${alerts.length}') : s.carNoAlertsBody),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.list(
                  children: [
                    if (!signedIn)
                      SignInCard(
                        icon: Icons.notifications_active_rounded,
                        title: s.carSignInAlertsTitle,
                        body: s.carSignInAlertsBody,
                        action: s.carSignInButton,
                        onAction: _signIn,
                      )
                    else ...[
                      if (!_kit.services.account.pushAllowed) ...[
                        _PushOff(onTurnOn: _kit.services.permissions.openAppSettings),
                        const SizedBox(height: 12),
                      ],
                      _form(context),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
                        child: Text(s.carMyAlerts, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.ink)),
                      ),
                      if (_error != null && alerts == null)
                        CarsMessage(emoji: '⚠️', title: s.carLoadFailed, body: s.carCheckInternet, action: s.retry, onAction: _load)
                      else if (alerts == null)
                        const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                      else if (alerts.isEmpty)
                        CarsMessage(emoji: '🔔', title: s.carNoAlertsTitle, body: s.carNoAlertsBody)
                      else
                        for (final a in alerts) ...[
                          _AlertRow(alert: a, onDelete: () => _delete(a)),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _form(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: p.hairline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.add_alert_rounded, color: p.accent),
              const SizedBox(width: 8),
              Text(s.carNewAlert, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.ink)),
            ],
          ),
          const SizedBox(height: 12),
          CarPickField(
            pick: _pick,
            empty: s.carAnyCar,
            onTap: () async {
              final chosen = await pickCar(context, _kit, allowAny: true);
              if (chosen != null && mounted) setState(() => _pick = chosen.pick);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CarNumberField(label: s.carPriceMax, controller: _price, hint: '7 000 000', grouped: true, onChanged: () {})),
              const SizedBox(width: 10),
              Expanded(child: CarNumberField(label: s.carMileageMax, controller: _mileage, hint: '150 000', grouped: true, onChanged: () {})),
            ],
          ),
          const SizedBox(height: 12),
          CarNumberField(label: s.carYearFrom, controller: _year, hint: '2012', maxLength: 4, onChanged: () {}),
          const SizedBox(height: 12),
          CarFieldLabel(s.carFuel),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final fuel in carFuels)
                CarChip(
                  label: fuelLabel(s, fuel)!,
                  on: _fuels.contains(fuel),
                  onTap: () => setState(() => _fuels.contains(fuel) ? _fuels.remove(fuel) : _fuels.add(fuel)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _create,
            icon: _busy
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Icon(Icons.notifications_rounded),
            label: Text(s.carCreateAlert),
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.onDelete});

  final CarAlert alert;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final criteria = [
      if (alert.priceMax != null) '≤ ${won(alert.priceMax)}',
      if (alert.mileageMax != null) '≤ ${kmShort(alert.mileageMax!)}',
      if (alert.yearFrom != null) '${alert.yearFrom}+',
      for (final f in alert.fuels) fuelLabel(s, f) ?? f,
    ];
    final brand = alert.brand;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.hairline)),
      child: Row(
        children: [
          brand == null
              ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.notifications_rounded, color: p.accent),
                )
              : BrandLogo(brand, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand == null ? s.carAnyCar : [brand, ?alert.model].join(' '),
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: p.ink),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in criteria.isEmpty ? [s.carAllListings] : criteria)
                      DecoratedBox(
                        decoration: BoxDecoration(color: p.badge, borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          child: Text(c, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.inkSoft)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: s.carDelete,
            icon: Icon(Icons.delete_outline_rounded, color: p.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _PushOff extends StatelessWidget {
  const _PushOff({required this.onTurnOn});

  final VoidCallback onTurnOn;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(color: p.gold.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(Icons.notifications_off_outlined, size: 20, color: p.gold),
          const SizedBox(width: 10),
          Expanded(child: Text(s.carPushOff, style: TextStyle(fontSize: 13, height: 1.35, color: p.inkSoft))),
          TextButton(onPressed: onTurnOn, child: Text(s.carPushOn)),
        ],
      ),
    );
  }
}
