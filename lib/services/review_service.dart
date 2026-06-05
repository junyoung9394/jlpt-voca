import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ReviewService {
  static const _keyLaunchCount = 'app_launch_count';
  static const _keyReviewRequested = 'review_requested';
  static const _keyReviewSnoozedAt = 'review_snoozed_at';
  static const _keyReviewSnoozeCount = 'review_snooze_count';
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.junyoung.jlptvoca';

  /// 앱 시작 시 main.dart에서 호출 — 실행 횟수를 1 증가시킨다.
  static Future<void> incrementLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyLaunchCount) ?? 0;
    await prefs.setInt(_keyLaunchCount, count + 1);
  }

  /// 퀴즈 완료 / 학습 완료 시점에 호출.
  static Future<void> requestReviewIfEligible(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final requested = prefs.getBool(_keyReviewRequested) ?? false;
    if (requested) return;

    final count = prefs.getInt(_keyLaunchCount) ?? 0;
    final learned = (prefs.getStringList('learned') ?? []).length;
    if (count < 10 && learned < 30) return;

    // "다음에" 최대 2회까지만 허용, 이후 영구 비노출
    final snoozeCount = prefs.getInt(_keyReviewSnoozeCount) ?? 0;
    if (snoozeCount >= 2) return;

    // "다음에" 눌렀던 경우 5회 뒤에 다시 노출
    final snoozedAt = prefs.getInt(_keyReviewSnoozedAt) ?? 0;
    if (snoozedAt > 0 && count < snoozedAt + 5) return;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '앱이 마음에 드셨나요? 😊',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '별점과 리뷰는 앱을 더 좋게 만드는 데 큰 힘이 돼요!\n잠깐 시간 내주시면 정말 감사해요 🙏',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.setInt(_keyReviewSnoozedAt, count);
              await prefs.setInt(_keyReviewSnoozeCount, snoozeCount + 1);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('다음에', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () async {
              await prefs.setBool(_keyReviewRequested, true);
              if (ctx.mounted) Navigator.of(ctx).pop();
              await launchUrl(
                Uri.parse(_playStoreUrl),
                mode: LaunchMode.externalApplication,
              );
            },
            child: const Text('⭐ 리뷰 남기기'),
          ),
        ],
      ),
    );
  }
}
