import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/calendar_text.dart';
import 'parcel_controller.dart';
import 'parcel_models.dart';
import 'parcel_pages.dart';
import 'parcel_parts.dart';

/// Couriers flying between Uzbekistan and Korea who carry parcels: the web
/// page (pages/parcel/) rebuilt as one screen. The route sits on top
/// (remembered, swapped with a tap) and folds into the bar on scrolling.
/// By date, the coming days follow one another in one list, each under its
/// own heading, with a strip of days pinned above that follows the scroll
/// and jumps on a tap. By city, the cities. Posts can be searched, saved
/// and shared; reaching a courier goes through a one-time notice that the
/// app only shows posts from Telegram groups.
class ParcelScreen extends StatefulWidget {
  const ParcelScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> with WidgetsBindingObserver {
  late final ParcelController _c = ParcelController(
    source: widget.services.parcels,
    store: widget.services.store,
  );
  late final _actions = PostActions(controller: _c, services: widget.services);
  final _scroll = ScrollController();
  final _strip = ScrollController();
  final _search = TextEditingController();

  bool _searching = false;
  String _query = '';

  /// The swap button turns half a turn each time.
  double _turns = 0;
  bool _noticeOpen = false;

  /// The day whose posts are at the top of the list.
  String? _active;

  /// Where each day's section starts, as a scroll offset: noted while the
  /// sections are laid out.
  final _tops = <String, double>{};
  final _soon = <String>{};

  static const _bar = 56.0;
  static const _heroExtra = 136.0;
  static const _stripHeight = 98.0;
  static const _searchHeight = 62.0;
  static const _chipsHeight = 62.0;
  static const _dayHeight = 44.0;

  AppLanguage get _language => widget.services.locale.language ?? AppLanguage.uz;
  double get _heroMin => MediaQuery.paddingOf(context).top + _bar;
  double get _heroMax => _heroMin + _heroExtra;

  bool get _showSearch =>
      _searching || (_c.mode == ParcelMode.byCity && (_c.cities?.data?.length ?? 0) > 8);

  bool get _showStrip => _c.mode == ParcelMode.byDate && !_c.dates.failed && (_c.dates.data?.isNotEmpty ?? true);

  double get _pinnedHeight =>
      (_showSearch ? _searchHeight : 0) +
      (_c.mode == ParcelMode.byCity ? _chipsHeight : (_showStrip ? _stripHeight : 0));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_follow);
    _c.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.dispose();
    _scroll.dispose();
    _strip.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _c.refreshIfOld();
  }

  void _swap() {
    HapticFeedback.selectionClick();
    setState(() {
      _turns += 0.5;
      _active = null;
      _tops.clear();
      _setQuery('');
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _c.swap();
  }

  void _setMode(ParcelMode mode) {
    HapticFeedback.selectionClick();
    setState(() {
      _setQuery('');
      _searching = false;
    });
    _c.setMode(mode);
  }

  void _setQuery(String value) {
    _query = value;
    if (_search.text != value) _search.text = value;
    if (normalizeSearch(value).isNotEmpty && _c.mode == ParcelMode.byDate) _c.wantAll();
  }

  void _toggleSearch() {
    HapticFeedback.selectionClick();
    setState(() {
      _searching = !_searching;
      if (!_searching) _setQuery('');
    });
  }

  Future<void> _refresh() async {
    final ok = await _c.refresh();
    if (!ok && mounted) showFailed(context);
  }

  void _openCity(ParcelCity city) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ParcelCityScreen(
          services: widget.services,
          controller: _c,
          city: city.name,
          country: _c.country,
          direction: _c.direction,
        ),
      ),
    );
  }

  void _openSaved() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ParcelSavedScreen(services: widget.services, controller: _c)),
    );
  }

  /// A day's section was laid out: where it starts, and whether it is near
  /// enough to the screen for its posts to load.
  void _onSection(String key, SliverConstraints constraints) {
    _tops[key] = constraints.precedingScrollExtent;
    if (constraints.remainingCacheExtent <= 0) return;
    if (_soon.add(key) && _soon.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final keys = _soon.toList();
        _soon.clear();
        if (!mounted) return;
        keys.forEach(_c.want);
        _follow();
      });
    }
  }

  /// The strip follows the list: the day at the top is the one marked.
  void _follow() {
    if (_c.mode != ParcelMode.byDate || !_scroll.hasClients) return;
    final feed = _c.feed;
    if (feed.isEmpty) return;
    final offset = _scroll.offset;
    final line = offset + math.max(_heroMin, _heroMax - offset) + _pinnedHeight + 8;
    var active = feed.first.key;
    for (final day in feed) {
      final top = _tops[day.key];
      if (top == null || top > line) break;
      active = day.key;
    }
    if (active != _active) {
      setState(() => _active = active);
      _reveal(active);
    }
  }

  /// Scrolls the strip so the day is in the middle of it.
  void _reveal(String key) {
    final dates = _c.dates.data;
    if (dates == null || !_strip.hasClients) return;
    final at = dates.indexWhere((d) => d.key == key);
    if (at < 0) return;
    final width = _strip.position.viewportDimension;
    final target = (14 + at * 80 + 35 - width / 2).clamp(0.0, _strip.position.maxScrollExtent);
    _strip.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
  }

  double _offsetFor(double top) => math.max(0, top - _heroMin - _pinnedHeight);

  /// A tap on a day: the list scrolls to it when every day before it is
  /// loaded (so it won't move on the way); otherwise the list starts from it.
  void _jump(ParcelDate day) {
    HapticFeedback.selectionClick();
    final feed = _c.feed;
    final at = feed.indexWhere((d) => d.key == day.key);
    final top = _tops[day.key];
    final settled = at >= 0 && feed.take(at).every((d) => _c.day(d.key).data != null);
    setState(() => _active = day.key);
    _reveal(day.key);
    if (top != null && settled && normalizeSearch(_query).isEmpty) {
      _scroll.animateTo(_offsetFor(top), duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      return;
    }
    _c.pick(day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final top = _tops[day.key];
      if (top == null || !_scroll.hasClients) return;
      final target = _offsetFor(top);
      if (_scroll.offset > target) _scroll.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.page,
        body: ListenableBuilder(
          listenable: Listenable.merge([_c, _c.saved]),
          builder: (context, _) {
            if (normalizeSearch(_query).isNotEmpty && _c.mode == ParcelMode.byDate) {
              // Days that arrived since the search began are searched too.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _c.wantAll();
              });
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              color: p.accent,
              edgeOffset: _heroMax,
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                // The next day's posts start loading before it scrolls in.
                scrollCacheExtent: const ScrollCacheExtent.pixels(700),
                slivers: [
                  SliverPersistentHeader(pinned: true, delegate: _hero(context)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    sliver: SliverToBoxAdapter(
                      child: NoticeCard(
                        seen: _c.noticeSeen,
                        open: _noticeOpen,
                        onOk: () {
                          HapticFeedback.selectionClick();
                          _c.acknowledgeNotice();
                        },
                        onToggle: () => setState(() => _noticeOpen = !_noticeOpen),
                      ),
                    ),
                  ),
                  if (_c.offline)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(14, 10, 14, 0),
                      sliver: SliverToBoxAdapter(child: OfflineNote()),
                    ),
                  if (_pinnedHeight > 0)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _Pinned(height: _pinnedHeight, color: p.page, child: _pinned(context)),
                    ),
                  ...(_c.mode == ParcelMode.byDate ? _days(context) : _cities(context)),
                  SliverToBoxAdapter(child: SizedBox(height: 24 + bottom)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  _HeroDelegate _hero(BuildContext context) {
    final s = AppLocalizations.of(context);
    final saved = _c.saved.items.length;
    return _HeroDelegate(
      top: MediaQuery.paddingOf(context).top,
      title: s.parcelTitle,
      palette: VegukinPalette.of(context),
      updating: _c.updating,
      route: Row(
        children: [
          Expanded(
            child: Place(label: s.parcelFrom, country: _c.direction.from, name: countryName(s, _c.direction.from)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _SwapButton(turns: _turns, tooltip: s.parcelSwap, onTap: _swap),
          ),
          Expanded(
            child: Place(
              label: s.parcelTo,
              country: _c.direction.to,
              name: countryName(s, _c.direction.to),
              end: true,
            ),
          ),
        ],
      ),
      modes: _Modes(mode: _c.mode, onChanged: _setMode),
      compact: _CompactRoute(direction: _c.direction, tooltip: s.parcelSwap, onTap: _swap),
      actions: [
        IconButton(
          onPressed: _toggleSearch,
          tooltip: s.parcelSearch,
          icon: Icon(_searching ? Icons.search_off_rounded : Icons.search_rounded, color: Colors.white),
        ),
        IconButton(
          onPressed: _openSaved,
          tooltip: s.parcelSavedTitle,
          icon: Badge(
            isLabelVisible: saved > 0,
            label: Text('$saved'),
            backgroundColor: Brand.gold400,
            textColor: const Color(0xFF3B2A05),
            child: const Icon(Icons.bookmarks_outlined, color: Colors.white),
          ),
        ),
        IconButton(
          onPressed: () => showHowItWorks(context),
          tooltip: s.parcelHowTitle,
          icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
        ),
      ],
    );
  }

  /// Under the bar, pinned: the search field when open, and the strip of
  /// days or the countries.
  Widget _pinned(BuildContext context) {
    final s = AppLocalizations.of(context);
    final dates = _c.dates;
    return Column(
      children: [
        if (_showSearch)
          SizedBox(
            height: _searchHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: SearchField(
                controller: _search,
                autofocus: _searching,
                hint: _c.mode == ParcelMode.byDate ? s.parcelSearchPosts : s.parcelSearchCity,
                onChanged: (v) => setState(() => _setQuery(v)),
                onClose: _searching ? _toggleSearch : null,
              ),
            ),
          ),
        if (_c.mode == ParcelMode.byCity)
          SizedBox(height: _chipsHeight, child: _countries(context))
        else if (_showStrip)
          SizedBox(
            height: _stripHeight,
            child: dates.loading
                ? const StripSkeleton()
                : ListView.separated(
                    controller: _strip,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 2),
                    clipBehavior: Clip.none,
                    itemCount: dates.data!.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final day = dates.data![i];
                      return DayChip(
                        date: day,
                        selected: day.key == (_active ?? _c.feed.firstOrNull?.key),
                        past: _c.isPast(day),
                        language: _language,
                        onTap: () => _jump(day),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _countries(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          for (final country in ParcelCountry.values) ...[
            Expanded(
              child: CountryChip(
                country: country,
                label: countryName(s, country),
                selected: _c.country == country,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _setQuery(''));
                  _c.setCountry(country);
                },
              ),
            ),
            if (country == ParcelCountry.uzb) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  List<Widget> _days(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final dates = _c.dates;
    if (dates.loading) {
      return [
        if (_c.slow) const SliverToBoxAdapter(child: WakingNote()),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        ...postSlivers(context, const Fetch.loading(), onRetry: _c.refresh, card: (_) => const SizedBox()),
      ];
    }
    if (dates.failed) return [fillRemaining(Problem(onRetry: _c.refresh))];
    if (dates.data!.isEmpty) {
      return [
        fillRemaining(EmptyState(
          text: s.parcelNoDates,
          action: s.parcelSeeOther(routeName(s, _c.direction.other)),
          onAction: _swap,
          showHow: true,
        )),
      ];
    }
    final query = normalizeSearch(_query);
    final feed = _c.feed;
    final sections = <Widget>[];
    var settled = 0;
    var found = 0;
    for (final day in feed) {
      final fetch = _c.day(day.key);
      if (!fetch.loading) settled++;
      var posts = fetch.data;
      if (query.isNotEmpty) {
        // While searching, only days with a match show.
        if (posts == null) continue;
        posts = posts.where((post) => postMatches(post, query)).toList();
        if (posts.isEmpty) continue;
        found += posts.length;
      }
      sections.add(_section(context, day, fetch, posts));
    }
    final note = TextStyle(fontSize: 13, color: p.inkMuted);
    return [
      if (query.isNotEmpty && settled < feed.length)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Row(
              children: [
                SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: p.accent)),
                const SizedBox(width: 10),
                Text(s.parcelSearching(settled, feed.length), style: note),
              ],
            ),
          ),
        ),
      ...sections,
      if (query.isNotEmpty && settled == feed.length && found == 0)
        fillRemaining(EmptyState(text: s.parcelNothingFound, icon: Icons.search_off_rounded))
      else if (query.isEmpty && settled == feed.length)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(s.parcelEnd, textAlign: TextAlign.center, style: note),
          ),
        ),
    ];
  }

  /// A day: a marker that notes where it starts, its heading (pinned while
  /// its posts scroll), and its posts.
  Widget _section(BuildContext context, ParcelDate day, Fetch<List<ParcelPost>> fetch, List<ParcelPost>? posts) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return SliverMainAxisGroup(
      slivers: [
        SliverLayoutBuilder(
          builder: (context, constraints) {
            _onSection(day.key, constraints);
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _DayHeading(
            height: _dayHeight,
            title: gregorianLine(day.date, _language),
            count: s.parcelPostCount(posts?.length ?? day.count),
            past: _c.isPast(day),
            palette: p,
          ),
        ),
        if (fetch.failed)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Problem(onRetry: () async {
                _c.retryDay(day.key);
                return true;
              }),
            ),
          )
        else if (posts == null)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            sliver: SliverToBoxAdapter(child: PostSkeleton()),
          )
        else if (posts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Text(s.parcelNoPosts, style: TextStyle(fontSize: 13.5, color: p.inkMuted)),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            sliver: SliverList.separated(
              itemCount: posts.length,
              itemBuilder: (context, i) => _actions.card(context, posts[i], _c.direction),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
      ],
    );
  }

  List<Widget> _cities(BuildContext context) {
    final s = AppLocalizations.of(context);
    final cities = _c.cities;
    if (cities == null || cities.loading) {
      return [if (_c.slow) const SliverToBoxAdapter(child: WakingNote()), const ListSkeleton()];
    }
    if (cities.failed) return [fillRemaining(Problem(onRetry: _c.refresh))];
    final list = cities.data!;
    if (list.isEmpty) return [fillRemaining(EmptyState(text: s.parcelNoCities))];
    final query = normalizeSearch(_query);
    final shown = query.isEmpty ? list : list.where((c) => normalizeSearch(c.name).contains(query)).toList();
    if (shown.isEmpty) return [fillRemaining(EmptyState(text: s.parcelNoCities, icon: Icons.search_off_rounded))];
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        sliver: SliverToBoxAdapter(child: CityList(cities: shown, onOpen: _openCity)),
      ),
    ];
  }
}

