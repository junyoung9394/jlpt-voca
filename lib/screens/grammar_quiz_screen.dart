import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/grammar_item.dart';
import '../providers/grammar_provider.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/review_service.dart';
import '../services/storage_service.dart';

class GrammarQuizScreen extends StatefulWidget {
  final String level;
  final Color color;

  const GrammarQuizScreen({
    super.key,
    required this.level,
    required this.color,
  });

  @override
  State<GrammarQuizScreen> createState() => _GrammarQuizScreenState();
}

class _GrammarQuizScreenState extends State<GrammarQuizScreen> {
  late List<GrammarItem> _quizItems;
  int _currentIndex = 0;
  final AudioPlayer _audio = AudioPlayer();
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;
  late List<String> _choices;
  late int _correctIndex;
  bool _showExplanation = false;

  BannerAd? _bannerAd;
  bool _isBannerReady = false;

  @override
  void initState() {
    super.initState();
    _initQuiz();
    _loadBanner();
    AnalyticsService.logStartGrammarQuiz(widget.level);
  }

  void _loadBanner() {
    _bannerAd = AdService.createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _isBannerReady = true);
      },
      onFailed: () {
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) _loadBanner();
        });
      },
    );
    _bannerAd?.load();
  }

  void _initQuiz() {
    final provider = context.read<GrammarProvider>();
    final all = provider.getByLevel(widget.level);

    final shuffled = List<GrammarItem>.from(all)..shuffle(Random());
    _quizItems = shuffled.take(10).toList();

    _buildChoices();
  }

  void _buildChoices() {
    if (_quizItems.isEmpty || _currentIndex >= _quizItems.length) {
      _choices = [];
      _correctIndex = 0;
      _selectedAnswer = null;
      _answered = false;
      _showExplanation = false;
      return;
    }

    final correct = _quizItems[_currentIndex];
    final provider = context.read<GrammarProvider>();
    final all = provider.getByLevel(widget.level);

    final wrongs = List<GrammarItem>.from(all)
      ..removeWhere((grammar) => grammar.id == correct.id)
      ..shuffle(Random());

    final options = [correct, ...wrongs.take(3)];
    options.shuffle(Random());

    _correctIndex = options.indexOf(correct);
    _choices = options.map((grammar) => grammar.meaning).toList();
    _selectedAnswer = null;
    _answered = false;
    _showExplanation = false;
  }

  void _selectAnswer(int index) {
    if (_answered) return;

    setState(() {
      _selectedAnswer = index;
      _answered = true;

      if (index == _correctIndex) {
        _score++;
        StorageService.addXp(20);
        _audio.play(AssetSource('sounds/success.mp3')).catchError((_) {});
      } else {
        _audio.play(AssetSource('sounds/failure.mp3')).catchError((_) {});
      }
    });
  }

  void _next() {
    if (_currentIndex < _quizItems.length - 1) {
      _currentIndex++;
      if (_currentIndex % 10 == 0) AdService.showInterstitialAd();
      setState(() => _buildChoices());
    } else {
      AdService.showInterstitialAd();
      _showResult();
    }
  }

  void _showResult() {
    AnalyticsService.logCompleteGrammarQuiz(
      level: widget.level,
      score: _score,
      total: _quizItems.length,
    );
    ReviewService.requestReviewIfEligible(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '문법 퀴즈 완료! 🎉',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_score / ${_quizItems.length}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _score >= 8
                  ? '훌륭합니다! 🌟'
                  : _score >= 5
                      ? '잘 했어요! 💪'
                      : '조금 더 연습해봐요! 📚',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('목록으로'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              setState(() {
                _currentIndex = 0;
                _score = 0;
                _initQuiz();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('다시 도전'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audio.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_quizItems.isEmpty) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF10111B) : const Color(0xFFF8F7FF),
        appBar: AppBar(
          title: Text('${widget.level} 문법 퀴즈'),
          backgroundColor: widget.color,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('문법 문항이 부족합니다.'),
        ),
      );
    }

    final current = _quizItems[_currentIndex];
    final progress = (_currentIndex + 1) / _quizItems.length;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF10111B) : const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: Text(
          '${widget.level} 문법 퀴즈',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white30,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_currentIndex + 1} / ${_quizItems.length}',
                        style: TextStyle(
                          color: widget.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '점수: $_score',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.color.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '다음 문형의 의미는?',
                          style: TextStyle(
                            color:
                                isDark ? Colors.white70 : Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          current.pattern,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            current.type,
                            style: TextStyle(
                              color: widget.color,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(4, (index) {
                    Color backgroundColor =
                        isDark ? const Color(0xFF191B2A) : Colors.grey.shade100;
                    Color borderColor =
                        isDark ? Colors.white12 : Colors.grey.shade300;
                    Color textColor = isDark ? Colors.white : Colors.black87;
                    Widget? trailingIcon;

                    if (_answered) {
                      if (index == _correctIndex) {
                        backgroundColor = isDark
                            ? const Color(0xFF193026)
                            : Colors.green.shade50;
                        borderColor = Colors.green;
                        textColor = Colors.green.shade800;
                        trailingIcon = const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        );
                      } else if (index == _selectedAnswer) {
                        backgroundColor = isDark
                            ? const Color(0xFF352027)
                            : Colors.red.shade50;
                        borderColor = Colors.red;
                        textColor = Colors.red.shade800;
                        trailingIcon = const Icon(
                          Icons.cancel,
                          color: Colors.red,
                        );
                      }
                    } else if (_selectedAnswer == index) {
                      backgroundColor = widget.color.withOpacity(0.1);
                      borderColor = widget.color;
                    }

                    return GestureDetector(
                      onTap: () => _selectAnswer(index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: borderColor,
                              child: Text(
                                ['①', '②', '③', '④'][index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                index < _choices.length ? _choices[index] : '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (trailingIcon != null) trailingIcon,
                          ],
                        ),
                      ),
                    );
                  }),
                  if (_answered) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showExplanation = !_showExplanation;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF192635)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '해설 보기',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _showExplanation
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showExplanation)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF192635)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          current.explanation,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentIndex < _quizItems.length - 1
                              ? '다음 문제 →'
                              : '결과 보기 🎉',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isBannerReady && _bannerAd != null)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}
