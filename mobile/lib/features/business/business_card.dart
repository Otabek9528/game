import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../support/support_parts.dart';
import 'business_data.dart';
import 'business_logo.dart';
import 'business_models.dart';
import 'business_parts.dart';
import 'business_source.dart';
import 'business_text.dart';

void openBusiness(BuildContext context, BizKit kit, Business business) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BusinessCard(kit: kit, seed: business)));
}

/// A business, to decide whether to contact it: who it is, then how to
/// reach it (the two likely ways as large buttons carrying the number or
/// handle, the rest as a list), then what the owner wrote. It opens at once
/// on what the list already knew, and fills in. The page is washed in the
/// colour of the business's own logo.
class BusinessCard extends StatefulWidget {
  const BusinessCard({super.key, required this.kit, required this.seed});

  final BizKit kit;
  final Business seed;

  @override
  State<BusinessCard> createState() => _BusinessCardState();
}

class _BusinessCardState extends State<BusinessCard> {
  late Business _business = widget.seed;
  bool _full = false;
  bool _failed = false;
  LogoData? _logo;

  /// The logo fetched, or found missing: the monogram, in the name's colour.
  bool _logoDone = false;

  /// Scrolled past the name: the bar turns solid and takes the name.
  final _scroll = ScrollController();
  bool _scrolled = false;

  BizKit get _kit => widget.kit;

  @override
  void initState() {
    super.initState();
    _load();
    _loadLogo(widget.seed.logoUrl);
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 150;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _loadLogo(Uri? url) {
    if (url == null) return;
    _kit.logos.load(url).then((logo) {
      if (!mounted || url != _business.logoUrl) return;
      setState(() {
        _logo = logo;
        _logoDone = true;
      });
    });
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final business = await _kit.services.businesses.business(widget.seed.id);
      if (!mounted) return;
      setState(() {
        _business = Business(
          id: business.id,
          name: business.name,
          logo: business.logo ?? widget.seed.logo,
          description: business.description,
          likes: business.likes,
          views: business.views,
          categoryId: business.categoryId ?? widget.seed.categoryId,
          categoryName: business.categoryName ?? widget.seed.categoryName,
          links: business.links,
        );
        _full = true;
      });
      if (_business.logoUrl != widget.seed.logoUrl) _loadLogo(_business.logoUrl);
      _kit.library.refresh(_business);
      _kit.services.businesses.countView(business.id);
    } on BizException {
      if (!mounted) return;
      // A saved business still has its contacts.
      setState(() {
        _failed = true;
        _full = widget.seed.links.isNotEmpty;
      });
    }
  }

