# 🎮 Storyline System - Gameplay Integration

## Overview
The interactive storyline system is now **fully integrated** into single-player gameplay! Players will encounter storyline events during their journey through the marshes.

---

## 🎯 How It Works

### Collectible Types
During gameplay, players now encounter **3 types of collectibles**:

1. **🐟 Fish (30%)** - Increases fish count, used as currency
2. **📦 Chest (7%)** - Old heritage facts (simple info dialogs)
3. **✨ Storyline Book (8%)** - NEW! Interactive storylines with choices

### Spawn Distribution
```dart
// From _spawnObject() in marshes_game.dart
- 8%  → Interactive Storyline (amber-tinted book icon)
- 7%  → Heritage Fact (chest with animation)
- 30% → Fish (cyan collectible)
- 55% → Obstacles (sugar cane variants)
```

---

## 📖 Interactive Storyline Flow

### 1. **Collection**
When player collects a storyline book:
- ✅ Game pauses automatically
- ✅ Music pauses
- ✅ Bonus sound plays
- ✅ System checks player progress (fish count, story count)
- ✅ Selects an appropriate story based on requirements

### 2. **Story Selection Logic**
```dart
// Smart selection based on player stats
StorylineRepository.getAvailableStories(
  fishCount: currentFishCount,
  storyCount: currentStoryCount,
)
```

**Available Stories:**
- **Old Fisherman** - Always available (no requirements)
- **Lost Child** - Requires 2+ fish caught
- **Marsh Guardian** - Requires 1+ story completed
- **Evening Peace** - Always available (narrator only)
- **Tale of the Great Marsh** - Always available

### 3. **During Storyline**
- Game remains paused
- Music stays paused
- Player makes choices
- Can view character portraits
- Text scrolls for long content

### 4. **After Completion**
- ✅ Rewards applied to game stats
- ✅ Story count increases
- ✅ Game automatically resumes
- ✅ Music resumes
- ✅ Player continues from same position

---

## 🎁 Reward System

### Rewards Are Applied Immediately
When a storyline completes, rewards update:

```dart
Rewards can include:
- score: Points (e.g., +50, +150, +200)
- fishCount: Fish bonus (e.g., +1, +2)
- storyCount: Story completion count (always +1)
```

### Example Rewards:
| Story | Score | Fish | Stories |
|-------|-------|------|---------|
| Old Fisherman | +50 | - | +1 |
| Lost Child | +150 | - | +1 |
| Marsh Guardian | +200 | - | +1 |
| Evening Peace | +25 | - | - |
| Great Marsh Tale | +75 | - | +1 |

### Reward Integration
```dart
// In main.dart - _handleStorylineRewards()
- Updates HUD displays (score, fish, stories)
- Updates internal game counters
- Syncs with game state for future requirements
```

---

## 🎨 Visual Differences

### Heritage Fact (Old System)
- **Icon:** Animated chest (6-frame animation)
- **Color:** Default sprite colors
- **Trigger:** Simple info dialog
- **Dismissal:** Tap anywhere to continue

### Interactive Storyline (New System)
- **Icon:** Book sprite with amber tint
- **Animation:** Gentle floating/scaling effect
- **Trigger:** Full storyline dialog with choices
- **Dismissal:** Must complete the story (make choices)

---

## 🔄 Game Flow Integration

### Single-Player Mode
```
Player navigating → Collect book → Game pauses
                                      ↓
                              Story triggers
                                      ↓
                         Player makes choices
                                      ↓
                          Story completes
                                      ↓
                       Rewards applied
                                      ↓
                      Game resumes automatically
```

### State Management
```dart
// In main.dart
_activeStorylineFromGame: bool
  → Tracks if storyline came from gameplay vs debug menu
  → Determines whether to resume game after completion
  → Ensures proper music/pause state handling
```

---

## 🎮 Player Experience

