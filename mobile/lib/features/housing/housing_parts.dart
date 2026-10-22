import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'housing_source.dart';

/// What the housing pages share: the board's server, the account.
class HousingKit {
  HousingKit(this.services);

  final AppServices services;

  HousingSource get source => services.housing;
  bool get signedIn => services.account.signedIn;

  /// The account's header; the account is made when missing.
  Future<Map<String, String>> auth() async {
    try {
      await services.account.ensure();
    } catch (_) {}
    return services.account.authHeaders;
  }
}

/// The amber of a distance and of "new", as on the web page.
Color housingAmber(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFFDCAE4F) : const Color(0xFFC8901A);

const _regions = {'서울', '부산', '대구', '인천', '광주', '대전', '울산', '세종', '경기', '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주'};
final _regionEnd = RegExp(r'(특별자치시|특별자치도|특별시|광역시|시|도|군|구)$');

/// "경기도 안산시 단원구 원곡동 1" → ("경기도 · 안산시 단원구", "원곡동 1"):
/// the region small above, the rest as the heading.
(String?, String) splitAddress(String address) {
  final parts = address.trim().split(RegExp(r'\s+'));
  if (parts.length < 3) return (null, address.trim());
  var n = 0;
  while (n < 3 && n < parts.length - 1 && (_regionEnd.hasMatch(parts[n]) || (n == 0 && _regions.contains(parts[n])))) {
    n++;
  }
  if (n == 0) return (null, address.trim());
  final head = parts.first;
  final rest = parts.sublist(1, n).join(' ');
  return (rest.isEmpty ? head : '$head · $rest', parts.sublist(n).join(' '));
}

/// A Korean number as people write it: 010-1234-5678, 02-123-4567.
String formatPhone(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length == 11 && d.startsWith('0')) return '${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7)}';
  if (d.length == 10 && d.startsWith('02')) return '${d.substring(0, 2)}-${d.substring(2, 6)}-${d.substring(6)}';
  if (d.length == 10 && d.startsWith('0')) return '${d.substring(0, 3)}-${d.substring(3, 6)}-${d.substring(6)}';
  return raw;
}

/// Groups a number with dashes as it's typed (02-…, 010-…, 031-…).
class PhoneTyping extends TextInputFormatter {
  const PhoneTyping();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (!RegExp(r'^[\d\s-]*$').hasMatch(text)) return newValue;
    final d = text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 11) return newValue;
    String group(List<int> sizes) {
      final out = <String>[];
      var i = 0;
      for (final size in sizes) {
        if (i >= d.length) break;
        final end = (i + size).clamp(0, d.length);
        out.add(d.substring(i, end));
        i = end;
      }
      return out.join('-');
    }

    final formatted = d.startsWith('02')
        ? group(d.length <= 9 ? [2, 3, 4] : [2, 4, 4])
        : d.startsWith('010')
        ? group([3, 4, 4])
        : group(d.length <= 10 ? [3, 3, 4] : [3, 4, 4]);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// "2.4 km", "12 km".
String housingKm(double km) => '${km < 10 ? km.toStringAsFixed(1) : km.round()} km';

/// What to tell someone when [e] came back.
String housingMessage(AppLocalizations s, HousingException e) => switch (e.code) {
  'forbidden' => s.hsErrForbidden,
  'not_found' => s.hsErrNotFound,
  'gone' => s.hsErrGone,
  'geocode_failed' => s.hsErrGeocode,
  'geocode_unavailable' => s.hsErrGeoUnavailable,
  'service_unavailable' => s.hsErrUnavailable,
  'internal_error' => s.hsErrServer,
  'rate_limited' when e.retryAfter != null && e.retryAfter! <= 90 => s.hsErrRateSeconds('${e.retryAfter}'),
  'rate_limited' when e.retryAfter != null => s.hsErrRateMinutes('${(e.retryAfter! / 60).round()}'),
  'offline' => s.hsErrNetwork,
  _ => s.hsErrGeneric,
};

void showHousingSnack(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

/// A small rounded label.
class HousingPill extends StatelessWidget {
  const HousingPill(this.text, {super.key, required this.colour, this.icon});

  final String text;
  final Color colour;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: colour.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: colour), const SizedBox(width: 3)],
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colour),
          ),
        ],
      ),
    ),
  );
}

/// The address: its region small, the rest as a heading.
class HousingAddress extends StatelessWidget {
  const HousingAddress(this.address, {super.key, this.size = 16.5});

  final String address;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final (region, rest) = splitAddress(address);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (region != null)
          Text(
            region,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.inkMuted),
          ),
        Text(
          rest,
          style: TextStyle(fontSize: size, height: 1.3, fontWeight: FontWeight.w800, color: p.ink),
        ),
      ],
    );
  }
}

/// Nothing here, or something went wrong: a sign, a title, a line, a button.
class HousingMessage extends StatelessWidget {
  const HousingMessage({super.key, required this.icon, required this.title, this.body, this.action, this.onAction});

  final IconData icon;
  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: p.cardSelected, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, size: 30, color: p.accent),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink),
          ),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onAction,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              child: Text(action!),
            ),
          ],
        ],
      ),
    );
  }
}

/// A Korean address typed in.
class HousingAddressField extends StatelessWidget {
  const HousingAddressField({
    super.key,
    required this.controller,
    this.hint = '서울특별시 관악구 신림동',
    this.error,
    this.enabled = true,
    this.onSubmitted,
    this.action = TextInputAction.search,
  });

  final TextEditingController controller;
  final String hint;
  final String? error;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction action;

  @override
  Widget build(BuildContext context) {
    final p = VegukinPalette.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: p.hairlineStrong),
    );
    return TextField(
      controller: controller,
      enabled: enabled,
      textInputAction: action,
      onSubmitted: onSubmitted,
      style: TextStyle(fontSize: 15.5, color: enabled ? p.ink : p.inkMuted),
      decoration: InputDecoration(
        hintText: hint,
        errorText: error,
        errorMaxLines: 3,
        prefixIcon: Icon(Icons.place_outlined, color: p.accent),
        isDense: true,
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(borderSide: BorderSide(color: p.accent, width: 1.5)),
      ),
    );
  }
}
