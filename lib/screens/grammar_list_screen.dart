import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/grammar_item.dart';
import '../providers/grammar_provider.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import 'tts_helper.dart';
import '../utils/hiragana_to_korean.dart';

class GrammarListScreen extends StatefulWidget {
  final String level;
  final Color color;

  const GrammarListScreen({
    super.key,
    required this.level,
    required this.color,
  });

  @override
  State<GrammarListScreen> createState() => _GrammarListScreenState();
}

class _GrammarListScreenState extends State<GrammarListScreen> {
  String _searchQuery = '';
  String _filterType = '전체';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logViewGrammarList(widget.level);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GrammarProvider>();
    final items = provider.getByLevel(widget.level);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final types = <String>[
      '전체',
      ...items
          .map((item) => item.type)
          .where((type) => type.isNotEmpty)
          .toSet(),
    ];

    final filtered = items.where((grammar) {
      final search = _searchQuery.trim();

      final matchSearch = search.isEmpty ||
          grammar.pattern.contains(search) ||
          grammar.meaning.contains(search) ||
          grammar.explanation.contains(search) ||
          grammar.connection.contains(search);

      final matchType = _filterType == '전체' || grammar.type == _filterType;

      return matchSearch && matchType;
    }).toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF10111B) : const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: Text(
          '${widget.level} 문법',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: '문형, 의미, 설명 검색',
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
          if (types.length > 1)
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: types.length,
                itemBuilder: (context, index) {
                  final type = types[index];
                  final selected = _filterType == type;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _filterType = type;
                        });
                      },
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
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      items.isEmpty
                          ? '아직 ${widget.level} 문법 데이터가 없습니다.'
                          : '검색 결과가 없습니다.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        fontSize: 15,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                        12, 4, 12, 4 + MediaQuery.of(context).padding.bottom),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final grammar = filtered[index];
                      final isBookmarked = provider.isBookmarked(grammar.id);
                      final isMastered = provider.isMastered(grammar.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isMastered
                                ? widget.color
                                : isDark
                                    ? Colors.white12
                                    : Colors.grey.shade200,
                            child: Text(
                              _numberLabel(grammar.id),
                              style: TextStyle(
                                fontSize: 12,
                                color: isMastered
                                    ? Colors.white
                                    : isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            grammar.pattern,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 3),
                              Text(
                                grammar.meaning,
                                style: const TextStyle(fontSize: 13),
                              ),
                              if (grammar.connection.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '접속: ${grammar.connection}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (grammar.type.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    grammar.type,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: widget.color,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: Icon(
                                  isBookmarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color:
                                      isBookmarked ? Colors.amber : Colors.grey,
                                  size: 21,
                                ),
                                onPressed: () {
                                  provider.toggleBookmark(grammar.id);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GrammarDetailScreen(
                                  grammar: grammar,
                                  color: widget.color,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _numberLabel(String id) {
    final digits = RegExp(r'\d+').allMatches(id).map((m) => m.group(0)).join();

    if (digits.isEmpty) {
      return '文';
    }

    if (digits.length <= 2) {
      return digits;
    }

    return digits.substring(digits.length - 2);
  }
}

class GrammarDetailScreen extends StatefulWidget {
  final GrammarItem grammar;
  final Color color;

  const GrammarDetailScreen({
    super.key,
    required this.grammar,
    required this.color,
  });

  @override
  State<GrammarDetailScreen> createState() => _GrammarDetailScreenState();
}

class _GrammarDetailScreenState extends State<GrammarDetailScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    _bannerAd = AdService.createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _isBannerAdReady = true);
      },
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grammar = widget.grammar;
    final provider = context.watch<GrammarProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isBookmarked = provider.isBookmarked(grammar.id);
    final isMastered = provider.isMastered(grammar.id);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF10111B) : const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: Text(
          grammar.level,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: () {
              provider.toggleBookmark(grammar.id);
            },
            tooltip: '북마크',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatternHeader(grammar),
                  const SizedBox(height: 16),
                  if (grammar.connection.isNotEmpty) ...[
                    _SectionCard(
                      title: '🔗 접속',
                      child: Text(
                        grammar.connection,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _SectionCard(
                    title: '📖 설명',
                    child: Text(
                      grammar.explanation.isNotEmpty
                          ? grammar.explanation
                          : '설명이 없습니다.',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: '✏️ 예문',
                    child: grammar.examples.isEmpty
                        ? const Text(
                            '예문이 없습니다.',
                            style: TextStyle(fontSize: 14),
                          )
                        : Column(
                            children: grammar.examples
                                .map(
                                  (example) => _ExampleTile(
                                    example: example,
                                    color: widget.color,
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  if (grammar.caution.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: '⚠️ 주의',
                      backgroundColor: isDark
                          ? const Color(0xFF282014)
                          : Colors.orange.shade50,
                      child: Text(
                        grammar.caution,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFFFFCC80)
                              : Colors.orange.shade900,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        provider.toggleMastered(grammar.id);
                      },
                      icon: Icon(
                        isMastered
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        isMastered ? '학습 완료 ✓' : '학습 완료로 표시',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMastered
                            ? widget.color
                            : isDark
                                ? const Color(0xFF191B2A)
                                : Colors.white,
                        foregroundColor: isMastered
                            ? Colors.white
                            : isDark
                                ? Colors.white
                                : Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isMastered
                              ? widget.color
                              : isDark
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (_isBannerAdReady && _bannerAd != null)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget _buildPatternHeader(GrammarItem grammar) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (grammar.type.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                grammar.type,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            grammar.pattern,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            grammar.meaning,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? backgroundColor;

  const _SectionCard({
    required this.title,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? const Color(0xFF191B2A) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ExampleTile extends StatefulWidget {
  final GrammarExample example;
  final Color color;

  const _ExampleTile({
    required this.example,
    required this.color,
  });

  @override
  State<_ExampleTile> createState() => _ExampleTileState();
}

class _ExampleTileState extends State<_ExampleTile> {
  bool _showReading = false;
  bool _showTranslation = false;
  final TTSHelper _tts = TTSHelper();

  @override
  Widget build(BuildContext context) {
    // readingKo가 있으면 직접 사용, 없으면 reading 필드에서 자동 변환
    final koreanReading = widget.example.readingKo.isNotEmpty
        ? widget.example.readingKo
        : (widget.example.reading.isNotEmpty
            ? HiraganaToKorean.convert(widget.example.reading)
            : '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202334) : const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.example.sentence,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _tts.speak(context, widget.example.sentence),
                icon: Icon(Icons.volume_up, color: widget.color, size: 20),
                tooltip: 'TTS 재생',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (koreanReading.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '한글 발음',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      koreanReading,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.color.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _showReading = !_showReading;
              });
            },
            child: Row(
              children: [
                Icon(
                  _showReading ? Icons.visibility : Icons.visibility_off,
                  size: 15,
                  color: widget.color,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _showReading ? widget.example.reading : '후리가나 보기',
                    style: TextStyle(
                      fontSize: 13,
                      color: _showReading
                          ? isDark
                              ? Colors.white70
                              : Colors.grey.shade700
                          : widget.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                _showTranslation = !_showTranslation;
              });
            },
            child: Row(
              children: [
                Icon(
                  Icons.translate,
                  size: 15,
                  color: Colors.blue.shade400,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _showTranslation ? widget.example.translation : '번역 보기',
                    style: TextStyle(
                      fontSize: 13,
                      color: _showTranslation
                          ? Colors.blue.shade700
                          : Colors.blue.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
