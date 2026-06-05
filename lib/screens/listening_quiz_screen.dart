import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/tts_settings_service.dart';

class ListeningQuizScreen extends StatefulWidget {
  final List<Map<String, String>> words;
  final int limit;

  const ListeningQuizScreen(
      {super.key, required this.words, required this.limit});

  @override
  State<ListeningQuizScreen> createState() => _ListeningQuizScreenState();
}

class _ListeningQuizScreenState extends State<ListeningQuizScreen> {
  late final List<Map<String, String>> _pool;
  Map<String, String> _cur = const {};
  int _idx = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedAnswer;
  List<String> _options = [];
  bool _isPlaying = false;

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audio = AudioPlayer();
  double _speed = TtsSettingsService.defaultSpeed;

  BannerAd? _bannerAd;
  bool _bannerReady = false;

  @override
  void initState() {
    super.initState();
    _pool = widget.words.take(widget.limit).toList()..shuffle();
    _initTts();
    _loadBannerAd();
    if (_pool.isNotEmpty) _loadQuestion();
  }

  Future<void> _initTts() async {
    final speed = await TtsSettingsService.getSpeed();
    if (mounted) setState(() => _speed = speed);
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(speed);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
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
    _cur = _pool[_idx];
    _answered = false;
    _selectedAnswer = null;

    final correct = _cur['meaning'] ?? '';
    final others = widget.words
        .where((w) => w['meaning'] != correct && (w['meaning'] ?? '').isNotEmpty)
        .map((w) => w['meaning']!)
        .toSet()
        .toList()
      ..shuffle();
    _options = [correct, ...others.take(3)]..shuffle();
    setState(() {});

    Future.delayed(const Duration(milliseconds: 300), _speak);
  }

  Future<void> _speak() async {
    if (_isPlaying) {
      await _tts.stop();
    }
    setState(() => _isPlaying = true);
    try {
      await _tts.setSpeechRate(_speed);
      await _tts.speak(_cur['word'] ?? '');
    } catch (_) {
      if (mounted) setState(() => _isPlaying = false);
    }
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
      _loadQuestion();
    } else {
      AdService.showInterstitialAd();
      _showResult();
    }
  }

  void _showResult() {
    if (!mounted) return;
    AnalyticsService.logCompleteWordQuiz(
        score: _score, total: _pool.length);
    final accuracy = (_score / _pool.length * 100).toInt();
    final xpEarned = _score * 20;
    final emoji =
        accuracy >= 80 ? '🏆' : accuracy >= 60 ? '👍' : '💪';
    final msg =
        accuracy >= 80 ? '훌륭해요!' : accuracy >= 60 ? '잘했어요!' : '다시 도전!';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$emoji $msg', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF26A69A)]),
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
                      style:
                          const TextStyle(fontSize: 15, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ResultStat('$xpEarned XP', '⭐ 획득'),
                _ResultStat('${_pool.length - _score}개', '📝 오답'),
                _ResultStat('${StorageService.getStreak()}일', '🔥 스트릭'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('확인',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _optionBg(String opt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_answered) return isDark ? const Color(0xFF191B2A) : Colors.white;
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
    if (_pool.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('청취 퀴즈')),
        body: const Center(child: Text('퀴즈 데이터가 없습니다.')),
      );
    }

    final total = _pool.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('청취 퀴즈 ${_idx + 1} / $total'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A3330)
                      : const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('정답 $_score',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00897B))),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: total > 0 ? (_idx + 1) / total : 0.0,
            backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
            valueColor:
                const AlwaysStoppedAnimation(Color(0xFF00897B)),
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
                        colors: [Color(0xFF00695C), Color(0xFF00897B)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF00897B).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('음성을 듣고 뜻을 고르세요 👂',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _speak,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: _isPlaying
                                  ? Colors.white.withOpacity(0.35)
                                  : Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying
                                  ? Icons.volume_up_rounded
                                  : Icons.play_circle_outline_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isPlaying ? '재생 중...' : '탭하여 다시 듣기',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.speed,
                                color: Colors.white60, size: 16),
                            const SizedBox(width: 6),
                            Text('속도 ${_speed.toStringAsFixed(1)}x',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 140,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 7),
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 보기
                  ...(_options.map((opt) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _select(opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: _optionBg(opt),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _optionBorder(opt), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(opt,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87)),
                              ),
                              if (_answered)
                                Icon(
                                  opt == _cur['meaning']
                                      ? Icons.check_circle
                                      : opt == _selectedAnswer
                                          ? Icons.cancel
                                          : null,
                                  color: opt == _cur['meaning']
                                      ? Colors.green
                                      : Colors.red,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList()),
                ],
              ),
            ),
          ),
          if (_bannerReady && _bannerAd != null)
            SafeArea(
              top: false,
              child: SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String value;
  final String label;
  const _ResultStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
