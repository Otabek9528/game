import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/calendar_text.dart';
import 'parcel_controller.dart';
import 'parcel_models.dart';
import 'post_card.dart';

/// Couriers flying between Uzbekistan and Korea who carry parcels: the web
/// page (pages/parcel/) rebuilt. Its four steps (direction, how to search,
/// a list, the posts) become one screen: the route on top, remembered and
/// swapped with a tap; under it the days couriers fly with the chosen
/// day's posts, or the cities.
class ParcelScreen extends StatefulWidget {
  const ParcelScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends State<ParcelScreen> {
  late final ParcelController _c = ParcelController(
    source: widget.services.parcels,
    store: widget.services.store,
  );

  /// The swap button turns half a turn each time.
  double _turns = 0;
  String _query = '';
  final _search = TextEditingController();

  AppLanguage get _language => widget.services.locale.language ?? AppLanguage.uz;

  @override
  void initState() {
    super.initState();
    _c.start();
  }

  @override
  void dispose() {
    _c.dispose();
    _search.dispose();
    super.dispose();
  }

  void _swap() {
    HapticFeedback.selectionClick();
    setState(() {
      _turns += 0.5;
      _query = '';
      _search.clear();
    });
    _c.swap();
  }

  Future<void> _refresh() async {
    final ok = await _c.refresh();
    if (!ok && mounted) _failed(context);
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

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.page,
        body: ListenableBuilder(
          listenable: _c,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(
                title: s.parcelTitle,
                onInfo: () => showHowItWorks(context),
                child: _Route(direction: _c.direction, turns: _turns, onSwap: _swap),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: p.accent,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _modes(context)),
                      ...(_c.mode == ParcelMode.byDate ? _byDate(context) : _byCity(context)),
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

  Widget _modes(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: SegmentedButton<ParcelMode>(
        segments: [
          ButtonSegment(value: ParcelMode.byDate, label: Text(s.parcelByDate), icon: const Icon(Icons.event_rounded)),
          ButtonSegment(
            value: ParcelMode.byCity,
            label: Text(s.parcelByCity),
            icon: const Icon(Icons.location_city_rounded),
          ),
        ],
        selected: {_c.mode},
        showSelectedIcon: false,
        onSelectionChanged: (v) {
          HapticFeedback.selectionClick();
          _c.setMode(v.first);
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: p.action,
          selectedForegroundColor: Colors.white,
          foregroundColor: p.inkSoft,
          backgroundColor: p.card,
          side: BorderSide(color: p.hairline),
        ),
      ),
    );
  }

  List<Widget> _byDate(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final dates = _c.dates;
    if (dates.loading) {
      return [
        const SliverToBoxAdapter(child: _StripSkeleton()),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
        ..._postsSkeleton(),
      ];
    }
    if (dates.failed) return [_fill(_Problem(onRetry: _c.refresh))];
    final list = dates.data!;
    if (list.isEmpty) {
      return [
        _fill(_Empty(
          text: s.parcelNoDates,
          action: s.parcelSeeOther(_routeName(s, _c.direction.other)),
          onAction: _swap,
          showHow: true,
        )),
      ];
    }
    final selected = _c.selected!;
    final count = _c.posts.data?.length ?? selected.count;
    return [
      SliverToBoxAdapter(
        child: _DayStrip(
          dates: list,
          selected: selected,
          language: _language,
          onSelect: (d) {
            HapticFeedback.selectionClick();
            _c.select(d);
          },
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  gregorianLine(selected.date, _language),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
                ),
              ),
              Text(s.parcelPostCount(count), style: TextStyle(fontSize: 13, color: p.inkMuted)),
            ],
          ),
        ),
      ),
      ..._posts(_c.posts, onRetry: _c.refresh),
    ];
  }

  List<Widget> _byCity(BuildContext context) {
    final s = AppLocalizations.of(context);
    final cities = _c.cities;
    final chips = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Row(
          children: [
            for (final country in ParcelCountry.values) ...[
              Expanded(
                child: _CountryChip(
                  country: country,
                  label: _countryName(s, country),
                  selected: _c.country == country,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _query = '';
                      _search.clear();
                    });
                    _c.setCountry(country);
                  },
                ),
              ),
              if (country == ParcelCountry.uzb) const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
    if (cities == null || cities.loading) return [chips, const _ListSkeleton()];
    if (cities.failed) return [chips, _fill(_Problem(onRetry: _c.refresh))];
    final list = cities.data!;
    if (list.isEmpty) return [chips, _fill(_Empty(text: s.parcelNoCities))];
    final query = _query.trim().toLowerCase();
    final shown = query.isEmpty ? list : list.where((c) => c.name.toLowerCase().contains(query)).toList();
    return [
      chips,
      if (list.length > 8)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
            child: _SearchField(
              controller: _search,
              hint: s.parcelSearchCity,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      if (shown.isEmpty)
        _fill(_Empty(text: s.parcelNoCities))
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          sliver: SliverToBoxAdapter(
            child: _CityList(cities: shown, onOpen: _openCity),
          ),
        ),
    ];
  }

  List<Widget> _posts(Fetch<List<ParcelPost>> posts, {required Future<bool> Function() onRetry}) =>
      postSlivers(context, posts, onRetry: onRetry, onOpen: widget.services.openLink);

  List<Widget> _postsSkeleton() => postSlivers(context, const Fetch.loading(), onRetry: _c.refresh, onOpen: (_) async {});
}

