import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/prayer_controller.dart';
import 'place_actions.dart';
import 'place_detail.dart';
import 'places_kit.dart';
import 'places_models.dart';
import 'places_parts.dart';

/// Where people tell other people's places to go: the group.
const placesGroupUrl = 'https://t.me/MuslimVegukin';

/// Mosques, halal restaurants and shops in Korea: every one of a kind, the
/// nearest first (from the location the prayer times use), found by name,
/// city or a Korean address, with a call or the way there one tap away.
class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key, required this.services, required this.kind});

  final AppServices services;
  final PlaceKind kind;

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

/// An address the server found, to measure from.
typedef _Around = ({String text, double lat, double lon, String? label});

class _PlacesScreenState extends State<PlacesScreen> {
  late final PlacesKit _kit = PlacesKit(widget.services);
  late PlaceKind _kind = widget.kind;
  final _search = TextEditingController();
  String _query = '';
  String? _city;

  _Around? _around;

  /// Before update 6: the places the server found near the address.
  List<Place>? _aroundFew;
  bool _finding = false;

  @override
  void initState() {
    super.initState();
    unawaited(_kit.load(_kind));
    unawaited(_kit.loadPhotos());
    unawaited(_kit.loadWatched());
  }

  @override
  void dispose() {
    _search.dispose();
    _kit.dispose();
    super.dispose();
  }

  void _setKind(PlaceKind kind) {
    if (kind == _kind) return;
    HapticFeedback.selectionClick();
    setState(() {
      _kind = kind;
      _city = null;
      _aroundFew = null;
    });
    unawaited(_kit.load(kind));
    if (_around case final around?) unawaited(_findAround(around.text));
  }

  void _onQuery(String query) => setState(() {
        _query = query;
        if (_around != null && query.trim() != _around!.text) {
          _around = null;
          _aroundFew = null;
        }
      });

