# Storyline Spawn & Selection Mechanics

## 📊 Spawn Rate: **10% Chance**

When playing the game, a chest collectible (StoryCollectible) spawns with a **10% chance** every 1.5 seconds.

### Complete Spawn Distribution:
- **10%** - Story Chest (Interactive Storyline)
- **30%** - Fish Collectible
- **60%** - Obstacles (Sugar Cane)

### Spawn Location:
```dart
// From marshes_game.dart - _spawnObject()
void _spawnObject() {
  final rand = Random();
  int lane = rand.nextInt(3); // Random lane (0, 1, or 2)
  double xPos = lane * laneWidth + (laneWidth / 2);
  
  double roll = rand.nextDouble();
  
  if (roll < 0.1) {
    // 10% - Story Chest spawns
    add(StoryCollectible()..position = Vector2(xPos, -100));
  } else if (roll < 0.4) {
    // 30% - Fish
    add(FishCollectible()..position = Vector2(xPos, -100));
  } else {
    // 60% - Obstacles
    add(Obstacle(useHighVariant: useHigh)..position = Vector2(xPos, -100));
  }
}
```

---

## 🎯 Story Selection System

When a chest is collected, the system intelligently selects a story based on your current progress.

### Selection Process:

#### 1. **Filter Available Stories**
The system checks all 5 stories and filters based on `triggerRequirements`:

```dart
// From components.dart - StoryCollectible.collect()
final availableStories = storylineRepo.getAvailableStories(
  fishCount: game.fishCount,      // Current fish collected
  storyCount: game.storyCount,    // Stories completed
);
```

#### 2. **Check Requirements**
Each story can have optional requirements:

```dart
// From storyline_repository.dart
List<StorylineElement> getAvailableStories({
  required int fishCount,
  required int storyCount,
}) {
  return _storylineElements.values.where((story) {
    if (story.triggerRequirements == null) return true; // Always available
    
    final reqs = story.triggerRequirements!;
    if (reqs['fishCount'] != null && fishCount < reqs['fishCount']!) {
      return false; // Not enough fish
    }
    if (reqs['storyCount'] != null && storyCount < reqs['storyCount']!) {
      return false; // Not enough stories completed
    }
    
    return true;
  }).toList();
}
```

#### 3. **Random Selection**
From the available stories that meet requirements, one is randomly selected:

```dart
if (availableStories.isNotEmpty) {
  final random = Random();
  final selectedStory = availableStories[random.nextInt(availableStories.length)];
  game.pauseForStoryline(selectedStory.id);
}
```

---

## 📚 All 5 Available Stories

### 1. **"The Old Fisherman"** (`old_fisherman_encounter`)
- **Trigger Requirements:** NONE (Always available from start)
- **Description:** "A chance meeting with a wise old fisherman by the river"
- **Rewards:** 
  - +50 score points
  - +1 story count
- **Availability:** ✅ **Available immediately**

---

### 2. **"The Lost Child"** (`lost_child_quest`)
- **Trigger Requirements:** NONE (Always available from start)
- **Description:** "A child needs help finding her way home"
- **Rewards:**
  - +150 score points
  - +1 story count
- **Availability:** ✅ **Available immediately**

---

### 3. **"The Marsh Guardian"** (`marsh_guardian_trial`)
- **Trigger Requirements:** 
  - `storyCount >= 1` (Must complete at least 1 story first)
- **Description:** "A mystical guardian offers you a trial"
- **Rewards:**
  - +200 score points
  - +1 story count
- **Availability:** 🔒 **Unlocks after completing 1 story**

---

### 4. **"Evening Peace"** (`evening_peace`)
- **Trigger Requirements:** NONE (Always available from start)
- **Description:** "A quiet moment in the marshes"
- **Rewards:**
  - +25 score points
- **Character:** Narrator only (no dialogue character)
- **Availability:** ✅ **Available immediately**

---

### 5. **"Tale of the Great Marsh"** (`tale_of_the_great_marsh`)
- **Trigger Requirements:** NONE (Always available from start)
- **Description:** "An elder shares ancient wisdom"
- **Rewards:**
  - +75 score points
  - +1 story count
- **Availability:** ✅ **Available immediately**

---

## 🎮 Progression Logic

### First Chest (storyCount = 0, fishCount varies):
**Available stories:**
- Old Fisherman
- Lost Child
- Evening Peace
- Tale of the Great Marsh

**Not available yet:**
- ❌ Marsh Guardian (requires storyCount >= 1)

**Result:** System randomly picks 1 of the 4 available stories

---

### Second+ Chests (storyCount >= 1):
**Available stories:**
- Old Fisherman
- Lost Child
- Evening Peace
- Tale of the Great Marsh
- ✅ Marsh Guardian (NOW UNLOCKED)

**Result:** System randomly picks 1 of all 5 stories

---

## 🎲 Probability Breakdown

### To Get a Story:
1. Chest must spawn: **10% chance** per spawn cycle (every 1.5 seconds)
2. Must successfully collect the chest (avoid obstacles, catch it)
3. Story is then selected from available pool

### Expected Story Frequency:
- Average spawns per minute: ~40 objects
- Expected chests per minute: ~4 chests (10% of 40)
- **If you collect every chest:** ~4 stories per minute
- **Realistic gameplay:** 1-3 stories per minute depending on skill

### Story Selection Odds:
- **Before first story:** 25% chance each for 4 available stories
- **After first story:** 20% chance each for all 5 stories

---

## 💡 Smart Features

### 1. **Progressive Unlocking**
- Most stories available immediately for variety
- "Marsh Guardian" unlocks after 1 completion (premium content reward)

### 2. **No Duplicates Issue**
- Stories CAN repeat (no duplicate prevention currently)
- Each chest roll is independent
- This allows re-experiencing favorite stories

### 3. **Fallback Safety**
```dart
if (availableStories.isNotEmpty) {
  // Select and show story
} else {
  // Fallback: give bonus points and resume game
  game.incrementStoryCount();
  game.resumeGame();
}
```

### 4. **Automatic Pause**
- Game pauses when story appears
- Automatically resumes after story completion
- All gameplay stats preserved

---

## 🔧 Technical Summary

| Aspect | Value |
|--------|-------|
| Spawn Rate | 10% per cycle |
| Spawn Interval | Every 1.5 seconds |
| Total Stories | 5 |
| Always Available | 4 stories |
| Locked Initially | 1 story (Marsh Guardian) |
| Unlock Condition | Complete 1 story |
| Selection Method | Random from available pool |
| Duplicate Prevention | None (stories can repeat) |

---

## 📝 Code Locations

- **Spawn Logic:** `lib/game/marshes_game.dart` - `_spawnObject()`
- **Collection Logic:** `lib/game/components.dart` - `StoryCollectible.collect()`
- **Filtering Logic:** `lib/data/storyline_repository.dart` - `getAvailableStories()`
- **Story Definitions:** `lib/data/storyline_repository.dart` - `_createXxxStory()` methods
