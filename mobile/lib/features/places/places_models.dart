import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Mosques, restaurants (halal) and shops: the server's three building types.
enum PlaceKind {
  mosque('Masjid', '🕌'),
  restaurant('Oshxona', '🍽️'),
  shop("Do'kon", '🏪');

  const PlaceKind(this.buildingType, this.emoji);

  /// The server's name for it.
  final String buildingType;
  final String emoji;

  /// The web app's: `mosque`, `restaurant`, `shop`.
  String get key => name;

  static PlaceKind? fromBuildingType(Object? value) => values.where((k) => k.buildingType == value).firstOrNull;

  static PlaceKind? fromKey(Object? value) => values.where((k) => k.key == value).firstOrNull;
}

String? _text(Object? value) => value is String && value.trim().isNotEmpty ? value.trim() : null;

double? _number(Object? value) => value is num ? value.toDouble() : (value is String ? double.tryParse(value) : null);

/// The server's place numbers come as text ("103") or as numbers.
int? _id(Object? value) => value is int ? value : (value is String ? int.tryParse(value.trim()) : null);

/// A link the server keeps; only http(s) ones are opened.
String? _link(Object? value) {
  final text = _text(value);
  return text != null && RegExp(r'^https?://', caseSensitive: false).hasMatch(text) ? text : null;
}

/// A place as the lists and the place page have it.
@immutable
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.kind,
    this.city,
    this.address,
    this.phones = const [],
    this.lat,
    this.lon,
    this.kakaoUrl,
    this.naverUrl,
    this.photoFolder,
    this.menuUrl,
    this.telegramUrl,
    this.tiktokUrl,
    this.instagramUrl,
    this.note,
    this.reviewCount = 0,
    this.rating = 0,
    this.distanceKm,
  });

  final int id;
  final String name;
  final PlaceKind kind;

  /// In English: "Ansan".
  final String? city;

  /// In Korean, as it is copied and searched.
  final String? address;

  /// The server keeps them in one field, comma-separated.
  final List<String> phones;
  final double? lat;
  final double? lon;
  final String? kakaoUrl;
  final String? naverUrl;

  /// "Photos/117": a folder of the web app's.
  final String? photoFolder;

  /// Restaurants' menus.
  final String? menuUrl;
  final String? telegramUrl;
  final String? tiktokUrl;
  final String? instagramUrl;

  /// About the place, written by people: opening hours, days off, news.
  final String? note;
  final int reviewCount;

  /// The average, 0 without reviews.
  final double rating;

  /// From where the server was asked (nearby, by address); null otherwise.
  final double? distanceKm;

  bool get located => lat != null && lon != null;

  String? social(String field) => switch (field) {
        'telegram' => telegramUrl,
        'tiktok' => tiktokUrl,
        'instagram' => instagramUrl,
        'note' => note,
        _ => null,
      };

  /// [kind] when the answer doesn't say (it always does).
  static Place? fromJson(Object? json, {PlaceKind? kind}) {
    if (json is! Map<String, dynamic>) return null;
    final id = _id(json['id']);
    final name = _text(json['name']);
    final placeKind = PlaceKind.fromBuildingType(json['buildingType']) ?? kind;
    if (id == null || name == null || placeKind == null) return null;
    var lat = _number(json['lat']), lon = _number(json['lon']);
    // Saved without a location: the admin panel writes 0, 0.
    if (lat == 0 && lon == 0) lat = lon = null;
    return Place(
      id: id,
      name: name,
      kind: placeKind,
      city: _text(json['city']),
      address: _text(json['address']),
      phones: [
        for (final p in (_text(json['phone']) ?? '').split(','))
          if (p.trim().isNotEmpty) p.trim(),
      ],
      lat: lat,
      lon: lon,
      kakaoUrl: _link(json['kakaoMapUrl']),
      naverUrl: _link(json['naverMapUrl']),
      photoFolder: _text(json['photo']),
      menuUrl: _link(json['menuUrl']),
      telegramUrl: _link(json['telegramUrl']),
      tiktokUrl: _link(json['tiktokUrl']),
      instagramUrl: _link(json['instagramUrl']),
      note: _text(json['ownerNote']),
      reviewCount: _number(json['reviewCount'])?.toInt() ?? 0,
      rating: _number(json['averageRating']) ?? 0,
      distanceKm: _number(json['distance']),
    );
  }

  /// As the server sends it, to keep on the phone.
  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'buildingType': kind.buildingType,
        'city': city,
        'address': address,
        'phone': phones.join(', '),
        'lat': lat,
        'lon': lon,
        'kakaoMapUrl': kakaoUrl,
        'naverMapUrl': naverUrl,
        'photo': photoFolder,
        'menuUrl': menuUrl,
        'telegramUrl': telegramUrl,
        'tiktokUrl': tiktokUrl,
        'instagramUrl': instagramUrl,
        'ownerNote': note,
        'reviewCount': reviewCount,
        'averageRating': rating,
      };

  /// Great-circle distance from [lat2], [lon2], in km; null without a location.
  double? distanceFrom(double lat2, double lon2) {
    if (!located) return null;
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat! - lat2), dLon = rad(lon! - lon2);
    final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat2)) * math.cos(rad(lat!)) * math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }
}

