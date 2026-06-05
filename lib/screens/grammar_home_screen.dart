import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/grammar_provider.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import 'grammar_list_screen.dart';
import 'grammar_bookmark_screen.dart';
import 'grammar_quiz_screen.dart';

class GrammarHomeScreen extends StatefulWidget {
  const GrammarHomeScreen({super.key});

  @override
  State<GrammarHomeScreen> createState() => _GrammarHomeScreenState();
}

class _GrammarHomeScreenState extends State<GrammarHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  int _selectedIndex = 0;

  final List<String> _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  final List<Color> _levelColors = [
    const Color(0xFF43A047),
    const Color(0xFF1E88E5),
    const Color(0xFFFB8C00),
    const Color(0xFF8E24AA),
    const Color(0xFFE53935),
  ];

  final List<String> _levelDesc = [
    '기초 문법',
    '초급 문법',
    '중급 문법',
    '중상급 문법',
    '고급 문법',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<GrammarProvider>().loadAll();
      AdService.loadInterstitialAd();
    });
    AnalyticsService.logViewGrammarHome();
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
        title: const Text(
          'JLPT 문법',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7B61FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF7B61FF),
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_outlined), text: '문법 학습'),
            Tab(icon: Icon(Icons.quiz_outlined), text: '문법 퀴즈'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrammarHome(),
          _buildQuizTab(),
        ],
      ),
    );
  }

  Widget _buildGrammarHome() {
    final provider = context.watch<GrammarProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(provider),
          const SizedBox(height: 24),

          const Text(
            '급수 선택',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ...List.generate(_levels.length, (i) {
            final level = _levels[i];
            final color = _levelColors[i];

            final items = provider.getByLevel(level);

            final total = items.length;
            final mastered = provider.getMasteredCount(level);

            return _LevelCard(
              level: level,
              description: _levelDesc[i],
              color: color,
              total: total,
              mastered: mastered,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GrammarListScreen(
                      level: level,
                      color: color,
                    ),
                  ),
                );
              },
              onQuizTap: () {
                if (total < 4) return;

                AdService.showInterstitialAd();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GrammarQuizScreen(
                      level: level,
                      color: color,
                    ),
                  ),
                );
              },
            );
          }),

          // ── 하루일본어 웹사이트 ──
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse('https://japanese.luckygrampus.com/'),
              mode: LaunchMode.externalApplication,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF191B2A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: const Color(0xFF0083B0).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('🌐', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('하루일본어 웹사이트',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0083B0))),
                        Text('문법 개념을 웹에서 더 자세히 학습하기',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new,
                      size: 16, color: Color(0xFF0083B0)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuizTab() {
    final provider = context.watch<GrammarProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎯 문법 퀴즈',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('레벨별 문법 퀴즈를 풀어보세요!',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('급수 선택',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...List.generate(_levels.length, (i) {
            final level = _levels[i];
            final color = _levelColors[i];
            final items = provider.getByLevel(level);
            final total = items.length;
            final canQuiz = total >= 4;

            return GestureDetector(
              onTap: canQuiz
                  ? () {
                      AdService.showInterstitialAd();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GrammarQuizScreen(level: level, color: color),
                        ),
                      );
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF191B2A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: canQuiz
                          ? color.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8)
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: canQuiz
                            ? color
                            : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(level,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_levelDesc[i],
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey.shade600)),
                          const SizedBox(height: 2),
                          Text(
                            canQuiz ? '총 $total개 문법 퀴즈' : '문법 데이터 부족 (최소 4개 필요)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: canQuiz
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      canQuiz ? Icons.play_circle_filled : Icons.lock_outline,
                      color: canQuiz ? color : Colors.grey,
                      size: 30,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(GrammarProvider provider) {
    int totalMastered = 0;
    int totalItems = 0;

    for (final level in _levels) {
      totalMastered += provider.getMasteredCount(level);
      totalItems += provider.getByLevel(level).length;
    }

    final progress = totalItems > 0 ? totalMastered / totalItems : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7B61FF),
            Color(0xFF9B8CFF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '문법 학습 진행도',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalMastered / $totalItems 문법 완료',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white30,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String level;
  final String description;
  final Color color;
  final int total;
  final int mastered;
  final VoidCallback onTap;
  final VoidCallback onQuizTap;

  const _LevelCard({
    required this.level,
    required this.description,
    required this.color,
    required this.total,
    required this.mastered,
    required this.onTap,
    required this.onQuizTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? mastered / total : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    level,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$mastered / $total 문법 완료',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor:
                            isDark ? Colors.white12 : Colors.grey.shade200,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    onPressed: onTap,
                    icon: const Icon(Icons.chevron_right),
                  ),
                  IconButton(
                    onPressed: total > 3 ? onQuizTap : null,
                    icon: Icon(
                      Icons.quiz,
                      color: total > 3 ? color : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
