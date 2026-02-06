# 📝 Storyline Integration - Code Changes Summary

## Files Modified

### 1. **`lib/game/marshes_game.dart`** - Game Engine
**Added:**
```dart
// New callback for interactive storylines
final Function(String storyId) onStorylineTriggered;

// New method to pause for storylines
void pauseForStoryline(String storyId) {
  isPlaying = false;
  pauseBackgroundMusic();
  onStorylineTriggered(storyId);
}
```

**Modified spawn logic:**
```dart
void _spawnObject() {
  // OLD: 10% Story, 30% Fish, 60% Obstacle
  // NEW: 8% Interactive Storyline, 7% Heritage Fact, 30% Fish, 55% Obstacle
  
  if (roll < 0.08) {
    add(InteractiveStorylineCollectible()..position = Vector2(xPos, -100));
  } else if (roll < 0.15) {
    add(StoryCollectible()..position = Vector2(xPos, -100)); // Heritage fact
  } else if (roll < 0.45) {
    add(FishCollectible()..position = Vector2(xPos, -100));
  } else {
    add(Obstacle(useHighVariant: useHigh)..position = Vector2(xPos, -100));
  }
}
```

---

### 2. **`lib/game/components.dart`** - Game Objects
**Added new collectible class:**
```dart
class InteractiveStorylineCollectible extends Collectible {
  late SpriteComponent _bookSprite;
  bool isCollecting = false;

  InteractiveStorylineCollectible() : super(size: Vector2(kBaseSize, kBaseSize));

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Book sprite with amber tint
    final bookSprite = await game.loadSprite('chest.png');
    _bookSprite = SpriteComponent(
      sprite: bookSprite,
      size: size,
    );
    
    // Amber color to distinguish from heritage facts
    _bookSprite.paint = Paint()..colorFilter = const ColorFilter.mode(
      Colors.amber,
      BlendMode.modulate,
    );
    
    add(_bookSprite);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Floating animation
    _bookSprite.scale = Vector2.all(1.0 + 0.1 * (1 + sin(position.y * 0.01)));
  }

  @override
  void collect() async {
    if (isCollecting) return;
    isCollecting = true;

    game.playBonusSound();
    removeFromParent();

    // Smart story selection based on player progress
    final storylineRepo = StorylineRepository();
    final availableStories = storylineRepo.getAvailableStories(
      fishCount: game.fishCount,
      storyCount: game.storyCount,
    );

    if (availableStories.isNotEmpty) {
      final random = Random();
      final selectedStory = availableStories[random.nextInt(availableStories.length)];
      
      // Trigger interactive storyline
      game.pauseForStoryline(selectedStory.id);
    } else {
      // Fallback if no stories available
      game.incrementStoryCount();
      game.resumeGame();
    }
  }
}
```

**Kept old collectible:**
```dart
class StoryCollectible extends Collectible {
  // Still triggers heritage facts (simple info dialogs)
  // Now spawns at 7% instead of 10%
}
```

---

### 3. **`lib/main.dart`** - App Container & State
**Added state tracking:**
```dart
bool _activeStorylineFromGame = false; // Track source of storyline
```

**Added callback to game initialization:**
```dart
_game = MarshesGame(
  onGameOver: _handleGameOver,
  onStoryTrigger: _showStoryDialog,          // Old heritage facts
  onStorylineTriggered: _showGameStoryline,  // NEW: Interactive storylines
  onScoreUpdate: (s) { ... },
  onHealthUpdate: (h) { ... },
  onFishCountUpdate: (f) { ... },
  onStoryCountUpdate: (s) { ... },
  onPauseTriggered: _showPauseDialog,
);
```

**Added new handler methods:**
```dart
// NEW: Handle storyline triggered from gameplay
void _showGameStoryline(String storyId) {
  setState(() {
    _activeStorylineId = storyId;
    _activeStorylineFromGame = true;  // Mark as from game
  });
}

// UPDATED: Close storyline with proper game resume
void _closeStoryline() {
  final wasFromGame = _activeStorylineFromGame;
  setState(() {
    _activeStorylineId = null;
    _activeStorylineFromGame = false;
    if (!wasFromGame) {
      _showMenu = true;
    }
  });
  
  // Resume game if from gameplay
  if (wasFromGame) {
    _game.resumeGame();
  }
}

// UPDATED: Apply rewards to game state
void _handleStorylineRewards(Map<String, int>? rewards) {
  if (rewards == null) return;
  
  setState(() {
    if (rewards['score'] != null) {
      _score += rewards['score']!;
    }
    if (rewards['fishCount'] != null) {
      _fishCount += rewards['fishCount']!;
    }
    if (rewards['storyCount'] != null) {
      _storyCount += rewards['storyCount']!;
    }
  });
  
  // Sync story count with game state
  if (_activeStorylineFromGame && rewards['storyCount'] != null) {
    _game.incrementStoryCount();
  }
}
```

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    GAMEPLAY FLOW                             │
└─────────────────────────────────────────────────────────────┘

Player Playing Game
        ↓
Collect Amber Book (8% chance)
        ↓
InteractiveStorylineCollectible.collect()
        ↓
Check available stories (fishCount, storyCount)
        ↓
Select random available story
        ↓
game.pauseForStoryline(storyId)
        ↓
