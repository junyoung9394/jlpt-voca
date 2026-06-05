import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/tts_settings_service.dart';

class TTSHelper {
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(BuildContext context, String text,
      {String langCode = "ja-JP"}) async {
    try {
      final engines = List<String>.from(await _tts.getEngines);

      if (!engines.contains('com.google.android.tts')) {
        if (!context.mounted) return;
        _showTTSInstallDialog(context);
        return;
      }

      await _tts.setLanguage(langCode);
      await _tts.setSpeechRate(await TtsSettingsService.getSpeed());
      if (!context.mounted) return;
      await _tts.speak(text);
    } catch (e) {
      if (!context.mounted) return;
      _showTTSInstallDialog(context);
    }
  }

  void _showTTSInstallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('TTS 엔진 필요'),
        content: const Text(
          '이 기기에는 구글 음성 엔진이 설치되어 있지 않습니다.\n\n'
          'Play 스토어에서 "Speech Services by Google"을 설치해야 '
          '음성 기능이 정상 작동합니다.',
        ),
        actions: [
          TextButton(
            child: const Text('스토어 열기'),
            onPressed: () async {
              const url =
                  'https://play.google.com/store/apps/details?id=com.google.android.tts';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          TextButton(
            child: const Text('닫기'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
