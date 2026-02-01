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

      // Set up onDisconnect to remove player if game is in waiting state
      // Note: Ideally we'd only do this while waiting, but managing the switch is complex without Cloud Functions.
      // For now, if they disconnect, they leave.
      final playerRef = _database.child('games/$gameId/players/$playerId');
      await playerRef.onDisconnect().remove();

      // We also try to decrement player count on disconnect if possible, but transactions on disconnect are tricky.
      // We'll rely on client-side counting or players finding the game empty.

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

    // Set up onDisconnect to remove player
    final playerRef = gameRef.child('players/$playerId');
    await playerRef.onDisconnect().remove();

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

  // Duplicate the game and move all valid players to it
  Future<void> duplicateGame() async {
    if (_currentGameId == null) return;

    final snapshot = await _database.child('games/$_currentGameId').get();
    if (!snapshot.exists || snapshot.value == null) return;

    final oldGameData = snapshot.value as Map<dynamic, dynamic>;
    final playersData = oldGameData['players'] as Map<dynamic, dynamic>? ?? {};

    // Filter valid players (connected/online).
    // Note: Since we don't have a reliable 'isOnline' flag in the model that persists
    // (onDisconnect removes them), we will assume players currently in the list are "online" enough.
    // However, if we wanted to handle "offline" vs "removed", we'd need that flag.
    // For now, duplicate everyone who is still in the DB.
    final newPlayers = <String, Map<String, dynamic>>{};
    int playerCount = 0;
    String? newCreatorId;

    // We can preserve the creator if they are still here, otherwise pick the first one.
    final oldCreatorId = oldGameData['creatorId'];

    playersData.forEach((key, value) {
      final pData = value as Map<dynamic, dynamic>;
      // If we implemented isOnline, check it here: if (pData['isOnline'] != true) return;

      // Reset stats for new game
      newPlayers[key] = {
        'playerId': pData['playerId'],
        'name': pData['name'],
        'isReady': false, // Reset ready status
        'joinedAt': DateTime.now().millisecondsSinceEpoch,
        // Reset other stats
        'score': 0,
        'fishCount': 0,
        'lives': 3,
        'storyCount': 0,
        'obstaclesHit': 0,
        'position': null,
      };
      playerCount++;
      if (key == oldCreatorId) {
        newCreatorId = key;
      }
    });

    if (playerCount == 0) return; // No one to migrate

    // If creator left, assign new creator
    newCreatorId ??= newPlayers.keys.first;

    // Create new game
    final newGameId = _database.child('games').push().key!;
    // Generate a fresh code
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final newCode =
        List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();

    final newGameMap = {
      'gameId': newGameId,
      'code': newCode,
      'status': GameStatus.waiting.name, // Everyone goes back to waiting/queue
      'creatorId': newCreatorId,
      'maxPlayers':
          oldGameData['maxPlayers'] ?? MultiplayerConstants.kMaxPlayers,
      'currentPlayers': playerCount,
      'players': newPlayers,
      'hazards': {},
      'raceLength': oldGameData['raceLength'] ?? RaceLength.short.name,
      'createdAt': ServerValue.timestamp,
    };

    debugPrint("Duplicating game to: $newGameId with code $newCode");
    await _database.child('games/$newGameId').set(newGameMap);

    // Update old game to point to new game
    // We use a special status 'migrated' or just modify the client to listen for a 'nextGameId' field
    // Update old game to point to new game
    // We use a special status 'restarted' and provide next game details
    await _database.child('games/$_currentGameId').update({
      'status': GameStatus.restarted.name,
      'nextGameId': newGameId,
      'nextGameCode': newCode,
    });
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

  // Cancel game (creator only) - destroys the game for everyone
  Future<void> cancelGame() async {
    if (_currentGameId == null) return;

    // Remove the game entirely from DB
    await _database.child('games/$_currentGameId').remove();

    _gameSubscription?.cancel();
    _currentGameId = null;
    _currentPlayerId = null;
  }

  // Leave game
  Future<void> leaveGame() async {
    if (_currentGameId == null || _currentPlayerId == null) return;

    final gameRef = _database.child('games/$_currentGameId');

    // Remove player entirely from the game
    await gameRef.child('players/$_currentPlayerId').remove();

    // Use transaction to safely decrement player count
    await gameRef.child('currentPlayers').runTransaction((mutableData) {
      if (mutableData == null) return Transaction.success(0);
      final current = (mutableData as int);
      return Transaction.success(max(0, current - 1));
    });

    // Check if we should delete the game (no players left)
    // We check the snapshot again to be sure
    final snapshot = await gameRef.child('currentPlayers').get();
    final remainingPlayers = (snapshot.value as int?) ?? 0;

    if (remainingPlayers <= 0) {
      await gameRef.remove();
    }

    _gameSubscription?.cancel();
    _currentGameId = null;
    _currentPlayerId = null;
  }

  // Switch local state to a new game (for migration)
  Future<void> switchToGame(String newGameId) async {
    _currentGameId = newGameId;
    // _currentPlayerId remains the same as we migrated the player ID in duplicateGame
    // But we need to update the onDisconnect handlers for the new path

    if (_currentPlayerId != null) {
      final playerRef =
          _database.child('games/$newGameId/players/$_currentPlayerId');
      await playerRef.onDisconnect().remove();
    }
  }

  // Clean up
  void dispose() {
    _gameSubscription?.cancel();
  }
}
