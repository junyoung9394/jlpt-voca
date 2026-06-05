import 'package:flutter/material.dart';
import '../data/n1_words.dart';
import '../data/n2_words.dart';
import '../data/n3_words.dart';
import '../data/n4_words.dart';
import '../data/n5_words.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';
import 'study_screen.dart';
import 'quiz_screen.dart';
import 'listening_quiz_screen.dart';
import 'grammar_list_screen.dart';

enum Mode { study, quiz, listen }

class JLPTLevelScreen extends StatefulWidget {
  final Mode mode;
  const JLPTLevelScreen({super.key, required this.mode});

  @override
  State<JLPTLevelScreen> createState() => _JLPTLevelScreenState();
}

class _JLPTLevelScreenState extends State<JLPTLevelScreen> {
  bool _isNavigating = false; // 동시 탭 방지

  static const _levelInfo = [
    {
      'label': 'N5',
      'subtitle': '입문 · 기초 단어 학습',
      'emoji': '🌱',
      'color': 0xFF4CAF50
    },
    {
      'label': 'N4',
      'subtitle': '초급 · 기초 문법 이해',
      'emoji': '📘',
      'color': 0xFF2196F3
    },
    {
      'label': 'N3',
      'subtitle': '중급 · 일상 회화 가능',
      'emoji': '⚡',
      'color': 0xFF9C27B0
    },
    {
      'label': 'N2',
      'subtitle': '상급 · 자연스러운 일본어',
      'emoji': '🔥',
      'color': 0xFFE91E63
    },
    {
      'label': 'N1',
      'subtitle': '최고급 · 고도의 일본어',
      'emoji': '🏆',
      'color': 0xFFFF5722
    },
  ];

  List<Map<String, String>> _getWords(String label) {
    switch (label) {
      case 'N1':
        return n1Words;
      case 'N2':
        return n2Words;
      case 'N3':
        return n3Words;
      case 'N4':
        return n4Words;
      case 'N5':
        return n5Words;
      default:
        return [];
    }
  }

  Future<void> _onTap(String label, Color color) async {
    if (_isNavigating || !mounted) return;
    setState(() => _isNavigating = true);

    try {
      final words = _getWords(label);
      AnalyticsService.logViewWordLevel(label);

      if (widget.mode == Mode.listen) {
        if (!mounted) return;
        final choice = await showDialog<int>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            title: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
                const SizedBox(width: 10),
                const Text('청취 퀴즈',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('총 ${words.length}개 단어 중 몇 문제 풀까요?',
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 14),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _QuizCountCard(
                              dialogCtx: dialogCtx,
                              count: 10,
                              label: '10문제',
                              emoji: '⚡',
                              color: color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuizCountCard(
                              dialogCtx: dialogCtx,
                              count: 20,
                              label: '20문제',
                              emoji: '🎯',
                              color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _QuizCountCard(
                              dialogCtx: dialogCtx,
                              count: 30,
                              label: '30문제',
                              emoji: '🔥',
                              color: color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuizCountCard(
                              dialogCtx: dialogCtx,
                              count: words.length,
                              label: '전체\n${words.length}문제',
                              emoji: '🏆',
                              color: color),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        if (!mounted) return;
        if (choice != null && choice > 0) {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ListeningQuizScreen(words: words, limit: choice)));
        }
      } else if (widget.mode == Mode.study) {
        if (!mounted) return;
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => StudyScreen(words: [...words]..shuffle())));
      } else {
        // 퀴즈 문제 수 선택 — 2×2 카드 레이아웃 (GridView 대신 Row 사용)
        if (!mounted) return;
        final choice = await showDialog<int>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            title: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
                const SizedBox(width: 10),
                const Text('퀴즈', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('총 ${words.length}개 단어 중 몇 문제 풀까요?',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 14),
                // GridView.count 대신 Row+Column으로 대화상자 레이아웃 안정화
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _QuizCountCard(
                            dialogCtx: dialogCtx,
                            count: 10,
                            label: '10문제',
                            emoji: '⚡',
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuizCountCard(
                            dialogCtx: dialogCtx,
                            count: 20,
                            label: '20문제',
                            emoji: '🎯',
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _QuizCountCard(
                            dialogCtx: dialogCtx,
                            count: 30,
                            label: '30문제',
                            emoji: '🔥',
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuizCountCard(
                            dialogCtx: dialogCtx,
                            count: words.length,
                            label: '전체\n${words.length}문제',
                            emoji: '🏆',
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        if (!mounted) return;
        if (choice != null && choice > 0) {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => QuizScreen(words: words, limit: choice)));
        }
      }
    } catch (e, st) {
      debugPrint('[JLPTLevelScreen._onTap] 오류: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('화면 전환 중 오류가 발생했습니다. 다시 시도해 주세요.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarTitle = widget.mode == Mode.study
        ? '학습 레벨 선택'
        : widget.mode == Mode.listen
            ? '청취 퀴즈 레벨 선택'
            : '단어 퀴즈 레벨 선택';
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 상단 안내
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.mode == Mode.study
                      ? [const Color(0xFF7B61FF), const Color(0xFF9C85FF)]
                      : widget.mode == Mode.listen
                          ? [const Color(0xFF00695C), const Color(0xFF00897B)]
                          : [const Color(0xFFE91E63), const Color(0xFFFF6B9D)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                      widget.mode == Mode.study
                          ? '📚'
                          : widget.mode == Mode.listen
                              ? '👂'
                              : '🎯',
                      style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mode == Mode.study
                            ? '레벨별 단어 학습'
                            : widget.mode == Mode.listen
                                ? '청취 퀴즈'
                                : '레벨별 단어 퀴즈',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      Text(
                        widget.mode == Mode.study
                            ? '레벨을 선택해서 학습해요'
                            : widget.mode == Mode.listen
                                ? '음성 듣고 뜻을 맞춰보세요'
                                : '레벨별 단어 퀴즈로 실력을 테스트해요',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 레벨 카드
            ..._levelInfo.map((info) {
              final label = info['label'] as String;
              final words = _getWords(label);
              final learned = StorageService.getLearned();
              final learnedCount =
                  words.where((w) => learned.contains(w['word'])).length;
              final progress =
                  words.isEmpty ? 0.0 : learnedCount / words.length;
              final color = Color(info['color'] as int);

              return GestureDetector(
                onTap: _isNavigating ? null : () => _onTap(label, color),
                child: AnimatedOpacity(
                  opacity: _isNavigating ? 0.6 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF191B2A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: color.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14)),
                          child: Center(
                            child: Text(info['emoji'] as String,
                                style: const TextStyle(fontSize: 26)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(label,
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: color)),
                                  Text('$learnedCount / ${words.length}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: color,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text(info['subtitle'] as String,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey)),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation(color),
                                  minHeight: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.arrow_forward_ios,
                            size: 14,
                            color:
                                isDark ? Colors.white38 : Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── 퀴즈 문제 수 카드 (위젯 클래스로 변환하여 안정성 확보) ──────────────────────
class _QuizCountCard extends StatelessWidget {
  final BuildContext dialogCtx;
  final int count;
  final String label;
  final String emoji;
  final Color color;

  const _QuizCountCard({
    required this.dialogCtx,
    required this.count,
    required this.label,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // 투명 영역도 탭 감지
      onTap: () => Navigator.pop(dialogCtx, count),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 학습 유형 선택 카드 ────────────────────────────────────────────────────────
class _StudyTypeCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _StudyTypeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 13, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
