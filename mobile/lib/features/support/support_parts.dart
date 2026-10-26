import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

/// The emerald top of the donation and community pages: back, the page's
/// name, then a mark, a headline, a line under it, and the page's actions.
class SupportHero extends StatelessWidget {
  const SupportHero({
    super.key,
    required this.title,
    required this.mark,
    required this.headline,
    required this.subtitle,
    this.actions = const [],
    this.below,
    this.inline = false,
  });

  final String title;
  final Widget mark;
  final String headline;
  final String subtitle;
  final List<Widget> actions;

  /// Under the subtitle: the community page's buttons.
  final Widget? below;

  /// The mark beside the words rather than above them: a big mark in a
  /// shorter hero.
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.hero.sublist(1),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
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
                  ...actions,
                  const SizedBox(width: 4),
                ],
              ),
            ),
            if (inline)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                child: Row(
                  children: [
                    mark,
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headline,
                            style: const TextStyle(
                              fontSize: 22,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              color: Colors.white70,
                            ),
                          ),
                          if (below != null) ...[
                            const SizedBox(height: 10),
                            below!,
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 22),
                child: Column(
                  children: [
                    mark,
                    const SizedBox(height: 12),
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Colors.white70,
                      ),
                    ),
                    if (below != null) ...[const SizedBox(height: 16), below!],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A round mark on the hero: a white ring around [child].
class HeroMark extends StatelessWidget {
  const HeroMark({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.14),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.35),
        width: 1.5,
      ),
    ),
    child: Center(child: child),
  );
}

/// A white card with a hairline edge.
class SupportCard extends StatelessWidget {
  const SupportCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.edge,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? edge;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: edge ?? p.hairline),
      ),
      child: child,
    );
  }
}

/// A heading over a group of cards.
class SupportLabel extends StatelessWidget {
  const SupportLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: p.ink,
        ),
      ),
    );
  }
}

/// A row with an icon tile, a bold title and a line under it.
class IconLine extends StatelessWidget {
  const IconLine({
    super.key,
    required this.icon,
    required this.title,
    this.body = '',
    this.tint,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color? tint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final colour = tint ?? p.accent;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colour.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: colour),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 1),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: p.inkSoft,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Copies [text], with a buzz and a short note.
Future<void> copyWithNote(
  BuildContext context,
  String text,
  String note,
) async {
  await Clipboard.setData(ClipboardData(text: text));
  HapticFeedback.mediumImpact();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(note), behavior: SnackBarBehavior.floating),
    );
}
