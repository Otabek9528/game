import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'business_data.dart';
import 'business_library.dart';
import 'business_logo.dart';
import 'business_models.dart';

/// What every page of the directory shares: the services, the saved
/// businesses, the logos fetched so far, and the directory last loaded.
class BizKit {
  BizKit(this.services)
      : library = BusinessLibrary(services.store),
        logos = LogoCache(services.businesses);

  final AppServices services;
  final BusinessLibrary library;
  final LogoCache logos;
  BizDirectory? directory;

  AppLanguage get language => services.locale.language ?? AppLanguage.uz;
}

/// A business in a list: its logo (with a medal for the top three), name,
/// the start of its description, and its likes.
class BizRow extends StatelessWidget {
  const BizRow({super.key, required this.kit, required this.business, required this.onTap, this.rank, this.showCategory = false});

  final BizKit kit;
  final Business business;
  final VoidCallback onTap;
  final int? rank;
  final bool showCategory;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final preview = business.preview;
    final category = showCategory ? business.categoryName : null;
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: rank == 1 ? const Color(0xFFE8BC3C).withValues(alpha: 0.7) : p.hairline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          child: Row(
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    BizLogo(business: business, logos: kit.logos, size: 56),
                    if (rank case final rank?) Positioned(right: -4, bottom: -4, child: Medal(rank)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: p.ink),
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, height: 1.35, color: p.inkSoft),
                      ),
                    ],
                    if (category != null || business.likes > 0) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (category != null)
                            Flexible(
                              child: Text(
                                category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.accent),
                              ),
                            ),
                          if (category != null && business.likes > 0) const SizedBox(width: 10),
                          if (business.likes > 0) ...[
                            Icon(Icons.favorite_rounded, size: 14, color: rank == null ? p.inkMuted : const Color(0xFFE25563)),
                            const SizedBox(width: 3),
                            Text(
                              '${business.likes}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.inkMuted),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
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

/// Gold, silver or bronze, with the place on it.
class Medal extends StatelessWidget {
  const Medal(this.place, {super.key});

  final int place;

  @override
  Widget build(BuildContext context) {
    final (size, colors, ink) = switch (place) {
      1 => (25.0, const [Color(0xFFFBE08A), Color(0xFFE8BC3C), Color(0xFFB8871A)], const Color(0xFF4A3400)),
      2 => (22.0, const [Color(0xFFF4F6F8), Color(0xFFCBD1D9), Color(0xFF98A0AA)], const Color(0xFF39404A)),
      _ => (20.0, const [Color(0xFFEEC39C), Color(0xFFC8834A), Color(0xFF96602F)], Colors.white),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        border: Border.all(color: VegukinPalette.of(context).card, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Text('$place', style: TextStyle(fontSize: size * 0.46, fontWeight: FontWeight.w900, color: ink)),
    );
  }
}

/// The one owner-facing element in the public views: last, and quiet.
class OwnerCard extends StatelessWidget {
  const OwnerCard({super.key, required this.kit, this.emptyCategory = false});

  final BizKit kit;
  final bool emptyCategory;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Material(
      color: p.gold.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.gold.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => showOwnerSheet(context, kit),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: p.gold.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(13)),
                child: Icon(Icons.storefront_rounded, color: p.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.bizOwnerTitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink)),
                    const SizedBox(height: 2),
                    Text(
                      emptyCategory ? s.bizOwnerBodyEmpty : s.bizOwnerBody,
                      style: TextStyle(fontSize: 13, height: 1.35, color: p.inkSoft),
                    ),
                  ],
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

/// How a business gets listed, step by step, and who to write to. Sending
/// the listing itself needs a Telegram account, so the admin takes it.
Future<void> showOwnerSheet(BuildContext context, BizKit kit) {
  HapticFeedback.selectionClick();
  final s = AppLocalizations.of(context);
  final p = VegukinPalette.of(context);
  final fee = NumberFormat.decimalPattern('en_US').format(kit.directory?.listingFee ?? 10000);
  Widget step(String n, String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Text(n, style: TextStyle(fontWeight: FontWeight.w800, color: p.accent)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink)),
                  const SizedBox(height: 2),
                  Text(body, style: TextStyle(fontSize: 13.5, height: 1.4, color: p.inkSoft)),
                ],
              ),
            ),
          ],
        ),
      );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: p.card,
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 0, 22, 22 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.bizOwnerEyebrow.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: p.gold),
          ),
          const SizedBox(height: 4),
          Text(s.bizOwnerSheetTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.ink)),
          const SizedBox(height: 18),
          step('1', s.bizStep1Title, s.bizStep1Body),
          step('2', s.bizStep2Title, s.bizStep2Body(s.bizCurrency(fee))),
          step('3', s.bizStep3Title, s.bizStep3Body),
          Text(s.bizOwnerFine, style: TextStyle(fontSize: 12.5, height: 1.45, color: p.inkMuted)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.telegram, size: 20, color: linkLook('telegram').$2),
                const SizedBox(width: 10),
                Expanded(child: Text(s.bizOwnerHow, style: TextStyle(fontSize: 13, height: 1.4, color: p.inkSoft))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => kit.services.openLink(bizAdmin),
            icon: const Icon(Icons.send_rounded),
            label: Text(s.bizOwnerContact),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    ),
  );
}

/// Every category, to switch to; the current one marked.
Future<BizCategory?> pickCategory(BuildContext context, BizKit kit, {String? current}) {
  final s = AppLocalizations.of(context);
  final p = VegukinPalette.of(context);
  final categories = kit.directory?.categories ?? const <BizCategory>[];
  return showModalBottomSheet<BizCategory>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: p.card,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(12, 0, 12, 16 + MediaQuery.paddingOf(context).bottom),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Text(s.bizCategories, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.ink)),
          ),
          for (final c in categories)
            ListTile(
              onTap: () => Navigator.pop(context, c),
              selected: c.id == current,
              selectedTileColor: p.accent.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: Text(c.icon ?? '•', style: const TextStyle(fontSize: 24)),
              title: Text(c.name, style: TextStyle(fontWeight: FontWeight.w700, color: c.count == 0 ? p.inkMuted : p.ink)),
              subtitle: categoryAbout(c.slug, kit.language) == null ? null : Text(categoryAbout(c.slug, kit.language)!),
              trailing: Text(
                c.count == 0 ? '—' : '${c.count}',
                style: TextStyle(fontWeight: FontWeight.w800, color: c.count == 0 ? p.inkMuted : p.accent),
              ),
            ),
        ],
      ),
    ),
  );
}
