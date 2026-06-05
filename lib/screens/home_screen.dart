import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';
import '../services/daily_word_service.dart';
import '../data/all_words.dart';
import 'tts_helper.dart';
import '../data/n5_words.dart';
import '../data/n4_words.dart';
import '../data/n3_words.dart';
import '../data/n2_words.dart';
import '../data/n1_words.dart';
import 'jlpt_level_screen.dart';
import 'study_screen.dart';
import 'search_screen.dart';
import 'book_screen.dart';
import 'exam_screen.dart';
import 'grammar_home_screen.dart';
import 'basic_japanese_home_screen.dart';
import '../services/analytics_service.dart';
import 'settings_screen.dart';
import 'my_words_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int get _dailyGoal => StorageService.getDailyGoal();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AnalyticsService.logViewHome();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  // ── 레벨별 진행률 계산 ──
  Map<String, int> get _levelProgress {
    final learned = StorageService.getLearned().toSet();
    return {
      'N5': n5Words.where((w) => learned.contains(w['word'])).length,
      'N4': n4Words.where((w) => learned.contains(w['word'])).length,
      'N3': n3Words.where((w) => learned.contains(w['word'])).length,
      'N2': n2Words.where((w) => learned.contains(w['word'])).length,
      'N1': n1Words.where((w) => learned.contains(w['word'])).length,
    };
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('전체 초기화'),
        content: const Text('모든 학습 기록, XP, 스트릭이\n초기화됩니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('초기화', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await StorageService.clearAll();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ 초기화 완료!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy.MM.dd (E)', 'ko').format(DateTime.now());
    final todayCount = StorageService.getTodayCount();
    final totalLearned = StorageService.getLearned().length;
    final totalXp = StorageService.getTotalXp();
    final streak = StorageService.getStreak();
    final reviewCount = StorageService.getDueWords().length;
    final levelName = StorageService.getLevelName();
    final levelEmoji = StorageService.getLevelEmoji();
    final levelProgress = StorageService.getLevelProgress();
    final nextXp = StorageService.getNextLevelXp();
    final todayProgress = (todayCount / _dailyGoal).clamp(0.0, 1.0);
    final goalDone = todayCount >= _dailyGoal;
    final lp = _levelProgress;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF10111B) : const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: const Text('일본어 VOCA 학습'),
        backgroundColor: isDark ? const Color(0xFF151725) : Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()));
                setState(() {});
              }),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
              if (mounted) setState(() {}); // 일일 목표 변경 반영
            },
          ),
          IconButton(
              icon: const Icon(Icons.refresh_outlined), onPressed: _resetData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── 상단 헤더 ──
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7B61FF), Color(0xFFFF6B9D)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(today,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('$levelEmoji $levelName',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('오늘도 화이팅! 🎌',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('총 $totalLearned개 학습 완료 · $totalXp XP',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 10),
                    // 레벨 진행 바
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: levelProgress,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.3),
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.white),
                              minHeight: 7,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('$totalXp / $nextXp XP',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),

              // ── 오늘의 단어 ──
              const _DailyWordCard(),

              // ── 스트릭 + 오늘 목표 ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1A1C2B)
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(16),
                            border: isDark
                                ? Border.all(color: Colors.white10)
                                : null,
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('🔥',
                                    style: TextStyle(fontSize: 22)),
                                const SizedBox(height: 6),
                                Text('연속 학습',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFFE65100))),
                                Text('$streak일',
                                    style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFFE65100))),
                                Text(streak == 0 ? '오늘 시작해요!' : '$streak일 연속!',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: isDark
                                            ? Colors.white60
                                            : const Color(0xFFBF360C))),
                              ]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: goalDone
                                ? (isDark
                                    ? const Color(0xFF192820)
                                    : const Color(0xFFE8F5E9))
                                : (isDark
                                    ? const Color(0xFF1A1C2B)
                                    : const Color(0xFFF3F0FF)),
                            borderRadius: BorderRadius.circular(16),
                            border: isDark
                                ? Border.all(color: Colors.white10)
                                : null,
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(goalDone ? '🎉' : '📚',
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(height: 6),
                                Text(goalDone ? '목표 달성!' : '오늘의 목표',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : goalDone
                                                ? const Color(0xFF2E7D32)
                                                : const Color(0xFF7B61FF))),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: todayProgress,
                                    backgroundColor:
                                        isDark ? Colors.white12 : Colors.white,
                                    valueColor: AlwaysStoppedAnimation(goalDone
                                        ? Colors.green
                                        : const Color(0xFF7B61FF)),
                                    minHeight: 7,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('$todayCount / $_dailyGoal 단어',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.grey)),
                              ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 빠른 통계 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(children: [
                  _statChip('복습 대기', '$reviewCount', Colors.orange,
                      onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MyWordsScreen(initialTab: 0)));
                    setState(() {});
                  }),
                  const SizedBox(width: 8),
                  _statChip('즐겨찾기', '${StorageService.getFavorites().length}',
                      Colors.pink, onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MyWordsScreen(initialTab: 1)));
                    setState(() {});
                  }),
                  const SizedBox(width: 8),
                  _statChip('오답노트', '${StorageService.getWrongNotes().length}',
                      Colors.red, onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MyWordsScreen(initialTab: 2)));
                    setState(() {});
                  }),
                ]),
              ),

              // ── 레벨별 진행률 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF191B2A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10)
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('레벨별 학습 진행률',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.grey)),
                      const SizedBox(height: 12),
                      ...[
                        (
                          'N5',
                          lp['N5']!,
                          n5Words.length,
                          const Color(0xFF4CAF50)
                        ),
                        (
                          'N4',
                          lp['N4']!,
                          n4Words.length,
                          const Color(0xFF2196F3)
                        ),
                        (
                          'N3',
                          lp['N3']!,
                          n3Words.length,
                          const Color(0xFF9C27B0)
                        ),
                        (
                          'N2',
                          lp['N2']!,
                          n2Words.length,
                          const Color(0xFFE91E63)
                        ),
                        (
                          'N1',
                          lp['N1']!,
                          n1Words.length,
                          const Color(0xFFFF5722)
                        ),
                      ].map((e) {
                        final label = e.$1;
                        final done = e.$2;
                        final total = e.$3;
                        final color = e.$4;
                        final prog = done / total;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(children: [
                            SizedBox(
                              width: 36,
                              child: Text(label,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: color)),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: prog,
                                  backgroundColor: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation(color),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 72,
                              child: Text('$done/$total',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey),
                                  textAlign: TextAlign.right),
                            ),
                          ]),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ── JLPT D-Day 배너 ──
              _DDayBanner(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ExamScreen()))),

              // ── 학습 메뉴 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('학습',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.grey)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _studyBox(
                      context: context,
                      emoji: '🔤',
                      title: '기초',
                      subtitle: '히라가나 · 가타카나 · 한자',
                      color: const Color(0xFF0083B0),
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const BasicJapaneseHomeScreen()));
                        setState(() {});
                      },
                    ),
                    _studyBox(
                      context: context,
                      emoji: '📖',
                      title: '단어',
                      subtitle: 'N5~N1 레벨별 학습',
                      color: const Color(0xFF7B61FF),
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const JLPTLevelScreen(mode: Mode.study)));
                        setState(() {});
                      },
                    ),
                    _studyBox(
                      context: context,
                      emoji: '📝',
                      title: '문법',
                      subtitle: 'N5~N1 레벨별 문법',
                      color: const Color(0xFF43A047),
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const GrammarHomeScreen()));
                        setState(() {});
                      },
                    ),
                    _studyBox(
                      context: context,
                      emoji: '👂',
                      title: '청취',
                      subtitle: '음성 듣고 뜻 맞추기',
                      color: const Color(0xFF00897B),
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const JLPTLevelScreen(mode: Mode.listen)));
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              // ── 오늘의 복습 ──
              _menuCard('오늘의 복습', '$reviewCount개 단어 복습 대기', Icons.replay,
                  const Color(0xFFFF9800), () async {
                final rk = StorageService.getDueWords();
                final rw =
                    allWords.where((w) => rk.contains(w['word'])).toList();
                if (rw.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('복습할 단어가 없습니다 👍')));
                  return;
                }
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => StudyScreen(words: rw)));
                setState(() {});
              }, badge: reviewCount > 0 ? '$reviewCount' : null),

              // ── 하루일본어 웹사이트 ──
              const _WebBanner(),

              // ── 쿠팡 파트너스 교재 추천 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('교재 추천',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.grey)),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BookScreen())),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7B61FF), Color(0xFFFF6B9D)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text('📚', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('JLPT 교재 추천',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            SizedBox(height: 3),
                            Text('쿠팡에서 합격 교재 확인하기 🛒',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('보기',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7B61FF))),
                      ),
                    ],
                  ),
                ),
              ),
              // 파트너스 고지
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Text(
                  '이 포스팅은 쿠팡 파트너스 활동의 일환으로, 이에 따른 일정액의 수수료를 제공받습니다.',
                  style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white60 : Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _statChip(String label, String value, Color color,
    {VoidCallback? onTap}) {
  return Builder(builder: (context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF191B2A)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? color.withValues(alpha: 0.34)
                    : color.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : color)),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white70 : Colors.grey)),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 12,
                  color: isDark ? Colors.white38 : color.withValues(alpha: 0.5)),
          ]),
        ),
      ),
    );
  });
}

