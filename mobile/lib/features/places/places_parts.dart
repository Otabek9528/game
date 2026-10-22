import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import 'places_kit.dart';
import 'places_models.dart';

/// Each kind's colour: emerald mosques, gold restaurants, terracotta shops
/// (the web app's).
Color kindColour(BuildContext context, PlaceKind kind) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (kind) {
    PlaceKind.mosque => dark ? const Color(0xFF10B981) : const Color(0xFF059669),
    PlaceKind.restaurant => dark ? const Color(0xFFEAB932) : const Color(0xFFA9790A),
    PlaceKind.shop => dark ? const Color(0xFFE2865F) : const Color(0xFFC8603A),
  };
}

/// "Masjidlar", "Мечети", "Mosques".
String kindPlural(AppLocalizations s, PlaceKind kind) => switch (kind) {
      PlaceKind.mosque => s.featureMosques,
      PlaceKind.restaurant => s.featureRestaurants,
      PlaceKind.shop => s.featureShops,
    };

/// "650 m", "2.4 km", "23 km".
String distanceText(AppLocalizations s, double km) {
  if (km < 1) return s.plMetres('${((km * 1000) / 10).round() * 10}');
  if (km < 10) return s.plKm(km.toStringAsFixed(1));
  return s.plKm('${km.round()}');
}

/// What to tell someone when [code] came back.
String placesMessage(AppLocalizations s, String code) => switch (code) {
      'offline' => s.plErrNetwork,
      'sign_in_required' || 'no_session' || 'bad_session' => s.plErrSignIn,
      'too_many_reviews' => s.plErrTooManyReviews,
      'text_too_long' || 'too_long' => s.plErrTooLong,
      'too_short' => s.plErrTooShort,
      'text_empty' || 'empty' => s.plTextEmpty,
      'wrong_host' => s.plErrWrongHost,
      'invalid_handle' => s.plErrHandle,
      'invalid_url' || 'invalid_scheme' => s.plErrUrl,
      'incomplete' || 'invalid_invite' => s.plErrIncomplete,
      'not_a_profile' => s.plErrNotProfile,
      'already_pending' => s.plErrPending,
      'same_as_current' => s.plErrSame,
      'rate_limited' => s.plErrRateLimited,
      'place_not_found' || 'http_404' => s.plErrGone,
      'not_owner' => s.plErrNotOwner,
      'has_owner' => s.plErrHasOwner,
      'too_many_pending' => s.plErrTooManyPending,
      'invalid_rating' => s.plReviewPick,
      _ => s.plErrGeneric,
    };

void showPlacesSnack(BuildContext context, String text, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), action: action, behavior: SnackBarBehavior.floating));
}

/// Five stars, halves included: [rating] of 5.
class PlaceStars extends StatelessWidget {
  const PlaceStars(this.rating, {super.key, this.size = 15});

  final double rating;
  final double size;

  static Color colour(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFFC531) : const Color(0xFFF5A700);

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final gold = colour(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i - 0.25
                ? Icons.star_rounded
                : rating >= i - 0.75
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: size,
            color: rating >= i - 0.75 ? gold : p.hairlineStrong,
          ),
      ],
    );
  }
}

/// A photo as wide as the screen: the small copy at once, the large one
/// faded in over it. Decoded at the screen's width, so a card's photo and
/// the place page's are one image, loaded once.
class PlaceImage extends StatelessWidget {
  const PlaceImage({super.key, required this.photo, required this.fallback});

  final PlacePhoto photo;
  final Widget fallback;

  /// The large copy at the screen's width.
  static ImageProvider full(BuildContext context, PlacePhoto photo) => ResizeImage(
        NetworkImage('${photo.full}'),
        width: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round(),
      );

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            '${photo.thumb}',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
            frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : fallback,
          ),
          Image(
            image: full(context, photo),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
            frameBuilder: (_, child, frame, sync) => sync
                ? child
                : AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 220), child: child),
          ),
        ],
      );
}

/// A place's photos, swiped through, with dots ([counter]: "1 / 3"
/// instead); a tap on one gives its number. Only the photo on screen and
/// the next are loaded. Its kind on its colour when it has none.
class PlacePhotos extends StatefulWidget {
  const PlacePhotos({super.key, required this.kit, required this.place, this.onPhoto, this.counter = false});

  final PlacesKit kit;
  final Place place;
  final ValueChanged<int>? onPhoto;
  final bool counter;

  @override
  State<PlacePhotos> createState() => _PlacePhotosState();
}

class _PlacePhotosState extends State<PlacePhotos> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.kit.photosOf(widget.place);
    final backdrop = PlaceBackdrop(kind: widget.place.kind);
    if (photos.isEmpty) return backdrop;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: photos.length,
          onPageChanged: (i) {
            setState(() => _index = i);
            // The one after, ready before it is swiped to.
            if (i + 1 < photos.length) precacheImage(PlaceImage.full(context, photos[i + 1]), context).ignore();
          },
          itemBuilder: (context, i) => GestureDetector(
            onTap: widget.onPhoto == null ? null : () => widget.onPhoto!(i),
            child: PlaceImage(photo: photos[i], fallback: backdrop),
          ),
        ),
        if (photos.length > 1 && widget.counter)
          Positioned(
            right: 12,
            bottom: 12,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    AppLocalizations.of(context).plPhotoCount('${_index + 1}', '${photos.length}'),
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          )
        else if (photos.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < photos.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: i == _index ? 1 : 0.6),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 3)],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A place's kind on its colour, in tilework: where its photo goes.
class PlaceBackdrop extends StatelessWidget {
  const PlaceBackdrop({super.key, required this.kind});

  final PlaceKind kind;

  @override
  Widget build(BuildContext context) {
    final colour = kindColour(context, kind);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(colour, Colors.black, 0.35)!, colour],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: KhatamLatticePainter(color: Colors.white.withValues(alpha: 0.08))),
          Center(child: Text(kind.emoji, style: const TextStyle(fontSize: 56))),
        ],
      ),
    );
  }
}

/// A white card with a hairline edge.
class PlacesCard extends StatelessWidget {
  const PlacesCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(14), this.color});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Material(
      color: color ?? p.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: p.hairline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// A section's title on a place page.
class PlacesHeading extends StatelessWidget {
  const PlacesHeading(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
