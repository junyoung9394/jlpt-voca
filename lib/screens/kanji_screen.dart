import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/kanji_item.dart';
import '../data/kanji_data.dart';
import '../services/ad_service.dart';
import 'handwriting_practice_screen.dart';
import 'tts_helper.dart';

class KanjiScreen extends StatefulWidget {
  const KanjiScreen({super.key});

  @override
  State<KanjiScreen> createState() => _KanjiScreenState();
}

class _KanjiScreenState extends State<KanjiScreen> {
  final TTSHelper _tts = TTSHelper();
  int _gradeFilter = 0; // 0 = 전체
  String _searchQuery = '';
  BannerAd? _bannerAd;
  bool _bannerReady = false;

  static const _accentColor = Color(0xFFE65100);

  static const _gradeColors = {
    1: Color(0xFFE53935), // 빨강
    2: Color(0xFFE67C00), // 주황
    3: Color(0xFF2E7D32), // 초록
    4: Color(0xFF1565C0), // 파랑
    5: Color(0xFF6A1B9A), // 보라
    6: Color(0xFF00838F), // 청록
  };

  Color _colorForGrade(int grade) => _gradeColors[grade] ?? _accentColor;

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

  List<KanjiItem> get _filteredItems {
    return kanjiData.where((item) {
      final matchGrade = _gradeFilter == 0 || item.grade == _gradeFilter;
      final q = _searchQuery.trim();
      final matchSearch = q.isEmpty ||
          item.kanji.contains(q) ||
          item.meaning.contains(q) ||
          item.onyomi.contains(q) ||
          item.kunyomi.contains(q);
      return matchGrade && matchSearch;
    }).toList();
  }

  void _showDetail(BuildContext context, KanjiItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _KanjiDetailSheet(item: item, tts: _tts),
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
        title:
            const Text('교육한자', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 검색창
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: '한자, 뜻, 음독, 훈독 검색',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF191B2A) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            // 학년 필터
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  _GradeChip(
                    label: '전체',
                    selected: _gradeFilter == 0,
                    color: _accentColor,
                    onSelected: () => setState(() => _gradeFilter = 0),
                  ),
                  for (int g = 1; g <= 6; g++)
                    _GradeChip(
                      label: '$g학년',
                      selected: _gradeFilter == g,
                      color: _colorForGrade(g),
                      onSelected: () => setState(() => _gradeFilter = g),
                    ),
                ],
              ),
            ),
            // 카운트
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${items.length}자',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '탭하면 자세히 볼 수 있어요',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            // 그리드
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        '검색 결과가 없습니다.',
                        style: TextStyle(
                            color:
                                isDark ? Colors.white70 : Colors.grey.shade600,
                            fontSize: 15),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final gradeColor = _colorForGrade(item.grade);
                        return GestureDetector(
                          onTap: () => _showDetail(context, item),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF191B2A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: gradeColor.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                  color: gradeColor.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.kanji,
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: gradeColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.meaning.split(',').first.trim(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: gradeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${item.grade}학년',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: gradeColor,
                                        fontWeight: FontWeight.bold),
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

// ── 학년 필터 칩 ──────────────────────────────────────────
class _GradeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onSelected;

  const _GradeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: color,
        backgroundColor: isDark ? const Color(0xFF191B2A) : Colors.white,
        labelStyle: TextStyle(
          color: selected
              ? Colors.white
              : isDark
                  ? Colors.white70
                  : Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        side: BorderSide(
            color: selected
                ? color
                : isDark
                    ? Colors.white24
                    : Colors.grey.shade300),
      ),
    );
  }
}

// ── 상세 바텀시트 ─────────────────────────────────────────
class _KanjiDetailSheet extends StatelessWidget {
  final KanjiItem item;
  final TTSHelper tts;

  const _KanjiDetailSheet({required this.item, required this.tts});

  static const _gradeColors = {
    1: Color(0xFFE53935),
    2: Color(0xFFE67C00),
    3: Color(0xFF2E7D32),
    4: Color(0xFF1565C0),
    5: Color(0xFF6A1B9A),
    6: Color(0xFF00838F),
  };

  @override
  Widget build(BuildContext context) {
    final gradeColor = _gradeColors[item.grade] ?? const Color(0xFFE65100);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF191B2A) : Colors.white,
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 드래그 핸들
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 한자 헤더
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: gradeColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Text(
                        item.kanji,
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.grade}학년  ·  ${item.strokes}획',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.meaning,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => tts.speak(context, item.kanji),
                        icon: const Icon(Icons.volume_up,
                            color: Colors.white, size: 32),
                        tooltip: 'TTS 재생',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 음독·훈독
                Row(
                  children: [
                    Expanded(
                      child: _ReadingCard(
                        label: '音読み (음독)',
                        value: item.onyomi.isEmpty ? '없음' : item.onyomi,
                        color: const Color(0xFFE53935),
                        onTap: item.onyomi.isNotEmpty
                            ? () =>
                                tts.speak(context, item.onyomi.split('・').first)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ReadingCard(
                        label: '訓読み (훈독)',
                        value: item.kunyomi.isEmpty ? '없음' : item.kunyomi,
                        color: const Color(0xFF1565C0),
                        onTap: item.kunyomi.isNotEmpty
                            ? () => tts.speak(
                                context, item.kunyomi.split('・').first)
                            : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 획수 바
                _StrokesBar(strokes: item.strokes, color: gradeColor),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HandwritingPracticeScreen(
                          target: item.kanji,
                          reading: item.kunyomi.isNotEmpty
                              ? item.kunyomi
                              : item.onyomi,
                          hint: '${item.kanji} 한자를 직접 써 보세요',
                          acceptedAnswers: [item.kanji],
                          color: gradeColor,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.draw_outlined),
                    label: const Text('필기 연습'),
                    style: FilledButton.styleFrom(
                      backgroundColor: gradeColor,
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

class _ReadingCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _ReadingCard({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              if (onTap != null)
                GestureDetector(
                  onTap: onTap,
                  child: Icon(Icons.volume_up, size: 18, color: color),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StrokesBar extends StatelessWidget {
  final int strokes;
  final Color color;

  const _StrokesBar({required this.strokes, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202334) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '획수 (筆順)',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.grey.shade600),
              ),
              Text(
                '$strokes획',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(strokes, (i) {
              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: (i + 1) / strokes * 0.7 + 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
