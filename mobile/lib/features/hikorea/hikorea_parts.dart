import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'hikorea_models.dart';

/// A white card with a hairline edge; tappable when [onTap] is given.
class HkCard extends StatelessWidget {
  const HkCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.edge,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? edge;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Material(
      color: color ?? p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: edge ?? p.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// A small rounded square with an emoji or a short code in it.
class HkBadge extends StatelessWidget {
  const HkBadge(this.text, {super.key, this.size = 42, this.emoji = true});

  final String text;
  final double size;
  final bool emoji;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Text(
        text,
        style: emoji
            ? TextStyle(fontSize: size * 0.48)
            : TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: p.accent),
      ),
    );
  }
}

/// A heading over a list; [trailing] a count, or [action] a link.
class HkHeading extends StatelessWidget {
  const HkHeading(this.text, {super.key, this.trailing, this.action, this.onAction});

  final String text;
  final String? trailing;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(4, 18, 4, action == null ? 10 : 4),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink)),
          ),
          if (trailing case final trailing?)
            Text(trailing, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.inkMuted)),
          if (action case final action?)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: Text(action),
            ),
        ],
      ),
    );
  }
}

/// The colours of a state: green for open, amber for filling, red for
/// nearly gone, grey for none.
enum HkTone { open, filling, low, none }

({Color background, Color ink}) hkTone(BuildContext context, HkTone tone) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final p = VegukinPalette.of(context);
  return switch (tone) {
    HkTone.open => dark
        ? (background: const Color(0x3310B981), ink: Brand.emerald400)
        : (background: const Color(0xFFD1FAE5), ink: Brand.emerald800),
    HkTone.filling => dark
        ? (background: const Color(0x33F59E0B), ink: const Color(0xFFFCD34D))
        : (background: const Color(0xFFFEF3C7), ink: const Color(0xFF92400E)),
    HkTone.low => dark
        ? (background: const Color(0x33EF4444), ink: const Color(0xFFFCA5A5))
        : (background: const Color(0xFFFEE2E2), ink: const Color(0xFFB91C1C)),
    HkTone.none => (background: p.badge, ink: p.inkMuted),
  };
}

/// A calendar day's fill: saturated, so the month reads at a glance.
({Color background, Color ink}) hkDayColours(BuildContext context, HkTier tier) {
  final p = VegukinPalette.of(context);
  return switch (tier) {
    HkTier.open => (background: const Color(0xFF6EE7B7), ink: const Color(0xFF064E3B)),
    HkTier.some => (background: const Color(0xFFFCD34D), ink: const Color(0xFF78350F)),
    HkTier.full => (background: const Color(0xFFFCA5A5), ink: const Color(0xFF7F1D1D)),
    HkTier.closed => (background: p.badge, ink: p.inkMuted),
    HkTier.later => (background: Colors.transparent, ink: p.inkMuted),
  };
}

/// A short coloured label.
class HkPill extends StatelessWidget {
  const HkPill(this.text, {super.key, required this.tone, this.icon});

  final String text;
  final HkTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colours = hkTone(context, tone);
    return DecoratedBox(
      decoration: BoxDecoration(color: colours.background, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: colours.ink), const SizedBox(width: 4)],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colours.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Checked 5 min ago", from when the server last looked at HiKorea.
String checkedAgo(AppLocalizations s, DateTime at, DateTime now) {
  final gap = now.difference(at);
  if (gap.inMinutes < 1) return s.hkCheckedNow;
  if (gap.inHours < 1) return s.hkCheckedMinutes(gap.inMinutes);
  if (gap.inDays < 1) return s.hkCheckedHours(gap.inHours);
  return s.hkCheckedDays(gap.inDays);
}

/// A watch's state, as a pill.
class HkStatus extends StatelessWidget {
  const HkStatus(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final (text, tone) = switch (status) {
      'active' => (s.hkStatusActive, HkTone.open),
      'undeliverable' => (s.hkStatusUndeliverable, HkTone.low),
      'cancelled' => (s.hkStatusCancelled, HkTone.none),
      _ => (s.hkStatusExpired, HkTone.none),
    };
    return HkPill(text, tone: tone);
  }
}
