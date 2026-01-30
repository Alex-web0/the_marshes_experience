# Stream-Based Mute System

## Overview
Implemented a reactive, stream-based mute system that automatically controls background music based on mute state changes.

## Key Features

### 1. Broadcast Stream Architecture
**Location**: `lib/data/audio_manager.dart`

```dart
// Stream controller for broadcasting mute state changes
final StreamController<bool> _muteStateController = 
    StreamController<bool>.broadcast();

Stream<bool> get muteStateStream => _muteStateController.stream;
```

**Benefits**:
- One-to-many communication pattern
- Multiple listeners can subscribe to mute state changes
- Instant propagation of state changes across the app
- Decoupled components - button doesn't need to know about game

### 2. Automatic Music Control
**Location**: `lib/game/marshes_game.dart`

The game listens to mute state changes and responds automatically:

```dart
_muteStateSubscription = AudioManager().muteStateStream.listen((isMuted) {
  if (isMuted) {
    // Stop music when muted
    FlameAudio.bgm.stop();
  } else {
    // Resume appropriate music when unmuted
    if (isAutoPilot && !isPlaying) {
      // On main menu - play menu music
      playMenuMusic();
    } else if (isPlaying) {
      // In game - play game music
      playBackgroundMusic();
    }
  }
});
```

**Smart Music Resumption**:
- Detects current game state (menu vs gameplay)
- Plays appropriate music track when unmuting
- **Main Menu**: Randomly plays bg_music_1.mp3 or bg_music_2.mp3
- **Gameplay**: Plays bg_music_game.mp3
- Immediate response - no delay or manual intervention needed

### 3. Reactive UI with StreamBuilder
**Location**: `lib/ui/mute_button.dart`

The mute button automatically updates without manual setState:

```dart
return StreamBuilder<bool>(
  stream: _audioManager.muteStateStream,
  initialData: _audioManager.isMuted,
  builder: (context, snapshot) {
    final isMuted = snapshot.data ?? _audioManager.isMuted;
    
    return GestureDetector(
      onTap: _toggleMute,
      child: Container(
        child: Image.asset(
          !isMuted
              ? 'assets/images/unmute_button.png'
              : 'assets/images/mute_button.png',
          width: 40,
          height: 40,
        ),
      ),
    );
  },
);
```

**Benefits**:
- No manual setState needed
- Widget automatically rebuilds when stream emits new value
- Correct icon always displayed
- Multiple mute buttons stay in sync if needed

## User Experience Flow

### Scenario 1: Unmuting on Main Menu
1. User is on main menu with audio muted
2. No background music is playing
3. User taps mute button
4. Button sound plays (before muting was toggled)
5. Stream broadcasts `isMuted = false`
6. Game receives stream event
7. Game detects: `isAutoPilot = true` && `!isPlaying`
8. **Menu music automatically starts playing**
9. Mute button icon updates to unmuted state

### Scenario 2: Unmuting During Gameplay
1. User is playing game with audio muted
2. No background music is playing
3. User pauses and taps mute button
4. Stream broadcasts `isMuted = false`
5. Game receives stream event
6. Game detects: `isPlaying = true`
7. **Gameplay music automatically starts playing**
8. User resumes game with music playing

### Scenario 3: Muting Immediately Stops Music
1. User is on main menu with music playing
2. User taps mute button
3. Button sound plays (while still unmuted)
4. Stream broadcasts `isMuted = true`
5. Game receives stream event
6. **Music immediately stops** via `FlameAudio.bgm.stop()`
7. Mute button icon updates to muted state

## Technical Implementation

### Stream Lifecycle Management
```dart
// In MarshesGame
@override
void onRemove() {
  _sensorSubscription?.cancel();
  _muteStateSubscription?.cancel();  // Clean up mute listener
  stopBackgroundMusic();
  super.onRemove();
}

// In AudioManager
void dispose() {
  _muteStateController.close();  // Close stream when app terminates
}
```

### State Persistence + Stream Broadcasting
```dart
Future<void> toggleMute() async {
  _isMuted = !_isMuted;
  await _prefs?.setBool('audio_muted', _isMuted);
  _muteStateController.add(_isMuted);  // Broadcast to listeners
}
```

**Dual responsibility**:
1. Saves state to SharedPreferences for persistence
2. Broadcasts state to stream for real-time updates

## Advantages Over Previous Implementation

### Before (Manual setState)
- Mute button had to manually call setState
- Game didn't know when mute state changed
- Had to manually start music when unmuting on menu
- Tight coupling between UI and audio logic
- No automatic music resumption

### After (Stream-Based)
- Mute button uses StreamBuilder - no manual setState
- Game automatically reacts to mute changes
- Music starts/stops automatically based on state + context
- Loose coupling via stream communication
- Smart music resumption based on game state
- Scalable - easy to add more listeners if needed

## Real-World Benefits

1. **Seamless User Experience**: Unmuting on main menu immediately starts ambient music without user doing anything else

2. **Context-Aware**: System knows whether to play menu music or gameplay music when unmuting

3. **Instant Response**: Music stops/starts immediately when mute button is tapped

4. **Persistent + Reactive**: Combines persistent storage with real-time reactivity

5. **Maintainable**: Adding new audio-reactive features is easy - just subscribe to the stream

## Future Extensions

This stream architecture makes it easy to add:
- Volume sliders that broadcast volume changes
- Separate music/SFX mute controls
- Audio visualizations that react to mute state
- Settings page that stays in sync with mute button
- Analytics tracking of mute usage patterns

## Testing Scenarios

✅ **Test 1**: Unmute on main menu → Menu music starts automatically
✅ **Test 2**: Unmute during gameplay → Game music starts automatically  
✅ **Test 3**: Mute during music playback → Music stops immediately
✅ **Test 4**: Multiple mute buttons stay in sync (if added)
✅ **Test 5**: Mute state persists across app restarts
✅ **Test 6**: Button icon updates automatically when state changes
✅ **Test 7**: Stream subscription cleaned up on game removal
