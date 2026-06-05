class GrammarExample {
  final String sentence;
  final String reading;
  final String translation;
  final String readingKo;

  GrammarExample({
    required this.sentence,
    required this.reading,
    required this.translation,
    this.readingKo = '',
  });

  factory GrammarExample.fromJson(Map<String, dynamic> json) {
    return GrammarExample(
      sentence: json['sentence']?.toString() ?? '',
      reading: json['reading']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
      readingKo: json['readingKo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sentence': sentence,
      'reading': reading,
      'translation': translation,
      'readingKo': readingKo,
    };
  }
}

class GrammarItem {
  final String id;
  final String level;
  final String pattern;
  final String meaning;
  final String connection;
  final String type;
  final String explanation;
  final List<GrammarExample> examples;
  final String caution;

  GrammarItem({
    required this.id,
    required this.level,
    required this.pattern,
    required this.meaning,
    required this.connection,
    required this.type,
    required this.explanation,
    required this.examples,
    required this.caution,
  });

  factory GrammarItem.fromJson(Map<String, dynamic> json) {
    return GrammarItem(
      id: json['id']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      pattern: json['pattern']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      connection: _parseConnection(json),
      type: json['type']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      examples: _parseExamples(json['examples']),
      caution: json['caution']?.toString() ?? '',
    );
  }

  static String _parseConnection(Map<String, dynamic> json) {
    if (json['connection'] != null) {
      return json['connection'].toString();
    }

    if (json['접속'] != null) {
      return json['접속'].toString();
    }

    return '';
  }

  static List<GrammarExample> _parseExamples(dynamic rawExamples) {
    if (rawExamples == null) {
      return [];
    }

    if (rawExamples is! List) {
      return [];
    }

    return rawExamples
        .whereType<Map>()
        .map(
          (e) => GrammarExample.fromJson(
        Map<String, dynamic>.from(e),
      ),
    )
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'pattern': pattern,
      'meaning': meaning,
      'connection': connection,
      'type': type,
      'explanation': explanation,
      'examples': examples.map((e) => e.toJson()).toList(),
      'caution': caution,
    };
  }
}