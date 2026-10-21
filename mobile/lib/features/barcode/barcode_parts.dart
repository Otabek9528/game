import 'package:flutter/material.dart';

import '../../core/config.dart';
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

/// A store's logo file, its shape (width over height), and its own
/// background colour when it has one.
class _Logo {
  const _Logo(this.file, this.aspect, [this.background]);

  final String file;
  final double aspect;
  final Color? background;
}

/// The stores' logos, bundled as on the web page; trimmed of their margins
/// (and 7-Eleven of the checkerboard drawn into it).
const _logos = {
  'No Brand': _Logo('nobrand.png', 1, Color(0xFFFDB316)),
  'Emart24': _Logo('emart24.png', 5.04),
  '7-Eleven': _Logo('7_11.png', 5.58),
  'GS25': _Logo('gs25.png', 3.16),
  'CU': _Logo('cu.png', 1.61, Color(0xFF652D8E)),
  'Daiso': _Logo('daiso.png', 0.9),
};

/// A store's logo in a frame shaped to it: [height] tall and as wide as the
/// logo wants, up to [maxWidth]; or exactly [width]. A logo with a colour of
/// its own fills the frame in that colour, edge to edge; the others sit on
/// white. Initials when there is no logo.
class StoreEmblem extends StatelessWidget {
  const StoreEmblem(this.store, {super.key, this.height = 44, this.width, this.maxWidth});

  final String store;
  final double height;
  final double? width;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final logo = _logos[store];
    final background = logo?.background;
    return Container(
      width: width ?? (height * (logo?.aspect ?? 1)).clamp(height, maxWidth ?? height * 2.6),
      height: height,
      padding: background == null
          ? EdgeInsets.symmetric(horizontal: height * 0.16, vertical: height * 0.18)
          : EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background ?? Colors.white,
        borderRadius: BorderRadius.circular(height * 0.24),
        border: background == null ? Border.all(color: p.hairline) : null,
      ),
      alignment: Alignment.center,
      child: logo == null
          ? Text(
              store.characters.take(2).toString().toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: height * 0.32, color: Brand.emerald700),
            )
          : Image.asset('assets/stores/${logo.file}', fit: BoxFit.contain),
    );
  }
}

/// How big a product photo is fetched.
enum PhotoSize {
  /// Cards and thumbnails: 600 px on the short side, sharp across a card.
  card,

  /// Full screen: 1600 px wide, room to zoom.
  full,
}

/// Where [original] is fetched at [size]: through [AppConfig.photoService],
/// tens of kilobytes for a card instead of the original's hundreds or
/// thousands; or, [direct], from the API itself, decoded near the size
/// shown so a long list doesn't fill the memory.
ImageProvider productImage(Uri original, PhotoSize size, {bool direct = false}) {
  if (direct) {
    final image = NetworkImage('$original');
    return size == PhotoSize.full
        ? image
        : ResizeImage(image, width: 1000, height: 1000, policy: ResizeImagePolicy.fit);
  }
  final shape = switch (size) {
    PhotoSize.card => 'w=600&h=600&fit=outside&q=72',
    PhotoSize.full => 'w=1600&q=82',
  };
  // `we`: never enlarged past the original.
  return NetworkImage('${AppConfig.photoService}?url=${Uri.encodeComponent('$original')}&$shape&we&output=webp');
}

/// A product photo at [size], from [AppConfig.photoService] or else from
/// the API: [loading] until it arrives (then it fades in), [placeholder] if
/// neither can give it.
class NetworkPhoto extends StatefulWidget {
  const NetworkPhoto(
    this.url, {
    super.key,
    required this.size,
    required this.placeholder,
    this.loading,
    this.fit = BoxFit.cover,
  });

  final Uri url;
  final PhotoSize size;
  final Widget placeholder;
  final Widget? loading;
  final BoxFit fit;

  @override
  State<NetworkPhoto> createState() => _NetworkPhotoState();
}

class _NetworkPhotoState extends State<NetworkPhoto> {
  /// Photos the service failed and the API then gave. After two, the
  /// service is skipped for the rest of the session: it is the service, not
  /// the photos.
  static int _serviceMisses = 0;

  late bool _direct = _serviceMisses >= 2;
  bool _fellBack = false;

  @override
  void didUpdateWidget(NetworkPhoto old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url || old.size != widget.size) {
      _direct = _serviceMisses >= 2;
      _fellBack = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = widget.loading ?? const SizedBox.expand();
    return Image(
      image: productImage(widget.url, widget.size, direct: _direct),
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, sync) {
        if (sync) return child;
        if (frame != null && _fellBack) {
          _fellBack = false;
          _serviceMisses++;
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            loading,
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 220),
              child: child,
            ),
          ],
        );
      },
      errorBuilder: (context, _, _) {
        if (_direct) return widget.placeholder;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _direct = true;
              _fellBack = true;
            });
          }
        });
        return loading;
      },
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
    return NetworkPhoto(
      url,
      size: PhotoSize.card,
      placeholder: placeholder,
      loading: ColoredBox(color: p.cardSelected),
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
