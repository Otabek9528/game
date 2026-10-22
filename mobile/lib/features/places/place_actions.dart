import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'places_models.dart';
import 'places_parts.dart';

/// The dialer for [phone]: digits, +, - and brackets only.
Uri telUri(String phone) => Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+\-()]'), ''));

/// The place in Naver Map: its own link, else a search for its address.
Uri naverUri(Place place) =>
    Uri.parse(place.naverUrl ?? 'https://map.naver.com/p/search/${Uri.encodeComponent(place.address ?? place.name)}');

/// The way there in Kakao Map: its own link, else Kakao's route link.
Uri kakaoUri(Place place) => Uri.parse(place.kakaoUrl ??
    (place.located
        ? 'https://map.kakao.com/link/to/${Uri.encodeComponent(place.name)},${place.lat},${place.lon}'
        : 'https://map.kakao.com/link/search/${Uri.encodeComponent(place.address ?? place.name)}'));

/// The way there in Google Maps.
Uri googleUri(Place place) => place.located
    ? Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': '${place.lat},${place.lon}'})
    : Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': place.address ?? place.name});

/// The way there: Naver, Kakao or Google Maps.
Future<void> routeToPlace(BuildContext context, AppServices services, Place place) async {
  final s = AppLocalizations.of(context);
  final p = VegukinPalette.of(context);
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: p.card,
    builder: (context) {
      Widget row(String key, Widget icon, String title, String? subtitle) => ListTile(
            leading: icon,
            title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink)),
            subtitle: subtitle == null ? null : Text(subtitle, style: TextStyle(color: p.inkMuted)),
            trailing: Icon(Icons.open_in_new_rounded, size: 18, color: p.inkMuted),
            onTap: () => Navigator.pop(context, key),
          );
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetTitle(s.plRouteTitle, subtitle: s.plRouteHint),
            row('naver', const _MapMark('N', Color(0xFF03C75A), Colors.white), 'Naver Map', null),
            row('kakao', const _MapMark('K', Color(0xFFFEE500), Color(0xFF191600)), 'Kakao Map', null),
            row('google', const _MapMark('G', Color(0xFF4285F4), Colors.white), 'Google Maps', null),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
  if (!context.mounted) return;
  switch (choice) {
    case 'naver':
      await services.openLink(naverUri(place));
    case 'kakao':
      await services.openLink(kakaoUri(place));
    case 'google':
      await services.openLink(googleUri(place));
  }
}

Future<void> copyAddress(BuildContext context, Place place) async {
  final address = place.address;
  if (address == null) return;
  final s = AppLocalizations.of(context);
  HapticFeedback.lightImpact();
  await Clipboard.setData(ClipboardData(text: address));
  if (context.mounted) showPlacesSnack(context, s.plAddressCopied);
}

/// The phone's share sheet: name, address, number, and the place in both
/// Korean maps (people use one or the other; neither is everyone's).
Future<void> sharePlace(BuildContext context, AppServices services, Place place) {
  final s = AppLocalizations.of(context);
  return services.shareText([
    '${place.kind.emoji} ${place.name}',
    if (place.address != null) '📍 ${place.address}',
    if (place.phones.isNotEmpty) '📞 ${place.phones.join(', ')}',
    '',
    'Naver Map: ${naverUri(place)}',
    'Kakao Map: ${kakaoUri(place)}',
    '',
    s.plShareFooter,
  ].join('\n'));
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text, {this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.ink)),
          if (subtitle case final subtitle?) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13.5, height: 1.4, color: p.inkSoft)),
          ],
        ],
      ),
    );
  }
}

/// A map app's letter on its colour.
class _MapMark extends StatelessWidget {
  const _MapMark(this.letter, this.background, this.ink);

  final String letter;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
        child: Text(letter, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: ink)),
      );
}
