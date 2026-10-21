import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/system.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'community_screen.dart';
import 'support_data.dart';
import 'support_parts.dart';

/// The web page (pages/donation/) rebuilt: why first, then the account
/// with each detail one tap to copy, and the banking apps on the phone one
/// tap away with the number already copied; what the money is for; thanks.
class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  late final Future<List<InstalledApp>> _apps =
      widget.services.system.installedApps([for (final (_, package) in bankApps) package]);

  /// The main button reads "copied" for a moment after a tap.
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copyAccount() async {
    final s = AppLocalizations.of(context);
    await copyWithNote(context, DonationAccount.number, s.donationCopied);
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _openBank(String package) async {
    final s = AppLocalizations.of(context);
    await copyWithNote(context, DonationAccount.number, s.donationPasteHint);
    await widget.services.system.openApp(package);
  }

  void _share() {
    HapticFeedback.selectionClick();
    final s = AppLocalizations.of(context);
    widget.services.shareText([
      s.donationHeroTitle,
      '',
      '${s.donationBank}: ${DonationAccount.bank}',
      '${s.donationName}: ${DonationAccount.holder}',
      '${s.donationAccount}: ${DonationAccount.number}',
    ].join('\n'));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: p.page,
        body: ListView(
          padding: EdgeInsets.only(bottom: 28 + bottom),
          children: [
            SupportHero(
              title: s.donationTitle,
              mark: const HeroMark(child: Icon(Icons.favorite_rounded, color: Brand.gold300, size: 34)),
              headline: s.donationHeroTitle,
              subtitle: s.donationHeroSubtitle,
              actions: [
                IconButton(
                  onPressed: _share,
                  tooltip: s.donationShare,
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Why, before how.
                  SupportCard(
                    color: p.gold.withValues(alpha: 0.08),
                    edge: p.gold.withValues(alpha: 0.25),
                    child: Text(
                      s.donationMessage,
                      style: TextStyle(fontSize: 14.5, height: 1.55, color: p.inkSoft),
                    ),
                  ),
                  SupportLabel(s.donationTransfer),
                  _AccountCard(copied: _copied, onCopyAccount: _copyAccount),
                  FutureBuilder<List<InstalledApp>>(
                    future: _apps,
                    builder: (context, snapshot) {
                      final apps = snapshot.data ?? const [];
                      if (apps.isEmpty) return const SizedBox.shrink();
                      return _BankApps(apps: apps, onOpen: _openBank);
                    },
                  ),
                  SupportLabel(s.donationUsageTitle),
                  SupportCard(
                    child: Column(
                      children: [
                        for (final (i, (icon, text)) in [
                          (Icons.dns_rounded, s.donationUsage1),
                          (Icons.build_rounded, s.donationUsage2),
                          (Icons.code_rounded, s.donationUsage3),
                        ].indexed) ...[
                          if (i > 0) const SizedBox(height: 12),
                          IconLine(icon: icon, title: text),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Icon(Icons.volunteer_activism_rounded, size: 40, color: p.gold),
                  const SizedBox(height: 8),
                  Text(
                    s.donationThanksText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w600, color: p.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.donationThanks,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: Brand.displayFont, fontSize: 20, fontWeight: FontWeight.w700, color: p.accent),
                  ),
                  const SizedBox(height: 22),
                  Material(
                    color: p.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: p.hairline),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => CommunityScreen(services: widget.services)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: IconLine(
                          icon: Icons.forum_rounded,
                          title: s.donationAsk,
                          body: CommunityGroup.handle,
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
    );
  }
}

/// The bank, the name and the number; each copied with a tap.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.copied, required this.onCopyAccount});

  final bool copied;
  final VoidCallback onCopyAccount;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return SupportCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: const Color(0xFF009A8E), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DonationAccount.bank,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: p.ink),
                ),
              ),
            ],
          ),
          Padding(padding: const EdgeInsets.fromLTRB(0, 12, 8, 6), child: Divider(height: 1, color: p.hairline)),
          _Field(
            label: s.donationName,
            value: DonationAccount.holder,
            copyTooltip: s.donationCopyName,
            onCopy: () => copyWithNote(context, DonationAccount.holder, s.donationCopied),
          ),
          _Field(
            label: s.donationAccount,
            value: DonationAccount.number,
            big: true,
            copyTooltip: s.donationCopyAccount,
            onCopy: onCopyAccount,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: onCopyAccount,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(copied ? Icons.check_rounded : Icons.copy_rounded, key: ValueKey(copied)),
              ),
              label: Text(copied ? s.donationCopied : s.donationCopyAccount),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.copyTooltip,
    required this.onCopy,
    this.big = false,
  });

  final String label;
  final String value;
  final String copyTooltip;
  final VoidCallback onCopy;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: big ? 23 : 16,
                      fontWeight: big ? FontWeight.w800 : FontWeight.w700,
                      letterSpacing: big ? 0.5 : 0.2,
                      color: p.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onCopy,
              tooltip: copyTooltip,
              icon: Icon(Icons.copy_rounded, size: 20, color: p.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// The phone's banking apps: a tap copies the number and opens the app.
class _BankApps extends StatelessWidget {
  const _BankApps({required this.apps, required this.onOpen});

  final List<InstalledApp> apps;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    String name(String package) => bankApps.firstWhere((a) => a.$2 == package, orElse: () => (package, package)).$1;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SupportCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.donationOpenApp, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink)),
            const SizedBox(height: 2),
            Text(s.donationOpenAppHint, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final app in apps)
                  Tooltip(
                    message: name(app.package),
                    child: InkWell(
                      onTap: () => onOpen(app.package),
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 70,
                        child: Column(
                          children: [
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: app.icon == null
                                  ? Container(
                                      width: 48,
                                      height: 48,
                                      color: p.cardSelected,
                                      child: Icon(Icons.account_balance_rounded, color: p.accent),
                                    )
                                  : Image.memory(app.icon!, width: 48, height: 48, gaplessPlayback: true),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              name(app.package),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.inkSoft),
                            ),
                            const SizedBox(height: 2),
                          ],
                        ),
                      ),
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
