import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/storage_service.dart';
import '../services/review_service.dart';
import '../services/tts_settings_service.dart';
import 'handwriting_practice_screen.dart';
import 'practice_answer_utils.dart';
import 'pronunciation_practice_sheet.dart';

class StudyScreen extends StatefulWidget {
  final List<Map<String, String>> words;
  const StudyScreen({super.key, required this.words});
  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen>
    with SingleTickerProviderStateMixin {
  late final List<Map<String, String>> _words;
  final PageController _pc = PageController();
  final FlutterTts _tts = FlutterTts();

  int _idx = 0;
  double _speed = TtsSettingsService.defaultSpeed;
  bool _fav = false;
  bool _showXp = false;
  int _xpAmount = 0;
  BannerAd? _bannerAd;
  bool _bannerReady = false;

  int _learnedInSession = 0;

  // 카드 뒤집기
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _words = [...widget.words]..shuffle();
    _initTts();
    _loadFav();
    _loadBannerAd();

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnim = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
  }

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _bannerReady = true);
      },
      onFailed: () {
        _bannerAd = null;
      },
    );
    _bannerAd?.load();
  }

  Future<void> _initTts() async {
    final speed = await TtsSettingsService.getSpeed();
    if (mounted) setState(() => _speed = speed);
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(speed);
    await _tts.setPitch(1.0);
  }

  void _loadFav() {
    if (_words.isEmpty) return;
    setState(() =>
        _fav = StorageService.getFavorites().contains(_words[_idx]['word']!));
  }

  Future<void> _toggleFav() async {
    final w = _words[_idx]['word']!;
    if (_fav) {
      await StorageService.removeFavorite(w);
    } else {
      await StorageService.addFavorite(w);
      await StorageService.addXp(2); // 즐겨찾기 추가도 XP
    }
    _loadFav();
  }

  Future<void> _speak() async {
    try {
      await _tts.setSpeechRate(_speed);
      await _tts.speak(_words[_idx]['word']!);
    } catch (_) {}
  }

  Future<void> _speakExample() async {
    final example = _words[_idx]['example'] ?? '';
    if (example.isEmpty) return;
    try {
      await _tts.setSpeechRate(_speed * 0.8); // 예문은 조금 느리게
      await _tts.speak(example);
    } catch (_) {}
  }

  Future<void> _openWritingPractice() async {
    final word = _words[_idx];
    final kanji = word['kanji'] ?? '';
    final target = kanji.isNotEmpty && kanji != '-'
        ? kanji.split(RegExp(r'[・/、,]')).first
        : word['word'] ?? '';
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HandwritingPracticeScreen(
          target: target,
          reading: word['word'],
          hint: '아래 캔버스에 단어를 써 보세요',
          acceptedAnswers: wordPracticeAnswers(word),
          color: const Color(0xFF7B61FF),
        ),
      ),
    );
  }

  Future<void> _openPronunciationPractice() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => PronunciationPracticeSheet(word: _words[_idx]),
    );
  }

  Future<void> _onKnow() async {
    final w = _words[_idx]['word']!;
    final isNew = !StorageService.getLearned().contains(w);
    await StorageService.addLearned(w);
    await StorageService.markKnown(w);
    _learnedInSession++;

    // XP 토스트 + 즉시 상태 업데이트
    _xpAmount = isNew ? 10 : 2;
    if (mounted) setState(() => _showXp = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showXp = false);
    });
    _goNext();
  }

  Future<void> _onDontKnow() async {
    await StorageService.markUnknown(_words[_idx]['word']!);
    _goNext();
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _resetFlip() {
    _flipCtrl.value = 0;
    _isFlipped = false;
  }

  void _goNext() {
    _resetFlip();
    if (_idx < _words.length - 1) {
      _pc.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
      // ✅ 50단어마다 전면 광고 (AdService cooldown 7분 적용)
      if (_learnedInSession > 0 && _learnedInSession % 10 == 0) {
        Future.delayed(
            const Duration(milliseconds: 500), AdService.showInterstitialAd);
      }
    } else {
      _showComplete();
    }
  }

  void _showComplete() {
    // ✅ 완료 시 전면 광고 (AdService cooldown 7분 적용)
    AdService.showInterstitialAd();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ReviewService.requestReviewIfEligible(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('🎉 학습 완료!', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('모든 단어 학습 완료!', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFFFF6B9D)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CompleteStat('${StorageService.getStreak()}일', '🔥 스트릭'),
                    _CompleteStat(
                        '${StorageService.getLearned().length}', '📚 총 학습'),
                    _CompleteStat('${StorageService.getTotalXp()} XP', '⭐ 경험치'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
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
      );
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _pc.dispose();
    _flipCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _words.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('학습 ${_idx + 1} / $total'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_idx + 1) / total,
            backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF7B61FF)),
            minHeight: 4,
          ),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: total,
            physics: const PageScrollPhysics(),
            onPageChanged: (i) => setState(() {
              _idx = i;
              _resetFlip();
              _loadFav();
            }),
            itemBuilder: (_, i) {
              final item = _words[i];
              final wlen = item['word']?.length ?? 0;
              final fz = wlen > 8
                  ? 28.0
                  : wlen > 5
                      ? 32.0
                      : 38.0;
              final isNew = !StorageService.getLearned().contains(item['word']);
              final hasExample = (item['example'] ?? '').isNotEmpty;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    // ── 뒤집기 카드 ──
                    GestureDetector(
                      onTap: i == _idx ? _flipCard : null,
                      child: AnimatedBuilder(
                        animation: _flipAnim,
                        builder: (_, __) {
                          final angle = i == _idx ? _flipAnim.value : 0.0;
                          final showBack = angle > math.pi / 2;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            child: showBack
                                ? Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()..rotateY(math.pi),
                                    child: _buildCardBack(item, isDark, i == _idx),
                                  )
                                : _buildCardFront(item, fz, isNew),
                          );
                        },
                      ),
                    ),
                    // 힌트 텍스트
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app_outlined,
                              size: 13,
                              color: isDark ? Colors.white38 : Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            _isFlipped && i == _idx
                                ? (hasExample ? '예문 확인!' : '카드를 탭해서 앞으로')
                                : '카드를 탭해서 뜻 확인',
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── TTS + 즐겨찾기 ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _IconBtn(
                          icon: Icons.volume_up_rounded,
                          color: const Color(0xFF7B61FF),
                          bg: const Color(0xFFEDE9FF),
                          onTap: i == _idx ? _speak : null,
                        ),
                        const SizedBox(width: 16),
                        _IconBtn(
                          icon: _fav
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: _fav ? Colors.amber : Colors.grey,
                          bg: _fav
                              ? const Color(0xFFFFF8E1)
                              : const Color(0xFFF5F5F5),
                          onTap: i == _idx ? _toggleFav : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: i == _idx ? _openWritingPractice : null,
                            icon: const Icon(Icons.draw_outlined),
                            label: const Text('필기 연습'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF7B61FF),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                i == _idx ? _openPronunciationPractice : null,
                            icon: const Icon(Icons.mic_none_rounded),
                            label: const Text('발음 평가'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE91E63),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── 속도 슬라이더 ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF191B2A) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8)
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.speed,
                              size: 16, color: Color(0xFF7B61FF)),
                          const SizedBox(width: 6),
                          Text('${_speed.toStringAsFixed(1)}x',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7B61FF))),
                          Expanded(
                            child: Slider(
                              value: _speed,
                              min: 0.2, max: 2.0, divisions: 9, // ✅ 0.2~2.0
                              activeColor: const Color(0xFF7B61FF),
                              inactiveColor: Colors.grey.shade200,
                              onChanged: (v) {
                                setState(() => _speed = v);
                                _tts.setSpeechRate(v);
                                TtsSettingsService.setSpeed(v);
                              },
                            ),
                          ),
                          Text('느림',
                              style: TextStyle(
                                  fontSize: 9,
                                  color:
                                      isDark ? Colors.white60 : Colors.grey)),
                          const SizedBox(width: 4),
                          Text('빠름',
                              style: TextStyle(
                                  fontSize: 9,
                                  color:
                                      isDark ? Colors.white60 : Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 알겠어요 / 모르겠어요 ──
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: i == _idx ? _onKnow : null,
                            icon: const Icon(Icons.check_circle_outline,
                                size: 18),
                            label: const Text('알겠어요'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B61FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: i == _idx ? _onDontKnow : null,
                            icon: const Icon(Icons.replay, size: 18),
                            label: const Text('모르겠어요'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF191B2A)
                                  : Colors.white,
                              foregroundColor:
                                  isDark ? Colors.white : Colors.grey.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('← 스와이프로 넘길 수도 있어요',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.grey)),
                  ],
                ),
              );
            },
          ),

          // ✅ XP 획득 토스트
          if (_showXp)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 12)
                    ],
                  ),
                  child: Text('+$_xpAmount XP ⭐',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _bannerReady && _bannerAd != null
          ? SafeArea(
              top: false,
              child: Container(
                color: isDark ? const Color(0xFF151725) : Colors.white,
                alignment: Alignment.center,
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : null,
    );
  }

  Widget _buildCardFront(Map<String, String> item, double fz, bool isNew) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B61FF), Color(0xFF9C85FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isNew)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('✨ 새 단어 +10 XP',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          Text(item['word'] ?? '',
              style: TextStyle(
                  fontSize: fz,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.2),
              textAlign: TextAlign.center),
          if ((item['kanji'] ?? '').isNotEmpty &&
              item['kanji'] != '-') ...[
            const SizedBox(height: 8),
            Text(item['kanji'] ?? '',
                style: const TextStyle(fontSize: 22, color: Colors.white70),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('탭해서 뜻 보기 👆',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(Map<String, String> item, bool isDark, bool isCurrent) {
    final hasExample = (item['example'] ?? '').isNotEmpty;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A1F5F), const Color(0xFF1A2A4A)]
              : [const Color(0xFFEDE9FF), const Color(0xFFE0F0FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 뜻
          Text(item['meaning'] ?? '',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF3D2D8A)),
              textAlign: TextAlign.center),
          if (hasExample) ...[
            const SizedBox(height: 20),
            Divider(
                color: isDark
                    ? Colors.white24
                    : const Color(0xFF7B61FF).withValues(alpha: 0.2),
                height: 1),
            const SizedBox(height: 14),
            // 예문 + TTS 버튼
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(item['example'] ?? '',
                      style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF444444),
                          height: 1.5),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: isCurrent ? _speakExample : null,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B61FF).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up_rounded,
                        size: 18, color: Color(0xFF7B61FF)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item['exampleMeaning'] ?? '',
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                    fontStyle: FontStyle.italic),
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}  // end _StudyScreenState

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final VoidCallback? onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.bg, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

class _CompleteStat extends StatelessWidget {
  final String value, label;
  const _CompleteStat(this.value, this.label);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
    ]);
  }
}