┌───────────────────────────────────────┐
│ MarshesGame.pauseForStoryline()      │
│ - isPlaying = false                   │
│ - pauseBackgroundMusic()              │
│ - onStorylineTriggered(storyId)      │
└───────────────────────────────────────┘
        ↓
main.dart._showGameStoryline(storyId)
        ↓
┌───────────────────────────────────────┐
│ Update State                          │
│ - _activeStorylineId = storyId        │
│ - _activeStorylineFromGame = true     │
└───────────────────────────────────────┘
        ↓
StorylineDialog shown in stack
        ↓
Player makes choices
        ↓
Story completes
        ↓
_handleStorylineRewards(rewards)
        ↓
┌───────────────────────────────────────┐
│ Apply Rewards                         │
│ - Update _score                       │
│ - Update _fishCount                   │
│ - Update _storyCount                  │
│ - game.incrementStoryCount()          │
└───────────────────────────────────────┘
        ↓
_closeStoryline()
        ↓
┌───────────────────────────────────────┐
│ Resume Game                           │
│ - _activeStorylineId = null           │
│ - _activeStorylineFromGame = false    │
│ - game.resumeGame()                   │
│   - isPlaying = true                  │
│   - resumeBackgroundMusic()           │
└───────────────────────────────────────┘
        ↓
Player continues playing
```

---

## Debug Menu vs Gameplay

### Debug Menu Flow:
```
Main Menu → 🐛 TEST STORIES → Select Story
                                    ↓
                          _showStoryline(storyId)
                                    ↓
              _activeStorylineFromGame = false
                                    ↓
                          Story dialog shows
                                    ↓
                          Player completes
                                    ↓
                        Rewards NOT applied
                                    ↓
                      _closeStoryline()
                                    ↓
                        Back to main menu
```

### Gameplay Flow:
```
Playing Game → Collect Book → Story triggers
                                    ↓
                    _showGameStoryline(storyId)
                                    ↓
              _activeStorylineFromGame = true
                                    ↓
                          Story dialog shows
                                    ↓
                          Player completes
                                    ↓
                       Rewards APPLIED to game
                                    ↓
                      _closeStoryline()
                                    ↓
                       Game auto-resumes
```

---

## Key Differences from Debug Testing

| Feature | Debug Menu | Gameplay |
|---------|-----------|----------|
| **Access** | Main menu button | Collect book in-game |
| **Game State** | Not running | Paused |
| **Music** | Menu music | Paused game music |
| **Rewards** | Not applied | Applied to session |
| **After Close** | Return to menu | Resume game |
| **Story Count** | Not incremented | Incremented |
| **Purpose** | Testing/preview | Real gameplay |

---

## State Management

### Key Variables:
```dart
// In _GameContainerState
_activeStorylineId: String?              // Which story is showing
_activeStorylineFromGame: bool           // Source: gameplay vs debug
_showDebugStorylineMenu: bool            // Debug menu visible
_showMenu: bool                          // Main menu visible

// These work together to determine:
// - Which UI layer to show
// - Whether to resume game
// - Whether to apply rewards
// - Where to return after close
```

### State Transitions:
```dart
// From gameplay:
_activeStorylineFromGame = true
  → Story shows
  → Rewards apply
  → Game resumes

// From debug menu:
_activeStorylineFromGame = false
  → Story shows
  → No rewards
  → Return to menu
```

---

## Testing Checklist

### ✅ Gameplay Integration:
- [ ] Start single-player game
- [ ] Collect amber-tinted book collectible
- [ ] Verify game pauses
- [ ] Verify music pauses
- [ ] Complete storyline with choices
- [ ] Verify rewards apply (check HUD)
- [ ] Verify game auto-resumes
- [ ] Verify music resumes
- [ ] Verify player position maintained

### ✅ Story Selection Logic:
- [ ] With 0 fish: Get Old Fisherman/Evening Peace/Great Marsh
- [ ] With 2+ fish: Can get Lost Child story
- [ ] With 1+ story completed: Can get Marsh Guardian
- [ ] Different stories on multiple collections

### ✅ State Management:
- [ ] Debug menu still works independently
- [ ] Gameplay stories don't affect debug menu
- [ ] Game over screen shows correct story count
- [ ] Rewards persist until game over

### ✅ Edge Cases:
- [ ] Multiple story collections in one game
- [ ] Story collection right before game over
- [ ] Pause menu during regular gameplay (not storyline)
- [ ] Heritage facts still work (chest collectibles)

---

## Summary of Changes

### New Features:
✅ Interactive storylines spawn during gameplay (8%)  
✅ Smart story selection based on player progress  
✅ Automatic game pause/resume with music handling  
✅ Reward system integrated with game stats  
✅ Separate tracking for debug vs gameplay storylines  

### Files Changed:
- `lib/game/marshes_game.dart` - Added storyline callback & pause method
- `lib/game/components.dart` - Created InteractiveStorylineCollectible
- `lib/main.dart` - Added state tracking & reward application

### Lines Added: ~150 lines
### Files Created: 2 documentation files

### Compatibility:
✅ Old heritage fact system still works  
✅ Debug menu unchanged  
✅ All existing features maintained  
✅ No breaking changes  

🚀 **Ready for gameplay testing!**
