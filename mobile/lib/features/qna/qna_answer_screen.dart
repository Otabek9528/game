import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../support/support_parts.dart';
import 'qna_library.dart';
import 'qna_models.dart';
import 'qna_parts.dart';
import 'qna_source.dart';

/// Opens [question] on its own page.
void openQuestion(BuildContext context, AppServices services, QnaLibrary library, QnaQuestion question) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => QnaAnswerScreen(services: services, library: library, question: question),
    ),
  );
}

/// A question and its answer, to read: a page of its own rather than the
/// web page's pop-up, so a similar question opens on top and Back returns
/// to this one. The answer's size can be raised; it can be saved to read
/// without a connection, copied, shared, and followed to its source.
class QnaAnswerScreen extends StatefulWidget {
  const QnaAnswerScreen({super.key, required this.services, required this.library, required this.question});

  final AppServices services;
  final QnaLibrary library;

  /// From a list it comes whole; a similar question has only its title
  /// until it is fetched.
  final QnaQuestion question;

  @override
  State<QnaAnswerScreen> createState() => _QnaAnswerScreenState();
}

class _QnaAnswerScreenState extends State<QnaAnswerScreen> {
  late QnaQuestion _question = widget.question;
  List<QnaQuestion>? _related;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final detail = await widget.services.qna.detail(widget.question.id);
      if (!mounted) return;
      setState(() {
        if (detail.question.isComplete) _question = detail.question;
        _related = [for (final q in detail.related) if (q.id != _question.id) q];
      });
    } on QnaException {
      // A whole question still reads; only the similar ones are missing.
      if (mounted) setState(() => _failed = !_question.isComplete);
    }
  }

  void _toggleSave() {
    final s = AppLocalizations.of(context);
    HapticFeedback.selectionClick();
    final saved = widget.library.toggleSave(_question);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(saved ? s.qnaSavedNote : s.qnaRemovedNote),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _share() {
    HapticFeedback.selectionClick();
    final link = _question.link;
    final answer = _question.answerBody ?? '';
    widget.services.shareText([
      '📖 ${_question.title}',
      '',
      if (link != null) '🔗 $link' else answer.length > 400 ? '${answer.substring(0, 400)}…' : answer,
    ].join('\n'));
  }

  void _copy() {
    final s = AppLocalizations.of(context);
    final q = _question;
    copyWithNote(
      context,
      [
        q.title,
        if (q.questionBody case final body?) '\n$body',
        '\n${s.qnaAnswer}${q.answerSource == null ? '' : ' (${q.answerSource})'}:',
        q.answerBody ?? '',
        if (q.link case final link?) '\n$link',
      ].join('\n'),
      s.qnaCopied,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final q = _question;
    final views = q.views;
    return ListenableBuilder(
      listenable: widget.library,
      builder: (context, _) {
        final scale = widget.library.textScale;
        final saved = widget.library.isSaved(q.id);
        return Scaffold(
          backgroundColor: p.page,
          appBar: AppBar(
            backgroundColor: p.page,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                onPressed: widget.library.nextTextSize,
                tooltip: s.qnaTextSize,
                icon: const Icon(Icons.format_size_rounded),
              ),
              IconButton(
                onPressed: q.isComplete ? _toggleSave : null,
                tooltip: saved ? s.qnaUnsave : s.qnaSave,
                icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: saved ? p.gold : null),
              ),
              IconButton(
                onPressed: q.isComplete ? _share : null,
                tooltip: s.qnaShare,
                icon: const Icon(Icons.share_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 28 + MediaQuery.paddingOf(context).bottom),
            children: [
              Row(
                children: [
                  Expanded(child: Align(alignment: AlignmentDirectional.centerStart, child: TopicChip(q.topic))),
                  if (views != null && views > 0) ...[
                    Icon(Icons.visibility_outlined, size: 16, color: p.inkMuted),
                    const SizedBox(width: 4),
                    Text(compactCount(views), style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              SectionMark(s.qnaQuestion),
              const SizedBox(height: 6),
              SelectableText(
                q.title,
                style: TextStyle(fontSize: 21 * scale, height: 1.32, fontWeight: FontWeight.w800, color: p.ink),
              ),
              if (q.questionBody case final body? when body != q.title) ...[
                const SizedBox(height: 10),
                SelectableText(body, style: TextStyle(fontSize: 15 * scale, height: 1.55, color: p.inkSoft)),
              ],
              const SizedBox(height: 22),
              const StarDivider(),
              const SizedBox(height: 18),
              Row(
                children: [
                  SectionMark(s.qnaAnswer),
                  if (q.answerSource case final source?) ...[
                    const SizedBox(width: 10),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                        decoration: BoxDecoration(
                          color: p.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_rounded, size: 15, color: p.accent),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                source,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (q.isComplete)
                LinkedText(
                  q.answerBody!,
                  style: TextStyle(fontSize: 16 * scale, height: 1.65, color: p.ink),
                  onLink: widget.services.openLink,
                )
              else if (_failed)
                QnaMessage(
                  icon: Icons.wifi_off_rounded,
                  title: s.qnaAnswerError,
                  body: s.qnaCheckConnection,
                  action: FilledButton.tonalIcon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(s.qnaRetry),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: SizedBox.square(dimension: 30, child: CircularProgressIndicator(strokeWidth: 3))),
                ),
              if (q.isComplete) ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    if (q.link case final link?) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => widget.services.openLink(link),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text(s.qnaOpenSource, maxLines: 1, overflow: TextOverflow.ellipsis),
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copy,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: Text(s.qnaCopy, maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                      ),
                    ),
                  ],
                ),
              ],
              if (_related case final related? when related.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(s.qnaRelated, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.ink)),
                const SizedBox(height: 10),
                SupportCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final (i, other) in related.indexed) ...[
                        if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: p.hairline),
                        InkWell(
                          onTap: () => openQuestion(context, widget.services, widget.library, other),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 13, 10, 13),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    other.title,
                                    style: TextStyle(fontSize: 14.5, height: 1.4, fontWeight: FontWeight.w600, color: p.ink),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.chevron_right_rounded, color: p.inkMuted),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