  Future<void> _findAround(String address) async {
    FocusScope.of(context).unfocus();
    setState(() => _finding = true);
    try {
      final found = await _kit.nearAddress(_kind, address);
      if (!mounted) return;
      if (found.lat == null || found.lon == null) throw const PlacesException('http_404', 404);
      setState(() {
        _around = (text: address, lat: found.lat!, lon: found.lon!, label: found.label);
        _aroundFew = _kit.fewOnly ? found.places : null;
        _city = null;
      });
    } on PlacesException catch (e) {
      if (!mounted) return;
      final s = AppLocalizations.of(context);
      showPlacesSnack(context, e.status == 404 ? s.plAddressNotFound : placesMessage(s, e.code));
    } finally {
      if (mounted) setState(() => _finding = false);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _kit.load(_kind, refresh: true),
      _kit.loadWatched(),
    ]);
  }

  void _open(Place place) => openPlace(context, _kit, place);

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Scaffold(
      backgroundColor: p.page,
      body: ListenableBuilder(
        listenable: Listenable.merge([_kit, widget.services.prayer]),
        builder: (context, _) {
          final around = _around;
          final searching = _query.trim().isNotEmpty && around == null;
          final all = _kit.placesOf(_kind);
          final shown = _aroundFew ??
              _kit.find(
                _kind,
                city: _city,
                query: around == null ? _query : '',
                from: around == null ? null : (lat: around.lat, lon: around.lon),
              );
          final byDistance = around != null || _kit.here != null || _kit.fewOnly;
          final failure = _kit.failureOf(_kind);
          final cities = _kit.fewOnly ? const <(String, int)>[] : _kit.citiesOf(_kind);
          final recent = searching || around != null ? const <Place>[] : _kit.recent.where((r) => r.kind == _kind).take(8).toList();
          final hangul = searching && hasHangul(_query) && _query.trim().length >= 2;

          return RefreshIndicator(
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
                SliverToBoxAdapter(
                  child: _Hero(
                    kind: _kind,
                    onKind: _setKind,
                    controller: _search,
                    onChanged: _onQuery,
                    onSubmitted: (q) {
                      if (hasHangul(q) && q.trim().length >= 2) unawaited(_findAround(q.trim()));
                    },
                    location: _LocationLine(kit: _kit, kind: _kind),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(14, 12, 14, 28 + MediaQuery.paddingOf(context).bottom),
                  sliver: SliverList.list(
                    children: [
                      if (hangul) ...[
                        _AroundOffer(address: _query.trim(), busy: _finding, onTap: () => _findAround(_query.trim())),
                        const SizedBox(height: 10),
                      ],
                      if (around != null) ...[
                        _AroundBanner(
                          text: s.plNearAddress(around.label ?? around.text),
                          onClear: () {
                            HapticFeedback.selectionClick();
                            _search.clear();
                            setState(() {
                              _query = '';
                              _around = null;
                              _aroundFew = null;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (recent.isNotEmpty) ...[
                        _Label(icon: Icons.history_rounded, text: s.plRecent),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: recent.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, i) => ActionChip(
                              avatar: Text(recent[i].kind.emoji),
                              label: Text(recent[i].name),
                              backgroundColor: p.card,
                              side: BorderSide(color: p.hairline),
                              onPressed: () => _open(_kit.placesOf(_kind)?.where((x) => x.id == recent[i].id).firstOrNull ?? recent[i]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (cities.length > 1 && !searching && around == null) ...[
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: cities.length + 1,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final city = i == 0 ? null : cities[i - 1].$1;
                              final selected = _city == city;
                              return ChoiceChip(
                                label: Text(i == 0 ? s.plAllCities : '${cities[i - 1].$1} · ${cities[i - 1].$2}'),
                                selected: selected,
                                showCheckmark: false,
                                selectedColor: p.action,
                                backgroundColor: p.card,
                                side: BorderSide(color: selected ? p.action : p.hairline),
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : p.inkSoft,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _city = city);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (all == null && failure == null && _aroundFew == null)
                        for (var i = 0; i < 5; i++) const _SkeletonCard()
                      else if (all == null && failure == 'needs_location' && _aroundFew == null)
                        _Message(icon: Icons.near_me_rounded, title: s.plNeedsLocation)
                      else if (all == null && failure != null && _aroundFew == null)
                        _Message(
                          icon: Icons.wifi_off_rounded,
                          title: s.plLoadFailed,
                          action: FilledButton.tonalIcon(
                            onPressed: () => _kit.load(_kind, refresh: true),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(s.retry),
                          ),
                        )
                      else if (shown.isEmpty)
                        _Message(
                          icon: searching ? Icons.search_off_rounded : Icons.place_outlined,
                          title: searching
                              ? s.plNothingFound
                              : switch (_kind) {
                                  PlaceKind.mosque => s.plNoneYetMosque,
                                  PlaceKind.restaurant => s.plNoneYetRestaurant,
                                  PlaceKind.shop => s.plNoneYetShop,
                                },
                          body: searching && !hangul ? s.plNothingFoundHint : null,
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                          child: Text(
                            [
                              kindCount(s, _kind, shown.length),
                              if (!searching) byDistance ? s.plSortedNearest : s.plSortedCity,
                            ].join(' · '),
                            style: TextStyle(fontSize: 13, color: p.inkMuted),
                          ),
                        ),
                        for (final (i, place) in shown.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PlaceCard(
                              kit: _kit,
                              place: place,
                              km: around != null ? place.distanceFrom(around.lat, around.lon) : _kit.distanceTo(place),
                              nearest: i == 0 && byDistance && !searching && _city == null,
                              onTap: () => _open(place),
                            ),
                          ),
                      ],
                      const SizedBox(height: 8),
                      _Missing(onTap: () => widget.services.openLink(Uri.parse(placesGroupUrl))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.kind,
    required this.onKind,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.location,
  });

  final PlaceKind kind;
  final ValueChanged<PlaceKind> onKind;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final Widget location;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    const radius = BorderRadius.vertical(bottom: Radius.circular(26));
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
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (final k in PlaceKind.values) ...[
                      Expanded(child: _KindTab(kind: k, selected: k == kind, onTap: () => onKind(k))),
                      if (k != PlaceKind.values.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 2,
                  shadowColor: Colors.black26,
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF292524)),
                    decoration: InputDecoration(
                      hintText: s.plSearchHint,
                      hintStyle: const TextStyle(color: Color(0xFF78716C)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Brand.emerald700),
                      suffixIcon: ListenableBuilder(
                        listenable: controller,
                        builder: (context, _) => controller.text.isEmpty
                            ? const SizedBox.shrink()
                            : IconButton(
                                onPressed: () {
                                  controller.clear();
                                  onChanged('');
                                },
                                tooltip: s.plClearSearch,
                                icon: const Icon(Icons.close_rounded, color: Color(0xFF78716C)),
                              ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                location,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KindTab extends StatelessWidget {
  const _KindTab({required this.kind, required this.selected, required this.onTap});

  final PlaceKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.12),
      shape: StadiumBorder(side: BorderSide(color: Colors.white.withValues(alpha: selected ? 1 : 0.25))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(kind.emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  kindPlural(s, kind),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Brand.emerald800 : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where distances are measured from, with a way to measure again; or how
/// to turn location on.
class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.kit, required this.kind});

  final PlacesKit kit;
  final PlaceKind kind;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final prayer = kit.services.prayer;
    final here = kit.here;
    const soft = TextStyle(fontSize: 13, height: 1.3, color: Color(0xE6FFFFFF));
    Widget line(IconData icon, String text, {String? action, VoidCallback? onAction, bool busy = false}) => Row(
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: soft)),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              )
            else if (action != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
                child: Text(action, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
          ],
        );
    void locate() {
      HapticFeedback.lightImpact();
      unawaited(kit.locate(kind));
    }

    if (prayer.locating) return line(Icons.near_me_rounded, s.locating, busy: true);
    if (here != null) {
      final when = ageText(s, prayer.now.difference(here.timestamp));
      return line(
        Icons.near_me_rounded,
        here.city == null ? s.plAroundHere(when) : s.plAround(here.city!, when),
        action: s.refreshLocation,
        onAction: locate,
      );
    }
    return switch (prayer.status) {
      PrayerStatus.permissionBlocked =>
        line(Icons.location_disabled_rounded, s.plLocateBlocked, action: s.openSettings, onAction: prayer.openAppSettings),
      PrayerStatus.locationOff =>
        line(Icons.location_off_rounded, s.plLocateOff, action: s.turnOnLocation, onAction: prayer.openLocationSettings),
      PrayerStatus.locationFailed => line(Icons.near_me_disabled_rounded, s.plLocateFailed, action: s.retry, onAction: locate),
      _ => line(Icons.near_me_rounded, s.plLocatePrompt, action: s.plLocateButton, onAction: locate),
    };
  }
}

/// "Just now", "5 min ago", "3 hours ago", "2 days ago".
String ageText(AppLocalizations s, Duration age) {
  if (age.inMinutes < 1) return s.locationJustNow;
  if (age.inHours < 1) return s.locationMinutesAgo(age.inMinutes);
  if (age.inDays < 1) return s.locationHoursAgo(age.inHours);
  return s.locationDaysAgo(age.inDays);
}

/// A place in the list: its picture, name, where and how far, its reviews,
/// and the call and the way there right on it.
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
    return PlacesCard(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlaceThumb(kit: kit, place: place),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16, height: 1.25, fontWeight: FontWeight.w700, color: p.ink),
                          ),
                        ),
                        if (watched) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.notifications_active_rounded, size: 18, color: p.gold, semanticLabel: s.plWatchingBadge),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(children: [
                        if (km != null)
                          TextSpan(
                            text: distanceText(s, km),
                            style: TextStyle(fontWeight: FontWeight.w800, color: p.accent),
                          ),
                        if (km != null && place.city != null) const TextSpan(text: ' · '),
                        if (place.city != null) TextSpan(text: place.city),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, color: p.inkSoft),
                    ),
                    const SizedBox(height: 4),
                    if (place.reviewCount > 0)
                      Row(
                        children: [
                          PlaceStars(place.rating, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            '${place.rating.toStringAsFixed(1)} · ${s.plReviewCount(place.reviewCount)}',
                            style: TextStyle(fontSize: 12.5, color: p.inkMuted),
                          ),
                        ],
                      )
                    else
                      Text(s.plNoReviews, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                  ],
                ),
              ),
            ],
          ),
          if (place.address != null) ...[
            const SizedBox(height: 8),
            Text(
              place.address!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: p.inkMuted),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (place.phones.isNotEmpty) ...[
                Flexible(
                  flex: 0,
                  child: PlaceMiniAction(
                    icon: Icons.call_rounded,
                    label: s.plCall,
                    onTap: () => callPlace(context, kit.services, place),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                flex: 0,
                child: PlaceMiniAction(
                  icon: Icons.directions_rounded,
                  label: s.plRoute,
                  onTap: () => routeToPlace(context, kit.services, place),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: nearest
                    ? Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: p.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Text(
                              s.plNearest,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.accent),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Search near 역삼동": the server finds the address, the list measures
/// from there.
class _AroundOffer extends StatelessWidget {
  const _AroundOffer({required this.address, required this.busy, required this.onTap});

  final String address;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return PlacesCard(
      onTap: busy ? null : onTap,
      color: p.cardSelected,
      child: Row(
        children: [
          Icon(Icons.travel_explore_rounded, color: p.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  busy ? s.plFinding : s.plSearchNear(address),
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink),
                ),
                const SizedBox(height: 2),
                Text(s.plSearchNearHint, style: TextStyle(fontSize: 12.5, color: p.inkSoft)),
              ],
            ),
          ),
          busy
              ? SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: p.accent))
              : Icon(Icons.chevron_right_rounded, color: p.accent),
        ],
      ),
    );
  }
}

class _AroundBanner extends StatelessWidget {
  const _AroundBanner({required this.text, required this.onClear});

  final String text;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(
        color: p.cardSelected,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.place_rounded, size: 18, color: p.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink)),
          ),
          IconButton(
            onPressed: onClear,
            tooltip: AppLocalizations.of(context).plClearSearch,
            icon: Icon(Icons.close_rounded, color: p.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: p.inkMuted),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.inkMuted)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.body, this.action});

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 44, color: p.inkMuted),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 15.5, height: 1.4, fontWeight: FontWeight.w600, color: p.inkSoft)),
          if (body case final body?) ...[
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, height: 1.4, color: p.inkMuted)),
          ],
          if (action case final action?) ...[const SizedBox(height: 14), action],
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        height: 132,
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.hairline)),
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