/// The posts of a city, from the city list.
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
  Fetch<List<ParcelPost>> _posts = const Fetch.loading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<bool> _load() async {
    try {
      final list = await widget.controller.postsByCity(widget.city, widget.country, widget.direction);
      if (mounted) setState(() => _posts = Fetch.done(list));
      return true;
    } catch (_) {
      if (mounted && _posts.data == null) setState(() => _posts = const Fetch.failed());
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
    final count = _posts.data?.length;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.page,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(
              title: '${widget.country.flag} ${widget.city}',
              child: Text(
                [_routeName(s, widget.direction), if (count != null) s.parcelPostCount(count)].join('  ·  '),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: p.accent,
                onRefresh: () async {
                  if (!await _load() && context.mounted) _failed(context);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    ...postSlivers(context, _posts, onRetry: _retry, onOpen: widget.services.openLink),
                    SliverToBoxAdapter(child: SizedBox(height: 24 + bottom)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The posts in their states: placeholders while loading, a retry when
/// they couldn't load, a note when there are none.
List<Widget> postSlivers(
  BuildContext context,
  Fetch<List<ParcelPost>> posts, {
  required Future<bool> Function() onRetry,
  required Future<void> Function(Uri) onOpen,
}) {
  final s = AppLocalizations.of(context);
  if (posts.loading) {
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        sliver: SliverList.separated(
          itemCount: 2,
          itemBuilder: (_, _) => const _PostSkeleton(),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
        ),
      ),
    ];
  }
  if (posts.failed) return [_fill(_Problem(onRetry: onRetry))];
  final list = posts.data!;
  if (list.isEmpty) return [_fill(_Empty(text: s.parcelNoPosts))];
  return [
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      sliver: SliverList.separated(
        itemCount: list.length,
        itemBuilder: (_, i) => PostCard(post: list[i], onOpen: onOpen),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
      ),
    ),
  ];
}

/// "Qanday ishlaydi?": the web page's three steps.
Future<void> showHowItWorks(BuildContext context) {
  final s = AppLocalizations.of(context);
  final p = VegukinPalette.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: p.card,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.parcelHowTitle, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink)),
            const SizedBox(height: 4),
            Text(s.parcelTagline, style: TextStyle(fontSize: 14, color: p.inkMuted)),
            const SizedBox(height: 14),
            const _HowSteps(),
          ],
        ),
      ),
    ),
  );
}

