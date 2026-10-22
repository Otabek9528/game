import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'cars_kit.dart';
import 'cars_models.dart';

/// Below the going price green, about it amber, above it red; sold grey.
Color dealColour(BuildContext context, Deal? deal, {bool sold = false}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (sold) return dark ? const Color(0xFF8B96A3) : const Color(0xFF7C8796);
  return switch (deal) {
    Deal.low => dark ? const Color(0xFF34D27F) : const Color(0xFF16A34A),
    Deal.mid => dark ? const Color(0xFFF0A93A) : const Color(0xFFD97706),
    Deal.high => dark ? const Color(0xFFF96B6B) : const Color(0xFFDC2626),
    null => VegukinPalette.of(context).inkMuted,
  };
}

String? fuelLabel(AppLocalizations s, String? fuel) => switch (fuel) {
      'petrol' => s.carFuelPetrol,
      'diesel' => s.carFuelDiesel,
      'lpg' => s.carFuelLpg,
      'hybrid' => s.carFuelHybrid,
      _ => null,
    };

String? gearboxLabel(AppLocalizations s, String? transmission) => switch (transmission) {
      'automatic' => s.carAutomatic,
      'manual' => s.carManual,
      _ => null,
    };

const carFuels = ['petrol', 'diesel', 'lpg', 'hybrid'];

void showCarsSnack(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

// ------------------------------------------------------------- makes

const _logos = {
  'Hyundai': 'hyundai', 'Kia': 'kia', 'Chevrolet': 'chevrolet', 'Genesis': 'genesis', 'BMW': 'bmw',
  'Audi': 'audi', 'Infiniti': 'infiniti', 'Jaguar': 'jaguar', 'SsangYong': 'ssangyong',
  'Samsung/Renault': 'samsung', 'Mercedes': 'mercedes-benz', 'Volvo': 'volvo', 'Honda': 'honda',
  'Toyota': 'toyota', 'Volkswagen': 'volkswagen', 'Lexus': 'lexus', 'Daewoo': 'daewoo', 'Nissan': 'nissan',
};

const _brandColours = {
  'Hyundai': Color(0xFF0B2C5E), 'Kia': Color(0xFFBB162B), 'Chevrolet': Color(0xFFC9971C), 'Genesis': Color(0xFF1C1C22),
  'Samsung': Color(0xFF1428A0), 'SsangYong': Color(0xFFC8102E), 'Renault': Color(0xFFF5A623), 'Daewoo': Color(0xFF0B5FA5),
  'Toyota': Color(0xFFEB0A1E), 'BMW': Color(0xFF16588E), 'Nissan': Color(0xFFC3002F),
};

/// A make's badge on white, or its first letter on its colour.
class BrandLogo extends StatelessWidget {
  const BrandLogo(this.brand, {super.key, this.size = 40});

  final String brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logo = _logos[brand];
    final radius = BorderRadius.circular(size * 0.3);
    final letter = Text(
      brand.trim().isEmpty ? '?' : brand.trim()[0].toUpperCase(),
      style: TextStyle(fontSize: size * 0.45, fontWeight: FontWeight.w900, color: Colors.white),
    );
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: logo == null ? _brandColours[brand] ?? const Color(0xFF41506A) : Colors.white,
        borderRadius: radius,
        border: logo == null ? null : Border.all(color: const Color(0x14000000)),
      ),
      child: logo == null
          ? letter
          : Padding(
              padding: EdgeInsets.all(size * 0.14),
              child: Image.asset('assets/cars/$logo.png', fit: BoxFit.contain, errorBuilder: (_, _, _) => letter),
            ),
    );
  }
}

// ------------------------------------------------------------- photos

/// A car's picture: its photo over a colour of its own (with a car drawn
/// on it) while it loads or when there is none; grey when sold.
class CarPhoto extends StatelessWidget {
  const CarPhoto({super.key, required this.car, this.width = 400});

  final Car car;

  /// How wide it is decoded, in pixels.
  final int width;

  @override
  Widget build(BuildContext context) {
    final url = car.thumb ?? car.photo;
    final placeholder = CarPlaceholder(id: car.id);
    final image = url == null
        ? placeholder
        : Image.network(
            '$url',
            fit: BoxFit.cover,
            cacheWidth: width,
            gaplessPlayback: true,
            frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : placeholder,
            errorBuilder: (_, _, _) => car.photo != null && car.photo != url
                ? Image.network('${car.photo}', fit: BoxFit.cover, cacheWidth: width, errorBuilder: (_, _, _) => placeholder)
                : placeholder,
          );
    if (!car.sold) return image;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.33, 0.59, 0.08, 0, 0, //
        0.33, 0.59, 0.08, 0, 0,
        0.33, 0.59, 0.08, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: image,
    );
  }
}

