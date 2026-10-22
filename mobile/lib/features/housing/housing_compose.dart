import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'housing_parts.dart';
import 'housing_source.dart';

/// A new post, or one's own changed: the address (fixed once posted), a
/// phone and/or one's Telegram name, and the text. Returns true when saved.
class HousingCompose extends StatefulWidget {
  const HousingCompose({super.key, required this.kit, this.post});

  final HousingKit kit;
  final HousingPost? post;

  @override
  State<HousingCompose> createState() => _HousingComposeState();
}

class _HousingComposeState extends State<HousingCompose> {
  HousingKit get _kit => widget.kit;
  HousingPost? get _post => widget.post;
  bool get _editing => _post != null;

  late final _address = TextEditingController(text: _post?.address ?? '');
  late final _phone = TextEditingController(text: _post?.contact == null ? '' : formatPhone(_post!.contact!));
  late final _username = TextEditingController(text: _post?.contactUsername ?? '');
  late final _body = TextEditingController(text: _post?.text ?? '');
  late bool _telegram = _post?.showUsername ?? false;
  String? _own;
  bool _busy = false;
  final _errors = <String, String>{};
  String? _formError;

  static final _usernameRule = RegExp(r'^[A-Za-z][A-Za-z0-9_]{4,31}$');

  @override
  void initState() {
    super.initState();
    unawaited(() async {
      try {
        final own = await _kit.source.username(await _kit.auth());
        if (!mounted || own == null) return;
        setState(() => _own = own);
        if (_username.text.isEmpty) _username.text = own;
      } on HousingException {
        // Typed in, then.
      }
    }());
  }

  @override
  void dispose() {
    for (final c in [_address, _phone, _username, _body]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _normalizeUsername(String v) =>
      v.trim().replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'^(www\.)?t\.me/'), '').replaceFirst(RegExp(r'^@+'), '');

  bool _check() {
    final s = AppLocalizations.of(context);
    _errors.clear();
    final address = _address.text.trim();
    if (!_editing && (address.length < 4 || address.length > 200 || !RegExp(r'[가-힣]').hasMatch(address))) {
      _errors['address'] = s.hsErrAddress;
    }
    final phone = _phone.text.trim();
    if (phone.isNotEmpty && (phone.length < 5 || phone.length > 40 || RegExp(r'\d').allMatches(phone).length < 5)) {
      _errors['contact'] = s.hsErrPhone;
    }
    final username = _normalizeUsername(_username.text);
    if (_telegram && username.isEmpty) {
      _errors['contact_username'] = s.hsErrUsernameEmpty;
    } else if (_telegram && !_usernameRule.hasMatch(username)) {
      _errors['contact_username'] = s.hsErrUsername;
    }
    if (phone.isEmpty && !_telegram) _errors['contact'] = s.hsErrContactRequired;
    final body = _body.text.trim();
    if (body.length < 20 || body.length > 4000) _errors['body'] = s.hsErrBody;
    setState(() {});
    return _errors.isEmpty;
  }

  Future<void> _send() async {
    final s = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _formError = null);
    if (!_check()) return HapticFeedback.heavyImpact();
    setState(() => _busy = true);
    final draft = (
      address: _editing ? null : _address.text.trim(),
      contact: _phone.text.trim(),
      body: _body.text.trim(),
      showUsername: _telegram,
      username: _normalizeUsername(_username.text),
    );
    try {
      final auth = await _kit.auth();
      _editing ? await _kit.source.edit(auth, _post!.id, draft) : await _kit.source.create(auth, draft);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    } on HousingException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        if (e.code == 'geocode_failed') {
          _errors['address'] = s.hsErrGeocode;
        } else if (e.code == 'validation_failed' && e.fields.isNotEmpty) {
          for (final MapEntry(:key, :value) in e.fields.entries) {
            _errors[key] = switch (key) {
              'address' => s.hsErrAddress,
              'contact' when value.startsWith('provide') => s.hsErrContactRequired,
              'contact' => s.hsErrPhone,
              'contact_username' => s.hsErrUsername,
              'body' => s.hsErrBody,
              _ => value,
            };
          }
        } else {
          _formError = housingMessage(s, e);
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final p = VegukinPalette.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: p.hairlineStrong),
    );
    InputDecoration deco(String hint, String? error, {String? prefix, Widget? icon}) => InputDecoration(
      hintText: hint,
      errorText: error,
      errorMaxLines: 3,
      prefixText: prefix,
      prefixIcon: icon,
      isDense: true,
      filled: true,
      fillColor: p.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: p.accent, width: 1.5)),
    );
    Widget label(String text, {bool required = false}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(
        children: [
          Flexible(
            child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.ink)),
          ),
          if (required) ...[const SizedBox(width: 6), HousingPill(s.hsRequired, colour: p.accent)],
        ],
      ),
    );
    Widget hint(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Text(text, style: TextStyle(fontSize: 12.5, height: 1.4, color: p.inkMuted)),
    );
    return Scaffold(
      backgroundColor: p.page,
      appBar: AppBar(backgroundColor: p.page, surfaceTintColor: Colors.transparent, title: Text(_editing ? s.hsEditTitle : s.hsNewTitle)),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: p.card,
          border: Border(top: BorderSide(color: p.hairline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_formError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _formError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                FilledButton(
                  onPressed: _busy ? null : _send,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  child: Text(
                    _busy
                        ? s.hsSending
                        : _editing
                        ? s.hsSave
                        : s.hsSubmit,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(s.hsComposeSub, style: TextStyle(fontSize: 14, color: p.inkSoft)),
          label(s.hsAddress, required: true),
          HousingAddressField(
            controller: _address,
            hint: '서울특별시 관악구 신림동 1522-27',
            enabled: !_editing,
            error: _errors['address'],
            action: TextInputAction.next,
          ),
          hint(_editing ? s.hsAddressLocked : s.hsAddressHint),
          label(s.hsPhone),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: const [PhoneTyping()],
            decoration: deco('010-1234-5678', _errors['contact'], icon: Icon(Icons.call_outlined, color: p.accent)),
          ),
          hint(s.hsContactHint),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            value: _telegram,
            onChanged: (v) => setState(() => _telegram = v),
            secondary: const Icon(Icons.telegram, color: Color(0xFF229ED9)),
            title: Text(
              s.hsTelegramOptIn,
              style: TextStyle(fontWeight: FontWeight.w700, color: p.ink),
            ),
          ),
          if (_telegram) ...[
            TextField(
              controller: _username,
              autocorrect: false,
              decoration: deco('username', _errors['contact_username'], prefix: '@'),
            ),
            hint(s.hsYourUsername(_own == null ? '—' : '@$_own')),
          ],
          label(s.hsBody, required: true),
          ListenableBuilder(
            listenable: _body,
            builder: (context, _) => TextField(
              controller: _body,
              minLines: 6,
              maxLines: 14,
              decoration: deco(s.hsBodyHint, _errors['body']).copyWith(
                counterText: '${_body.text.length} / 4000',
                counterStyle: TextStyle(color: _body.text.length > 4000 ? Theme.of(context).colorScheme.error : p.inkMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
