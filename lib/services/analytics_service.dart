import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  static void logAppOpen() => _analytics.logAppOpen();

  static void logViewHome() =>
      _analytics.logEvent(name: 'view_home');

  static void logViewWordLevel(String level) =>
      _analytics.logEvent(name: 'view_word_level', parameters: {'level': level});

  static void logViewGrammarHome() =>
      _analytics.logEvent(name: 'view_grammar_home');

  static void logViewGrammarList(String level) =>
      _analytics.logEvent(name: 'view_grammar_list', parameters: {'level': level});

  static void logStartWordQuiz({required int questionCount}) =>
      _analytics.logEvent(name: 'start_word_quiz', parameters: {'question_count': questionCount});

  static void logCompleteWordQuiz({required int score, required int total}) =>
      _analytics.logEvent(name: 'complete_word_quiz', parameters: {
        'score': score,
        'total': total,
        'accuracy': total > 0 ? (score / total * 100).toInt() : 0,
      });

  static void logStartGrammarQuiz(String level) =>
      _analytics.logEvent(name: 'start_grammar_quiz', parameters: {'level': level});

  static void logCompleteGrammarQuiz({
    required String level,
    required int score,
    required int total,
  }) =>
      _analytics.logEvent(name: 'complete_grammar_quiz', parameters: {
        'level': level,
        'score': score,
        'total': total,
        'accuracy': total > 0 ? (score / total * 100).toInt() : 0,
      });

  static void logRewardedXpButtonClick() =>
      _analytics.logEvent(name: 'rewarded_xp_button_click');

  static void logRewardedXpGranted(int xpAmount) =>
      _analytics.logEvent(name: 'rewarded_xp_granted', parameters: {'xp_amount': xpAmount});

  static void logInterstitialAdShown() =>
      _analytics.logEvent(name: 'interstitial_ad_shown');

  static void logBannerAdLoaded() =>
      _analytics.logEvent(name: 'banner_ad_loaded');
}
