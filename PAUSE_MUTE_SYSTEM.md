# Pause and Mute System Documentation

## Overview
The game now includes a comprehensive pause menu system and global mute functionality with persistent state management.

## Features Implemented

### 1. Pause Menu System
**Location**: `lib/ui/pause_menu.dart`

The pause menu provides three options when the game is paused:
- **RESUME** - Continue playing from where you left off
- **RESTART** - Start a new game session
- **MAIN MENU** - Return to the main menu

**Design**:
- Glassmorphism design with backdrop blur effect
- Semi-transparent black overlay (70% opacity)
- Large, touch-friendly buttons with icons and text
- Pixelify Sans font for consistency
- Button sound effects on interaction

**Usage**:
- Press the pause button in the top-right corner during gameplay
- Game and music pause immediately
- Select an option to continue

### 2. Global Mute System
**Location**: `lib/data/audio_manager.dart`

A singleton pattern AudioManager that manages global audio state with persistence and real-time broadcasting.

**Features**:
- Persistent mute state using SharedPreferences
- Survives app restarts and session changes
- Single source of truth for audio state
- **Stream-based state broadcasting** for real-time updates
- **Automatic music control** - Background music responds to mute state changes
- Automatic state synchronization across all components

**API**:
```dart
// Initialize (called in main())
await AudioManager().initialize();

// Toggle mute (broadcasts state change via stream)
AudioManager().toggleMute();

// Check mute status
bool isMuted = AudioManager().isMuted;

// Set mute state directly (broadcasts state change via stream)
AudioManager().setMuted(true);

// Listen to mute state changes
AudioManager().muteStateStream.listen((isMuted) {
  // React to mute state changes
});
```

**Stream Architecture**:
- Uses `StreamController<bool>.broadcast()` for one-to-many communication
- Broadcasts `true` when audio is muted, `false` when unmuted
- All listeners receive state updates instantly
- Game automatically starts/stops music based on stream events

### 3. Mute Button Widget
**Location**: `lib/ui/mute_button.dart`

A reusable button component that displays the current mute state and allows toggling.

**Features**:
- Shows `unmute_button.png` when audio is on
- Shows `mute_button.png` when audio is muted
- Plays button sound before muting (if currently unmuted)
- Glassmorphism container with rounded corners
- **Uses StreamBuilder** to automatically update when state changes
- No manual setState needed - reacts to AudioManager stream

**Placement**:
- Main menu: Bottom center (below the menu dialog)
- Pause menu: Bottom center (below the pause dialog)

### 4. Audio Integration

All audio playback methods now check the mute state:
- `playBackgroundMusic()` - Gameplay music
- `playMenuMusic()` - Menu ambient music
- `resumeBackgroundMusic()` - Resume after pause
- `playButtonSound()` - Button click sounds
- `playDrowningSound()` - Player drowning
- `playItemCollectSound()` - Fish collection
- `playBonusSound()` - Story box collection

**Implementation Pattern**:
```dart
void playSound() {
  if (!AudioManager().isMuted) {
    FlameAudio.play('sounds/sound_file.mp3', volume: 0.5);
  }
}
```

**Stream Listener in Game**:
```dart
// MarshesGame listens to mute state changes
_muteStateSubscription = AudioManager().muteStateStream.listen((isMuted) {
  if (isMuted) {
    FlameAudio.bgm.stop();  // Stop music immediately
  } else {
    // Resume appropriate music based on game state
    if (isAutoPilot && !isPlaying) {
      playMenuMusic();  // Main menu music
    } else if (isPlaying) {
      playBackgroundMusic();  // Gameplay music
    }
  }
});
```

### 5. Pause Button in HUD
**Location**: `lib/main.dart` - HUD layer

A pause button appears in the top-right corner during gameplay:
- Uses `pause_button.png` asset
- Positioned next to the lives indicator
- Calls `playButtonSound()` then `pauseGame()` on tap
- 32x32 pixel size with padding

### 6. Game Pause Logic
**Location**: `lib/game/marshes_game.dart`

**Methods**:
- `pauseGame()` - Sets `isPlaying = false`, pauses music, triggers callback
- `resumeGameFromPause()` - Sets `isPlaying = true`, resumes music

**Callback System**:
- `onPauseTriggered` callback notifies UI to show pause menu
- UI manages pause menu visibility and user choices
- Resume/restart/menu actions call appropriate game methods

## Assets Used