### Progression System
1. **Early Game** (0-1 fish, 0 stories)
   - Old Fisherman
   - Evening Peace
   - Tale of the Great Marsh

2. **Mid Game** (2+ fish)
   - **Unlocked:** Lost Child (requires 2 fish)
   - All early game stories still available

3. **Late Game** (1+ story completed)
   - **Unlocked:** Marsh Guardian (requires previous story)
   - All previous stories still available

### Why This Matters
- Stories feel **earned** through gameplay
- Requirements create **progression goals**
- Players discover new content as they play
- Each playthrough can be different

---

## 🧪 Testing in Gameplay

### How to Test:
1. Start single-player game
2. Navigate and avoid obstacles
3. Collect fish (to unlock Lost Child story)
4. Wait for **amber-tinted book** collectibles
5. Collect book → Story triggers automatically
6. Make choices → Complete story
7. Observe rewards → Game resumes

### What to Check:
- ✅ Game pauses on collection
- ✅ Correct story appears based on progress
- ✅ Can make choices
- ✅ Text scrolls properly
- ✅ Rewards apply correctly
- ✅ Game resumes after completion
- ✅ Music resumes properly
- ✅ Player position maintained

---

## 🐛 Debug vs Gameplay

### Debug Menu (🐛 TEST STORIES button)
- **Access:** Main menu, debug mode only
- **Purpose:** Test all stories without gameplay
- **State:** Game not running, no rewards applied to game
- **Return:** Back to main menu

### Gameplay Storylines
- **Access:** During single-player game, collect book
- **Purpose:** Real storyline encounters
- **State:** Game paused, all stats active
- **Return:** Game resumes automatically
- **Rewards:** Applied to current game session

---

## 📊 Statistics Tracking

### During Game:
```dart
HUD displays:
- DIST: Distance traveled (top-left)
- 🐟 Fish count (top-left)
- 📚 Story count (top-left)
- ❤️ Lives (top-right, x3)
```

### Game Over:
```dart
GameStats includes:
- score: Final distance
- fishCount: Total fish collected
- storyCount: Total stories completed
- timestamp: When game ended
```

### Integration:
- Story completion increments `storyCount`
- Story rewards add to `score`
- Can add fish rewards if story grants them
- All tracked in game over screen

---

## 🎯 Design Philosophy

### Why Two Systems?
1. **Heritage Facts (7%)** - Quick cultural education
   - Simple, informative
   - No interruption to flow
   - Quick read and continue

2. **Interactive Storylines (8%)** - Deep engagement
   - Meaningful choices
   - Character interactions
   - Rewards and progression
   - Memorable experiences

### Balance:
- **15% collectibles** total (fish, chests, books)
- **85% obstacles** (maintains challenge)
- Stories feel **special** but not overwhelming
- Each story collection feels **earned**

---

## 🔮 Future Enhancements

### Potential Additions:
1. **More Stories**
   - Add to `storyline_repository.dart`
   - Define requirements based on progress
   - Automatically available in gameplay

2. **Unlockable Content**
   - Stories unlock based on achievements
   - Special stories for high scores
   - Rare story variants

3. **Story Replay**
   - Track completed stories
   - Option to replay favorites
   - Different choices = different outcomes

4. **Multiplayer Integration**
   - Shared story experiences
   - Collaborative choices
   - Competitive story collection

5. **Persistent Progress**
   - Save completed stories to database
   - Track all choices made
   - Story completion achievements

---

## 🚀 Summary

**The storyline system is now a core gameplay feature!**

✅ **Seamlessly integrated** into single-player mode  
✅ **Smart story selection** based on player progress  
✅ **Automatic pause/resume** with music handling  
✅ **Reward system** affects game stats  
✅ **Progressive unlocking** creates goals  
✅ **Separate from debug testing** (both work independently)  

Players now experience **rich, interactive narratives** naturally during gameplay, making each run through the marshes a unique storytelling journey! 🎮📖✨
