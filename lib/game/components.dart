import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'marshes_game.dart';
import '../data/heritage_repository.dart';

// --- Constants ---
const double kBaseSize = 64.0; // x64 Pixel Art Scale

// --- Player ---
class BoatPlayer extends RectangleComponent with HasGameReference<MarshesGame>, CollisionCallbacks {
  int currentLane = 1; // Middle lane (0, 1, 2)
  int health = 3; // 0, 1, 2 (3 lives effectively: Healthy(3), Damaged(2), Critical(1), Dead(0)
  
  BoatPlayer() 
      : super(
          size: Vector2(kBaseSize, kBaseSize), 
          paint: Paint()..color = Colors.blueAccent,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
    _updatePosition();
    y = game.size.y - 150;
  }
  
  void moveLeft() {
    if (currentLane > 0) {
      currentLane--;
      _updatePosition();
    }
  }

  void moveRight() {
    if (currentLane < MarshesGame.laneCount - 1) {
      currentLane++;
      _updatePosition();
    }
  }
  
  void _updatePosition() {
    // Determine target X based on lane
    double laneW = game.size.x / MarshesGame.laneCount;
    double targetX = (currentLane * laneW) + (laneW / 2);
    
    // Snapping for now, add interpolation for smooth movement later if needed
    x = targetX;
  }

  void takeHit() {
    health--;
    game.onHealthUpdate(health);
    
    // Feedback: Slow down, Visual change
    game.currentSpeed *= 0.5; // Slow down
    
    // TODO: Replace with "Damaged" Sprite
    if (health == 2) paint.color = Colors.orange;
    if (health == 1) paint.color = Colors.red;
    
    if (health <= 0) {
      removeFromParent();
      game.gameOver();
    }
  }
  
  void reset() {
    health = 3;
    currentLane = 1;
    paint.color = Colors.blueAccent;
    _updatePosition();
    if (parent == null) game.add(this);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Obstacle) {
      takeHit();
      other.removeFromParent(); // Destroy obstacle on hit? Or pass through? User said "boat slows", implies survival. 
    } else if (other is Collectible) {
      other.collect();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

// --- Scrolling Object Base ---
abstract class ScrollingObject extends RectangleComponent with HasGameReference<MarshesGame> {
  ScrollingObject({required Color color}) 
      : super(
          size: Vector2(kBaseSize, kBaseSize),
          paint: Paint()..color = color,
          anchor: Anchor.center,
        );
        
  @override
  void onLoad() {
      add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    y += game.currentSpeed * dt;
    
    // Cleanup if off screen
    if (y > game.size.y + 100) {
      removeFromParent();
    }
  }
}

// --- Specific Objects ---

class Obstacle extends ScrollingObject {
  // TODO: Replace with Rock/Log Sprite
  Obstacle() : super(color: Colors.brown);
}

abstract class Collectible extends ScrollingObject {
  Collectible({required Color color}) : super(color: color);
  void collect();
}

class FishCollectible extends Collectible {
  // TODO: Replace with Animated Fish Sprite
  FishCollectible() : super(color: Colors.greenAccent);

  @override
  void collect() {
    // TODO: Play Sound
    game.incrementFishCount();
    removeFromParent();
  }
}

class StoryCollectible extends Collectible {
  // TODO: Replace with '?' Box Sprite
  StoryCollectible() : super(color: Colors.purpleAccent);

  @override
  void collect() {
    removeFromParent(); // Consume
    // Trigger story
    game.incrementStoryCount();
    game.heritageRepository.getRandomFact().then((fact) {
       game.pauseForStory(fact);
    });
  }
}

extension on MarshesGame {
  // Helper to access repo easily
   HeritageRepository get heritageRepository => HeritageRepository();
}
