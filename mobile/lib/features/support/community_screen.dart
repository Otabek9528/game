import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import 'donation_screen.dart';
import 'support_data.dart';
import 'support_parts.dart';

/// The web page (pages/community/) rebuilt: the group first with one join
/// button that stays in reach; what to post, where reporting a place or a
/// bug hands over a ready template (the bug one with the phone and app
/// version filled in); the rules, compact.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key, required this.services});

  final AppServices services;

  void _join() {
    HapticFeedback.lightImpact();
    services.openLink(Uri.parse(CommunityGroup.url));
  }

  Future<void> _template(BuildContext context, {required String title, required bool bug}) async {
    final s = AppLocalizations.of(context);
    var text = s.communityTemplatePlace;
    if (bug) {
      final device = await services.system.device();
      text = s.communityTemplateBug(
        device == null ? 'Android' : '${device.phone} · Android ${device.android}',
        device?.version ?? '—',
      );
    }
    if (!context.mounted) return;
    final go = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: VegukinPalette.of(context).card,
      builder: (context) => _TemplateSheet(title: title, text: text),
    );
    if (go != true || !context.mounted) return;
    await copyWithNote(context, text, s.communityTemplateCopied);
    await services.openLink(Uri.parse(CommunityGroup.url));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final banned = [
      (s.communityBanned1Title, s.communityBanned1Body),
      (s.communityBanned2Title, s.communityBanned2Body),
      (s.communityBanned3Title, s.communityBanned3Body),
      (s.communityBanned4Title, s.communityBanned4Body),
      (s.communityBanned5Title, s.communityBanned5Body),
    ];
    const danger = Color(0xFFDC5B2E);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.page,
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  SupportHero(
                    title: s.communityTitle,
                    mark: const HeroMark(child: KhatamMark(size: 40, glow: false)),
                    headline: CommunityGroup.name,
                    subtitle: '${CommunityGroup.handle}  ·  ${s.communityHeroSubtitle}',
                    actions: [
                      IconButton(
                        onPressed: () => copyWithNote(context, CommunityGroup.url, s.communityLinkCopied),
                        tooltip: s.communityCopyLink,
                        icon: const Icon(Icons.copy_rounded, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () => services.shareText('${CommunityGroup.name}: ${s.communityHeroSubtitle}\n${CommunityGroup.url}'),
                        tooltip: s.communityShare,
                        icon: const Icon(Icons.share_rounded, color: Colors.white),
                      ),
                    ],
                    below: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 16, color: Brand.gold300),
                          const SizedBox(width: 6),
                          Text(
                            s.communityHeroTitle,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SupportCard(
                          child: IconLine(
                            icon: Icons.flag_rounded,
                            title: s.communityPurposeTitle,
                            body: s.communityPurposeText,
                          ),
                        ),
                        SupportLabel(s.communityAllowedTitle),
                        // What a member comes to do: two hand over templates.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Action(
                                icon: Icons.add_location_alt_rounded,
                                title: s.communityTopicPlaceTitle,
                                body: s.communityTopicPlaceBody,
                                template: true,
                                onTap: () => _template(context, title: s.communityTopicPlaceTitle, bug: false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Action(
                                icon: Icons.bug_report_rounded,
                                title: s.communityTopicBugTitle,
                                body: s.communityTopicBugBody,
                                template: true,
                                tint: danger,
                                onTap: () => _template(context, title: s.communityTopicBugTitle, bug: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Action(
                                icon: Icons.lightbulb_rounded,
                                title: s.communityTopicIdeaTitle,
                                body: s.communityTopicIdeaBody,
                                tint: Brand.gold500,
                                onTap: _join,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Action(
                                icon: Icons.help_rounded,
                                title: s.communityTopicQuestionTitle,
                                body: s.communityTopicQuestionBody,
                                tint: const Color(0xFF2563EB),
                                onTap: _join,
                              ),
                            ),
                          ],
                        ),
                        SupportLabel(s.communityMore),
                        SupportCard(
                          child: Column(
                            children: [
                              for (final (i, (icon, title, body)) in [
                                (Icons.campaign_rounded, s.communityTopicNewsTitle, s.communityTopicNewsBody),
                                (Icons.science_rounded, s.communityTopicBetaTitle, s.communityTopicBetaBody),
                                (Icons.forum_rounded, s.communityTopicPeopleTitle, s.communityTopicPeopleBody),
                              ].indexed) ...[
                                if (i > 0) const SizedBox(height: 14),
                                IconLine(icon: icon, title: title, body: body),
                              ],
                            ],
                          ),
                        ),
                        SupportLabel(s.communityRulesTitle),
                        SupportCard(
                          color: danger.withValues(alpha: 0.06),
                          edge: danger.withValues(alpha: 0.25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.communityRulesWarning,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: danger),
                              ),
                              const SizedBox(height: 10),
                              for (final (title, body) in banned)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 1),
                                        child: Icon(Icons.block_rounded, size: 18, color: danger),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(children: [
                                            TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                            TextSpan(text: '  ·  $body', style: TextStyle(color: p.inkSoft)),
                                          ]),
                                          style: TextStyle(fontSize: 13.5, height: 1.4, color: p.ink),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14)),
                                child: IconLine(
                                  icon: Icons.lock_rounded,
                                  title: s.communityPenaltyTitle,
                                  body: s.communityPenaltyText,
                                  tint: danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Material(
                          color: p.gold.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: p.gold.withValues(alpha: 0.25)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => DonationScreen(services: services)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: IconLine(
                                icon: Icons.favorite_rounded,
                                title: s.donationHeroTitle,
                                body: s.donationHeroSubtitle,
                                tint: p.gold,
                                trailing: Icon(Icons.chevron_right_rounded, color: p.inkMuted),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Join, always in reach.
            Container(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
              decoration: BoxDecoration(
                color: p.card,
                border: Border(top: BorderSide(color: p.hairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.communityCta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, height: 1.35, color: p.inkSoft),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _join,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(s.communityJoinNow),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Something to post in the group; [template] ones hand over a template.
class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.template = false,
    this.tint,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  final bool template;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final colour = tint ?? p.accent;
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: p.hairline)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: colour.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
                    child: Icon(icon, size: 22, color: colour),
                  ),
                  const Spacer(),
                  Icon(template ? Icons.edit_note_rounded : Icons.north_east_rounded, size: 20, color: p.inkMuted),
                ],
              ),
              const SizedBox(height: 10),
              Text(title, style: TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w700, color: p.ink)),
              const SizedBox(height: 3),
              Text(
                body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, height: 1.35, color: p.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The template to post: what it looks like, and one button to copy it and
/// open the group.
class _TemplateSheet extends StatelessWidget {
  const _TemplateSheet({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.ink)),
            const SizedBox(height: 4),
            Text(s.communityTemplateHint, style: TextStyle(fontSize: 13.5, height: 1.4, color: p.inkSoft)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.page,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.hairline),
              ),
              child: Text(text, style: TextStyle(fontSize: 14, height: 1.55, color: p.ink)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(s.communityTemplateGo),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}
