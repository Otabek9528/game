import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'privacy_text.dart';

/// The privacy policy in the app's language: the text of the web page Google
/// Play links (store/privacy.html), drawn natively.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key, required this.services});

  final AppServices services;

  static final _inline = RegExp(r'\*\*(.+?)\*\*|\[(.+?)\]\((.+?)\)');

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final lines = privacyText[(services.locale.language ?? AppLanguage.uz).code]!;
    final blocks = <Widget>[];
    List<Widget>? box;
    for (final line in lines) {
      if (line == '[box]') {
        box = [];
      } else if (line == '[/box]') {
        blocks.add(Container(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.hairlineStrong),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: box!),
        ));
        box = null;
      } else {
        (box ?? blocks).add(_block(line, p));
      }
    }
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(title: Text(s.accountPrivacy), backgroundColor: p.page, surfaceTintColor: Colors.transparent),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 28 + MediaQuery.paddingOf(context).bottom),
        children: blocks,
      ),
    );
  }

  Widget _block(String line, VegukinPalette p) {
    final body = TextStyle(fontSize: 15, height: 1.5, color: p.ink);
    if (line.startsWith('# ')) {
      return Text(line.substring(2), style: TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w800, color: p.ink));
    }
    if (line.startsWith('_ ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 14),
        child: Text(line.substring(2), style: TextStyle(fontSize: 13, color: p.inkMuted)),
      );
    }
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(line.substring(3), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink)),
      );
    }
    if (line.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 9, left: 2, right: 12),
              decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
            ),
            Expanded(child: Text.rich(_spans(line.substring(2), body, p))),
          ],
        ),
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text.rich(_spans(line, body, p)));
  }

  /// **Bold** and [links](…), which open where they point.
  TextSpan _spans(String text, TextStyle style, VegukinPalette p) {
    final spans = <InlineSpan>[];
    var at = 0;
    for (final match in _inline.allMatches(text)) {
      spans.add(TextSpan(text: text.substring(at, match.start)));
      if (match[1] case final bold?) {
        spans.add(TextSpan(text: bold, style: const TextStyle(fontWeight: FontWeight.w700)));
      } else {
        final link = Uri.parse(match[3]!);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => services.openLink(link),
            child: Text(match[2]!, style: style.copyWith(color: p.accent, fontWeight: FontWeight.w700)),
          ),
        ));
      }
      at = match.end;
    }
    spans.add(TextSpan(text: text.substring(at)));
    return TextSpan(style: style, children: spans);
  }
}
