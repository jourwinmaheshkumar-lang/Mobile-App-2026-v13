import 'package:flutter/foundation.dart';
import '../services/preference_service.dart';

enum TextCaseFormat {
  uppercase,
  lowercase,
  titleCase,
}

class TextUtils extends ChangeNotifier {
  static final TextUtils _instance = TextUtils._internal();
  factory TextUtils() => _instance;
  TextUtils._internal();

  static final PreferenceService _prefs = PreferenceService();
  String _currentFormat = 'titleCase';

  Future<void> init() async {
    _currentFormat = await _prefs.getTextCase();
    if (_currentFormat == 'normal') {
      _currentFormat = 'titleCase';
      await _prefs.saveTextCase('titleCase');
    }
    notifyListeners();
  }

  Future<void> setFormat(String format) async {
    if (_currentFormat != format) {
      _currentFormat = format;
      await _prefs.saveTextCase(format);
      notifyListeners();
    }
  }

  String get currentFormat => _currentFormat;

  String format(String text) {
    if (text.isEmpty) return text;
    
    switch (_currentFormat) {
      case 'uppercase':
        return text.toUpperCase();
      case 'lowercase':
        return text.toLowerCase();
      case 'titleCase':
      default:
        return _toTitleCase(text);
    }
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

// Global text utility instance
final textUtils = TextUtils();
