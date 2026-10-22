import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_screen.dart';
import '../cars/cars_parts.dart' show CarsTabBar, SignInCard;
import 'housing_compose.dart';
import 'housing_parts.dart';
import 'housing_source.dart';

/// Rooms and flats passed on between Uzbeks in Korea, as the Mini App has it:
/// the board (newest, or nearest to an address), one's own posts, alerts
/// for an area, and a new post. Reading needs no sign-in.
class HousingScreen extends StatefulWidget {
  const HousingScreen({super.key, required this.services, this.startPost});

  final AppServices services;

  /// A post to open at once: a notification's.
  final int? startPost;

  /// The post a link names: "…housing.html?post=12".
  static int? postIn(String path) => int.tryParse(Uri.tryParse(path)?.queryParameters['post'] ?? '');

  @override
  State<HousingScreen> createState() => _HousingScreenState();
}

class _HousingScreenState extends State<HousingScreen> {
  late final _kit = HousingKit(widget.services);
  int _tab = 0;
  final _board = GlobalKey<_BoardState>();
  final _mine = GlobalKey<_MineState>();

  @override
  void initState() {
    super.initState();
    if (widget.startPost case final id?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showHousingPost(context, _kit, id, onChanged: _changed);
      });
    }
  }

  void _changed() {
    _board.currentState?.reload();
    _mine.currentState?.load();
  }

  Future<void> _compose() async {
    final s = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    if (!_kit.signedIn && !await askToSignIn(context, widget.services)) return;
    if (!mounted) return;
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => HousingCompose(kit: _kit)));
    if (saved == true && mounted) {
      showHousingSnack(context, s.hsPosted);
      _changed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) setState(() => _tab = 0);
      },
      child: Scaffold(
        backgroundColor: p.page,
        body: IndexedStack(
          index: _tab,
          children: [
            for (final (i, tab) in [
              _Board(key: _board, kit: _kit, onPost: _compose, onChanged: _changed),
              _Mine(key: _mine, kit: _kit, onPost: _compose, onChanged: _changed),
              _Alerts(kit: _kit),
            ].indexed)
              TickerMode(enabled: i == _tab, child: tab),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          backgroundColor: p.card,
          indicatorColor: p.cardSelected,
          onDestinationSelected: (i) {
            if (i == 3) return unawaited(_compose());
            HapticFeedback.selectionClick();
            setState(() => _tab = i);
            if (i == 1) _mine.currentState?.load();
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_work_outlined),
              selectedIcon: Icon(Icons.home_work_rounded, color: p.accent),
              label: s.hsTabBoard,
            ),
            NavigationDestination(
              icon: const Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article_rounded, color: p.accent),
              label: s.hsTabMine,
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_none_rounded),
              selectedIcon: Icon(Icons.notifications_rounded, color: p.accent),
              label: s.hsTabAlerts,
            ),
            NavigationDestination(
              icon: Container(
                width: 40,
                height: 32,
                decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
              label: s.hsTabPost,
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ the board

class _Board extends StatefulWidget {
  const _Board({super.key, required this.kit, required this.onPost, required this.onChanged});

  final HousingKit kit;
  final VoidCallback onPost;
  final VoidCallback onChanged;

  @override
  State<_Board> createState() => _BoardState();
}

class _BoardState extends State<_Board> with AutomaticKeepAliveClientMixin {
  HousingKit get _kit => widget.kit;
  final _address = TextEditingController();
  final _posts = <HousingPost>[];
  String? _next;
  bool _loading = false;
  bool _done = false;
  String? _error;

  /// Searching near an address: where, and how the map names it.
  ({double lat, double lon, String name})? _origin;
  bool _notFound = false;
  int _asked = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(reload());
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    setState(() {
      _posts.clear();
      _next = null;
      _done = false;
      _error = null;
    });
    await _more();
  }

  Future<void> _more() async {
    if (_loading || _done) return;
    final asked = ++_asked;
    setState(() => _loading = true);
    try {
      final page = await _kit.source.posts(cursor: _next, lat: _origin?.lat, lon: _origin?.lon);
      if (!mounted || asked != _asked) return;
      setState(() {
        _posts.addAll(page.posts);
        _next = page.next;
        _done = page.next == null;
        _error = null;
      });
    } on HousingException catch (e) {
      if (!mounted || asked != _asked) return;
      if (e.code.startsWith('cursor')) {
        _loading = false;
        return reload();
      }
      setState(() => _error = e.code);
      if (_posts.isNotEmpty) showHousingSnack(context, housingMessage(AppLocalizations.of(context), e));
    } finally {
      if (mounted && asked == _asked) setState(() => _loading = false);
    }
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final text = _address.text.trim();
    if (text.isEmpty) return _clear();
    HapticFeedback.lightImpact();
    final asked = ++_asked;
    setState(() {
      _posts.clear();
      _loading = true;
      _notFound = false;
      _error = null;
    });
    try {
      final origin = await _kit.source.geocode(await _kit.auth(), text);
      if (!mounted || asked != _asked) return;
      _origin = origin;
      _loading = false;
      await reload();
    } on HousingException catch (e) {
      if (!mounted || asked != _asked) return;
      setState(() {
        _loading = false;
        _notFound = e.code == 'geocode_failed' || e.code == 'validation_failed';
        if (!_notFound) _error = e.code;
      });
      if (!_notFound) showHousingSnack(context, housingMessage(AppLocalizations.of(context), e));
    }
  }

  void _clear() {
    _address.clear();
    _origin = null;
    _notFound = false;
    unawaited(reload());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final origin = _origin;
    return RefreshIndicator(
      onRefresh: reload,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 300) unawaited(_more());
          return false;
        },
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            CarsTabBar(title: s.featureHousing, subtitle: Text(origin == null ? s.hsRecent : s.hsNearest)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: HousingAddressField(controller: _address, onSubmitted: (_) => _search()),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _loading ? null : _search,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(s.hsSearch),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                    child: Text(s.hsSearchHint, style: TextStyle(fontSize: 12.5, height: 1.35, color: p.inkMuted)),
                  ),
                  if (origin != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: InputChip(
                        avatar: Icon(Icons.place_rounded, size: 18, color: p.accent),
                        label: Text(origin.name, overflow: TextOverflow.ellipsis),
                        onDeleted: _clear,
                        deleteButtonTooltipMessage: s.hsCancel,
                        onPressed: _clear,
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            origin == null ? s.hsRecent : s.hsNearest,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.ink),
                          ),
                        ),
                        if (_posts.isNotEmpty) Text(s.hsCount('${_posts.length}'), style: TextStyle(fontSize: 13, color: p.inkMuted)),
                      ],
                    ),
                  ),
                  if (_notFound)
                    HousingMessage(icon: Icons.wrong_location_outlined, title: s.hsGeoTitle, body: '${s.hsGeoBody}\n서울특별시 관악구 신림동 1522-27')
                  else if (_error != null && _posts.isEmpty)
                    HousingMessage(
                      icon: Icons.wifi_off_rounded,
                      title: s.hsLoadFailedTitle,
                      body: s.hsLoadFailedBody,
                      action: s.hsRetry,
                      onAction: reload,
                    )
                  else if (_posts.isEmpty && _loading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_posts.isEmpty)
                    HousingMessage(
                      icon: Icons.home_work_outlined,
                      title: s.hsEmptyTitle,
                      body: s.hsEmptyBody,
                      action: s.hsPostAd,
                      onAction: widget.onPost,
                    )
                  else ...[
                    for (final post in _posts) ...[
                      _PostCard(
                        post: post,
                        onTap: () => showHousingPost(context, _kit, post.id, distance: post.distanceKm, onChanged: widget.onChanged),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_done)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          s.hsAllShown,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: p.inkMuted),
                        ),
                      )
                    else
                      TextButton(onPressed: _more, child: Text(s.hsMore)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onTap});

  final HousingPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final amber = housingAmber(context);
    final (cta, ctaIcon) = post.hasContact
        ? (s.hsSeeNumber, Icons.call_rounded)
        : post.hasTelegram
        ? (s.hsViaTelegram, Icons.telegram)
        : (s.hsNoContact, null);
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: HousingAddress(post.address)),
                  if (post.distanceKm != null) ...[
                    const SizedBox(width: 8),
                    HousingPill(housingKm(post.distanceKm!), colour: amber, icon: Icons.near_me_rounded),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14.5, height: 1.45, color: p.inkSoft),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(post.postedAgo, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                        if (post.isNew) HousingPill(s.hsNew, colour: amber),
                        if (post.mine) HousingPill(s.hsYours, colour: p.accent),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (ctaIcon == null)
                    Flexible(
                      child: Text(
                        cta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: p.inkMuted),
                      ),
                    )
                  else
                    Flexible(
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(ctaIcon, size: 14, color: p.accent),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  cta,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: p.accent),
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
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ a post

