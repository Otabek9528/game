import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_screen.dart';
import 'place_actions.dart';
import 'place_map.dart';
import 'place_sheets.dart';
import 'places_kit.dart';
import 'places_models.dart';
import 'places_parts.dart';
import 'places_screen.dart';

/// A place from a search: its page shows at once what the search knew,
/// with how far it is from the point searched around.
void openPlace(BuildContext context, PlacesKit kit, Place place, {double? km, PlaceOrigin? origin}) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => PlaceDetailScreen(kit: kit, id: place.id, preview: place, km: km, origin: origin),
  ));
}

/// A place from a notification or a link, by its number.
void openPlaceById(BuildContext context, AppServices services, int id) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _OwnKit(services: services, id: id)));
}

/// The place page with a kit of its own, for when no list opened it.
class _OwnKit extends StatefulWidget {
  const _OwnKit({required this.services, required this.id});

  final AppServices services;
  final int id;

  @override
  State<_OwnKit> createState() => _OwnKitState();
}

class _OwnKitState extends State<_OwnKit> {
  late final PlacesKit _kit = PlacesKit(widget.services);

  @override
  void dispose() {
    _kit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PlaceDetailScreen(kit: _kit, id: widget.id);
}

/// A place: where it is, how to call and get there, what it's like and
/// what people say, and its news by notification.
class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({super.key, required this.kit, required this.id, this.preview, this.km, this.origin});

  final PlacesKit kit;
  final int id;

  /// What the list knew, shown while the page loads.
  final Place? preview;

  /// How far it is from where the search looked: the phone, or an address.
  final double? km;
  final PlaceOrigin? origin;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  PlacesKit get _kit => widget.kit;
  AppServices get _services => _kit.services;

  late PlaceDetail? _detail = _kit.detailOf(widget.id);
  String? _error;
  bool _allReviews = false;
  bool _claimSent = false;
  final _scroll = ScrollController();
  final _reviewsKey = GlobalKey();
  bool _collapsed = false;

  static const _heroHeight = 268.0;

  /// The page's rounded top edge, over the bottom of the photo.
  static const _lip = 22.0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    unawaited(_kit.loadPhotos());
    _scroll.addListener(() {
      final collapsed = _scroll.hasClients && _scroll.offset > _heroHeight - kToolbarHeight - _lip - 16;
      if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final detail = await _kit.loadDetail(widget.id);
      if (mounted) setState(() => _detail = detail);
    } on PlacesException catch (e) {
      if (mounted) setState(() => _error = e.code);
    }
  }

  void _set(PlaceDetail detail) {
    setState(() => _detail = detail);
    _kit.putDetail(detail);
  }

  void _say(String text, {SnackBarAction? action}) => showPlacesSnack(context, text, action: action);

  /// Signed in, or asked to; true when signed in now (its reviews then
  /// reread, so one's own is known).
  Future<bool> _signedIn() async {
    if (_services.account.signedIn) return true;
    final signedIn = await askToSignIn(context, _services);
    if (signedIn) await _load();
    return signedIn && mounted;
  }

  Future<void> _toggleWatch() async {
    final detail = _detail;
    if (detail == null) return;
    final s = AppLocalizations.of(context);
    final on = !detail.watch.watching;
    HapticFeedback.lightImpact();
    _set(detail.copyWith(watch: detail.watch.copyWith(watching: on, count: math.max(0, detail.watch.count + (on ? 1 : -1)))));
    try {
      final auth = await _kit.auth();
      if (auth.isEmpty) throw const PlacesException('offline');
      final answer = await _kit.source.watch(auth, widget.id, on: on, lang: _kit.language.code);
      if (!mounted) return;
      _set(_detail!.copyWith(watch: _detail!.watch.copyWith(watching: answer.watching, count: answer.count)));
      if (on && !_services.account.pushAllowed) {
        _say(s.plWatchNoPush, action: SnackBarAction(label: s.plWatchPushOn, onPressed: _services.permissions.openAppSettings));
      } else {
        _say(on ? s.plWatchOn : s.plWatchOff);
      }
    } on PlacesException catch (e) {
      if (!mounted) return;
      _set(detail);
      _say(placesMessage(s, e.code));
    }
  }

