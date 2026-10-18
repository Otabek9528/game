import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import '../qna/qna_parts.dart';
import 'business_card.dart';
import 'business_data.dart';
import 'business_logo.dart';
import 'business_models.dart';
import 'business_parts.dart';
import 'business_source.dart';

/// The web page (pages/business/) rebuilt: every kind of business as a
/// tile, the search above them, and the businesses one has saved, a call
/// away. It opens at once on the directory last seen, and refreshes it.
class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  late final BizKit _kit = BizKit(widget.services);
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _kit.directory = _kit.library.directory;
    _load();
  }

  @override
  void dispose() {
    _kit.library.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final directory = await widget.services.businesses.directory();
      if (!mounted) return;
      _kit.library.directory = directory;
      setState(() {
        _kit.directory = directory;
        _loading = false;
      });
    } on BizException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = _kit.directory == null;
      });
    }
  }

  void _openCategory(BizCategory category) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BizCategoryScreen(kit: _kit, category: category)));
  }

  void _openSearch() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BizSearchScreen(kit: _kit)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final directory = _kit.directory;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: p.page,
      body: RefreshIndicator(
        onRefresh: _load,
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
              titleTextStyle: const TextStyle(fontFamily: Brand.displayFont, fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
              title: Text(s.bizTitle),
              actions: [
                IconButton(onPressed: _openSearch, tooltip: s.bizSearchTitle, icon: const Icon(Icons.search_rounded)),
                const SizedBox(width: 4),
              ],
            ),
            SliverToBoxAdapter(child: _Hero(total: directory?.total, onSearch: _openSearch)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(14, 14, 14, 24 + bottom),
              sliver: SliverList.list(
                children: [
                  if (_kit.language != AppLanguage.uz)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
                      child: Row(
                        children: [
                          Icon(Icons.translate_rounded, size: 18, color: p.inkMuted),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.bizUzbekNote, style: TextStyle(fontSize: 13, color: p.inkMuted))),
                        ],
                      ),
                    ),
                  ListenableBuilder(
                    listenable: _kit.library,
                    builder: (context, _) => _SavedStrip(kit: _kit),
                  ),
                  if (directory == null && _failed)
                    QnaMessage(
                      icon: Icons.wifi_off_rounded,
                      title: s.bizLoadError,
                      body: s.bizCheckConnection,
                      action: FilledButton.tonalIcon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: Text(s.bizRetry)),
                    )
                  else if (directory == null && _loading)
                    _TileGrid(children: [for (var i = 0; i < 6; i++) const _SkeletonTile()])
                  else if (directory != null && directory.categories.isEmpty)
                    QnaMessage(icon: Icons.storefront_rounded, title: s.bizDirectoryEmpty, body: s.bizDirectoryEmptyBody)
                  else if (directory != null)
                    _TileGrid(
                      children: [
                        for (final c in directory.categories)
                          _CategoryTile(category: c, about: categoryAbout(c.slug, _kit.language), onTap: () => _openCategory(c)),
                      ],
                    ),
                  const SizedBox(height: 16),
                  OwnerCard(kit: _kit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.total, required this.onSearch});

  final int? total;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.hero.first, p.hero.last]),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
              child: CustomPaint(painter: KhatamLatticePainter(color: Colors.white.withValues(alpha: 0.05))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.bizTagline, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white)),
                if (total case final total? when total > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(s.bizCountAll(total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Brand.gold300)),
                  ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 2,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    onTap: onSearch,
                    customBorder: const StadiumBorder(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Brand.emerald700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.bizSearchHint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, color: p.inkMuted),
                            ),
                          ),
                        ],
                      ),
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
}

/// The businesses one has saved: a row of logos at the top, one tap from
/// their card and its call button.
class _SavedStrip extends StatelessWidget {
  const _SavedStrip({required this.kit});

  final BizKit kit;

