import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
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

/// "34 ta masjid", "34 мечети", "34 mosques".
String kindCount(AppLocalizations s, PlaceKind kind, int n) => switch (kind) {
      PlaceKind.mosque => s.plCountMosques(n),
      PlaceKind.restaurant => s.plCountRestaurants(n),
      PlaceKind.shop => s.plCountShops(n),
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

/// A place's picture in a list: its first photo, or its kind on its colour.
class PlaceThumb extends StatelessWidget {
  const PlaceThumb({super.key, required this.kit, required this.place, this.size = 58});

  final PlacesKit kit;
  final Place place;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colour = kindColour(context, place.kind);
    final photos = kit.photosOf(place);
    final tile = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text(place.kind.emoji, style: TextStyle(fontSize: size * 0.46)),
    );
    if (photos.isEmpty) return tile;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.network(
        '${photos.first.thumb}',
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, _, _) => tile,
        frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : tile,
      ),
    );
  }
}

/// A small rounded action under a place: call, directions.
class PlaceMiniAction extends StatelessWidget {
  const PlaceMiniAction({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Material(
      color: p.cardSelected,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: p.accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.accent),
                ),
              ),
            ],
          ),
        ),
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
