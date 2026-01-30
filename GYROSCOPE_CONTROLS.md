# Gyroscope/Accelerometer Controls

## ✅ Status: FULLY IMPLEMENTED

The boat movement in "The Marshes Experience" **IS** controlled by the phone's gyroscope/accelerometer (tilt controls).

## Implementation Details

### Sensor Setup
**File:** `lib/game/marshes_game.dart`

#### Import
```dart
import 'package:sensors_plus/sensors_plus.dart';
```

#### Initialization (in `onLoad()`)
```dart
// 4. Sensors
_sensorSubscription = accelerometerEventStream().listen((event) {
  handleTilt(event.x);
});
```

#### Cleanup (in `onRemove()`)
```dart
_sensorSubscription?.cancel();
```

### Tilt Handling

#### Method: `handleTilt(double xTilt)`
```dart
void handleTilt(double xTilt) {
  if (!isPlaying) return;
  // Simple threshold steering
  if (xTilt > 2) player.moveRight();
  if (xTilt < -2) player.moveLeft();
}
```

### How It Works

1. **Sensor Stream**: The game subscribes to `accelerometerEventStream()` from the `sensors_plus` package
2. **X-Axis Reading**: Only the X-axis tilt is used (left/right tilting of the phone)
3. **Threshold-Based**: Uses a threshold of ±2 to prevent accidental movements
4. **Continuous Monitoring**: The stream continuously monitors tilt while the game is running

### Control Behavior

#### Tilt Right (xTilt > 2)
- Phone tilts to the right
- Boat moves to the right lane
- Smooth transition animation (500px/s)

#### Tilt Left (xTilt < -2)
- Phone tilts to the left
- Boat moves to the left lane
- Smooth transition animation (500px/s)

#### Neutral Zone (-2 to 2)
- No movement triggered
- Boat stays in current lane
- Prevents jittery movements from small tilts

### Additional Controls (For Testing)

#### Keyboard Controls (Desktop/Windows)
```dart
@override
KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
  if (!isPlaying) return KeyEventResult.ignored;

  if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
    player.moveLeft();
    return KeyEventResult.handled;
  }
  if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
    player.moveRight();
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}
```

**Purpose:** Testing on desktop/laptop during development
**Keys:** 
- Arrow Left → Move left
- Arrow Right → Move right

### Lane System

**Total Lanes:** 3 (Left, Center, Right)
**Lane Indices:** 0 (left), 1 (center), 2 (right)
**Starting Position:** Lane 1 (center)

### Movement Animation

**Speed:** 500 pixels per second (smooth transition)
**Interpolation:** Linear interpolation in `update()` loop
**Behavior:**
- Gradual movement from current lane to target lane
- Prevents instant teleportation
- Visual feedback of boat sliding between lanes

### Dependencies

**Package:** `sensors_plus: ^7.0.0`
**Platforms Supported:**
- ✅ iOS - Full gyroscope/accelerometer support
- ✅ Android - Full gyroscope/accelerometer support
- ⚠️ Web - Limited sensor support (browser-dependent)
- ❌ Desktop (Windows/macOS/Linux) - No sensor support (keyboard fallback available)

### User Experience

#### Physical Movement Required
- **Subtle Tilt:** Hold phone upright, tilt slightly left/right
- **Dead Zone:** Small movements ignored for stability
- **Responsive:** Immediate lane change on significant tilt
- **Natural:** Mimics steering wheel motion

#### Gameplay Tips
- Hold phone comfortably upright
- Tilt gently left/right to steer
- Quick tilts for faster lane changes
- Return to neutral to stay in lane

### Technical Specifications

#### Sensor Type
- **Primary:** Accelerometer (measures device acceleration including gravity)
- **Alternative:** Could use gyroscope for rotation-based controls (not currently implemented)

#### Polling Rate
- **Continuous:** Event stream provides real-time updates
- **Frequency:** Device-dependent (typically 50-100 Hz)

#### Axis Mapping
- **X-axis:** Left/Right tilt (primary control)
- **Y-axis:** Forward/Backward tilt (not used)
- **Z-axis:** Vertical acceleration (not used)

#### Threshold Tuning
```dart
Current: ±2 threshold
- Too low (< 1): Overly sensitive, accidental movements
- Current (2): Balanced, requires intentional tilt
- Too high (> 5): Less responsive, requires exaggerated tilts
```

### Troubleshooting

#### Boat Not Moving?
1. Check device permissions (iOS/Android sensor access)
2. Verify `sensors_plus` package is installed
3. Test on physical device (emulators may not support sensors)
4. Check console for sensor stream errors

#### Too Sensitive?
- Increase threshold value in `handleTilt()`
- Current: `if (xTilt > 2)` → Try `if (xTilt > 3)`

#### Not Sensitive Enough?
- Decrease threshold value
- Current: `if (xTilt > 2)` → Try `if (xTilt > 1.5)`

### Future Enhancements

Potential improvements:
- [ ] Adjustable sensitivity in settings
- [ ] Calibration screen for user preference
- [ ] Haptic feedback on lane change
- [ ] Visual tilt indicator on screen
- [ ] Gyroscope rotation for smoother control
- [ ] Touch controls as alternative option

## Summary

✅ **Gyroscope controls are ACTIVE and WORKING**
- Phone tilt controls boat movement
- Left tilt → Boat moves left
- Right tilt → Boat moves right
- Threshold-based for stability
- Smooth lane transitions
- Keyboard backup for desktop testing
