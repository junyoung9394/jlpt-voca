import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'daily_word_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static AndroidScheduleMode _androidScheduleMode =
      AndroidScheduleMode.inexactAllowWhileIdle;

  // 채널 ID (앱마다 고유)
  static const _chDaily = 'daily_study_jp';
  static const _chStreak = 'streak_warning_jp';
  static const _chWeekly = 'weekly_report_jp';

  // 알림 ID
  static const _legacyIdDaily = 1;
  static const _idStreak = 2;
  static const _idWeekly = 3;
  static const _dailyIdStart = 1000;
  static const _dailyScheduleDays = 30;

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo')); // UTC+9, 한국·일본 동일

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<bool> requestAndroidPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;

    final notificationPermission =
        await android.requestNotificationsPermission();
    _androidScheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    return notificationPermission != false;
  }

  static Future<void> scheduleAll() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? true;

    if (!enabled) {
      await _plugin.cancelAll();
      return;
    }

    final hour = prefs.getInt('notif_hour') ?? 20;
    final minute = prefs.getInt('notif_minute') ?? 0;
    await _scheduleDailyReminders(hour, minute);
    await _scheduleStreakWarning(prefs);
    await _scheduleWeeklyReport(prefs);
  }

  // 날짜마다 달라지는 오늘의 단어를 알림 본문에 담기 위해 한 달 치를 개별 예약한다.
  static Future<void> _scheduleDailyReminders(int hour, int minute) async {
    await _plugin.cancel(_legacyIdDaily);
    for (var day = 0; day < _dailyScheduleDays; day++) {
      await _plugin.cancel(_dailyIdStart + day);
    }

    final firstDelivery = _nextTime(hour, minute);
    for (var day = 0; day < _dailyScheduleDays; day++) {
      final delivery = firstDelivery.add(Duration(days: day));
      final word = DailyWordService.getDailyWord(delivery);
      final display = DailyWordService.displayWord(word);
      final reading = DailyWordService.reading(word);
      final meaning = DailyWordService.meaning(word);
      final title = display == reading
          ? '📖 오늘의 일본어: $display'
          : '📖 오늘의 일본어: $display ($reading)';

      await _plugin.zonedSchedule(
        _dailyIdStart + day,
        title,
        '$meaning  ·  매일 10분, 꾸준히 정복해요!',
        delivery,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _chDaily,
            '일일 학습 알림',
            channelDescription: '매일 일본어 학습을 리마인드해드려요',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: _androidScheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // ── 2. 스트릭 경고 (21:00, 스트릭 2일 이상일 때만) ──
  static Future<void> _scheduleStreakWarning(SharedPreferences prefs) async {
    await _plugin.cancel(_idStreak);
    final streak = prefs.getInt('streak_days') ?? 0;
    if (streak < 2) return;

    // 오늘 이미 학습했으면 스트릭 경고 불필요
    final lastStudy = prefs.getString('last_study_date') ?? '';
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (lastStudy == todayStr) return;

    await _plugin.zonedSchedule(
      _idStreak,
      '🔥 $streak일 스트릭이 끊길 위기!',
      '오늘 아직 학습하지 않았어요. 지금 바로 단어 하나만 확인해보세요!',
      _nextTime(21, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _chStreak,
          '스트릭 경고',
          channelDescription: '스트릭이 끊길 위기일 때 알려드려요',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: _androidScheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── 3. 주간 리포트 (월요일 09:00) ──
  static Future<void> _scheduleWeeklyReport(SharedPreferences prefs) async {
    final totalLearned = (prefs.getStringList('learned') ?? []).length;
    final body = totalLearned == 0
        ? '이번 주는 학습을 시작해볼까요? 매일 10분이면 충분해요!'
        : '지금까지 $totalLearned개 학습 완료! 이번 주도 파이팅 💪';

    await _plugin.zonedSchedule(
      _idWeekly,
      '📊 주간 학습 리포트',
      body,
      _nextMonday9am(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _chWeekly,
          '주간 리포트',
          channelDescription: '매주 월요일 학습 현황을 알려드려요',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: _androidScheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();

  static tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  static tz.TZDateTime _nextMonday9am() {
    var t = _nextTime(9, 0);
    while (t.weekday != DateTime.monday) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }
}