void _failed(BuildContext context) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).parcelError),
      behavior: SnackBarBehavior.floating,
    ));
}

Widget _fill(Widget child) => SliverFillRemaining(hasScrollBody: false, child: child);

String _routeName(AppLocalizations s, ParcelDirection d) =>
    d == ParcelDirection.uzbToKor ? s.parcelUzbToKor : s.parcelKorToUzb;

String _countryName(AppLocalizations s, ParcelCountry c) => c == ParcelCountry.uzb ? s.parcelUzbekistan : s.parcelKorea;

String _capital(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// The emerald top: the bar, and under it [child] (the route, or a
/// subtitle).
class _Hero extends StatelessWidget {
  const _Hero({required this.title, required this.child, this.onInfo});

  final String title;
  final Widget child;
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.hero.sublist(1)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
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
                  if (onInfo != null)
                    IconButton(
                      onPressed: onInfo,
                      tooltip: s.parcelHowTitle,
                      icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
                    ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(16, 2, 16, 18), child: child),
          ],
        ),
      ),
    );
  }
}

/// From and to, with the swap between them, as flight searches do it.
class _Route extends StatelessWidget {
  const _Route({required this.direction, required this.turns, required this.onSwap});

  final ParcelDirection direction;
  final double turns;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: _Place(label: s.parcelFrom, country: direction.from, name: _countryName(s, direction.from))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: Colors.black38,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSwap,
              child: Tooltip(
                message: s.parcelSwap,
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
          ),
        ),
        Expanded(
          child: _Place(label: s.parcelTo, country: direction.to, name: _countryName(s, direction.to), end: true),
        ),
      ],
    );
  }
}

class _Place extends StatelessWidget {
  const _Place({required this.label, required this.country, required this.name, this.end = false});

  final String label;
  final ParcelCountry country;
  final String name;
  final bool end;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Column(
          key: ValueKey(country),
          crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70)),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: end ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(country.flag, style: const TextStyle(fontSize: 19)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The days couriers fly, side by side; each with its post count.
class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.dates, required this.selected, required this.language, required this.onSelect});

  final List<ParcelDate> dates;
  final ParcelDate selected;
  final AppLanguage language;
  final ValueChanged<ParcelDate> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        clipBehavior: Clip.none,
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _DayChip(
          date: dates[i],
          selected: dates[i].key == selected.key,
          language: language,
          onTap: () => onSelect(dates[i]),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.date, required this.selected, required this.language, required this.onTap});

  final ParcelDate date;
  final bool selected;
  final AppLanguage language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final now = DateTime.now();
    final days = DateTime.utc(date.date.year, date.date.month, date.date.day)
        .difference(DateTime.utc(now.year, now.month, now.day))
        .inDays;
    final top = switch (days) {
      0 => s.dayToday,
      1 => s.dayTomorrow,
      _ => _capital(DateFormat.E(language.code).format(date.date)),
    };
    final ink = selected ? Colors.white : p.ink;
    final soft = selected ? Colors.white70 : p.inkMuted;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: selected ? p.action : p.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: selected ? p.action : p.hairline),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 70,
              height: 84,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    top,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: soft),
                  ),
                  Text(
                    '${date.date.day}',
                    style: TextStyle(fontSize: 25, height: 1.15, fontWeight: FontWeight.w800, color: ink),
                  ),
                  Text(
                    _capital(DateFormat.MMM(language.code).format(date.date)),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: soft),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (date.count > 0)
          Positioned(
            top: -7,
            right: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Brand.gold400,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: p.page, width: 2),
              ),
              child: Text(
                '${date.count}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF3B2A05)),
              ),
            ),
          ),
      ],
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({required this.country, required this.label, required this.selected, required this.onTap});

  final ParcelCountry country;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Material(
      color: selected ? p.cardSelected : p.card,
      shape: StadiumBorder(side: BorderSide(color: selected ? p.accent : p.hairline, width: selected ? 1.5 : 1)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? p.accent : p.inkSoft,
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint, required this.onChanged});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search_rounded, color: p.inkMuted),
        filled: true,
        fillColor: p.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.hairline)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.hairline)),
        focusedBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.accent)),
      ),
    );
  }
}

