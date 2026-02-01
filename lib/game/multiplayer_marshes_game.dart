import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';

import '../data/multiplayer_service.dart';
import '../domain/multiplayer_models.dart';
import '../data/audio_manager.dart';
import 'components.dart';

// Reuse existing components where possible, but we might need remote players
// RemotePlayer will simply render a boat at a specific position (x, y) updated by the server

class RemotePlayer extends PositionComponent
    with HasGameReference<MultiplayerMarshesGame> {
  final String playerId;
  final String name;
  // We'll use the same boat animation
  late SpriteAnimationComponent _boatAnimation;

  int fishCount = 0;
  int obstaclesHit = 0;

  RemotePlayer({
    required this.playerId,
    required this.name,
    this.fishCount = 0,
    this.obstaclesHit = 0,
  }) : super(size: Vector2(kPlayerWidth, kPlayerHeight), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final frames = <SpriteAnimationFrame>[];
    // Reuse the boat sprites (maybe tint them later to differentiate?)
    for (int i = 0; i < 13; i++) {
      final image =
          await game.images.load('boat_sprites/sprite_boat_${i + 1}.png');
      frames.add(SpriteAnimationFrame(Sprite(image), 0.095));
    }
    final boatSpriteSheet = SpriteAnimation(frames);

    _boatAnimation = SpriteAnimationComponent(
      animation: boatSpriteSheet,
      size: size,
    );
    // Make remote players semi-transparent to distinguish?
    _boatAnimation.paint.color = Colors.white.withOpacity(0.6);
    add(_boatAnimation);

    _addNameLabel();
  }

  // Update stats method
  void updateStats(int fish, int obstacles) {
    if (fish != fishCount || obstacles != obstaclesHit) {
      fishCount = fish;
      obstaclesHit = obstacles;
      _updateLabelText();
    }
  }

  void _addNameLabel() {
    _updateLabelText();
  }

  void _updateLabelText() {
    // Remove old if exists
    children
        .whereType<RectangleComponent>()
        .toList()
        .forEach((c) => c.removeFromParent());

    final truncatedName =
        (name.length > 6) ? '${name.substring(0, 6)}..' : name;
    final statsText = '🐟$fishCount  🔥$obstaclesHit';

    final namePaint = TextPaint(
      style: GoogleFonts.pixelifySans(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );

    final statsPaint = TextPaint(
      style: GoogleFonts.pixelifySans(
        color: Colors.yellowAccent,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );

    final nameSize = namePaint.getLineMetrics(truncatedName);
    final statsSize = statsPaint.getLineMetrics(statsText);

    final width = max(nameSize.width, statsSize.width) + 8;
    final height = nameSize.height + statsSize.height + 6;

    final bg = RectangleComponent(
      position: Vector2(size.x / 2, -25),
      size: Vector2(width, height),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.black.withOpacity(0.8),
    );

    bg.add(TextComponent(
      text: truncatedName,
      textRenderer: namePaint,
      position: Vector2(width / 2, 2),
      anchor: Anchor.topCenter,
    ));

    bg.add(TextComponent(
      text: statsText,
      textRenderer: statsPaint,
      position: Vector2(width / 2, nameSize.height + 2),
      anchor: Anchor.topCenter,
    ));

    add(bg);
  }
}

class MultiplayerMarshesGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents {
  final MultiplayerGame initialGameData;
  final MultiplayerService _service = MultiplayerService();
  final Function(double) onSpeedUpdate; // Callback for UI

  // Speed Logic
  double currentSpeed = 300.0;
  double targetSpeed = 300.0;
  static const double kMinSpeed = 200.0;
  static const double kMaxSpeed = 800.0; // Higher max speed for racing

  // Game State
  bool isPlaying = true; // Always playing in this mode once started
  double score = 0; // Distance
  double localDistanceTraveled = 0;

  // Opponents
  final Map<String, RemotePlayer> _opponents = {};

  // Local Player
  late LocalMultiplayerBoat player;
  static const int laneCount = 3;
  late double laneWidth;

  // Spawning
  late Timer _spawnTimer;

  // Sensor
  StreamSubscription? _sensorSubscription;
  StreamSubscription? _gameStream;

  final VoidCallback? onHazardDropped;

  MultiplayerMarshesGame({
    required this.initialGameData,
    required this.onSpeedUpdate,
    this.onHazardDropped,
  }) : super() {
    debugMode = kDebugMode;
  }

  @override
  Future<void> onLoad() async {
    // 1. Audio Setup (reuse same tracks)
    await FlameAudio.audioCache.loadAll([
      'music/bg_music_game.mp3',
      'sounds/button_press_1.mp3',
      'sounds/drowning.mp3',
      // ... other sounds
    ]);

    // 2. Setup Lanes
    laneWidth = size.x / laneCount;

    // 3. Background
    final parallax = await loadParallaxComponent(
      [ParallaxImageData('looped_extended.png')],
      baseVelocity: Vector2(0, -currentSpeed),
      repeat: ImageRepeat.repeatY,
      fill: LayerFill.width,
    );
    add(parallax);

    // 4. Local Player
    player = await _createLocalPlayer();
    add(player);

    // 5. Spawning
    _spawnTimer = Timer(1.5, repeat: true, onTick: _spawnObject);
    _spawnTimer.start();

    // 6. Multiplayer Listeners
    _gameStream =
        _service.watchGame(initialGameData.gameId).listen(_onGameUpdate);

    // Note: Gyroscope/accelerometer disabled for multiplayer - using button controls only

    // Start Audio
    if (!AudioManager().isMuted) {
      FlameAudio.bgm
          .play('music/bg_music_game.mp3', volume: 0.5)
          .catchError((_) {});
    }
  }

  // Helper to create our local player adapted for this game class
  Future<LocalMultiplayerBoat> _createLocalPlayer() async {
    final myId = _service.currentPlayerId;
    final myName = initialGameData.players[myId]?.name ?? 'Me';
    return LocalMultiplayerBoat(name: myName);
  }

  final Set<String> _spawnedHazardIds = {};

  double hazardCooldownTimer = 0;

  void dropHazard() {
    if (hazardCooldownTimer > 0) return;

    // Drop a row/cluster of 3-5 hazards
    final r = Random();
    int count = 3 + r.nextInt(3); // 3 to 5
    for (int i = 0; i < count; i++) {
      // Randomize lane and slight distance offset to create a "field"
      int lane = r.nextInt(laneCount);
      double offset = r.nextDouble() * 10.0; // Spread over 10 meters

      _service.addHazard(
        lane: lane,
        distance: localDistanceTraveled + offset,
      );
    }

    hazardCooldownTimer = 9.0;
    onHazardDropped?.call();
  }

  void _onGameUpdate(MultiplayerGame? gameData) {
    if (gameData == null) return;

    // Hazards
    gameData.hazards.forEach((id, hazard) {
      if (_spawnedHazardIds.contains(id)) return;

      final diff = hazard.distance - localDistanceTraveled;
      final pixelDiff = diff * 20.0;

      if (pixelDiff > -200 && pixelDiff < 2000) {
        _spawnedHazardIds.add(id);
        double laneW = size.x / laneCount;
        int lane = hazard.lane.clamp(0, laneCount - 1);
        double xPos = (lane * laneW) + (laneW / 2);
        double yPos = player.y - pixelDiff;

        add(MultiplayerObstacle()..position = Vector2(xPos, yPos));
      } else if (diff < -50) {
        _spawnedHazardIds.add(id);
      }
    });

    // Update opponents
    final players = gameData.players;
    for (var pId in players.keys) {
      if (pId == _service.currentPlayerId) continue;

      final pData = players[pId]!;
      if (!_opponents.containsKey(pId)) {
        final remote = RemotePlayer(playerId: pId, name: pData.name);
        _opponents[pId] = remote;
        add(remote);
      }

      final remote = _opponents[pId]!;
      remote.updateStats(pData.fishCount, pData.obstaclesHit);

      // Simple positioning logic
      final diff = pData.score - localDistanceTraveled;

      // X Position: Use synced X if available, else lane
      double targetX = 0;
      if (pData.position?.x != null && pData.position!.x > 0) {
        targetX = pData.position!.x;
      } else if (pData.position?.lane != null) {
        final laneW = size.x / laneCount;
        targetX = (pData.position!.lane * laneW) + (laneW / 2);
      } else {
        targetX = size.x / 2;
      }

      double yScale = 20.0;
      double relativeY = player.y - (diff * yScale);

      remote.position = Vector2(targetX, relativeY);
    }
  }

  void boostSpeed() {
    // If we are already above normal max speed (e.g. from fish boost), disable manual boost
    if (currentSpeed >= kMaxSpeed) return;

    // Add speed burst
    currentSpeed += 50;

    if (currentSpeed > kMaxSpeed) currentSpeed = kMaxSpeed;
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyW ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        boostSpeed();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        player.moveLeft();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        player.moveRight();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyS ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        dropHazard();
        return KeyEventResult.handled;
      }
    }
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _spawnTimer.update(dt);

    if (hazardCooldownTimer > 0) {
      hazardCooldownTimer -= dt;
    }

    if (_fishBoostTimer > 0) {
      _fishBoostTimer -= dt;
      if (_fishBoostTimer <= 0) {
        // Boost expired - Reset speed AND Music immediately
        currentSpeed = kMaxSpeed;

        if (_isHighSpeedMusic) {
          _isHighSpeedMusic = false;
          // Reset Timer
          _musicResetDebounceTimer = 5.0;
          FlameAudio.bgm.audioPlayer.setVolume(0.5);
          FlameAudio.bgm.audioPlayer.setPlaybackRate(1.0);
        }
      }
    }

    // Update UI
    onSpeedUpdate(currentSpeed);

    // Update Background Speed
    children.whereType<ParallaxComponent>().forEach((p) {
      p.parallax?.baseVelocity = Vector2(0, -currentSpeed);
    });

    // Distance
    localDistanceTraveled += currentSpeed * dt / 100;

    // Decay Speed
    if (currentSpeed > kMinSpeed) {
      currentSpeed -= 20.0 * dt; // Decay rate
      // If we were super speeding, we decay back down towards max speed then normal decay
      if (currentSpeed < kMinSpeed) currentSpeed = kMinSpeed;
    }

    // Low Speed/Obstacle Music Logic
    if (currentSpeed > 1000) {
      _musicResetDebounceTimer = 5.0;
      if (!_isHighSpeedMusic) {
        _isHighSpeedMusic = true;
        FlameAudio.bgm.audioPlayer.setVolume(1.0);
        FlameAudio.bgm.audioPlayer.setPlaybackRate(1.5);
      }
    } else if (currentSpeed < 950) {
      if (_isHighSpeedMusic) {
        _musicResetDebounceTimer -= dt;
        if (_musicResetDebounceTimer <= 0) {
          _isHighSpeedMusic = false;
          FlameAudio.bgm.audioPlayer.setVolume(0.5);
          FlameAudio.bgm.audioPlayer.setPlaybackRate(1.0);
          _musicResetDebounceTimer = 5.0;
        }
      }
    } else {
      // Hysteresis range (950-1000) - keep timer reset
      _musicResetDebounceTimer = 5.0;
    }

    // Sync to DB (throttle)
    _syncCounter += dt;
    if (_syncCounter > 0.1) {
      // 10 times a sec
      _syncCounter = 0;
      _service.updatePlayerState(
        score: localDistanceTraveled.toInt(),
        distance: localDistanceTraveled,
        lane: player.currentLane,
        obstaclesHit: obstaclesHit,
        x: player.x,
      );
    }

    // Check Win Condition
    if (!_hasFinished &&
        localDistanceTraveled >= initialGameData.raceLength.distance) {
      _hasFinished = true;
      // We finished!
      debugPrint("Race Finished!");
      _service.finishGame(_service.currentPlayerId!);
    }
  }

  bool _hasFinished = false;
  double _syncCounter = 0;
  int obstaclesHit = 0;

  void _spawnObject() {
    final rand = Random();
    int lane = rand.nextInt(laneCount);
    double xPos = lane * laneWidth + (laneWidth / 2);

    if (rand.nextDouble() < 0.7) {
      add(MultiplayerObstacle()..position = Vector2(xPos, -100));
    } else {
      add(MultiplayerFish()..position = Vector2(xPos, -100));
    }
  }

  @override
  void onRemove() {
    _sensorSubscription?.cancel();
    _gameStream?.cancel();
    FlameAudio.bgm.stop();
    super.onRemove();
    FlameAudio.bgm.audioPlayer.setPlaybackRate(1.0);
    FlameAudio.bgm.audioPlayer.setVolume(0.5);
  }

  void playItemCollectSound() {
    if (!AudioManager().isMuted)
      FlameAudio.play('sounds/item_collect.mp3', volume: 0.5);
  }

  int fishCount = 0;

  double _fishBoostTimer = 0;
  static const double kFishBoostMaxSpeed = 2000.0;
  static const double kFishBoostSpeedThreshold = 650.0;
  static const double kFishBoostSpeedMultiplier = 1.2;
  static const double kFishBoostDuration = 2.5;

  bool _isHighSpeedMusic = false;
  double _musicResetDebounceTimer = 5.0;

  void incrementFishCount() {
    fishCount++;
    if (currentSpeed > kFishBoostSpeedThreshold) {
      if (currentSpeed + kFishBoostSpeedThreshold <= kFishBoostMaxSpeed) {
        currentSpeed += kFishBoostSpeedThreshold * kFishBoostSpeedMultiplier;
      } else {
        currentSpeed = kFishBoostMaxSpeed;
      }
      _fishBoostTimer = kFishBoostDuration; // Reset timer to 5 seconds
    }
    _service.updatePlayerState(fishCount: fishCount);
  }

  void gameOver() {}
  void onHealthUpdate(int h) {}
}