/// A review: its writer stays private, except that one's own is marked.
@immutable
class PlaceReview {
  const PlaceReview({required this.rating, this.text = '', this.at, this.mine = false});

  final int rating;
  final String text;
  final DateTime? at;
  final bool mine;

  static PlaceReview? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final rating = _number(json['rating'])?.toInt();
    if (rating == null || rating < 1 || rating > 5) return null;
    return PlaceReview(
      rating: rating,
      text: _text(json['text']) ?? '',
      at: DateTime.tryParse(json['timestamp'] as String? ?? '')?.toLocal(),
      mine: json['mine'] == true,
    );
  }
}

/// Who watches a place and what this person may do there.
@immutable
class PlaceWatch {
  const PlaceWatch({
    this.count = 0,
    this.watching = false,
    this.hasOwner = false,
    this.isOwner = false,
    this.claimPending = false,
    this.pendingAnnouncements = 0,
  });

  final int count;
  final bool watching;
  final bool hasOwner;
  final bool isOwner;
  final bool claimPending;
  final int pendingAnnouncements;

  PlaceWatch copyWith({int? count, bool? watching, bool? hasOwner, bool? isOwner, bool? claimPending, int? pendingAnnouncements}) =>
      PlaceWatch(
        count: count ?? this.count,
        watching: watching ?? this.watching,
        hasOwner: hasOwner ?? this.hasOwner,
        isOwner: isOwner ?? this.isOwner,
        claimPending: claimPending ?? this.claimPending,
        pendingAnnouncements: pendingAnnouncements ?? this.pendingAnnouncements,
      );

  static PlaceWatch fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const PlaceWatch();
    return PlaceWatch(
      count: _number(json['watchCount'])?.toInt() ?? 0,
      watching: json['watching'] == true,
      hasOwner: json['hasOwner'] == true,
      isOwner: json['isOwner'] == true,
      claimPending: json['claimPending'] == true,
      pendingAnnouncements: _number(json['pendingAnnouncements'])?.toInt() ?? 0,
    );
  }
}

/// The place page: the place, its reviews, what waits for review, and its
/// watchers.
@immutable
class PlaceDetail {
  const PlaceDetail({
    required this.place,
    this.reviews = const [],
    this.pending = const {},
    this.watch = const PlaceWatch(),
    this.ownReviews = false,
    this.schedule,
  });

  final Place place;

  /// Newest first.
  final List<PlaceReview> reviews;

  /// Fields with a suggestion waiting for the admin: telegram, tiktok,
  /// instagram, note.
  final Set<String> pending;
  final PlaceWatch watch;

  /// The server marks one's own review, so it can be changed or deleted
  /// (update 6 on); before that, reviews only pile up.
  final bool ownReviews;

  /// A mosque's congregation and Eid times; null for other places and from a
  /// server without them.
  final MosqueSchedule? schedule;

  PlaceReview? get myReview => reviews.where((r) => r.mine).firstOrNull;

  /// How many of each star, 1 to 5.
  List<int> get spread => [for (var star = 1; star <= 5; star++) reviews.where((r) => r.rating == star).length];

  double get average => reviews.isEmpty ? 0 : reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length;

  PlaceDetail copyWith({List<PlaceReview>? reviews, Set<String>? pending, PlaceWatch? watch, MosqueSchedule? schedule}) =>
      PlaceDetail(
        place: place,
        reviews: reviews ?? this.reviews,
        pending: pending ?? this.pending,
        watch: watch ?? this.watch,
        ownReviews: ownReviews,
        schedule: schedule ?? this.schedule,
      );

