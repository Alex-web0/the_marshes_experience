import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
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

  // Generate a 6-character alphanumeric game code with 3 chars from server timestamp
  Future<String> _generateGameCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed ambiguous chars
    final random = Random();

    // Get server timestamp from Firebase
    final serverTimeRef = _database.child('.info/serverTimeOffset');
    final snapshot = await serverTimeRef.get();
    final serverOffset = (snapshot.value as int?) ?? 0;
    final serverTime = DateTime.now().millisecondsSinceEpoch + serverOffset;

    // Use last 3 digits of timestamp and convert to chars
    final timeString = serverTime.toString();
    final timeChars = timeString.substring(timeString.length - 3);

    // Convert timestamp digits to alphanumeric chars
    final timestampPart = timeChars.split('').map((digit) {
      final index = int.parse(digit);
      return chars[index % chars.length];
    }).join();

    // Generate 3 random chars
    final randomPart =
        List.generate(3, (index) => chars[random.nextInt(chars.length)]).join();

    // Combine: 3 timestamp chars + 3 random chars
    return timestampPart + randomPart;
  }

  // Generate unique player ID
  String _generatePlayerId() {
    return 'player_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  // Create a new game
  Future<MultiplayerGame> createGame(String playerName) async {
    final gameId = _database.child('games').push().key!;
    final gameCode = await _generateGameCode();
    final playerId = _generatePlayerId();

    final game = MultiplayerGame(
      gameId: gameId,
      code: gameCode,
      status: GameStatus.waiting,
      creatorId: playerId,
      maxPlayers: kMaxPlayers,
      currentPlayers: 1,
      players: {
        playerId: MultiplayerPlayer(
          playerId: playerId,
          name: playerName,
          isReady: false,
          joinedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      },
    );

    await _database.child('games/$gameId').set(game.toMap());
    await _database.child('games/$gameId/players/$playerId').set(
          game.players[playerId]!.toMap(),
        );

    _currentGameId = gameId;
    _currentPlayerId = playerId;

    return game;
  }

  // Find game by code
  Future<String?> findGameByCode(String code) async {
    final query = await _database
        .child('games')
        .orderByChild('code')
        .equalTo(code.toUpperCase())
        .once();

    if (query.snapshot.value != null) {
      final games = query.snapshot.value as Map<dynamic, dynamic>;
      final gameId = games.keys.first;
      final gameData = games[gameId] as Map<dynamic, dynamic>;

      // Check if game is joinable
      if (gameData['status'] == GameStatus.waiting.name &&
          (gameData['currentPlayers'] ?? 0) <
              (gameData['maxPlayers'] ?? kMaxPlayers)) {
        return gameId.toString();
      }
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
    final maxPlayers = (maxPlayersSnapshot.value as int?) ?? kMaxPlayers;

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
      await gameRef.child('status').set(GameStatus.playing.name);
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
    if (lane != null && distance != null && x != null && y != null) {
      updates['position'] = {
        'lane': lane,
        'distance': distance,
        'x': x,
        'y': y,
      };
    }

    await _database
        .child('games/$_currentGameId/players/$_currentPlayerId')
        .update(updates);
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

    // Remove player
    await gameRef.child('players/$_currentPlayerId').remove();

    // Update player count
    final snapshot = await gameRef.child('currentPlayers').get();
    final currentPlayers = (snapshot.value as int?) ?? 1;
    await gameRef.child('currentPlayers').set(max(0, currentPlayers - 1));

    // If no players left, delete game
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
