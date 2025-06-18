import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Current game management
  static const String _currentGameKey = 'current_game';
  static const String _teamNamesKey = 'team_names';
  static const String _gameHistoryKey = 'game_history';

  Future<void> saveCurrentGame(GameModel game) async {
    try {
      await prefs.setString(_currentGameKey, game.toJsonString());
    } catch (e) {
      throw StorageException('Failed to save current game: $e');
    }
  }

  GameModel? getCurrentGame() {
    try {
      final gameJson = prefs.getString(_currentGameKey);
      if (gameJson == null) return null;
      return GameModel.fromJsonString(gameJson);
    } catch (e) {
      // If there's an error loading the game, return null and clear corrupted data
      prefs.remove(_currentGameKey);
      return null;
    }
  }

  Future<void> clearCurrentGame() async {
    await prefs.remove(_currentGameKey);
  }

  // Team names management
  Future<void> saveTeamNames(String teamA, String teamB) async {
    try {
      await prefs.setString(_teamNamesKey, jsonEncode({
        'teamA': teamA,
        'teamB': teamB,
      }));
    } catch (e) {
      throw StorageException('Failed to save team names: $e');
    }
  }

  Map<String, String> getTeamNames() {
    try {
      final namesJson = prefs.getString(_teamNamesKey);
      if (namesJson == null) {
        return {'teamA': 'الفريق الأيمن', 'teamB': 'الفريق الأيسر'};
      }
      final data = jsonDecode(namesJson);
      return {
        'teamA': data['teamA'] ?? 'الفريق الأيمن',
        'teamB': data['teamB'] ?? 'الفريق الأيسر',
      };
    } catch (e) {
      // Return default names if there's an error
      return {'teamA': 'الفريق الأيمن', 'teamB': 'الفريق الأيسر'};
    }
  }

  // Game history management
  Future<void> saveGameToHistory(GameModel game) async {
    try {
      final history = getGameHistory();
      
      // Add completed game to history
      final completedGame = game.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        winnerId: game.winner,
      );
      
      history.insert(0, completedGame);
      
      // Keep only last 20 games
      if (history.length > 20) {
        history.removeRange(20, history.length);
      }
      
      final historyJson = history.map((g) => g.toJson()).toList();
      await prefs.setString(_gameHistoryKey, jsonEncode(historyJson));
    } catch (e) {
      throw StorageException('Failed to save game to history: $e');
    }
  }

  List<GameModel> getGameHistory() {
    try {
      final historyJson = prefs.getString(_gameHistoryKey);
      if (historyJson == null) return [];
      
      final List<dynamic> historyData = jsonDecode(historyJson);
      return historyData
          .map((json) => GameModel.fromJson(json))
          .toList();
    } catch (e) {
      // Return empty list if there's an error and clear corrupted data
      prefs.remove(_gameHistoryKey);
      return [];
    }
  }

  Future<void> clearGameHistory() async {
    await prefs.remove(_gameHistoryKey);
  }

  // Clear all data
  Future<void> clearAllData() async {
    await prefs.clear();
  }
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);
  
  @override
  String toString() => 'StorageException: $message';
}