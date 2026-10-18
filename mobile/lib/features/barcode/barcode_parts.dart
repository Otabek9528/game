import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'barcode_models.dart';

/// How a verdict looks: its colour, icon and words.
class VerdictStyle {
  const VerdictStyle._(this.color, this.solid, this.icon);

  /// For icons, words and tints on the page.
  final Color color;

  /// Under white words (the answer's banner, the chosen tab): deep enough
  /// for them in both themes.
  final Color solid;

  final IconData icon;

  factory VerdictStyle.of(BuildContext context, Verdict verdict) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (verdict) {
      Verdict.joiz => VerdictStyle._(dark ? Brand.emerald400 : Brand.emerald600, Brand.emerald700, Icons.check_circle_rounded),
      Verdict.shubhali =>
        VerdictStyle._(dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706), const Color(0xFFB45309), Icons.error_rounded),
      Verdict.nojoiz =>
        VerdictStyle._(dark ? const Color(0xFFF87171) : const Color(0xFFDC2626), const Color(0xFFB91C1C), Icons.block_rounded),
    };
  }

  static String label(AppLocalizations s, Verdict verdict) => switch (verdict) {
        Verdict.joiz => s.barcodeVerdictJoiz,
        Verdict.shubhali => s.barcodeVerdictShubhali,
        Verdict.nojoiz => s.barcodeVerdictNojoiz,
      };

  static String description(AppLocalizations s, Verdict verdict) => switch (verdict) {
        Verdict.joiz => s.barcodeVerdictJoizDesc,
        Verdict.shubhali => s.barcodeVerdictShubhaliDesc,
        Verdict.nojoiz => s.barcodeVerdictNojoizDesc,
      };
}

/// The stores' logos, bundled as on the web page.
const _emblems = {
  'No Brand': 'nobrand.png',
  'Emart24': 'emart24.png',
  '7-Eleven': '7_11.png',
  'GS25': 'gs25.png',
  'CU': 'cu.png',
  'Daiso': 'daiso.png',
};

/// A store's logo on a white tile; its initials when there is none.
class StoreEmblem extends StatelessWidget {
  const StoreEmblem(this.store, {super.key, this.size = 44, this.padding = 6});

  final String store;
  final double size;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final file = _emblems[store];
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: p.hairline),
      ),
      alignment: Alignment.center,
      child: file == null
          ? Text(
              store.characters.take(2).toString().toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: size * 0.3, color: Brand.emerald700),
            )
          : Image.asset('assets/stores/$file', fit: BoxFit.contain),
    );
  }
}

/// A product's photo filling its frame (cropped, never with bars beside
/// it), or a parcel icon when there is none or it won't load.
class ProductPhoto extends StatelessWidget {
  const ProductPhoto(this.product, {super.key, this.iconSize = 34});

  final Product product;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final url = product.imageUrl;
    final placeholder = ColoredBox(
      color: p.cardSelected,
      child: Center(child: Icon(Icons.inventory_2_outlined, size: iconSize, color: p.inkMuted)),
    );
    if (url == null) return placeholder;
    return LayoutBuilder(
      builder: (context, constraints) {
        ImageProvider image = NetworkImage(url.toString());
        // Decoded near the size shown, not at the photo's own: a phone photo
        // is 1080×1920, and a store's list of them at full size scrolls
        // slowly and fills the memory. Twice the frame's long side, so a
        // photo of any shape still covers the frame sharply.
        if (constraints.biggest.isFinite) {
          final side = (constraints.biggest.longestSide * MediaQuery.devicePixelRatioOf(context) * 2).round();
          image = ResizeImage(image, width: side, height: side, policy: ResizeImagePolicy.fit);
        }
        return Image(
          image: image,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => placeholder,
          frameBuilder: (context, child, frame, sync) =>
              frame == null && !sync ? ColoredBox(color: p.cardSelected) : child,
        );
      },
    );
  }
}

/// The API's category names, in the app's language, with an icon each.
(IconData, String) categoryLook(AppLocalizations s, String category) => switch (category) {
      'Drinks' => (Icons.local_drink_rounded, s.barcodeCatDrinks),
      'Snacks' => (Icons.fastfood_rounded, s.barcodeCatSnacks),
      'Sweets' => (Icons.cake_rounded, s.barcodeCatSweets),
      'Ice Cream' => (Icons.icecream_rounded, s.barcodeCatIceCream),
      'Baked Goods' => (Icons.bakery_dining_rounded, s.barcodeCatBaked),
      'Cup Noodles/Ramen' => (Icons.ramen_dining_rounded, s.barcodeCatNoodles),
      'Lunchbox/Dosirak' => (Icons.cookie_rounded, s.barcodeCatLunchbox),
      'Dairy' => (Icons.water_drop_rounded, s.barcodeCatDairy),
      'Canned Food' => (Icons.inventory_rounded, s.barcodeCatCanned),
      'Frozen Food' => (Icons.ac_unit_rounded, s.barcodeCatFrozen),
      'Condiments/Sauces' => (Icons.soup_kitchen_rounded, s.barcodeCatSauces),
      'Fruits/Vegetables' => (Icons.eco_rounded, s.barcodeCatFruits),
      'Dried Food' => (Icons.grass_rounded, s.barcodeCatDried),
      _ => (Icons.category_rounded, category),
    };

/// [text] with its `*starred*` parts in bold.
TextSpan starredText(String text, TextStyle style) => TextSpan(
      style: style,
      children: [
        for (final (i, part) in text.split('*').indexed)
          TextSpan(text: part, style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w800) : null),
      ],
    );