  Future<void> _review() async {
    if (!await _signedIn()) return;
    final detail = _detail;
    if (detail == null || !mounted) return;
    final s = AppLocalizations.of(context);
    final outcome = await showPlaceSheet<ReviewOutcome>(context, ReviewSheet(kit: _kit, detail: detail));
    if (outcome == null || !mounted) return;
    _say(switch (outcome) {
      ReviewOutcome.published => s.plReviewPublished,
      ReviewOutcome.updated => s.plReviewUpdated,
      ReviewOutcome.deleted => s.plReviewDeleted,
    });
    await _load();
  }

  Future<void> _suggest(List<String> fields) async {
    if (fields.isEmpty || !await _signedIn()) return;
    if (!mounted) return;
    final field = fields.length == 1 ? fields.single : await pickSuggestField(context, fields);
    final detail = _detail;
    if (field == null || detail == null || !mounted) return;
    final sent = await showPlaceSheet<bool>(context, SuggestSheet(kit: _kit, place: detail.place, field: field));
    if (sent != true || !mounted) return;
    _set(_detail!.copyWith(pending: {..._detail!.pending, field}));
    _say(AppLocalizations.of(context).plSuggestSent);
  }

  Future<void> _announce() async {
    if (!await _signedIn()) return;
    final detail = _detail;
    if (detail == null || !mounted) return;
    final pending = await showPlaceSheet<int>(context, AnnounceSheet(kit: _kit, place: detail.place));
    if (pending == null || !mounted) return;
    _set(_detail!.copyWith(watch: _detail!.watch.copyWith(pendingAnnouncements: pending)));
    _say(AppLocalizations.of(context).plAnnounceSent);
  }

  Future<void> _claim() async {
    if (!await _signedIn() || !mounted) return;
    final s = AppLocalizations.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.plClaimPrompt),
        content: Text(s.plClaimConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.plCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(s.plClaimContinue)),
        ],
      ),
    );
    if (go != true || !mounted) return;
    try {
      final auth = await _kit.auth();
      if (auth.isEmpty) throw const PlacesException('offline');
      await _kit.source.claim(auth, widget.id, _kit.language.code);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _claimSent = true);
      _set(_detail!.copyWith(watch: _detail!.watch.copyWith(claimPending: true)));
      _say(s.plClaimSent);
    } on PlacesException catch (e) {
      if (!mounted) return;
      if (e.code == 'has_owner') _set(_detail!.copyWith(watch: _detail!.watch.copyWith(hasOwner: true)));
      _say(placesMessage(s, e.code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final detail = _detail;
    final place = detail?.place ?? widget.preview;
    if (place == null) {
      return Scaffold(
        backgroundColor: p.page,
        appBar: AppBar(backgroundColor: p.page, surfaceTintColor: Colors.transparent),
        body: _error == null
            ? const Center(child: CircularProgressIndicator())
            : _Failed(code: _error!, onRetry: _load),
      );
    }
    final km = widget.km;
    final distance = km == null
        ? null
        : widget.origin == PlaceOrigin.address
            ? s.plKmFromAddress(distanceText(s, km))
            : s.plKmFromYou(distanceText(s, km));
    return Scaffold(
      backgroundColor: p.page,
      body: ListenableBuilder(
        listenable: _kit,
        builder: (context, _) => CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: _heroHeight,
              backgroundColor: _collapsed ? p.hero.first : Colors.transparent,
              surfaceTintColor: Colors.transparent,
              foregroundColor: Colors.white,
              systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
              leading: _Round(plain: _collapsed, child: BackButton(color: _collapsed ? Colors.white : const Color(0xFF292524))),
              title: _collapsed
                  ? Text(place.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white))
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: PlacePhotos(
                  kit: _kit,
                  place: place,
                  counter: true,
                  inset: _lip,
                  onPhoto: (i) => showPlacePhotos(context, _kit.photosOf(place), i),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(_lip),
                child: Container(
                  height: _lip,
                  decoration: BoxDecoration(
                    color: p.page,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(_lip + 2)),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 28 + MediaQuery.paddingOf(context).bottom),
              sliver: SliverList.list(
                children: [
                  // Most wanted first: what it is, the way there, a call;
                  // then what it's like, what people say, its news.
                  _Head(
                    place: place,
                    distance: distance,
                    watch: detail?.watch,
                    reviews: detail?.reviews.length ?? place.reviewCount,
                    rating: detail?.average ?? place.rating,
                    onWatch: detail == null ? null : _toggleWatch,
                    onReviews: () {
                      final target = _reviewsKey.currentContext;
                      if (target != null) Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 350));
                    },
                  ),
                  _Section(title: s.plGettingThere, child: _Location(place: place, services: _services)),
                  if (place.phones.isNotEmpty || place.menuUrl != null)
                    _Section(title: s.plContact, child: _Contact(place: place, services: _services)),
                  if (_error != null && detail == null) ...[
                    const SizedBox(height: 16),
                    _Failed(code: _error!, onRetry: _load),
                  ] else if (detail == null) ...[
                    const SizedBox(height: 36),
                    const Center(child: CircularProgressIndicator()),
                  ] else ...[
                    _Section(title: s.plAbout, child: _About(detail: detail, onSuggest: () => _suggest(const ['note']))),
                    _Social(detail: detail, services: _services, onSuggest: _suggest),
                    KeyedSubtree(
                      key: _reviewsKey,
                      child: _Reviews(
                        detail: detail,
                        language: _kit.language,
                        all: _allReviews,
                        onAll: () => setState(() => _allReviews = true),
                        onWrite: _review,
                      ),
                    ),
                    _Community(
                      detail: detail,
                      claimSent: _claimSent,
                      onAnnounce: _announce,
                      onClaim: _claim,
                    ),
                  ],
                  const SizedBox(height: 26),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _services.openLink(Uri.parse(placesGroupUrl)),
                      style: TextButton.styleFrom(foregroundColor: p.inkMuted),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: Text(s.plCorrections, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
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

/// A part of the page: its title, and what's under it.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [PlacesHeading(title, trailing: trailing), child],
      );
}

/// A white disc behind the top bar's buttons while they float over the
/// picture; nothing once the bar is green.
class _Round extends StatelessWidget {
  const _Round({required this.child, required this.plain});

  final Widget child;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    if (plain) return child;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xEEFFFFFF),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 6)],
        ),
        child: child,
      ),
    );
  }
}