/// The emerald top. Open: the bar, the route and the two ways to search.
/// Scrolled: just the bar, with the route as a small swap button.
class _HeroDelegate extends SliverPersistentHeaderDelegate {
  _HeroDelegate({
    required this.top,
    required this.title,
    required this.palette,
    required this.updating,
    required this.route,
    required this.modes,
    required this.compact,
    required this.actions,
  });

  final double top;
  final String title;
  final VegukinPalette palette;
  final bool updating;
  final Widget route;
  final Widget modes;
  final Widget compact;
  final List<Widget> actions;

  static const _bar = _ParcelScreenState._bar;
  static const _extra = _ParcelScreenState._heroExtra;

  @override
  double get minExtent => top + _bar;

  @override
  double get maxExtent => top + _bar + _extra;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / _extra).clamp(0.0, 1.0);
    const radius = BorderRadius.vertical(bottom: Radius.circular(22));
    return SizedBox.expand(
      child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: palette.hero.sublist(1)),
        borderRadius: radius,
        boxShadow: t > 0.95 ? const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 2))] : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned(
              left: 16,
              right: 16,
              top: top + _bar + 2 - shrinkOffset,
              child: Opacity(
                opacity: (1 - t * 1.6).clamp(0.0, 1.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [route, const SizedBox(height: 12), modes],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: top,
              height: _bar,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      layoutBuilder: (current, previous) =>
                          Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
                      child: t < 0.6
                          ? Text(
                              title,
                              key: const ValueKey('title'),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: Brand.displayFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            )
                          : KeyedSubtree(key: const ValueKey('route'), child: compact),
                    ),
                  ),
                  ...actions,
                  const SizedBox(width: 2),
                ],
              ),
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
      ),
    );
  }

  @override
  bool shouldRebuild(_HeroDelegate old) => true;
}

