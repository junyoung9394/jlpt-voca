import 'package:shared_preferences/shared_preferences.dart';
import '../data/all_words.dart';

class DailyWordService {
  static Map<String, String> getDailyWord([DateTime? date]) {
    final target = date ?? DateTime.now();
    final dayOfYear = target.difference(DateTime(target.year, 1, 1)).inDays;
    return allWords[dayOfYear % allWords.length];
  }

  static String displayWord(Map<String, String> w) =>
      (w['kanji'] != null && w['kanji'] != '-') ? w['kanji']! : w['word']!;

  static String reading(Map<String, String> w) => w['word'] ?? '';
  static String meaning(Map<String, String> w) => w['meaning'] ?? '';

  // 알림·위젯에 오늘의 단어를 SharedPreferences에 저장
  static Future<void> saveToPrefs() async {
    final w = getDailyWord();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notif_daily_word', displayWord(w));
    await prefs.setString('notif_daily_reading', reading(w));
    await prefs.setString('notif_daily_meaning', meaning(w));
  }
}
