import '../../core/config.dart';

/// The check's answer for a product, as the API names it.
enum Verdict {
  joiz,
  shubhali,
  nojoiz;

  /// Anything unknown reads as [joiz], as on the web page.
  static Verdict parse(Object? value) => switch ('$value'.toLowerCase()) {
        'nojoiz' => nojoiz,
        'shubhali' => shubhali,
        _ => joiz,
      };
}

/// A product from the halal database (pages/barcode: /api/v2/product,
/// /api/v2/store/…/products).
class Product {
  const Product({
    required this.barcode,
    required this.verdict,
    this.name,
    this.nameEnglish,
    this.image,
    this.pork = false,
    this.alcohol = false,
    this.meat = false,
    this.seafood = false,
    this.ambiguous = false,
    this.sameFactory,
    this.ingredients,
    this.category,
    this.source,
    this.store,
    this.otherStores = const [],
  });

  final String barcode;
  final Verdict verdict;
  final String? name;
  final String? nameEnglish;

  /// The photo; the API gives some as paths on itself (`/api/…`).
  final String? image;

  final bool pork;
  final bool alcohol;

  /// Meat other than pork; seafood.
  final bool meat;
  final bool seafood;

  /// An ingredient that may come from plants or animals (shortening,
  /// flavouring, glycerin…).
  final bool ambiguous;

  /// Made in a factory that also makes prohibited products; null: unknown.
  final bool? sameFactory;

  final String? ingredients;

  /// The API's English category name (`Drinks`, `Cup Noodles/Ramen`, …).
  final String? category;

  /// `store_products` (checked in [store]) or `general`.
  final String? source;
  final String? store;

  /// Other stores that sell it.
  final List<String> otherStores;

  String get title => [name, nameEnglish].firstWhere((n) => n != null && n.trim().isNotEmpty, orElse: () => barcode)!;

  /// The photo's full address.
  Uri? get imageUrl {
    final path = image?.trim();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('/')) return AppConfig.apiBase.resolve(path.substring(1));
    return Uri.tryParse(path);
  }

  bool get hasIngredients => ingredients != null && ingredients!.trim().isNotEmpty;

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  factory Product.fromJson(Map<String, dynamic> json, {String? barcode}) => Product(
        barcode: _text(json['barcode']) ?? barcode ?? '',
        verdict: Verdict.parse(json['verdict']),
        name: _text(json['name']),
        nameEnglish: _text(json['nameEnglish']),
        image: _text(json['image']),
        pork: json['pork'] == true,
        alcohol: json['alcohol'] == true,
        meat: json['meat'] == true,
        seafood: json['seafood'] == true,
        ambiguous: json['ambiguousIngredient'] == true,
        sameFactory: json['sameFactory'] is bool ? json['sameFactory'] as bool : null,
        ingredients: _text(json['ingredients']),
        category: _text(json['category']),
        source: _text(json['source']),
        store: _text(json['store']),
        otherStores: [
          for (final other in (json['otherStores'] as List?) ?? const [])
            ?_text(other is Map ? other['store'] : other),
        ],
      );

  Map<String, Object?> toJson() => {
        'barcode': barcode,
        'verdict': verdict.name,
        'name': name,
        'nameEnglish': nameEnglish,
        'image': image,
        'pork': pork,
        'alcohol': alcohol,
        'meat': meat,
        'seafood': seafood,
        'ambiguousIngredient': ambiguous,
        'sameFactory': sameFactory,
        'ingredients': ingredients,
        'category': category,
        'source': source,
        'store': store,
        'otherStores': [for (final store in otherStores) {'store': store}],
      };
}

/// A store on the landing page, with how many of its products are checked.
class StoreSummary {
  const StoreSummary({required this.store, required this.count});

  final String store;
  final int count;

  /// Too few products to be much use yet: shown greyed, "soon".
  bool get isSoon => count < 10;

  static StoreSummary? fromJson(Map<String, dynamic> json) {
    final store = json['store']?.toString().trim();
    if (store == null || store.isEmpty) return null;
    return StoreSummary(store: store, count: (json['count'] as num?)?.toInt() ?? 0);
  }
}

/// A store's counts, for its tabs and categories.
class StoreMeta {
  const StoreMeta({required this.total, required this.byVerdict, required this.categories});

  final int total;
  final Map<Verdict, int> byVerdict;

  /// Each category with its counts per verdict, in the API's order.
  final List<(String, Map<Verdict, int>)> categories;

  static Map<Verdict, int> _counts(Object? json) => {
        for (final v in Verdict.values) v: ((json as Map?)?[v.name] as num?)?.toInt() ?? 0,
      };

  factory StoreMeta.fromJson(Map<String, dynamic> json) => StoreMeta(
        total: (json['total'] as num?)?.toInt() ?? 0,
        byVerdict: _counts(json['byVerdict']),
        categories: [
          for (final cat in (json['byCategory'] as List?) ?? const [])
            if (cat is Map && cat['category'] != null) ('${cat['category']}', _counts(cat['byVerdict'])),
        ],
      );
}

/// One page of a store's products.
class ProductPage {
  const ProductPage({required this.products, required this.total, required this.hasMore});

  final List<Product> products;
  final int total;
  final bool hasMore;
}

/// What is wrong with a typed barcode.
enum CodeProblem { empty, nonDigit, length, checksum }

/// The web page's check for a typed code: digits only, 8 to 14 of them, and
/// for EAN-8, UPC-A and EAN-13 a correct check digit.
CodeProblem? checkTypedCode(String raw) {
  final code = raw.trim();
  if (code.isEmpty) return CodeProblem.empty;
  if (!RegExp(r'^\d+$').hasMatch(code)) return CodeProblem.nonDigit;
  if (code.length < 8 || code.length > 14) return CodeProblem.length;
  if ((code.length == 8 || code.length == 12 || code.length == 13) && !hasValidCheckDigit(code)) {
    return CodeProblem.checksum;
  }
  return null;
}

/// GS1 check digit: from the right, data digits weigh 3, 1, 3, …
bool hasValidCheckDigit(String code) {
  final digits = code.codeUnits.map((c) => c - 0x30).toList();
  final check = digits.removeLast();
  var sum = 0;
  var weight = 3;
  for (final digit in digits.reversed) {
    sum += digit * weight;
    weight = weight == 3 ? 1 : 3;
  }
  return (10 - sum % 10) % 10 == check;
}