/// Where it is: the map, a navigator in one tap (Naver and Kakao first:
/// they route best in Korea; Google gives transit only here), and the
/// address, copied with a tap.
class _Location extends StatelessWidget {
  const _Location({required this.place, required this.services});

  final Place place;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final address = place.address;
    return PlacesCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (place.located)
            SizedBox(
              height: 168,
              child: PlaceMap(lat: place.lat!, lon: place.lon!, colour: kindColour(context, place.kind), emoji: place.kind.emoji),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: _NavButton(
                    mark: 'N',
                    name: 'Naver',
                    brand: const Color(0xFF03C75A),
                    onMark: Colors.white,
                    onTap: () => services.openLink(naverUri(place)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NavButton(
                    mark: 'K',
                    name: 'Kakao',
                    brand: const Color(0xFFFEE500),
                    onMark: const Color(0xFF191600),
                    onTap: () => services.openLink(kakaoUri(place)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NavButton(
                    mark: 'G',
                    name: 'Google',
                    brand: const Color(0xFF4285F4),
                    onMark: Colors.white,
                    onTap: () => services.openLink(googleUri(place)),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 18, indent: 16, endIndent: 16, color: p.hairline),
          _InfoRow(
            icon: Icons.place_rounded,
            label: s.plAddress,
            value: address ?? s.plNoAddress,
            muted: address == null,
            action: address == null ? null : _RowAction(Icons.copy_rounded, s.plCopyAddress),
            onTap: address == null ? null : () => copyAddress(context, place),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// A navigator, big enough to hit without looking: its mark on its
/// colour, its name under it.
class _NavButton extends StatelessWidget {
  const _NavButton({required this.mark, required this.name, required this.brand, required this.onMark, required this.onTap});

  final String mark;
  final String name;
  final Color brand;
  final Color onMark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    // A wash of the brand on light (Kakao's pale yellow a little more);
    // on dark, washes turn muddy: the page's own raised colour.
    final tint = Theme.of(context).brightness == Brightness.dark
        ? p.cardSelected
        : brand.withValues(alpha: brand.computeLuminance() > 0.5 ? 0.22 : 0.11);
    return Semantics(
      button: true,
      label: '$name Map',
      child: ExcludeSemantics(
        child: Material(
          color: tint,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: SizedBox(
              height: 78,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: brand,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: brand.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Text(mark, style: TextStyle(fontSize: 17, height: 1, fontWeight: FontWeight.w900, color: onMark)),
                  ),
                  const SizedBox(height: 7),
                  Text(name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.ink)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A line of the page's facts: an icon, what it is, the value, and what a
/// tap does at its end.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.value,
    this.label,
    this.detail,
    this.action,
    this.onTap,
    this.muted = false,
    this.below,
  });

  final IconData icon;

  /// What it is, small above: "Telefon".
  final String? label;
  final String value;

  /// A word more, under the value.
  final String? detail;
  final Widget? action;
  final VoidCallback? onTap;
  final bool muted;

  /// More under the value: a line waiting for review.
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: muted ? p.badge : p.cardSelected, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: muted ? p.inkMuted : p.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label case final label?) ...[
                      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.inkMuted)),
                      const SizedBox(height: 2),
                    ],
                    Text(value, style: TextStyle(fontSize: 15, height: 1.35, fontWeight: FontWeight.w600, color: muted ? p.inkMuted : p.ink)),
                    if (detail case final detail?) ...[
                      const SizedBox(height: 2),
                      Text(detail, style: TextStyle(fontSize: 13, height: 1.35, color: p.inkSoft)),
                    ],
                    ?below,
                  ],
                ),
              ),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({
    required this.place,
    required this.distance,
    required this.watch,
    required this.reviews,
    required this.rating,
    required this.onWatch,
    required this.onReviews,
  });

  final Place place;

  /// "Sizdan 1.4 km": from where the search looked.
  final String? distance;
  final PlaceWatch? watch;
  final int reviews;
  final double rating;
  final VoidCallback? onWatch;
  final VoidCallback onReviews;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final colour = kindColour(context, place.kind);
    final distance = this.distance;
    final watch = this.watch;
    final kindName = switch (place.kind) {
      PlaceKind.mosque => s.plMosque,
      PlaceKind.restaurant => s.plRestaurant,
      PlaceKind.shop => s.plShop,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: colour.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  '${place.kind.emoji}  ${kindName.toUpperCase()}',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: colour),
                ),
              ),
            ),
            const Spacer(),
            if (watch != null) _WatchPill(watch: watch, onTap: onWatch),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          place.name,
          style: TextStyle(fontFamily: Brand.displayFont, fontSize: 26, height: 1.2, fontWeight: FontWeight.w700, color: p.ink),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(children: [
            if (distance != null) TextSpan(text: distance, style: TextStyle(fontWeight: FontWeight.w800, color: p.accent)),
            if (distance != null && place.city != null) const TextSpan(text: ' · '),
            if (place.city != null) TextSpan(text: place.city),
          ]),
          style: TextStyle(fontSize: 15, color: p.inkSoft),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: reviews > 0 ? onReviews : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: reviews > 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlaceStars(rating, size: 18),
                      const SizedBox(width: 6),
                      Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink)),
                      const SizedBox(width: 6),
                      Text('· ${s.plReviewCount(reviews)}', style: TextStyle(fontSize: 14, color: p.inkSoft)),
                    ],
                  )
                : Text(s.plNoReviews, style: TextStyle(fontSize: 14, color: p.inkMuted)),
          ),
        ),
      ],
    );
  }
}

