import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets/brand_logos.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import 'support_data.dart';

/// Muslim Vegukin on its other platforms: the Telegram bot (and the web app
/// inside it), the WhatsApp bot and the Telegram group, each a tap away, and
/// all of them shared in one message. Opened from the home screen's emblem
/// and from the account page.
Future<void> showPlatforms(BuildContext context, AppServices services) {
  HapticFeedback.lightImpact();
  services.activity.log('platforms');
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Clear of the status bar and the notch when it grows tall.
    useSafeArea: true,
    backgroundColor: VegukinPalette.of(context).page,
    clipBehavior: Clip.antiAlias,
    builder: (_) => PlatformsSheet(services: services),
  );
}

class PlatformsSheet extends StatelessWidget {
  const PlatformsSheet({super.key, required this.services});

  final AppServices services;

  void _open(String what, String url) {
    HapticFeedback.selectionClick();
    services.activity.log('platforms', what);
    unawaited(services.openLink(Uri.parse(url)));
  }

  void _share(AppLocalizations s) {
    services.activity.log('platforms', 'share');
    unawaited(
      services.shareText(
        s.platformsShareText(
          AppConfig.playStoreUrl,
          OtherPlatforms.botUrl,
          OtherPlatforms.whatsAppUrl,
          CommunityGroup.url,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottom + Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Hero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlatformTile(
                  logo: BrandLogo.telegram,
                  tint: const Color(0xFF26A5E4),
                  title: s.platformsBot,
                  handle: OtherPlatforms.botHandle,
                  body: s.platformsBotBody,
                  onTap: () => _open('telegram_bot', OtherPlatforms.botUrl),
                ),
                const SizedBox(height: Space.md),
                PlatformTile(
                  logo: BrandLogo.whatsapp,
                  tint: const Color(0xFF25D366),
                  title: s.platformsWhatsApp,
                  handle: OtherPlatforms.whatsAppNumber,
                  body: s.platformsWhatsAppBody,
                  onTap: () => _open('whatsapp_bot', OtherPlatforms.whatsAppUrl),
                ),
                const SizedBox(height: Space.md),
                PlatformTile(
                  logo: BrandLogo.telegram,
                  tint: const Color(0xFF26A5E4),
                  title: s.platformsGroup,
                  handle: CommunityGroup.handle,
                  body: s.platformsGroupBody,
                  onTap: () => _open('group', CommunityGroup.url),
                ),
                const SizedBox(height: Space.xl),
                OutlinedButton.icon(
                  onPressed: () => _share(s),
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  label: Text(s.platformsShare),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: p.accent,
                    side: BorderSide(color: p.accent.withValues(alpha: 0.45)),
                    shape: const RoundedRectangleBorder(borderRadius: Corner.button),
                    // From the theme: a bare TextStyle would drop the app's font.
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: TextSize.label,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The emerald top: the emblem, the name, what this is, and where one is now.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.hero.sublist(1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.xxl, Space.md, Space.xxl, Space.xxl),
        child: Column(
          children: [
            // The sheet's handle, light on the emerald.
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Space.xl),
            const KhatamMark(size: 68),
            const SizedBox(height: Space.lg),
            Text(
              s.platformsTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: Brand.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: TextSize.display,
                height: 1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(
              s.platformsIntro,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.45, color: Colors.white.withValues(alpha: 0.88)),
            ),
            const SizedBox(height: Space.lg),
            // Where one is now: the app itself, among the ways in.
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(Corner.pill),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: Brand.gold300),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        s.platformsYouAreHere,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
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

/// One platform: its mark on a tint of its colour, its name and address,
/// what it offers, and the arrow that says it opens outside the app.
class PlatformTile extends StatelessWidget {
  const PlatformTile({
    super.key,
    required this.logo,
    required this.tint,
    required this.title,
    required this.handle,
    required this.body,
    required this.onTap,
  });

  final BrandLogo logo;
  final Color tint;
  final String title;
  final String handle;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(borderRadius: Corner.card, side: BorderSide(color: p.hairline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.md, Space.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: Corner.chip),
                child: BrandLogoMark(logo, size: 28),
              ),
              const SizedBox(width: Space.md + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: TextSize.label, fontWeight: FontWeight.w800, color: p.ink)),
                    const SizedBox(height: 1),
                    Text(
                      handle,
                      style: TextStyle(fontSize: TextSize.small, fontWeight: FontWeight.w600, color: p.accent),
                    ),
                    const SizedBox(height: Space.xs + 2),
                    Text(body, style: TextStyle(fontSize: 13, height: 1.4, color: p.inkSoft)),
                  ],
                ),
              ),
              const SizedBox(width: Space.sm),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.north_east_rounded, size: 20, color: p.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
