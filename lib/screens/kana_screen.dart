import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/kana_item.dart';
import '../services/ad_service.dart';
import 'handwriting_practice_screen.dart';
import 'tts_helper.dart';
import 'kana_quiz_screen.dart';

class KanaScreen extends StatefulWidget {
  final String title;
  final List<KanaItem> items;
  final Color color;

  const KanaScreen({
    super.key,
    required this.title,
    required this.items,
    required this.color,
  });

  @override
  State<KanaScreen> createState() => _KanaScreenState();
}

class _KanaScreenState extends State<KanaScreen> {
  final TTSHelper _tts = TTSHelper();
  String _filter = '전체';
  BannerAd? _bannerAd;
  bool _bannerReady = false;

  static const _rowLabels = [
    '전체',
    'あ行',
    'か行',
    'さ行',
    'た行',
    'な行',
    'は行',
    'ま行',
    'や行',
    'ら行',
    'わ行',
    '탁음/반탁음',
  ];
  static const _katRowLabels = [
    '전체',
    'ア行',
    'カ行',
    'サ行',
    'タ行',
    'ナ行',
    'ハ行',
    'マ行',
    'ヤ行',
    'ラ行',
    'ワ行',
    '탁음/반탁음',
  ];

  static const _hiraganaRows = {
    'あ行': ['あ', 'い', 'う', 'え', 'お'],
    'か行': ['か', 'き', 'く', 'け', 'こ'],
    'さ行': ['さ', 'し', 'す', 'せ', 'そ'],
    'た行': ['た', 'ち', 'つ', 'て', 'と'],
    'な行': ['な', 'に', 'ぬ', 'ね', 'の'],
    'は行': ['は', 'ひ', 'ふ', 'へ', 'ほ'],
    'ま行': ['ま', 'み', 'む', 'め', 'も'],
    'や行': ['や', 'ゆ', 'よ'],
    'ら行': ['ら', 'り', 'る', 'れ', 'ろ'],
    'わ行': ['わ', 'を', 'ん'],
    '탁음/반탁음': [
      'が',
      'ぎ',
      'ぐ',
      'げ',
      'ご',
      'ざ',
      'じ',
      'ず',
      'ぜ',
      'ぞ',
      'だ',
      'ぢ',
      'づ',
      'で',
      'ど',
      'ば',
      'び',
      'ぶ',
      'べ',
      'ぼ',
      'ぱ',
      'ぴ',
      'ぷ',
      'ぺ',
      'ぽ'
    ],
  };

  static const _katakanaRows = {
    'ア行': ['ア', 'イ', 'ウ', 'エ', 'オ'],
    'カ行': ['カ', 'キ', 'ク', 'ケ', 'コ'],
    'サ行': ['サ', 'シ', 'ス', 'セ', 'ソ'],
    'タ行': ['タ', 'チ', 'ツ', 'テ', 'ト'],
    'ナ行': ['ナ', 'ニ', 'ヌ', 'ネ', 'ノ'],
    'ハ行': ['ハ', 'ヒ', 'フ', 'ヘ', 'ホ'],
    'マ行': ['マ', 'ミ', 'ム', 'メ', 'モ'],
    'ヤ行': ['ヤ', 'ユ', 'ヨ'],
    'ラ行': ['ラ', 'リ', 'ル', 'レ', 'ロ'],
    'ワ行': ['ワ', 'ヲ', 'ン'],
    '탁음/반탁음': [
      'ガ',
      'ギ',
      'グ',
      'ゲ',
      'ゴ',
      'ザ',
      'ジ',
      'ズ',
      'ゼ',
      'ゾ',
      'ダ',
      'ヂ',
      'ヅ',
      'デ',
      'ド',
      'バ',
      'ビ',
      'ブ',
      'ベ',
      'ボ',
      'パ',
      'ピ',
      'プ',
      'ペ',
      'ポ'
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
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

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  List<KanaItem> get _filteredItems {
    if (_filter == '전체') return widget.items;
    final isHiragana = widget.title.contains('히라가나');
    final rowMap = isHiragana ? _hiraganaRows : _katakanaRows;
    final chars = rowMap[_filter] ?? [];
    return widget.items
        .where((item) => chars.contains(item.character))
        .toList();
  }

  List<String> get _filterLabels {
    final isHiragana = widget.title.contains('히라가나');
    return isHiragana ? _rowLabels : _katRowLabels;
  }

  void _showDetail(BuildContext context, KanaItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _KanaDetailSheet(item: item, color: widget.color, tts: _tts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF10111B) : const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz_outlined),
            tooltip: '퀴즈',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => KanaQuizScreen(
                  title: widget.title,
                  items: widget.items,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _filterLabels.length,
              itemBuilder: (context, index) {
                final label = _filterLabels[index];
                final selected = _filter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = label),
                    selectedColor: widget.color,
                    backgroundColor:
                        isDark ? const Color(0xFF191B2A) : Colors.white,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : isDark
                              ? Colors.white70
                              : Colors.black87,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: selected
                          ? widget.color
                          : isDark
                              ? Colors.white24
                              : Colors.grey.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '카드를 탭하면 예시 단어와 TTS를 확인할 수 있어요',
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.grey.shade500),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(
                  12, 12, 12, 12 + MediaQuery.of(context).padding.bottom),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () => _showDetail(context, item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF191B2A) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                          color: widget.color.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.character,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.romaji,
                          style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white60 : Colors.grey),
                        ),
                        Text(
                          item.readingKo,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
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
}

class _KanaDetailSheet extends StatelessWidget {
  final KanaItem item;
  final Color color;
  final TTSHelper tts;

  const _KanaDetailSheet({
    required this.item,
    required this.color,
    required this.tts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        color: isDark ? const Color(0xFF191B2A) : Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Text(
                        item.character,
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(label: '한글 읽기', value: item.readingKo),
                            const SizedBox(height: 6),
                            _InfoRow(label: '로마자', value: item.romaji),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => tts.speak(context, item.character),
                        icon: const Icon(Icons.volume_up,
                            color: Colors.white, size: 32),
                        tooltip: 'TTS 재생',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '예시 단어',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            item.exampleWord,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.exampleMeaning,
                            style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                tts.speak(context, item.exampleWord),
                            icon: Icon(Icons.volume_up, color: color),
                            tooltip: '예시 단어 TTS',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HandwritingPracticeScreen(
                          target: item.character,
                          reading: item.romaji,
                          hint: '${item.character} 문자를 직접 써 보세요',
                          acceptedAnswers: [item.character],
                          color: color,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.draw_outlined),
                    label: const Text('필기 연습'),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
