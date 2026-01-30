# Sound Effects Implementation

## Overview
Implemented comprehensive sound effects system for all game interactions including button clicks, item collection, bonus acquisition, and game over events.

## Sound Files Renamed

### Original → New Names
- `button-press-386165.mp3` → `button_press_1.mp3`
- `button-press-2-386176.mp3` → `button_press_2.mp3`
- (Created) → `button_press_3.mp3` (copy of button_press_1)
- `drowning-34415.mp3` → `drowning.mp3`
- `item-equip-6904.mp3` → `item_collect.mp3`
- `game-bonus-02-294436.mp3` → `bonus_1.mp3`
- `video-game-bonus-323603.mp3` → `bonus_2.mp3`
- `water-splosh-38143.mp3` → `water_splash.mp3` (available for future use)

## Sound Effects Implementation

### 1. Button Clicks
**Function:** `playButtonSound({int? specificButton})`
**Usage:** All button presses and dialog dismissals
**Behavior:**
- Randomly selects from 3 button press sounds if no specific button specified
- Can specify exact button sound (1-3) if needed
- Volume: 60%

**Triggers:**
- Main menu "PLAY" button
- Main menu "OUR TEAM" button  
- Main menu "VISIT WEBSITE" button
- Game over "PLAY AGAIN" button
- Game over "MAIN MENU" button
- Story dialog dismissal (tap to continue)

### 2. Drowning Sound (Game Over)
**Function:** `playDrowningSound()`
**Usage:** When player dies and game over screen appears
**Behavior:**
- Plays first 6 seconds of drowning sound naturally
- Stops when game restarts or returns to menu
- Volume: 70%

**Triggers:**
- Player health reaches 0 (game over)

### 3. Item Collection Sound
**Function:** `playItemCollectSound()`
**Usage:** When player collects fish
**Behavior:**
- Single item equip sound effect
- Volume: 50%

**Triggers:**
- FishCollectible collision with player

### 4. Bonus Sound (Story Box Collection)
**Function:** `playBonusSound()`
**Usage:** When player collects story boxes/chests
**Behavior:**
- Randomly selects between 2 bonus sound effects
- Plays before story dialog appears
- Volume: 60%

**Triggers:**
- StoryCollectible collision with player

## Implementation Details

### Audio Preloading
All sound effects are preloaded in `MarshesGame.onLoad()`:
```dart
await FlameAudio.audioCache.load('sounds/button_press_1.mp3');
await FlameAudio.audioCache.load('sounds/button_press_2.mp3');
await FlameAudio.audioCache.load('sounds/button_press_3.mp3');
await FlameAudio.audioCache.load('sounds/drowning.mp3');
await FlameAudio.audioCache.load('sounds/item_collect.mp3');
await FlameAudio.audioCache.load('sounds/bonus_1.mp3');
await FlameAudio.audioCache.load('sounds/bonus_2.mp3');
```

### Volume Levels
- **Button sounds**: 60% - Clear but not overpowering
- **Drowning**: 70% - Dramatic, emphasizes game over
- **Item collect**: 50% - Subtle, frequent sound
- **Bonus**: 60% - Celebratory but balanced

### Integration Points

#### MarshesGame (`lib/game/marshes_game.dart`)
- Added 4 sound effect methods
- Preloaded all sound files
- Called drowning sound in `gameOver()`

#### Components (`lib/game/components.dart`)
- `FishCollectible.collect()`: Plays item collect sound
- `StoryCollectible.collect()`: Plays random bonus sound

#### UI Layers (`lib/ui/ui_layers.dart`)
- `LiquidGlassMenu`: Added `onButtonSound` callback parameter
- `_GlassButton`: Calls button sound before executing onTap
- `HeritageStoryDialog`: Plays button sound on dismissal tap

#### Game Over Menu (`lib/ui/game_over_menu.dart`)
- `GameOverMenu`: Added `onButtonSound` callback parameter
- `_GlassButton`: Calls button sound before button action
- TextButton (Main Menu): Manually calls button sound

#### Main App (`lib/main.dart`)
- Passes `_game.playButtonSound` to all UI components
- Connects game sound system to Flutter UI layer

## Sound Effect Flow

### Button Press Flow
1. User taps button
2. `onButtonSound?.call()` executes
3. `playButtonSound()` randomly selects 1 of 3 sounds
4. Sound plays at 60% volume
5. Original button action executes

### Fish Collection Flow
1. Player collides with fish
2. `FishCollectible.collect()` called
3. `game.playItemCollectSound()` executes
4. Item collect sound plays at 50% volume
5. Fish count increments and sprite removes

### Story Box Collection Flow
1. Player collides with story box
2. `StoryCollectible.collect()` called
3. `game.playBonusSound()` executes (random bonus 1 or 2)
4. Bonus sound plays at 60% volume
5. Box animation plays (300ms)
6. Box removes and dialog appears

### Game Over Flow
1. Player health reaches 0
2. `gameOver()` called
3. Background music stops
4. `playDrowningSound()` executes
5. Drowning sound plays at 70% volume
6. Game over dialog appears
7. Sound continues playing (first 6 seconds naturally)

## Random Selection Implementation

### Button Sounds (3 variants)
```dart
final rand = Random();
final buttonNum = specificButton ?? (rand.nextInt(3) + 1);
FlameAudio.play('sounds/button_press_$buttonNum.mp3', volume: 0.6);
```

### Bonus Sounds (2 variants)
```dart
final rand = Random();
final bonusTrack = rand.nextBool() ? 'sounds/bonus_1.mp3' : 'sounds/bonus_2.mp3';
FlameAudio.play(bonusTrack, volume: 0.6);
```

## Future Enhancements
- Add water splash sound for obstacle collisions
- Sound effect volume controls in settings
- Different button sounds for different contexts (menu vs game)
- Combo sound effects for multiple fish collected rapidly
- Background ambient sound layers (water flowing, birds)
- Achievement unlock sounds

## Testing Checklist
- [ ] Button sounds play on all menu buttons
- [ ] Random button variation works (hear different sounds)
- [ ] Fish collection sound plays correctly
- [ ] Story box plays random bonus sound (test multiple collections)
- [ ] Drowning sound plays on game over
- [ ] Drowning sound is 6 seconds or less
- [ ] No sound overlap issues
- [ ] All sounds are at appropriate volumes
- [ ] Sounds don't interfere with music
- [ ] Story dialog dismissal plays button sound

## Files Modified
1. `/assets/audio/sounds/` - All sound files renamed
2. `lib/game/marshes_game.dart` - Sound effect methods and preloading
3. `lib/game/components.dart` - Collection sound triggers
4. `lib/ui/ui_layers.dart` - Button sound callbacks
5. `lib/ui/game_over_menu.dart` - Button sound callbacks
6. `lib/main.dart` - Sound callback wiring
