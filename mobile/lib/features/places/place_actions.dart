import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
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