class _WatchPill extends StatelessWidget {
  const _WatchPill({required this.watch, required this.onTap});

  final PlaceWatch watch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final on = watch.watching;
    final ink = on ? (Theme.of(context).brightness == Brightness.dark ? p.goldSoft : const Color(0xFF8A6508)) : p.accent;
    return Semantics(
      button: true,
      toggled: on,
      label: [on ? s.plWatchingBadge : s.plWatch, if (watch.count > 0) s.plWatchers(watch.count)].join('. '),
      child: ExcludeSemantics(
        child: Material(
          color: on ? p.gold.withValues(alpha: 0.16) : p.cardSelected,
          shape: StadiumBorder(side: BorderSide(color: on ? p.gold.withValues(alpha: 0.5) : p.accent.withValues(alpha: 0.3))),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(on ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, size: 18, color: ink),
                  const SizedBox(width: 5),
                  Text(on ? s.plWatchingBadge : s.plWatch, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: ink)),
                  if (watch.count > 0) ...[
                    Container(width: 1, height: 14, margin: const EdgeInsets.symmetric(horizontal: 8), color: ink.withValues(alpha: 0.3)),
                    Text('${watch.count}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: ink)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The numbers, each called with a tap, and a restaurant's menu.
class _Contact extends StatelessWidget {
  const _Contact({required this.place, required this.services});

  final Place place;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final rows = [
      for (final phone in place.phones)
        _InfoRow(
          icon: Icons.contact_phone_rounded,
          label: s.plPhone,
          value: phone,
          action: _RowAction(Icons.call_rounded, s.plCallNumber, filled: true),
          onTap: () {
            HapticFeedback.lightImpact();
            services.openLink(telUri(phone));
          },
        ),
      if (place.menuUrl != null)
        _InfoRow(
          icon: Icons.restaurant_menu_rounded,
          label: s.plMenu,
          value: s.plMenuOpen,
          action: _RowAction(Icons.open_in_new_rounded, s.plMenuOpen),
          onTap: () => services.openLink(Uri.parse(place.menuUrl!)),
        ),
    ];
    return PlacesCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 68, endIndent: 16, color: p.hairline),
            r,
          ],
        ],
      ),
    );
  }
}

