import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/app_language.dart';
import '../../core/theme.dart';
import '../../core/widgets/khatam.dart';
import '../../l10n/app_localizations.dart';
import 'qna_answer_screen.dart';
import 'qna_library.dart';
import 'qna_models.dart';
import 'qna_parts.dart';
import 'qna_search_screen.dart';
import 'qna_source.dart';

/// The verse the section is named after (an-Nahl 43, al-Anbiya 7).
const qnaVerse = 'فَاسْأَلُوا أَهْلَ الذِّكْرِ إِن كُنتُمْ لَا تَعْلَمُونَ';

/// The web page (pages/questions/) rebuilt: the verse it is named after,
/// the search always in view rather than folded away, saved answers, and
/// today's selection, which stays the same all day and grows as it is
/// scrolled.
class QnaScreen extends StatefulWidget {
  const QnaScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<QnaScreen> createState() => _QnaScreenState();
}

class _QnaScreenState extends State<QnaScreen> {
  late final QnaLibrary _library = QnaLibrary(widget.services.store);
  final _scroll = ScrollController();

  final _questions = <QnaQuestion>[];
  bool _loading = false;
  bool _failed = false;
  bool _more = true;

  /// Bumped by a new selection: pages for the old one are dropped.
  int _round = 0;

  /// A day's selection grows to this, then stops.
  static const _most = 150;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    final today = _library.today();
    if (today != null) {
      _questions.addAll(today);
    } else {
      _load(fresh: true);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _library.dispose();
    super.dispose();
  }

  /// [fresh]: a new selection in place of this one (kept for the rest of the
  /// day); otherwise more questions after it.
  Future<void> _load({bool fresh = false}) async {
    if (_loading && !fresh) return;
    final round = fresh ? ++_round : _round;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final batch = await widget.services.qna.browse();
      if (!mounted || round != _round) return;
      setState(() {
        if (fresh) _questions.clear();
        final seen = {for (final q in _questions) q.id};
        final added = [for (final q in batch) if (seen.add(q.id)) q];
        _questions.addAll(added);
        _more = added.isNotEmpty && _questions.length < _most;
        _loading = false;
      });
      if (fresh) _library.keepToday(_questions);
    } on QnaException {
      if (!mounted || round != _round) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 600 && !_loading && !_failed && _more && _questions.isNotEmpty) _load();
  }

  void _openSearch() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => QnaSearchScreen(services: widget.services, library: _library)),
    );
  }

  void _openSaved() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => _SavedScreen(services: widget.services, library: _library)),
      );

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final uzbek = (widget.services.locale.language ?? AppLanguage.uz) == AppLanguage.uz;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: p.page,
      body: RefreshIndicator(
        onRefresh: () => _load(fresh: true),
        edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: p.hero.first,
              surfaceTintColor: Colors.transparent,
              foregroundColor: Colors.white,
              systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
              titleTextStyle: const TextStyle(
                fontFamily: Brand.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
              ),
              title: Text(s.featureQna),
              actions: [
                IconButton(onPressed: _openSearch, tooltip: s.qnaSearchTitle, icon: const Icon(Icons.search_rounded)),
                const SizedBox(width: 4),
              ],
            ),
            SliverToBoxAdapter(child: _Hero(onSearch: _openSearch)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              sliver: SliverList.list(
                children: [
                  if (!uzbek)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(Icons.translate_rounded, size: 18, color: p.inkMuted),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.qnaUzbekNote, style: TextStyle(fontSize: 13, color: p.inkMuted))),
                        ],
                      ),
                    ),
                  ListenableBuilder(
                    listenable: _library,
                    builder: (context, _) {
                      final saved = _library.saved.length;
                      if (saved == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: p.gold.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: p.gold.withValues(alpha: 0.3)),
                          ),
                          child: InkWell(
                            onTap: _openSaved,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                              child: Row(
                                children: [
                                  Icon(Icons.bookmarks_rounded, color: p.gold, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      s.qnaSaved,
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink),
                                    ),
                                  ),
                                  Text('$saved', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.gold)),
                                  Icon(Icons.chevron_right_rounded, color: p.inkMuted),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 0, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.qnaDaily, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink)),
                              Text(s.qnaDailySub, style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _loading ? null : () => _load(fresh: true),
                          tooltip: s.qnaNewSet,
                          icon: Icon(Icons.refresh_rounded, color: p.accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: ListenableBuilder(
                listenable: _library,
                builder: (context, _) => SliverList.builder(
                  itemCount: _questions.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: QuestionCard(
                      question: _questions[i],
                      saved: _library.isSaved(_questions[i].id),
                      onTap: () => openQuestion(context, widget.services, _library, _questions[i]),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 4, 14, 24 + bottom),
                child: _failed
                    ? QnaMessage(
                        icon: Icons.wifi_off_rounded,
                        title: s.qnaLoadError,
                        body: s.qnaCheckConnection,
                        action: FilledButton.tonalIcon(
                          onPressed: () => _load(fresh: _questions.isEmpty),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(s.qnaRetry),
                        ),
                      )
                    : _loading && _questions.isEmpty
                        ? Column(
                            children: [
                              for (var i = 0; i < 4; i++)
                                Container(
                                  height: 104,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(18)),
                                ),
                            ],
                          )
                        : _loading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(
                                  child: SizedBox.square(dimension: 26, child: CircularProgressIndicator(strokeWidth: 3)),
                                ),
                              )
                            : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The verse in Arabic, where it is from, whose answers these are, and the
/// search, always in view.
class _Hero extends StatelessWidget {
  const _Hero({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.hero.first, p.hero.last]),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
              child: CustomPaint(painter: KhatamLatticePainter(color: Colors.white.withValues(alpha: 0.05))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
              children: [
                Text(
                  qnaVerse,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: Brand.arabicFont, fontSize: 25, height: 1.6, color: Brand.gold300),
                ),
                Text(
                  s.qnaVerseRef,
                  style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 12),
                Text(
                  s.qnaSource,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _HeroChip(icon: Icons.library_books_rounded, text: s.qnaCount),
                    _HeroChip(icon: Icons.auto_awesome_rounded, text: s.qnaAi),
                  ],
                ),
                const SizedBox(height: 18),
                Material(
                  color: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 2,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    onTap: onSearch,
                    customBorder: const StadiumBorder(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Brand.emerald700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.qnaSearchHint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, color: p.inkMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(9, 5, 11, 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Brand.gold300),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      );
}

/// Saved answers, newest first; they open without a connection.
class _SavedScreen extends StatelessWidget {
  const _SavedScreen({required this.services, required this.library});

  final AppServices services;
  final QnaLibrary library;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(backgroundColor: p.page, surfaceTintColor: Colors.transparent, title: Text(s.qnaSaved)),
      body: ListenableBuilder(
        listenable: library,
        builder: (context, _) {
          final saved = library.saved;
          if (saved.isEmpty) {
            return ListView(
              children: [QnaMessage(icon: Icons.bookmark_border_rounded, title: s.qnaSavedEmpty, body: s.qnaSavedHint)],
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(14, 4, 14, 24 + MediaQuery.paddingOf(context).bottom),
            itemCount: saved.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => QuestionCard(
              question: saved[i],
              saved: true,
              onTap: () => openQuestion(context, services, library, saved[i]),
            ),
          );
        },
      ),
    );
  }
}
