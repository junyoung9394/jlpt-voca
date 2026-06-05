import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'analytics_service.dart';

/// Banner / Interstitial / Rewarded 역할 분리
/// - Interstitial: 7분 cooldown, preload, 자동 재로드
/// - Rewarded: preload, 퀴즈 완료 후 XP 2배
class AdService {
  AdService._();

  /// 스크린샷 등 임시로 광고를 끌 때 true로 설정
  static bool adsDisabled = false;

  // 디버그 모드에서는 Google 공식 테스트 ID 사용 (AdMob 정책 준수)
  static String get _bannerAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-8518556382646891/1166162802';
  static String get _interstitialAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-8518556382646891/7339854762';
  static String get _rewardedAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-8518556382646891/4764803759';

  // ── Interstitial 상태 ─────────────────────────────────
  static InterstitialAd? _interstitialAd;
  static bool _interstitialLoading = false;
  static DateTime? _lastInterstitialShown;
  static const Duration _cooldown = Duration(minutes: 7);
  static int _interstitialRetry = 0;
  static const int _maxRetry = 3;

  // ── Rewarded 상태 ─────────────────────────────────────
  static RewardedAd? _rewardedAd;
  static bool _rewardedLoading = false;
  static int _rewardedRetry = 0;

  // ══════════════════════════════════════════════════════
  // BANNER — 각 화면에서 생성/dispose 직접 관리
  // ══════════════════════════════════════════════════════
  static BannerAd? createBannerAd({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    if (adsDisabled) return null;
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          AnalyticsService.logBannerAdLoaded();
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('[Ad] Banner failed: $error');
          onFailed?.call();
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // INTERSTITIAL — cooldown 7분, preload 구조
  // ══════════════════════════════════════════════════════
  static void loadInterstitialAd() {
    if (adsDisabled || _interstitialLoading || _interstitialAd != null) return;
    _interstitialLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
          _interstitialRetry = 0;
          debugPrint('[Ad] Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _interstitialLoading = false;
          debugPrint('[Ad] Interstitial failed: $error');
          if (_interstitialRetry < _maxRetry) {
            _interstitialRetry++;
            Future.delayed(
              Duration(seconds: _interstitialRetry * 2),
              loadInterstitialAd,
            );
          }
        },
      ),
    );
  }

  static bool get _canShowInterstitial {
    if (_interstitialAd == null) return false;
    if (_lastInterstitialShown == null) return true;
    return DateTime.now().difference(_lastInterstitialShown!) >= _cooldown;
  }

  /// 퀴즈 완료 등 자연스러운 시점에 호출. cooldown 미충족 시 자동 스킵.
  static void showInterstitialAd() {
    if (adsDisabled) return;
    if (!_canShowInterstitial) {
      loadInterstitialAd();
      return;
    }
    final ad = _interstitialAd!;
    _interstitialAd = null;
    _lastInterstitialShown = DateTime.now();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        debugPrint('[Ad] Interstitial show failed: $error');
        loadInterstitialAd();
      },
    );
    AnalyticsService.logInterstitialAdShown();
    ad.show();
    loadInterstitialAd();
  }

  // ══════════════════════════════════════════════════════
  // REWARDED — preload 구조, 퀴즈 완료 후 XP 2배용
  // ══════════════════════════════════════════════════════
  static void loadRewardedAd() {
    if (adsDisabled || _rewardedLoading || _rewardedAd != null) return;
    _rewardedLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoading = false;
          _rewardedRetry = 0;
          debugPrint('[Ad] Rewarded loaded');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _rewardedLoading = false;
          debugPrint('[Ad] Rewarded failed: $error');
          if (_rewardedRetry < _maxRetry) {
            _rewardedRetry++;
            Future.delayed(
              Duration(seconds: _rewardedRetry * 2),
              loadRewardedAd,
            );
          }
        },
      ),
    );
  }

  static bool get isRewardedReady => _rewardedAd != null;

  /// 광고 완전 시청 후에만 [onRewarded] 호출 (닫기 전 지급 불가).
  static Future<void> showRewardedAd({required VoidCallback onRewarded}) async {
    if (adsDisabled) return;
    final ad = _rewardedAd;
    if (ad == null) return;
    _rewardedAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        debugPrint('[Ad] Rewarded show failed: $error');
        loadRewardedAd();
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => onRewarded());
  }
}