/// What tapping a contact row does, as a round button at its end.
class _RowAction extends StatelessWidget {
  const _RowAction(this.icon, this.label, {this.filled = false});

  final IconData icon;
  final String label;

  /// The page's colour: the row's main act (a call).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Semantics(
      label: label,
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsetsDirectional.only(start: 10),
        decoration: BoxDecoration(color: filled ? p.accent : p.cardSelected, shape: BoxShape.circle),
        child: Icon(icon, size: 19, color: filled ? Colors.white : p.accent),
      ),
    );
  }
}

/// A line saying a suggestion for this waits for the admin.
class _PendingLine extends StatelessWidget {
  const _PendingLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 16, color: p.gold),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: p.inkSoft))),
        ],
      ),
    );
  }
}

class _About extends StatelessWidget {
  const _About({required this.detail, required this.onSuggest});

  final PlaceDetail detail;
  final VoidCallback onSuggest;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final note = detail.place.note;
    final pending = detail.pending.contains('note');
    return PlacesCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note != null)
            Text(note, style: TextStyle(fontSize: 15, height: 1.55, color: p.ink))
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(Icons.schedule_rounded, size: 19, color: p.inkMuted),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(s.plAboutEmpty, style: TextStyle(fontSize: 14.5, height: 1.45, color: p.inkMuted))),
              ],
            ),
          if (pending)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: _PendingLine(s.plPendingField(s.plNoteLabel)))
          else
            TextButton.icon(
              onPressed: onSuggest,
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), visualDensity: VisualDensity.compact),
              icon: Icon(note == null ? Icons.add_rounded : Icons.edit_outlined, size: 18),
              label: Text(note == null ? s.plAboutAdd : s.plSuggestChange),
            ),
        ],
      ),
    );
  }
}

/// "@vegukin", or "Link" for an invite.
String socialHandle(AppLocalizations s, String field, String url) {
  final uri = Uri.tryParse(url);
  final segments = uri?.pathSegments.where((x) => x.isNotEmpty).toList() ?? const <String>[];
  if (segments.isEmpty) return url;
  if (field == 'telegram' && (segments.first.startsWith('+') || segments.first == 'joinchat')) return s.plInviteLink;
  if (field == 'tiktok' && {'vm.tiktok.com', 'vt.tiktok.com'}.contains(uri?.host)) return s.plInviteLink;
  return '@${segments.first.replaceFirst('@', '')}';
}

/// Its pages, as the web shows them: one wide tile for a single link,
/// equal tiles for two or three. A link once set stays (changes go through
/// the admin); one waiting for review shows as nothing and isn't offered
/// again. The rest offered in a quiet line, not a button.
class _Social extends StatelessWidget {
  const _Social({required this.detail, required this.services, required this.onSuggest});

