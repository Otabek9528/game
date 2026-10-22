import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/config.dart';

/// What went wrong talking to the cars server: `offline`, `http_<status>`,
/// `bad_response`.
class CarsException implements Exception {
  const CarsException(this.code, [this.status]);

  final String code;
  final int? status;

  @override
  String toString() => 'CarsException($code)';
}

int? _int(Object? v) => switch (v) {
      int() => v,
      num() => v.round(),
      String() => int.tryParse(v.trim()) ?? double.tryParse(v.trim())?.round(),
      _ => null,
    };

String? _text(Object? v) {
  final t = v is String ? v.trim() : v is num ? '$v' : null;
  return t == null || t.isEmpty ? null : t;
}

/// The server sends its media as "/media/…": on its own address.
Uri? mediaUri(Object? v) {
  final t = _text(v);
  if (t == null) return null;
  if (t.startsWith('/')) return AppConfig.apiBase.replace(path: t.split('?').first, query: t.contains('?') ? t.substring(t.indexOf('?') + 1) : null);
  final uri = Uri.tryParse(t);
  return uri != null && uri.hasScheme ? uri : null;
}

/// A photo or a video of a car, with its small picture.
@immutable
class CarMedia {
  const CarMedia({required this.video, this.url, this.thumb, this.sizeBytes});

  final bool video;
  final Uri? url;
  final Uri? thumb;
  final int? sizeBytes;

  static CarMedia? fromJson(Object? json) {
    if (json is! Map) return null;
    return CarMedia(
      video: json['type'] == 'video',
      url: mediaUri(json['url']),
      thumb: mediaUri(json['thumb']),
      sizeBytes: _int(json['size_bytes']),
    );
  }

  Map<String, Object?> toJson() =>
      {'type': video ? 'video' : 'photo', 'url': url?.toString(), 'thumb': thumb?.toString(), 'size_bytes': sizeBytes};
}

/// A car on sale (or sold), as read by the server from a channel post.
/// Lists bring the short form; [media] and the rest come with the full one.
@immutable
class Car {
  const Car({
    required this.id,
    this.brand,
    this.model,
    this.generation,
    this.year,
    this.priceKrw,
    this.negotiable = false,
    this.sold = false,
    this.mileageKm,
    this.transmission,
    this.fuel,
    this.postedRel,
    this.postedAt,
    this.photo,
    this.thumb,
    this.media,
    this.rawText,
    this.contact,
    this.contactHandle,
    this.legalStatus,
    this.registrationRequired,
    this.sourceName,
    this.views,
  });

  final int id;
  final String? brand;
  final String? model;
  final String? generation;
  final int? year;
  final int? priceKrw;
  final bool negotiable;
  final bool sold;
  final int? mileageKm;

  /// automatic, manual.
  final String? transmission;

  /// petrol, diesel, lpg, hybrid.
  final String? fuel;

  /// "2 kun oldin", as the server words it.
  final String? postedRel;
  final String? postedAt;
  final Uri? photo;
  final Uri? thumb;

  /// Null in a list's short form.
  final List<CarMedia>? media;
  final String? rawText;
  final String? contact;
  final String? contactHandle;

  /// legal, no_oformleniya.
  final String? legalStatus;
  final bool? registrationRequired;
  final String? sourceName;
  final int? views;

  bool get full => media != null;

  /// "Hyundai Sonata".
  String get name => [brand, model].whereType<String>().join(' ');

  static Car? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = _int(json['id']);
    if (id == null) return null;
    final media = json['media'];
    final registration = json['registration_required'];
    return Car(
      id: id,
      brand: _text(json['brand']),
      model: _text(json['model']),
      generation: _text(json['generation']),
      year: _int(json['year']),
      priceKrw: _int(json['price_krw']),
      negotiable: json['negotiable'] == true || json['negotiable'] == 1,
      sold: json['status'] == 'sold',
      mileageKm: _int(json['mileage_km']),
      transmission: _text(json['transmission']),
      fuel: _text(json['fuel']),
      postedRel: _text(json['posted_rel']),
      postedAt: _text(json['posted_at']),
      photo: mediaUri(json['photo']),
      thumb: mediaUri(json['thumb']),
      media: media is List ? [for (final m in media) ?CarMedia.fromJson(m)] : null,
      rawText: _text(json['raw_text']),
      contact: _text(json['contact']),
      contactHandle: _text(json['contact_handle'])?.replaceFirst(RegExp(r'^@'), ''),
      legalStatus: _text(json['legal_status']),
      registrationRequired: registration == null ? null : registration == true || registration == 1,
      sourceName: _text(json['source_name']),
      views: _int(json['views']),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'generation': generation,
        'year': year,
        'price_krw': priceKrw,
        'negotiable': negotiable,
        'status': sold ? 'sold' : 'active',
        'mileage_km': mileageKm,
        'transmission': transmission,
        'fuel': fuel,
        'posted_rel': postedRel,
        'posted_at': postedAt,
        'photo': photo?.toString(),
        'thumb': thumb?.toString(),
        if (media != null) 'media': [for (final m in media!) m.toJson()],
        'raw_text': rawText,
        'contact': contact,
        'contact_handle': contactHandle,
        'legal_status': legalStatus,
        'registration_required': registrationRequired,
        'source_name': sourceName,
        'views': views,
      };

