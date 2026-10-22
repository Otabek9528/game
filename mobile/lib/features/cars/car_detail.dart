import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../core/widgets/photos.dart';
import '../../l10n/app_localizations.dart';
import 'cars_kit.dart';
import 'cars_models.dart';
import 'cars_parts.dart';

void openCar(BuildContext context, CarsKit kit, int id) {
  kit.markSeen(id);
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CarDetailScreen(kit: kit, id: id)));
}

/// A listing: its photos and videos, price and the main facts, the post
/// itself (the facts are read from it by a machine), how the price sits in
/// its model's market, the details, the seller, and cars like it.
class CarDetailScreen extends StatefulWidget {
  const CarDetailScreen({super.key, required this.kit, required this.id});

  final CarsKit kit;
  final int id;

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  CarsKit get _kit => widget.kit;

  Car? _car;
  ({List<Car> cars, MarketStats stats})? _market;
  String? _error;
  final _textKey = GlobalKey();
  final _scroll = ScrollController();
  bool _collapsed = false;

  static const _heroHeight = 300.0;

  @override
  void initState() {
    super.initState();
    _car = _kit.known(widget.id);
    unawaited(_load());
    _scroll.addListener(() {
      final collapsed = _scroll.hasClients && _scroll.offset > _heroHeight - kToolbarHeight - 30;
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
      final car = await _kit.loadFull(widget.id);
      if (!mounted) return;
      setState(() => _car = car);
      if (car.brand != null) {
        final market = await _kit.modelSet(car.brand!, car.model);
        if (mounted) setState(() => _market = market);
      }
    } on CarsException catch (e) {
      if (mounted && (_car == null || !_car!.full)) setState(() => _error = e.code);
    }
  }

  void _call(String phone) {
    HapticFeedback.mediumImpact();
    _kit.services.openLink(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), '')));
  }

  void _telegram(String handle) {
    HapticFeedback.lightImpact();
    _kit.services.openLink(Uri.parse('https://t.me/$handle'));
  }

  void _toText() {
    final target = _textKey.currentContext;
    if (target != null) Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 400), alignment: 0.1);
  }

  void _photos(Car car, int index) {
    final s = AppLocalizations.of(context);
    final media = car.media ?? const [];
    final width = (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round();
    showPhotoViewer(
      context,
      [
        for (final m in media)
          ViewerPicture(
            quick: m.thumb == null ? null : NetworkImage('${m.thumb}'),
            screen: m.video || m.url == null
                ? NetworkImage('${m.thumb ?? m.url}')
                : ResizeImage(NetworkImage('${m.url}'), width: (width * 1.5).round(), policy: ResizeImagePolicy.fit),
            onPlay: m.video && m.url != null ? () => _kit.services.openLink(m.url!) : null,
            caption: m.video && m.sizeBytes != null ? s.carVideoSize((m.sizeBytes! / 1048576).toStringAsFixed(1)) : null,
          ),
      ],
      index,
      counter: (i, n) => s.plPhotoCount('$i', '$n'),
      failed: s.plPhotoFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final car = _car;
    if (car == null) {
      return Scaffold(
        backgroundColor: p.page,
        appBar: AppBar(backgroundColor: p.page, surfaceTintColor: Colors.transparent),
        body: _error == null
            ? const Center(child: CircularProgressIndicator())
            : CarsMessage(emoji: '⚠️', title: s.carListingFailed, body: s.carCheckInternet, action: s.retry, onAction: _load),
      );
    }
    final market = _market;
    final saved = _kit.isFavorite(car.id);
    final iconInk = _collapsed ? Colors.white : const Color(0xFF292524);
    return ListenableBuilder(
      listenable: _kit,
      builder: (context, _) {
        final car = _kit.known(widget.id) ?? _car!;
        return Scaffold(
          backgroundColor: p.page,
          bottomNavigationBar: car.full ? _ActionBar(car: car, kit: _kit, onCall: _call, onTelegram: _telegram, onText: _toText) : null,
          body: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: _heroHeight,
                backgroundColor: _collapsed ? p.hero.first : Colors.transparent,
                surfaceTintColor: Colors.transparent,
                systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
                leading: _Round(plain: _collapsed, child: BackButton(color: iconInk)),
                title: _collapsed
                    ? Text(car.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white))
                    : null,
                actions: [
                  _Round(
                    plain: _collapsed,
                    child: IconButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _kit.toggleFavorite(car);
                      },
                      tooltip: saved ? s.carUnsave : s.carSave,
                      icon: Icon(
                        _kit.isFavorite(car.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _kit.isFavorite(car.id) ? const Color(0xFFE11D48) : iconInk,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _Gallery(car: car, onOpen: (i) => _photos(car, i)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                sliver: SliverList.list(
                  children: [
                    _Head(car: car, median: _medianFor(car, market)),
                    if (!car.full) ...[
                      const SizedBox(height: 30),
                      if (_error != null)
                        CarsMessage(emoji: '⚠️', title: s.carListingFailed, action: s.retry, onAction: _load)
                      else
                        const Center(child: CircularProgressIndicator()),
                    ] else ...[
                      const SizedBox(height: 16),
                      _Notice(text: s.carNotice),
                      _Section(
                        key: _textKey,
                        title: s.carPostText,
                        child: _PostText(car: car),
                      ),
                      if (market != null && market.stats.available.n > 0)
                        _Section(title: s.carPriceAnalysis, child: _PriceAnalysis(car: car, market: market, thisYear: _kit.thisYear)),
                      _Section(title: s.carDetails, child: _Specs(car: car)),
                      if (car.contact != null || car.contactHandle != null)
                        _Section(title: s.carContact, child: _Contact(car: car, onCall: _call, onTelegram: _telegram)),
                      if (market != null)
                        _Section(
                          title: s.carSimilar,
                          subtitle: s.carSimilarSub,
                          child: _Similar(kit: _kit, car: car, market: market),
                        ),
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

  /// The going price to judge [car] by: of cars about its year when there
  /// are enough, else of its model.
  int? _medianFor(Car car, ({List<Car> cars, MarketStats stats})? market) {
    if (market == null) return null;
    return (nearYears(car, market.cars)?.spread ?? market.stats.available).med;
  }
}

class _Round extends StatelessWidget {
  const _Round({required this.child, required this.plain});

  final Widget child;
  final bool plain;

  @override
  Widget build(BuildContext context) => plain
      ? child
      : Padding(
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

/// The photos and videos, swiped through; a tap opens them full screen.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.car, required this.onOpen});

  final Car car;
  final ValueChanged<int> onOpen;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final car = widget.car;
    final media = car.media ?? const [];
    if (media.isEmpty) return CarPhoto(car: car, width: 1080);
    final width = (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round();
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: media.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            final m = media[i];
            final placeholder = CarPlaceholder(id: car.id);
            Widget image(Uri? url, {int? cache}) => url == null
                ? placeholder
                : Image.network('$url', fit: BoxFit.cover, cacheWidth: cache, gaplessPlayback: true, errorBuilder: (_, _, _) => const SizedBox.shrink());
            return GestureDetector(
              onTap: () => widget.onOpen(i),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  placeholder,
                  image(m.thumb, cache: 400),
                  if (!m.video) image(m.url, cache: width),
                  if (m.video)
                    const Center(
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xE6FFFFFF),
                        child: Icon(Icons.play_arrow_rounded, size: 38, color: Colors.black87),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (media.length > 1)
          Positioned(
            right: 12,
            bottom: 12,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    s.plPhotoCount('${_index + 1}', '${media.length}'),
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.car, required this.median});

  final Car car;
  final int? median;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final title = [if (car.year != null) '${car.year}', ?car.brand, ?car.model, ?car.generation].join(' ');
    final price = car.priceKrw;
    final colour = price == null ? p.inkMuted : dealColour(context, dealOf(price, median), sold: car.sold);
    final pills = [
      if (car.year != null) (Icons.calendar_today_rounded, '${car.year}'),
      if (car.mileageKm != null) (Icons.speed_rounded, kmShort(car.mileageKm!)),
      if (fuelLabel(s, car.fuel) case final fuel?) (Icons.local_gas_station_rounded, fuel),
      if (gearboxLabel(s, car.transmission) case final gearbox?) (Icons.settings_rounded, gearbox),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.isEmpty ? s.carListing : title,
          style: TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: p.ink),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              price == null ? s.carNoPrice : won(price),
              style: TextStyle(fontSize: price == null ? 17 : 27, fontWeight: FontWeight.w900, letterSpacing: -0.6, color: colour),
            ),
            if (car.negotiable && !car.sold) _Tag(text: '🤝 ${s.carNegotiable}', colour: p.accent),
            if (car.sold) _Tag(text: s.carSold, colour: dealColour(context, null, sold: true)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (icon, text) in pills)
              DecoratedBox(
                decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.hairline)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 15, color: p.accent),
                      const SizedBox(width: 6),
                      Text(text, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.ink)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (car.views != null && car.views! > 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 15, color: p.inkMuted),
              const SizedBox(width: 5),
              Text(s.carViews('${car.views}'), style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
            ],
          ),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.colour});

  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: colour.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colour)),
        ),
      );
}

/// The facts were read from the post by a machine: the post decides.
class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 19, color: p.gold),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, height: 1.45, color: p.inkSoft))),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({super.key, required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: p.ink)),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Text(subtitle!, style: TextStyle(fontSize: 13, color: p.inkMuted)),
              ],
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: p.hairline)),
      child: child,
    );
  }
}

