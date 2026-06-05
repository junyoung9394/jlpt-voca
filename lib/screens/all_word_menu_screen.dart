import 'package:flutter/material.dart';
import 'study_screen.dart';
import 'quiz_screen.dart';
import '../data/all_words.dart';

class AllWordsSelectionScreen extends StatelessWidget {
  const AllWordsSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('모든 단어 학습')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(context, '모든 단어 학습하기', () {
              final words = [...allWords]..shuffle();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudyScreen(words: words)),
              );
            }),
            const SizedBox(height: 16),
            _buildButton(context, '모든 단어 퀴즈 풀기', () {
              final words = [...allWords]..shuffle();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        QuizScreen(words: words, limit: allWords.length)),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, VoidCallback onPressed) {
    return SizedBox(
      width: 240,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple[100],
          foregroundColor: Colors.deepPurple[900],
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
