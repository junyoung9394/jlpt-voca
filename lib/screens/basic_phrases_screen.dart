import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/basic_japanese_item.dart';
import '../services/ad_service.dart';
import 'tts_helper.dart';

class BasicPhrasesScreen extends StatefulWidget {
  final String title;
  final List<BasicJapaneseItem> items;
  final Color color;
  final IconData icon;

  const BasicPhrasesScreen({
    super.key,
    required this.title,
    required this.items,
    required this.color,
    this.icon = Icons.chat_bubble_outline,
  });

  @override
  State<BasicPhrasesScreen> createState() => _BasicPhrasesScreenState();
}

class _BasicPhrasesScreenState extends State<BasicPhrasesScreen> {
  final TTSHelper _tts = TTSHelper();
  String _searchQuery = '';
  BannerAd? _bannerAd;
  bool _bannerReady = false;

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

  List<BasicJapaneseItem> get _filteredItems {
    final q = _searchQuery.trim();
    if (q.isEmpty) return widget.items;
    return widget.items.where((item) {
      return item.japanese.contains(q) ||
          item.readingKo.contains(q) ||
          item.meaning.contains(q);
    }).toList();
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: '일본어, 한글 발음, 뜻 검색',
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
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      '검색 결과가 없습니다.',
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                          fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                        12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _PhraseCard(
                        item: items[index],
                        color: widget.color,
                        tts: _tts,
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

class _PhraseCard extends StatelessWidget {
  final BasicJapaneseItem item;
  final Color color;
  final TTSHelper tts;

  const _PhraseCard({
    required this.item,
    required this.color,
    required this.tts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191B2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.japanese,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '한글 발음',
                        style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.readingKo,
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '뜻',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.meaning,
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => tts.speak(context, item.japanese),
            icon: Icon(Icons.volume_up, color: color),
            tooltip: 'TTS 재생',
          ),
        ],
      ),
    );
  }
}
