import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'practice_answer_utils.dart';

class PronunciationPracticeSheet extends StatefulWidget {
  final Map<String, String> word;

  const PronunciationPracticeSheet({super.key, required this.word});

  @override
  State<PronunciationPracticeSheet> createState() =>
      _PronunciationPracticeSheetState();
}

class _PronunciationPracticeSheetState
    extends State<PronunciationPracticeSheet> {
  final _speech = SpeechToText();
  bool _ready = false;
  bool _listening = false;
  String? _japaneseLocale;
  String _recognized = '';
  bool? _correct;

  Future<void> _listen() async {
    if (!_ready) {
      _ready = await _speech.initialize(
        onStatus: (status) {
          if (mounted && status == 'done') {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (!_ready) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('마이크와 음성 인식 권한을 허용해 주세요.')),
          );
        }
        return;
      }
      final locales = await _speech.locales();
      for (final locale in locales) {
        if (locale.localeId.toLowerCase().startsWith('ja')) {
          _japaneseLocale = locale.localeId;
          break;
        }
      }
    }
    setState(() {
      _recognized = '';
      _correct = null;
      _listening = true;
    });
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final text = result.recognizedWords;
        setState(() {
          _recognized = text;
          if (result.finalResult && text.trim().isNotEmpty) {
            _correct =
                matchesPracticeAnswer(wordPracticeAnswers(widget.word), text);
            _listening = false;
          }
        });
      },
      listenOptions: SpeechListenOptions(
        localeId: _japaneseLocale,
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 18),
            const Text('발음 평가',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.word['word'] ?? '',
                style: const TextStyle(
                    color: Color(0xFF7B61FF),
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
            Text(widget.word['meaning'] ?? '',
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey.shade600)),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _listening ? _speech.stop : _listen,
              style: FilledButton.styleFrom(
                backgroundColor: _listening
                    ? const Color(0xFFE91E63)
                    : const Color(0xFF7B61FF),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              ),
              icon: Icon(_listening ? Icons.stop : Icons.mic),
              label: Text(_listening ? '듣는 중...' : '발음 시작'),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF202334) : const Color(0xFFF7F5FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _recognized.isEmpty ? '말한 내용이 여기에 표시됩니다.' : _recognized,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _recognized.isEmpty ? Colors.grey : null,
                    fontSize: 16),
              ),
            ),
            if (_correct != null) ...[
              const SizedBox(height: 14),
              Text(
                _correct! ? '정답이에요. 발음이 인식되었습니다!' : '오답이에요. 다시 말해 보세요.',
                style: TextStyle(
                  color: _correct! ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
