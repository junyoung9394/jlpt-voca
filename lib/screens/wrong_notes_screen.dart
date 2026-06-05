import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/storage_service.dart';
import '../services/tts_settings_service.dart';
import 'study_screen.dart';
import 'quiz_screen.dart';
import '../data/n1_words.dart';
import '../data/n2_words.dart';
import '../data/n3_words.dart';
import '../data/n4_words.dart';
import '../data/n5_words.dart';

class WrongNotesScreen extends StatefulWidget {
  final bool embedded;
  const WrongNotesScreen({super.key, this.embedded = false});
  @override
  State<WrongNotesScreen> createState() => _WrongNotesScreenState();
}

class _WrongNotesScreenState extends State<WrongNotesScreen>
    with WidgetsBindingObserver {
  late List<String> _wrongKeys;
  final FlutterTts _tts = FlutterTts();
  String _search = '';

  static const _accentColor = Color(0xFF7B61FF);

  @override
  void initState() {
    super.initState();
    _initTts();
    _load();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(await TtsSettingsService.getSpeed());
  }

  void _load() => setState(() => _wrongKeys = StorageService.getWrongNotes());

  Map<String, String> _find(String key) {
    final all = [...n1Words, ...n2Words, ...n3Words, ...n4Words, ...n5Words];
    return all.firstWhere((e) => e['word'] == key, orElse: () => {});
  }

  Future<void> _remove(String key) async {
    await StorageService.removeWrong(key);
    _load();
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('오답노트 초기화'),
              content: const Text('모든 오답을 삭제할까요?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child:
                        const Text('삭제', style: TextStyle(color: Colors.red))),
              ],
            ));
    if (ok == true) {
      await StorageService.clearWrongNotes();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _search.isEmpty
        ? _wrongKeys
        : _wrongKeys.where((k) {
            final w = _find(k);
            return (w['word'] ?? '').contains(_search) ||
                (w['meaning'] ?? '').contains(_search);
          }).toList();

    final body = Column(
        children: [
          // ── 검색바 ──
          if (_wrongKeys.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: '단어 검색...',
                  prefixIcon: const Icon(Icons.search, color: Colors.red),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF191B2A) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

          // ── 리스트 ──
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('✅', style: TextStyle(fontSize: 52)),
                          const SizedBox(height: 12),
                          Text(
                            _wrongKeys.isEmpty
                                ? '오답이 없어요! 완벽해요 👍\n퀴즈를 풀면 오답이 자동 저장돼요'
                                : '검색 결과가 없어요',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 15, color: Colors.grey),
                          ),
                        ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final key = filtered[i];
                      final w = _find(key);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF191B2A) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.shade100),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.red.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.red, size: 20),
                          ),
                          title: Text(w['word'] ?? '',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((w['kanji'] ?? '').isNotEmpty)
                                Text(w['kanji'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.grey)),
                              Text(w['meaning'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _tts.speak(w['word'] ?? ''),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                      color: Color(0xFFEDE9FF),
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.volume_up_rounded,
                                      color: _accentColor, size: 18),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _remove(key),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 18),
                                ),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                  builder: (_) => StudyScreen(words: [w]))),
                        ),
                      );
                    },
                  ),
          ),

          // ── 하단 버튼 ──
          if (_wrongKeys.isNotEmpty)
            Container(
              color: isDark ? const Color(0xFF151725) : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final words = _wrongKeys
                            .map(_find)
                            .where((w) => w.isNotEmpty)
                            .toList();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => StudyScreen(words: words)));
                      },
                      icon: const Icon(Icons.menu_book, size: 18),
                      label: Text('학습 (${_wrongKeys.length}개)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final words = _wrongKeys
                            .map(_find)
                            .where((w) => w.isNotEmpty)
                            .toList();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => QuizScreen(
                                    words: words, limit: words.length)));
                      },
                      icon: const Icon(Icons.quiz_outlined, size: 18),
                      label: const Text('오답 퀴즈'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? const Color(0xFF191B2A) : Colors.white,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text('오답노트 (${_wrongKeys.length})'),
        actions: [
          if (_wrongKeys.isNotEmpty)
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: _clearAll),
        ],
      ),
      body: body,
    );
  }
}