/// The post as the seller wrote it: long ones folded, with where it's from.
class _PostText extends StatefulWidget {
  const _PostText({required this.car});

  final Car car;

  @override
  State<_PostText> createState() => _PostTextState();
}

class _PostTextState extends State<_PostText> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final text = widget.car.rawText;
    final style = TextStyle(fontSize: 14.5, height: 1.5, color: text == null ? p.inkMuted : p.ink);
    return _Card(
      child: LayoutBuilder(
        builder: (context, box) {
          final long = text != null &&
              (TextPainter(text: TextSpan(text: text, style: style), maxLines: 8, textDirection: Directionality.of(context))
                    ..layout(maxWidth: box.maxWidth))
                  .didExceedMaxLines;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(text ?? s.carNoText, style: style, maxLines: long && !_open ? 8 : null),
              if (long)
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _open = !_open);
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  child: Text(_open ? s.carReadLess : s.carReadMore),
                ),
              if (widget.car.sourceName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.send_rounded, size: 14, color: p.inkMuted),
                    const SizedBox(width: 6),
                    Expanded(child: Text(s.carSource(widget.car.sourceName!), style: TextStyle(fontSize: 12.5, color: p.inkMuted))),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Whether the price is good: a verdict against cars of about its year (or
/// its whole model), where it sits between the cheapest and the priciest,
/// and what it was compared with.
class _PriceAnalysis extends StatelessWidget {
  const _PriceAnalysis({required this.car, required this.market, required this.thisYear});

  final Car car;
  final ({List<Car> cars, MarketStats stats}) market;
  final int thisYear;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final stats = market.stats;
    final near = nearYears(car, market.cars);
    final base = near?.spread ?? stats.available;
    final median = base.med!;
    final price = car.priceKrw;
    final lo = price == null ? base.lo! : (price < base.lo! ? price : base.lo!);
    final hi = price == null ? base.hi! : (price > base.hi! ? price : base.hi!);
    final diff = price == null || median == 0 ? null : ((price - median) / median * 100).round();

    Widget? verdict;
    if (price != null && !car.sold) {
      if (base.n >= 3 && diff != null) {
        final (deal, label) = diff <= -12
            ? (Deal.low, s.carVeryCheap)
            : diff <= -4
                ? (Deal.low, s.carCheap)
                : diff < 4
                    ? (Deal.mid, s.carAtMarket)
                    : diff < 12
                        ? (Deal.high, s.carPricier)
                        : (Deal.high, s.carExpensive);
        verdict = _Verdict(
          colour: dealColour(context, deal),
          label: label,
          detail: diff.abs() < 4 ? s.carNearAverage : diff < 0 ? s.carBelowAverage('${diff.abs()}') : s.carAboveAverage('${diff.abs()}'),
        );
      } else {
        verdict = _Verdict(colour: dealColour(context, Deal.mid), label: s.carFewDetails, detail: s.carFewComparables('${base.n}'));
      }
    }
    final pinColour = dealColour(context, dealOf(price, median), sold: car.sold);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?verdict,
          if (verdict != null) const SizedBox(height: 18),
          _Scale(lo: lo, hi: hi, median: median, price: price, pinColour: pinColour),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(s.carScaleCheap(wonShort(lo)), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.inkMuted)),
              const Spacer(),
              Text(s.carScaleDear(wonShort(hi)), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.inkMuted)),
            ],
          ),
          Divider(height: 24, color: p.hairline),
          Text(
            near != null
                ? s.carNearYearBasis('${car.year}', '${base.n}', wonShort(median))
                : s.carModelBasis('${stats.countAvailable}', wonShort(median)),
            style: TextStyle(fontSize: 13, color: p.inkSoft),
          ),
          if (stats.sold.n > 0) ...[
            const SizedBox(height: 3),
            Text(s.carSoldBasis('${stats.countSold}', wonShort(stats.sold.med)), style: TextStyle(fontSize: 13, color: p.inkSoft)),
          ],
        ],
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.colour, required this.label, required this.detail});

  final Color colour;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: colour.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: colour, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: colour)),
            const SizedBox(width: 8),
            Expanded(child: Text(detail, style: TextStyle(fontSize: 13, color: VegukinPalette.of(context).inkSoft))),
          ],
        ),
      );
}

