import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/storage_service.dart';
import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/review_service.dart';
import 'services/daily_word_service.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';

import 'screens/home_screen.dart';
import 'screens/jlpt_level_screen.dart';
import 'screens/my_words_screen.dart';

import 'providers/grammar_provider.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

const _lightSystemOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarBrightness: Brightness.light,
  statusBarIconBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
);

const _darkSystemOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarBrightness: Brightness.dark,
  statusBarIconBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Firebase.initializeApp();
  AnalyticsService.logAppOpen();

  // 스크린샷 촬영 시 true로 변경하면 모든 광고가 비활성화됨
  AdService.adsDisabled = false;
  await MobileAds.instance.initialize();
  await initializeDateFormatting('ko', null);
  await StorageService.init();
  await ReviewService.incrementLaunchCount();

  // 저장된 테마 복원
  final savedTheme =
      (await SharedPreferences.getInstance()).getString('theme_mode') ??
          'light';
  themeModeNotifier.value = switch (savedTheme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  SystemChrome.setSystemUIOverlayStyle(
    themeModeNotifier.value == ThemeMode.dark
        ? _darkSystemOverlayStyle
        : _lightSystemOverlayStyle,
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializePostLaunchServices());
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => GrammarProvider(),
      child: const MyApp(),
    ),
  );
}

Future<void> _initializePostLaunchServices() async {
  try {
    // 오늘의 단어 → 알림·위젯에 전달
    await DailyWordService.saveToPrefs();
    await NotificationService.init();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('notifications_enabled') ?? true) {
      await NotificationService.requestAndroidPermissions();
    }
    await NotificationService.scheduleAll();
    await WidgetService.updateTodayWord();
  } catch (error, stackTrace) {
    debugPrint('Post-launch service initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JLPT 일본어 단어 문법',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [AnalyticsService.observer],
      themeMode: themeModeNotifier.value,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7B61FF)),
        useMaterial3: true,
        fontFamily: 'Dunggeunmiso',
        scaffoldBackgroundColor: const Color(0xFFF8F7FF),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black54),
          titleLarge: TextStyle(color: Colors.black87),
          titleMedium: TextStyle(color: Colors.black87),
          titleSmall: TextStyle(color: Colors.black87),
          labelLarge: TextStyle(color: Colors.black87),
          labelMedium: TextStyle(color: Colors.black54),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: _lightSystemOverlayStyle,
          titleTextStyle: TextStyle(
            fontFamily: 'Dunggeunmiso',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          iconTheme: IconThemeData(color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B61FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Dunggeunmiso',
        scaffoldBackgroundColor: const Color(0xFF12121F),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white70),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF151725),
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: _darkSystemOverlayStyle,
          titleTextStyle: TextStyle(
            fontFamily: 'Dunggeunmiso',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardColor: const Color(0xFF191B2A),
        cardTheme: const CardThemeData(
          color: Color(0xFF191B2A),
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF191B2A),
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIconColor: Colors.white70,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF8E7AFF)),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF151725),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          titleTextStyle: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          subtitleTextStyle: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? const Color(0xFF7B61FF)
                : Colors.grey,
          ),
        ),
        dividerColor: Colors.white12,
      ),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUsageGuide();
      context.read<GrammarProvider>().loadAll();
    });

    _loadBannerAd();
    AdService.loadInterstitialAd();
    AdService.loadRewardedAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _isBannerAdReady = true);
      },
      onFailed: () {
        // 30초 후 재시도
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) _loadBannerAd();
        });
      },
    );
    _bannerAd?.load();
  }

  Future<void> _showUsageGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('guideShown') ?? false;

    if (!shown && mounted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '앱 사용 안내 📚',
            textAlign: TextAlign.center,
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• JLPT N1~N5 레벨별 단어 학습 & 퀴즈'),
                SizedBox(height: 6),
                Text("  ✅ '알겠어요' → +10 XP"),
                Text("  🔄 '모르겠어요' → 복습 리스트 추가"),
                Text("  🎯 퀴즈 정답 → +20 XP"),
                SizedBox(height: 8),
                Text('• JLPT 문법도 함께 학습할 수 있어요'),
                Text('• 🔥 매일 학습하면 스트릭이 쌓여요!'),
                Text('• 🎯 오늘의 목표: 단어 10개'),
                Text('• ⭐ XP를 쌓으면 레벨이 올라가요'),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('시작하기! 🎉'),
              ),
            ),
          ],
        ),
      );

      await prefs.setBool('guideShown', true);
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();

      case 1:
        return const JLPTLevelScreen(mode: Mode.study);

      case 2:
        return const JLPTLevelScreen(mode: Mode.quiz);

      case 3:
        return const MyWordsScreen();

      default:
        return const HomeScreen();
    }
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(_currentIndex),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isBannerAdReady && _bannerAd != null)
            SizedBox(
              width: double.infinity,
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF151725)
                : Colors.white,
            indicatorColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF342F52)
                : const Color(0xFFEDE9FF),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: '학습',
              ),
              NavigationDestination(
                icon: Icon(Icons.quiz_outlined),
                selectedIcon: Icon(Icons.quiz),
                label: '퀴즈',
              ),
              NavigationDestination(
                icon: Icon(Icons.collections_bookmark_outlined),
                selectedIcon: Icon(Icons.collections_bookmark),
                label: '내 단어장',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