/// A listing without a photo: a colour of its own, a car on it.
class CarPlaceholder extends StatelessWidget {
  const CarPlaceholder({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    final hue = (id * 47) % 360.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, hue, 0.42, 0.62).toColor(),
            HSLColor.fromAHSL(1, (hue + 30) % 360, 0.46, 0.40).toColor(),
          ],
        ),
      ),
      child: const Center(child: Icon(Icons.directions_car_filled_rounded, size: 42, color: Color(0x66FFFFFF))),
    );
  }
}

// ------------------------------------------------------------- the card

/// A listing in a list: its photo (status, a good price, the heart over
/// it), then its price coloured by how it sits against the model's going
/// price, year and generation, mileage, gearbox, fuel, and when.
class CarCard extends StatelessWidget {
  const CarCard({super.key, required this.kit, required this.car, required this.onTap, this.showModel = false});

  final CarsKit kit;
  final Car car;
  final VoidCallback onTap;

  /// Its make and model on top: a list of many models.
  final bool showModel;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final median = kit.medianOf(car);
    final price = car.priceKrw;
    final deal = car.sold ? null : dealOf(price, median);
    final cheap = !car.sold && price != null && median != null && price < median * 0.9;
    final seen = kit.seen(car.id);
    final saved = kit.isFavorite(car.id);
    final specs = [
      if (car.mileageKm != null) kmShort(car.mileageKm!),
      ?gearboxLabel(s, car.transmission),
      ?fuelLabel(s, car.fuel),
    ];
    final yearGen = [if (car.year != null) '${car.year}', ?car.generation].join(' · ');
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: p.hairline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox(
          height: 138,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 128,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CarPhoto(car: car, width: 300),
                    Positioned(left: 7, top: 7, child: _StatusBadge(sold: car.sold)),
                    if (cheap)
                      Positioned(
                        left: 7,
                        bottom: 7,
                        child: _Pill(text: '🔥 ${s.carDeal}', background: const Color(0xFFFF6A2B), ink: Colors.white),
                      ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: HeartButton(
                        saved: saved,
                        onTap: () => kit.toggleFavorite(car),
                        tooltip: saved ? s.carUnsave : s.carSave,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 11, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showModel)
                        Text(
                          car.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.inkSoft),
                        ),
                      Row(
                        children: [
                          if (deal != null) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: dealColour(context, deal), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              price == null ? s.carNoPrice : won(price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: price == null ? 14 : 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: price == null ? p.inkMuted : car.sold ? dealColour(context, null, sold: true) : p.ink,
                                decoration: car.sold ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              yearGen.isEmpty ? s.carFewDetails : yearGen,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.ink),
                            ),
                          ),
                          if (car.negotiable && !car.sold) ...[
                            const SizedBox(width: 6),
                            _Pill(text: s.carNegotiable, background: p.cardSelected, ink: p.accent),
                          ],
                        ],
                      ),
                      const Spacer(),
                      if (specs.isNotEmpty)
                        Text(
                          specs.join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: p.inkSoft),
                        ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 13, color: p.inkMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              car.postedRel ?? car.postedAt ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: p.inkMuted),
                            ),
                          ),
                          if (seen) ...[
                            Icon(Icons.visibility_outlined, size: 13, color: p.inkMuted),
                            const SizedBox(width: 3),
                            Text(s.carSeen, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.inkMuted)),
                          ],
                        ],
                      ),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.sold});

  final bool sold;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return _Pill(
      text: sold ? s.carSold : s.carAvailable,
      background: sold ? const Color(0xE6596572) : const Color(0xE616A34A),
      ink: Colors.white,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.background, required this.ink});

  final String text;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: ink)),
        ),
      );
}

/// Saves a listing (red when saved), on a white disc over a photo.
class HeartButton extends StatelessWidget {
  const HeartButton({super.key, required this.saved, required this.onTap, required this.tooltip, this.size = 34});

  final bool saved;
  final VoidCallback onTap;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xE6FFFFFF),
          fixedSize: Size.square(size),
          minimumSize: Size.square(size),
          padding: EdgeInsets.zero,
        ),
        icon: Icon(
          saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: size * 0.55,
          color: saved ? const Color(0xFFE11D48) : const Color(0xFF44403C),
        ),
      );
}

// ------------------------------------------------------------- browse

/// A model's market at a glance: the going price, and the usual range on a
/// green-to-red bar with the average on it (how many, the bar above says).
class MarketSummary extends StatelessWidget {
  const MarketSummary({super.key, required this.stats});

  final MarketStats stats;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final av = stats.available;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.hairline)),
      child: av.n == 0
          ? Row(
              children: [
                Expanded(child: Text(s.carNoneOnSale, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.ink))),
                Text(s.carSoldCount('${stats.countSold}'), style: TextStyle(fontSize: 12.5, color: p.inkSoft)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.carMedianPrice, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.inkMuted)),
                Text(won(av.med), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: p.ink)),
                const SizedBox(height: 14),
                _RangeBar(lo: av.lo!, hi: av.hi!, marks: [(value: av.med!, label: null)]),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('${wonShort(av.lo)} ₩', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.inkMuted)),
                    const Spacer(),
                    Text('${wonShort(av.hi)} ₩', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.inkMuted)),
                  ],
                ),
              ],
            ),
    );
  }
}

