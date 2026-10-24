import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../support/support_parts.dart';
import 'qna_answer_screen.dart';
import 'qna_library.dart';
import 'qna_models.dart';
import 'qna_parts.dart';
import 'qna_source.dart';

/// Questions people often have, to start from. In Uzbek: the archive is.
const qnaExamples = [
  'Qisqichbaqa yeyish joizmi?',
  'Safarda namozni qasr qilish',
  'Ro‘zadorning tish yuvishi',
  'Bankdan kredit olish hukmi',
];

/// Asks the archive in one's own words. The question stays in its box after
/// a search, to be refined, instead of the web page's results that replace
/// it; recent searches and examples wait under an empty box.
class QnaSearchScreen extends StatefulWidget {
  const QnaSearchScreen({super.key, required this.services, required this.library});

  final AppServices services;
  final QnaLibrary library;

  @override
  State<QnaSearchScreen> createState() => _QnaSearchScreenState();
}

class _QnaSearchScreenState extends State<QnaSearchScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  /// The search shown below, null before the first.
  String? _searched;
  List<QnaQuestion>? _results;
  bool _searching = false;
  bool _failed = false;

  /// Answers to an older search are dropped.
  int _round = 0;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _ready => _text.text.trim().length >= 3;

  Future<void> _search([String? query]) async {
    if (query != null) {
      _text.value = TextEditingValue(text: query, selection: TextSelection.collapsed(offset: query.length));
    }
    final text = _text.text.trim();
    if (text.length < 3) return;
    _focus.unfocus();
    widget.library.remember(text);
    final round = ++_round;
    setState(() {
      _searched = text;
      _searching = true;
      _failed = false;
    });
    try {
      final results = await widget.services.qna.search(text, who: widget.services.activity.who);
      if (!mounted || round != _round) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } on QnaException {
      if (!mounted || round != _round) return;
      setState(() {
        _searching = false;
        _failed = true;
      });
    }
  }

  void _clear() {
    _round++;
    _text.clear();
    setState(() {
      _searched = null;
      _results = null;
      _searching = false;
      _failed = false;
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final short = _text.text.trim().isNotEmpty && !_ready;
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(
        backgroundColor: p.page,
        surfaceTintColor: Colors.transparent,
        title: Text(s.qnaSearchTitle),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + MediaQuery.paddingOf(context).bottom),
        children: [
          SupportCard(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _text,
                  focusNode: _focus,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 5,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _search(),
                  style: TextStyle(fontSize: 16.5, height: 1.4, color: p.ink),
                  decoration: InputDecoration(
                    hintText: s.qnaSearchHint,
                    border: InputBorder.none,
                    suffixIcon: _text.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _clear,
                            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                            icon: Icon(Icons.close_rounded, color: p.inkMuted),
                          ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        short ? s.qnaMinLetters : '',
                        style: TextStyle(fontSize: 12.5, color: p.inkMuted),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _ready && !_searching ? _search : null,
                      icon: const Icon(Icons.search_rounded, size: 20),
                      label: Text(s.qnaSearchButton),
                      // The theme's buttons span the width; this one sits in a row.
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ..._below(s, p),
        ],
      ),
    );
  }

  List<Widget> _below(AppLocalizations s, VegukinPalette p) {
    if (_searching) {
      return [
        const SizedBox(height: 10),
        for (var i = 0; i < 4; i++)
          Container(
            height: 92,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(18)),
          ),
      ];
    }
    if (_failed) {
      return [
        QnaMessage(
          icon: Icons.wifi_off_rounded,
          title: s.qnaOfflineTitle,
          body: s.qnaOfflineBody,
          action: FilledButton.tonalIcon(
            onPressed: () => _search(_searched),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(s.qnaRetry),
          ),
        ),
      ];
    }
    final results = _results;
    if (results != null && _searched != null) {
      if (results.isEmpty) {
        return [QnaMessage(icon: Icons.search_off_rounded, title: s.qnaNoResults, body: s.qnaNoResultsHint)];
      }
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
          child: Text(s.qnaResults(results.length), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.inkSoft)),
        ),
        for (final q in results)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ListenableBuilder(
              listenable: widget.library,
              builder: (context, _) => QuestionCard(
                question: q,
                saved: widget.library.isSaved(q.id),
                onTap: () => openQuestion(context, widget.services, widget.library, q),
              ),
            ),
          ),
      ];
    }
    // Nothing asked yet.
    return [
      ListenableBuilder(
        listenable: widget.library,
        builder: (context, _) {
          final recent = widget.library.recent;
          if (recent.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 0, 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(s.qnaRecent, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink)),
                    ),
                    TextButton(onPressed: widget.library.clearRecent, child: Text(s.qnaClear)),
                  ],
                ),
              ),
              SupportCard(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  children: [
                    for (final (i, query) in recent.indexed) ...[
                      if (i > 0) Divider(height: 1, indent: 48, color: p.hairline),
                      InkWell(
                        onTap: () => _search(query),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Row(
                            children: [
                              Icon(Icons.history_rounded, size: 20, color: p.inkMuted),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  query,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14.5, color: p.ink),
                                ),
                              ),
                              IconButton(
                                onPressed: () => widget.library.forget(query),
                                tooltip: s.qnaRemove,
                                icon: Icon(Icons.close_rounded, size: 18, color: p.inkMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
        child: Text(s.qnaExamples, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink)),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final example in qnaExamples)
            ActionChip(
              onPressed: () => _search(example),
              avatar: Icon(Icons.north_west_rounded, size: 16, color: p.accent),
              label: Text(example),
              labelStyle: TextStyle(fontSize: 13.5, color: p.ink),
              backgroundColor: p.card,
              side: BorderSide(color: p.hairline),
              shape: const StadiumBorder(),
            ),
        ],
      ),
      const SizedBox(height: 18),
      SupportCard(
        color: p.gold.withValues(alpha: 0.08),
        edge: p.gold.withValues(alpha: 0.28),
        child: IconLine(icon: Icons.auto_awesome_rounded, tint: p.gold, title: s.qnaHowTitle, body: s.qnaHowBody),
      ),
    ];
  }
}
