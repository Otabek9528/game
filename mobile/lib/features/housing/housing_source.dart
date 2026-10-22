import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config.dart';

/// What went wrong: the server's code (`validation_failed`, `geocode_failed`,
/// `rate_limited`, `sign_in_required`, `gone`, …) or `offline`, with the
/// fields it named and how long to wait.
class HousingException implements Exception {
  const HousingException(this.code, {this.status, this.fields = const {}, this.retryAfter});

  final String code;
  final int? status;
  final Map<String, String> fields;
  final int? retryAfter;

  @override
  String toString() => 'HousingException($code)';
}

int? _int(Object? v) => v is num
    ? v.toInt()
    : v is String
    ? int.tryParse(v)
    : null;
String? _text(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

/// A post on the board: an address, a free text, a phone and/or a Telegram
/// name. The list brings a preview (numbers in it hidden); the full post,
/// opened one by one, its whole text and the contact.
@immutable
class HousingPost {
  const HousingPost({
    required this.id,
    required this.address,
    required this.text,
    required this.postedAgo,
    this.truncated = false,
    this.isNew = false,
    this.hasContact = false,
    this.hasTelegram = false,
    this.mine = false,
    this.distanceKm,
    this.contact,
    this.telegram,
    this.full = false,
    this.addressInput,
    this.showUsername = false,
    this.contactUsername,
    this.expired = false,
    this.daysLeft,
  });

  final int id;
  final String address;

  /// The preview in a list, the whole text when [full].
  final String text;
  final String postedAgo;
  final bool truncated;
  final bool isNew;
  final bool hasContact;
  final bool hasTelegram;
  final bool mine;
  final double? distanceKm;
  final String? contact;

  /// Without "@".
  final String? telegram;
  final bool full;
  final String? addressInput;
  final bool showUsername;

  /// The name one chose to publish (one's own posts only).
  final String? contactUsername;

  /// One's own posts: run out (shown no more), and days to go.
  final bool expired;
  final int? daysLeft;

  static HousingPost? fromJson(Object? json, {bool full = false}) {
    if (json is! Map) return null;
    final id = _int(json['id']);
    if (id == null) return null;
    final contact = _text(json['contact']);
    final telegram = _text(json['telegram_username']);
    return HousingPost(
      id: id,
      address: _text(json['address_display']) ?? _text(json['address_input']) ?? '',
      text: (full ? json['body'] : json['body_preview']) as String? ?? '',
      postedAgo: _text(json['posted_rel_uz']) ?? '',
      truncated: json['body_truncated'] == true,
      isNew: json['is_new'] == true,
      hasContact: json['has_contact'] == true || contact != null,
      hasTelegram: json['has_telegram'] == true || telegram != null,
      mine: json['is_mine'] == true,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      contact: contact,
      telegram: telegram,
      full: full,
      addressInput: _text(json['address_input']),
      showUsername: json['show_username'] == true,
      contactUsername: _text(json['contact_username']),
      expired: json['status'] == 'expired',
      daysLeft: _int(json['days_left']),
    );
  }
}

/// "Tell me when a post appears within [radiusKm] of [address]".
@immutable
class HousingAlert {
  const HousingAlert({required this.id, required this.address, required this.radiusKm, this.active = true, this.matches = 0});

  final int id;
  final String address;
  final int radiusKm;
  final bool active;
  final int matches;

  static HousingAlert? fromJson(Object? json) {
    if (json is! Map || _int(json['id']) == null) return null;
    return HousingAlert(
      id: _int(json['id'])!,
      address: _text(json['address_display']) ?? _text(json['address_input']) ?? '',
      radiusKm: _int(json['radius_km']) ?? 10,
      active: json['is_active'] != false,
      matches: _int(json['match_count']) ?? 0,
    );
  }
}

/// A page of the board, and the way to the next.
typedef HousingPage = ({List<HousingPost> posts, String? next});

/// The fields of a post, as written.
typedef HousingDraft = ({String? address, String contact, String body, bool showUsername, String username});

/// The housing board of the Mini App (housing.py). [auth] is the app's
/// account: reading needs none signed in; posting and alerts do.
abstract interface class HousingSource {
  /// Newest first; or nearest to ([lat], [lon]) first.
  Future<HousingPage> posts({String? cursor, double? lat, double? lon});

  Future<HousingPost> post(Map<String, String> auth, int id);

  Future<List<HousingPost>> mine(Map<String, String> auth);

  /// An address in Korean, found: where it is and how the map names it.
  Future<({double lat, double lon, String name})> geocode(Map<String, String> auth, String address);

  Future<HousingPost> create(Map<String, String> auth, HousingDraft draft);

  Future<HousingPost> edit(Map<String, String> auth, int id, HousingDraft draft);

  Future<void> delete(Map<String, String> auth, int id);

  /// Thirty more days; how many are left now.
  Future<int> extend(Map<String, String> auth, int id);

  Future<List<HousingAlert>> alerts(Map<String, String> auth);

  Future<void> addAlert(Map<String, String> auth, String address, int radiusKm);

  Future<void> deleteAlert(Map<String, String> auth, int id);

  /// The account's Telegram name, when it has one.
  Future<String?> username(Map<String, String> auth);
}

class HttpHousingSource implements HousingSource {
  const HttpHousingSource([this._client]);

  final http.Client? _client;
  static final _shared = http.Client();
  http.Client get _http => _client ?? _shared;

  @override
  Future<HousingPage> posts({String? cursor, double? lat, double? lon}) async {
    final json = await _call(
      'GET',
      'posts',
      query: {
        'sort': lat == null ? 'recent' : 'distance',
        'limit': '20',
        'cursor': ?cursor,
        if (lat != null) 'lat': '$lat',
        if (lon != null) 'lon': '$lon',
      },
    );
    return (posts: [for (final p in (json['posts'] as List?) ?? const []) ?HousingPost.fromJson(p)], next: _text(json['next_cursor']));
  }

  @override
  Future<HousingPost> post(Map<String, String> auth, int id) async =>
      HousingPost.fromJson((await _call('GET', 'posts/$id', auth: auth))['post'], full: true) ??
      (throw const HousingException('bad_response'));

  @override
  Future<List<HousingPost>> mine(Map<String, String> auth) async => [
    for (final p in ((await _call('GET', 'me/posts', auth: auth))['posts'] as List?) ?? const []) ?HousingPost.fromJson(p, full: true),
  ];

  @override
  Future<({double lat, double lon, String name})> geocode(Map<String, String> auth, String address) async {
    final json = await _call('POST', 'geocode', auth: auth, body: {'address': address});
    return (lat: (json['lat'] as num).toDouble(), lon: (json['lon'] as num).toDouble(), name: _text(json['display_name']) ?? address);
  }

  Map<String, Object?> _draft(HousingDraft d) => {
    'address': ?d.address,
    'contact': d.contact,
    'body': d.body,
    'show_username': d.showUsername,
    'contact_username': d.showUsername ? d.username : '',
  };

  @override
  Future<HousingPost> create(Map<String, String> auth, HousingDraft draft) async =>
      HousingPost.fromJson((await _call('POST', 'posts', auth: auth, body: _draft(draft)))['post'], full: true)!;

  @override
  Future<HousingPost> edit(Map<String, String> auth, int id, HousingDraft draft) async => HousingPost.fromJson(
    (await _call('POST', 'posts/$id/edit', auth: auth, body: _draft(draft)..remove('address')))['post'],
    full: true,
  )!;

  @override
  Future<void> delete(Map<String, String> auth, int id) => _call('DELETE', 'posts/$id', auth: auth);

  @override
  Future<int> extend(Map<String, String> auth, int id) async =>
      _int((await _call('POST', 'posts/$id/extend', auth: auth))['days_left']) ?? 30;

  @override
  Future<List<HousingAlert>> alerts(Map<String, String> auth) async => [
    for (final a in ((await _call('GET', 'alerts', auth: auth))['alerts'] as List?) ?? const []) ?HousingAlert.fromJson(a),
  ];

  @override
  Future<void> addAlert(Map<String, String> auth, String address, int radiusKm) =>
      _call('POST', 'alerts', auth: auth, body: {'address': address, 'radius_km': radiusKm});

  @override
  Future<void> deleteAlert(Map<String, String> auth, int id) => _call('DELETE', 'alerts/$id', auth: auth);

  @override
  Future<String?> username(Map<String, String> auth) async => _text((await _call('GET', 'me', auth: auth))['username']);

  Future<Map<String, dynamic>> _call(
    String method,
    String path, {
    Map<String, String>? auth,
    Map<String, String>? query,
    Object? body,
  }) async {
    var url = AppConfig.apiBase.resolve('api/housing/$path');
    if (query != null) url = url.replace(queryParameters: query);
    final request = http.Request(method, url)
      ..headers.addAll(auth ?? const {})
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(const Duration(seconds: 30)));
    } on SocketException {
      throw const HousingException('offline');
    } on http.ClientException {
      throw const HousingException('offline');
    } on TimeoutException {
      throw const HousingException('offline');
    }
    Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      json = null;
    }
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    if (response.statusCode >= 400) {
      final fields = map['fields'];
      throw HousingException(
        map['error'] as String? ?? 'http_${response.statusCode}',
        status: response.statusCode,
        fields: {
          if (fields is Map)
            for (final e in fields.entries) '${e.key}': '${e.value}',
        },
        retryAfter: _int(map['retry_after']),
      );
    }
    return map;
  }
}
