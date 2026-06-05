String normalizePracticeAnswer(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[\s　.,!?！？。、・/]'), '');
}

List<String> wordPracticeAnswers(Map<String, String> word) {
  final answers = <String>{};
  final reading = word['word'] ?? '';
  if (reading.isNotEmpty) answers.add(reading);

  final kanji = word['kanji'] ?? '';
  if (kanji.isNotEmpty && kanji != '-') {
    answers.addAll(
      kanji
          .split(RegExp(r'[・/、,]'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty && value != '-'),
    );
  }
  return answers.toList();
}

bool matchesPracticeAnswer(Iterable<String> answers, String result) {
  final normalizedResult = normalizePracticeAnswer(result);
  return normalizedResult.isNotEmpty &&
      answers.map(normalizePracticeAnswer).contains(normalizedResult);
}
