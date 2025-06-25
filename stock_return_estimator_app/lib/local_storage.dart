import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String favoritesKey = 'favorites';
  static const String settingsKey = 'user_settings';

  static Future<List<Map<String, dynamic>>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(favoritesKey);
    if (jsonString == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<void> saveFavorite(Map<String, dynamic> favorite) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await loadFavorites();
    favorites.add(favorite);
    await prefs.setString(favoritesKey, jsonEncode(favorites));
  }

  static Future<void> deleteFavorite(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await loadFavorites();
    if (index >= 0 && index < favorites.length) {
      favorites.removeAt(index);
      await prefs.setString(favoritesKey, jsonEncode(favorites));
    }
  }

  static Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(favoritesKey);
  }

  static Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(settingsKey);
    if (jsonString == null) return {};
    return Map<String, dynamic>.from(jsonDecode(jsonString));
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(settingsKey, jsonEncode(settings));
  }
}
