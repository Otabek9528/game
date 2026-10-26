import 'package:flutter/foundation.dart';

import '../places/places_models.dart';

double? _num(Object? v) => v is num ? v.toDouble() : null;
String? _text(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

/// The radii an area may have, in km (place_notifications_api.RADII_KM).
const notifyRadii = [1, 3, 5, 10];

/// "Tell me what happens to places of [types] within [radiusKm] of a point":
/// where one stood ([fromLocation]) or an address.
@immutable
class NotifyArea {
  const NotifyArea({
    required this.id,
    required this.fromLocation,
    required this.lat,
    required this.lon,
    required this.radiusKm,
    required this.types,
    this.label,
    this.inside = 0,
  });

  final int id;
  final bool fromLocation;
  final String? label;
  final double lat;
  final double lon;
  final int radiusKm;
  final Set<PlaceKind> types;

  /// Places of those types inside it now.
  final int inside;

  static NotifyArea? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], lat = _num(json['lat']), lon = _num(json['lon']), radius = json['radiusKm'];
    if (id is! num || lat == null || lon == null || radius is! num) return null;
    return NotifyArea(
      id: id.toInt(),
      fromLocation: json['source'] == 'location',
      label: _text(json['label']),
      lat: lat,
      lon: lon,
      radiusKm: radius.toInt(),
      types: {for (final t in (json['types'] as List?) ?? const []) ?PlaceKind.fromKey(t)},
      inside: (json['insideCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// An area being made or changed: a point (where one stands) or an address
/// the server will find.
typedef AreaDraft = ({double? lat, double? lon, String? label, String? address, int radiusKm, Set<PlaceKind> types});

/// How a person is told: the app's push, the Telegram bot, or both. Only a
/// Telegram account [canTelegram]; [bot] is the bot's username.
@immutable
class NotifyDelivery {
  const NotifyDelivery({this.telegram = false, this.push = true, this.canTelegram = false, this.bot});

  final bool telegram;
  final bool push;
  final bool canTelegram;
  final String? bot;

  static NotifyDelivery fromJson(Object? json) => json is Map
      ? NotifyDelivery(
          telegram: json['telegram'] == true,
          push: json['push'] != false,
          canTelegram: json['canTelegram'] == true,
          bot: _text(json['bot']),
        )
      : const NotifyDelivery();
}

/// One's areas, watched places and how they are told; [botBlocked] when the
/// bot couldn't reach them last time.
typedef NotifyMe = ({List<NotifyArea> areas, List<WatchedPlace> watches, NotifyDelivery delivery, bool botBlocked});

/// The places around a point, for the area preview: where they are, of
/// which type, how far; and the point itself (an address, found).
typedef RadiusPreview = ({
  double lat,
  double lon,
  String? label,
  List<({double lat, double lon, PlaceKind kind, double km})> points,
});

NotifyMe notifyMeFromJson(Map<String, dynamic> json) {
  final sub = json['subscriber'];
  return (
    areas: [for (final a in (json['areas'] as List?) ?? const []) ?NotifyArea.fromJson(a)],
    watches: [for (final w in (json['watches'] as List?) ?? const []) ?WatchedPlace.fromJson(w)],
    delivery: NotifyDelivery.fromJson(json['delivery']),
    botBlocked: sub is Map && sub['active'] == false,
  );
}

/// [notifyMeFromJson]'s input again: what the page keeps on the phone, to
/// show at once next time.
Map<String, Object?> notifyMeToJson(NotifyMe me) => {
  'subscriber': {'active': !me.botBlocked},
  'delivery': {
    'telegram': me.delivery.telegram,
    'push': me.delivery.push,
    'canTelegram': me.delivery.canTelegram,
    'bot': me.delivery.bot,
  },
  'areas': [
    for (final a in me.areas)
      {
        'id': a.id,
        'source': a.fromLocation ? 'location' : 'address',
        'label': a.label,
        'lat': a.lat,
        'lon': a.lon,
        'radiusKm': a.radiusKm,
        'types': [for (final k in a.types) k.key],
        'insideCount': a.inside,
      },
  ],
  'watches': [
    for (final w in me.watches) {'placeId': w.id, 'name': w.name, 'type': w.kind.key, 'city': w.city},
  ],
};

RadiusPreview? radiusPreviewFromJson(Map<String, dynamic> json) {
  final c = json['center'];
  if (c is! Map || _num(c['lat']) == null || _num(c['lon']) == null) return null;
  return (
    lat: _num(c['lat'])!,
    lon: _num(c['lon'])!,
    label: _text(c['label']),
    points: [
      for (final p in (json['points'] as List?) ?? const [])
        if (p is Map && _num(p['lat']) != null && _num(p['lon']) != null && PlaceKind.fromKey(p['type']) != null)
          (lat: _num(p['lat'])!, lon: _num(p['lon'])!, kind: PlaceKind.fromKey(p['type'])!, km: _num(p['km']) ?? 0),
    ],
  );
}
