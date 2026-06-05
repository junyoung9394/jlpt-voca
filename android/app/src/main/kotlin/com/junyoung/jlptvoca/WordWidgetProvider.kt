package com.junyoung.jlptvoca

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews

class WordWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val prefs: SharedPreferences = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        )
        val word    = prefs.getString("flutter.widget_word",    "今日の単語")    ?: "今日の単語"
        val reading = prefs.getString("flutter.widget_reading", "")             ?: ""
        val meaning = prefs.getString("flutter.widget_meaning", "학습을 시작하세요!") ?: "학습을 시작하세요!"
        val level   = prefs.getString("flutter.widget_level",   "JLPT")         ?: "JLPT"

        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.word_widget_layout)
            views.setTextViewText(R.id.widget_level,   level)
            views.setTextViewText(R.id.widget_word,    word)
            views.setTextViewText(R.id.widget_reading, reading)
            views.setTextViewText(R.id.widget_meaning, meaning)
            manager.updateAppWidget(id, views)
        }
    }
}
