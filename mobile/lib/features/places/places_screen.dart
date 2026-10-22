import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import 'place_actions.dart';
import 'place_detail.dart';
import 'places_kit.dart';
import 'places_models.dart';
import 'places_parts.dart';

/// Where people tell other people's places to go: the group.
const placesGroupUrl = 'https://t.me/MuslimVegukin';

/// The web page's example address for each kind, in the field until typed over.
const _addressExample = {
  PlaceKind.mosque: '서울 강동구 구천면로 271',
  PlaceKind.restaurant: '서울 강남구 테헤란로 123',
  PlaceKind.shop: '서울 용산구 이태원로 123',
};

/// Mosques, restaurants or shops, as on the web page: "near me" or "near
/// another address", and the five nearest. "Near me" always takes a new
/// location fix, and runs by itself when the phone already lets it.
class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key, required this.services, required this.kind});

  final AppServices services;
  final PlaceKind kind;

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

enum _Mode { none, here, address }

class _PlacesScreenState extends State<PlacesScreen> {
  late final PlacesKit _kit = PlacesKit(widget.services);
  PlaceKind get _kind => widget.kind;
  final _address = TextEditingController();
  final _addressFocus = FocusNode();

  _Mode _mode = _Mode.none;
  bool _busy = false;
  PlacesFound? _found;
  String? _error;
  String? _addressError;

  @override
  void initState() {
    super.initState();
    unawaited(_kit.loadPhotos());
    unawaited(_kit.loadWatched());
    unawaited(_start());
  }

  /// "Near me" at once when the phone allows it without asking.
  Future<void> _start() async {
    if (await _kit.locationAllowed() && mounted && _mode == _Mode.none) await _nearMe();
  }

  @override
  void dispose() {
    _address.dispose();
    _addressFocus.dispose();
    _kit.dispose();
    super.dispose();
  }