  final PlaceDetail detail;
  final AppServices services;
  final ValueChanged<List<String>> onSuggest;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final place = detail.place;
    final fields = suggestFields.where((f) => f != 'note');
    final links = [for (final f in fields) if (place.social(f) != null) f];
    final offerable = [for (final f in fields) if (place.social(f) == null && !detail.pending.contains(f)) f];
    if (links.isEmpty && offerable.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlacesHeading(s.plSocial),
        if (links.length == 1)
          _SocialTile(field: links.single, url: place.social(links.single)!, wide: true, services: services)
        else if (links.isNotEmpty)
          Row(
            children: [
              for (final (i, f) in links.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _SocialTile(field: f, url: place.social(f)!, wide: false, services: services)),
              ],
            ],
          ),
        if (offerable.isNotEmpty)
          _QuietPrompt(
            text: links.isEmpty ? s.plSocialEmpty : s.plSocialMore,
            action: s.plSocialAdd,
            onTap: () => onSuggest(offerable),
          ),
      ],
    );
  }
}

class _SocialTile extends StatelessWidget {
  const _SocialTile({required this.field, required this.url, required this.wide, required this.services});

  final String field;
  final String url;
  final bool wide;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final colour = fieldColour(context, field);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = Text(fieldLabel(s, field),
        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: wide ? 15.5 : 13.5, fontWeight: FontWeight.w800, color: p.ink));
    final handle = Text(socialHandle(s, field, url),
        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: wide ? 13 : 11.5, color: p.inkSoft));
    final icon = Icon(fieldIcon(field), size: wide ? 30 : 26, color: colour);
    return Material(
      color: colour.withValues(alpha: dark ? 0.16 : (field == 'tiktok' ? 0.07 : 0.10)),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          services.openLink(Uri.parse(url));
        },
        child: wide
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    icon,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [name, const SizedBox(height: 2), handle]),
                    ),
                    Icon(Icons.open_in_new_rounded, size: 18, color: p.inkMuted),
                  ],
                ),
              )
            : SizedBox(
                height: 96,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [icon, const SizedBox(height: 6), name, const SizedBox(height: 2), handle],
                  ),
                ),
              ),
      ),
    );
  }
}

/// "Do you know …? Add": a sentence with a link in it.
class _QuietPrompt extends StatelessWidget {
  const _QuietPrompt({required this.text, required this.action, required this.onTap});

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$text ', style: TextStyle(fontSize: 14, color: p.inkMuted)),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Text(action, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.accent)),
            ),
          ),
        ],
      ),
    );
  }
}

/// "2-sentabr", "2 сентября", "2 September"; the year when not this one.
String reviewDate(DateTime at, AppLanguage language, DateTime now) {
  final sameYear = at.year == now.year;
  final pattern = language == AppLanguage.uz
      ? (sameYear ? 'd-MMMM' : "y-'yil' d-MMMM")
      : (sameYear ? 'd MMMM' : 'd MMMM y');
  return DateFormat(pattern, language.code).format(at);
}

/// What people say: the average and its spread, the way to add one's own,
/// and the reviews (one's own first), all in one card.
class _Reviews extends StatelessWidget {
  const _Reviews({
    required this.detail,
    required this.language,
    required this.all,
    required this.onAll,
    required this.onWrite,
  });

  final PlaceDetail detail;
  final AppLanguage language;
  final bool all;
  final VoidCallback onAll;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final mine = detail.ownReviews ? detail.myReview : null;
    final ordered = [?mine, ...detail.reviews.where((r) => r != mine)];
    final shown = all ? ordered : ordered.take(3).toList();
    final now = DateTime.now();
    return _Section(
      title: s.plReviews,
      trailing: detail.reviews.isEmpty
          ? null
          : Text('${detail.reviews.length}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.inkMuted)),
      child: PlacesCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (detail.reviews.isEmpty)
              Text(s.plReviewsFirst, style: TextStyle(fontSize: 14.5, height: 1.45, color: p.inkSoft))
            else
              _Summary(detail: detail),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onWrite,
              icon: Icon(mine == null ? Icons.rate_review_outlined : Icons.edit_outlined),
              label: Text(mine == null ? s.plWriteReview : s.plEditReview),
            ),
            const SizedBox(height: 8),
            for (final review in shown) ...[
              Divider(height: 1, color: p.hairline),
              _ReviewItem(
                review: review,
                date: review.at == null ? null : reviewDate(review.at!, language, now),
                onEdit: review.mine ? onWrite : null,
              ),
            ],
            if (!all && ordered.length > 3) ...[
              Divider(height: 1, color: p.hairline),
              TextButton(onPressed: onAll, child: Text(s.plAllReviews(ordered.length))),
            ],
          ],
        ),
      ),
    );
  }
}

