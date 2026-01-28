import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import '../data/heritage_repository.dart';
import 'components.dart';

class MarshesGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  // Game State
  bool isPlaying = false;
  bool isAutoPilot = true; // Starts in menu mode
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

  // Callbacks for UI
  final Function(int score, int fish, int stories) onGameOver;
  final Function(HeritageFact) onStoryTrigger;
  final Function(int) onScoreUpdate;

  final Function(int) onHealthUpdate;
  final Function(int) onFishCountUpdate; // New Callback

  MarshesGame({
    required this.onGameOver,
    required this.onStoryTrigger,
    required this.onScoreUpdate,
    required this.onHealthUpdate,
    required this.onFishCountUpdate,
  });

  @override
  Future<void> onLoad() async {
    // 1. Setup Lanes
    laneWidth = size.x / laneCount;
    
    // 1.5 Background
    final parallax = await loadParallaxComponent(
      [
        ParallaxImageData('/river_marshes_bg.png'),
      ],
      baseVelocity: Vector2(0, -currentSpeed), // Vertical scroll
      repeat: ImageRepeat.repeatY,
      fill: LayerFill.width,
    );
    add(parallax);
    
    // 2. Add Player
    player = BoatPlayer();
    add(player);
    
    // 3. Spawning Logic
    _spawnTimer = Timer(1.5, repeat: true, onTick: _spawnObject);
    _spawnTimer.start();

    // 4. Sensors
    _sensorSubscription = accelerometerEventStream().listen((event) {
      handleTilt(event.x);
    });
  }

  @override
  void onRemove() {
    _sensorSubscription?.cancel();
    super.onRemove();
  }

  @override
  void update(double dt) {
    if (!isPlaying && !isAutoPilot) return; // Paused for Dialog
    
    super.update(dt);
    _spawnTimer.update(dt);
    
    // Increase difficulty/speed
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
    } else if (isAutoPilot) {
         // Maybe scroll background but don't add score?
         // For now, no score update in menu mode
    }
  }

  void _spawnObject() {
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
       add(Obstacle()..position = Vector2(xPos, -100));
    }
  }

  // --- Input Handling ---
  
  // Keyboard for testing on Windows
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!isPlaying) return KeyEventResult.ignored;

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
     // Simple threshold steering
     if (xTilt > 2) player.moveRight();
     if (xTilt < -2) player.moveLeft();
  }

  // Methods to control game state
  void startGame() {
    isPlaying = true;
    isAutoPilot = false;
    currentSpeed = 300.0;
    targetSpeed = 300.0;
    score = 0;
    fishCount = 0;
    storyCount = 0;
    onFishCountUpdate(0);
    onFishCountUpdate(0);
    distanceTraveled = 0;
    
    // Remove old player if it still exists (it shouldn't if game over processed?)
    // But to be safe, we check validity.
    // Ideally we create a new one to be fresh.
    if (player.parent != null) player.removeFromParent();
    else if (player.isMounted) player.removeFromParent(); 

    player = BoatPlayer();
    add(player);
    
    children.whereType<Obstacle>().forEach((e) => e.removeFromParent());
    children.whereType<Collectible>().forEach((e) => e.removeFromParent());
  }

  void incrementFishCount() {
    fishCount++;
    onFishCountUpdate(fishCount);
  }

  void incrementStoryCount() {
    storyCount++;
  }
  
  void pauseForStory(HeritageFact fact) {
      isPlaying = false; // Pause updates
      onStoryTrigger(fact);
  }
  
  void resumeGame() {
      isPlaying = true;
  }

  void gameOver() {
    isPlaying = false;
    onGameOver(
        distanceTraveled.toInt(),
        fishCount,
        storyCount
    );
  }

  void resetToMenu() {
    isPlaying = false;
    isAutoPilot = true;
    currentSpeed = 200.0; // Cruising speed
    
    // Cleanup entities
    if (player.parent != null) player.removeFromParent();
    children.whereType<Obstacle>().forEach((e) => e.removeFromParent());
    children.whereType<Collectible>().forEach((e) => e.removeFromParent());
  }
}