  Future<void> _nearMe() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = _Mode.here;
      _busy = true;
      _error = null;
      _found = null;
    });
    try {
      final found = await _kit.nearMe(_kind);
      if (mounted) setState(() => _found = found);
    } on PlacesException catch (e) {
      if (mounted) setState(() => _error = e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openAddress() {
    HapticFeedback.selectionClick();
    setState(() {
      _mode = _Mode.address;
      _error = null;
      _addressError = null;
      if (_found?.origin != PlaceOrigin.address) _found = null;
    });
    _addressFocus.requestFocus();
  }

  Future<void> _searchAddress([String? text]) async {
    final s = AppLocalizations.of(context);
    final address = (text ?? _address.text).trim();
    if (text != null) _address.text = text;
    if (address.isEmpty) return setState(() => _addressError = s.plTextEmpty);
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _addressError = null;
      _found = null;
    });
    try {
      final found = await _kit.nearAddress(_kind, address);
      if (mounted) setState(() => _found = found);
    } on PlacesException catch (e) {
      if (!mounted) return;
      setState(() => e.code == 'address_not_found' ? _addressError = s.plAddressNotFound : _error = e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() => switch (_mode) {
        _Mode.here => _nearMe(),
        _Mode.address when _address.text.trim().isNotEmpty => _searchAddress(),
        _ => Future.value(),
      };

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Scaffold(
      backgroundColor: p.page,
      body: ListenableBuilder(
        listenable: Listenable.merge([_kit, widget.services.prayer]),
        builder: (context, _) => RefreshIndicator(
          onRefresh: _refresh,
          edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: p.hero.first,
                surfaceTintColor: Colors.transparent,
                foregroundColor: Colors.white,
                systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
                titleTextStyle: const TextStyle(
                  fontFamily: Brand.displayFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 21,
                  color: Colors.white,
                ),
                title: Text(kindPlural(s, _kind)),
              ),
              SliverToBoxAdapter(child: _hero(context)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(14, 16, 14, 28 + MediaQuery.paddingOf(context).bottom),
                sliver: SliverList.list(
                  children: [
                    ..._body(context),
                    const SizedBox(height: 16),
                    _Missing(onTap: () => widget.services.openLink(Uri.parse(placesGroupUrl))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    const radius = BorderRadius.vertical(bottom: Radius.circular(26));
    final recent = _kit.addresses;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.hero.first, p.hero.last]),
        borderRadius: radius,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: radius,
              child: CustomPaint(painter: KhatamLatticePainter(color: Colors.white.withValues(alpha: 0.05))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ModeButton(
                          icon: Icons.my_location_rounded,
                          label: s.plNearMe,
                          selected: _mode == _Mode.here,
                          onTap: _busy ? null : _nearMe,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ModeButton(
                          icon: Icons.travel_explore_rounded,
                          label: s.plByAddress,
                          selected: _mode == _Mode.address,
                          onTap: _busy ? null : _openAddress,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _mode != _Mode.address
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: _AddressPanel(
                            controller: _address,
                            focus: _addressFocus,
                            example: _addressExample[_kind]!,
                            error: _addressError,
                            busy: _busy,
                            recent: recent,
                            onSearch: _searchAddress,
                            onChanged: () {
                              if (_addressError != null) setState(() => _addressError = null);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _body(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final prayer = widget.services.prayer;
    if (_busy) {
      return [
        _Status(text: prayer.locating ? s.plLocatingYou : s.plLoadingPlaces),
        for (var i = 0; i < 3; i++) const _SkeletonCard(),
      ];
    }
    if (_error case final code?) return [_problem(context, code)];
    final found = _found;
    if (found == null) {
      return [if (_mode == _Mode.none) _Message(icon: Icons.touch_app_rounded, title: s.plChooseTitle, body: s.plChooseBody)];
    }
    final title = found.origin == PlaceOrigin.address
        ? s.plNearestToAddress
        : switch (_kind) {
            PlaceKind.mosque => s.plNearestMosques(found.places.length),
            PlaceKind.restaurant => s.plNearestRestaurants(found.places.length),
            PlaceKind.shop => s.plNearestShops(found.places.length),
          };
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
        child: Text(
          '${_kind.emoji}  $title',
          style: TextStyle(fontFamily: Brand.displayFont, fontSize: 21, fontWeight: FontWeight.w700, color: p.ink),
        ),
      ),
      _Origin(
        found: found,
        now: prayer.now,
        onAgain: found.origin == PlaceOrigin.address ? _openAddress : _nearMe,
      ),
      const SizedBox(height: 12),
      if (found.places.isEmpty)
        _Message(icon: Icons.search_off_rounded, title: s.plNothingFound)
      else
        for (final (i, place) in found.places.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: PlaceCard(
              kit: _kit,
              place: place,
              km: found.kmTo(place),
              nearest: i == 0,
              onTap: () => openPlace(context, _kit, place, km: found.kmTo(place), origin: found.origin),
            ),
          ),
    ];
  }

  /// Why no places: the location (with the way to fix it, and the address
  /// instead), or the connection.
  Widget _problem(BuildContext context, String code) {
    final s = AppLocalizations.of(context);
    final prayer = widget.services.prayer;
    final address = OutlinedButton.icon(
      onPressed: _openAddress,
      icon: const Icon(Icons.travel_explore_rounded),
      label: Text(s.plUseAddress),
    );
    return switch (code) {
      'location_denied' => _Message(
          icon: Icons.location_searching_rounded,
          title: s.plDeniedBody,
          action: FilledButton.icon(onPressed: _nearMe, icon: const Icon(Icons.my_location_rounded), label: Text(s.plAllow)),
          secondary: address,
        ),
      'location_blocked' => _Message(
          icon: Icons.location_disabled_rounded,
          title: s.plBlockedBody,
          action: FilledButton.icon(
            onPressed: prayer.openAppSettings,
            icon: const Icon(Icons.settings_rounded),
            label: Text(s.openSettings),
          ),
          secondary: address,
        ),
      'location_off' => _Message(
          icon: Icons.location_off_rounded,
          title: s.plOffBody,
          action: FilledButton.icon(
            onPressed: prayer.openLocationSettings,
            icon: const Icon(Icons.location_on_rounded),
            label: Text(s.turnOnLocation),
          ),
          secondary: address,
        ),
      'location_failed' => _Message(
          icon: Icons.near_me_disabled_rounded,
          title: s.plFailedBody,
          action: FilledButton.icon(onPressed: _nearMe, icon: const Icon(Icons.refresh_rounded), label: Text(s.retry)),
          secondary: address,
        ),
      _ => _Message(
          icon: Icons.wifi_off_rounded,
          title: s.plLoadFailed,
          action: FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded), label: Text(s.retry)),
        ),
    };
  }
}

/// One of the two ways to look, large, as on the web page.
class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = selected ? Brand.emerald800 : Colors.white;
    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: selected ? 1 : 0.35)),
      ),
      elevation: selected ? 3 : 0,
      shadowColor: Colors.black38,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        child: Semantics(
          button: true,
          selected: selected,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: ink, size: 26),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.25, fontWeight: FontWeight.w800, color: ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The address to look around: typed in Korean, or one searched before.
class _AddressPanel extends StatelessWidget {
  const _AddressPanel({
    required this.controller,
    required this.focus,
    required this.example,
    required this.error,
    required this.busy,
    required this.recent,
    required this.onSearch,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final String example;
  final String? error;
  final bool busy;
  final List<String> recent;
  final void Function([String? text]) onSearch;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final error = this.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          shadowColor: Colors.black26,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focus,
                  enabled: !busy,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  onChanged: (_) => onChanged(),
                  style: const TextStyle(fontSize: 16, color: Color(0xFF292524)),
                  decoration: InputDecoration(
                    hintText: example,
                    hintStyle: const TextStyle(color: Color(0xFFA8A29E)),
                    prefixIcon: const Icon(Icons.place_outlined, color: Brand.emerald700),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: FilledButton(
                  onPressed: busy ? null : () => onSearch(),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 16)),
                  child: Text(s.plSearchButton),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error ?? s.plAddressTip,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            fontWeight: error == null ? FontWeight.w400 : FontWeight.w700,
            color: error == null ? const Color(0xE6FFFFFF) : const Color(0xFFFDE68A),
          ),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(s.plRecentAddresses, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white70)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final address in recent)
                Material(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: StadiumBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.35))),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: busy ? null : () => onSearch(address),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Where the five were measured from: the phone just now, the location
/// saved earlier (said plainly, since it can be far off), or the address.
class _Origin extends StatelessWidget {
  const _Origin({required this.found, required this.now, required this.onAgain});

  final PlacesFound found;
  final DateTime now;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final when = found.at == null ? '' : ageText(s, now.difference(found.at!));
    final (icon, text, warn) = switch (found.origin) {
      PlaceOrigin.here => (
          Icons.my_location_rounded,
          found.label == null ? s.plHereNowNoCity(when) : s.plHereNow(found.label!, when),
          false,
        ),
      PlaceOrigin.saved => (
          Icons.history_rounded,
          found.label == null
              ? s.plSavedNoteNoCity(when.toLowerCase())
              : s.plSavedNote(found.label!, when.toLowerCase()),
          true,
        ),
      PlaceOrigin.address => (Icons.place_rounded, found.label ?? '', false),
    };
    return Row(
      children: [
        const SizedBox(width: 4),
        Icon(icon, size: 16, color: warn ? p.gold : p.accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, height: 1.35, color: warn ? p.inkSoft : p.inkMuted)),
        ),
        TextButton(
          onPressed: onAgain,
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          child: Text(found.origin == PlaceOrigin.address ? s.plChange : s.plRelocate),
        ),
      ],
    );
  }
}