/// The average, large, and how many gave each star.
class _Summary extends StatelessWidget {
  const _Summary({required this.detail});

  final PlaceDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final spread = detail.spread;
    final most = spread.reduce(math.max);
    final gold = PlaceStars.colour(context);
    return Row(
      children: [
        Column(
          children: [
            Text(
              detail.average.toStringAsFixed(1),
              style: TextStyle(fontFamily: Brand.displayFont, fontSize: 38, height: 1, fontWeight: FontWeight.w700, color: p.ink),
            ),
            const SizedBox(height: 4),
            PlaceStars(detail.average, size: 15),
            const SizedBox(height: 4),
            Text(s.plReviewCount(detail.reviews.length), style: TextStyle(fontSize: 12, color: p.inkMuted)),
          ],
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            children: [
              for (var star = 5; star >= 1; star--)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(width: 12, child: Text('$star', style: TextStyle(fontSize: 12, color: p.inkMuted))),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: most == 0 ? 0 : spread[star - 1] / most,
                            minHeight: 7,
                            color: gold,
                            backgroundColor: p.badge,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A review in the list: its stars and date, its words; one's own marked,
/// and changed with a tap.
class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.review, required this.date, required this.onEdit});

  final PlaceReview review;
  final String? date;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PlaceStars(review.rating.toDouble(), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: review.mine
                      ? Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              child: Text(
                                s.plYourReview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.accent),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (date != null) Text(date!, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                if (onEdit != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.edit_outlined, size: 16, color: p.accent),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review.text.isEmpty ? s.plNoText : review.text,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: review.text.isEmpty ? p.inkMuted : p.ink,
                fontStyle: review.text.isEmpty ? FontStyle.italic : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// News to the watchers: anyone's for a mosque, the owner's for the rest;
/// and the way to become that owner. One card, a row each.
class _Community extends StatelessWidget {
  const _Community({required this.detail, required this.claimSent, required this.onAnnounce, required this.onClaim});

  final PlaceDetail detail;
  final bool claimSent;
  final VoidCallback onAnnounce;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final watch = detail.watch;
    final mosque = detail.place.kind == PlaceKind.mosque;
    final rows = <Widget>[
      if (watch.isOwner)
        _InfoRow(icon: Icons.verified_rounded, value: s.plYouOwn),
      if (mosque || watch.isOwner)
        _InfoRow(
          icon: Icons.campaign_rounded,
          value: mosque && !watch.isOwner ? s.plAnnounceMosque : s.plAnnounceOwner,
          detail: mosque ? s.plAnnounceWhyMosque : s.plAnnounceWhyOwner,
          below: watch.pendingAnnouncements > 0 ? _PendingLine(s.plAnnouncePending(watch.pendingAnnouncements)) : null,
          action: Icon(Icons.chevron_right_rounded, color: p.inkMuted),
          onTap: onAnnounce,
        ),
      if (!mosque && !watch.hasOwner && !watch.isOwner)
        claimSent || watch.claimPending
            ? _InfoRow(
                icon: Icons.storefront_rounded,
                value: claimSent ? s.plClaimSent : s.plClaimPending,
                muted: true,
              )
            : _InfoRow(
                icon: Icons.storefront_rounded,
                value: s.plClaimPrompt,
                detail: s.plClaimWhy,
                action: Icon(Icons.chevron_right_rounded, color: p.inkMuted),
                onTap: onClaim,
              ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: s.plNewsTitle,
      child: PlacesCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (final (i, r) in rows.indexed) ...[
              if (i > 0) Divider(height: 1, indent: 68, endIndent: 16, color: p.hairline),
              r,
            ],
          ],
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.code, required this.onRetry});

  final String code;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final gone = code == 'place_not_found' || code == 'http_404';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(gone ? Icons.wrong_location_outlined : Icons.wifi_off_rounded, size: 44, color: p.inkMuted),
          const SizedBox(height: 12),
          Text(gone ? s.plGone : s.plLoadDetailFailed, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: p.inkSoft)),
          if (!gone) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(s.retry)),
          ],
        ],
      ),
    );
  }
}