Widget _studyBox({
  required BuildContext context,
  required String emoji,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191B2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.grey),
              maxLines: 2),
        ],
      ),
    ),
  );
}

Widget _menuCard(String title, String subtitle, IconData icon, Color color,
    VoidCallback onTap,
    {String? badge}) {
  return Builder(builder: (context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF191B2A) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: titleColor)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey)),
              ])),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(20)),
              child: Text(badge,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            )
          else
            Icon(Icons.arrow_forward_ios,
                size: 14,
                color: isDark ? Colors.white38 : Colors.grey.shade400),
        ]),
      ),
    );
  });
}

// ── 하루일본어 웹 배너 ──
class _WebBanner extends StatelessWidget {
  const _WebBanner();

  static const _url = 'https://japanese.luckygrampus.com/';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          launchUrl(Uri.parse(_url), mode: LaunchMode.externalApplication),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0083B0), Color(0xFF00B4D8)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('🌐', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('하루일본어 웹사이트',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  SizedBox(height: 3),
                  Text('히라가나부터 JLPT까지 개념 학습하기 →',
                      style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Text('바로가기',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0083B0))),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 오늘의 단어 카드 ──
class _DailyWordCard extends StatefulWidget {
  const _DailyWordCard();
  @override
  State<_DailyWordCard> createState() => _DailyWordCardState();
}

class _DailyWordCardState extends State<_DailyWordCard> {
  final _tts = TTSHelper();

  @override
  Widget build(BuildContext context) {
    final word = DailyWordService.getDailyWord();
    final display = DailyWordService.displayWord(word);
    final reading = DailyWordService.reading(word);
    final meaning = DailyWordService.meaning(word);
    final showReading = display != reading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191B2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: const Color(0xFF7B61FF).withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
        border: Border.all(
            color: const Color(0xFF7B61FF)
                .withValues(alpha: isDark ? 0.42 : 0.18)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌸', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text('오늘의 단어',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFB9AAFF)
                              : const Color(0xFF7B61FF))),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _tts.speak(context, reading),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B61FF)
                          .withValues(alpha: isDark ? 0.24 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.volume_up,
                          size: 14,
                          color: isDark
                              ? const Color(0xFFD6CBFF)
                              : const Color(0xFF7B61FF)),
                      const SizedBox(width: 4),
                      Text('발음',
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFFD6CBFF)
                                  : const Color(0xFF7B61FF))),
                    ]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(display,
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF2D2D2D))),
              if (showReading) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(reading,
                      style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? const Color(0xFFD6CBFF)
                              : const Color(0xFF7B61FF))),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(meaning,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: isDark ? Colors.white70 : Colors.grey)),
        ],
      ),
    );
  }
}

// ── D-Day 배너 위젯 ──
class _DDayBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _DDayBanner({required this.onTap});

  int _daysUntil(String dateStr) {
    final target = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return target.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final d1 = _daysUntil('2026-07-05');
    final d2 = _daysUntil('2026-12-06');
    final days = d1 >= 0 ? d1 : d2;
    final round = d1 >= 0 ? '제1회' : '제2회';
    final date = d1 >= 0 ? '2026.07.05' : '2026.12.06';
    final isUrgent = days <= 30;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUrgent
                ? [const Color(0xFFFF9800), const Color(0xFFFF5722)]
                : [const Color(0xFF7B61FF), const Color(0xFFFF6B9D)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isUrgent ? Colors.orange : const Color(0xFF7B61FF))
                  .withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(children: [
          const Text('🗓️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('JLPT 2026 $round · $date',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 2),
                Text(days == 0 ? '오늘이 시험 날! 🔥' : 'D-$days · 시험 정보 보기',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('D-$days',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7B61FF))),
          ),
        ]),
      ),
    );
  }
}
