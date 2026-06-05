import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/kanji_item.dart';
import '../services/ad_service.dart';

enum KanjiQuizType { kanjiToMeaning, meaningToKanji, kanjiToReading }

class KanjiQuizScreen extends StatefulWidget {
  final String title;
  final List<KanjiItem> items;
  final Color color;
  final KanjiQuizType quizType;

  const KanjiQuizScreen({
    super.key,
    required this.title,
    required this.items,
    required this.color,
    this.quizType = KanjiQuizType.kanjiToMeaning,
  });

  @override
  State<KanjiQuizScreen> createState() => _KanjiQuizScreenState();
}

class _KanjiQuizScreenState extends State<KanjiQuizScreen> {
  late final List<KanjiItem> _pool;
  int _idx = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedAnswer;
  List<String> _options = [];
  final AudioPlayer _audio = AudioPlayer();
  final _rng = Random();
  BannerAd? _bannerAd;
  bool _bannerReady = false;

  @override
  void initState() {
    super.initState();
    _pool = [...widget.items]..shuffle(_rng);
    _loadQuestion();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd(
      onLoaded: () { if (mounted) setState(() => _bannerReady = true); },
      onFailed: () { _bannerAd = null; },
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _audio.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  KanjiItem get _cur => _pool[_idx];

  String _getQuestion(KanjiItem item) {
    switch (widget.quizType) {
      case KanjiQuizType.kanjiToMeaning:
      case KanjiQuizType.kanjiToReading:
        return item.kanji;
      case KanjiQuizType.meaningToKanji:
        return item.meaning;
    }
  }

  String _getCorrectAnswer(KanjiItem item) {
    switch (widget.quizType) {
      case KanjiQuizType.kanjiToMeaning:
        return item.meaning;
      case KanjiQuizType.kanjiToReading:
        return item.onyomi.isNotEmpty ? item.onyomi : item.kunyomi;
      case KanjiQuizType.meaningToKanji:
        return item.kanji;
    }
  }

  String _getAnswerFromItem(KanjiItem item) => _getCorrectAnswer(item);

  void _loadQuestion() {
    final correct = _getCorrectAnswer(_cur);
    final others = widget.items
        .where((k) => _getAnswerFromItem(k) != correct)
        .map((k) => _getAnswerFromItem(k))
        .toSet()
        .toList()
      ..shuffle(_rng);
    _options = [correct, ...others.take(3)]..shuffle(_rng);
  }

  Future<void> _onSelect(String choice) async {
    if (_answered) return;
    _answered = true;
    _selectedAnswer = choice;
    final correct = choice == _getCorrectAnswer(_cur);
    if (correct) {
      _score++;
      _audio.play(AssetSource('sounds/success.mp3')).catchError((_) {});
    } else {
      _audio.play(AssetSource('sounds/failure.mp3')).catchError((_) {});
    }
    setState(() {});
  }

  void _next() {
    if (_idx < _pool.length - 1) {
      setState(() {
        _idx++;
        _answered = false;
        _selectedAnswer = null;
        _loadQuestion();
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 퀴즈 완료!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_score / ${_pool.length}',
                style: const TextStyle(
                    fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _score == _pool.length
                  ? '완벽해요! 🌟'
                  : _score >= _pool.length * 0.7
                      ? '잘 했어요! 👍'
                      : '더 연습해봐요! 💪',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('끝내기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _idx = 0;
                      _score = 0;
                      _answered = false;
                      _selectedAnswer = null;
                      _pool.shuffle(_rng);
                      _loadQuestion();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('다시 풀기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _pool.length;
    final question = _getQuestion(_cur);
    final correct = _getCorrectAnswer(_cur);
    final isKanjiQuestion = widget.quizType != KanjiQuizType.meaningToKanji;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_idx + 1) / total,
            backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(widget.color),
            minHeight: 4,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 진행 상황
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_idx + 1} / $total',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                        fontSize: 13)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('점수 $_score',
                      style: TextStyle(
                          color: widget.color, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 문제 카드
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color,
                      widget.color.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isKanjiQuestion ? '이 한자의 의미는?' : '이 뜻의 한자는?',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    if (widget.quizType == KanjiQuizType.kanjiToReading)
                      const Text('(음독/훈독)',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 16),
                    Text(
                      question,
                      style: TextStyle(
                        fontSize: isKanjiQuestion ? 72 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_answered) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '음독: ${_cur.onyomi.isEmpty ? '-' : _cur.onyomi}  훈독: ${_cur.kunyomi.isEmpty ? '-' : _cur.kunyomi}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 보기 2x2
            Expanded(
              flex: 3,
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                physics: const NeverScrollableScrollPhysics(),
                children: _options.map((opt) {
                  Color? bg;
                  Color? border;
                  if (_answered) {
                    if (opt == correct) {
                      bg = Colors.green.withValues(alpha: 0.15);
                      border = Colors.green;
                    } else if (opt == _selectedAnswer) {
                      bg = Colors.red.withValues(alpha: 0.15);
                      border = Colors.red;
                    }
                  }
                  return GestureDetector(
                    onTap: _answered ? null : () => _onSelect(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: bg ??
                            (isDark
                                ? const Color(0xFF191B2A)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: border ??
                              (isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200),
                          width: border != null ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: border == Colors.green
                                ? Colors.green
                                : border == Colors.red
                                    ? Colors.red
                                    : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_answered)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_idx < _pool.length - 1 ? '다음 문제 →' : '결과 보기'),
                ),
              ),
            ),
          if (_bannerReady && _bannerAd != null)
            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
}
