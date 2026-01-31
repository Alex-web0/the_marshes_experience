import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import '../domain/multiplayer_models.dart';
import '../domain/game_status.dart';
import '../domain/multiplayer_constants.dart';

class MultiplayerService {
  static final MultiplayerService _instance = MultiplayerService._internal();
  factory MultiplayerService() => _instance;
  MultiplayerService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String? _currentGameId;
  String? _currentPlayerId;
  StreamSubscription? _gameSubscription;

  String? get currentGameId => _currentGameId;
  String? get currentPlayerId => _currentPlayerId;

  // Generate unique player ID
  String _generatePlayerId() {
    return 'player_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  // Create a new game
  Future<MultiplayerGame> createGame(
      {required String name,
      required String code,
      RaceLength raceLength = RaceLength.short,
      int? maxPlayers}) async {
    try {
      debugPrint("Creating game for player: $name with code: $code");
      final gameId = _database.child('games').push().key!;
      final playerId = _generatePlayerId(); // Kept original playerId generation

      final newGame = MultiplayerGame(
        gameId: gameId,
        code: code,
        status: GameStatus.waiting,
        creatorId: playerId,
        maxPlayers: maxPlayers ?? MultiplayerConstants.kMaxPlayers,
        currentPlayers: 1,
        players: {
          playerId: MultiplayerPlayer(
            playerId: playerId,
            name: name,
            isReady: true,
            joinedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        },
        hazards: {},
        raceLength: raceLength,
      );

      debugPrint("Saving game to DB...");
      await _database.child('games/$gameId').set(newGame.toMap());
      _currentGameId = gameId;
      _currentPlayerId = playerId;

      debugPrint("Game created! ID: $gameId");
      return newGame;
    } catch (e) {
      debugPrint("Error in createGame inner: $e");
      rethrow;
    }
  }

  // Find game by code
  Future<String?> findGameByCode(String code) async {
    try {
      final query = await _database
          .child('games')
          .orderByChild('code')
          .equalTo(code.toUpperCase())
          .once();

      if (query.snapshot.value != null) {
        final games = query.snapshot.value as Map<dynamic, dynamic>;

        // Sort keys to ensure we check the newest games first
        // Firebase Push IDs are chronologically sorted
        final sortedKeys = games.keys.toList()..sort();

        // Iterate backwards (Newest -> Oldest)
        for (var key in sortedKeys.reversed) {
          final gameData = games[key];
          if (gameData == null || gameData is! Map) continue;

          final status = gameData['status'];
          final currentPlayers = (gameData['currentPlayers'] as int?) ?? 0;
          final maxPlayers = (gameData['maxPlayers'] as int?) ??
              MultiplayerConstants.kMaxPlayers;

          // Prioritize games that are WAITING and have space
          if (status == GameStatus.waiting.name &&
              currentPlayers < maxPlayers) {
            return key.toString();
          }
        }
      }
    } catch (e) {
      debugPrint("Error finding game: $e");
    }
    return null;
  }

  // Join a game
  Future<MultiplayerGame?> joinGame(String gameCode, String playerName) async {
    final gameId = await findGameByCode(gameCode);
    if (gameId == null) return null;

    final playerId = _generatePlayerId();
    final gameRef = _database.child('games/$gameId');

    // Get current player count and max players
    final snapshot = await gameRef.child('currentPlayers').get();
    final currentPlayers = (snapshot.value as int?) ?? 0;

    final maxPlayersSnapshot = await gameRef.child('maxPlayers').get();
    final maxPlayers =
        (maxPlayersSnapshot.value as int?) ?? MultiplayerConstants.kMaxPlayers;

    if (currentPlayers >= maxPlayers) {
      return null; // Game is full
    }

    // Add player
    final player = MultiplayerPlayer(
      playerId: playerId,
      name: playerName,
      isReady: false,
      joinedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await gameRef.child('players/$playerId').set(player.toMap());
    final newPlayerCount = currentPlayers + 1;
    await gameRef.child('currentPlayers').set(newPlayerCount);

    // Auto-start game if lobby is now full
    if (newPlayerCount >= maxPlayers) {
      await gameRef.update({
        'status': GameStatus.playing.name,
        'startedAt': ServerValue.timestamp,
      });
    }

    _currentGameId = gameId;
    _currentPlayerId = playerId;

    // Get updated game data
    final gameSnapshot = await gameRef.get();
    if (gameSnapshot.value != null) {
      return MultiplayerGame.fromMap(
          gameId, gameSnapshot.value as Map<dynamic, dynamic>);
    }

    return null;
  }

  // Listen to game updates
  Stream<MultiplayerGame?> watchGame(String gameId) {
    return _database.child('games/$gameId').onValue.map((event) {
      if (event.snapshot.value != null) {
        return MultiplayerGame.fromMap(
            gameId, event.snapshot.value as Map<dynamic, dynamic>);
      }
      return null;
    });
  }

  // Update player ready status
  Future<void> setPlayerReady(bool isReady) async {
    if (_currentGameId == null || _currentPlayerId == null) return;
    await _database
        .child('games/$_currentGameId/players/$_currentPlayerId/isReady')
        .set(isReady);
  }

  // Update player game state
  Future<void> updatePlayerState({
    int? score,
    int? lives,
    int? fishCount,
    int? storyCount,
    int? obstaclesHit,
    int? lane,
    double? distance,
    double? x,
    double? y,
  }) async {
    if (_currentGameId == null || _currentPlayerId == null) return;

    final updates = <String, dynamic>{};
    if (score != null) updates['score'] = score;
    if (lives != null) updates['lives'] = lives;
    if (fishCount != null) updates['fishCount'] = fishCount;
    if (storyCount != null) updates['storyCount'] = storyCount;
    if (obstaclesHit != null) updates['obstaclesHit'] = obstaclesHit;

    // Update position fields individually
    if (lane != null) updates['position/lane'] = lane;
    if (distance != null) updates['position/distance'] = distance;
    if (x != null) updates['position/x'] = x;
    if (y != null) updates['position/y'] = y;

    await _database
        .child('games/$_currentGameId/players/$_currentPlayerId')
        .update(updates);
  }

  Future<void> finishGame(String winnerId) async {
    if (_currentGameId == null) return;
    await _database.child('games/$_currentGameId').update({
      'status': GameStatus.ended.name, // Changed to .name for consistency
      'finishedAt': DateTime.now().millisecondsSinceEpoch,
      'winnerId': winnerId,
    });
  }

  Future<void> restartGame() async {
    if (_currentGameId == null) return;

    // Reset game state
    // We want to keep players but reset their stats

    final snapshot = await _database.child('games/$_currentGameId').get();
    if (!snapshot.exists) return;

    final gameData = snapshot.value as Map;
    if (gameData['players'] == null) return;
    final playersData = gameData['players'] as Map<dynamic, dynamic>;

    final updates = <String, dynamic>{
      'status': GameStatus.waiting.name, // Changed to .name for consistency
      'startedAt': 0,
      'finishedAt': null,
      'winnerId': null,
      'hazards': null, // Clear hazards
    };

    // Reset each player
    playersData.forEach((key, value) {
      updates['players/$key/score'] = 0;
      updates['players/$key/fishCount'] = 0;
      updates['players/$key/lives'] = 3;
      updates['players/$key/storyCount'] = 0;
      updates['players/$key/obstaclesHit'] = 0;
      updates['players/$key/isReady'] = false;
      updates['players/$key/position'] = null;
    });

    await _database.child('games/$_currentGameId').update(updates);
  }

  // Add a hazard to the game
  Future<void> addHazard({required int lane, required double distance}) async {
    if (_currentGameId == null || _currentPlayerId == null) return;

    final hazardRef = _database.child('games/$_currentGameId/hazards').push();
    final hazard = MultiplayerHazard(
      id: hazardRef.key!,
      placedBy: _currentPlayerId!,
      lane: lane,
      distance: distance,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await hazardRef.set(hazard.toMap());
  }

  // Start the game (creator only)
  Future<void> startGame() async {
    if (_currentGameId == null) return;
    await _database.child('games/$_currentGameId').update({
      'status': GameStatus.playing.name,
      'startedAt': ServerValue.timestamp,
    });
  }

  // Leave game
  Future<void> leaveGame() async {
    if (_currentGameId == null || _currentPlayerId == null) return;

    final gameRef = _database.child('games/$_currentGameId');

    // Mark player as offline instead of removing
    await gameRef.child('players/$_currentPlayerId/isOnline').set(false);

    // Update player count (online players)
    final snapshot = await gameRef.child('currentPlayers').get();
    final currentPlayers = (snapshot.value as int?) ?? 1;
    await gameRef.child('currentPlayers').set(max(0, currentPlayers - 1));

    // If no players left online, delete game
    if (currentPlayers <= 1) {
      await gameRef.remove();
    }

    _gameSubscription?.cancel();
    _currentGameId = null;
    _currentPlayerId = null;
  }

  // Clean up
  void dispose() {
    _gameSubscription?.cancel();
  }
}
