import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// What a page says instead of its content: nothing here yet, nothing found,
/// couldn't load. A picture, a line that says what happened, a line that says
/// what to do, and the button that does it. One look for all sections.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    this.icon,
    this.emoji,
    required this.title,
    this.body,
    this.action,
    this.actionLabel,
    this.onAction,
  }) : assert(icon != null || emoji != null, 'a picture: an icon or an emoji'),
       assert(action == null || actionLabel == null, 'one button: a widget or a label');

  /// In a soft disc.
  final IconData? icon;

  /// Instead of the icon, for sections that speak in emoji.
  final String? emoji;

  final String title;
  final String? body;

  /// The button, built by the page (with its own icon, say).
  final Widget? action;

  /// Or its label and what it does: a plain tonal button.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: Space.section),
      child: Column(
        children: [
          if (icon case final icon?)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: p.cardSelected, shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: p.inkMuted),
            )
          else
            SizedBox(
              height: 64,
              child: Center(child: Text(emoji!, textScaler: TextScaler.noScaling, style: const TextStyle(fontSize: 44))),
            ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink),
          ),
          if (body case final body?) ...[
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft)),
          ],
          if (action case final action?) ...[const SizedBox(height: Space.lg), action],
          if (actionLabel case final label?) ...[
            const SizedBox(height: Space.lg),
            FilledButton.tonal(
              onPressed: onAction,
              style: FilledButton.styleFrom(minimumSize: const Size(0, tapTarget)),
              child: Text(label),
            ),
          ],
        ],
      ),
    );
  }
}
