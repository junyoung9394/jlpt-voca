import 'package:flutter/material.dart';
import '../data/hiragana_data.dart';
import '../data/katakana_data.dart';
import '../data/basic_japanese_data.dart';
import '../data/kanji_data.dart';
import 'kana_screen.dart';
import 'kana_quiz_screen.dart';
import 'kanji_quiz_screen.dart';
import 'basic_phrases_screen.dart';
import 'kanji_screen.dart';

class BasicJapaneseHomeScreen extends StatefulWidget {
  const BasicJapaneseHomeScreen({super.key});

  @override
  State<BasicJapaneseHomeScreen> createState() =>
      _BasicJapaneseHomeScreenState();
}

class _BasicJapaneseHomeScreenState extends State<BasicJapaneseHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기초 일본어',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00B4DB),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF00B4DB),
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_outlined), text: '학습'),
            Tab(icon: Icon(Icons.quiz_outlined), text: '퀴즈'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StudyTab(),
          _QuizTab(),
        ],
      ),
    );
  }
}

// ── 학습 탭 ──────────────────────────────────────────
class _StudyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 배너
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🇯🇵 일본어 기초부터 시작해요!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('JLPT 학습 전에 기초를 탄탄히 다져봐요',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatBadge('히라가나', '${hiraganaData.length}자'),
                    const SizedBox(width: 8),
                    _StatBadge('가타카나', '${katakanaData.length}자'),
                    const SizedBox(width: 8),
                    _StatBadge('한자', '${kanjiData.length}자'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('문자 학습',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.grey)),
          ),
          _MenuCard(
            title: '히라가나 배우기',
            subtitle: '일본어 기본 문자 46자 + 탁음',
            icon: Icons.text_fields,
            color: const Color(0xFF7B61FF),
            tag: 'あ',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => KanaScreen(title: '히라가나', items: hiraganaData, color: const Color(0xFF7B61FF)))),
          ),
          _MenuCard(
            title: '가타카나 배우기',
            subtitle: '외래어 표기 문자 46자 + 탁음',
            icon: Icons.text_fields,
            color: const Color(0xFFFF6B9D),
            tag: 'ア',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => KanaScreen(title: '가타카나', items: katakanaData, color: const Color(0xFFFF6B9D)))),
          ),
          _MenuCard(
            title: '기초 한자',
            subtitle: 'N5·N4 필수 한자 ${kanjiData.length}자 · 음독·훈독·예시',
            icon: Icons.font_download_outlined,
            color: const Color(0xFFE65100),
            tag: '漢',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const KanjiScreen())),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('회화 & 표현',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.grey)),
          ),
          _MenuCard(
            title: '기초 표현',
            subtitle: '인사말, 감사·사과 표현 ${basicExpressionsData.length}개',
            icon: Icons.chat_bubble_outline,
            color: const Color(0xFF43A047),
            tag: '挨',
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => BasicPhrasesScreen(title: '기초 표현', items: basicExpressionsData, color: const Color(0xFF43A047), icon: Icons.chat_bubble_outline))),
          ),
          _MenuCard(
            title: '숫자와 시간',
            subtitle: '숫자, 시간, 날짜 표현 ${numbersData.length}개',
            icon: Icons.access_time,
            color: const Color(0xFFFF9800),
            tag: '数',
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => BasicPhrasesScreen(title: '숫자와 시간', items: numbersData, color: const Color(0xFFFF9800), icon: Icons.access_time))),
          ),
          _MenuCard(
            title: '쉬운 문장 연습',
            subtitle: '일상에서 쓰는 기본 문장 ${simpleSentencesData.length}개',
            icon: Icons.edit_note,
            color: const Color(0xFF00BCD4),
            tag: '文',
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => BasicPhrasesScreen(title: '쉬운 문장 연습', items: simpleSentencesData, color: const Color(0xFF00BCD4), icon: Icons.edit_note))),
          ),
          SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ── 퀴즈 탭 ──────────────────────────────────────────
class _QuizTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎯 기초 퀴즈',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('히라가나, 가타카나, 한자를 퀴즈로 익혀봐요!',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 가나 퀴즈 섹션
          const Text('가나 퀴즈',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuizCard(
                  emoji: 'あ',
                  title: '히라가나',
                  subtitle: '${hiraganaData.length}자',
                  color: const Color(0xFF7B61FF),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => KanaQuizScreen(
                          title: '히라가나 퀴즈',
                          items: hiraganaData,
                          color: const Color(0xFF7B61FF)))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuizCard(
                  emoji: 'ア',
                  title: '가타카나',
                  subtitle: '${katakanaData.length}자',
                  color: const Color(0xFFFF6B9D),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => KanaQuizScreen(
                          title: '가타카나 퀴즈',
                          items: katakanaData,
                          color: const Color(0xFFFF6B9D)))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 한자 퀴즈 섹션
          const Text('한자 퀴즈',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _BigQuizCard(
            emoji: '漢→뜻',
            title: '한자 보고 뜻 맞추기',
            subtitle: '한자를 보고 한국어 뜻을 고르세요',
            color: const Color(0xFFE65100),
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => KanjiQuizScreen(
                    title: '한자 퀴즈 (뜻)',
                    items: kanjiData,
                    color: const Color(0xFFE65100),
                    quizType: KanjiQuizType.kanjiToMeaning))),
          ),
          const SizedBox(height: 10),
          _BigQuizCard(
            emoji: '뜻→漢',
            title: '뜻 보고 한자 맞추기',
            subtitle: '한국어 뜻을 보고 한자를 고르세요',
            color: const Color(0xFF8D4A00),
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => KanjiQuizScreen(
                    title: '한자 퀴즈 (한자)',
                    items: kanjiData,
                    color: const Color(0xFF8D4A00),
                    quizType: KanjiQuizType.meaningToKanji))),
          ),
          const SizedBox(height: 10),
          _BigQuizCard(
            emoji: '漢→読',
            title: '한자 보고 읽기 맞추기',
            subtitle: '한자를 보고 음독/훈독을 고르세요',
            color: const Color(0xFFBF360C),
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => KanjiQuizScreen(
                    title: '한자 퀴즈 (읽기)',
                    items: kanjiData,
                    color: const Color(0xFFBF360C),
                    quizType: KanjiQuizType.kanjiToReading))),
          ),
          SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ── 공통 위젯들 ──────────────────────────────────────

Widget _StatBadge(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    ),
  );
}

class _QuizCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuizCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF191B2A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(emoji,
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey)),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('퀴즈 시작',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigQuizCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BigQuizCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF191B2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.play_circle_filled, color: color, size: 32),
          ],
        ),
      ),
    );
  }
}

Widget _MenuCard({
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
  String? tag,
}) {
  return Builder(builder: (context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF191B2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
          ],
          border: Border.all(
              color: isDark
                  ? color.withValues(alpha: 0.34)
                  : color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: tag != null
                  ? Center(
                      child: Text(tag,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontFamily: 'Dunggeunmiso')))
                  : Icon(icon, color: color, size: 24),
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
                          color: isDark ? Colors.white : null)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14,
                color: isDark ? Colors.white38 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  });
}
