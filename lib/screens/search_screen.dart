import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/all_words.dart';
import '../services/tts_settings_service.dart';
import 'study_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  String _query = '';

  static const _accentColor = Color(0xFF7B61FF);

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(await TtsSettingsService.getSpeed());
  }

  @override
  void dispose() {
    _controller.dispose();
    _tts.stop();
    super.dispose();
  }

  static String _romajiToHiragana(String romaji) {
    final patterns = [
      ['sha', 'しゃ'], ['shi', 'し'], ['shu', 'しゅ'], ['sho', 'しょ'],
      ['chi', 'ち'], ['cha', 'ちゃ'], ['chu', 'ちゅ'], ['cho', 'ちょ'],
      ['tsu', 'つ'],
      ['kya', 'きゃ'], ['kyu', 'きゅ'], ['kyo', 'きょ'],
      ['nya', 'にゃ'], ['nyu', 'にゅ'], ['nyo', 'にょ'],
      ['hya', 'ひゃ'], ['hyu', 'ひゅ'], ['hyo', 'ひょ'],
      ['mya', 'みゃ'], ['myu', 'みゅ'], ['myo', 'みょ'],
      ['rya', 'りゃ'], ['ryu', 'りゅ'], ['ryo', 'りょ'],
      ['gya', 'ぎゃ'], ['gyu', 'ぎゅ'], ['gyo', 'ぎょ'],
      ['ja', 'じゃ'], ['ju', 'じゅ'], ['jo', 'じょ'],
      ['ka', 'か'], ['ki', 'き'], ['ku', 'く'], ['ke', 'け'], ['ko', 'こ'],
      ['sa', 'さ'], ['si', 'し'], ['su', 'す'], ['se', 'せ'], ['so', 'そ'],
      ['ta', 'た'], ['ti', 'ち'], ['tu', 'つ'], ['te', 'て'], ['to', 'と'],
      ['na', 'な'], ['ni', 'に'], ['nu', 'ぬ'], ['ne', 'ね'], ['no', 'の'],
      ['ha', 'は'], ['hi', 'ひ'], ['fu', 'ふ'], ['hu', 'ふ'], ['he', 'へ'], ['ho', 'ほ'],
      ['ma', 'ま'], ['mi', 'み'], ['mu', 'む'], ['me', 'め'], ['mo', 'も'],
      ['ya', 'や'], ['yu', 'ゆ'], ['yo', 'よ'],
      ['ra', 'ら'], ['ri', 'り'], ['ru', 'る'], ['re', 'れ'], ['ro', 'ろ'],
      ['wa', 'わ'], ['wo', 'を'],
      ['ga', 'が'], ['gi', 'ぎ'], ['gu', 'ぐ'], ['ge', 'げ'], ['go', 'ご'],
      ['za', 'ざ'], ['zi', 'じ'], ['zu', 'ず'], ['ze', 'ぜ'], ['zo', 'ぞ'],
      ['da', 'だ'], ['de', 'で'], ['do', 'ど'],
      ['ba', 'ば'], ['bi', 'び'], ['bu', 'ぶ'], ['be', 'べ'], ['bo', 'ぼ'],
      ['pa', 'ぱ'], ['pi', 'ぴ'], ['pu', 'ぷ'], ['pe', 'ぺ'], ['po', 'ぽ'],
      ['a', 'あ'], ['i', 'い'], ['u', 'う'], ['e', 'え'], ['o', 'お'],
      ['n', 'ん'],
    ];

    final result = StringBuffer();
    int i = 0;
    final lower = romaji.toLowerCase();
    const consonants = 'bcdfghjklmnpqrstvwxyz';

    while (i < lower.length) {
      if (i + 1 < lower.length &&
          lower[i] == lower[i + 1] &&
          consonants.contains(lower[i])) {
        result.write('っ');
        i++;
        continue;
      }
      bool matched = false;
      for (final pair in patterns) {
        final pattern = pair[0];
        if (lower.startsWith(pattern, i)) {
          result.write(pair[1]);
          i += pattern.length;
          matched = true;
          break;
        }
      }
      if (!matched) {
        result.write(lower[i]);
        i++;
      }
    }
    return result.toString();
  }

  List<Map<String, String>> get _results {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    final qHiragana = _romajiToHiragana(q);
    return allWords.where((w) {
      return (w['word'] ?? '').contains(q) ||
          (w['word'] ?? '').contains(qHiragana) ||
          (w['kanji'] ?? '').contains(q) ||
          (w['meaning'] ?? '').contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 검색'),
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: '일본어 단어, 한자, 뜻으로 검색...',
                prefixIcon: const Icon(Icons.search, color: _accentColor),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF191B2A) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // 결과 수
          if (_query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  results.isEmpty ? '검색 결과 없음' : '검색 결과 ${results.length}개',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),

          // 결과 리스트
          Expanded(
            child: _query.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🔍', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text(
                          '일본어 단어, 한자, 뜻으로\n검색할 수 있어요',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('😅', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              '"$_query" 검색 결과가 없어요',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final w = results[i];
                          final hasKanji = (w['kanji'] ?? '').isNotEmpty;
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudyScreen(words: [w]),
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF191B2A)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          w['word'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (hasKanji) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            w['kanji'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey),
                                          ),
                                        ],
                                        const SizedBox(height: 2),
                                        Text(
                                          w['meaning'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: _accentColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _tts.speak(w['word'] ?? ''),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEDE9FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.volume_up_rounded,
                                        color: _accentColor,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