### Button Assets
- `assets/images/pause_button.png` - Pause icon in HUD
- `assets/images/mute_button.png` - Muted state icon
- `assets/images/unmute_button.png` - Unmuted state icon

## State Flow

### Pause Flow
1. User taps pause button in HUD
2. Button sound plays (if not muted)
3. `pauseGame()` called → music pauses, game stops
4. `onPauseTriggered` callback fires
5. `_showPauseMenu` set to true → PauseMenu appears
6. User selects option:
   - **Resume**: Hide menu, call `resumeGameFromPause()`, music resumes
   - **Restart**: Hide menu, call `_startGame()`, new game begins
   - **Main Menu**: Hide menu, call `_goToMainMenu()`, return to main menu

### Mute Flow
1. User taps mute button (main menu or pause menu)
2. If currently unmuted: play button sound first
3. `AudioManager().toggleMute()` called
4. New mute state saved to SharedPreferences
5. **Stream broadcasts new state** to all listeners
6. **MarshesGame receives stream event**:
   - If muted: Immediately stops background music
   - If unmuted: Automatically starts appropriate music:
     - Main menu (isAutoPilot && !isPlaying): Plays random menu music
     - In gameplay (isPlaying): Plays gameplay music
7. **MuteButton widget rebuilds** via StreamBuilder with new icon
8. All subsequent audio checks mute state before playing

### Mute Persistence
1. App starts: `main()` calls `AudioManager().initialize()`
2. SharedPreferences loads saved mute state (defaults to false)
3. User toggles mute during session
4. New state immediately saved to SharedPreferences
5. Stream broadcasts to all listeners
6. App restarts: Mute state restored from SharedPreferences

## UI Layer Order
The UI stack layers are rendered in this order (bottom to top):
1. Game layer (GameWidget)
2. HUD layer (score, fish count, story count, lives, pause button)
3. Main menu layer (LiquidGlassMenu)
4. Mute button (main menu - below menu dialog)
5. Team page layer
6. Game over layer
7. Pause menu layer
8. Mute button (pause menu - below pause dialog)
9. Story dialog layer (topmost)

## Technical Notes

### Singleton Pattern
AudioManager uses a singleton pattern to ensure a single instance:
```dart
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();
  
  bool _isMuted = false;
  SharedPreferences? _prefs;
  
  bool get isMuted => _isMuted;
}
```

### State Management
- Game state: Managed by `MarshesGame.isPlaying` flag
- UI state: Managed by `_GameContainerState._showPauseMenu` flag
- Audio state: Managed by `AudioManager._isMuted` flag
- All state changes trigger appropriate UI updates via `setState()`

### Callback Architecture
- Game doesn't directly manipulate UI
- UI provides callbacks for game events
- Separation of concerns maintained
- Example: `onPauseTriggered: _showPauseDialog`

## Testing Checklist

### Pause Menu
- [x] Pause button appears in HUD during gameplay
- [x] Pause button hidden during menu/dialog/pause states
- [x] Tapping pause stops game and music
- [x] Pause menu appears with three options
- [x] Resume button continues game correctly
- [x] Restart button starts new game
- [x] Main Menu button returns to menu
- [x] Button sounds play on interaction

### Mute System
- [x] Mute button appears in main menu
- [x] Mute button appears in pause menu
- [x] Tapping toggles between mute/unmute icons
- [x] Muted state stops all new audio playback
- [x] Muted state persists across app restarts
- [x] Unmuting resumes audio playback
- [x] Button sound plays before muting (when unmuted)

### Integration
- [x] All audio methods check mute state
- [x] Pause works during all game states
- [x] Mute works in all UI contexts
- [x] No audio plays when muted
- [x] Music resumes correctly when unmuted

## Future Enhancements

Potential improvements for future versions:
1. Volume slider instead of binary mute/unmute
2. Separate music and SFX volume controls
3. Fade in/out transitions for audio
4. Keyboard shortcuts for pause (spacebar)
5. Visual feedback when audio is muted during gameplay
6. Audio settings page with advanced options

## Code References

Key files modified/created:
- `lib/ui/pause_menu.dart` - Pause menu component (NEW)
- `lib/ui/mute_button.dart` - Mute button component (NEW)
- `lib/data/audio_manager.dart` - Audio state manager (NEW)
- `lib/game/marshes_game.dart` - Pause methods and audio mute checks
- `lib/main.dart` - UI integration and callbacks
