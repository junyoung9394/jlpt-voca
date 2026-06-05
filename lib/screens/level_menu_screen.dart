import 'package:flutter/material.dart';
import 'jlpt_level_screen.dart';

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('레벨별 학습')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(context, '레벨별 단어 학습하기', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const JLPTLevelScreen(mode: Mode.study),
                ),
              );
            }),
            const SizedBox(height: 16),
            _buildButton(context, '레벨별 퀴즈 풀기', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const JLPTLevelScreen(mode: Mode.quiz),
                ),
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