  @override
  Widget build(BuildContext context) {
    final saved = kit.library.saved;
    if (saved.isEmpty) return const SizedBox.shrink();
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                Icon(Icons.bookmark_rounded, size: 18, color: p.gold),
                const SizedBox(width: 6),
                Text(s.bizSaved, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink)),
              ],
            ),
          ),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: saved.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => SizedBox(
                width: 76,
                child: InkWell(
                  onTap: () => openBusiness(context, kit, saved[i]),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      BizLogo(business: saved[i], logos: kit.logos, size: 60, radius: 18),
                      const SizedBox(height: 6),
                      Text(
                        saved[i].name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, height: 1.2, fontWeight: FontWeight.w700, color: p.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two tiles a row: on a phone a pair of related kinds is a row. A row is
/// as tall as its tallest tile, so large text never cuts one off.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const gap = 10.0;
          final columns = constraints.maxWidth > 600 ? 3 : 2;
          return Column(
            children: [
              for (var i = 0; i < children.length; i += columns)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var j = i; j < i + columns; j++) ...[
                          if (j > i) const SizedBox(width: gap),
                          Expanded(child: j < children.length ? children[j] : const SizedBox.shrink()),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.about, required this.onTap});

  final BizCategory category;
  final String? about;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final empty = category.count == 0;
    return Opacity(
      opacity: empty ? 0.6 : 1,
      child: Material(
        color: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: p.hairline)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 150),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(13)),
                    child: Text(category.icon ?? '•', style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink),
                  ),
                  if (about != null)
                    Text(
                      about!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, height: 1.3, color: p.inkMuted),
                    ),
                  const Spacer(),
                  const SizedBox(height: 8),
                  Text(
                    empty ? s.bizTileEmpty : s.bizCountAll(category.count),
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: empty ? p.inkMuted : p.accent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) => Container(
        height: 150,
        decoration: BoxDecoration(color: VegukinPalette.of(context).cardSelected, borderRadius: BorderRadius.circular(18)),
      );
}

/// One kind of business: most liked first, medals for the top three. The
/// title switches to another kind.
class BizCategoryScreen extends StatefulWidget {
  const BizCategoryScreen({super.key, required this.kit, required this.category});

  final BizKit kit;
  final BizCategory category;

  @override
  State<BizCategoryScreen> createState() => _BizCategoryScreenState();
}

class _BizCategoryScreenState extends State<BizCategoryScreen> {
  List<Business>? _businesses;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final businesses = await widget.kit.services.businesses.category(widget.category.id);
      if (mounted) setState(() => _businesses = businesses);
    } on BizException {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _switch() async {
    final next = await pickCategory(context, widget.kit, current: widget.category.id);
    if (next == null || next.id == widget.category.id || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => BizCategoryScreen(kit: widget.kit, category: next)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final businesses = _businesses;
    final ranks = businesses == null ? const <int?>[] : ranksOf(businesses);
    final c = widget.category;
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(
        backgroundColor: p.page,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: InkWell(
          onTap: widget.kit.directory == null ? null : _switch,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c.icon ?? '', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    c.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink),
                  ),
                ),
                Icon(Icons.expand_more_rounded, color: p.inkMuted),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BizSearchScreen(kit: widget.kit))),
            tooltip: s.bizSearchTitle,
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(14, 4, 14, 24 + MediaQuery.paddingOf(context).bottom),
          children: [
            if (categoryAbout(c.slug, widget.kit.language) case final about?)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                child: Text(about, style: TextStyle(fontSize: 13.5, color: p.inkMuted)),
              ),
            if (businesses == null && _failed)
              QnaMessage(
                icon: Icons.wifi_off_rounded,
                title: s.bizLoadError,
                body: s.bizCheckConnection,
                action: FilledButton.tonalIcon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: Text(s.bizRetry)),
              )
            else if (businesses == null)
              for (var i = 0; i < 5; i++)
                Container(
                  height: 82,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(18)),
                )
            else if (businesses.isEmpty)
              QnaMessage(icon: Icons.storefront_rounded, title: s.bizCategoryEmpty, body: s.bizCategoryEmptyBody)
            else ...[
              if (ranks.first != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: Row(
                    children: [
                      Icon(Icons.favorite_rounded, size: 15, color: const Color(0xFFE25563)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(s.bizOrderNote, style: TextStyle(fontSize: 12.5, color: p.inkSoft))),
                    ],
                  ),
                ),
              for (final (i, b) in businesses.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BizRow(
                    kit: widget.kit,
                    business: b,
                    rank: ranks[i],
                    onTap: () => openBusiness(context, widget.kit, Business(
                      id: b.id,
                      name: b.name,
                      logo: b.logo,
                      description: b.description,
                      likes: b.likes,
                      views: b.views,
                      categoryId: c.id,
                      categoryName: b.categoryName ?? c.name,
                      links: b.links,
                    )),
                  ),
                ),
            ],
            const SizedBox(height: 6),
            OwnerCard(kit: widget.kit, emptyCategory: businesses != null && businesses.isEmpty),
          ],
        ),
      ),
    );
  }
}

