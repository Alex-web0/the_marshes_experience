import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/game_stats.dart';

abstract class ScoreRepository {
  Future<int> getHighScore();
  Future<bool> saveHighScore(int score);
  Future<void> saveGameSession(GameStats stats);
}

class LocalScoreRepository implements ScoreRepository {
  static const String _kHighScoreKey = 'marshes_high_score';
  static const String _kSessionsKey = 'marshes_sessions';

  @override
  Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kHighScoreKey) ?? 0;
  }

  @override
  Future<bool> saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHigh = prefs.getInt(_kHighScoreKey) ?? 0;
    
    if (score > currentHigh) {
      await prefs.setInt(_kHighScoreKey, score);
      return true; // New high score!
    }
    return false;
  }

  @override
  Future<void> saveGameSession(GameStats stats) async {
    // For now, we might not store every session locally to avoid bloat, 
    // but this is where we'd add it to a list or send to server.
    // Example: append to a list in prefs
    final prefs = await SharedPreferences.getInstance();
    List<String> sessions = prefs.getStringList(_kSessionsKey) ?? [];
    sessions.add(jsonEncode(stats.toJson()));
    await prefs.setStringList(_kSessionsKey, sessions);
  }
}
