import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_update.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';

/// On the home screen, while a new version is on its way: downloading (the
/// app keeps working), then ready, with "Restart". Nothing otherwise: a
/// version not taken is offered by Play's own dialog, and stays on the
/// account page.
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
                    child: _Card(stage: stage, onRestart: updates.restart),
                  )
                : const SizedBox(width: double.infinity),
          );
        },
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.stage, required this.onRestart});

  final UpdateStage stage;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final (title, body) = switch (stage) {
      UpdateStage.ready => (s.updateReady, s.updateReadyBody),
      UpdateStage.installing => (s.updateInstalling, null),
      _ => (s.updateDownloading, s.updateDownloadingBody),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.cardSelected,
        borderRadius: Corner.card,
        border: Border.all(color: p.accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, 14, Space.lg, Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  // Read out when it changes: "downloading", then "ready".
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: p.ink)),
                        if (body != null) ...[
                          const SizedBox(height: 2),
                          Text(body, style: TextStyle(fontSize: 13, height: 1.4, color: p.inkSoft)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (stage == UpdateStage.downloading) ...[
              const SizedBox(height: 14),
              // Play doesn't say how far along: moving, not measured.
              ClipRRect(
                borderRadius: BorderRadius.circular(Corner.pill),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  color: p.accent,
                  backgroundColor: p.accent.withValues(alpha: 0.15),
                ),
              ),
            ],
            if (stage == UpdateStage.ready) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onRestart();
                },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(tapTarget)),
                icon: const Icon(Icons.restart_alt_rounded, size: 20),
                label: Text(s.updateRestart),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
