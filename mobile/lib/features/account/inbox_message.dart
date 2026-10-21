import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app_services.dart';
import '../../core/account.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../home/feature_catalog.dart';
import '../qna/qna_parts.dart';

void openInboxMessage(BuildContext context, AppServices services, InboxItem item) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => InboxMessageScreen(services: services, item: item)),
  );
}

/// One message from the inbox, whole: its photos, all of its text (links,
/// Telegram names and phone numbers can be tapped, any of it copied), and
/// the page it is about.
class InboxMessageScreen extends StatelessWidget {
  const InboxMessageScreen({super.key, required this.services, required this.item});

  final AppServices services;
  final InboxItem item;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final language = services.locale.language ?? AppLanguage.uz;
    final target = featureForPush(item.data);
    final when = DateFormat(language == AppLanguage.uz ? 'd-MMMM, HH:mm' : 'd MMMM, HH:mm', language.code).format(item.at);
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(
        title: Text(s.inboxMessage),
        backgroundColor: p.page,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + MediaQuery.paddingOf(context).bottom),
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.badge, shape: BoxShape.circle),
                child: Text(target?.emoji ?? '🔔', style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  [if (target != null) target.label(s), when].join('  ·  '),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SelectableText(
            item.title,
            style: TextStyle(
              fontFamily: Brand.displayFont,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: p.ink,
            ),
          ),
          if (item.images.isNotEmpty) ...[
            const SizedBox(height: 16),
            InboxPhotos(urls: item.images),
          ],
          if (item.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            LinkedText(
              item.text,
              phones: true,
              style: TextStyle(fontSize: 16, height: 1.55, color: p.ink),
              onLink: services.openLink,
            ),
          ],
          if (target != null) ...[
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                services.openFeature(context, target, services);
              },
              icon: Text(target.emoji, style: const TextStyle(fontSize: 18)),
              label: Text(s.inboxOpenSection(target.label(s))),
            ),
          ],
        ],
      ),
    );
  }
}

/// A message's photos, whole (never cropped): one at the page's width, more
/// side by side to swipe through. A tap shows them full screen, to zoom.
class InboxPhotos extends StatefulWidget {
  const InboxPhotos({super.key, required this.urls});

  final List<String> urls;

  @override
  State<InboxPhotos> createState() => _InboxPhotosState();
}

class _InboxPhotosState extends State<InboxPhotos> {
  int _page = 0;

  void _open(int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => _PhotoViewer(urls: widget.urls, first: index)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final urls = widget.urls;
    Widget photo(int i, {BoxFit fit = BoxFit.contain}) => Semantics(
          button: true,
          image: true,
          label: s.inboxPhoto(i + 1, urls.length),
          child: GestureDetector(
            onTap: () => _open(i),
            child: _NetworkPhoto(url: urls[i], fit: fit),
          ),
        );

    if (urls.length == 1) {
      return ClipRRect(borderRadius: BorderRadius.circular(16), child: photo(0, fit: BoxFit.fitWidth));
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: ColoredBox(
              color: p.badge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: urls.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => photo(i),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _Count(text: '${_page + 1} / ${urls.length}'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < urls.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? p.accent : p.hairlineStrong,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}

/// A photo from the internet: a soft placeholder while it loads, a broken
/// picture if it can't.
class _NetworkPhoto extends StatelessWidget {
  const _NetworkPhoto({required this.url, required this.fit});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    Widget box(Widget child) => Container(
          height: 220,
          width: double.infinity,
          color: p.badge,
          alignment: Alignment.center,
          child: child,
        );
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : box(const SizedBox.square(dimension: 26, child: CircularProgressIndicator(strokeWidth: 2.5))),
      errorBuilder: (context, error, stack) => box(Icon(Icons.broken_image_outlined, size: 36, color: p.inkMuted)),
    );
  }
}

/// The photos full screen, on black: swipe between them, pinch to zoom.
class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.urls, required this.first});

  final List<String> urls;
  final int first;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late int _page = widget.first;
  late final _pages = PageController(initialPage: widget.first);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pages,
              itemCount: urls.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    urls[i],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) =>
                        const Icon(Icons.broken_image_outlined, size: 48, color: Colors.white54),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                      const Spacer(),
                      if (urls.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _Count(text: '${_page + 1} / ${urls.length}'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