/// Cheapest to priciest: the average as a tick, this car as a flag above.
class _Scale extends StatelessWidget {
  const _Scale({required this.lo, required this.hi, required this.median, required this.price, required this.pinColour});

  final int lo;
  final int hi;
  final int median;
  final int? price;
  final Color pinColour;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final span = hi - lo == 0 ? 1 : hi - lo;
    double at(int v) => (((v - lo) / span) * 100).clamp(4, 96) / 100;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return SizedBox(
          height: price == null ? 18 : 46,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 4,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [dealColour(context, Deal.low), dealColour(context, Deal.mid), dealColour(context, Deal.high)],
                      stops: const [0, .55, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: at(median) * w - 2,
                bottom: 0,
                child: Container(width: 4, height: 16, decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(2))),
              ),
              if (price != null)
                Positioned(
                  left: (at(price!) * w - 32).clamp(0.0, w - 64),
                  top: 0,
                  width: 64,
                  child: Column(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(color: pinColour, borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          child: Text(wonShort(price), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ),
                      Container(width: 2, height: 10, color: pinColour),
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

/// The details, two to a row.
class _Specs extends StatelessWidget {
  const _Specs({required this.car});

  final Car car;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final rows = [
      (s.carGeneration, car.generation),
      (s.carYear, car.year?.toString()),
      (s.carMileage, car.mileageKm == null ? null : '${groupDigits(car.mileageKm!)} km'),
      (s.carGearbox, gearboxLabel(s, car.transmission)),
      (s.carFuel, fuelLabel(s, car.fuel)),
      (s.carLegal, switch (car.legalStatus) { 'legal' => s.carLegalOk, 'no_oformleniya' => s.carLegalNoReg, _ => null }),
      (s.carRegistration, car.registrationRequired == null ? null : car.registrationRequired! ? s.carRequired : s.carNotRequired),
      (s.carPosted, car.postedRel ?? car.postedAt),
      (s.carSourceLabel, car.sourceName),
    ];
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i += 2) ...[
            if (i > 0) Divider(height: 1, color: p.hairline),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (key, value) in rows.skip(i).take(2))
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.inkMuted)),
                          const SizedBox(height: 2),
                          Text(
                            value ?? s.carNotGiven,
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: value == null ? p.inkMuted : p.ink),
                          ),
                        ],
                      ),
                    ),
                  if (rows.length - i == 1) const Spacer(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.car, required this.onCall, required this.onTelegram});

  final Car car;
  final ValueChanged<String> onCall;
  final ValueChanged<String> onTelegram;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    Widget row(IconData icon, Color colour, String value, String label, List<Widget> actions) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: colour.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, size: 21, color: colour),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.ink)),
                    Text(label, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        );
    final phone = car.contact;
    final handle = car.contactHandle;
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          if (phone != null)
            row(Icons.call_rounded, p.accent, phone, s.carSellerPhone, [
              IconButton.filledTonal(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await Clipboard.setData(ClipboardData(text: phone));
                  if (context.mounted) showCarsSnack(context, s.carCopied);
                },
                tooltip: s.carCopy,
                icon: const Icon(Icons.copy_rounded, size: 19),
              ),
              const SizedBox(width: 4),
              IconButton.filled(onPressed: () => onCall(phone), tooltip: s.carCall, icon: const Icon(Icons.call_rounded, size: 20)),
            ]),
          if (phone != null && handle != null) Divider(height: 1, color: p.hairline),
          if (handle != null)
            row(Icons.telegram, const Color(0xFF229ED9), '@$handle', s.carWriteOnTelegram, [
              FilledButton(
                onPressed: () => onTelegram(handle),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40), backgroundColor: const Color(0xFF229ED9)),
                child: Text(s.carWrite),
              ),
            ]),
        ],
      ),
    );
  }
}

