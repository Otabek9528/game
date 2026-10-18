/// A question from the archive (pages/questions: /api/questions/…), with its
/// answer. Questions listed as related carry only an id and a title until
/// they are opened.
class QnaQuestion {
  const QnaQuestion({
    required this.id,
    required this.title,
    this.topic,
    this.views,
    this.answerSource,
    this.questionBody,
    this.answerBody,
    this.link,
  });

  final String id;
  final String title;

  /// As the API names it, often with an emoji in front ("📚 Boshqa").
  final String? topic;
  final int? views;

  /// The scholar who answered.
  final String? answerSource;
  final String? questionBody;
  final String? answerBody;

  /// The answer's page on the source site.
  final Uri? link;

  /// Has the answer: no need to fetch it.
  bool get isComplete => answerBody != null && answerBody!.trim().isNotEmpty;

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static QnaQuestion? fromJson(Map<String, dynamic> json) {
    final id = _text(json['id']);
    final title = _text(json['title']);
    if (id == null || title == null) return null;
    final link = _text(json['link']);
    return QnaQuestion(
      id: id,
      title: title,
      topic: _text(json['topic']),
      views: (json['views'] as num?)?.toInt(),
      answerSource: _text(json['answerSource']),
      questionBody: _text(json['questionBody']),
      answerBody: _text(json['answerBody']),
      link: link == null || link == '#' ? null : Uri.tryParse(link),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'topic': topic,
        'views': views,
        'answerSource': answerSource,
        'questionBody': questionBody,
        'answerBody': answerBody,
        'link': link?.toString(),
      };
}

/// An opened question and the ones like it.
class QnaDetail {
  const QnaDetail({required this.question, required this.related});

  final QnaQuestion question;
  final List<QnaQuestion> related;
}

/// "1.2k", as the web page counts views.
String compactCount(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
