import '../../core/config.dart';

/// A kind of business (pages/business: /api/business/categories).
class BizCategory {
  const BizCategory({required this.id, required this.slug, required this.name, this.icon, this.count = 0});

  final String id;
  final String slug;
  final String name;

  /// An emoji, from the database.
  final String? icon;

  final int count;

  static BizCategory? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id']?.toString();
    final name = json['name']?.toString().trim();
    if (id == null || name == null || name.isEmpty) return null;
    return BizCategory(
      id: id,
      slug: json['slug']?.toString() ?? '',
      name: name,
      icon: json['icon']?.toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() => {'id': id, 'slug': slug, 'name': name, 'icon': icon, 'count': count};
}

/// The web page's order for the directory, by slug: related kinds in pairs
/// (food, home, papers, study, the rest), each pair by how many need it and
/// how often. A category not listed goes after them.
const _categoryRank = {
  'halal-market': 1,
  'pishiriqlar': 2,
  'pochta': 3,
  'aviakassa': 4,
  'tarjima': 5,
  'sugurta': 6,
  'consulting': 7,
  'repetitor': 8,
  'sim-telefon': 9,
  'kosmetika': 10,
};

/// Empty categories sink as a group; otherwise the page's own order, then
/// the name. Sorting by count would reshuffle the grid on every approval.
int byCategoryOrder(BizCategory a, BizCategory b) {
  if ((a.count == 0) != (b.count == 0)) return a.count == 0 ? 1 : -1;
  final ra = _categoryRank[a.slug] ?? 99;
  final rb = _categoryRank[b.slug] ?? 99;
  if (ra != rb) return ra - rb;
  return a.name.compareTo(b.name);
}

/// One way to reach a business: a phone number or a link, by kind.
class BizLink {
  const BizLink(this.kind, this.value);

  final String kind;
  final String value;

  static BizLink? fromJson(Object? json) {
    if (json is! Map) return null;
    final kind = json['kind']?.toString();
    final value = json['value']?.toString().trim();
    if (kind == null || value == null || value.isEmpty || !_contactRank.containsKey(kind)) return null;
    return BizLink(kind, value);
  }

  Map<String, Object?> toJson() => {'kind': kind, 'value': value};

  bool get isPhone => kind == 'phone';

  /// Where a tap goes: the dialler for a phone, otherwise the link itself,
  /// and only when it is a web address.
  Uri? get target {
    if (isPhone) return Uri(scheme: 'tel', path: value.replaceAll(RegExp(r'[^\d+]'), ''));
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http') ? uri : null;
  }

  /// What is printed with it: the number, a handle, a site's host; nothing
  /// for an app store listing, whose address names nothing.
  String display({required String privateGroup}) {
    if (isPhone) return value;
    if (kind == 'appstore' || kind == 'playstore') return '';
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return value;
    if (kind == 'website') return uri.host.replaceFirst(RegExp(r'^www\.'), '');
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.isEmpty) return uri.host;
    if (kind == 'youtube' || kind == 'facebook') return _pageName(segs, uri);
    // A private invite carries a token, not a name.
    if ((kind == 'telegram' || kind == 'tgchannel') && (segs.first.startsWith('+') || segs.first == 'joinchat')) {
      return privateGroup;
    }
    return '@${segs.first.replaceFirst(RegExp(r'^@'), '')}';
  }

  /// YouTube and Facebook addresses are mostly not a name (/channel/UC3x…,
  /// /profile.php?id=…); only a real handle is printed.
  String _pageName(List<String> segs, Uri uri) {
    if (kind == 'youtube') {
      if (uri.host == 'youtu.be') return '';
      if (segs.first.startsWith('@')) return segs.first;
      if ((segs.first == 'c' || segs.first == 'user') && segs.length > 1) return '@${segs[1]}';
      return '';
    }
    const notNames = {'profile.php', 'groups', 'pages', 'people', 'share', 'watch', 'events'};
    if (notNames.contains(segs.first) || RegExp(r'^\d+$').hasMatch(segs.first)) return '';
    return '@${segs.first}';
  }
}

/// Contacts first, the app stores last.
const _contactRank = {
  'phone': 1,
  'telegram': 2,
  'kakao': 3,
  'tgchannel': 4,
  'website': 5,
  'instagram': 6,
  'tiktok': 7,
  'youtube': 8,
  'facebook': 9,
  'playstore': 10,
  'appstore': 11,
};

