import '../models/kanji_item.dart';
import 'grade1_kanji.dart';
import 'grade2_kanji.dart';
import 'grade3_kanji.dart';
import 'grade4_kanji.dart';
import 'grade5_kanji.dart';
import 'grade6_kanji.dart';

export 'grade1_kanji.dart';
export 'grade2_kanji.dart';
export 'grade3_kanji.dart';
export 'grade4_kanji.dart';
export 'grade5_kanji.dart';
export 'grade6_kanji.dart';

// 문부과학성 교육한자 1026자 통합 목록 (2020년 4월 시행)
// 학년별 카운트: grade1=80, grade2=160, grade3=200, grade4=202, grade5=193, grade6=191
// 현재 입력: grade1=80, grade2=160, grade3=200, grade4=202, grade5=192, grade6=191 (합계 1025)
// TODO: 미입력 1자 — grade5 1자 미확인, 문부과학성 원문(別表) 대조 필요
const List<KanjiItem> kanjiData = [
  ...grade1KanjiList,
  ...grade2KanjiList,
  ...grade3KanjiList,
  ...grade4KanjiList,
  ...grade5KanjiList,
  ...grade6KanjiList,
];
