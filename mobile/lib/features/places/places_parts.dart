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

/// A photo on its way: a spinner, and after a moment why it may take a
/// while. On the kind's colour in a card ([kind]), or on black full screen.
class PhotoLoading extends StatelessWidget {
  const PhotoLoading({super.key, this.kind});

  final PlaceKind? kind;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final kind = this.kind;
    final colour = kind == null ? null : kindColour(context, kind);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: colour == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(colour, Colors.black, 0.6)!, Color.lerp(colour, Colors.black, 0.35)!],
              ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (colour != null) CustomPaint(painter: KhatamLatticePainter(color: Colors.white.withValues(alpha: 0.06))),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.plPhotoLoading,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  // Only once it's taking a moment.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1600),
                    curve: const Interval(0.55, 1),
                    builder: (_, opacity, child) => Opacity(opacity: opacity, child: child),
                    child: Text(
                      s.plPhotoLoadingSpeed,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, height: 1.3, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo layers over each other, each faded in when it arrives, and
/// whether one is on screen yet ([shown]) or all failed ([failed]).
mixin PhotoLayers<T extends StatefulWidget> on State<T> {
  bool shown = false;
  bool failed = false;

  void _mark({bool shown = false, bool failed = false}) {
    if (!(shown && !this.shown) && !(failed && !this.failed)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        this.shown |= shown;
        this.failed |= failed;
      });
    });
  }

  /// [image], faded in; [onError] in its place if it can't be had.
  Widget layer(ImageProvider image, BoxFit fit, Widget Function() onError) => Image(
        image: image,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => onError(),
        frameBuilder: (_, child, frame, sync) {
          if (frame != null) _mark(shown: true);
          return sync
              ? child
              : AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 220), child: child);
        },
      );

  /// None of the layers could be had: [instead] unless one is shown.
  Widget layersFailed(Widget instead) {
    _mark(failed: true);
    return shown ? const SizedBox.shrink() : instead;
  }
}

/// A photo as wide as the screen: [PhotoLoading] until the small copy is
/// there, the large one faded in over it; the original if the large copy
/// can't be had, the kind's picture if nothing can. Decoded at the
/// screen's width, so a card's photo and the place page's are one image,
/// loaded once.
class PlaceImage extends StatefulWidget {
  const PlaceImage({super.key, required this.photo, required this.kind});

  final PlacePhoto photo;
  final PlaceKind kind;

  /// The large copy at the screen's width.
  static ImageProvider full(BuildContext context, PlacePhoto photo) => _screenWide(context, photo.full);

  /// The original at the screen's width: when the large copy failed.
  static ImageProvider original(BuildContext context, PlacePhoto photo) => _screenWide(context, photo.original);

  static ImageProvider _screenWide(BuildContext context, Uri url) => ResizeImage(
        NetworkImage('$url'),
        width: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round(),
      );

  @override
  State<PlaceImage> createState() => _PlaceImageState();
}

class _PlaceImageState extends State<PlaceImage> with PhotoLayers {
  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    Widget none() => layersFailed(PlaceBackdrop(kind: widget.kind));
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!shown && !failed) PhotoLoading(kind: widget.kind),
        layer(NetworkImage('${photo.thumb}'), BoxFit.cover, () => const SizedBox.shrink()),
        layer(
          PlaceImage.full(context, photo),
          BoxFit.cover,
          () => photo.original == photo.full ? none() : layer(PlaceImage.original(context, photo), BoxFit.cover, none),
        ),
      ],
    );
  }
}

/// A place's photos, swiped through, with dots ([counter]: "1 / 3"
/// instead); a tap on one gives its number. Only the photo on screen and
/// the next are loaded. Its kind on its colour when it has none.
class PlacePhotos extends StatefulWidget {
  const PlacePhotos({super.key, required this.kit, required this.place, this.onPhoto, this.counter = false, this.inset = 0});

  final PlacesKit kit;
  final Place place;
  final ValueChanged<int>? onPhoto;
  final bool counter;

  /// How much of the bottom is covered (the place page's rounded edge).
  final double inset;

  @override
  State<PlacePhotos> createState() => _PlacePhotosState();
}

class _PlacePhotosState extends State<PlacePhotos> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.kit.photosOf(widget.place);
    final kind = widget.place.kind;
    if (photos.isEmpty) return widget.kit.photosPending(widget.place) ? PhotoLoading(kind: kind) : PlaceBackdrop(kind: kind);
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
            child: PlaceImage(photo: photos[i], kind: kind),
          ),
        ),
        if (photos.length > 1 && widget.counter)
          Positioned(
            right: 12,
            bottom: 12 + widget.inset,
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
            bottom: 10 + widget.inset,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: p.hairline)),
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
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: p.ink)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
