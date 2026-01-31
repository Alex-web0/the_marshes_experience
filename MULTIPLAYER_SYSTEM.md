# Multiplayer System Documentation

## Overview
Implemented a real-time multiplayer lobby system using Firebase Realtime Database. Players can create games, join via codes, and see live player queues.

## Features Implemented

### 1. Multiplayer Button on Main Menu
- Added "MULTIPLAYER" button between "PLAY" and "OUR TEAM"
- Uses same glassmorphism design as other menu buttons
- Plays button sound on tap

### 2. Multiplayer Page
**Location**: `lib/ui/multiplayer_page.dart`

The multiplayer page mirrors the "Our Team" page design with:
- Same gradient background (green marshes theme)
- Scrollable content
- Pixelify Sans font throughout
- Glassmorphism containers for inputs and status displays

### 3. Page States

#### **Idle State** (Initial)
- Player name input field
- Game code input field (6 characters, uppercase)
- "JOIN GAME" button (blue)
- Divider with "OR" text
- "CREATE GAME" button (green)
- Error messages shown in red if validation fails

#### **Loading State**
- Circular progress indicator (cyan accent color)
- "Loading..." text
- Shown while waiting for Firebase operations

#### **Error State**
- Red error message displayed above buttons
- Possible errors:
  - "Please enter a player name"
  - "Please enter a game code"
  - "Game not found or full"
  - "Failed to create/join game"

#### **Waiting State** (Creator)
- Large game code display with copy button
- "Waiting for players..." text
- Player count: "X / 8 Players"
- Live player list with:
  - Creator marked with star icon
  - Current player highlighted in cyan
  - Other players shown in white
- "START GAME" button (appears when 2+ players joined)
- "LEAVE GAME" button (red)

#### **Queued State** (Joiner or Game Started)
- Status container showing:
  - "IN QUEUE" or "GAME STARTED!" based on status
  - Amber color scheme
- Player count: "X / 8 Players"
- Live player list
- "LEAVE GAME" button

### 4. Firebase Structure

```
games/
  {gameId}/
    code: "ABC123"              // 6-character code
    status: "waiting"            // GameStatus enum: "waiting" | "playing" | "finished"
    creatorId: "player_123..."   // Creator's player ID
    maxPlayers: 8                // Fixed at 8
    currentPlayers: 2            // Real-time count
    startedAt: timestamp         // When game started (optional)
    finishedAt: timestamp        // When game ended (optional)
    players/
      {playerId}/
        name: "Player1"
        isReady: false           // For future use
        score: 0
        lives: 3
        fishCount: 0
        storyCount: 0
        position:
          lane: 1
          distance: 120.5
        joinedAt: timestamp
```

### 5. Game Status Enum
**Location**: `lib/domain/game_status.dart`

Type-safe enum for game status:

```dart
enum GameStatus {
  waiting,   // Game created, waiting for players
  playing,   // Game in progress
  finished;  // Game completed

  String toJson() => name;  // Serialize to Firebase
  
  static GameStatus fromJson(String json) {
    return GameStatus.values.firstWhere(
      (status) => status.name == json,
      orElse: () => GameStatus.waiting,
    );
  }
}
```

**Benefits**:
- Type safety - no typos like "playng" or "waitting"
- IDE autocomplete support
- Compile-time error checking
- Easier refactoring
- Clear contract for valid states
**Location**: `lib/data/multiplayer_service.dart`

Singleton service managing all Firebase interactions:

**Methods**:
- `createGame(playerName)` - Creates new game, returns game object
- `findGameByCode(code)` - Searches for game by code
- `joinGame(gameCode, playerName)` - Joins existing game
- `watchGame(gameId)` - Returns stream of game updates
- `setPlayerReady(isReady)` - Toggle ready status
- `updatePlayerState(...)` - Update player's game state (score, position, etc.)
- `startGame()` - Changes game status to "playing" (creator only)
- `leaveGame()` - Removes player from game, cleans up if last player

**ID Generation**:
- Game codes: 6 alphanumeric chars (excludes ambiguous: I, O, 0, 1, L)
- Player IDs: `player_{timestamp}_{random4digits}`

### 6. Data Models
**Location**: `lib/domain/multiplayer_models.dart`

**MultiplayerGame**:
- Represents a game session
- Contains map of players
- Tracks status and timestamps

**MultiplayerPlayer**:
- Player information and stats
- Position (lane + distance)
- Ready status
- Joined timestamp

**PlayerPosition**:
- Lane (0-2)
- Distance (double)

## User Flows

### Creating a Game

1. User taps "MULTIPLAYER" on main menu
2. Multiplayer page opens in Idle state
3. User enters player name (auto-filled with Player{random})
4. User taps "CREATE GAME"
5. State changes to Loading
6. Firebase creates game with unique code
7. State changes to Waiting
8. Game code displayed (copyable)
9. Creator waits for players to join
10. When 2+ players: "START GAME" button appears
11. Creator taps "START GAME"
12. Game status changes to "playing"
13. All players see "GAME STARTED!" status

### Joining a Game

1. User taps "MULTIPLAYER" on main menu
2. User enters player name
3. User enters 6-character game code
4. User taps "JOIN GAME"
5. State changes to Loading
6. Service searches for game by code
7. If found and not full:
   - Player added to game
   - Player count incremented
   - State changes to Queued
8. If not found or full:
   - State changes to Error
   - Error message displayed
