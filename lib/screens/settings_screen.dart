import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/tts_settings_service.dart';
import 'tts_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifEnabled = true;
  int _notifHour = 20;
  int _notifMinute = 0;
  bool _darkMode = false;
  int _dailyGoal = 10;
  double _ttsSpeed = TtsSettingsService.defaultSpeed;
  final _tts = TTSHelper();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifEnabled = p.getBool('notifications_enabled') ?? true;
      _notifHour = p.getInt('notif_hour') ?? 20;
      _notifMinute = p.getInt('notif_minute') ?? 0;
      _darkMode = (p.getString('theme_mode') ?? 'light') == 'dark';
      _dailyGoal = p.getInt('daily_goal') ?? 10;
      _ttsSpeed = p.getDouble(TtsSettingsService.speedKey) ??
          TtsSettingsService.defaultSpeed;
    });
  }

  Future<void> _save({
    bool scheduleNotifications = true,
    bool requestNotificationPermissions = false,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('notifications_enabled', _notifEnabled);
    await p.setInt('notif_hour', _notifHour);
    await p.setInt('notif_minute', _notifMinute);
    await p.setString('theme_mode', _darkMode ? 'dark' : 'light');
    await p.setInt('daily_goal', _dailyGoal);
    await p.setDouble(TtsSettingsService.speedKey, _ttsSpeed);

    if (!scheduleNotifications) return;

    final permissionsGranted = !requestNotificationPermissions ||
        await NotificationService.requestAndroidPermissions();
    await NotificationService.scheduleAll();
    if (requestNotificationPermissions && !permissionsGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('정해진 시간에 알림을 받으려면 알림 권한을 허용해 주세요.'),
        ),
      );
    }
  }

  Future<void> _setDarkMode(bool enabled) async {
    setState(() => _darkMode = enabled);

    final p = await SharedPreferences.getInstance();
    await p.setString('theme_mode', enabled ? 'dark' : 'light');
    if (!mounted) return;
    final applyNow = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('화면 모드 변경'),
        content: Text(
          '${enabled ? '다크 모드' : '기본 모드'}를 적용하려면 앱을 다시 열어야 합니다.\n지금 앱을 종료할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('나중에'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('지금 적용'),
          ),
        ],
      ),
    );
    if (applyNow == true) {
      await SystemNavigator.pop();
    }
  }

  Future<void> _saveTtsSpeed() async {
    await TtsSettingsService.setSpeed(_ttsSpeed);
  }

  Future<void> _setNotificationsEnabled(bool enabled) async {
    setState(() => _notifEnabled = enabled);
    await _save(requestNotificationPermissions: enabled);
    if (!mounted || enabled) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('학습 알림을 껐습니다. 예약된 알림이 모두 취소되었습니다.')),
    );
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notifHour, minute: _notifMinute),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t != null) {
      setState(() {
        _notifHour = t.hour;
        _notifMinute = t.minute;
      });
      await _save(requestNotificationPermissions: _notifEnabled);
    }
  }

  Future<void> _pickGoal() async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('일일 학습 목표'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [5, 10, 15, 20, 30]
              .map((v) => RadioListTile<int>(
                    title: Text('하루 $v개'),
                    value: v,
                    groupValue: _dailyGoal,
                    activeColor: const Color(0xFF7B61FF),
                    onChanged: (val) => Navigator.pop(context, val),
                  ))
              .toList(),
        ),
      ),
    );
    if (result != null) {
      setState(() => _dailyGoal = result);
      await _save(scheduleNotifications: false);
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('전체 초기화'),
        content: const Text('모든 학습 기록, XP, 스트릭이\n초기화됩니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('초기화', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await StorageService.clearAll();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ 초기화 완료!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  String get _timeLabel =>
      '${_notifHour.toString().padLeft(2, '0')}:${_notifMinute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 20, 16, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          // ── 학습 설정 ──
          const _SectionLabel('학습 설정'),
          _Card(children: [
            _ArrowRow(
              iconColor: const Color(0xFFFF9800),
              icon: Icons.flag_rounded,
              title: '일일 학습 목표',
              subtitle: '하루 $_dailyGoal단어',
              onTap: _pickGoal,
            ),
            const Divider(height: 1, indent: 72, endIndent: 16),
            _TtsSpeedRow(
              speed: _ttsSpeed,
              onChanged: (value) {
                setState(() => _ttsSpeed = value);
              },
              onChangeEnd: (_) => _saveTtsSpeed(),
              onPreview: () async {
                await _saveTtsSpeed();
                if (!context.mounted) return;
                await _tts.speak(context, 'こんにちは');
              },
            ),
          ]),

          const SizedBox(height: 20),

          // ── 알림 설정 ──
          const _SectionLabel('알림 설정'),
          _Card(children: [
            _SwitchRow(
              iconColor: const Color(0xFF2196F3),
              icon: Icons.notifications_rounded,
              title: '학습 알림',
              subtitle: _notifEnabled
                  ? '매일 $_timeLabel에 알림을 보내드려요'
                  : '꺼짐 - 예약된 알림을 보내지 않아요',
              value: _notifEnabled,
              onChanged: _setNotificationsEnabled,
            ),
            if (_notifEnabled) ...[
              const Divider(height: 1, indent: 72, endIndent: 16),
              _ArrowRow(
                iconColor: const Color(0xFF03A9F4),
                icon: Icons.access_time_rounded,
                title: '알림 시간',
                subtitle: '$_timeLabel 에 알림을 드려요',
                onTap: _pickTime,
              ),
            ],
          ]),

          const SizedBox(height: 20),

          // ── 화면 설정 ──
          const _SectionLabel('화면 설정'),
          _Card(children: [
            _SwitchRow(
              iconColor: const Color(0xFF7B61FF),
              icon: Icons.dark_mode_rounded,
              title: '화면 모드',
              subtitle:
                  _darkMode ? '다크 모드 선택됨 - 다시 열면 적용' : '기본 모드 선택됨 - 다시 열면 적용',
              value: _darkMode,
              onChanged: _setDarkMode,
            ),
          ]),

          const SizedBox(height: 20),

          // ── 데이터 관리 ──
          const _SectionLabel('데이터 관리'),
          _Card(children: [
            _ArrowRow(
              iconColor: const Color(0xFFF44336),
              icon: Icons.delete_outline_rounded,
              title: '학습 데이터 초기화',
              subtitle: '모든 학습 기록을 삭제해요',
              onTap: _confirmReset,
              titleColor: Colors.red,
            ),
          ]),

          const SizedBox(height: 36),
          Center(
            child: Text('앱 버전 1.2.2',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade400)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── 공통 위젯 ──

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color:
                  isDark ? const Color(0xFFBFB0FF) : const Color(0xFF7B61FF))),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191B2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)
              ],
      ),
      child: Column(children: children),
    );
  }
}

class _ArrowRow extends StatelessWidget {
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;

  const _ArrowRow({
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: iconColor, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15, color: titleColor)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      secondary: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: iconColor, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      activeColor: const Color(0xFF7B61FF),
      onChanged: onChanged,
    );
  }
}

class _TtsSpeedRow extends StatelessWidget {
  final double speed;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final VoidCallback onPreview;

  const _TtsSpeedRow({
    required this.speed,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF26A69A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.record_voice_over_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('TTS 속도',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : null)),
                    const Spacer(),
                    Text('${speed.toStringAsFixed(1)}x',
                        style: TextStyle(
                            color: isDark
                                ? const Color(0xFFD6CBFF)
                                : const Color(0xFF7B61FF),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('일본어 발음 재생 속도를 조절해요',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey)),
                Slider(
                  value: speed,
                  min: 0.2,
                  max: 2.0,
                  divisions: 9,
                  activeColor: const Color(0xFF7B61FF),
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onPreview,
                    icon: const Icon(Icons.volume_up_rounded, size: 17),
                    label: const Text('미리 듣기'),
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
