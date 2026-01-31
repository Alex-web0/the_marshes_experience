import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'marshes_game.dart';
import '../data/heritage_repository.dart';

// --- Constants ---
const double kBaseSize = 64.0; // x64 Pixel Art Scale
const double kPlayerWidth = 68; // x32 Pixel Art Scale
const double kPlayerHeight = 300; // x64 Pixel Art Scale

class BoatFrame {
  final double x;
  final double y;
  final double w;
  final double h;

  BoatFrame(this.x, this.y, this.w, this.h);
}

// --- Player ---
class BoatPlayer extends PositionComponent
    with HasGameReference<MarshesGame>, CollisionCallbacks {
  int currentLane = 1; // Middle lane (0, 1, 2)
  int health =
      3; // 0, 1, 2 (3 lives effectively: Healthy(3), Damaged(2), Critical(1), Dead(0)

  late SpriteAnimationComponent _boatAnimation;

  // Smooth lane transition
  double targetX = 0;
  double transitionSpeed = 500.0; // Pixels per second
  bool isTransitioning = false;

  // Seamless tilt control
  double _currentTilt = 0;
  static const double kTiltSensitivity = 200.0;

  BoatPlayer()
      : super(
          size: Vector2(kPlayerWidth, kPlayerHeight),
          anchor: Anchor.center,
        );

  final frames = <BoatFrame>[
    BoatFrame(0, 0, 78, 300),
    BoatFrame(78, 0, 80, 300),
    BoatFrame(158, 0, 84, 300),
    BoatFrame(242, 0, 86, 300),
    BoatFrame(328, 0, 88, 300),
    BoatFrame(416, 0, 90, 300),
    BoatFrame(506, 0, 92, 300),
    BoatFrame(598, 0, 94, 300),
    BoatFrame(692, 0, 96, 300),
    BoatFrame(788, 0, 98, 300),
    BoatFrame(886, 0, 100, 300),
    BoatFrame(986, 0, 102, 300),
    BoatFrame(1088, 0, 104, 300),
    BoatFrame(1192, 0, 106, 300),
  ];

  @override
  Future<void> onLoad() async {
    // Load boat sprite sheet with 7 frames arranged horizontally
    // final image = await game.images.load('boat_sprite.png');

    final frames = <SpriteAnimationFrame>[];

    for (int i = 0; i < 13; i++) {
      final image =
          await game.images.load('boat_sprites/sprite_boat_${i + 1}.png');
      frames.add(SpriteAnimationFrame(Sprite(image), 0.095));
    }

    final boatSpriteSheet = SpriteAnimation(frames);

    // Add the animation component
    _boatAnimation = SpriteAnimationComponent(
      animation: boatSpriteSheet,
      size: size,
    );
    add(_boatAnimation);

    // Add hitbox for collision detection - covers entire player
    final hitbox = RectangleHitbox(
      size: Vector2(kPlayerWidth - (kPlayerWidth * 0.1205),
          kPlayerHeight / 1.78), // Full player size
    );
    hitbox.renderShape = true; // Enable debug rendering
    hitbox.paint = Paint()
      ..color = Colors.cyan.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    add(hitbox);

    // Set initial position to center lane
    double laneW = game.size.x / MarshesGame.laneCount;
    x = (currentLane * laneW) + (laneW / 2); // Center of middle lane
    targetX = x; // Initialize targetX to current position
    y = game.size.y - 150;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Seamless tilt movement overrides lane transition
    if (_currentTilt.abs() > 0.5) {
      isTransitioning = false; // Cancel any lane transition
      // Reverse steering: Positive X (Left Tilt) -> Move Left (Decrease X)
      x -= _currentTilt * kTiltSensitivity * dt;
      
      // Clamp to screen
      final halfWidth = size.x / 2;
      x = x.clamp(halfWidth, game.size.x - halfWidth);
    } 
    // Fallback to lane logic (e.g. for keyboard)
    else if (isTransitioning && (x - targetX).abs() > 1) {
      double direction = targetX > x ? 1 : -1;
      double moveAmount = transitionSpeed * dt * direction;

      // Check if we'll overshoot
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
    targetX = (currentLane * laneW) + (laneW / 2);
    isTransitioning = true;
  }

  void takeHit() {
    health--;
    game.onHealthUpdate(health);

    // Feedback: Slow down
    game.currentSpeed *= 0.5; // Slow down

    if (health <= 0) {
      removeFromParent();
      game.gameOver();
    }
  }

  void reset() {
    health = 3;
    currentLane = 1;
    _updatePosition();
    if (parent == null) game.add(this);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Obstacle) {
      takeHit();
      other
          .removeFromParent(); // Destroy obstacle on hit? Or pass through? User said "boat slows", implies survival.
    } else if (other is Collectible) {
      other.collect();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

// --- Scrolling Object Base ---
abstract class ScrollingObject extends PositionComponent
    with HasGameReference<MarshesGame> {
  ScrollingObject({required Vector2 size})
      : super(
          size: size,
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
  static const double sugarCaneWidth = 80.0; // Fixed width for both variants
  static const double sugarCaneHeight =
      79.0; // Original height for sugar_cane.png
  static const double sugarCaneHighHeight =
      87.0; // Original height for sugar_cane_high.png

  final bool useHighVariant;

  Obstacle({this.useHighVariant = false})
      : super(
          size: useHighVariant
              ? Vector2(sugarCaneWidth, sugarCaneHighHeight)
              : Vector2(sugarCaneWidth, sugarCaneHeight),
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load the appropriate sugar cane sprite
    final spriteName =
        useHighVariant ? 'sugar_cane_high.png' : 'sugar_cane.png';
    final sprite = await game.loadSprite(spriteName);

    add(SpriteComponent(
      sprite: sprite,
      size: size,
    ));
  }
}

abstract class Collectible extends ScrollingObject {
  Collectible({required Vector2 size}) : super(size: size);
  void collect();
}

class FishCollectible extends Collectible {
  static const double fishSize = 40.0; // Smaller than boat (64.0)

  FishCollectible() : super(size: Vector2(fishSize, fishSize));

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load and add fish sprite
    final fishSprite = await game.loadSprite('fish_sprite.png');
    add(SpriteComponent(
      sprite: fishSprite,
      size: size,
    ));
  }

  @override
  void collect() {
    game.playItemCollectSound(); // Play item collection sound
    game.incrementFishCount();
    removeFromParent();
  }
}

class StoryCollectible extends Collectible {
  late SpriteAnimationComponent _boxSprite;
  bool isOpening = false;

  StoryCollectible() : super(size: Vector2(kBaseSize, kBaseSize));

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load and display idle box sprite
    final idleBoxSprite = await game.loadSpriteAnimation(
        'chest.png',
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.1,
          textureSize: Vector2(32, 32),
        ));
    _boxSprite = SpriteAnimationComponent(
      animation: idleBoxSprite,
      size: size,
    );
    add(_boxSprite);
  }

  @override
  void collect() async {
    if (isOpening) return; // Prevent multiple collections
    isOpening = true;

    // Play random bonus sound for chest acquisition
    game.playBonusSound();

    // // Change to open box sprite
    // final openBoxSprite = await game.loadSpriteAnimation(
    //     'box_open.png',
    //     SpriteAnimationData.sequenced(
    //       amount: 5,
    //       stepTime: 0.05,
    //       textureSize: Vector2(64, 64),
    //     ));
    // _boxSprite.animation = openBoxSprite;

    // Wait for a short animation delay (box opening)
    await Future.delayed(const Duration(milliseconds: 300));

    // Remove the box
    removeFromParent();

    // Trigger story dialog
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
