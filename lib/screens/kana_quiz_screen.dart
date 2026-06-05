import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/kana_item.dart';

class KanaQuizScreen extends StatefulWidget {
  final String title;
  final List<KanaItem> items;
  final Color color;

  const KanaQuizScreen({
    super.key,
    required this.title,
    required this.items,
    required this.color,
  });

  @override
  State<KanaQuizScreen> createState() => _KanaQuizScreenState();
}

class _KanaQuizScreenState extends State<KanaQuizScreen> {
  late final List<KanaItem> _pool;
  int _idx = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedAnswer;
  List<String> _options = [];
  final AudioPlayer _audio = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _pool = [...widget.items]..shuffle();
    _loadQuestion();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  KanaItem get _cur => _pool[_idx];

  void _loadQuestion() {
    final correct = _cur.readingKo;
    final others = widget.items
        .where((k) => k.readingKo != correct)
        .map((k) => k.readingKo)
        .toSet()
        .toList()
      ..shuffle();
    _options = [correct, ...others.take(3)]..shuffle();
    _answered = false;
    _selectedAnswer = null;
    setState(() {});
  }

  Future<void> _select(String choice) async {
    if (_answered) return;
    _answered = true;
    _selectedAnswer = choice;
    final isCorrect = choice == _cur.readingKo;
    if (isCorrect) {
      _score++;
      try {
        await _audio.play(AssetSource('sounds/success.mp3'));
      } catch (_) {}
    } else {
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
      _showResult();
    }
  }

  void _showResult() {
    final accuracy = (_score / _pool.length * 100).toInt();
    final emoji = accuracy >= 80 ? '🏆' : accuracy >= 60 ? '👍' : '💪';
    final msg = accuracy >= 80 ? '훌륭해요!' : accuracy >= 60 ? '잘했어요!' : '다시 도전!';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$emoji $msg', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [widget.color, widget.color.withValues(alpha: 0.65)]),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _idx = 0;
                    _score = 0;
                    _pool.shuffle();
                    _loadQuestion();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('다시 도전',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('종료'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (_idx + 1) / _pool.length;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF10111B) : const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: Text('${widget.title} 퀴즈',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Text('${_idx + 1} / ${_pool.length}',
                      style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.grey,
                          fontSize: 13)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor:
                            isDark ? Colors.white12 : Colors.grey.shade200,
                        color: widget.color,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$_score점',
                      style: TextStyle(
                          color: widget.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF191B2A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border:
                      Border.all(color: widget.color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      _cur.character,
                      style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: widget.color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _cur.romaji,
                      style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white54 : Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('한국어 독음을 선택하세요',
                  style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey,
                      fontSize: 13)),
              const SizedBox(height: 16),
              ...List.generate(2, (row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: List.generate(2, (col) {
                      final i = row * 2 + col;
                      if (i >= _options.length) {
                        return const Expanded(child: SizedBox());
                      }
                      final opt = _options[i];
                      final isCorrect = opt == _cur.readingKo;
                      final isSelected = _selectedAnswer == opt;

                      Color btnColor;
                      if (!_answered) {
                        btnColor = isDark
                            ? const Color(0xFF252840)
                            : Colors.grey.shade100;
                      } else if (isCorrect) {
                        btnColor = const Color(0xFF4CAF50);
                      } else if (isSelected) {
                        btnColor = const Color(0xFFE53935);
                      } else {
                        btnColor = isDark
                            ? const Color(0xFF252840)
                            : Colors.grey.shade100;
                      }

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: col == 1 ? 8 : 0),
                          child: GestureDetector(
                            onTap: () => _select(opt),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 64,
                              decoration: BoxDecoration(
                                color: btnColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: !_answered
                                      ? (isDark
                                          ? Colors.white12
                                          : Colors.grey.shade300)
                                      : isCorrect
                                          ? const Color(0xFF4CAF50)
                                          : isSelected
                                              ? const Color(0xFFE53935)
                                              : (isDark
                                                  ? Colors.white12
                                                  : Colors.grey.shade300),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  opt,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _answered &&
                                            (isCorrect || isSelected)
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
