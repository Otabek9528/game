import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_screen.dart';
import '../cars/cars_parts.dart' show SignInCard;
import 'jobs_screen.dart';
import 'jobs_source.dart';

enum _Form { form, sending, sent, failed }

/// Posting a job in the group, and one's posts there (the web page's sheet):
/// a new post, or one changed; taken, open again, done, deleted.
class JobsPostsPage extends StatefulWidget {
  const JobsPostsPage({super.key, required this.kit, this.mine = false});

  final JobsKit kit;

  /// Open on one's posts rather than a new one.
  final bool mine;

  @override
  State<JobsPostsPage> createState() => _JobsPostsPageState();
}

class _JobsPostsPageState extends State<JobsPostsPage> {
  JobsKit get _kit => widget.kit;
  late bool _mine = widget.mine;

  // One's posts.
  List<JobPost>? _posts;
  bool _loading = false;
  bool _loadFailed = false;

  // The form.
  final _text = TextEditingController();
  final _contact = TextEditingController();
  final _scroll = ScrollController();
  bool _manual = false;
  bool? _commission;
  bool _agreed = false;
  bool _howOpen = false;
  JobPost? _editing;
  _Form _form = _Form.form;
  String? _failure;
  String? _hint;
  bool _sentCommission = false;
  bool _wasEdit = false;

  @override
  void initState() {
    super.initState();
    _manual = _kit.telegramName == null;
    _text.addListener(_changed);
    _contact.addListener(_changed);
    unawaited(_load());
  }