/// A post in full, from below: the address, how long ago (and how far),
/// the whole text, the phone (a call, or copied) and Telegram; its owner
/// edits or deletes it here.
Future<void> showHousingPost(BuildContext context, HousingKit kit, int id, {double? distance, VoidCallback? onChanged}) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: VegukinPalette.of(context).page,
    builder: (_) => _PostSheet(kit: kit, id: id, distance: distance, onChanged: onChanged),
  );
}

class _PostSheet extends StatefulWidget {
  const _PostSheet({required this.kit, required this.id, this.distance, this.onChanged});

  final HousingKit kit;
  final int id;
  final double? distance;
  final VoidCallback? onChanged;

  @override
  State<_PostSheet> createState() => _PostSheetState();
}

class _PostSheetState extends State<_PostSheet> {
  HousingKit get _kit => widget.kit;
  HousingPost? _post;
  HousingException? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final post = await _kit.source.post(await _kit.auth(), widget.id);
      if (mounted) setState(() => _post = post);
    } on HousingException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _edit(HousingPost post) async {
    final s = AppLocalizations.of(context);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HousingCompose(kit: _kit, post: post),
      ),
    );
    if (saved != true || !mounted) return;
    showHousingSnack(context, s.hsSaved);
    widget.onChanged?.call();
    await _load();
  }

  Future<void> _delete(HousingPost post) async {
    final s = AppLocalizations.of(context);
    if (!await confirmHousing(context, s.hsDeleteConfirm, s.hsDelete)) return;
    try {
      await _kit.source.delete(await _kit.auth(), post.id);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showHousingSnack(context, s.hsDeleted);
      widget.onChanged?.call();
      Navigator.pop(context);
    } on HousingException catch (e) {
      if (mounted) showHousingSnack(context, housingMessage(s, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final post = _post;
    final error = _error;
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: error != null
          ? HousingMessage(
              icon: Icons.error_outline_rounded,
              title: s.hsOpenFailedTitle,
              body: s.hsOpenFailedBody,
              action: s.hsRetry,
              onAction: _load,
            )
          : post == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.paddingOf(context).bottom),
              children: [
                HousingAddress(post.address, size: 21),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 15, color: p.inkMuted),
                    const SizedBox(width: 4),
                    Text(post.postedAgo, style: TextStyle(fontSize: 13, color: p.inkMuted)),
                    if (widget.distance != null) ...[
                      const SizedBox(width: 8),
                      HousingPill(housingKm(widget.distance!), colour: housingAmber(context), icon: Icons.near_me_rounded),
                    ],
                  ],
                ),
                Divider(height: 28, color: p.hairline),
                SelectableText(post.text, style: TextStyle(fontSize: 15.5, height: 1.55, color: p.ink)),
                const SizedBox(height: 20),
                _Contact(post: post, services: _kit),
                if (post.mine) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _edit(post),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(s.hsEdit),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _delete(post),
                          style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(s.hsDelete),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.post, required this.services});

  final HousingPost post;
  final HousingKit services;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final phone = post.contact;
    final telegram = post.telegram;
    if (phone == null && telegram == null) {
      return Text(s.hsNoPhone, style: TextStyle(fontSize: 14, color: p.inkMuted));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (phone != null)
          Material(
            color: p.cardSelected,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.mediumImpact();
                services.services.openLink(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), '')));
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                      child: const Icon(Icons.call_rounded, color: Colors.white, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formatPhone(phone),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.ink),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await Clipboard.setData(ClipboardData(text: phone));
                        if (context.mounted) showHousingSnack(context, s.hsCopied);
                      },
                      child: Text(s.hsCopy),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (phone != null && telegram != null) const SizedBox(height: 10),
        if (telegram != null)
          Material(
            color: const Color(0xFF229ED9).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => services.services.openLink(Uri.parse('https://t.me/$telegram')),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 21,
                      backgroundColor: Color(0xFF229ED9),
                      child: Icon(Icons.telegram, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '@$telegram',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.ink),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.inkMuted),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<bool> confirmHousing(BuildContext context, String question, String yes) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(question),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context).hsCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(yes)),
        ],
      ),
    ) ==
    true;

