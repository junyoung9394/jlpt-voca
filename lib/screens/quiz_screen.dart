import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/review_service.dart';
import '../services/tts_settings_service.dart';

class QuizScreen extends StatefulWidget {
  final List<Map<String, String>> words;
  final int limit;
  const QuizScreen({super.key, required this.words, required this.limit});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<Map<String, String>> _pool;
  // 빈 pool 대비: late 대신 기본값으로 초기화
  Map<String, String> _cur = const {};
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audio = AudioPlayer();

  int _idx = 0, _score = 0;
  bool _answered = false;
  double _speed = TtsSettingsService.defaultSpeed;
  List<String> _options = [];
  String? _selectedAnswer;

  BannerAd? _bannerAd;
  bool _bannerReady = false;

  @override
  void initState() {
    super.initState();
    _pool = widget.words.take(widget.limit).toList()..shuffle();
    _initTts();
    _loadBannerAd();
    AdService.loadRewardedAd();

    if (_pool.isEmpty) {
      // 데이터 없음 — 다음 프레임에서 SnackBar 표시
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('퀴즈 데이터가 없습니다. 단어를 먼저 확인해주세요.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    } else {
      _loadQuestion();
    }

    AnalyticsService.logStartWordQuiz(questionCount: widget.limit);
  }

  Future<void> _initTts() async {
    final speed = await TtsSettingsService.getSpeed();
    if (mounted) setState(() => _speed = speed);
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(speed);
  }

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _bannerReady = true);
      },
      onFailed: () {
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) _loadBannerAd();
        });
      },
    );
    _bannerAd?.load();
  }

  void _loadQuestion() {
    if (_pool.isEmpty) return;

    _cur = _pool[_idx];
    _answered = false;
    _selectedAnswer = null;

    final correct = _cur['meaning'] ?? '';
    if (correct.isEmpty) {
      // 뜻 없는 단어는 건너뜀
      if (_idx < _pool.length - 1) {
        _idx++;
        _loadQuestion();
      }
      return;
    }

    final others = widget.words
        .where(
            (w) => w['meaning'] != correct && (w['meaning'] ?? '').isNotEmpty)
        .map((w) => w['meaning']!)
        .toSet()
        .toList()
      ..shuffle();
    _options = [correct, ...others.take(3)]..shuffle();
    setState(() {});
  }

  Future<void> _select(String choice) async {
    if (_answered) return;
    _answered = true;
    _selectedAnswer = choice;
    final isCorrect = choice == _cur['meaning'];

    if (isCorrect) {
      _score++;
      await StorageService.addXp(20);
      await StorageService.addQuizCorrect(1);
      try {
        await _audio.play(AssetSource('sounds/success.mp3'));
      } catch (_) {}
    } else {
      final wrongWord = _cur['word'] ?? '';
      if (wrongWord.isNotEmpty) await StorageService.addWrong(wrongWord);
      try {
        await _audio.play(AssetSource('sounds/failure.mp3'));
      } catch (_) {}
    }
    setState(() {});

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    if (_idx < _pool.length - 1) {
      _idx++;
      if (_idx % 10 == 0) AdService.showInterstitialAd();
      _loadQuestion();
    } else {
      AdService.showInterstitialAd();
      _showResult();
    }
  }

  void _showResult() {
    if (!mounted) return;
    AnalyticsService.logCompleteWordQuiz(score: _score, total: _pool.length);
    ReviewService.requestReviewIfEligible(context);
    final accuracy = (_score / _pool.length * 100).toInt();
    final xpEarned = _score * 20;
    final emoji = accuracy >= 80
        ? '🏆'
        : accuracy >= 60
            ? '👍'
            : '💪';
    final msg = accuracy >= 80
        ? '훌륭해요!'
        : accuracy >= 60
            ? '잘했어요!'
            : '다시 도전!';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('$emoji $msg', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 점수 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFFFF6B9D)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('$_score / ${_pool.length}',
                        style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    Text('정답률 $accuracy%',
                        style: const TextStyle(
                            fontSize: 15, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ResultStat('$xpEarned XP', '⭐ 획득'),
                  _ResultStat('${StorageService.getStreak()}일', '🔥 스트릭'),
                  _ResultStat('${_pool.length - _score}개', '📝 오답'),
                ],
              ),
              const SizedBox(height: 4),
              Text('총 XP: ${StorageService.getTotalXp()}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),

              // 보상형 광고 버튼
              if (AdService.isRewardedReady) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      AnalyticsService.logRewardedXpButtonClick();
                      Navigator.pop(ctx);
                      await AdService.showRewardedAd(
                        onRewarded: () {
                          StorageService.addXp(xpEarned);
                          AnalyticsService.logRewardedXpGranted(xpEarned);
                        },
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎁 +$xpEarned XP 추가 획득!'),
                            backgroundColor: const Color(0xFF7B61FF),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                    icon: const Text('🎁', style: TextStyle(fontSize: 16)),
                    label: Text('광고 보고 +$xpEarned XP 더 받기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF3E0),
                      foregroundColor: const Color(0xFFE65100),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const Text('광고 완전 시청 후 지급',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _speak() async {
    try {
      await _tts.setSpeechRate(_speed);
      await _tts.speak(_cur['word'] ?? '');
    } catch (_) {}
  }

  Color _optionBg(String opt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_answered) {
      return isDark ? const Color(0xFF191B2A) : Colors.white;
    }
    if (opt == _cur['meaning']) {
      return isDark ? const Color(0xFF193026) : const Color(0xFFE8F5E9);
    }
    if (opt == _selectedAnswer) {
      return isDark ? const Color(0xFF352027) : const Color(0xFFFFEBEE);
    }
    return isDark ? const Color(0xFF191B2A) : Colors.white;
  }

  Color _optionBorder(String opt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_answered) return isDark ? Colors.white12 : Colors.grey.shade200;
    if (opt == _cur['meaning']) return Colors.green;
    if (opt == _selectedAnswer) return Colors.red;
    return isDark ? Colors.white12 : Colors.grey.shade200;
  }

  @override
  void dispose() {
    _tts.stop();
    _audio.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 데이터가 없을 때 빈 상태 화면
    if (_pool.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('퀴즈'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 20),
              Text(
                '퀴즈 데이터가 없습니다.',
                style: TextStyle(fontSize: 17, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                '단어가 준비되지 않았습니다.\n다시 시도해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('돌아가기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = _pool.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wlen = _cur['word']?.length ?? 0;
    final fz = wlen <= 5
        ? 42.0
        : wlen <= 8
            ? 34.0
            : 26.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('퀴즈 ${_idx + 1} / $total'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF302A4B)
                      : const Color(0xFFEDE9FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('정답 $_score',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B61FF))),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: total > 0 ? (_idx + 1) / total : 0.0,
            backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B9D)),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // 문제 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4A3AFF), Color(0xFF7B61FF)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF7B61FF).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('뜻을 고르세요 👇',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 13)),
                        const SizedBox(height: 12),
                        Text(_cur['word'] ?? '',
                            style: TextStyle(
                                fontSize: fz,
                                color: Colors.white,
                                fontWeight: FontWeight.w900),
                            textAlign: TextAlign.center),
                        if ((_cur['kanji'] ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(_cur['kanji'] ?? '',
                              style: const TextStyle(
                                  fontSize: 20, color: Colors.white60),
                              textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: _speak,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.volume_up_rounded,
                                    color: Colors.white, size: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('속도 ${_speed.toStringAsFixed(1)}x',
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 11)),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 8),
                                      overlayShape:
                                          SliderComponentShape.noOverlay,
                                    ),
                                    child: Slider(
                                      value: _speed,
                                      min: 0.2,
                                      max: 2.0,
                                      divisions: 9,
                                      activeColor: Colors.white,
                                      inactiveColor: Colors.white30,
                                      onChanged: (v) {
                                        setState(() => _speed = v);
                                        _tts.setSpeechRate(v);
                                        TtsSettingsService.setSpeed(v);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 선택지
                  ..._options.map((opt) => GestureDetector(
                        onTap: () => _select(opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _optionBg(opt),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _optionBorder(opt), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(opt,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center),
                              ),
                              if (_answered && opt == _cur['meaning'])
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 22),
                              if (_answered &&
                                  opt == _selectedAnswer &&
                                  opt != _cur['meaning'])
                                const Icon(Icons.cancel,
                                    color: Colors.red, size: 22),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (_bannerReady && _bannerAd != null)
            Container(
              color: isDark ? const Color(0xFF151725) : Colors.white,
              width: double.infinity,
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String value, label;
  const _ResultStat(this.value, this.label);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }
}
