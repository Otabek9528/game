import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'linkify.dart';
import 'parcel_models.dart';

/// A courier's post: who and when they fly, what they wrote (phones,
/// Telegram names and links tappable), and the ways to reach them.
class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post, required this.onOpen});

  final ParcelPost post;
  final Future<void> Function(Uri) onOpen;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  /// Longer posts fold to this many lines.
  static const _folded = 8;

  late List<TextPiece> _pieces = linkify(widget.post.text);
  final _taps = <TapGestureRecognizer>[];
  bool _open = false;

  @override
  void didUpdateWidget(PostCard old) {
    super.didUpdateWidget(old);
    if (old.post.text != widget.post.text) _pieces = linkify(widget.post.text);
  }

  @override
  void dispose() {
    for (final t in _taps) {
      t.dispose();
    }
    super.dispose();
  }

  void _go(Uri uri) {
    HapticFeedback.lightImpact();
    widget.onOpen(uri);
  }

  void _copy() {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: widget.post.text));
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).parcelCopied),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final post = widget.post;
    final username = post.username;
    final phone = _pieces.where((x) => x.kind == PieceKind.phone).firstOrNull;

    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
    final body = TextStyle(fontSize: 14.5, height: 1.45, color: p.ink);
    final link = body.copyWith(color: p.accent, fontWeight: FontWeight.w600);
    final spans = <TextSpan>[];
    for (final piece in _pieces) {
      if (piece.kind == PieceKind.text) {
        spans.add(TextSpan(text: piece.text));
        continue;
      }
      final tap = TapGestureRecognizer()..onTap = () => _go(piece.target!);
      _taps.add(tap);
      spans.add(TextSpan(text: piece.text, style: link, recognizer: tap));
    }
    final text = TextSpan(style: body, children: spans);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(username: username),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (username != null)
                      Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink),
                      )
                    else
                      Text(
                        s.parcelContactInText,
                        style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: p.inkMuted),
                      ),
                    if (post.flightTime != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.flight_takeoff_rounded, size: 15, color: p.gold),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              post.flightTime!,
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.inkSoft),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              final measure = TextPainter(
                text: text,
                maxLines: _folded,
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: box.maxWidth);
              final long = measure.didExceedMaxLines;
              measure.dispose();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    text,
                    maxLines: _open ? null : _folded,
                    overflow: _open ? TextOverflow.clip : TextOverflow.ellipsis,
                  ),
                  if (long)
                    TextButton(
                      onPressed: () => setState(() => _open = !_open),
                      style: TextButton.styleFrom(
                        foregroundColor: p.accent,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(_open ? s.parcelShowLess : s.parcelShowMore),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (username != null)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _go(Uri.parse('https://t.me/$username')),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(s.parcelWriteTelegram, overflow: TextOverflow.ellipsis),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  ),
                )
              else if (phone != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _go(phone.target!),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: Text(s.parcelCall),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.accent,
                      minimumSize: const Size(0, 44),
                      side: BorderSide(color: p.accent.withValues(alpha: 0.5)),
                    ),
                  ),
                )
              else
                const Spacer(),
              if (username != null && phone != null) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => _go(phone.target!),
                  tooltip: s.parcelCall,
                  icon: const Icon(Icons.call_rounded),
                ),
              ],
              const SizedBox(width: 4),
              IconButton(
                onPressed: _copy,
                tooltip: s.parcelCopy,
                color: p.inkMuted,
                icon: const Icon(Icons.copy_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The courier's initial on a colour of their own; a plane when they have
/// no username.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.username});

  final String? username;

  static const _colours = [
    Brand.emerald700,
    Color(0xFF0F766E),
    Color(0xFFB7791F),
    Color(0xFF9A3412),
    Color(0xFF1E40AF),
    Color(0xFF6D28D9),
  ];

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final name = username;
    if (name == null || name.isEmpty) {
      return CircleAvatar(
        radius: 21,
        backgroundColor: p.cardSelected,
        child: Icon(Icons.flight_rounded, color: p.accent, size: 22),
      );
    }
    final colour = _colours[name.codeUnits.fold<int>(0, (a, b) => a + b) % _colours.length];
    return CircleAvatar(
      radius: 21,
      backgroundColor: colour,
      child: Text(
        name[0].toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
      ),
    );
  }
}
