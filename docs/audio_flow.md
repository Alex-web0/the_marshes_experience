# 🎵 Audio System Flow Diagram

## State Machine for Background Music

```
┌─────────────────────────────────────────────────────────────────┐
│                         GAME LIFECYCLE                          │
└─────────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │  MAIN MENU  │  🔇 No Music
    └──────┬──────┘
           │
           │ User presses "PLAY"
           │ → startGame()
           ▼
    ┌─────────────┐
    │   PLAYING   │  🔊 Music Playing (volume: 0.5)
    └──────┬──────┘
           │
           ├───────────────────────────────────┐
           │                                   │
           │ Collect Story (?)                 │ Lose All Health
           │ → pauseForStory()                 │ → gameOver()
           ▼                                   ▼
    ┌─────────────┐                    ┌─────────────┐
    │STORY DIALOG │  ⏸️ Music Paused    │  GAME OVER  │  ⏹️ Music Stopped
    └──────┬──────┘                    └──────┬──────┘
           │                                   │
           │ Tap to dismiss                    │ Press "MAIN MENU"
           │ → resumeGame()                    │ → resetToMenu()
           ▼                                   ▼
    ┌─────────────┐                    ┌─────────────┐
    │   PLAYING   │  ▶️ Music Resumed   │  MAIN MENU  │  🔇 No Music
    └──────┬──────┘                    └─────────────┘
           │
           │ Press "MAIN MENU" (if paused)
           │ → resetToMenu()
           ▼
    ┌─────────────┐
    │  MAIN MENU  │  ⏹️ Music Stopped
    └─────────────┘
```

---

## Method Call Flow

### 🎮 Game Start
```
User Action: Tap "PLAY" button
    ↓
main.dart: _GameContainerState._startGame()
    ↓
marshes_game.dart: MarshesGame.startGame()
    ↓
🎵 playBackgroundMusic()
    ↓
FlameAudio.bgm.play('music/bg_music_game.mp3', volume: 0.5)
```

### 📖 Story Trigger
```
Collision: Player → StoryCollectible
    ↓
components.dart: StoryCollectible.collect()
    ↓
marshes_game.dart: pauseForStory(fact)
    ↓
⏸️ pauseBackgroundMusic()
    ↓
FlameAudio.bgm.pause()
    ↓
ui_layers.dart: HeritageStoryDialog shown
```

### 📖 Story Dismiss
```
User Action: Tap anywhere on dialog
    ↓
main.dart: _GameContainerState._dismissStory()
    ↓
marshes_game.dart: resumeGame()
    ↓
▶️ resumeBackgroundMusic()
    ↓
FlameAudio.bgm.resume()
```

### 💔 Game Over
```
Event: Player health reaches 0
    ↓
components.dart: BoatPlayer.takeHit()
    ↓
marshes_game.dart: gameOver()
    ↓
⏹️ stopBackgroundMusic()
    ↓
FlameAudio.bgm.stop()
    ↓
game_over_menu.dart: GameOverMenu shown
```

### 🏠 Return to Menu
```
User Action: Tap "MAIN MENU" button
    ↓
main.dart: _GameContainerState._goToMainMenu()
    ↓
marshes_game.dart: resetToMenu()
    ↓
⏹️ stopBackgroundMusic()
    ↓
FlameAudio.bgm.stop()
```

---

## Audio Lifecycle Management

### Preloading (onLoad)
```dart
@override
Future<void> onLoad() async {
  // Load audio into cache to prevent lag
  await FlameAudio.audioCache.load('music/bg_music_game.mp3');
  // ... rest of initialization
}
```

### Cleanup (onRemove)
```dart
@override
void onRemove() {
  _sensorSubscription?.cancel();
  stopBackgroundMusic();  // ← Ensures no memory leaks
  super.onRemove();
}
```

---

## Key Features

### ✅ Smart State Management
- Music **only** plays during active gameplay
- **Never** plays in menus or game over screens
- Seamlessly pauses/resumes during story dialogs

### ✅ Resource Efficient
- Audio preloaded during game initialization
- Single BGM instance (no overlapping tracks)
- Proper cleanup prevents memory leaks

### ✅ User Experience
- Volume set to 50% (adjustable)
- Loops automatically during gameplay
- No jarring cuts (smooth pause/resume)

---

## File Structure
```
the_marshes_experience/
├── assets/
│   └── music/
│       └── bg_music_game.mp3  ← Audio file
├── lib/
│   ├── game/
│   │   └── marshes_game.dart  ← Audio logic
│   └── main.dart              ← State triggers
└── pubspec.yaml               ← Asset declaration
```

---

## Testing Commands

### Run on Desktop (Quick Test)
```bash
flutter run -d macos
# or
flutter run -d windows
# or
flutter run -d linux
```

### Run on Mobile (Full Experience)
```bash
flutter run -d <device-id>
```

### Check for Audio Issues
```bash
flutter analyze
flutter doctor
```

---

## Debugging Tips

1. **Check audio file exists:**
   ```bash
   ls -la assets/music/bg_music_game.mp3
   ```

2. **Verify asset declaration:**
   ```bash
   grep -A5 "assets:" pubspec.yaml
   ```

3. **Test audio in isolation:**
   ```dart
   // In onLoad() or a test method
   await FlameAudio.audioCache.load('music/bg_music_game.mp3');
   FlameAudio.bgm.play('music/bg_music_game.mp3');
   ```

4. **Check device audio:**
   - Ensure device volume is up
   - Check silent mode is off
   - Test with headphones

---

## Performance Notes

- **Memory**: ~3-5MB for typical game music file
- **CPU**: Minimal (handled by platform audio APIs)
- **Load Time**: <500ms with preloading
- **Battery**: Negligible impact

---

## Platform Compatibility

| Platform | Status | Notes |
|----------|--------|-------|
| iOS | ✅ | Requires audio session configuration |
| Android | ✅ | Full support |
| Web | ✅ | May require user interaction first |
| macOS | ✅ | Full support |
| Windows | ✅ | Full support |
| Linux | ✅ | Full support |