/// Prices from [lo] to [hi] as a green-to-red bar, a ring at each mark.
class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.lo, required this.hi, required this.marks});

  final int lo;
  final int hi;
  final List<({int value, String? label})> marks;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final span = (hi - lo) == 0 ? 1 : hi - lo;
    return LayoutBuilder(
      builder: (context, box) => SizedBox(
        height: 16,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 5,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(colors: [
                    dealColour(context, Deal.low),
                    dealColour(context, Deal.mid),
                    dealColour(context, Deal.high),
                  ], stops: const [0, .55, 1]),
                ),
              ),
            ),
            for (final m in marks)
              Positioned(
                left: (((m.value - lo) / span).clamp(0.0, 1.0)) * box.maxWidth - 8,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: p.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.accent, width: 3),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The channel every new listing appears in first.
class ChannelCard extends StatelessWidget {
  const ChannelCard({super.key, required this.onTap});

  final VoidCallback onTap;

  static final url = Uri.parse('https://t.me/vegukin_car');

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    const blue = Color(0xFF229ED9);
    return Material(
      color: blue.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.09),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: blue, shape: BoxShape.circle),
                child: const Icon(Icons.telegram, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.carChannelTitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: VegukinPalette.of(context).ink)),
                    const SizedBox(height: 2),
                    Text(s.carChannelBody, style: TextStyle(fontSize: 12.5, height: 1.3, color: VegukinPalette.of(context).inkSoft)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DecoratedBox(
                decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text(s.carOpen, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A chip that is on or off.
class CarChip extends StatelessWidget {
  const CarChip({super.key, required this.label, required this.on, required this.onTap, this.onColour});

  final String label;
  final bool on;
  final VoidCallback onTap;

  /// Its colour when on (else the page's ink).
  final Color? onColour;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final fill = onColour ?? p.ink;
    return Material(
      color: on ? fill : p.card,
      shape: StadiumBorder(side: BorderSide(color: on ? fill : p.hairlineStrong)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: on ? p.page : p.inkSoft),
          ),
        ),
      ),
    );
  }
}

/// All / for sale / sold, as one control.
class StatusSwitch extends StatelessWidget {
  const StatusSwitch({super.key, required this.value, required this.onChanged});

  /// active, sold; null for all.
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final options = [(null, s.carAll), ('active', s.carAvailable), ('sold', s.carSold)];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.badge, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (final (key, label) in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == key ? p.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: value == key ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1))] : null,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: value != key
                          ? p.inkMuted
                          : key == 'active'
                              ? dealColour(context, Deal.low)
                              : key == 'sold'
                                  ? dealColour(context, null, sold: true)
                                  : p.ink,
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

/// Nothing to show, or something went wrong: a sign, a title, a line, and
/// what to do.
class CarsMessage extends StatelessWidget {
  const CarsMessage({super.key, required this.emoji, required this.title, this.body, this.action, this.onAction});

  final String emoji;
  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink)),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(body!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.4, color: p.inkSoft)),
          ],
          if (action != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onAction,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              child: Text(action!),
            ),
          ],
        ],
      ),
    );
  }
}

/// A tab's top: its title (or the make picker), a line under it.
class CarsTabBar extends StatelessWidget {
  const CarsTabBar({super.key, required this.title, this.subtitle, this.leading, this.onTap, this.trailing});

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


/// A field's name above it.
class CarFieldLabel extends StatelessWidget {
  const CarFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VegukinPalette.of(context).inkSoft)),
      );
}

/// A number typed in: "7 000 000" as it's typed when [grouped].
class CarNumberField extends StatelessWidget {
  const CarNumberField({super.key, required this.label, required this.controller, required this.hint, required this.onChanged, this.grouped = false, this.maxLength});

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
        CarFieldLabel(label),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
            if (grouped) const GroupedDigits(),
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

class GroupedDigits extends TextInputFormatter {
  const GroupedDigits();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final text = digits.isEmpty ? '' : groupDigits(digits);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}


/// The make and model chosen (its badge and name), or [empty]; a tap
/// changes it.
class CarPickField extends StatelessWidget {
  const CarPickField({super.key, required this.pick, required this.empty, required this.onTap});

  final CarPick? pick;
  final String empty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final pick = this.pick;
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: pick == null ? p.hairlineStrong : p.accent, width: pick == null ? 1 : 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
                  pick == null ? empty : pick.model == null ? s.carAllOf(pick.brand) : '${pick.brand} ${pick.model}',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: pick == null ? p.inkSoft : p.ink),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// What signing in brings, and the button: alerts and posts need a name.
class SignInCard extends StatelessWidget {
  const SignInCard({super.key, required this.icon, required this.title, required this.body, required this.action, required this.onAction});

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.hairline)),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, size: 32, color: p.accent),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.ink)),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft)),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.login_rounded), label: Text(action)),
        ],
      ),
    );
  }
}