9. Player sees live queue with other players
10. When creator starts game:
    - Status changes to "GAME STARTED!"

### Leaving a Game

1. User taps "LEAVE GAME" button
2. Player removed from Firebase
3. Player count decremented
4. If last player: Game deleted
5. State resets to Idle
6. Can create or join new game

## Real-time Updates

### Stream Listening
- Each client watches their game via `watchGame()` stream
- Firebase automatically pushes updates when:
  - New player joins
  - Player leaves
  - Game status changes
  - Player stats update

### Player List Updates
- Player list rebuilds automatically when game updates
- Shows:
  - Join order (sorted by joinedAt)
  - Creator (star icon)
  - Current player (highlighted in cyan)
  - Ready status (green badge)

## Styling & Design

### Colors
- Background gradient: Green marshes theme (#1a3a2e → #0d1f1a)
- Primary accent: Cyan (#00E5FF)
- Secondary accent: Amber (#FFC107)
- Success: Green Accent (#69F0AE)
- Error: Red Accent (#FF5252)
- Creator: Amber (#FFC107)

### Typography
- Font: Pixelify Sans (consistent with entire app)
- Headers: 28px bold
- Buttons: 18px bold
- Body: 16px regular
- Game code: 36px bold, letter-spacing: 8

### Components
- Input fields: Black semi-transparent with white border
- Buttons: Colored background with black text
- Player cards: Gradient with border
- Status containers: Border with matching color theme

## Error Handling

### Validation Errors
- Empty player name → "Please enter a player name"
- Empty game code → "Please enter a game code"

### Network Errors
- Failed to create → "Failed to create game: {error}"
- Failed to join → "Failed to join game: {error}"

### Game State Errors
- Game not found → "Game not found or full"
- Game full (8/8) → joinGame returns null → Error state

## Future Enhancements (Not Yet Implemented)

### Phase 2: Actual Multiplayer Gameplay
1. Sync game state every 200ms during play
2. Show ghost boats of other players
3. Shared obstacle spawning (same positions for all)
4. Real-time leaderboard during game
5. End game when first player dies or time limit
6. Post-game results screen with rankings

### Phase 3: Additional Features
1. Ready system (all must be ready before start)
2. Kick player (creator only)
3. Private/public game toggle
4. Game settings (difficulty, time limit, etc.)
5. Friend list / recent players
6. Spectator mode for full games
7. Chat system
8. Achievements and rankings

## Technical Details

### Firebase Setup
- **Package**: `firebase_core`, `firebase_database`
- **Initialization**: `Firebase.initializeApp()` in main()
- **Database**: Realtime Database (not Firestore)
- **Rules**: Currently open (needs security rules for production)

### Performance Considerations
- Uses streams for efficient real-time updates
- Only watches active game (no global listeners)
- Cleans up streams on dispose
- Minimal data structure for fast reads/writes

### Memory Management
- Controllers disposed in dispose()
- Stream subscriptions canceled
- Game data cleared on leave

## Integration Points

### Main Menu
- `LiquidGlassMenu` widget updated with `onMultiplayer` callback
- Positioned between PLAY and OUR TEAM buttons

### Main App State
- Added `_showMultiplayerPage` boolean
- Added `_showMultiplayer()` and `_hideMultiplayer()` methods
- Multiplayer page added to UI stack at layer 3.45

### Audio
- Button sounds play on all interactions
- Integrated with existing `playButtonSound()` callback

## Testing Checklist

- [x] Create game generates unique code
- [x] Code is copyable to clipboard
- [x] Join game with valid code works
- [x] Join game with invalid code shows error
- [x] Join game when full shows error
- [x] Player list updates in real-time
- [x] Player count updates when joining/leaving
- [x] Creator can see START GAME button
- [x] Joiner cannot see START GAME button
- [x] Leave game removes player
- [x] Last player leaving deletes game
- [x] Game status changes to "playing" when started
- [x] Back button returns to main menu
- [x] Navigation maintains audio state
- [ ] Multiple devices can join same game (needs testing)
- [ ] Network errors handled gracefully

## Files Created/Modified

### New Files
1. `lib/domain/multiplayer_models.dart` - Data models
2. `lib/data/multiplayer_service.dart` - Firebase service
3. `lib/ui/multiplayer_page.dart` - UI page

### Modified Files
1. `lib/main.dart` - Added multiplayer state and navigation
2. `lib/ui/ui_layers.dart` - Added MULTIPLAYER button
3. `pubspec.yaml` - Added Firebase dependencies (already done by user)

## Security Considerations (TODO)

Current Firebase rules are likely open. Need to add:
```json
{
  "rules": {
    "games": {
      "$gameId": {
        ".read": true,
        ".write": "data.child('players').child(auth.uid).exists() || !data.exists()",
        "players": {
          "$playerId": {
            ".write": "$playerId === auth.uid"
          }
        }
      }
    }
  }
}
```

## Known Limitations

1. No authentication - uses anonymous player IDs
2. No game expiration - old games persist indefinitely
3. No spectator mode
4. No actual gameplay sync (Phase 2)
5. No chat or communication
6. No game history or stats tracking
7. Fixed max players (8) - not configurable

## Next Steps

To implement actual multiplayer gameplay:
1. Add game sync to MarshesGame
2. Create multiplayer game mode
3. Render ghost boats for other players
4. Sync positions every 200ms
5. Handle player disconnections
6. Implement win/loss conditions
7. Create results screen
