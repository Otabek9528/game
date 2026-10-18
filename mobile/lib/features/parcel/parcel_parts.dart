import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'parcel_models.dart';

// The parcel pages' shared parts.

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
            const HowSteps(),
          ],
        ),
      ),
    ),
  );
}

void showFailed(BuildContext context) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).parcelError),
      behavior: SnackBarBehavior.floating,
    ));
}

Widget fillRemaining(Widget child) => SliverFillRemaining(hasScrollBody: false, child: child);

String routeName(AppLocalizations s, ParcelDirection d) =>
    d == ParcelDirection.uzbToKor ? s.parcelUzbToKor : s.parcelKorToUzb;

String countryName(AppLocalizations s, ParcelCountry c) => c == ParcelCountry.uzb ? s.parcelUzbekistan : s.parcelKorea;

String capital(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

class Place extends StatelessWidget {
  const Place({super.key, required this.label, required this.country, required this.name, this.end = false});

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

/// A day in the strip: its weekday (or "Bugun"), date and post count.
/// Days already past are faded.
class DayChip extends StatelessWidget {
  const DayChip({
    super.key,
    required this.date,
    required this.selected,
    required this.past,
    required this.language,
    required this.onTap,
  });

  final ParcelDate date;
  final bool selected;
  final bool past;
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
      _ => capital(DateFormat.E(language.code).format(date.date)),
    };
    final ink = selected ? Colors.white : p.ink;
    final soft = selected ? Colors.white70 : p.inkMuted;
    return Opacity(
      opacity: past && !selected ? 0.45 : 1,
      child: Stack(
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
                    capital(DateFormat.MMM(language.code).format(date.date)),
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
    ),
    );
  }
}

class CountryChip extends StatelessWidget {
  const CountryChip({super.key, required this.country, required this.label, required this.selected, required this.onTap});

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

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.onClose,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  /// Shows a close button at the end.
  final VoidCallback? onClose;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search_rounded, color: p.inkMuted),
        suffixIcon: onClose == null
            ? null
            : IconButton(
                onPressed: onClose,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: Icon(Icons.close_rounded, color: p.inkMuted),
              ),
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

class CityList extends StatelessWidget {
  const CityList({super.key, required this.cities, required this.onOpen});

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

class Problem extends StatelessWidget {
  const Problem({super.key, required this.onRetry});

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

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.text,
    this.action,
    this.onAction,
    this.showHow = false,
    this.icon = Icons.inbox_rounded,
  });

  final IconData icon;

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
            child: Icon(icon, size: 36, color: p.accent),
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
                  const HowSteps(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class HowSteps extends StatelessWidget {
  const HowSteps({super.key});

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
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child});

  final Widget child;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
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

class Bone extends StatelessWidget {
  const Bone({super.key, this.width, required this.height, this.radius = 8});

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

class StripSkeleton extends StatelessWidget {
  const StripSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Pulse(
        child: SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            itemCount: 6,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, _) => const Bone(width: 70, height: 84, radius: 16),
          ),
        ),
      );
}

class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Pulse(
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
                Bone(width: 42, height: 42, radius: 21),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Bone(width: 130, height: 13), SizedBox(height: 7), Bone(width: 90, height: 11)],
                ),
              ],
            ),
            SizedBox(height: 16),
            Bone(height: 12),
            SizedBox(height: 8),
            Bone(height: 12),
            SizedBox(height: 8),
            Bone(width: 180, height: 12),
            SizedBox(height: 16),
            Bone(height: 44, radius: 22),
          ],
        ),
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        sliver: SliverToBoxAdapter(
          child: Pulse(
            child: Column(
              children: [
                for (var i = 0; i < 5; i++)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Bone(height: 56, radius: 14),
                  ),
              ],
            ),
          ),
        ),
      );
}

/// "Ehtiyot bo‘ling": the posts come from Telegram groups, the app has
/// nothing to do with the couriers, and isn't responsible for any damage.
/// In full until the user says they understand; then one line that opens.
class NoticeCard extends StatelessWidget {
  const NoticeCard({super.key, required this.seen, required this.open, required this.onOk, required this.onToggle});

  final bool seen;
  final bool open;
  final VoidCallback onOk;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final full = !seen || open;
    return Material(
      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: seen ? onToggle : null,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 11, seen ? 8 : 14, full ? 12 : 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      full ? s.parcelNoticeTitle : s.parcelNoticeShort,
                      maxLines: full ? null : 2,
                      overflow: full ? null : TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: full ? 14.5 : 12.5,
                        height: 1.3,
                        fontWeight: full ? FontWeight.w700 : FontWeight.w600,
                        color: p.ink,
                      ),
                    ),
                  ),
                  if (seen) Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: p.inkMuted),
                ],
              ),
              if (full) ...[
                const SizedBox(height: 6),
                Text(s.parcelNotice, style: TextStyle(fontSize: 13.5, height: 1.45, color: p.inkSoft)),
              ],
              if (!seen) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: onOk,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      minimumSize: const Size(0, 40),
                    ),
                    child: Text(s.parcelNoticeOk),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The notice as a sheet, the first time the user reaches for a courier.
/// True when they said they understand.
Future<bool> showNoticeSheet(BuildContext context) async {
  final s = AppLocalizations.of(context);
  final p = VegukinPalette.of(context);
  final ok = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    backgroundColor: p.card,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 40, color: Color(0xFFD97706)),
            const SizedBox(height: 8),
            Text(
              s.parcelNoticeTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink),
            ),
            const SizedBox(height: 8),
            Text(
              s.parcelNotice,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, height: 1.5, color: p.inkSoft),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: Text(s.parcelNoticeOk),
            ),
          ],
        ),
      ),
    ),
  );
  return ok ?? false;
}

/// A thin amber line: no connection, older posts showing.
class OfflineNote extends StatelessWidget {
  const OfflineNote({super.key});

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.hairline)),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: p.inkMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).parcelOffline,
              style: TextStyle(fontSize: 12.5, color: p.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

/// Under the placeholders after a few seconds: the server is waking.
class WakingNote extends StatelessWidget {
  const WakingNote({super.key});

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: p.accent)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              AppLocalizations.of(context).parcelWaking,
              style: TextStyle(fontSize: 13, color: p.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}