/// "Just now", "5 min ago", "3 hours ago", "2 days ago".
String ageText(AppLocalizations s, Duration age) {
  if (age.inMinutes < 1) return s.locationJustNow;
  if (age.inHours < 1) return s.locationMinutesAgo(age.inMinutes);
  if (age.inDays < 1) return s.locationHoursAgo(age.inHours);
  return s.locationDaysAgo(age.inDays);
}

/// A place found: its photos, how far, its name, rating and address, and
/// the call and the way there right on it.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.kit,
    required this.place,
    required this.km,
    required this.onTap,
    this.nearest = false,
  });

  final PlacesKit kit;
  final Place place;
  final double? km;
  final bool nearest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final km = this.km;
    final watched = kit.watching(place.id);
    void open() {
      HapticFeedback.selectionClick();
      onTap();
    }

    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: p.hairline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 188,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlacePhotos(kit: kit, place: place, onTap: open),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Row(
                      children: [
                        if (km != null) _Chip(icon: Icons.near_me_rounded, text: distanceText(s, km)),
                        if (nearest) ...[
                          const SizedBox(width: 6),
                          _Chip(text: s.plNearest, colour: Brand.emerald700),
                        ],
                      ],
                    ),
                  ),
                  if (watched)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: _Chip(icon: Icons.notifications_active_rounded, text: s.plWatchingBadge, colour: const Color(0xCC8A6508)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: Brand.displayFont, fontSize: 19, height: 1.25, fontWeight: FontWeight.w700, color: p.ink),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (place.city != null)
                        Flexible(
                          child: Text(
                            place.city!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: p.accent),
                          ),
                        ),
                      if (place.city != null) const SizedBox(width: 10),
                      if (place.reviewCount > 0) ...[
                        PlaceStars(place.rating, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${place.rating.toStringAsFixed(1)} (${place.reviewCount})',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.inkSoft),
                        ),
                      ] else
                        Flexible(
                          child: Text(s.plNoReviews, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                        ),
                    ],
                  ),
                  if (place.address != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 15, color: p.inkMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: p.inkSoft),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (place.phones.isNotEmpty)
                          PlaceMiniAction(
                            icon: Icons.call_rounded,
                            label: s.plCall,
                            onTap: () => callPlace(context, kit.services, place),
                          ),
                        PlaceMiniAction(
                          icon: Icons.directions_rounded,
                          label: s.plRoute,
                          onTap: () => routeToPlace(context, kit.services, place),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: open,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text(s.plDetails), const Icon(Icons.chevron_right_rounded, size: 20)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small label on a photo.
class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.icon, this.colour = const Color(0xB3000000)});

  final String text;
  final IconData? icon;
  final Color colour;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 4)],
              Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
      );
}

class _Status extends StatelessWidget {
  const _Status({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
      child: Row(
        children: [
          SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: p.accent)),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: p.inkSoft)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.body, this.action, this.secondary});

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return PlacesCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 40, color: p.accent),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 15.5, height: 1.45, fontWeight: FontWeight.w700, color: p.ink)),
          if (body case final body?) ...[
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft)),
          ],
          if (action case final action?) ...[const SizedBox(height: 16), action],
          if (secondary case final secondary?) ...[const SizedBox(height: 8), secondary],
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        height: 300,
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: p.hairline)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 188,
              decoration: BoxDecoration(color: p.badge, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            ),
          ],
        ),
      ),
    );
  }
}

/// A place that isn't listed: told in the group, as on the web.
class _Missing extends StatelessWidget {
  const _Missing({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Material(
      color: p.gold.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.gold.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.add_location_alt_rounded, color: p.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.plMissingTitle, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink)),
                    const SizedBox(height: 2),
                    Text(s.plMissingBody, style: TextStyle(fontSize: 13, color: p.inkSoft)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, size: 18, color: p.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
