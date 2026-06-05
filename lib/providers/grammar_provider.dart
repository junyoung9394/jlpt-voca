import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/grammar_item.dart';

class GrammarProvider extends ChangeNotifier {
  Map<String, List<GrammarItem>> _grammarData = {};
  Set<String> _bookmarked = {};
  Set<String> _mastered = {};

  bool _isLoading = false;
  bool _isLoaded = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String? get errorMessage => _errorMessage;

  Set<String> get bookmarked => _bookmarked;
  Set<String> get mastered => _mastered;

  List<GrammarItem> getByLevel(String level) {
    return _grammarData[level] ?? [];
  }

  List<GrammarItem> getBookmarked() {
    final allItems = _grammarData.values.expand((items) => items).toList();
    return allItems.where((item) => _bookmarked.contains(item.id)).toList();
  }

  bool isBookmarked(String id) {
    return _bookmarked.contains(id);
  }

  bool isMastered(String id) {
    return _mastered.contains(id);
  }

  int getMasteredCount(String level) {
    final items = getByLevel(level);
    return items.where((item) => _mastered.contains(item.id)).length;
  }

  int getTotalCount() {
    return _grammarData.values.fold<int>(
      0,
          (sum, items) => sum + items.length,
    );
  }

  int getTotalMasteredCount() {
    return _grammarData.values
        .expand((items) => items)
        .where((item) => _mastered.contains(item.id))
        .length;
  }

  Future<void> loadAll() async {
    if (_isLoading) return;
    if (_isLoaded && _grammarData.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      _bookmarked = Set<String>.from(
        prefs.getStringList('grammar_bookmarked') ?? [],
      );

      _mastered = Set<String>.from(
        prefs.getStringList('grammar_mastered') ?? [],
      );

      final Map<String, List<GrammarItem>> loadedData = {};

      for (final level in ['N5', 'N4', 'N3', 'N2', 'N1']) {
        final fileName = 'grammar_${level.toLowerCase()}.json';
        final path = 'assets/data/$fileName';

        final jsonString = await rootBundle.loadString(path);
        final decoded = json.decode(jsonString);

        if (decoded is! List) {
          throw Exception('$path 파일 형식이 List가 아닙니다.');
        }

        loadedData[level] = decoded
            .map((item) => GrammarItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      _grammarData = loadedData;
      _isLoaded = true;
    } catch (e) {
      _grammarData = {};
      _isLoaded = false;
      _errorMessage = e.toString();
      debugPrint('GrammarProvider loadAll error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    _isLoaded = false;
    _grammarData = {};
    await loadAll();
  }

  Future<void> toggleBookmark(String id) async {
    if (_bookmarked.contains(id)) {
      _bookmarked.remove(id);
    } else {
      _bookmarked.add(id);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'grammar_bookmarked',
      _bookmarked.toList(),
    );

    notifyListeners();
  }

  Future<void> toggleMastered(String id) async {
    if (_mastered.contains(id)) {
      _mastered.remove(id);
    } else {
      _mastered.add(id);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'grammar_mastered',
      _mastered.toList(),
    );

    notifyListeners();
  }

  Future<void> clearGrammarProgress() async {
    _bookmarked.clear();
    _mastered.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('grammar_bookmarked');
    await prefs.remove('grammar_mastered');

    notifyListeners();
  }
}