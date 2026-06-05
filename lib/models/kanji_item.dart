class KanjiItem {
  final String kanji;
  final String onyomi;
  final String kunyomi;
  final String meaning;
  final int strokes;
  final int grade;

  const KanjiItem({
    required this.kanji,
    required this.onyomi,
    required this.kunyomi,
    required this.meaning,
    required this.strokes,
    required this.grade,
  });
}