/// Pinned under the bar.
class _Pinned extends SliverPersistentHeaderDelegate {
  _Pinned({required this.height, required this.color, required this.child});

  final double height;
  final Color color;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: ColoredBox(color: color, child: child));

  @override
  bool shouldRebuild(_Pinned old) => true;
}

/// A day's heading, pinned under the strip while its posts pass.
class _DayHeading extends SliverPersistentHeaderDelegate {
  _DayHeading({required this.height, required this.title, required this.count, required this.past, required this.palette});

  final double height;
  final String title;
  final String count;
  final bool past;
  final VegukinPalette palette;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final p = palette;
    // A header's child picks its own height: it must fill its slot.
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: p.page,
        border: overlapsContent ? Border(bottom: BorderSide(color: p.hairline)) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: past ? p.inkMuted : p.ink),
            ),
          ),
          Text(count, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_DayHeading old) =>
      old.title != title || old.count != count || old.past != past || old.palette != palette || old.height != height;
}

class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.turns, required this.tooltip, required this.onTap});

  final double turns;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black38,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox.square(
            dimension: 46,
            child: AnimatedRotation(
              turns: turns,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              child: const Icon(Icons.swap_horiz_rounded, color: Brand.emerald700, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

/// The route in the folded bar: 🇰🇷 → 🇺🇿, a tap swaps it.
class _CompactRoute extends StatelessWidget {
  const _CompactRoute({required this.direction, required this.tooltip, required this.onTap});

  final ParcelDirection direction;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: 0.16),
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(direction.from.flag, style: const TextStyle(fontSize: 18)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white70),
                  ),
                  Text(direction.to.flag, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Icon(Icons.swap_horiz_rounded, size: 20, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// By date or by city, white on the emerald.
class _Modes extends StatelessWidget {
  const _Modes({required this.mode, required this.onChanged});

  final ParcelMode mode;
  final ValueChanged<ParcelMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return SizedBox(
      height: 42,
      child: SegmentedButton<ParcelMode>(
        segments: [
          ButtonSegment(value: ParcelMode.byDate, label: Text(s.parcelByDate), icon: const Icon(Icons.event_rounded)),
          ButtonSegment(
            value: ParcelMode.byCity,
            label: Text(s.parcelByCity),
            icon: const Icon(Icons.location_city_rounded),
          ),
        ],
        selected: {mode},
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        onSelectionChanged: (v) => onChanged(v.first),
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: Colors.white,
          selectedForegroundColor: Brand.emerald800,
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        ),
      ),
    );
  }
}
