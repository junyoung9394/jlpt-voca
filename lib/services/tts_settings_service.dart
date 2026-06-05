import 'package:shared_preferences/shared_preferences.dart';

class TtsSettingsService {
  static const String speedKey = 'tts_speed';
  static const double defaultSpeed = 0.6;

  static Future<double> getSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(speedKey) ?? defaultSpeed;
  }

  static Future<void> setSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(speedKey, speed);
  }
}