  @override
  void dispose() {
    _text.dispose();
    _contact.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _changed() => setState(() => _hint = _valid ? null : _hint);

  Future<void> _load() async {
    if (!_kit.signedIn) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final (auth, user) = await _kit.auth();
      final posts = await _kit.source.posts(auth, user);
      if (mounted) setState(() => _posts = posts);
    } on JobsException {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show({required bool mine}) {
    HapticFeedback.selectionClick();
    if (!mine && _editing != null) _reset();
    setState(() => _mine = mine);
    if (mine) unawaited(_load());
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  // ---------------------------------------------------------------- the form

  String get _contactValue => !_manual && _kit.telegramName != null ? '@${_kit.telegramName}' : _contact.text.trim();

  String? _missing(AppLocalizations s) {
    if (_text.text.trim().length < 10) return s.jbHintText;
    if (_contactValue.length < 3) return s.jbHintContact;
    if (_commission == null) return s.jbHintCommission;
    if (_editing == null && !_agreed) return s.jbHintAgree;
    return null;
  }

  bool get _valid => _missing(AppLocalizations.of(context)) == null;

  void _reset() {
    _editing = null;
    _text.clear();
    _contact.clear();
    _manual = _kit.telegramName == null;
    _commission = null;
    _agreed = false;
    _hint = null;
    _form = _Form.form;
  }

  void _edit(JobPost post) {
    HapticFeedback.lightImpact();
    setState(() {
      _reset();
      _editing = post;
      _text.text = post.text;
      final telegram = _kit.telegramName;
      if (telegram == null || post.contact != '@$telegram') {
        _manual = true;
        _contact.text = post.contact;
      }
      _commission = post.commission;
      _mine = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _send() async {
    final s = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final missing = _missing(s);
    if (missing != null) {
      HapticFeedback.heavyImpact();
      return setState(() => _hint = missing);
    }
    final editing = _editing;
    final commission = _commission!;
    setState(() => _form = _Form.sending);
    try {
      final (auth, user) = await _kit.auth();
      if (editing != null) {
        await _kit.source.edit(auth, user, editing.id, text: _text.text.trim(), contact: _contactValue, commission: commission);
      } else {
        await _kit.source.create(auth, user, name: _kit.name, text: _text.text.trim(), contact: _contactValue, commission: commission);
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _wasEdit = editing != null;
        _sentCommission = commission;
        _editing = null;
        _form = _Form.sent;
      });
      unawaited(_load());
    } on JobsException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _failure = _kit.message(s, e, s.jbPostError);
        _form = _Form.failed;
      });
    }
  }

  // ------------------------------------------------------------ one's posts

  Future<void> _act(JobPost post, JobStatus? status) async {
    final s = AppLocalizations.of(context);
    final (title, text, yes, danger) = switch (status) {
      JobStatus.reserved => (s.jbReserve, s.jbReserveText, s.jbYes, false),
      JobStatus.available => (s.jbReopenTitle, s.jbReopenText, s.jbYes, false),
      JobStatus.finished => (s.jbFinish, s.jbFinishText, s.jbYes, false),
      null => (s.jbDeleteTitle, s.jbDeleteText, s.jbDelete, true),
    };
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.jbCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: danger ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error) : null,
            child: Text(yes),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    try {
      final (auth, user) = await _kit.auth();
      status == null ? await _kit.source.delete(auth, user, post.id) : await _kit.source.setStatus(auth, user, post.id, status);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      if (status == null && _editing?.id == post.id) setState(_reset);
      await _load();
    } on JobsException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      showJobsSnack(context, _kit.message(s, e, s.jbErrorTitle));
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final count = _posts?.length ?? 0;
    Widget tab(String label, bool on, VoidCallback onTap, {int? badge}) => Expanded(
      child: Material(
        color: on ? p.card : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: on ? null : onTap,
          child: SizedBox(
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, color: on ? p.ink : p.inkSoft),
                  ),
                ),
                if (badge != null && badge > 0) ...[const SizedBox(width: 6), JobsCount(badge)],
              ],
            ),
          ),
        ),
      ),
    );
    return PopScope(
      canPop: _editing == null,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) setState(_reset);
      },
      child: Scaffold(
        backgroundColor: p.page,
        appBar: AppBar(
          backgroundColor: p.page,
          surfaceTintColor: Colors.transparent,
          title: Text(s.jbPost),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    tab(s.jbNewPost, !_mine, () => _show(mine: false)),
                    tab(s.jbMyPosts, _mine, () => _show(mine: true), badge: count),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: !_kit.signedIn
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SignInCard(
                    icon: Icons.work_outline_rounded,
                    title: s.jbSignInTitle,
                    body: s.jbSignInBody,
                    action: s.jbSignIn,
                    onAction: () async {
                      if (await askToSignIn(context, _kit.services) && mounted) {
                        setState(() => _manual = _kit.telegramName == null);
                        await _load();
                      }
                    },
                  ),
                ],
              )
            : ListView(
                controller: _scroll,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: _mine ? _minePosts(s, p) : _formView(s, p),
              ),
      ),
    );
  }

  List<Widget> _formView(AppLocalizations s, VegukinPalette p) {
    final error = Theme.of(context).colorScheme.error;
    Widget centred(List<Widget> children) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 8),
      child: Column(children: children),
    );
    switch (_form) {
      case _Form.sending:
        return [
          centred([
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_wasEditPending ? s.jbSaving : s.jbSending, style: TextStyle(color: p.inkSoft)),
          ]),
        ];
      case _Form.sent:
        return [
          centred([
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, size: 40, color: p.accent),
            ),
            const SizedBox(height: 14),
            Text(
              _wasEdit ? s.jbSavedTitle : s.jbSentTitle,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.ink),
            ),
            const SizedBox(height: 6),
            Text(
              _wasEdit ? s.jbSavedBody : s.jbSentBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, height: 1.4, color: p.inkSoft),
            ),
            const SizedBox(height: 12),
            _Chip(commission: _sentCommission, long: true),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => setState(_reset),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(s.jbPostAgain),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _show(mine: true),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              icon: const Icon(Icons.article_outlined),
              label: Text(s.jbMyPosts),
            ),
          ]),
        ];
      case _Form.failed:
        return [
          centred([
            Icon(Icons.error_outline_rounded, size: 48, color: error),
            const SizedBox(height: 12),
            Text(s.jbErrorTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.ink)),
            const SizedBox(height: 6),
            Text(_failure ?? s.jbPostError, textAlign: TextAlign.center, style: TextStyle(color: p.inkSoft)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => setState(() => _form = _Form.form),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(s.jbRetry),
            ),
          ]),
        ];
      case _Form.form:
        break;
    }
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: p.hairlineStrong),
    );
    InputDecoration deco(String? hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: p.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: p.accent, width: 1.5)),
    );
    Widget label(String text, {String? pill}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Flexible(
            child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.ink)),
          ),
          if (pill != null) ...[
            const SizedBox(width: 6),
            DecoratedBox(
              decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(pill, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.accent)),
              ),
            ),
          ],
        ],
      ),
    );
    Widget link(IconData icon, String text, VoidCallback onTap) => Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(text),
      ),
    );
    final telegram = _kit.telegramName;
    final length = _text.text.length;
    final editing = _editing;
    final valid = _valid;
    return [
      if (editing == null) _HowItWorks(open: _howOpen, onTap: () => setState(() => _howOpen = !_howOpen)),
      if (editing != null)
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: p.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.jbEditing, style: TextStyle(fontWeight: FontWeight.w800, color: p.ink)),
              ),
              TextButton(
                onPressed: () {
                  setState(_reset);
                  _show(mine: true);
                },
                child: Text(s.jbCancel),
              ),
            ],
          ),
        ),
      label(s.jbText),
      TextField(
        controller: _text,
        minLines: 6,
        maxLines: 14,
        inputFormatters: [LengthLimitingTextInputFormatter(1000)],
        decoration: deco(null).copyWith(
          counterText: '$length / 1000',
          counterStyle: TextStyle(
            color: length >= 1000
                ? Theme.of(context).colorScheme.error
                : length >= 800
                ? const Color(0xFFE0A100)
                : p.inkMuted,
          ),
        ),
      ),
      label(s.jbContact, pill: telegram == null ? s.jbRequired : null),
      if (!_manual && telegram != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.hairlineStrong),
          ),
          child: Row(
            children: [
              const Icon(Icons.telegram, color: Color(0xFF229ED9)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('@$telegram', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: p.ink)),
              ),
              Icon(Icons.check_circle_rounded, size: 20, color: p.accent),
            ],
          ),
        ),
        link(Icons.call_outlined, s.jbContactManual, () {
          setState(() {
            _manual = true;
            _contact.clear();
          });
        }),
      ] else ...[
        TextField(controller: _contact, decoration: deco(s.jbContactHint)),
        if (telegram != null)
          link(Icons.telegram, s.jbContactBack, () {
            setState(() {
              _manual = false;
              _contact.clear();
            });
          }),
      ],
      label(s.jbCommission, pill: s.jbCommissionPick),
      for (final yes in [true, false]) ...[
        _CommissionOption(
          yes: yes,
          selected: _commission == yes,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _commission = yes);
          },
        ),
        const SizedBox(height: 10),
      ],
      if (_commission != null)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.cardSelected.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('👁 ${s.jbPreview}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.inkMuted)),
              const SizedBox(height: 8),
              Text(_commission! ? s.jbFootYes : s.jbFootNo, style: TextStyle(fontSize: 13.5, height: 1.45, color: p.ink)),
            ],
          ),
        ),
      if (editing == null) ...[
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: CheckboxListTile(
            value: _agreed,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() {
                _agreed = v ?? false;
                if (_valid) _hint = null;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(s.jbAgree, style: TextStyle(fontSize: 13.5, height: 1.4, color: p.ink)),
          ),
        ),
      ],
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _send,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: valid ? null : p.accent.withValues(alpha: 0.45),
        ),
        icon: Icon(editing == null ? Icons.send_rounded : Icons.save_rounded),
        label: Text(editing == null ? s.jbSubmit : s.jbSave, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      if (_hint != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            _hint!,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: 14),
      Text('⚠️ ${s.jbBanWarning}', style: TextStyle(fontSize: 12.5, height: 1.4, color: p.inkMuted)),
    ];
  }

  bool get _wasEditPending => _editing != null;

  List<Widget> _minePosts(AppLocalizations s, VegukinPalette p) {
    final posts = _posts;
    if (posts == null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: _loadFailed
                ? Column(
                    children: [
                      Text(s.jbLoadFailed, style: TextStyle(color: p.inkSoft)),
                      const SizedBox(height: 12),
                      FilledButton.tonal(onPressed: _load, child: Text(s.jbRetry)),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      ];
    }
    if (posts.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
          child: Column(
            children: [
              const Text('📭', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text(s.jbEmptyTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink)),
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: () => _show(mine: false), child: Text(s.jbEmptyAction)),
            ],
          ),
        ),
      ];
    }
    return [
      if (_loading) const LinearProgressIndicator(minHeight: 2),
      for (final post in posts) ...[
        _PostCard(
          post: post,
          now: _kit.now(),
          onStatus: (status) => _act(post, status),
          onEdit: () => _edit(post),
          onDelete: () => _act(post, null),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    Widget step(String n, String text) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
            child: Text(n, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13.5, height: 1.45, color: p.ink))),
        ],
      ),
    );
    Widget note(String emoji, String text) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, child: Text(emoji, textAlign: TextAlign.center)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, height: 1.45, color: p.inkSoft))),
        ],
      ),
    );
    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📌'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s.jbHowTitle, style: TextStyle(fontWeight: FontWeight.w800, color: p.ink)),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more_rounded, color: p.inkMuted),
                    ),
                  ],
                ),
                if (open) ...[
                  step('1', s.jbHow1),
                  step('2', s.jbHow2),
                  step('3', s.jbHow3),
                  const SizedBox(height: 4),
                  note('💰', s.jbHowCommission),
                  note('📌', s.jbHowRule),
                  note('⏳', s.jbHowWait),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommissionOption extends StatelessWidget {
  const _CommissionOption({required this.yes, required this.selected, required this.onTap});

  final bool yes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    return Material(
      color: selected ? p.cardSelected : p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? p.accent : p.hairlineStrong, width: selected ? 1.8 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(yes ? '💰' : '🤝', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          yes ? s.jbWithCommission : s.jbNoCommission,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.ink),
                        ),
                        Text(
                          yes ? '10,000 KRW' : s.jbFree,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      yes ? s.jbWithCommissionBody : s.jbNoCommissionBody,
                      style: TextStyle(fontSize: 13, height: 1.4, color: p.inkSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? p.accent : p.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "With a fee" or "free".
class _Chip extends StatelessWidget {
  const _Chip({required this.commission, this.long = false});

  final bool commission;
  final bool long;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final colour = commission ? const Color(0xFFC8901A) : p.inkSoft;
    final text = long
        ? (commission ? '💰 ${s.jbChipCommission}' : '🤝 ${s.jbChipFree}')
        : (commission ? '💰 10,000 KRW' : '🤝 ${s.jbNoCommission}');
    return DecoratedBox(
      decoration: BoxDecoration(color: colour.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colour)),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.now, required this.onStatus, required this.onEdit, required this.onDelete});

  final JobPost post;
  final DateTime now;
  final ValueChanged<JobStatus> onStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _ago(AppLocalizations s) {
    final at = post.createdAt;
    if (at == null) return '';
    final seconds = now.difference(at).inSeconds;
    if (seconds < 60) return s.jbJustNow;
    if (seconds < 3600) return s.jbMinutesAgo(seconds ~/ 60);
    if (seconds < 86400) return s.jbHoursAgo(seconds ~/ 3600);
    return s.jbDaysAgo(seconds ~/ 86400);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final error = Theme.of(context).colorScheme.error;
    const amber = Color(0xFFC8901A);
    final (statusText, statusColour) = switch (post.status) {
      JobStatus.available => (s.jbActive, const Color(0xFF2E9E5B)),
      JobStatus.reserved => (s.jbReserved, amber),
      JobStatus.finished => (s.jbFinished, p.inkMuted),
    };
    final wait = post.finishIn(now);
    final big = const Size.fromHeight(44);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_ago(s), style: TextStyle(fontSize: 12.5, color: p.inkMuted)),
              ),
              DecoratedBox(
                decoration: BoxDecoration(color: statusColour.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: statusColour, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColour)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.text, style: TextStyle(fontSize: 14.5, height: 1.45, color: p.ink)),
          const SizedBox(height: 10),
          _Chip(commission: post.commission),
          const SizedBox(height: 12),
          switch (post.status) {
            JobStatus.available => FilledButton.icon(
              onPressed: () => onStatus(JobStatus.reserved),
              style: FilledButton.styleFrom(minimumSize: big, backgroundColor: amber),
              icon: const Icon(Icons.how_to_reg_rounded, size: 20),
              label: Text(s.jbReserve),
            ),
            JobStatus.reserved => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onStatus(JobStatus.available),
                        style: OutlinedButton.styleFrom(minimumSize: big),
                        child: Text(s.jbReopen, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: wait == Duration.zero ? () => onStatus(JobStatus.finished) : null,
                        style: FilledButton.styleFrom(minimumSize: big),
                        child: Text(s.jbFinish, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
                if (wait > Duration.zero)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '⏳ ${s.jbFinishIn(wait.inHours, wait.inMinutes % 60)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: p.inkMuted),
                    ),
                  ),
              ],
            ),
            JobStatus.finished => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.task_alt_rounded, size: 20, color: p.inkMuted),
                  const SizedBox(width: 8),
                  Text(s.jbDone, style: TextStyle(fontWeight: FontWeight.w700, color: p.inkMuted)),
                ],
              ),
            ),
          },
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              // Changing a post rewrites its message in the group: only while it's open.
              if (post.status == JobStatus.available)
                TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18), label: Text(s.jbEdit)),
              TextButton.icon(
                onPressed: onDelete,
                style: TextButton.styleFrom(foregroundColor: error),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(s.jbDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
