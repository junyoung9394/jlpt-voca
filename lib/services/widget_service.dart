import 'package:home_widget/home_widget.dart';
import 'daily_word_service.dart';

class WidgetService {
  static Future<void> updateTodayWord() async {
    final w = DailyWordService.getDailyWord();
    await HomeWidget.saveWidgetData<String>('widget_word',    DailyWordService.displayWord(w));
    await HomeWidget.saveWidgetData<String>('widget_reading', DailyWordService.reading(w));
    await HomeWidget.saveWidgetData<String>('widget_meaning', DailyWordService.meaning(w));
    await HomeWidget.saveWidgetData<String>('widget_level',   'JLPT');
    await HomeWidget.updateWidget(androidName: 'WordWidgetProvider');
  }
}
