import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static final PreferenceService _instance = PreferenceService._internal();
  factory PreferenceService() => _instance;
  PreferenceService._internal();

  static const String _keyTableColumns = 'table_columns_visibility';
  static const String _keySortAscending = 'sort_ascending';
  static const String _keyViewMode = 'view_mode';
  static const String _keyTextCase = 'text_case';

  // Save visible column IDs
  Future<void> saveVisibleColumns(List<String> columnIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyTableColumns, columnIds);
  }

  // Load visible column IDs
  Future<List<String>?> getVisibleColumns() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyTableColumns);
  }

  // Save sort preference
  Future<void> saveSortAscending(bool ascending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySortAscending, ascending);
  }

  // Load sort preference
  Future<bool> getSortAscending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySortAscending) ?? true;
  }

  // Save view mode
  Future<void> saveViewMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyViewMode, mode);
  }

  // Load view mode
  Future<String> getViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyViewMode) ?? 'card';
  }

  // Save text case
  Future<void> saveTextCase(String textCase) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTextCase, textCase);
  }

  // Load text case
  Future<String> getTextCase() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTextCase) ?? 'titleCase';
  }
}
