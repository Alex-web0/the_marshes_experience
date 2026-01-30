# 🎵 Background Music Implementation

## Overview
Added background music support to "The Marshes Experience" game using Flame Audio engine. Music plays **only during active gameplay** and pauses/stops appropriately based on game state.

---

## Changes Made

### 1. **Updated `pubspec.yaml`**
Added music assets directory:
```yaml
assets:
  - assets/images/
  - assets/music/
```

### 2. **Updated `lib/game/marshes_game.dart`**

#### Imports
- Added `import 'package:flame_audio/flame_audio.dart';`

#### Audio Preloading (in `onLoad()`)
```dart
await FlameAudio.audioCache.load('music/bg_music_game.mp3');
```

#### New Audio Methods
```dart
void playBackgroundMusic() {
  FlameAudio.bgm.play('music/bg_music_game.mp3', volume: 0.5);
}

void stopBackgroundMusic() {
  FlameAudio.bgm.stop();
}

void pauseBackgroundMusic() {
  FlameAudio.bgm.pause();
}

void resumeBackgroundMusic() {
  FlameAudio.bgm.resume();
}
```

#### Integration Points

**Game Start** (`startGame()`)
- ✅ Music starts playing when user taps "PLAY"

**Story Pause** (`pauseForStory()`)
- ⏸️ Music pauses when story dialog appears

**Story Resume** (`resumeGame()`)
- ▶️ Music resumes when player dismisses story

**Game Over** (`gameOver()`)
- ⏹️ Music stops completely

**Return to Menu** (`resetToMenu()`)
- ⏹️ Music stops when returning to main menu

**Cleanup** (`onRemove()`)
- 🧹 Music stops on game disposal

---

## Audio File
- **Location**: `assets/music/bg_music_game.mp3`
- **Format**: MP3
- **Volume**: 0.5 (50%) - adjustable in `playBackgroundMusic()`

---

## Game States & Music Behavior

| State | Music Status | Trigger |
|-------|-------------|---------|
| **Main Menu** | 🔇 Silent | Initial state |
| **Playing** | 🔊 Playing | `startGame()` called |
| **Story Dialog** | ⏸️ Paused | Collecting story item |
| **Game Over** | ⏹️ Stopped | Player loses all health |
| **Back to Menu** | ⏹️ Stopped | "Main Menu" button |

---

## Technical Details

### Flame Audio BGM (Background Music)
- Uses `FlameAudio.bgm` singleton for background music
- Automatically loops by default
- Supports pause/resume for seamless story interruptions
- Volume configurable (currently 0.5)

### Preloading
Music is preloaded in `onLoad()` to prevent lag when starting gameplay.

### Memory Management
- Music stops in `onRemove()` to prevent memory leaks
- Proper cleanup when game widget is disposed

---

## Testing Checklist

- [ ] Music plays when pressing "PLAY"
- [ ] No music during main menu
- [ ] Music pauses during story dialogs
- [ ] Music resumes after dismissing story
- [ ] Music stops on game over
- [ ] Music stops when returning to menu
- [ ] No music glitches or overlaps
- [ ] Volume is appropriate (50%)

---

## Future Enhancements

1. **Volume Controls**: Add UI slider for user-adjustable volume
2. **Menu Music**: Add separate ambient music for menus
3. **Sound Effects**: 
   - Collect fish (success chime)
   - Hit obstacle (impact sound)
   - Story collect (mystical chime)
   - Game over (sad/dramatic sound)
4. **Music Fade**: Implement fade in/out transitions
5. **Multiple Tracks**: Different music for difficulty levels
6. **Settings Persistence**: Remember user volume preferences

---

## Troubleshooting

**Music doesn't play:**
1. Verify file exists: `assets/music/bg_music_game.mp3`
2. Check `pubspec.yaml` includes `assets/music/`
3. Run `flutter pub get`
4. Clean and rebuild: `flutter clean && flutter run`

**Import error:**
The "unused import" warning for flame_audio is a false positive - it's used via `FlameAudio.bgm` and `FlameAudio.audioCache`.

---

## Code Quality
- ✅ No breaking changes to existing functionality
- ✅ Clean separation of concerns
- ✅ Proper resource management
- ✅ Follows Flame best practices
- ✅ No compilation errors
