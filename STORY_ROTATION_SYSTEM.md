# Story Rotation & Viewed Tracking System

## 🎯 Overview

The storyline system now includes intelligent rotation tracking to ensure players see all stories before any repeat, providing a complete heritage experience without redundancy.

---

## ✨ Key Features

### 1. **Viewed Stories Tracking**
- Each story ID is tracked when viewed
- Persisted to device cache using `SharedPreferences`
- Survives app restarts and game sessions

### 2. **Smart Selection Algorithm**
- **Prioritizes unviewed stories** - Players see new content first
- **Automatic reset** - When all stories viewed, rotation starts fresh
- **Respects requirements** - Still filters by fishCount/storyCount

### 3. **Persistent Cache**
- Stored in SharedPreferences under key: `viewed_story_ids`
- Automatically saves after each story view
- Loads on app initialization

---

## 🔄 How It Works

### Story Selection Flow:

```
Player collects chest
    ↓
1. Get all stories from repository
    ↓
2. Filter by trigger requirements (fishCount, storyCount)
    ↓
3. Filter out already-viewed stories
    ↓
4. If unviewed stories exist → Pick random from unviewed
   If all viewed → Reset tracking + Pick random from all
    ↓
5. Mark selected story as viewed
    ↓
6. Save to cache
    ↓
7. Display story to player
```

---

## 📊 Code Structure

### Modified Files:

#### 1. **storyline_repository.dart**

##### New Fields:
```dart
// Tracking which stories have been viewed
final Set<String> _viewedStoryIds = {};

// SharedPreferences key for cache
static const String _viewedStoriesKey = 'viewed_story_ids';
```

##### New Methods:

**Loading/Saving Cache:**
```dart
Future<void> _loadViewedStoriesFromCache() async
Future<void> _saveViewedStoriesToCache() async
```

**Marking Stories:**
```dart
// Mark story as viewed + auto-reset when all viewed
Future<void> markStoryAsViewed(String storyElementId) async

// Manual reset (for testing or new game)
Future<void> resetViewedStories() async
```

**Querying Viewed Status:**
```dart
// Get stories not yet viewed
List<StorylineElement> getUnviewedStories()

// Check if specific story viewed
bool hasStoryBeenViewed(String storyElementId)

// Get count of viewed stories
int getViewedStoriesCount()
```

**Updated Selection Logic:**
```dart
List<StorylineElement> getAvailableStories({
  required int fishCount,
  required int storyCount,
}) {
  // 1. Filter by requirements
  final eligibleStories = /* filter logic */;
  
  // 2. Get unviewed from eligible
  final unviewedEligible = eligibleStories
      .where((story) => !_viewedStoryIds.contains(story.id))
      .toList();
  
  // 3. Return unviewed OR all if none left
  return unviewedEligible.isNotEmpty ? unviewedEligible : eligibleStories;
}
```

#### 2. **components.dart (StoryCollectible)**

Updated `collect()` method:
```dart
if (availableStories.isNotEmpty) {
  final random = Random();
  final selectedStory = availableStories[random.nextInt(availableStories.length)];
  
  // ✨ NEW: Mark story as viewed
  await storylineRepo.markStoryAsViewed(selectedStory.id);
  
  game.pauseForStoryline(selectedStory.id);
}
```

---

## 🎮 Player Experience

### First Playthrough (0 viewed):
1. Collect chest → Story A (marked viewed)
2. Collect chest → Story B (marked viewed)
3. Collect chest → Story C (marked viewed)
4. ...continues with unviewed stories only

### After Viewing All Stories:
1. All 23+ stories marked as viewed
2. System automatically resets: `_viewedStoryIds.clear()`
3. Next chest → Fresh rotation starts
4. Player experiences all stories again in new random order

### Example Scenario:
```
Total Stories: 23
Viewed: 0

Chest 1 → Random from 23 unviewed → "Mudhif Discovery" (22 left)
Chest 2 → Random from 22 unviewed → "Buffalo Companion" (21 left)
Chest 3 → Random from 21 unviewed → "Fisherman Wisdom" (20 left)
...
Chest 23 → Last unviewed story → "Ancient Melody" (0 left)

[AUTO RESET TRIGGERED]

Chest 24 → Random from 23 again → "Tannur Oven" (22 left)
```

---

## 💾 Cache Persistence

### Storage Location:
- **Platform:** SharedPreferences
- **Key:** `viewed_story_ids`
- **Format:** List of String (story IDs)

### Example Cached Data:
```json
[
  "mudhif_discovery",
  "buffalo_companion",
  "fisherman_wisdom",
  "mashhuf_boat",
  "reeds_heritage"
]
```

### Persistence Benefits:
- ✅ Survives app restarts
- ✅ Survives game restarts
- ✅ No duplicate stories until all seen
- ✅ Consistent across sessions