  void _toggleSave() {
    final s = AppLocalizations.of(context);
    HapticFeedback.selectionClick();
    final saved = _kit.library.toggleSave(_business);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(saved ? s.bizSavedNote : s.bizRemovedNote), behavior: SnackBarBehavior.floating));
  }

  void _share() {
    HapticFeedback.selectionClick();
    final s = AppLocalizations.of(context);
    final b = _business;
    _kit.services.shareText([
      b.name,
      ?b.categoryName,
      '',
      for (final link in splitLinks(b.links).primary + splitLinks(b.links).rest)
        '${linkChannel(s, link.kind)}: ${link.value}',
      '',
      s.bizShareFooter,
    ].join('\n'));
  }

  void _open(BizLink link) {
    final target = link.target;
    if (target == null) return;
    HapticFeedback.lightImpact();
    _kit.services.openLink(target);
  }

  void _copyPhone(String number) =>
      copyWithNote(context, number, AppLocalizations.of(context).bizPhoneCopied);

  void _zoom() {
    final logo = _logo;
    if (logo == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _LogoViewer(bytes: logo.bytes)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final b = _business;
    final tint = _logo?.facts?.tint ?? (b.logoUrl == null || _logoDone ? nameTint(b.name) : null);
    final split = splitLinks(b.links);
    final description = b.description;
    final views = b.views;
    return ListenableBuilder(
      listenable: _kit.library,
      builder: (context, _) {
        final saved = _kit.library.isSaved(b.id);
        return Scaffold(
          backgroundColor: p.page,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: _scrolled ? Color.alphaBlend((tint ?? p.page).withValues(alpha: 0.30), p.page) : Colors.transparent,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            shape: _scrolled ? Border(bottom: BorderSide(color: p.hairline)) : null,
            title: _scrolled ? Text(b.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.ink)) : null,
            actions: [
              IconButton(
                onPressed: _full ? _toggleSave : null,
                tooltip: saved ? s.bizUnsave : s.bizSave,
                icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: saved ? p.gold : null),
              ),
              IconButton(
                onPressed: _full ? _share : null,
                tooltip: s.bizShare,
                icon: const Icon(Icons.share_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Stack(
            children: [
              // The wash, from the logo's own colour, fading into the page.
              AnimatedOpacity(
                opacity: tint == null ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  height: 360,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (tint ?? p.page).withValues(alpha: 0.30),
                        (tint ?? p.page).withValues(alpha: 0.12),
                        (tint ?? p.page).withValues(alpha: 0),
                      ],
                      stops: const [0, 0.48, 1],
                    ),
                  ),
                ),
              ),
              ListView(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(
                  18,
                  MediaQuery.paddingOf(context).top + kToolbarHeight,
                  18,
                  28 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  // Who it is.
                  Center(
                    child: GestureDetector(
                      onTap: _zoom,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          BizLogo(business: b, logos: _kit.logos, size: 96, radius: 26),
                          if (_logo != null)
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(color: p.card, shape: BoxShape.circle, border: Border.all(color: p.hairline)),
                                child: Icon(Icons.zoom_out_map_rounded, size: 14, color: p.inkSoft),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (b.categoryName case final category?)
                    Text(
                      category.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: p.gold),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    b.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w800, color: p.ink),
                  ),
                  if ((views ?? 0) > 0 || b.likes > 0) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 14,
                      children: [
                        if (views != null && views > 0)
                          _Proof(icon: Icons.visibility_outlined, text: s.bizViews(views)),
                        if (b.likes > 0) _Proof(icon: Icons.favorite_border_rounded, text: s.bizLikes(b.likes)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  // How to reach it.
                  if (!_full && !_failed)
                    const _Loading()
                  else if (!_full && _failed)
                    Column(
                      children: [
                        Text(s.bizLoadFailed, style: TextStyle(fontSize: 14, color: p.inkSoft)),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(s.bizRetry),
                        ),
                      ],
                    )
                  else ...[
                    if (split.primary.isEmpty)
                      _NoContact(
                        text: description == null ? s.bizNoInfo : s.bizNoContact,
                        onAsk: () => _kit.services.openLink(bizAdmin),
                      )
                    else
                      Row(
                        children: [
                          for (final (i, link) in split.primary.indexed) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: _ContactButton(
                                link: link,
                                primary: i == 0,
                                onTap: () => _open(link),
                                onLongPress: link.isPhone ? () => _copyPhone(link.value) : null,
                              ),
                            ),
                          ],
                        ],
                      ),
                    if (split.rest.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _Label(s.bizLinks),
                      SupportCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            for (final (i, link) in split.rest.indexed) ...[
                              if (i > 0) Divider(height: 1, indent: 60, color: p.hairline),
                              _LinkRow(link: link, onTap: () => _open(link)),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (description != null) ...[
                      const SizedBox(height: 22),
                      _Label(s.bizAbout),
                      SupportCard(
                        child: BizDescription(
                          text: description,
                          onLink: (uri) => _kit.services.openLink(uri),
                          onPhone: (digits) => _kit.services.openLink(Uri(scheme: 'tel', path: digits)),
                          onCopy: (text, note) => copyWithNote(context, text, note),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 22),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _kit.services.openLink(bizAdmin),
                      icon: Icon(Icons.flag_outlined, size: 18, color: p.inkMuted),
                      label: Text(s.bizReport, style: TextStyle(color: p.inkMuted)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Proof extends StatelessWidget {
  const _Proof({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: p.inkMuted),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 13, color: p.inkSoft)),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: VegukinPalette.of(context).ink)),
      );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    Widget bar(double height, [double width = double.infinity]) => Container(
          width: width,
          height: height,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(14)),
        );
    return Column(
      children: [
        Row(children: [Expanded(child: bar(64)), const SizedBox(width: 10), Expanded(child: bar(64))]),
        const SizedBox(height: 12),
        bar(14),
        bar(14),
        Align(alignment: Alignment.centerLeft, child: bar(14, 160)),
      ],
    );
  }
}

/// A large button carrying what one came for (the number, the handle), with
/// what the tap will do under it. A phone number is copied by holding it.
class _ContactButton extends StatelessWidget {
  const _ContactButton({required this.link, required this.primary, required this.onTap, this.onLongPress});

  final BizLink link;
  final bool primary;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final (icon, colour) = linkLook(link.kind);
    final value = link.display(privateGroup: s.bizPrivateGroup);
    final ink = primary ? Colors.white : p.ink;
    return Material(
      color: primary ? Brand.emerald700 : p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: primary ? BorderSide.none : BorderSide(color: p.hairlineStrong),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary ? Colors.white.withValues(alpha: 0.16) : colour.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 21, color: primary ? Colors.white : colour),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (value.isNotEmpty)
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: ink),
                      ),
                    Text(
                      linkVerb(s, link.kind),
                      maxLines: value.isEmpty ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: value.isEmpty ? 14 : 12,
                        fontWeight: value.isEmpty ? FontWeight.w700 : FontWeight.w500,
                        color: primary ? Colors.white.withValues(alpha: 0.85) : p.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoContact extends StatelessWidget {
  const _NoContact({required this.text, required this.onAsk});

  final String text;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return SupportCard(
      child: Row(
        children: [
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: p.inkSoft))),
          TextButton(onPressed: onAsk, child: Text(s.bizNoContactAsk)),
        ],
      ),
    );
  }
}

/// A place it can also be found: what it is, then whose.
class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.link, required this.onTap});

  final BizLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final (icon, colour) = linkLook(link.kind);
    final value = link.display(privateGroup: s.bizPrivateGroup);
    // A website that is really a map or a store is named for where it goes.
    var name = linkChannel(s, link.kind);
    if (link.kind == 'website') {
      final host = hostOf(link.value);
      name = switch (host.map) {
        MapHost.naver => s.bizMapNaver,
        MapHost.kakao => s.bizMapKakao,
        MapHost.google => s.bizMapGoogle,
        null => host.kind == 'website' ? s.bizChannelWebsite : host.brand ?? name,
      };
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: colour.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 19, color: colour),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink)),
                  if (value.isNotEmpty)
                    Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// The owner's description as they wrote it, with typography and taps
