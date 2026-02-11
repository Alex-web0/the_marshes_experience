# 🎲 Storyline Chest Spawn Rate Control

## 📍 Location

**File:** `lib/game/marshes_game.dart`  
**Method:** `_spawnObject()` (around line 287-306)

---

## 🎯 Current Spawn Rate: **36%**

### The Code:
```dart
void _spawnObject() {
  if (!isPlaying) return;

  final rand = Random();
  int lane = rand.nextInt(laneCount);
  double xPos = lane * laneWidth + (laneWidth / 2);

  // 36% Chest (Interactive Storyline), 30% Fish, 34% Obstacle
  double roll = rand.nextDouble();

  if (roll < 0.36) {                          // ← STORY CHEST SPAWN RATE
    // Interactive storyline chest
    add(StoryCollectible()..position = Vector2(xPos, -100));
  } else if (roll < 0.66) {                    // Fish: 0.36 to 0.66 (30%)
    add(FishCollectible()..position = Vector2(xPos, -100));
  } else {                                     // Obstacles: 0.66 to 1.0 (34%)
    bool useHigh = rand.nextDouble() > 0.65;
    add(Obstacle(useHighVariant: useHigh)..position = Vector2(xPos, -100));
  }
}
```

---

## 📊 Current Distribution

| Object Type | Spawn Rate | Range |
|-------------|-----------|--------|
| **Story Chest** | 36% | 0.00 - 0.36 |
| **Fish** | 30% | 0.36 - 0.66 |
| **Obstacles** | 34% | 0.66 - 1.00 |

---

## 🔧 How to Change the Spawn Rate

### To Increase Story Chests:

**Example 1: Change to 50%**
```dart
if (roll < 0.50) {                          // ← Change from 0.36 to 0.50
  add(StoryCollectible()..position = Vector2(xPos, -100));
} else if (roll < 0.75) {                   // ← Adjust: 0.50 + 0.25 (fish)
  add(FishCollectible()..position = Vector2(xPos, -100));
} else {                                     // ← Remaining: 0.25 (obstacles)
  bool useHigh = rand.nextDouble() > 0.65;
  add(Obstacle(useHighVariant: useHigh)..position = Vector2(xPos, -100));
}
```
**Result:** 50% chests, 25% fish, 25% obstacles

---

**Example 2: Change to 25%**
```dart
if (roll < 0.25) {                          // ← Change from 0.36 to 0.25
  add(StoryCollectible()..position = Vector2(xPos, -100));
} else if (roll < 0.55) {                   // ← Adjust: 0.25 + 0.30 (fish)
  add(FishCollectible()..position = Vector2(xPos, -100));
} else {                                     // ← Remaining: 0.45 (obstacles)
  bool useHigh = rand.nextDouble() > 0.65;
  add(Obstacle(useHighVariant: useHigh)..position = Vector2(xPos, -100));
}
```
**Result:** 25% chests, 30% fish, 45% obstacles

---

**Example 3: Change to 60% (Very High)**
```dart
if (roll < 0.60) {                          // ← Change from 0.36 to 0.60
  add(StoryCollectible()..position = Vector2(xPos, -100));
} else if (roll < 0.80) {                   // ← Adjust: 0.60 + 0.20 (fish)
  add(FishCollectible()..position = Vector2(xPos, -100));
} else {                                     // ← Remaining: 0.20 (obstacles)
  bool useHigh = rand.nextDouble() > 0.65;
  add(Obstacle(useHighVariant: useHigh)..position = Vector2(xPos, -100));
}
```
**Result:** 60% chests, 20% fish, 20% obstacles

---

## 🎮 Understanding the Math

### The Logic:
```dart
double roll = rand.nextDouble();  // Random number: 0.0 to 1.0
```

- If `roll < 0.36` → Story Chest (36% chance)
- Else if `roll < 0.66` → Fish (30% chance: from 0.36 to 0.66)
- Else → Obstacle (34% chance: from 0.66 to 1.0)

### Formula:
```
Chest Percentage = First Threshold × 100
Fish Percentage = (Second Threshold - First Threshold) × 100
Obstacle Percentage = (1.0 - Second Threshold) × 100
```

---

## 📈 Spawn Frequency Calculation

### Current Setup (36% spawn rate):
- **Spawn interval:** 1.5 seconds
- **Spawns per minute:** ~40 objects
- **Chests per minute:** ~14-15 chests
- **Stories per session (5 min):** ~70-75 chests spawned

### With Different Rates:

| Spawn Rate | Chests/Minute | Chests/5min |
|------------|---------------|-------------|
| 25% | ~10 | ~50 |
| 36% (current) | ~14-15 | ~70-75 |
| 50% | ~20 | ~100 |
| 60% | ~24 | ~120 |

---

## 💡 Recommended Ranges

### Balanced Gameplay:
- **20-30%** - Rare, special encounters
- **30-40%** - Regular story experience (current: 36%)
- **40-50%** - Story-focused gameplay
- **50-60%** - Very frequent stories (may be overwhelming)

### Considerations:
- ⚠️ **Too low (<20%):** Players may miss stories
- ⚠️ **Too high (>60%):** Overwhelming, less gameplay challenge
- ✅ **Sweet spot (30-45%):** Good balance of story and gameplay

---

## 🎯 Quick Reference Table

| Desired Rate | Change Line | Code |
|--------------|-------------|------|
| **25%** | Line ~296 | `if (roll < 0.25)` |
| **30%** | Line ~296 | `if (roll < 0.30)` |
| **36%** (current) | Line ~296 | `if (roll < 0.36)` |
| **40%** | Line ~296 | `if (roll < 0.40)` |
| **50%** | Line ~296 | `if (roll < 0.50)` |

**Remember:** Adjust the second threshold accordingly to maintain balance!

---

## 🔄 Related Systems

### Story Rotation System:
- Stories are tracked as "viewed" (see `storyline_repository.dart`)
- No duplicate stories until all 23+ viewed
- Auto-resets after completion
- Spawn rate affects how quickly players complete rotation

### Current with 36%:
- ~14-15 chests/minute
- ~3-5 minutes to see all 23 stories (if collecting most chests)

---

## 📝 Step-by-Step Change Guide

1. Open `lib/game/marshes_game.dart`
2. Find `_spawnObject()` method (line ~287)
3. Locate the spawn rate comment: `// 36% Chest (Interactive Storyline)...`
4. Change `if (roll < 0.36)` to your desired percentage (e.g., `0.50` for 50%)
5. Adjust the second threshold (`else if (roll < 0.66)`) to maintain balance
6. Update the comment to reflect new percentages
7. Save and hot reload/restart

---

## ✅ Current Status
**Spawn Rate:** 36% (Increased from original 18%)  
**Location:** `lib/game/marshes_game.dart`, line ~296  
**Distribution:** 36% stories, 30% fish, 34% obstacles
