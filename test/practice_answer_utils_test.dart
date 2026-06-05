import 'package:flutter_test/flutter_test.dart';
import 'package:jlpt_voca/screens/practice_answer_utils.dart';

void main() {
  test('word practice accepts kana and kanji variations', () {
    const word = {
      'word': 'あう',
      'kanji': '会う・逢う',
      'meaning': '만나다',
    };

    final answers = wordPracticeAnswers(word);
    expect(matchesPracticeAnswer(answers, 'あう'), isTrue);
    expect(matchesPracticeAnswer(answers, '会う'), isTrue);
    expect(matchesPracticeAnswer(answers, '逢う。'), isTrue);
    expect(matchesPracticeAnswer(answers, 'みる'), isFalse);
  });
}
