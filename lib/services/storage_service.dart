import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static const _favKey        = 'favorites';
  static const _wrongKey      = 'wrongNotes';
  static const _learnedKey    = 'learned';
  static const _reviewKey     = 'review';
  static const _streakKey     = 'streak_days';
  static const _lastStudyKey  = 'last_study_date';
  static const _totalXpKey    = 'total_xp';
  static const _todayCountKey = 'today_word_count';
  static const _todayDateKey  = 'today_date';
  static const _quizCorrectKey = 'quiz_correct_total';
  static const _srsKey        = 'srs_data';
  static const _srsMigratedKey = 'srs_migrated';

  // 레벨별 다음 복습 간격 (일)
  static const List<int> _srsIntervals = [1, 3, 7, 14, 30, 90];

  // ── XP 레벨 기준 (실제 단어 수 기반) ──
  // N5: 743개 × 10XP = 7,430 XP → 초보자 완료
  // N4: 1,035개 × 10XP = 10,350 XP → (누적 17,780)
  // N3: 1,524개 × 10XP = 15,240 XP → (누적 33,020) → 중급자 완료
  // N2+N1: 나머지 → 고급자
  static const int xpBeginner  = 0;
  static const int xpIntermediate = 7430;  // N5 완료 기준
  static const int xpAdvanced  = 33020;   // N3 완료 기준

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _checkAndUpdateStreak();
    await _migrateReviewToSrs();
  }

  // ── 즐겨찾기 ──
  static List<String> getFavorites() => _prefs.getStringList(_favKey) ?? [];
  static Future<void> addFavorite(String w) async {
    final l = getFavorites();
    if (!l.contains(w)) { l.add(w); await _prefs.setStringList(_favKey, l); }
  }
  static Future<void> removeFavorite(String w) async {
    final l = getFavorites();
    if (l.remove(w)) await _prefs.setStringList(_favKey, l);
  }
  static Future<void> clearFavorites() async => _prefs.remove(_favKey);

  // ── 오답노트 ──
  static List<String> getWrongNotes() => _prefs.getStringList(_wrongKey) ?? [];
  static Future<void> addWrong(String w) async {
    final l = getWrongNotes();
    if (!l.contains(w)) { l.add(w); await _prefs.setStringList(_wrongKey, l); }
  }
  static Future<void> removeWrong(String w) async {
    final l = getWrongNotes();
    if (l.remove(w)) await _prefs.setStringList(_wrongKey, l);
  }
  static Future<void> clearWrongNotes() async => _prefs.remove(_wrongKey);

  // ── 학습 완료 ──
  static List<String> getLearned() => _prefs.getStringList(_learnedKey) ?? [];
  static Future<void> addLearned(String w) async {
    final l = getLearned();
    if (!l.contains(w)) {
      l.add(w);
      await _prefs.setStringList(_learnedKey, l);
      await _recordStudyActivity();
      await addXp(10); // 새 단어 +10 XP
    } else {
      await addXp(2); // 복습 단어 +2 XP
    }
  }
  static Future<void> removeLearned(String w) async {
    final l = getLearned();
    if (l.remove(w)) await _prefs.setStringList(_learnedKey, l);
  }
  static Future<void> clearLearned() async => _prefs.remove(_learnedKey);

  // ── 복습 ──
  static List<String> getReview() => _prefs.getStringList(_reviewKey) ?? [];
  static Future<void> addReview(String w) async {
    final l = getReview();
    if (!l.contains(w)) { l.add(w); await _prefs.setStringList(_reviewKey, l); }
  }
  static Future<void> removeReview(String w) async {
    final l = getReview();
    if (l.remove(w)) await _prefs.setStringList(_reviewKey, l);
  }
  static Future<void> clearReview() async => _prefs.remove(_reviewKey);

  // ── 스트릭 ──
  static int getStreak() => _prefs.getInt(_streakKey) ?? 0;

  static Future<void> _checkAndUpdateStreak() async {
    final lastStr = _prefs.getString(_lastStudyKey);
    if (lastStr == null) return;
    final last = DateTime.parse(lastStr);
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(last.year, last.month, last.day)).inDays;
    if (diff > 1) await _prefs.setInt(_streakKey, 0);
  }

  static Future<void> _recordStudyActivity() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    final lastStr = _prefs.getString(_lastStudyKey);
    if (lastStr == null) {
      await _prefs.setInt(_streakKey, 1);
    } else {
      final last = DateTime.parse(lastStr);
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(last.year, last.month, last.day)).inDays;
      if (diff == 1) {
        final newStreak = getStreak() + 1;
        await _prefs.setInt(_streakKey, newStreak);
        if (newStreak % 7 == 0) await addXp(50); // 7일 스트릭 보너스
      } else if (diff > 1) {
        await _prefs.setInt(_streakKey, 1);
      }
    }
    await _prefs.setString(_lastStudyKey, now.toIso8601String());
    final savedDate = _prefs.getString(_todayDateKey) ?? '';
    if (savedDate != todayStr) {
      await _prefs.setString(_todayDateKey, todayStr);
      await _prefs.setInt(_todayCountKey, 1);
    } else {
      final cnt = _prefs.getInt(_todayCountKey) ?? 0;
      await _prefs.setInt(_todayCountKey, cnt + 1);
    }
  }

  // ── XP & 레벨 ──
  static int getTotalXp() => _prefs.getInt(_totalXpKey) ?? 0;
  static Future<void> addXp(int xp) async =>
      _prefs.setInt(_totalXpKey, getTotalXp() + xp);

  static String getLevelName() {
    final xp = getTotalXp();
    if (xp < xpIntermediate) return '초보자';
    if (xp < xpAdvanced) return '중급자';
    return '고급자';
  }

  static String getLevelEmoji() {
    final xp = getTotalXp();
    if (xp < xpIntermediate) return '🌱';
    if (xp < xpAdvanced) return '📘';
    return '🏆';
  }

  static double getLevelProgress() {
    final xp = getTotalXp();
    if (xp < xpIntermediate) return xp / xpIntermediate;
    if (xp < xpAdvanced) return (xp - xpIntermediate) / (xpAdvanced - xpIntermediate);
    return 1.0;
  }

  static int getNextLevelXp() {
    final xp = getTotalXp();
    if (xp < xpIntermediate) return xpIntermediate;
    if (xp < xpAdvanced) return xpAdvanced;
    return xp; // 최고 레벨 도달: 현재 XP = 목표 → 진행 바 100% 유지
  }

  // ── 설정 ──
  static int getDailyGoal() => _prefs.getInt('daily_goal') ?? 10;

  // ── 퀴즈 정답 ──
  static int getQuizCorrect() => _prefs.getInt(_quizCorrectKey) ?? 0;
  static Future<void> addQuizCorrect(int n) async =>
      _prefs.setInt(_quizCorrectKey, getQuizCorrect() + n);

  // ── 오늘 학습 수 ──
  static int getTodayCount() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    if ((_prefs.getString(_todayDateKey) ?? '') != todayStr) return 0;
    return _prefs.getInt(_todayCountKey) ?? 0;
  }

  // ── SRS ──

  static Map<String, Map<String, dynamic>> _getSrsData() {
    final raw = _prefs.getString(_srsKey);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveSrsData(Map<String, Map<String, dynamic>> data) async {
    await _prefs.setString(_srsKey, jsonEncode(data));
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // 알겠어요 → 레벨 업, 다음 복습일 = 오늘 + intervals[newLevel]
  static Future<void> markKnown(String word) async {
    final data = _getSrsData();
    final currentLevel = (data[word]?['level'] as int?) ?? 0;
    final newLevel = (currentLevel + 1).clamp(0, 5);
    final today = DateTime.now();
    data[word] = {
      'level': newLevel,
      'nextReview': _dateStr(today.add(Duration(days: _srsIntervals[newLevel]))),
      'lastStudied': _dateStr(today),
    };
    await _saveSrsData(data);
  }

  // 모르겠어요 → 레벨 다운, 다음 복습일 = 내일
  static Future<void> markUnknown(String word) async {
    final data = _getSrsData();
    final currentLevel = (data[word]?['level'] as int?) ?? 0;
    final newLevel = (currentLevel - 1).clamp(0, 5);
    final today = DateTime.now();
    data[word] = {
      'level': newLevel,
      'nextReview': _dateStr(today.add(const Duration(days: 1))),
      'lastStudied': _dateStr(today),
    };
    await _saveSrsData(data);
  }

  // 오늘 이하 nextReview인 단어 키 목록
  static List<String> getDueWords() {
    final data = _getSrsData();
    final today = _dateStr(DateTime.now());
    return data.entries
        .where((e) => ((e.value['nextReview'] as String?) ?? '9999').compareTo(today) <= 0)
        .map((e) => e.key)
        .toList();
  }

  // 특정 단어의 SRS 레벨 (0~5), 기록 없으면 -1
  static int getSrsLevel(String word) =>
      (_getSrsData()[word]?['level'] as int?) ?? -1;

  // 기존 review 리스트 → SRS 레벨 0으로 1회 마이그레이션
  static Future<void> _migrateReviewToSrs() async {
    if (_prefs.getBool(_srsMigratedKey) ?? false) return;
    final reviewList = _prefs.getStringList(_reviewKey) ?? [];
    if (reviewList.isNotEmpty) {
      final data = _getSrsData();
      final today = _dateStr(DateTime.now());
      for (final word in reviewList) {
        data.putIfAbsent(word, () => {
          'level': 0,
          'nextReview': today,
          'lastStudied': today,
        });
      }
      await _saveSrsData(data);
    }
    await _prefs.setBool(_srsMigratedKey, true);
  }

  // ── ✅ 전체 초기화 (XP 포함) ──
  static Future<void> clearAll() async {
    await _prefs.remove(_learnedKey);
    await _prefs.remove(_reviewKey);
    await _prefs.remove(_wrongKey);
    await _prefs.remove(_favKey);
    await _prefs.remove(_totalXpKey);    // ✅ XP 초기화
    await _prefs.remove(_streakKey);     // ✅ 스트릭 초기화
    await _prefs.remove(_lastStudyKey);  // ✅ 마지막 학습일 초기화
    await _prefs.remove(_todayCountKey); // ✅ 오늘 카운트 초기화
    await _prefs.remove(_todayDateKey);  // ✅ 오늘 날짜 초기화
    await _prefs.remove(_quizCorrectKey);// ✅ 퀴즈 정답 초기화
    await _prefs.remove(_srsKey);        // ✅ SRS 데이터 초기화
    await _prefs.remove(_srsMigratedKey);// ✅ 마이그레이션 플래그 초기화
  }
}
