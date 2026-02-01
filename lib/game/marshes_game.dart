import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/heritage_repository.dart';
import '../data/audio_manager.dart';
import 'components.dart';

class MarshesGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  // Game State
  bool isPlaying = false;
  bool isAutoPilot = true; // Starts in menu mode
  bool isPaused = false; // Track if game is paused
  double currentSpeed = 200.0;
  double targetSpeed = 300.0; // New: Target speed for recovery
  double score = 0;
  double distanceTraveled = 0;

  int fishCount = 0; // New: Fish counter
  int storyCount = 0; // New: Story counter

  // Lane System
  static const int laneCount = 3;
  late double laneWidth;

  // Player
  late BoatPlayer player;

  // Spawning
  late Timer _spawnTimer;

  // Stream Subscription
  StreamSubscription? _sensorSubscription;
  StreamSubscription? _muteStateSubscription;

  // Callbacks for UI
  final Function(int score, int fish, int stories) onGameOver;
  final Function(HeritageFact) onStoryTrigger;
  final Function(int) onScoreUpdate;
  final Function(int) onHealthUpdate;
  final Function(int) onFishCountUpdate;
  final Function(int) onStoryCountUpdate; // Story counter callback
  final VoidCallback? onPauseTriggered; // Pause callback

  MarshesGame({
    required this.onGameOver,
    required this.onStoryTrigger,
    required this.onScoreUpdate,
    required this.onHealthUpdate,
    required this.onFishCountUpdate,
    required this.onStoryCountUpdate,
    this.onPauseTriggered,
  }) : super() {
    debugMode = kDebugMode; // Enable debug mode to show hitboxes
  }

  @override
  Future<void> onLoad() async {
    // Preload audio files - Music
    await FlameAudio.audioCache.load('music/bg_music_game.mp3');
    await FlameAudio.audioCache.load('music/bg_music_1.mp3');
    await FlameAudio.audioCache.load('music/bg_music_2.mp3');

    // Preload audio files - Sound Effects
    await FlameAudio.audioCache.loadAll([
      'sounds/bonus_1.mp3',
      'sounds/bonus_2.mp3',
      'sounds/button_press_1.mp3',
      'sounds/button_press_2.mp3',
      'sounds/button_press_3.mp3',
      'sounds/drowning.mp3',
      'sounds/item_collect.mp3',
      'sounds/water_splash.mp3',
    ]);

    // 1. Setup Lanes
    laneWidth = size.x / laneCount;

    // 1.5 Background
    final parallax = await loadParallaxComponent(
      [
        ParallaxImageData('looped_extended.png'),
      ],
      baseVelocity: Vector2(0, -currentSpeed), // Vertical scroll
      repeat: ImageRepeat.repeatY,
      fill: LayerFill.width,
    );
    add(parallax);

    // 2. Add Player
    // player = BoatPlayer(); -> Moved to startGame to prevent premature spawning
    // add(player);

    // 3. Spawning Logic
    _spawnTimer = Timer(1.5, repeat: true, onTick: _spawnObject);
    // _spawnTimer.start(); -> Moved to startGame

    // 4. Sensors
    _sensorSubscription = accelerometerEventStream().listen((event) {
      handleTilt(event.x);
    });

    // 5. Listen to mute state changes
    _muteStateSubscription = AudioManager().muteStateStream.listen((isMuted) {
      if (isMuted) {
        // Stop music when muted
        FlameAudio.bgm.stop();
      } else {
        // Resume appropriate music when unmuted based on game state
        if (isPaused) {
          // Game is paused - start music and immediately pause it
          // so resumeBackgroundMusic() will work correctly later
          playBackgroundMusic();
          FlameAudio.bgm.pause();
        } else if (isPlaying || !isAutoPilot) {
          // In game - play game music
          playBackgroundMusic();
        } else if (isAutoPilot) {
          // On main menu - play menu music
          playMenuMusic();
        }
      }
    });
  }

  @override
  void onRemove() {
    _sensorSubscription?.cancel();
    _muteStateSubscription?.cancel();
    stopBackgroundMusic();
    super.onRemove();
  }

  // --- Audio Management ---
  void playBackgroundMusic() {
    if (!AudioManager().isMuted) {
      try {
        FlameAudio.bgm
            .play('music/bg_music_game.mp3', volume: 0.5)
            .catchError((e) {
          debugPrint("Error playing background music: $e");
        });
      } catch (e) {
        debugPrint("Error playing background music (sync): $e");
      }
    }
  }

  void stopBackgroundMusic() {
    try {
      FlameAudio.bgm.stop().catchError((e) {
        debugPrint("Error stopping music: $e");
      });
    } catch (e) {
      debugPrint("Error stopping music (sync): $e");
    }
  }

  void pauseBackgroundMusic() {
    try {
      FlameAudio.bgm.pause().catchError((e) {
        debugPrint("Error pausing music: $e");
      });
    } catch (e) {
      debugPrint("Error pausing music (sync): $e");
    }
  }

  void resumeBackgroundMusic() {
    if (!AudioManager().isMuted) {
      try {
        FlameAudio.bgm.resume().catchError((e) {
          debugPrint("Error resuming music: $e");
        });
      } catch (e) {
        debugPrint("Error resuming music (sync): $e");
      }
    }
  }

  void playMenuMusic() {
    if (!AudioManager().isMuted) {
      // Randomly choose between bg_music_1.mp3 and bg_music_2.mp3
      final rand = Random();
      final musicTrack =
          rand.nextBool() ? 'music/bg_music_1.mp3' : 'music/bg_music_2.mp3';
      try {
        FlameAudio.bgm
            .play(musicTrack,
                volume: 0.3) // Lower volume for ambient menu music
            .catchError((e) {
          debugPrint("Error playing menu music: $e");
        });
      } catch (e) {
        debugPrint("Error playing menu music (sync): $e");
      }
    }
  }

  // --- Sound Effects ---
  void playButtonSound({int? specificButton}) {
    if (!AudioManager().isMuted) {
      // Play specific button sound (1-3) or random if not specified
      final rand = Random();
      final buttonNum = specificButton ?? (rand.nextInt(3) + 1);
      FlameAudio.play('sounds/button_press_$buttonNum.mp3', volume: 0.6);
    }
  }

  void playDrowningSound() {
    if (!AudioManager().isMuted) {
      // Play drowning sound and stop after 7 seconds
      final audioPlayer = FlameAudio.play('sounds/drowning.mp3', volume: 0.7);

      // Stop the sound after 7 seconds
      Future.delayed(const Duration(seconds: 5), () {
        audioPlayer.then((player) => player.stop());
      });
    }
  }

  void playItemCollectSound() {
    if (!AudioManager().isMuted) {
      FlameAudio.play('sounds/item_collect.mp3', volume: 0.5);
    }
  }

  void playBonusSound() {
    if (!AudioManager().isMuted) {
      // Randomly choose between bonus_1 and bonus_2
      final rand = Random();
      final bonusTrack =
          rand.nextBool() ? 'sounds/bonus_1.mp3' : 'sounds/bonus_2.mp3';
      FlameAudio.play(bonusTrack, volume: 0.6);
    }
  }

  // --- Pause/Resume ---
  void pauseGame() {
    if (isPlaying) {
      isPaused = true;
      isPlaying = false;
      pauseBackgroundMusic();
      onPauseTriggered?.call();
    }
  }

  void resumeGameFromPause() {
    isPaused = false;
    isPlaying = true;
    resumeBackgroundMusic();
  }

  @override
  void update(double dt) {
    if (!isPlaying && !isAutoPilot) return; // Paused for Dialog

    super.update(dt); // Updates children components (parallax, player if added)

    // Only update spawner when actually playing
    if (isPlaying) {
      _spawnTimer.update(dt);
    }

    // Increase difficulty/speed
    if (isPlaying) {
      // Recovery Logic: If below target speed, accelerate faster
      if (currentSpeed < targetSpeed) {
        currentSpeed += 50.0 * dt; // Fast recovery
      } else {
        // Natural Difficulty Increase
        currentSpeed += 2.0 * dt;
        targetSpeed += 2.0 * dt; // Keep raising the bar
      }

      distanceTraveled += currentSpeed * dt / 100;
      onScoreUpdate(distanceTraveled.toInt());
    }
  }

  void _spawnObject() {
    if (!isPlaying) return; // double check

    final rand = Random();
    int lane = rand.nextInt(laneCount);
    double xPos = lane * laneWidth + (laneWidth / 2);

    // 10% Chance for Story Item (?), 30% for Fish, 60% for Obstacle
    double roll = rand.nextDouble();

    if (roll < 0.1) {
      add(StoryCollectible()..position = Vector2(xPos, -100));
    } else if (roll < 0.4) {
      add(FishCollectible()..position = Vector2(xPos, -100));
    } else {
      // 65% chance for regular sugar_cane, 35% for sugar_cane_high
      bool useHigh = rand.nextDouble() > 0.65;
      add(Obstacle(useHighVariant: useHigh)..position = Vector2(xPos, -100));
    }
  }

  // --- Input Handling ---

  // Keyboard for testing on Windows
  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!isPlaying) return KeyEventResult.ignored;

    // Guard against player not being initialized/added yet
    if (!children.contains(player)) return KeyEventResult.ignored;

    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      player.moveLeft();
      return KeyEventResult.handled;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      player.moveRight();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // Sensor handling will be injected from main via a listener or handled here if we want direct stream access
  void handleTilt(double xTilt) {
    if (!isPlaying) return;
    // Guard against player not being initialized/added yet
    if (!children.contains(player)) return;

    // Continuous seamless steering
    player.updateTilt(xTilt);
  }

  // Methods to control game state
  void startGame() {
    isPlaying = true;
    isAutoPilot = false;
    isPaused = false;
    currentSpeed = 300.0;
    targetSpeed = 300.0;
    score = 0;
    fishCount = 0;
    storyCount = 0;
    onFishCountUpdate(0);
    onFishCountUpdate(0);
    distanceTraveled = 0;

    // Initialize player if first time or recreate
    // We didn't init in onLoad, so we do it here.
    // If we're restarting, remove old one first.
    // However, player variable might be unassigned if first run.
    // We can't check 'player.parent' if player isn't assigned.

    // Check if player is assigned by using a try-catch or nullable check if it was nullable.
    // Since it's late, we assume startGame is the first place it's ever touched after onLoad skipped it.
    // But wait, resetToMenu might have been called?

    // Safer approach: Remove any existing BoatPlayer from children
    children.whereType<BoatPlayer>().forEach((e) => e.removeFromParent());

    player = BoatPlayer();
    add(player);

    children.whereType<Obstacle>().forEach((e) => e.removeFromParent());
    children.whereType<Collectible>().forEach((e) => e.removeFromParent());

    // Start Spawning
    _spawnTimer.start();

    // Start background music when game starts
    playBackgroundMusic();
  }

  void incrementFishCount() {
    fishCount++;
    onFishCountUpdate(fishCount);
  }

  void incrementStoryCount() {
    storyCount++;
    onStoryCountUpdate(storyCount);
  }

  void pauseForStory(HeritageFact fact) {
    isPlaying = false; // Pause updates
    pauseBackgroundMusic(); // Pause music during story
    onStoryTrigger(fact);
  }

  void resumeGame() {
    isPlaying = true;
    resumeBackgroundMusic(); // Resume music when story is dismissed
  }

  void gameOver() {
    isPlaying = false;
    stopBackgroundMusic(); // Stop music on game over
    playDrowningSound(); // Play drowning sound effect
    onGameOver(distanceTraveled.toInt(), fishCount, storyCount);
  }

  void resetToMenu() {
    isPlaying = false;
    isAutoPilot = true;
    isPaused = false;
    currentSpeed = 200.0; // Cruising speed

    // Cleanup entities
    if (player.parent != null) player.removeFromParent();
    children.whereType<Obstacle>().forEach((e) => e.removeFromParent());
    children.whereType<Collectible>().forEach((e) => e.removeFromParent());

    // Stop spawning
    _spawnTimer.stop();

    // Stop music when returning to menu
    stopBackgroundMusic();
  }
}