/// added: labels in weight, numbers to call, links as small buttons, and
/// under an address its copy and map buttons.
class BizDescription extends StatefulWidget {
  const BizDescription({super.key, required this.text, required this.onLink, required this.onPhone, required this.onCopy});

  final String text;
  final ValueChanged<Uri> onLink;
  final ValueChanged<String> onPhone;
  final void Function(String text, String note) onCopy;

  @override
  State<BizDescription> createState() => _BizDescriptionState();
}

class _BizDescriptionState extends State<BizDescription> {
  final _taps = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final tap in _taps) {
      tap.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _tap(VoidCallback onTap) {
    final tap = TapGestureRecognizer()..onTap = onTap;
    _taps.add(tap);
    return tap;
  }

  @override
  Widget build(BuildContext context) {
    for (final tap in _taps) {
      tap.dispose();
    }
    _taps.clear();
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final base = TextStyle(fontSize: 14.5, height: 1.55, color: p.ink);
    final blocks = parseDescription(widget.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (b, block) in blocks.indexed) ...[
          if (b > 0) const SizedBox(height: 12),
          for (final line in block) ...[
            Text.rich(
              TextSpan(
                style: base,
                children: [
                  if (line.label case final label?) TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w800)),
                  for (final piece in line.pieces)
                    switch (piece.kind) {
                      PieceKind.text => TextSpan(text: piece.text),
                      PieceKind.tag => TextSpan(text: piece.text, style: TextStyle(color: p.accent)),
                      PieceKind.address => TextSpan(text: piece.text, style: const TextStyle(fontWeight: FontWeight.w700)),
                      PieceKind.phone => TextSpan(
                          text: piece.text,
                          style: TextStyle(color: p.accent, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                          recognizer: _tap(() => widget.onPhone(piece.value!)),
                        ),
                      PieceKind.link => WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: _InlineLink(url: piece.value!, onTap: () => widget.onLink(Uri.parse(piece.value!))),
                        ),
                    },
                ],
              ),
            ),
            if (line.address case final address?)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _AddressButton(
                      badge: Icon(Icons.copy_rounded, size: 14, color: p.inkSoft),
                      label: s.bizCopyAddress,
                      onTap: () => widget.onCopy(address, s.bizAddressCopied),
                    ),
                    _AddressButton(
                      badge: const _MapBadge('N', Color(0xFF03C75A), Colors.white),
                      label: 'Naver Map',
                      onTap: () => widget.onLink(naverMap(address)),
                    ),
                    _AddressButton(
                      badge: const _MapBadge('K', Color(0xFFFEE500), Color(0xFF3A1D1D)),
                      label: 'Kakao Map',
                      onTap: () => widget.onLink(kakaoMap(address)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 2),
          ],
        ],
      ],
    );
  }
}

/// A link inside the description: a profile as its handle, anything else as
/// the name of where it goes, never as a long raw address.
class _InlineLink extends StatelessWidget {
  const _InlineLink({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final host = hostOf(url);
    final (icon, colour) = linkLook(host.kind);
    const handles = {'telegram', 'instagram', 'tiktok', 'youtube', 'facebook'};
    final handle = handles.contains(host.kind) ? BizLink(host.kind, url).display(privateGroup: s.bizPrivateGroup) : '';
    final label = handle.startsWith('@')
        ? handle
        : switch (host.map) {
            MapHost.naver => s.bizMapNaver,
            MapHost.kakao => s.bizMapKakao,
            MapHost.google => s.bizMapGoogle,
            null => host.brand ?? url,
          };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: colour.withValues(alpha: 0.1),
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(host.kind == 'website' ? Icons.open_in_new_rounded : icon, size: 14, color: colour),
                const SizedBox(width: 5),
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressButton extends StatelessWidget {
  const _AddressButton({required this.badge, required this.label, required this.onTap});

  final Widget badge;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Material(
      color: p.cardSelected,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              badge,
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge(this.letter, this.background, this.ink);

  final String letter;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(4)),
        child: Text(letter, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: ink)),
      );
}

/// The logo, full screen: pinch to zoom.
class _LogoViewer extends StatelessWidget {
  const _LogoViewer({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(maxScale: 5, child: Image.memory(bytes, fit: BoxFit.contain)),
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
