# Menu Music Implementation

## Overview
Added ambient background music for the main menu that plays automatically when the app starts and when returning to the menu from the game.

## Features

### Random Track Selection
- The menu randomly selects between two music tracks: `bg_music_1.mp3` and `bg_music_2.mp3`
- Each time the menu is shown, there's a 50/50 chance of either track playing
- Provides variety and keeps the menu experience fresh

### Ambient Volume Level
- Menu music plays at **30% volume** (`volume: 0.3`)
- Lower than gameplay music (50% volume) to create a calming, ambient atmosphere
- Still audible but not overwhelming

### Music Behavior

#### On App Launch
- Menu music starts automatically 500ms after the app loads
- Only plays if the menu is actually showing (prevents music during loading)

#### During Gameplay
- Menu music **stops** when starting a new game
- Gameplay music (`bg_music_game.mp3`) takes over at 50% volume

#### Returning to Menu
- Menu music **restarts** when returning from game over screen
- Randomly selects a new track each time

#### On Game Over
- Gameplay music stops
- Menu music waits to play until user explicitly returns to main menu

## Implementation Details

### Audio Files
Located in `assets/audio/music/`:
- `bg_music_1.mp3` - Menu ambient track #1
- `bg_music_2.mp3` - Menu ambient track #2
- `bg_music_game.mp3` - Gameplay music (unchanged)

### Code Changes

#### MarshesGame (`lib/game/marshes_game.dart`)
```dart
void playMenuMusic() {
  // Randomly choose between bg_music_1.mp3 and bg_music_2.mp3
  final rand = Random();
  final musicTrack = rand.nextBool() ? 'music/bg_music_1.mp3' : 'music/bg_music_2.mp3';
  FlameAudio.bgm.play(musicTrack, volume: 0.3); // Lower volume for ambient menu music
}
```

#### Main.dart (`lib/main.dart`)
- `initState()`: Schedules menu music to play 500ms after app loads
- `_startGame()`: Stops menu music before starting gameplay
- `_goToMainMenu()`: Restarts menu music when returning to menu

### Audio Preloading
All three tracks are preloaded in `MarshesGame.onLoad()`:
```dart
await FlameAudio.audioCache.load('music/bg_music_game.mp3');
await FlameAudio.audioCache.load('music/bg_music_1.mp3');
await FlameAudio.audioCache.load('music/bg_music_2.mp3');
```

## User Experience

### Volume Levels
- **Menu Music**: 30% - Subtle, ambient, non-intrusive
- **Gameplay Music**: 50% - More prominent, energetic

### Transitions
- Menu → Game: Clean stop, no overlap
- Game → Menu: Fresh start with random track selection
- App Launch → Menu: Smooth fade-in after brief delay

## Testing Checklist
- [ ] Menu music plays when app first opens
- [ ] Music is audible but not loud (ambient level)
- [ ] Random track selection works (test multiple launches)
- [ ] Music stops when starting game
- [ ] Gameplay music plays during game
- [ ] Menu music resumes when returning from game over
- [ ] No music overlap or conflicts
- [ ] Audio files load without errors

## Future Enhancements
- Cross-fade transitions between menu and gameplay music
- User volume controls in settings
- Additional menu music tracks for more variety
- Music preference persistence (remember last played track)
