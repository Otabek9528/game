import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_update.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';

/// On the home screen, while a new version is on its way: "Update ·
/// Downloading…" (the app keeps working), then "Update · New version ready"
/// with Install (the app restarts on it). Nothing otherwise: a version not
/// taken is offered by Play's own dialog, and stays on the account page.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key, required this.updates});

  final UpdateController updates;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: updates,
    builder: (context, _) {
      final stage = updates.stage;
      final shown = stage == UpdateStage.downloading || stage == UpdateStage.ready || stage == UpdateStage.installing;
      return AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: shown
            ? Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _Card(stage: stage, onInstall: updates.restart),
              )
            : const SizedBox(width: double.infinity),
      );
    },
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.stage, required this.onInstall});

  final UpdateStage stage;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final status = switch (stage) {
      UpdateStage.ready => s.updateReady,
      UpdateStage.installing => s.updateInstalling,
      _ => s.updateDownloading,
    };
    final titleStyle = TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: p.ink);
    final statusStyle = TextStyle(fontSize: 13, height: 1.35, color: p.inkSoft);
    final install = stage == UpdateStage.ready
        ? FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              onInstall();
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, tapTarget),
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            ),
            child: Text(s.updateInstall),
          )
        : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.cardSelected,
        borderRadius: Corner.card,
        border: Border.all(color: p.accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.md, Space.md),
        child: LayoutBuilder(
          builder: (context, box) {
            // Install beside the words when both lines fit there on one line
            // each; under them otherwise (Russian, large text).
            var beside = true;
            if (install != null) {
              final scaler = MediaQuery.textScalerOf(context);
              final base = DefaultTextStyle.of(context).style;
              double width(String text, TextStyle style) {
                final painter = TextPainter(
                  text: TextSpan(text: text, style: base.merge(style)),
                  textDirection: Directionality.of(context),
                  textScaler: scaler,
                  maxLines: 1,
                )..layout();
                final w = painter.width;
                painter.dispose();
                return w;
              }

              final label = Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
              final room = box.maxWidth - 40 - Space.md - Space.sm - (width(s.updateInstall, label) + 2 * Space.lg);
              beside = room >= width(s.updateTitle, titleStyle) && room >= width(status, statusStyle);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: p.card, shape: BoxShape.circle),
                      child: stage == UpdateStage.installing
                          ? Padding(
                              padding: const EdgeInsets.all(11),
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: p.accent),
                            )
                          : Icon(
                              stage == UpdateStage.ready ? Icons.system_update_rounded : Icons.downloading_rounded,
                              size: 22,
                              color: p.accent,
                            ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      // Read out when it changes: downloading, then ready.
                      child: Semantics(
                        liveRegion: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.updateTitle, style: titleStyle),
                            Text(status, style: statusStyle),
                          ],
                        ),
                      ),
                    ),
                    if (install != null && beside) ...[const SizedBox(width: Space.sm), install],
                  ],
                ),
                if (install != null && !beside) ...[const SizedBox(height: Space.md), install],
                if (stage == UpdateStage.downloading) ...[
                  const SizedBox(height: Space.md),
                  // Play doesn't say how far along: moving, not measured.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Corner.pill),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      color: p.accent,
                      backgroundColor: p.accent.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
