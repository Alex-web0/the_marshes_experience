// Multiplayer game models
import 'game_status.dart';
import 'multiplayer_constants.dart';

class MultiplayerGame {
  final String gameId;
  final String code;
  final GameStatus status;
  final String creatorId;
  final int maxPlayers;
  final int currentPlayers;
  final Map<String, MultiplayerPlayer> players;
  final int? startedAt;
  final int? finishedAt;

  MultiplayerGame({
    required this.gameId,
    required this.code,
    required this.status,
    required this.creatorId,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.players,
    this.startedAt,
    this.finishedAt,
  });

  factory MultiplayerGame.fromMap(String gameId, Map<dynamic, dynamic> map) {
    final playersMap = <String, MultiplayerPlayer>{};
    if (map['players'] != null) {
      final playersData = map['players'] as Map<dynamic, dynamic>;
      playersData.forEach((key, value) {
        playersMap[key.toString()] =
            MultiplayerPlayer.fromMap(key.toString(), value);
      });
    }

    return MultiplayerGame(
      gameId: gameId,
      code: map['code'] ?? '',
      status: map['status'] != null
          ? GameStatus.fromJson(map['status'])
          : GameStatus.waiting,
      creatorId: map['creatorId'] ?? '',
      maxPlayers: map['maxPlayers'] ?? kMaxPlayers,
      currentPlayers: map['currentPlayers'] ?? 0,
      players: playersMap,
      startedAt: map['startedAt'],
      finishedAt: map['finishedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'status': status.toJson(),
      'creatorId': creatorId,
      'maxPlayers': maxPlayers,
      'currentPlayers': currentPlayers,
      'startedAt': startedAt,
      'finishedAt': finishedAt,
    };
  }
}

class MultiplayerPlayer {
  final String playerId;
  final String name;
  final bool isReady;
  final int score;
  final int lives;
  final int fishCount;
  final int storyCount;
  final PlayerPosition? position;
  final int joinedAt;

  MultiplayerPlayer({
    required this.playerId,
    required this.name,
    this.isReady = false,
    this.score = 0,
    this.lives = 3,
    this.fishCount = 0,
    this.storyCount = 0,
    this.position,
    required this.joinedAt,
  });

  factory MultiplayerPlayer.fromMap(
      String playerId, Map<dynamic, dynamic> map) {
    PlayerPosition? pos;
    if (map['position'] != null) {
      final posMap = map['position'] as Map<dynamic, dynamic>;
      pos = PlayerPosition(
        lane: posMap['lane'] ?? 1,
        distance: (posMap['distance'] ?? 0).toDouble(),
        x: (posMap['x'] ?? 0).toDouble(),
        y: (posMap['y'] ?? 0).toDouble(),
      );
    }

    return MultiplayerPlayer(
      playerId: playerId,
      name: map['name'] ?? 'Player',
      isReady: map['isReady'] ?? false,
      score: map['score'] ?? 0,
      lives: map['lives'] ?? 3,
      fishCount: map['fishCount'] ?? 0,
      storyCount: map['storyCount'] ?? 0,
      position: pos,
      joinedAt: map['joinedAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isReady': isReady,
      'score': score,
      'lives': lives,
      'fishCount': fishCount,
      'storyCount': storyCount,
      'position': position?.toMap(),
      'joinedAt': joinedAt,
    };
  }

  MultiplayerPlayer copyWith({
    bool? isReady,
    int? score,
    int? lives,
    int? fishCount,
    int? storyCount,
    PlayerPosition? position,
  }) {
    return MultiplayerPlayer(
      playerId: playerId,
      name: name,
      isReady: isReady ?? this.isReady,
      score: score ?? this.score,
      lives: lives ?? this.lives,
      fishCount: fishCount ?? this.fishCount,
      storyCount: storyCount ?? this.storyCount,
      position: position ?? this.position,
      joinedAt: joinedAt,
    );
  }
}

class PlayerPosition {
  final int lane;
  final double distance;
  final double x;
  final double y;

  PlayerPosition({
    required this.lane,
    required this.distance,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toMap() {
    return {
      'lane': lane,
      'distance': distance,
      'x': x,
      'y': y,
    };
  }
}
