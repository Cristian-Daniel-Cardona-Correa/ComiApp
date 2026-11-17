import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cooking_timer.dart';
import '../models/cooking_session.dart';

class CookingRepository {
  static const String _timersKey = 'comiapp_active_timers';
  static const String _sessionPrefix = 'comiapp_session_';

  Future<void> saveActiveTimers(List<CookingTimer> timers) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = timers.map((t) => t.toMap()).toList();
    await prefs.setString(_timersKey, json.encode(jsonList));
  }

  Future<List<CookingTimer>> loadActiveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_timersKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = json.decode(raw);
      return list.map((item) => CookingTimer.fromMap(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearAllTimers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timersKey);
  }

  Future<void> saveSession(CookingSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_sessionPrefix${session.recipeId}', session.toJson());
  }

  Future<CookingSession?> loadSession(String recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_sessionPrefix$recipeId');
    if (raw == null) return null;
    try {
      return CookingSession.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession(String recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_sessionPrefix$recipeId');
  }
}