class MultiplayerBoatPlayer extends PositionComponent
    with HasGameReference<MultiplayerMarshesGame>, CollisionCallbacks {
  final String name;
  final bool isLocalPlayer;
  int currentLane = 1;
  int health = 3;
  late SpriteAnimationComponent _boatAnimation;
  double targetX = 0;
  double transitionSpeed = 500.0;
  bool isTransitioning = false;
  double _currentTilt = 0;
  static const double kTiltSensitivity = 200.0;

  MultiplayerBoatPlayer({required this.name, this.isLocalPlayer = false})
      : super(
            size: Vector2(kPlayerWidth, kPlayerHeight), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final frames = <SpriteAnimationFrame>[];
    for (int i = 0; i < 13; i++) {
      final image =
          await game.images.load('boat_sprites/sprite_boat_${i + 1}.png');
      frames.add(SpriteAnimationFrame(Sprite(image), 0.095));
    }
    final boatSpriteSheet = SpriteAnimation(frames);
    _boatAnimation =
        SpriteAnimationComponent(animation: boatSpriteSheet, size: size);
    add(_boatAnimation);
    add(RectangleHitbox(
        size: Vector2(kPlayerWidth * 0.8, kPlayerHeight * 0.6)));

    // Only add name label for remote players, not local player
    if (!isLocalPlayer) {
      _addNameLabel();
    }

    double laneW = game.size.x / MultiplayerMarshesGame.laneCount;
    x = (currentLane * laneW) + (laneW / 2);
    targetX = x;
    y = game.size.y - 150;
  }

  void _addNameLabel() {
    final truncatedName =
        (name.length > 5) ? '${name.substring(0, 5)}..' : name;
    final textPaint = TextPaint(
      style: GoogleFonts.pixelifySans(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );

    final textSize = textPaint.getLineMetrics(truncatedName);
    final textWidth = textSize.width;
    final textHeight = textSize.height;

    final bg = RectangleComponent(
      position: Vector2(size.x / 2, -15),
      size: Vector2(textWidth + 8, textHeight + 4),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.black.withOpacity(0.8),
    );

    final text = TextComponent(
      text: truncatedName,
      textRenderer: textPaint,
      position: Vector2(bg.size.x / 2, bg.size.y / 2),
      anchor: Anchor.center,
    );

    bg.add(text);
    add(bg);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_currentTilt.abs() > 0.5) {
      isTransitioning = false;
      x -= _currentTilt * kTiltSensitivity * dt;
      final halfWidth = size.x / 2;
      x = x.clamp(halfWidth, game.size.x - halfWidth);

      double laneW = game.size.x / MultiplayerMarshesGame.laneCount;
      currentLane =
          (x / laneW).floor().clamp(0, MultiplayerMarshesGame.laneCount - 1);
    } else if (isTransitioning && (x - targetX).abs() > 1) {
      double direction = targetX > x ? 1 : -1;
      double moveAmount = transitionSpeed * dt * direction;
      if ((x + moveAmount - targetX).abs() > (x - targetX).abs()) {
        x = targetX;
        isTransitioning = false;
      } else {
        x += moveAmount;
      }
    } else if (isTransitioning) {
      x = targetX;
      isTransitioning = false;
    }
  }

  void updateTilt(double tilt) {
    _currentTilt = tilt;
  }

  void moveLeft() {
    if (currentLane > 0) {
      currentLane--;
      _updateTargetX();
    }
  }

  void moveRight() {
    if (currentLane < MultiplayerMarshesGame.laneCount - 1) {
      currentLane++;
      _updateTargetX();
    }
  }

  void _updateTargetX() {
    double laneW = game.size.x / MultiplayerMarshesGame.laneCount;
    targetX = (currentLane * laneW) + (laneW / 2);
    isTransitioning = true;
  }

  @override
  void onCollisionStart(Set<Vector2> pts, PositionComponent other) {
    if (other is MultiplayerObstacle) {
      health--;
      game.currentSpeed *= 0.5;
      game.obstaclesHit++;
      game._fishBoostTimer = 0; // Cancel boost on hit

      // Reset music if it was boosted
      if (game._isHighSpeedMusic) {
        game._isHighSpeedMusic = false;
        game._musicResetDebounceTimer = 5.0;
        FlameAudio.bgm.audioPlayer.setVolume(0.5);
        FlameAudio.bgm.audioPlayer.setPlaybackRate(1.0);
      }

      other.removeFromParent();
    } else if (other is MultiplayerFish) {
      other.collect();
    }
    super.onCollisionStart(pts, other);
  }
}