### Cache Management:
```dart
// Load on app start
await _loadViewedStoriesFromCache();

// Save after each view
await _saveViewedStoriesToCache();

// Manual reset (if needed)
await resetViewedStories();
```

---

## 🔧 Technical Implementation Details

### Automatic Reset Logic:
```dart
Future<void> markStoryAsViewed(String storyElementId) async {
  _viewedStoryIds.add(storyElementId);
  await _saveViewedStoriesToCache();

  // Auto-reset when all stories viewed
  if (_viewedStoryIds.length >= _storylineElements.length) {
    await resetViewedStories();
  }
}
```

### Selection Priority:
```dart
// Priority 1: Unviewed + Eligible
final unviewedEligible = eligibleStories
    .where((story) => !_viewedStoryIds.contains(story.id))
    .toList();

// Priority 2: All Eligible (if none unviewed)
return unviewedEligible.isNotEmpty ? unviewedEligible : eligibleStories;
```

### Error Handling:
```dart
try {
  final prefs = await SharedPreferences.getInstance();
  // Cache operations
} catch (e) {
  print('Error with cache: $e');
  // Continue with in-memory tracking
}
```

---

## 📈 Statistics Tracking

### Available Methods:

```dart
// Get total viewed count
int viewedCount = repository.getViewedStoriesCount();

// Get unviewed stories
List<StorylineElement> unviewed = repository.getUnviewedStories();

// Check specific story
bool viewed = repository.hasStoryBeenViewed('mudhif_discovery');

// Calculate progress
double progress = viewedCount / totalStories;
```

### Example Usage:
```dart
// In UI or analytics
final repo = StorylineRepository();
print('Viewed: ${repo.getViewedStoriesCount()} / ${repo.getAllStorylineElements().length}');
print('Progress: ${(repo.getViewedStoriesCount() / repo.getAllStorylineElements().length * 100).toStringAsFixed(1)}%');
```

---

## 🎲 Spawn Rate Integration

### Current System:
- **Chest spawn rate:** 18% per 1.5s cycle
- **Expected chests/minute:** ~7-8 chests
- **Stories to see all:** 23+ stories

### Time to Complete Rotation:
- **Best case:** ~3-4 minutes (if collecting every chest)
- **Realistic:** 5-10 minutes of active gameplay
- **After rotation:** Fresh random order starts automatically

---

## 🧪 Testing & Debugging

### Manual Testing Commands:

```dart
final repo = StorylineRepository();

// Check viewed count
print('Viewed: ${repo.getViewedStoriesCount()}');

// List unviewed stories
final unviewed = repo.getUnviewedStories();
print('Unviewed: ${unviewed.map((s) => s.title).join(", ")}');

// Force reset (for testing)
await repo.resetViewedStories();
print('Reset complete - all stories available again');

// Check specific story
bool isSeen = repo.hasStoryBeenViewed('mudhif_discovery');
print('Mudhif story seen: $isSeen');
```

### Cache Verification:
```dart
// Check what's in SharedPreferences
final prefs = await SharedPreferences.getInstance();
final cached = prefs.getStringList('viewed_story_ids');
print('Cached IDs: $cached');
```

---

## 🚀 Benefits

### For Players:
- ✅ **Complete heritage experience** - See all 23+ stories
- ✅ **No redundancy** - No repeats until all viewed
- ✅ **Fresh on replay** - New random order each rotation
- ✅ **Progress persistence** - Tracking survives restarts

### For Development:
- ✅ **Easy to extend** - Add new stories seamlessly
- ✅ **Analytics ready** - Built-in progress tracking
- ✅ **Testable** - Manual reset for debugging
- ✅ **Maintainable** - Clean separation of concerns

### For Heritage Preservation:
- ✅ **Ensures exposure** - Every story gets seen
- ✅ **Equal representation** - All heritage aspects covered
- ✅ **Educational value** - Complete cultural knowledge transfer

---

## 🔮 Future Enhancements (Optional)

### Potential Additions:

1. **Weighted Random Selection**
   - Prioritize rare/important stories
   - Balance character avatar distribution

2. **Story Categories**
   - Track viewed per category (buffalo, mudhif, fishing, etc.)
   - Ensure variety within sessions

3. **Analytics Integration**
   - Export view history to Firebase
   - Track most/least viewed stories
   - Player engagement metrics

4. **UI Progress Indicator**
   - Show "Stories Discovered: X/23"
   - Achievement for viewing all stories
   - Progress bar in menu

5. **Smart Spacing**
   - Don't show same character avatars back-to-back
   - Delay recently viewed stories even after reset

---

## 📝 Summary

The story rotation system ensures:
- ✨ **Zero duplicates** until all stories seen
- 💾 **Persistent tracking** across sessions
- 🔄 **Automatic reset** for infinite replayability
- 🎯 **Smart selection** respecting requirements
- 🎲 **Random order** for freshness each rotation

Players will now experience the complete Al-Chibayish Marshes heritage collection without repetition!
