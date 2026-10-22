import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'car_detail.dart';
import 'cars_kit.dart';
import 'cars_models.dart';
import 'cars_parts.dart';
import 'cars_picker.dart';

/// The used-car market, as the Mini App has it: everything newest first or
/// one model with its going price (Browse), filters (Search), and the cars
/// saved on this phone (Saved).
class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  late final CarsKit _kit = CarsKit(widget.services);
  int _tab = 0;
  final _opened = <int>{0};

  @override
  void initState() {
    super.initState();
    unawaited(_kit.loadCatalog());
  }

  @override
  void dispose() {
    _kit.dispose();
    super.dispose();
  }

  void _go(int tab) {
    if (tab == _tab) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tab = tab;
      _opened.add(tab);
    });
    if (tab == 2) unawaited(_kit.refreshFavorites());
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) _go(0);
      },
      child: Scaffold(
        backgroundColor: p.page,
        body: IndexedStack(
          index: _tab,
          children: [
            _BrowseTab(kit: _kit),
            if (_opened.contains(1)) _SearchTab(kit: _kit) else const SizedBox.shrink(),
            if (_opened.contains(2)) _SavedTab(kit: _kit, onBrowse: () => _go(0)) else const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: _kit,
          builder: (context, _) => NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: _go,
            backgroundColor: p.card,
            indicatorColor: p.cardSelected,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.directions_car_outlined),
                selectedIcon: Icon(Icons.directions_car_rounded, color: p.accent),
                label: s.carTabBrowse,
              ),
              NavigationDestination(
                icon: const Icon(Icons.manage_search_rounded),
                selectedIcon: Icon(Icons.manage_search_rounded, color: p.accent),
                label: s.carTabSearch,
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: _kit.favorites.isNotEmpty,
                  label: Text('${_kit.favorites.length}'),
                  child: const Icon(Icons.favorite_border_rounded),
                ),
                selectedIcon: Badge(
                  isLabelVisible: _kit.favorites.isNotEmpty,
                  label: Text('${_kit.favorites.length}'),
                  child: Icon(Icons.favorite_rounded, color: p.accent),
                ),
                label: s.carTabSaved,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tab's top: its title (or the make picker), a line under it.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.title, this.subtitle, this.leading, this.onTap, this.trailing});

  final String title;
  final Widget? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final content = Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 10)],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: p.ink)),
              if (subtitle != null)
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 12.5, color: p.inkMuted),
                  child: subtitle!,
                ),
            ],
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 6),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.expand_more_rounded, size: 20, color: p.accent),
          ),
        ],
      ],
    );
    return SliverAppBar(
      pinned: true,
      backgroundColor: p.page,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 64,
      titleSpacing: 0,
      title: onTap == null
          ? Padding(padding: const EdgeInsets.only(left: 4), child: content)
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), child: content),
            ),
      actions: [?trailing, const SizedBox(width: 8)],
    );
  }
}


// ------------------------------------------------------------------ browse

class _BrowseTab extends StatefulWidget {
  const _BrowseTab({required this.kit});

  final CarsKit kit;

  @override
  State<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<_BrowseTab> with AutomaticKeepAliveClientMixin {
  CarsKit get _kit => widget.kit;

  /// The model shown; null: every listing, newest first.
  CarPick? _pick;
  List<Car>? _cars;
  MarketStats? _stats;
  int? _count;
  String? _error;
  CarSort _sort = CarSort.newest;
  String? _status;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final pick = _pick;
    setState(() {
      _error = null;
      _cars = null;
    });
    try {
      if (pick == null) {
        final found = await _kit.source.search(const CarQuery());
        if (!mounted || _pick != null) return;
        setState(() {
          _cars = _kit.remember(found.cars);
          _count = found.count;
          _stats = null;
        });
      } else {
        final set = await _kit.modelSet(pick.brand, pick.model);
        if (!mounted || _pick != pick) return;
        setState(() {
          _cars = set.cars;
          _stats = set.stats;
        });
      }
    } on CarsException catch (e) {
      if (mounted) setState(() => _error = e.code);
    }
  }

