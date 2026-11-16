import 'package:flutter/widgets.dart';

/// Distances between things, on a 4-point grid. New code takes its paddings
/// and gaps from here instead of writing a number.
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 32;

  /// The page's side margin.
  static const double page = 16;
}

/// Corner radii by what they round.
abstract final class Corner {
  /// Chips, small tiles, the inside of a card.
  static const double sm = 12;

  /// Buttons and fields.
  static const double md = 16;

  /// Cards.
  static const double lg = 18;

  /// Sheets and the big hero panels.
  static const double xl = 24;

  /// Fully round ends.
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(sm));
}

/// Text sizes: eight steps instead of a size per label.
abstract final class TextSize {
  /// Badges and counters.
  static const double tiny = 11.5;

  /// Captions, times, secondary lines.
  static const double caption = 12.5;

  /// The secondary line of a row or a card.
  static const double small = 13.5;

  /// Body text.
  static const double body = 15;

  /// A row's or a button's label.
  static const double label = 16;

  /// A card's or a state's title.
  static const double title = 18;

  /// A section's heading on a page.
  static const double heading = 20;

  /// A page's own title.
  static const double display = 22;
}

/// What a finger needs, on both platforms (Android asks 48, iOS 44).
const double tapTarget = 48;

/// How far text may grow with the phone's font setting.
abstract final class TextGrowth {
  /// Everywhere: past this, rows and cards lose content.
  static const double app = 1.6;

  /// In tight chrome: titles in bars, bottom bars, chips, calendar cells.
  static const double tight = 1.3;
}
