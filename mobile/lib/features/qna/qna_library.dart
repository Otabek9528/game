import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/key_value_store.dart';
import 'qna_models.dart';

/// What the Q&A pages keep on the phone: saved answers (readable without a
/// connection), recent searches, today's selection, and the reading size.
class QnaLibrary extends ChangeNotifier {
  QnaLibrary(this._store, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _saved.addAll(_questions(_read('qna_saved')));
    try {
      _recent.addAll((_read('qna_recent') as List?)?.whereType<String>() ?? const []);
    } catch (_) {}
    _textStep = int.tryParse(_store.read('qna_text') ?? '')?.clamp(0, textScales.length - 1) ?? 0;
  }

  final KeyValueStore _store;
  final DateTime Function() _clock;

  final _saved = <QnaQuestion>[];
  final _recent = <String>[];
  late int _textStep;

  static const maxSaved = 100;
  static const maxRecent = 8;

  /// The answer's reading sizes, as multiples of the normal one.
  static const textScales = [1.0, 1.15, 1.3];

  Object? _read(String key) {
    try {
      return jsonDecode(_store.read(key) ?? 'null');
    } catch (_) {
      return null;
    }
  }

  static List<QnaQuestion> _questions(Object? json) => [
        for (final q in (json as List?) ?? const [])
          if (q is Map<String, dynamic>) ?QnaQuestion.fromJson(q),
      ];

  /// Newest first.
  List<QnaQuestion> get saved => List.unmodifiable(_saved);

  bool isSaved(String id) => _saved.any((q) => q.id == id);

  /// Saves [question], or takes it out if it was saved. Returns whether it
  /// is saved now.
  bool toggleSave(QnaQuestion question) {
    final was = isSaved(question.id);
    _saved.removeWhere((q) => q.id == question.id);
    if (!was) {
      _saved.insert(0, question);
      if (_saved.length > maxSaved) _saved.removeRange(maxSaved, _saved.length);
    }
    _store.write('qna_saved', jsonEncode([for (final q in _saved) q.toJson()]));
    notifyListeners();
    return !was;
  }

  /// Newest first.
  List<String> get recent => List.unmodifiable(_recent);

  void remember(String query) {
    _recent
      ..removeWhere((q) => q.toLowerCase() == query.toLowerCase())
      ..insert(0, query);
    if (_recent.length > maxRecent) _recent.removeRange(maxRecent, _recent.length);
    _saveRecent();
  }

  void forget(String query) {
    _recent.remove(query);
    _saveRecent();
  }

  void clearRecent() {
    _recent.clear();
    _saveRecent();
  }

  void _saveRecent() {
    _store.write('qna_recent', jsonEncode(_recent));
    notifyListeners();
  }

  String get _today {
    final now = _clock();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Today's selection, when it was fetched today: the page opens on it at
  /// once, the same all day, as "Kunlik tanlov" says.
  List<QnaQuestion>? today() {
    final json = _read('qna_daily');
    if (json is! Map || json['date'] != _today) return null;
    final questions = _questions(json['questions']);
    return questions.isEmpty ? null : questions;
  }

  void keepToday(List<QnaQuestion> questions) =>
      _store.write('qna_daily', jsonEncode({'date': _today, 'questions': [for (final q in questions) q.toJson()]}));

  int get textStep => _textStep;

  double get textScale => textScales[_textStep];

  /// The next reading size, round to the first.
  void nextTextSize() {
    _textStep = (_textStep + 1) % textScales.length;
    _store.write('qna_text', '$_textStep');
    notifyListeners();
  }
}