// ------------------------------------------------------------------ mine

class _Mine extends StatefulWidget {
  const _Mine({super.key, required this.kit, required this.onPost, required this.onChanged});

  final HousingKit kit;
  final VoidCallback onPost;
  final VoidCallback onChanged;

  @override
  State<_Mine> createState() => _MineState();
}

class _MineState extends State<_Mine> with AutomaticKeepAliveClientMixin {
  HousingKit get _kit => widget.kit;
  List<HousingPost>? _posts;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  bool _asked = false;

  Future<void> load() async {
    if (!_kit.signedIn) return;
    _asked = true;
    setState(() => _error = null);
    try {
      final posts = await _kit.source.mine(await _kit.auth());
      if (mounted) setState(() => _posts = posts);
    } on HousingException catch (e) {
      if (mounted) setState(() => _error = e.code);
    }
  }

  Future<void> _act(Future<String> Function() call) async {
    try {
      final done = await call();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showHousingSnack(context, done);
      widget.onChanged();
    } on HousingException catch (e) {
      if (mounted) showHousingSnack(context, housingMessage(AppLocalizations.of(context), e));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final posts = _posts;
    return ListenableBuilder(
      listenable: _kit.services.account,
      builder: (context, _) {
        if (_kit.signedIn && !_asked) WidgetsBinding.instance.addPostFrameCallback((_) => load());
        return RefreshIndicator(
          onRefresh: load,
          child: CustomScrollView(
            slivers: [
              CarsTabBar(title: s.hsMineTitle, subtitle: Text(posts == null ? s.hsComposeSub : s.hsCount('${posts.length}'))),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.list(
                  children: [
                    if (!_kit.signedIn)
                      SignInCard(
                        icon: Icons.home_work_rounded,
                        title: s.hsSignInPostTitle,
                        body: s.hsSignInPostBody,
                        action: s.hsSignIn,
                        onAction: () async {
                          if (await askToSignIn(context, _kit.services)) await load();
                        },
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                        child: Text(s.hsMineSub, style: TextStyle(fontSize: 13, height: 1.4, color: p.inkMuted)),
                      ),
                      if (_error != null && posts == null)
                        HousingMessage(
                          icon: Icons.wifi_off_rounded,
                          title: s.hsFailedTitle,
                          body: s.hsFailedBody,
                          action: s.hsRetry,
                          onAction: load,
                        )
                      else if (posts == null)
                        const Padding(
                          padding: EdgeInsets.all(30),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (posts.isEmpty)
                        HousingMessage(
                          icon: Icons.article_outlined,
                          title: s.hsMineEmptyTitle,
                          body: s.hsMineEmptyBody,
                          action: s.hsPostAd,
                          onAction: widget.onPost,
                        )
                      else
                        for (final post in posts) ...[
                          _MineCard(
                            post: post,
                            onEdit: post.expired
                                ? null
                                : () async {
                                    final saved = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => HousingCompose(kit: _kit, post: post),
                                      ),
                                    );
                                    if (saved == true && context.mounted) {
                                      showHousingSnack(context, s.hsSaved);
                                      widget.onChanged();
                                    }
                                  },
                            onExtend: () => _act(() async => s.hsExtended('${await _kit.source.extend(await _kit.auth(), post.id)}')),
                            onDelete: () async {
                              if (await confirmHousing(context, s.hsDeleteConfirm, s.hsDelete)) {
                                await _act(() async {
                                  await _kit.source.delete(await _kit.auth(), post.id);
                                  return s.hsDeleted;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
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

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }
}

class _MineCard extends StatelessWidget {
  const _MineCard({required this.post, required this.onEdit, required this.onExtend, required this.onDelete});

  final HousingPost post;
  final VoidCallback? onEdit;
  final VoidCallback onExtend;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final colour = post.expired ? p.inkMuted : p.accent;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: HousingAddress(post.address)),
                HousingPill(post.expired ? s.hsExpired : s.hsActive, colour: colour),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              post.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            post.expired ? s.hsHidden : s.hsDaysLeft('${post.daysLeft ?? 0}'),
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: post.expired ? p.inkMuted : housingAmber(context)),
          ),
          Wrap(
            spacing: 4,
            children: [
              if (onEdit != null)
                TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18), label: Text(s.hsEdit)),
              TextButton.icon(onPressed: onExtend, icon: const Icon(Icons.update_rounded, size: 18), label: Text(s.hsExtend)),
              TextButton.icon(
                onPressed: onDelete,
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(s.hsDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ alerts

class _Alerts extends StatefulWidget {
  const _Alerts({required this.kit});

  final HousingKit kit;

  @override
  State<_Alerts> createState() => _AlertsState();
}

class _AlertsState extends State<_Alerts> with AutomaticKeepAliveClientMixin {
  HousingKit get _kit => widget.kit;
  final _address = TextEditingController();
  final _radius = TextEditingController(text: '10');
  List<HousingAlert>? _alerts;
  String? _error;
  String? _addressError;
  bool _busy = false;

  static const _presets = [5, 10, 15, 20];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _address.dispose();
    _radius.dispose();
    super.dispose();
  }

  bool _asked = false;

  Future<void> _load() async {
    if (!_kit.signedIn) return;
    _asked = true;
    setState(() => _error = null);
    try {
      final alerts = await _kit.source.alerts(await _kit.auth());
      if (mounted) setState(() => _alerts = alerts);
    } on HousingException catch (e) {
      if (mounted) setState(() => _error = e.code);
    }
  }

  Future<void> _add() async {
    final s = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final radius = int.tryParse(_radius.text) ?? 0;
    if (radius < 1 || radius > 500) return showHousingSnack(context, s.hsErrRadius);
    final address = _address.text.trim();
    if (address.length < 2 || !RegExp(r'[가-힣]').hasMatch(address)) return setState(() => _addressError = s.hsErrAddress);
    setState(() {
      _busy = true;
      _addressError = null;
    });
    try {
      await _kit.source.addAlert(await _kit.auth(), address, radius);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _address.clear();
      showHousingSnack(context, s.hsAlertAdded);
      await _load();
    } on HousingException catch (e) {
      if (!mounted) return;
      if (e.code == 'geocode_failed' || e.code == 'validation_failed') {
        setState(() => _addressError = e.fields.containsKey('radius_km') ? s.hsErrRadius : s.hsErrGeocode);
      } else {
        showHousingSnack(context, housingMessage(s, e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(HousingAlert alert) async {
    final s = AppLocalizations.of(context);
    if (!await confirmHousing(context, s.hsAlertDeleteConfirm, s.hsDelete)) return;
    try {
      await _kit.source.deleteAlert(await _kit.auth(), alert.id);
      if (!mounted) return;
      showHousingSnack(context, s.hsAlertDeleted);
      await _load();
    } on HousingException catch (e) {
      if (mounted) showHousingSnack(context, housingMessage(s, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final alerts = _alerts;
    return ListenableBuilder(
      listenable: Listenable.merge([_kit.services.account, _radius]),
      builder: (context, _) {
        if (_kit.signedIn && !_asked) WidgetsBinding.instance.addPostFrameCallback((_) => _load());
        return RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              CarsTabBar(title: s.hsAlertsTitle, subtitle: Text(alerts == null ? s.hsSignInAlertsTitle : s.hsCount('${alerts.length}'))),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.list(
                  children: [
                    if (!_kit.signedIn)
                      SignInCard(
                        icon: Icons.notifications_active_rounded,
                        title: s.hsSignInAlertsTitle,
                        body: s.hsSignInAlertsBody,
                        action: s.hsSignIn,
                        onAction: () async {
                          if (await askToSignIn(context, _kit.services)) await _load();
                        },
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: p.hairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(s.hsAlertsSub, style: TextStyle(fontSize: 13.5, height: 1.4, color: p.inkSoft)),
                            const SizedBox(height: 12),
                            HousingAddressField(controller: _address, error: _addressError, action: TextInputAction.done),
                            const SizedBox(height: 14),
                            Text(
                              s.hsRadius,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.inkSoft),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                for (final r in _presets) ...[
                                  Expanded(
                                    child: ChoiceChip(
                                      label: SizedBox(
                                        width: double.infinity,
                                        child: Text('$r km', textAlign: TextAlign.center),
                                      ),
                                      selected: _radius.text == '$r',
                                      showCheckmark: false,
                                      onSelected: (_) {
                                        HapticFeedback.selectionClick();
                                        _radius.text = '$r';
                                      },
                                    ),
                                  ),
                                  if (r != _presets.last) const SizedBox(width: 6),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(s.hsRadiusCustom, style: TextStyle(fontSize: 13, color: p.inkMuted)),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: TextField(
                                    controller: _radius,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(isDense: true, suffixText: 'km'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _busy ? null : _add,
                              icon: const Icon(Icons.add_alert_rounded),
                              label: Text(s.hsAdd),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_error != null && alerts == null)
                        HousingMessage(
                          icon: Icons.wifi_off_rounded,
                          title: s.hsFailedTitle,
                          body: s.hsFailedBody,
                          action: s.hsRetry,
                          onAction: _load,
                        )
                      else if (alerts == null)
                        const Padding(
                          padding: EdgeInsets.all(30),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (alerts.isEmpty)
                        HousingMessage(icon: Icons.notifications_none_rounded, title: s.hsAlertsEmptyTitle, body: s.hsAlertsEmptyBody)
                      else
                        for (final a in alerts) ...[
                          Opacity(
                            opacity: a.active ? 1 : 0.62,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
                              decoration: BoxDecoration(
                                color: p.card,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: p.hairline),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        HousingAddress(a.address, size: 15.5),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            HousingPill('${a.radiusKm} km', colour: housingAmber(context), icon: Icons.radar_rounded),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                !a.active
                                                    ? s.hsAlertOff
                                                    : a.matches > 0
                                                    ? s.hsAlertSent('${a.matches}')
                                                    : s.hsActive,
                                                style: TextStyle(fontSize: 12.5, color: p.inkMuted),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _delete(a),
                                    tooltip: s.hsDelete,
                                    icon: Icon(Icons.delete_outline_rounded, color: p.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
}