/// The model's other listings with a price, cheapest first.
class _Similar extends StatelessWidget {
  const _Similar({required this.kit, required this.car, required this.market});

  final CarsKit kit;
  final Car car;
  final ({List<Car> cars, MarketStats stats}) market;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final peers = [for (final c in market.cars) if (c.priceKrw != null && c.id != car.id) c]
      ..sort((a, b) => a.priceKrw!.compareTo(b.priceKrw!));
    if (peers.isEmpty) return Text(s.carNoComparables, style: TextStyle(fontSize: 14, color: p.inkMuted));
    final median = market.stats.available.med;
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: peers.length > 20 ? 20 : peers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = peers[i];
          return SizedBox(
            width: 150,
            child: Material(
              color: p.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.hairline)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => openCar(context, kit, c.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CarPhoto(car: c, width: 320),
                          if (c.sold)
                            Positioned(
                              left: 6,
                              top: 6,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: const Color(0xE6596572), borderRadius: BorderRadius.circular(20)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  child: Text(s.carSold, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(color: dealColour(context, dealOf(c.priceKrw, median), sold: c.sold), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(won(c.priceKrw),
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.ink)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
                      child: Text(
                        '${c.year ?? s.carNotGiven} · ${c.mileageKm == null ? s.carNotGiven : kmShort(c.mileageKm!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: p.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Saved, and the way to reach the seller: a call, Telegram, or the post
/// where the number is written.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.car, required this.kit, required this.onCall, required this.onTelegram, required this.onText});

  final Car car;
  final CarsKit kit;
  final ValueChanged<String> onCall;
  final ValueChanged<String> onTelegram;
  final VoidCallback onText;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final saved = kit.isFavorite(car.id);
    final phone = car.contact;
    final handle = car.contactHandle;
    return DecoratedBox(
      decoration: BoxDecoration(color: p.card, border: Border(top: BorderSide(color: p.hairline))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 54,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    kit.toggleFavorite(car);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: saved ? const Color(0xFFE11D48) : p.hairlineStrong),
                  ),
                  child: Icon(
                    saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    semanticLabel: saved ? s.carUnsave : s.carSave,
                    color: saved ? const Color(0xFFE11D48) : p.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: phone != null
                      ? () => onCall(phone)
                      : handle != null
                          ? () => onTelegram(handle)
                          : onText,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    backgroundColor: handle != null && phone == null ? const Color(0xFF229ED9) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: Icon(phone != null ? Icons.call_rounded : handle != null ? Icons.telegram : Icons.notes_rounded),
                  label: Text(
                    phone != null ? s.carContact : handle != null ? s.carWriteOnTelegram : s.carNumberInText,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