class _CityList extends StatelessWidget {
  const _CityList({required this.cities, required this.onOpen});

  final List<ParcelCity> cities;
  final ValueChanged<ParcelCity> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Material(
      color: p.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.hairline),
      ),
      child: Column(
        children: [
          for (final (i, city) in cities.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 62, color: p.hairline),
            InkWell(
              onTap: () => onOpen(city),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: p.cardSelected, shape: BoxShape.circle),
                      child: Icon(Icons.location_on_rounded, size: 19, color: p.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        city.name,
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: p.ink),
                      ),
                    ),
                    Text(s.parcelPostCount(city.count), style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                    Icon(Icons.chevron_right_rounded, color: p.inkMuted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.onRetry});

  final Future<bool> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: p.inkMuted),
          const SizedBox(height: 12),
          Text(
            s.parcelError,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, height: 1.45, color: p.inkSoft),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              onRetry();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(s.retry),
            style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text, this.action, this.onAction, this.showHow = false});

  final String text;
  final String? action;
  final VoidCallback? onAction;
  final bool showHow;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: p.cardSelected, shape: BoxShape.circle),
            child: Icon(Icons.inbox_rounded, size: 36, color: p.accent),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w600, color: p.inkSoft),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(action!, textAlign: TextAlign.center),
              style: OutlinedButton.styleFrom(
                foregroundColor: p.accent,
                minimumSize: const Size(0, 46),
                side: BorderSide(color: p.accent.withValues(alpha: 0.5)),
                shape: const StadiumBorder(),
              ),
            ),
          ],
          if (showHow) ...[
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: p.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: p.gold.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.parcelHowTitle, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink)),
                  const SizedBox(height: 10),
                  const _HowSteps(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HowSteps extends StatelessWidget {
  const _HowSteps();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Column(
      children: [
        for (final (i, step) in [s.parcelHow1, s.parcelHow2, s.parcelHow3].indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: p.action,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(step, style: TextStyle(fontSize: 14, height: 1.35, color: p.inkSoft))),
              ],
            ),
          ),
      ],
    );
  }
}

/// Grey shapes that breathe while the real ones load.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: Tween(begin: 0.45, end: 1.0).animate(_a), child: widget.child);
}

class _Bone extends StatelessWidget {
  const _Bone({this.width, required this.height, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: VegukinPalette.of(context).hairline,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class _StripSkeleton extends StatelessWidget {
  const _StripSkeleton();

  @override
  Widget build(BuildContext context) => _Pulse(
        child: SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            itemCount: 6,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, _) => const _Bone(width: 70, height: 84, radius: 16),
          ),
        ),
      );
}

class _PostSkeleton extends StatelessWidget {
  const _PostSkeleton();

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return _Pulse(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.hairline),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Bone(width: 42, height: 42, radius: 21),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_Bone(width: 130, height: 13), SizedBox(height: 7), _Bone(width: 90, height: 11)],
                ),
              ],
            ),
            SizedBox(height: 16),
            _Bone(height: 12),
            SizedBox(height: 8),
            _Bone(height: 12),
            SizedBox(height: 8),
            _Bone(width: 180, height: 12),
            SizedBox(height: 16),
            _Bone(height: 44, radius: 22),
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        sliver: SliverToBoxAdapter(
          child: _Pulse(
            child: Column(
              children: [
                for (var i = 0; i < 5; i++)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: _Bone(height: 56, radius: 14),
                  ),
              ],
            ),
          ),
        ),
      );
}