  /// The short form kept, the full form's details over it (and a newer
  /// list's fields over a kept full form).
  Car mergedWith(Car newer) => Car(
        id: id,
        brand: newer.brand ?? brand,
        model: newer.model ?? model,
        generation: newer.generation ?? generation,
        year: newer.year ?? year,
        priceKrw: newer.priceKrw ?? priceKrw,
        negotiable: newer.negotiable,
        sold: newer.sold,
        mileageKm: newer.mileageKm ?? mileageKm,
        transmission: newer.transmission ?? transmission,
        fuel: newer.fuel ?? fuel,
        postedRel: newer.postedRel ?? postedRel,
        postedAt: newer.postedAt ?? postedAt,
        photo: newer.photo ?? photo,
        thumb: newer.thumb ?? thumb,
        media: newer.media ?? media,
        rawText: newer.rawText ?? rawText,
        contact: newer.contact ?? contact,
        contactHandle: newer.contactHandle ?? contactHandle,
        legalStatus: newer.legalStatus ?? legalStatus,
        registrationRequired: newer.registrationRequired ?? registrationRequired,
        sourceName: newer.sourceName ?? sourceName,
        views: newer.views ?? views,
      );

  Car withViews(int views) => mergedWith(Car(id: id, negotiable: negotiable, sold: sold, views: views));
}

/// A make, its listings, and its models with theirs.
@immutable
class CarBrand {
  const CarBrand({required this.brand, required this.total, required this.models});

  final String brand;
  final int total;
  final List<({String model, int count})> models;

  static CarBrand? fromJson(Object? json) {
    if (json is! Map) return null;
    final brand = _text(json['brand']);
    if (brand == null) return null;
    return CarBrand(
      brand: brand,
      total: _int(json['total']) ?? 0,
      models: [
        for (final m in (json['models'] as List?) ?? const [])
          if (m is Map && _text(m['model']) != null) (model: _text(m['model'])!, count: _int(m['count']) ?? 0),
      ],
    );
  }
}

/// A make, and one of its models or all of them ([model] null).
typedef CarPick = ({String brand, String? model});

