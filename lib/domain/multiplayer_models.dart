// Multiplayer game models
import 'package:flutter/foundation.dart';
import 'game_status.dart';
import 'multiplayer_constants.dart';

enum RaceLength { short, medium, long }

extension RaceLengthExtension on RaceLength {
  int get distance {
    if (this == RaceLength.short && kDebugMode) {
      return 200;
    }
    switch (this) {
      case RaceLength.short:
        return 800;
      case RaceLength.medium:
        return 2800;
      case RaceLength.long:
        return 5000;
    }
  }

  String get label {
    switch (this) {
      case RaceLength.short:
        return 'Short (800m)';
      case RaceLength.medium:
        return 'Medium (2800m)';
      case RaceLength.long:
        return 'Long (5000m)';
    }
  }
}

class MultiplayerHazard {
  final String id;
  final String placedBy;
  final int lane;
  final double distance;
  final int createdAt;

  MultiplayerHazard({
    required this.id,
    required this.placedBy,
    required this.lane,
    required this.distance,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'placedBy': placedBy,
      'lane': lane,
      'distance': distance,
      'createdAt': createdAt,
    };
  }

  factory MultiplayerHazard.fromMap(String id, Map<dynamic, dynamic> map) {
    return MultiplayerHazard(
      id: id,
      placedBy: map['placedBy'] ?? '',
      lane: (map['lane'] as num?)?.toInt() ?? 0,
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
    );
  }
}

class MultiplayerGame {
  final String gameId;
  final String code;
  final GameStatus status;
  final String creatorId;
  final int maxPlayers;
  final int currentPlayers;
  final Map<String, MultiplayerPlayer> players;
  final int startedAt;
  final int? finishedAt;
  final Map<String, MultiplayerHazard> hazards;
  final RaceLength raceLength;
  final String? winnerId;
  final String? nextGameId;
  final String? nextGameCode;

  MultiplayerGame({
    required this.gameId,
    required this.code,
    required this.status,
    required this.creatorId,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.players,
    this.startedAt = 0,
    this.finishedAt,
    this.hazards = const {},
    this.raceLength = RaceLength.short,
    this.winnerId,
    this.nextGameId,
    this.nextGameCode,
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

    final hazardsMap = <String, MultiplayerHazard>{};
    if (map['hazards'] != null) {
      final hazardsData = map['hazards'] as Map<dynamic, dynamic>;
      hazardsData.forEach((key, value) {
        hazardsMap[key.toString()] =
            MultiplayerHazard.fromMap(key.toString(), value);
      });
    }

    RaceLength length = RaceLength.short;
    if (map['raceLength'] != null) {
      length = RaceLength.values.firstWhere(
          (e) => e.toString() == map['raceLength'],
          orElse: () => RaceLength.short);
    }

    return MultiplayerGame(
      gameId: gameId,
      code: map['code'] ?? '',
      status: map['status'] != null
          ? GameStatus.fromJson(map['status'])
          : GameStatus.waiting,
      creatorId: map['creatorId'] ?? '',
      maxPlayers: map['maxPlayers'] ?? MultiplayerConstants.kMaxPlayers,
      currentPlayers: map['currentPlayers'] ?? 0,
      players: playersMap,
      startedAt: map['startedAt'] ?? 0,
      finishedAt: map['finishedAt'],
      hazards: hazardsMap,
      raceLength: length,
      winnerId: map['winnerId'],
      nextGameId: map['nextGameId'],
      nextGameCode: map['nextGameCode'],
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
      'raceLength': raceLength.toString(),
      'winnerId': winnerId,
      'nextGameId': nextGameId,
      'nextGameCode': nextGameCode,
      'players': players.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}

class MultiplayerPlayer {
  final String playerId;
  final String name;
  final bool isReady;
  final bool isOnline;
  final int score;
  final int lives;
  final int fishCount;
  final int storyCount;
  final int obstaclesHit;
  final PlayerPosition? position;
  final int joinedAt;

  MultiplayerPlayer({
    required this.playerId,
    required this.name,
    this.isReady = false,
    this.isOnline = true,
    this.score = 0,
    this.lives = 3,
    this.fishCount = 0,
    this.storyCount = 0,
    this.obstaclesHit = 0,
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
      isOnline: map['isOnline'] ?? true,
      score: map['score'] ?? 0,
      lives: map['lives'] ?? 3,
      fishCount: map['fishCount'] ?? 0,
      storyCount: map['storyCount'] ?? 0,
      obstaclesHit: map['obstaclesHit'] ?? 0,
      position: pos,
      joinedAt: map['joinedAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isReady': isReady,
      'isOnline': isOnline,
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