class LocalMultiplayerBoat extends MultiplayerBoatPlayer {
  LocalMultiplayerBoat({required super.name}) : super(isLocalPlayer: true);
}

abstract class MultiplayerScrollingObject extends PositionComponent
    with HasGameReference<MultiplayerMarshesGame> {
  MultiplayerScrollingObject({required Vector2 size})
      : super(size: size, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    y += game.currentSpeed * dt;
    if (y > game.size.y + 100) {
      removeFromParent();
    }
    priority = y.toInt();
  }
}

class MultiplayerObstacle extends MultiplayerScrollingObject {
  MultiplayerObstacle() : super(size: Vector2(80, 79));
  @override
  Future<void> onLoad() async {
    super.onLoad();
    final sprite = await game.loadSprite('sugar_cane.png');
    add(SpriteComponent(sprite: sprite, size: size));
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }
}

class MultiplayerFish extends MultiplayerScrollingObject {
  MultiplayerFish() : super(size: Vector2(60, 40));
  @override
  Future<void> onLoad() async {
    super.onLoad();
    final sprite = await game.loadSprite('fish_sprite.png');
    add(SpriteComponent(sprite: sprite, size: size));
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  void collect() {
    removeFromParent();
    game.playItemCollectSound();
    game.incrementFishCount();
  }
}
