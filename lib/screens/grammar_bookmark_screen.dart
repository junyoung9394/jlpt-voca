import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/grammar_provider.dart';
import 'grammar_list_screen.dart';

class GrammarBookmarkScreen extends StatelessWidget {
  const GrammarBookmarkScreen({super.key});

  static const List<Color> _levelColors = [
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFFE53935),
  ];

  Color _colorFor(String level) {
    const levels = ['N5', 'N4', 'N3', 'N2', 'N1'];
    final index = levels.indexOf(level);

    if (index >= 0) {
      return _levelColors[index];
    }

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GrammarProvider>();
    final bookmarked = provider.getBookmarked();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF10111B) : const Color(0xFFF8F7FF),
      body: bookmarked.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 72,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '북마크한 문법이 없습니다.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '문법 상세 화면에서 북마크 버튼을 눌러 저장하세요.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: bookmarked.length,
              itemBuilder: (context, index) {
                final grammar = bookmarked[index];
                final color = _colorFor(grammar.level);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          grammar.level,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      grammar.pattern,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      grammar.meaning,
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.bookmark,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        provider.toggleBookmark(grammar.id);
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GrammarDetailScreen(
                            grammar: grammar,
                            color: color,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
