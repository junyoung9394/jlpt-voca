import 'package:flutter/material.dart';
import '../services/affiliate_service.dart';

class BookScreen extends StatelessWidget {
  const BookScreen({super.key});

  static const _accentColor = Color(0xFF7B61FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 교재 추천'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 상단 배너
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7B61FF), Color(0xFFFF6B9D)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📚', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 10),
                  const Text('JLPT 합격을 위한\n추천 교재',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text('합격 경험자들이 추천하는 교재를 만나보세요',
                      style: TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: AffiliateService.openCoupang,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🛒', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Text('쿠팡에서 교재 보기',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF7B61FF))),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF7B61FF)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 교재 카드 목록
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('추천 교재', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            const SizedBox(height: 10),

            ...AffiliateService.books.map((book) => GestureDetector(
              onTap: () => AffiliateService.openLink(book['url']!),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _accentColor.withOpacity(0.08), blurRadius: 12, offset: const Offset(0,4))],
                  border: Border.all(color: _accentColor.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(book['emoji']!, style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book['title']!,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          Text(book['subtitle']!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('보기', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )),

            const SizedBox(height: 20),

            // ✅ 파트너스 필수 고지 문구
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                  const SizedBox(height: 6),
                  Text(
                    AffiliateService.disclaimer,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
