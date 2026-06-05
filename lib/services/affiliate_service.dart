import 'package:url_launcher/url_launcher.dart';

class AffiliateService {
  // ✅ 쿠팡 파트너스 링크 (직접 발급받은 링크)
  static const _coupangLink = 'https://link.coupang.com/a/eAoNWK';
  static const _disclaimer = '이 포스팅은 쿠팡 파트너스 활동의 일환으로,\n이에 따른 일정액의 수수료를 제공받습니다.';

  // 교재 추천 목록
  static const List<Map<String, String>> books = [
    {
      'title': 'JLPT 한권으로 합격',
      'subtitle': 'N1~N5 전 레벨 교재',
      'emoji': '📗',
      'url': _coupangLink,
    },
    {
      'title': '일본어 단어장 JLPT N3',
      'subtitle': '시험 빈출 단어 완벽 정리',
      'emoji': '📘',
      'url': _coupangLink,
    },
    {
      'title': 'JLPT N2 실전 모의고사',
      'subtitle': '최신 기출 문제 수록',
      'emoji': '📕',
      'url': _coupangLink,
    },
  ];

  static String get disclaimer => _disclaimer;

  /// 쿠팡 링크 열기 (외부 브라우저)
  static Future<bool> openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// 기본 쿠팡 파트너스 링크 열기
  static Future<bool> openCoupang() => openLink(_coupangLink);
}
