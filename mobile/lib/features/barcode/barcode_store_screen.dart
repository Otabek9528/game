import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'barcode_models.dart';
import 'barcode_parts.dart';
import 'barcode_result.dart';

/// One store's checked products (pages/barcode/store.html): by verdict, then
/// by category, loading more as the list is scrolled.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, required this.services, required this.store});

  final AppServices services;
  final StoreSummary store;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const _page = 20;

  final _scroll = ScrollController();
  StoreMeta? _meta;
  Verdict _verdict = Verdict.joiz;
  String? _category;

  final _products = <Product>[];
  bool _loading = false;
  bool _hasMore = true;
  bool _failed = false;

  /// Bumped on every change of tab or category: answers to an older request
  /// are dropped.
  int _round = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMeta();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    try {
      final meta = await widget.services.barcodes.store(widget.store.store);
      if (mounted) setState(() => _meta = meta);
    } on Exception {
      // The tabs show no counts; the products still load.
    }
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    final round = _round;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await widget.services.barcodes.storeProducts(
        widget.store.store,
        verdict: _verdict,
        category: _category,
        offset: _products.length,
        limit: _page,
      );
      if (!mounted || round != _round) return;
      setState(() {
        _products.addAll(page.products);
        _hasMore = page.hasMore;
        _loading = false;
      });
    } on Exception {
      if (!mounted || round != _round) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 600 && !_failed) _load();
  }

  void _choose({Verdict? verdict, String? category, bool allCategories = false}) {
    HapticFeedback.selectionClick();
    setState(() {
      _round++;
      if (verdict != null && verdict != _verdict) {
        _verdict = verdict;
        // Each verdict has its own categories.
        _category = null;
      }
      if (allCategories) _category = null;
      if (category != null) _category = category;
      _products.clear();
      _hasMore = true;
      _loading = false;
      _failed = false;
    });
    _load();
    if (_scroll.hasClients && _scroll.offset > _heroHeight) {
      _scroll.jumpTo(_heroHeight);
    }
  }

  static const _heroHeight = 112.0;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final meta = _meta;
    final categories = [
      for (final (name, counts) in meta?.categories ?? const <(String, Map<Verdict, int>)>[])
        if ((counts[_verdict] ?? 0) > 0) (name, counts[_verdict]!),
    ];
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: p.page,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: _heroHeight + kToolbarHeight,
            backgroundColor: p.hero.first,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
            titleTextStyle: const TextStyle(
              fontFamily: Brand.displayFont,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.white,
            ),
            title: Text(widget.store.store),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.hero),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Row(
                      children: [
                        StoreEmblem(widget.store.store, size: 64, padding: 8),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                s.barcodeProducts(meta?.total ?? widget.store.count),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterBar(
              height: categories.isEmpty ? 76 : 122,
              child: _Filters(
                verdict: _verdict,
                counts: meta?.byVerdict,
                categories: categories,
                category: _category,
                onVerdict: (v) => _choose(verdict: v),
                onCategory: (c) => c == null ? _choose(allCategories: true) : _choose(category: c),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.74,
              ),
              itemCount: _products.length,
              itemBuilder: (context, i) => _ProductCard(
                product: _products[i],
                onTap: () => showProductSheet(context, widget.services, _products[i]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, 24 + bottom),
              child: _failed
                  ? Column(
                      children: [
                        Text(s.barcodeProductsError, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink)),
                        const SizedBox(height: 2),
                        Text(s.barcodeCheckConnection, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: p.inkMuted)),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(s.barcodeRetry),
                        ),
                      ],
                    )
                  : _loading
                      ? const Center(
                          child: SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 3)),
                        )
                      : _products.isEmpty
                          ? Column(
                              children: [
                                const SizedBox(height: 20),
                                Icon(Icons.search_off_rounded, size: 44, color: p.inkMuted),
                                const SizedBox(height: 8),
                                Text(s.barcodeStoreEmpty, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.ink)),
                                const SizedBox(height: 2),
                                Text(s.barcodeStoreEmptyDesc, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: p.inkMuted)),
                              ],
                            )
                          : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends SliverPersistentHeaderDelegate {
  const _FilterBar({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => SizedBox.expand(
        child: Material(
          color: VegukinPalette.of(context).page,
          elevation: overlapsContent ? 2 : 0,
          child: child,
        ),
      );

  @override
  bool shouldRebuild(_FilterBar old) => true;
}

/// The three verdicts as tabs, each with its count, and the categories
/// under the chosen one.
class _Filters extends StatelessWidget {
  const _Filters({
    required this.verdict,
    required this.counts,
    required this.categories,
    required this.category,
    required this.onVerdict,
    required this.onCategory,
  });

  final Verdict verdict;
  final Map<Verdict, int>? counts;
  final List<(String, int)> categories;
  final String? category;
  final ValueChanged<Verdict> onVerdict;
  final ValueChanged<String?> onCategory;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(
            children: [
              for (final (i, v) in Verdict.values.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _VerdictTab(
                    verdict: v,
                    count: counts?[v],
                    selected: v == verdict,
                    onTap: () => onVerdict(v),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (categories.isNotEmpty)
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              children: [
                _CategoryChip(
                  icon: Icons.apps_rounded,
                  label: s.barcodeAll,
                  count: counts?[verdict],
                  selected: category == null,
                  onTap: () => onCategory(null),
                ),
                for (final (name, count) in categories)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Builder(builder: (context) {
                      final (icon, label) = categoryLook(s, name);
                      return _CategoryChip(
                        icon: icon,
                        label: label,
                        count: count,
                        selected: category == name,
                        onTap: () => onCategory(name),
                      );
                    }),
                  ),
              ],
            ),
          ),
        const Spacer(),
        Divider(height: 1, color: p.hairline),
      ],
    );
  }
}

class _VerdictTab extends StatelessWidget {
  const _VerdictTab({required this.verdict, required this.count, required this.selected, required this.onTap});

  final Verdict verdict;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final style = VerdictStyle.of(context, verdict);
    final ink = selected ? Colors.white : style.color;
    return Material(
      color: selected ? style.solid : style.color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(style.icon, size: 16, color: ink),
                  if (count != null) ...[
                    const SizedBox(width: 4),
                    Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ink)),
                  ],
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  VerdictStyle.label(s, verdict),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final ink = selected ? Colors.white : p.ink;
    return Material(
      color: selected ? p.accent : p.card,
      shape: StadiumBorder(side: BorderSide(color: selected ? p.accent : p.hairline)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : p.accent),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white70 : p.inkMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final style = VerdictStyle.of(context, product.verdict);
    final category = product.category;
    return Material(
      color: p.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: p.hairline)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductPhoto(product),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(style.icon, size: 22, color: style.color),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category != null)
                    Text(
                      categoryLook(s, category).$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.accent),
                    ),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, height: 1.3, fontWeight: FontWeight.w700, color: p.ink),
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