  Future<void> _choose() async {
    final chosen = await pickCar(context, _kit, allowAny: true);
    if (chosen == null || !mounted) return;
    setState(() => _pick = chosen.pick);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = AppLocalizations.of(context);
    final pick = _pick;
    final cars = _cars;
    final stats = _stats;
    final sorts = [
      (CarSort.newest, s.carSortNew),
      (CarSort.value, s.carSortValue),
      (CarSort.priceLow, s.carSortPriceUp),
      (CarSort.priceHigh, s.carSortPriceDown),
      (CarSort.mileageLow, s.carSortMileage),
      (CarSort.yearNew, s.carSortYear),
    ];
    return ListenableBuilder(
      listenable: _kit,
      builder: (context, _) {
        final shown = cars == null
            ? null
            : sortCars([for (final c in cars) if (_status == null || (_status == 'sold') == c.sold) _kit.known(c.id) ?? c], _sort, _kit.thisYear);
        return RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              _TabBar(
                title: pick == null ? s.carMarket : [pick.brand, ?pick.model].join(' '),
                leading: pick == null ? null : BrandLogo(pick.brand, size: 38),
                subtitle: cars == null
                    ? Text(s.carLoading)
                    : pick == null
                        ? Text(s.carListings('${_count ?? cars.length}'))
                        : Text(s.carAvailableSold('${stats?.countAvailable ?? 0}', '${stats?.countSold ?? 0}')),
                onTap: _choose,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.list(
                  children: [
                    if (stats != null) ...[MarketSummary(stats: stats), const SizedBox(height: 14)],
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: sorts.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => CarChip(
                          label: sorts[i].$2,
                          on: _sort == sorts[i].$1,
                          onTap: () => setState(() => _sort = sorts[i].$1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    StatusSwitch(value: _status, onChanged: (v) => setState(() => _status = v)),
                    const SizedBox(height: 14),
                    if (_error != null && cars == null)
                      CarsMessage(emoji: '⚠️', title: s.carLoadFailed, body: s.carCheckInternet, action: s.retry, onAction: _load)
                    else if (shown == null)
                      const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                    else ...[
                      if (shown.isEmpty)
                        pick == null
                            ? CarsMessage(emoji: '🚗', title: s.carEmptyAllTitle, body: s.carEmptyAllBody)
                            : CarsMessage(emoji: '🚗', title: s.carEmptyModelTitle, body: s.carEmptyModelBody),
                      for (final (i, car) in shown.indexed) ...[
                        if (i == 6) ...[_channel(), const SizedBox(height: 12)],
                        CarCard(kit: _kit, car: car, showModel: pick == null || pick.model == null, onTap: () => openCar(context, _kit, car.id)),
                        const SizedBox(height: 12),
                      ],
                      if (shown.length < 6) _channel(),
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

  Widget _channel() => ChannelCard(onTap: () => _kit.services.openLink(ChannelCard.url));
}

// ------------------------------------------------------------------ search

class _SearchTab extends StatefulWidget {
  const _SearchTab({required this.kit});

  final CarsKit kit;

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> with AutomaticKeepAliveClientMixin {
  CarsKit get _kit => widget.kit;

  CarPick? _pick;
  final _price = TextEditingController();
  final _mileage = TextEditingController();
  final _year = TextEditingController();
  final _fuels = <String>{};
  String? _status;

  ({List<Car> cars, int count})? _found;
  String? _error;
  Timer? _wait;
  int _asked = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_search());
  }

  @override
  void dispose() {
    _wait?.cancel();
    _price.dispose();
    _mileage.dispose();
    _year.dispose();
    super.dispose();
  }

  static int? _number(TextEditingController c) {
    final v = int.tryParse(c.text.replaceAll(RegExp(r'\D'), ''));
    return v == null || v == 0 ? null : v;
  }

  CarQuery get _query => CarQuery(
        pick: _pick,
        priceMax: _number(_price),
        mileageMax: _number(_mileage),
        yearFrom: _number(_year),
        fuels: {..._fuels},
        status: _status,
      );

  bool get _filtered => _query.params.isNotEmpty;

  void _soon() {
    _wait?.cancel();
    _wait = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    final asked = ++_asked;
    setState(() {
      _error = null;
      _found = null;
    });
    try {
      final found = await _kit.source.search(_query);
      if (!mounted || asked != _asked) return;
      setState(() => _found = (cars: _kit.remember(found.cars), count: found.count));
    } on CarsException catch (e) {
      if (mounted && asked == _asked) setState(() => _error = e.code);
    }
  }

  Future<void> _choose() async {
    final chosen = await pickCar(context, _kit, allowAny: true);
    if (chosen == null || !mounted) return;
    setState(() => _pick = chosen.pick);
    await _search();
  }

  void _clear() {
    HapticFeedback.lightImpact();
    _price.clear();
    _mileage.clear();
    _year.clear();
    setState(() {
      _pick = null;
      _fuels.clear();
      _status = null;
    });
    _search();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final found = _found;
    final pick = _pick;
    return ListenableBuilder(
      listenable: _kit,
      builder: (context, _) => CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          _TabBar(
            title: s.carTabSearch,
            subtitle: Text(s.carSearchSub),
            trailing: _filtered ? TextButton(onPressed: _clear, child: Text(s.carClearFilters)) : null,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverList.list(
              children: [
                Material(
                  color: p.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: pick == null ? p.hairline : p.accent, width: pick == null ? 1 : 1.5),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _choose,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          pick == null
                              ? Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(11)),
                                  child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 22),
                                )
                              : BrandLogo(pick.brand, size: 38),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              pick == null ? s.carPickModel : pick.model == null ? s.carAllOf(pick.brand) : '${pick.brand} ${pick.model}',
                              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: pick == null ? p.inkSoft : p.ink),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: p.inkMuted),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _Field(label: s.carPriceMax, controller: _price, hint: '7 000 000', grouped: true, onChanged: _soon),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _Field(label: s.carMileageMax, controller: _mileage, hint: '150 000', grouped: true, onChanged: _soon)),
                    const SizedBox(width: 12),
                    Expanded(child: _Field(label: s.carYearFrom, controller: _year, hint: '2012', maxLength: 4, onChanged: _soon)),
                  ],
                ),
                const SizedBox(height: 14),
                _Label(s.carFuel),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final fuel in carFuels)
                      CarChip(
                        label: fuelLabel(s, fuel)!,
                        on: _fuels.contains(fuel),
                        onTap: () {
                          setState(() => _fuels.contains(fuel) ? _fuels.remove(fuel) : _fuels.add(fuel));
                          _search();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _Label(s.carStatus),
                StatusSwitch(
                  value: _status,
                  onChanged: (v) {
                    setState(() => _status = v);
                    _search();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
                  child: Text(
                    found == null ? s.carLoading : s.carResults('${found.count}'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.ink),
                  ),
                ),
                if (_error != null)
                  CarsMessage(emoji: '⚠️', title: s.carLoadFailed, body: s.carCheckInternet, action: s.retry, onAction: _search)
                else if (found == null)
                  const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
                else if (found.cars.isEmpty)
                  CarsMessage(emoji: '🔍', title: s.carNothingFound, body: s.carWidenFilters)
                else
                  for (final car in found.cars) ...[
                    CarCard(kit: _kit, car: _kit.known(car.id) ?? car, showModel: true, onTap: () => openCar(context, _kit, car.id)),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VegukinPalette.of(context).inkSoft)),
      );
}

/// A number typed in: "7 000 000" as it's typed when [grouped].
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller, required this.hint, required this.onChanged, this.grouped = false, this.maxLength});

  final String label;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final bool grouped;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.hairline));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(label),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
            if (grouped) const _Grouped(),
          ],
          onChanged: (_) => onChanged(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: p.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(borderSide: BorderSide(color: p.accent, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _Grouped extends TextInputFormatter {
  const _Grouped();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final text = digits.isEmpty ? '' : groupDigits(digits);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

// ------------------------------------------------------------------ saved

class _SavedTab extends StatelessWidget {
  const _SavedTab({required this.kit, required this.onBrowse});

  final CarsKit kit;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: kit,
      builder: (context, _) {
        final saved = kit.favorites;
        return RefreshIndicator(
          onRefresh: kit.refreshFavorites,
          child: CustomScrollView(
            slivers: [
              _TabBar(title: s.carTabSaved, subtitle: Text(s.carSavedSub('${saved.length}'))),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.list(
                  children: [
                    if (saved.isEmpty)
                      CarsMessage(
                        emoji: '🤍',
                        title: s.carSavedEmptyTitle,
                        body: s.carSavedEmptyBody,
                        action: s.carStartBrowsing,
                        onAction: onBrowse,
                      ),
                    for (final car in saved) ...[
                      CarCard(kit: kit, car: car, showModel: true, onTap: () => openCar(context, kit, car.id)),
                      const SizedBox(height: 12),
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

