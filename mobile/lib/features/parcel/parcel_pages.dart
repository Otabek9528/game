import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'parcel_controller.dart';
import 'parcel_models.dart';
import 'parcel_parts.dart';
import 'post_card.dart';

/// What a post's buttons do, the same on every parcel page.
class PostActions {
  const PostActions({required this.controller, required this.services});

  final ParcelController controller;
  final AppServices services;

  /// Telegram, the dialer or a link. The first time, the notice comes
  /// first: the app shows the posts and has nothing to do with the couriers.
  Future<void> open(BuildContext context, Uri uri) async {
    if (!controller.noticeSeen) {
      final ok = await showNoticeSheet(context);
      if (!ok) return;
      await controller.acknowledgeNotice();
    }
    await services.openLink(uri);
  }

  Future<void> toggleSave(BuildContext context, ParcelPost post, ParcelDirection direction) async {
    final saved = controller.saved;
    if (!saved.contains(post)) {
      await saved.save(post, direction);
      return;
    }
    final s = AppLocalizations.of(context);
    final item = saved.items.firstWhere((x) => x.post.id == post.id);
    final at = await saved.remove(post);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(s.parcelRemoved),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: s.parcelUndo, onPressed: () => saved.restore(item, at)),
      ));
  }

  Widget card(BuildContext context, ParcelPost post, ParcelDirection direction) => PostCard(
        key: ValueKey(post.id),
        post: post,
        route: routeName(AppLocalizations.of(context), direction),
        onOpen: (uri) => open(context, uri),
        onShare: services.shareText,
        saved: controller.saved.contains(post),
        onSave: () => toggleSave(context, post, direction),
      );
}

/// "Samarqand" matches "samarqand", and o‘ matches o' however it's typed.
String normalizeSearch(String text) => text.toLowerCase().replaceAll(RegExp('[‘’ʻʼ`´]'), "'").trim();

bool postMatches(ParcelPost post, String query) =>
    normalizeSearch('${post.username ?? ''} ${post.flightTime ?? ''} ${post.text}').contains(query);

/// A list of posts in its states: placeholders while loading, a retry when
/// it couldn't load, a note when there are none.
List<Widget> postSlivers(
  BuildContext context,
  Fetch<List<ParcelPost>> posts, {
  required Future<bool> Function() onRetry,
  required Widget Function(ParcelPost) card,
  String empty = '',
}) {
  final s = AppLocalizations.of(context);
  if (posts.loading) {
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        sliver: SliverList.separated(
          itemCount: 2,
          itemBuilder: (_, _) => const PostSkeleton(),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
        ),
      ),
    ];
  }
  if (posts.failed) return [fillRemaining(Problem(onRetry: onRetry))];
  final list = posts.data!;
  if (list.isEmpty) return [fillRemaining(EmptyState(text: empty.isEmpty ? s.parcelNoPosts : empty))];
  return [
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      sliver: SliverList.separated(
        itemCount: list.length,
        itemBuilder: (_, i) => card(list[i]),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
      ),
    ),
  ];
}

/// The emerald top of the inner pages: back, a title, a line under it.
class PageHero extends StatelessWidget {
  const PageHero({super.key, required this.title, this.subtitle, this.updating = false});

  final String title;
  final String? subtitle;
  final bool updating;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.hero.sublist(1)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: Brand.displayFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                  ),
              ],
            ),
            if (updating)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(minHeight: 2, color: Brand.gold300, backgroundColor: Colors.transparent),
              ),
          ],
        ),
      ),
    );
  }
}

/// The posts of a city, from the city list: last time's at once, then
/// fresh ones.
class ParcelCityScreen extends StatefulWidget {
  const ParcelCityScreen({
    super.key,
    required this.services,
    required this.controller,
    required this.city,
    required this.country,
    required this.direction,
  });

  final AppServices services;
  final ParcelController controller;
  final String city;
  final ParcelCountry country;
  final ParcelDirection direction;

  @override
  State<ParcelCityScreen> createState() => _ParcelCityScreenState();
}

class _ParcelCityScreenState extends State<ParcelCityScreen> {
  late Fetch<List<ParcelPost>> _posts = switch (
      widget.controller.savedCityPosts(widget.city, widget.country, widget.direction)) {
    final List<ParcelPost> cached => Fetch.done(cached),
    null => const Fetch.loading(),
  };
  bool _updating = false;
  bool _offline = false;
  String _query = '';
  final _search = TextEditingController();
  late final _actions = PostActions(controller: widget.controller, services: widget.services);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<bool> _load() async {
    if (_posts.data != null) setState(() => _updating = true);
    try {
      final list = await widget.controller.postsByCity(widget.city, widget.country, widget.direction);
      if (mounted) {
        setState(() {
          _posts = Fetch.done(list);
          _updating = false;
          _offline = false;
        });
      }
      return true;
    } catch (_) {
      if (mounted) {
        setState(() {
          _updating = false;
          if (_posts.data == null) {
            _posts = const Fetch.failed();
          } else {
            _offline = true;
          }
        });
      }
      return false;
    }
  }

  Future<bool> _retry() {
    setState(() => _posts = const Fetch.loading());
    return _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final all = _posts.data;
    final query = normalizeSearch(_query);
    final shown = all == null || query.isEmpty
        ? _posts
        : Fetch.done(all.where((post) => postMatches(post, query)).toList());
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.page,
        body: ListenableBuilder(
          listenable: widget.controller.saved,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHero(
                title: '${widget.country.flag} ${widget.city}',
                subtitle: [routeName(s, widget.direction), if (all != null) s.parcelPostCount(all.length)].join('  ·  '),
                updating: _updating,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: p.accent,
                  onRefresh: () async {
                    if (!await _load() && context.mounted) showFailed(context);
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      if (_offline)
                        const SliverPadding(
                          padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
                          sliver: SliverToBoxAdapter(child: OfflineNote()),
                        ),
                      if ((all?.length ?? 0) > 3)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          sliver: SliverToBoxAdapter(
                            child: SearchField(
                              controller: _search,
                              hint: s.parcelSearchPosts,
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                        ),
                      ...postSlivers(
                        context,
                        shown,
                        onRetry: _retry,
                        card: (post) => _actions.card(context, post, widget.direction),
                        empty: query.isEmpty ? '' : s.parcelNothingFound,
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: 24 + bottom)),
                    ],
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

/// Posts kept on this phone, newest first; either way.
class ParcelSavedScreen extends StatelessWidget {
  const ParcelSavedScreen({super.key, required this.services, required this.controller});

  final AppServices services;
  final ParcelController controller;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final actions = PostActions(controller: controller, services: services);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.page,
        body: ListenableBuilder(
          listenable: controller.saved,
          builder: (context, _) {
            final items = controller.saved.items;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHero(
                  title: s.parcelSavedTitle,
                  subtitle: items.isEmpty ? null : s.parcelPostCount(items.length),
                ),
                Expanded(
                  child: items.isEmpty
                      ? SingleChildScrollView(child: EmptyState(text: s.parcelSavedEmpty, icon: Icons.bookmark_rounded))
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(14, 14, 14, 24 + bottom),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => actions.card(context, items[i].post, items[i].direction),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