/// A business's links, split as the web page splits them: the two ways one
/// would actually reach it as large buttons, the rest as a list.
///
/// A channel or a YouTube page is followed, not written to, so it takes a
/// button only when there is nothing else. The two app stores are one app in
/// two places: either both lead or both wait below.
({List<BizLink> primary, List<BizLink> rest}) splitLinks(List<BizLink> links) {
  final sorted = [...links]..sort((a, b) => _contactRank[a.kind]! - _contactRank[b.kind]!);
  const follow = {'tgchannel', 'youtube'};
  const store = {'appstore', 'playstore'};
  var pool = sorted.where((l) => !follow.contains(l.kind)).toList();
  if (pool.isEmpty) pool = sorted;
  var n = pool.length < 2 ? pool.length : 2;
  if (n > 0 && n < pool.length && store.contains(pool[n - 1].kind) && store.contains(pool[n].kind)) n--;
  final primary = pool.sublist(0, n);
  return (primary: primary, rest: [for (final l in sorted) if (!primary.contains(l)) l]);
}

/// A listed business. From a list it has what a row needs; opened, its
/// links and description too.
class Business {
  const Business({
    required this.id,
    required this.name,
    this.logo,
    this.description,
    this.likes = 0,
    this.views,
    this.categoryId,
    this.categoryName,
    this.links = const [],
  });

  final String id;
  final String name;

  /// A path on the API.
  final String? logo;
  final String? description;
  final int likes;

  /// Times the listing was opened; the server has called it `views` and
  /// `taps`.
  final int? views;
  final String? categoryId;
  final String? categoryName;
  final List<BizLink> links;

  Uri? get logoUrl {
    final path = logo?.trim().replaceFirst(RegExp(r'^/+'), '');
    if (path == null || path.isEmpty) return null;
    return path.startsWith('http') ? Uri.tryParse(path) : AppConfig.apiBase.resolve(path);
  }

  /// The description as a row previews it: its lines run on with a dot
  /// between them, its links taken out (nobody taps a link in a two-line
  /// preview).
  String get preview => [
        for (final line in (description ?? '').replaceAll(urlPattern, '').split('\n'))
          if (line.replaceAll(RegExp(r'\s+'), ' ').trim() case final text when text.isNotEmpty && !RegExp(r'[:：]$').hasMatch(text))
            text,
      ].join(' · ');

  static int? _number(Object? value) => value is num ? value.toInt() : null;

  static Business? fromJson(Object? json, {String? categoryName}) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id']?.toString();
    final name = json['name']?.toString().trim();
    if (id == null || name == null || name.isEmpty) return null;
    final description = json['description']?.toString().trim();
    return Business(
      id: id,
      name: name,
      logo: json['logo']?.toString(),
      description: description == null || description.isEmpty ? null : description,
      likes: _number(json['likes']) ?? 0,
      views: _number(json['views']) ?? _number(json['taps']),
      categoryId: json['categoryId']?.toString() ?? json['category_id']?.toString(),
      categoryName: json['categoryName']?.toString() ?? categoryName,
      links: [for (final link in (json['links'] as List?) ?? const []) ?BizLink.fromJson(link)],
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'logo': logo,
        'description': description,
        'likes': likes,
        'views': views,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'links': [for (final l in links) l.toJson()],
      };
}

/// Medals for the top three of a category, by likes, and only where they
/// mean something: nobody wins with no likes, and equal likes share a place
/// (two silvers are followed by fourth, not bronze).
List<int?> ranksOf(List<Business> businesses) {
  var place = 0;
  int? previous;
  return [
    for (final (i, b) in businesses.indexed)
      () {
        if (b.likes != previous) {
          place = i + 1;
          previous = b.likes;
        }
        return b.likes > 0 && place <= 3 ? place : null;
      }(),
  ];
}

/// The directory: the categories, and what a listing costs.
class BizDirectory {
  const BizDirectory({required this.categories, this.listingFee});

  final List<BizCategory> categories;
  final int? listingFee;

  int get total => categories.fold(0, (n, c) => n + c.count);
}

/// A search's matches in one category.
class BizGroup {
  const BizGroup({required this.category, required this.total, required this.businesses});

  final BizCategory category;
  final int total;
  final List<Business> businesses;
}

/// Links written into a description: full addresses, www., and the social
/// hosts without one.
final urlPattern = RegExp(
  r'''(https?://[^\s<>"']+|www\.[^\s<>"']+|\b(?:t\.me|telegram\.me|instagram\.com|tiktok\.com|youtube\.com|youtu\.be|facebook\.com|fb\.me|(?:open|pf)\.kakao\.com|naver\.me)/[^\s<>"']+)''',
  caseSensitive: false,
);