/// "Hyundai_Sonata": a model's name in the channel's deep links.
String modelSlug(String brand, String model) => '${_slugify(brand)}_${_slugify(model)}';
String _slugify(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

/// What the filters ask the server for.
@immutable
class CarQuery {
  const CarQuery({this.pick, this.priceMax, this.mileageMax, this.yearFrom, this.fuels = const {}, this.status});

  final CarPick? pick;
  final int? priceMax;
  final int? mileageMax;
  final int? yearFrom;
  final Set<String> fuels;

  /// active, sold; null for both.
  final String? status;

  Map<String, String> get params => {
        if (pick != null) 'brand': pick!.brand,
        'model': ?pick?.model,
        if (priceMax != null) 'price_max': '$priceMax',
        if (mileageMax != null) 'mileage_max': '$mileageMax',
        if (yearFrom != null) 'year_from': '$yearFrom',
        if (fuels.isNotEmpty) 'fuel': fuels.join(','),
        'status': ?status,
      };
}

// ------------------------------------------------------------- the market

/// How a price sits against the going price: below, about, above.
enum Deal { low, mid, high }

/// Within 5% of [median] is about it.
Deal? dealOf(int? price, int? median) {
  if (price == null || median == null || median == 0) return null;
  final d = (price - median) / median;
  return d < -0.05 ? Deal.low : d > 0.05 ? Deal.high : Deal.mid;
}

/// The middle price (two middles averaged, rounded).
int? median(Iterable<int> prices) {
  final s = prices.toList()..sort();
  if (s.isEmpty) return null;
  final m = s.length >> 1;
  return s.length.isOdd ? s[m] : ((s[m - 1] + s[m]) / 2).round();
}

/// Prices of a set of cars: their middle, and the range without the odd
/// one out (Tukey's fences: a 15M among 2–4M doesn't stretch the scale).
@immutable
class PriceSpread {
  const PriceSpread({required this.n, this.med, this.lo, this.hi});

  final int n;
  final int? med;
  final int? lo;
  final int? hi;

  static const none = PriceSpread(n: 0);

  factory PriceSpread.of(Iterable<int> prices) {
    final s = prices.toList()..sort();
    final n = s.length;
    if (n == 0) return none;
    double quant(double p) {
      final i = (n - 1) * p, b = i.floor(), r = i - b;
      return b + 1 < n ? s[b] + r * (s[b + 1] - s[b]) : s[b].toDouble();
    }

    var lo = s.first, hi = s.last;
    if (n >= 4) {
      final q1 = quant(.25), q3 = quant(.75), iqr = q3 - q1;
      lo = math.max(s.first, (q1 - 1.5 * iqr).round());
      hi = math.min(s.last, (q3 + 1.5 * iqr).round());
      if (lo >= hi) (lo, hi) = (s.first, s.last);
    }
    return PriceSpread(n: n, med: median(s), lo: lo, hi: hi);
  }
}

/// A model's market: on sale and sold.
@immutable
class MarketStats {
  const MarketStats({required this.available, required this.sold, required this.countAvailable, required this.countSold});

  final PriceSpread available;
  final PriceSpread sold;
  final int countAvailable;
  final int countSold;

  static const empty = MarketStats(available: PriceSpread.none, sold: PriceSpread.none, countAvailable: 0, countSold: 0);

  factory MarketStats.of(List<Car> cars) => MarketStats(
        available: PriceSpread.of([for (final c in cars) if (!c.sold && c.priceKrw != null) c.priceKrw!]),
        sold: PriceSpread.of([for (final c in cars) if (c.sold && c.priceKrw != null) c.priceKrw!]),
        countAvailable: cars.where((c) => !c.sold).length,
        countSold: cars.where((c) => c.sold).length,
      );
}

/// [car] against cars of about its year (±1, then ±2) when four or more are
/// on sale: a 2009 car isn't judged by 2014 ones. Null when too few.
({PriceSpread spread, int years})? nearYears(Car car, List<Car> modelCars) {
  final year = car.year;
  if (year == null) return null;
  final base = [for (final c in modelCars) if (!c.sold && c.priceKrw != null && c.year != null) c];
  for (final w in [1, 2]) {
    final near = [for (final c in base) if ((c.year! - year).abs() <= w) c.priceKrw!];
    if (near.length >= 4) return (spread: PriceSpread.of(near), years: w);
  }
  return null;
}

/// How the list is ordered.
enum CarSort { newest, value, priceLow, priceHigh, mileageLow, yearNew }

/// Lower is a better buy: the price, with age and mileage added.
double valueScore(Car c, int thisYear) {
  if (c.priceKrw == null) return 1e9;
  final age = thisYear - (c.year ?? 2014);
  final mileage = (c.mileageKm ?? 150000) / 10000;
  return c.priceKrw! / 1e6 + age * 0.15 + mileage * 0.08;
}

List<Car> sortCars(List<Car> cars, CarSort sort, int thisYear) {
  final list = [...cars];
  switch (sort) {
    case CarSort.newest:
      break;
    case CarSort.value:
      list.sort((a, b) => valueScore(a, thisYear).compareTo(valueScore(b, thisYear)));
    case CarSort.priceLow:
      list.sort((a, b) => (a.priceKrw ?? 1 << 52).compareTo(b.priceKrw ?? 1 << 52));
    case CarSort.priceHigh:
      list.sort((a, b) => (b.priceKrw ?? -1).compareTo(a.priceKrw ?? -1));
    case CarSort.mileageLow:
      list.sort((a, b) => (a.mileageKm ?? 1000000000).compareTo(b.mileageKm ?? 1000000000));
    case CarSort.yearNew:
      list.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
  }
  return list;
}

// ------------------------------------------------------------- the words

/// "7 500 000 ₩".
String won(int? v) => v == null ? '—' : '${groupDigits(v)} ₩';

/// "7.5M".
String wonShort(int? v) {
  if (v == null) return '—';
  final m = (v / 1e6).toStringAsFixed(1);
  return '${m.endsWith('.0') ? m.substring(0, m.length - 2) : m}M';
}

/// "150k km".
String kmShort(int v) => v >= 1000 ? '${(v / 1000).round()}k km' : '$v km';

/// 7500000 → "7 500 000".
String groupDigits(Object v) => '$v'.replaceAll(RegExp(r'\D'), '').replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