  static PlaceDetail? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final place = Place.fromJson(json);
    if (place == null) return null;
    final raw = (json['reviews'] as List?) ?? const [];
    return PlaceDetail(
      place: place,
      reviews: [for (final r in raw) ?PlaceReview.fromJson(r)],
      pending: {for (final f in (json['pendingFields'] as List?) ?? const []) if (f is String) f},
      watch: PlaceWatch.fromJson(json['watch']),
      // A server before update 6 sends the writer's id instead of "mine".
      ownReviews: raw.any((r) => r is Map && r.containsKey('mine')),
      schedule: place.kind == PlaceKind.mosque ? MosqueSchedule.fromJson(json) : null,
    );
  }
}

/// "HH:MM" as the server keeps prayer times (Korea time); null for anything else.
String? _hhmm(Object? value) =>
    value is String && RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value) ? value : null;

/// The server's "2027-02-24" (a Korea date), as a day.
DateTime? _day(Object? value) {
  final m = value is String ? RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value) : null;
  return m == null ? null : DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
}

/// One Eid's prayers (up to three) and when they were last changed.
@immutable
class EidTimes {
  const EidTimes({this.sessions = const [], this.updated, this.stale = false});

  final List<String> sessions;
  final DateTime? updated;

  /// Not changed for 60 days: likely last year's.
  final bool stale;

  static EidTimes? fromJson(Object? json) {
    if (json is! Map) return null;
    final sessions = [for (final t in (json['sessions'] as List?) ?? const []) ?_hhmm(t)];
    if (sessions.isEmpty) return null;
    return EidTimes(sessions: sessions, updated: _day(json['updatedAt']), stale: json['stale'] == true);
  }
}

/// A mosque's own prayer times, as its community keeps them
/// (mosque_timetable_api.py): the daily congregation times and Juma, and the
/// two Eids. Anyone signed in changes them; they show at once.
@immutable
class MosqueSchedule {
  const MosqueSchedule({this.daily = const {}, this.dailyUpdated, this.dailyStale = false, this.eids = const {}});

  /// The order they are shown in.
  static const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha', 'jumuah'];

  /// The five of every day; Juma takes Peshin's place on Fridays.
  static const fivePrayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  static const eidKinds = ['fitr', 'adha'];

  /// "HH:MM" by prayer, only those that have a time.
  final Map<String, String> daily;
  final DateTime? dailyUpdated;
  final bool dailyStale;

  /// By Eid ('fitr', 'adha'), only those that have times.
  final Map<String, EidTimes> eids;

  bool get hasDaily => daily.isNotEmpty;
  bool get hasEid => eids.isNotEmpty;

  /// From a place's page or a save's answer: `timetable` and `eid`. Null
  /// when the server has no prayer times at all (no `eid`).
  static MosqueSchedule? fromJson(Object? json) {
    if (json is! Map || !json.containsKey('eid')) return null;
    final timetable = json['timetable'];
    final daily = <String, String>{
      if (timetable is Map)
        for (final p in prayers) p: ?_hhmm(timetable[p]),
    };
    final eid = json['eid'];
    return MosqueSchedule(
      daily: daily,
      dailyUpdated: timetable is Map ? _day(timetable['updatedAt']) : null,
      dailyStale: timetable is Map && timetable['stale'] == true,
      eids: {
        if (eid is Map)
          for (final kind in eidKinds) kind: ?EidTimes.fromJson(eid[kind]),
      },
    );
  }
}

/// A place this person watches, as the notifications list has it.
@immutable
class WatchedPlace {
  const WatchedPlace({required this.id, required this.name, required this.kind, this.city});

  final int id;
  final String name;
  final PlaceKind kind;
  final String? city;

  static WatchedPlace? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = _id(json['placeId']), name = _text(json['name']);
    final kind = PlaceKind.fromKey(json['type']) ?? PlaceKind.fromBuildingType(json['type']);
    if (id == null || name == null || kind == null) return null;
    return WatchedPlace(id: id, name: name, kind: kind, city: _text(json['city']));
  }
}

/// [code]: the server's (`sign_in_required`, `place_not_found`,
/// `already_pending`, `rate_limited` …), `offline`, or `http_<status>`.
class PlacesException implements Exception {
  const PlacesException(this.code, [this.status = 0, this.message]);

  final String code;
  final int status;

  /// The server's own words, in English.
  final String? message;

  @override
  String toString() => 'PlacesException($code, $status)';
}
