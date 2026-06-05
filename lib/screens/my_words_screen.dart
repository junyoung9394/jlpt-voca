import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../data/all_words.dart';
import 'favorites_screen.dart';
import 'wrong_notes_screen.dart';
import 'study_screen.dart';

class MyWordsScreen extends StatefulWidget {
  final int initialTab;
  const MyWordsScreen({super.key, this.initialTab = 0});

  @override
  State<MyWordsScreen> createState() => _MyWordsScreenState();
}

class _MyWordsScreenState extends State<MyWordsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _clearFavorites() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('즐겨찾기 초기화'),
        content: const Text('모든 즐겨찾기를 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await StorageService.clearFavorites();
    setState(() {});
  }

  Future<void> _clearWrong() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('오답노트 초기화'),
        content: const Text('모든 오답을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await StorageService.clearWrongNotes();
    setState(() {});
  }

  List<Map<String, String>> _getDueWordMaps() {
    final dueKeys = StorageService.getDueWords().toSet();
    return allWords.where((w) => dueKeys.contains(w['word'])).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tabIdx = _tabController.index;
    final hasFav = StorageService.getFavorites().isNotEmpty;
    final hasWrong = StorageService.getWrongNotes().isNotEmpty;
    final dueWords = _getDueWordMaps();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 단어장',
            style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          if (tabIdx == 1 && hasFav)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '즐겨찾기 초기화',
              onPressed: _clearFavorites,
            ),
          if (tabIdx == 2 && hasWrong)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '오답노트 초기화',
              onPressed: _clearWrong,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.replay, size: 16),
                  const SizedBox(width: 4),
                  Text('복습 (${dueWords.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 16),
                  const SizedBox(width: 4),
                  Text('즐겨찾기 (${StorageService.getFavorites().length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.note_alt, size: 16),
                  const SizedBox(width: 4),
                  Text('오답 (${StorageService.getWrongNotes().length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReviewTab(dueWords: dueWords),
          const FavoritesScreen(embedded: true),
          const WrongNotesScreen(embedded: true),
        ],
      ),
    );
  }
}

class _ReviewTab extends StatelessWidget {
  final List<Map<String, String>> dueWords;
  const _ReviewTab({required this.dueWords});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (dueWords.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('복습 대기 단어가 없어요!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('단어를 학습하면 복습 스케줄이 생성됩니다',
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('⏰', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${dueWords.length}개 단어 복습 대기',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('지금 복습하고 기억을 강화하세요!',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              StudyScreen(words: [...dueWords]..shuffle())));
                },
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('학습 시작'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: dueWords.length,
            itemBuilder: (_, i) {
              final w = dueWords[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF191B2A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6)
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w['word'] ?? '',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          if ((w['kanji'] ?? '').isNotEmpty &&
                              w['kanji'] != '-')
                            Text(w['kanji'] ?? '',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey)),
                        ],
                      ),
                    ),
                    Text(w['meaning'] ?? '',
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.grey.shade600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.replay,
                        size: 16, color: Colors.orange),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