/// Search across every kind, as one types; matches grouped by kind, since
/// knowing a match is a bakery rather than an insurer is most of what makes
/// it useful.
class BizSearchScreen extends StatefulWidget {
  const BizSearchScreen({super.key, required this.kit});

  final BizKit kit;

  @override
  State<BizSearchScreen> createState() => _BizSearchScreenState();
}

class _BizSearchScreenState extends State<BizSearchScreen> {
  final _text = TextEditingController();
  Timer? _wait;
  String _query = '';
  List<BizGroup>? _groups;
  bool _failed = false;
  bool _searching = false;

  @override
  void dispose() {
    _wait?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _wait?.cancel();
    _wait = Timer(const Duration(milliseconds: 280), () => _search(value.trim()));
    setState(() {});
  }

  Future<void> _search(String query) async {
    if (query == _query) return;
    _query = query;
    if (query.isEmpty) {
      setState(() {
        _groups = null;
        _failed = false;
        _searching = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _failed = false;
    });
    try {
      final groups = await widget.kit.services.businesses.search(query);
      if (!mounted || query != _query) return;
      setState(() {
        _groups = groups;
        _searching = false;
      });
    } on BizException {
      if (!mounted || query != _query) return;
      setState(() {
        _searching = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final groups = _groups;
    final total = groups?.fold<int>(0, (n, g) => n + g.total) ?? 0;
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(
        backgroundColor: p.page,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: TextField(
          controller: _text,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: (value) => _search(value.trim()),
          style: TextStyle(fontSize: 17, color: p.ink),
          decoration: InputDecoration(
            hintText: s.bizSearchHint,
            border: InputBorder.none,
            suffixIcon: _text.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _text.clear();
                      _onChanged('');
                    },
                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                    icon: Icon(Icons.close_rounded, color: p.inkMuted),
                  ),
          ),
        ),
        bottom: _searching
            ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator(minHeight: 2))
            : null,
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(14, 8, 14, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          if (_failed)
            QnaMessage(
              icon: Icons.wifi_off_rounded,
              title: s.bizLoadError,
              body: s.bizCheckConnection,
              action: FilledButton.tonalIcon(
                onPressed: () {
                  final query = _query;
                  _query = '';
                  _search(query);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(s.bizRetry),
              ),
            )
          else if (groups == null) ...[
            // Nothing typed: the kinds, to start from.
            if (widget.kit.directory?.categories case final categories?) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                child: Text(s.bizCategories, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink)),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in categories)
                    if (c.count > 0)
                      ActionChip(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(builder: (_) => BizCategoryScreen(kit: widget.kit, category: c)),
                        ),
                        avatar: Text(c.icon ?? ''),
                        label: Text(c.name),
                        backgroundColor: p.card,
                        side: BorderSide(color: p.hairline),
                        shape: const StadiumBorder(),
                      ),
                ],
              ),
            ],
          ] else if (groups.isEmpty)
            QnaMessage(icon: Icons.search_off_rounded, title: s.bizNothingFound, body: s.bizNothingFoundBody(_query))
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(s.bizCountFound(total), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.inkSoft)),
            ),
            for (final g in groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 0, 6),
                child: Row(
                  children: [
                    Text(g.category.icon ?? '', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${g.category.name} · ${g.total}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => BizCategoryScreen(kit: widget.kit, category: g.category)),
                      ),
                      child: Text(s.bizSeeAll),
                    ),
                  ],
                ),
              ),
              for (final b in g.businesses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BizRow(kit: widget.kit, business: b, onTap: () => openBusiness(context, widget.kit, b)),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
