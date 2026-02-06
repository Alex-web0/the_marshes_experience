# Storyline System Documentation

## Overview

The storyline system provides an interactive narrative framework for "The Marshes Experience" game. It allows players to encounter characters, make choices, and experience branching story paths that affect game outcomes.

## Architecture

### Core Components

1. **Models** (`lib/domain/storyline_models.dart`)
   - `StoryCharacter`: Represents NPCs in the game
   - `StoryParagraph`: Individual narrative segments
   - `StoryChoice`: Player decision points
   - `StorylineElement`: Complete story arcs
   - `StoryProgress`: Player's journey tracking

2. **Repository** (`lib/data/storyline_repository.dart`)
   - Manages story content loading
   - Tracks player progress
   - Handles choice navigation
   - Provides story completion tracking

---

## Model Specifications

### 1. StoryCharacter

**Purpose**: Represents a character (NPC) that the player can interact with in the game.

**Parameters**:
- `id` (String, required): Unique identifier for the character
  - Example: `'old_fisherman'`, `'marsh_guardian'`, `'lost_child'`
  - Used to reference the character in paragraphs and story elements

- `name` (String, required): Display name shown in UI
  - Example: `'Old Fisherman'`, `'Marsh Guardian'`
  - Appears in dialogue boxes and character lists

- `personality` (String, required): Character trait description
  - Example: `'Wise and patient, speaks in riddles'`
  - Helps define dialogue tone and character behavior
  - Used by content creators as a writing guide

- `imagePath` (String, required): Path to character's avatar image
  - Example: `'assets/images/characters/old_fisherman.png'`
  - Displayed in dialogue boxes and character selection screens

**Usage**:
```dart
final fisherman = StoryCharacter(
  id: 'old_fisherman',
  name: 'Old Fisherman',
  personality: 'Wise and weathered, speaks slowly',
  imagePath: 'assets/images/characters/old_fisherman.png',
);
```

---

### 2. StoryChoice

**Purpose**: Represents a player decision point that branches the narrative.

**Parameters**:
- `id` (String, required): Unique identifier for this choice
  - Example: `'help'`, `'ignore'`, `'ask_about_marshes'`
  - Used to track which choice the player made

- `text` (String, required): Button text displayed to player
  - Example: `'Help the fisherman'`, `'Walk away'`
  - Should be clear and action-oriented

- `nextParagraphId` (String, required): Target paragraph ID
  - Example: `'fisherman_grateful'`, `'fisherman_disappointed'`
  - Creates the branching story structure
  - Must match an existing paragraph ID in the story

- `requirements` (Map<String, int>?, optional): Conditions to show this choice
  - Example: `{'fishCount': 3, 'storyCount': 1}`
  - If null or empty, choice is always available
  - Allows gating choices behind player progress
  - Keys: `'fishCount'`, `'storyCount'`, `'score'`, `'lives'`

**Usage**:
```dart
final choice = StoryChoice(
  id: 'help',
  text: 'Help the fisherman with his nets',
  nextParagraphId: 'fisherman_grateful',
  requirements: {'fishCount': 2}, // Only if player has 2+ fish
);
```

---

### 3. StoryParagraph

**Purpose**: A single segment of narrative text with optional choices.

**Parameters**:
- `id` (String, required): Unique identifier for this paragraph
  - Example: `'intro'`, `'crossroads'`, `'ending_good'`
  - Used for navigation and progress tracking

- `text` (String, required): The narrative content
  - Example: `'The old fisherman looks at you with knowing eyes...'`
  - Can be multi-line, include dialogue and descriptions
  - Should be engaging and fit the game's tone

- `characterId` (String?, optional): Speaking character's ID
  - Example: `'old_fisherman'`, `'marsh_guardian'`
  - If null, treated as narrator/environmental text
  - If set, character's avatar and name will appear

- `choices` (List<StoryChoice>, optional): Available player choices
  - Empty list means auto-continue or story end
  - 1 choice = linear continuation with player acknowledgment
  - 2+ choices = branching narrative
  - Each choice leads to a different paragraph

**Usage**:
```dart
final paragraph = StoryParagraph(
  id: 'greeting',
  text: '"Welcome, traveler," the old man says softly.',
  characterId: 'old_fisherman',
  choices: [
    StoryChoice(id: 'greet', text: 'Greet him back', nextParagraphId: 'friendly'),
    StoryChoice(id: 'silent', text: 'Stay silent', nextParagraphId: 'awkward'),
  ],
);
```

---

### 4. StorylineElement

**Purpose**: A complete, self-contained story arc or encounter.

**Parameters**:
- `id` (String, required): Unique identifier for this story
  - Example: `'old_fisherman_quest'`, `'marsh_guardian_test'`
  - Used to track completion and trigger stories

- `title` (String, required): Display name for the story
  - Example: `'The Old Fisherman's Tale'`, `'Secrets of the Marsh'`
  - Shown in story selection menus and completion screens

- `description` (String, required): Brief story summary
  - Example: `'Help an old fisherman navigate dangerous waters'`
  - Used in story selection menus and quest logs

- `paragraphs` (Map<String, StoryParagraph>, required): All story paragraphs
  - Key: paragraph ID, Value: paragraph object
  - Contains the entire story flow
  - Must include at least the starting paragraph

- `startParagraphId` (String, required): Entry point paragraph ID
  - Example: `'intro'`, `'opening_scene'`
  - Must exist in the paragraphs map
  - Where the story begins when triggered

- `characters` (Map<String, StoryCharacter>, required): Story characters
  - Key: character ID, Value: character object
  - All characters referenced in paragraphs must be here
  - Used to display character info during story

- `triggerRequirements` (Map<String, int>?, optional): Conditions to unlock
  - Example: `{'fishCount': 5, 'storyCount': 2}`
  - If null, story is always available when encountered
  - Gates story behind player progression
  - Keys: `'fishCount'`, `'storyCount'`, `'score'`, `'lives'`

- `rewards` (Map<String, int>?, optional): Rewards for completion
  - Example: `{'score': 100, 'fishCount': 2, 'storyCount': 1}`
  - Applied when story is completed
  - Can grant points, fish, or increment story counter
  - Keys: `'score'`, `'fishCount'`, `'storyCount'`

**Usage**:
```dart
final story = StorylineElement(
  id: 'old_fisherman_quest',
  title: 'The Old Fisherman',
  description: 'A chance meeting with a wise fisherman',
  paragraphs: {
    'intro': introParagraph,
    'greeting': greetingParagraph,
    'ending': endingParagraph,
  },
  startParagraphId: 'intro',
  characters: {
    'old_fisherman': fishermanCharacter,
  },
  triggerRequirements: {'fishCount': 1},
  rewards: {'score': 50, 'storyCount': 1},
);
```

---

### 5. StoryProgress

**Purpose**: Tracks a player's journey through a specific story.

**Parameters**:
- `storyElementId` (String, required): Which story this tracks
  - Example: `'old_fisherman_quest'`
  - Links progress to a specific storyline element

- `currentParagraphId` (String?, optional): Current location in story
  - Example: `'greeting'`, `'crossroads'`
  - If null, story hasn't been started
  - Used to resume stories in progress

- `visitedParagraphs` (List<String>, optional): History of visited paragraphs
  - Example: `['intro', 'greeting', 'crossroads']`
  - Shows the path the player took
  - Used for analytics and replay features

- `choicesMade` (Map<String, String>, optional): Decisions made
  - Key: paragraph ID, Value: choice ID
  - Example: `{'intro': 'help', 'crossroads': 'left_path'}`
  - Records which choice was selected at each decision point
  - Enables story replay with different choices

- `isCompleted` (bool, optional): Completion status
  - Default: `false`
  - Set to `true` when story reaches an end paragraph
  - Used to track which stories player has finished

- `startedAt` (int?, optional): Start timestamp (milliseconds since epoch)
  - Example: `1704067200000`
  - Records when player began this story
  - Used for analytics and time-based features

- `completedAt` (int?, optional): Completion timestamp
  - Example: `1704070800000`
  - Records when player finished the story
  - Used to calculate completion time

**Usage**:
```dart
final progress = StoryProgress(
  storyElementId: 'old_fisherman_quest',
  currentParagraphId: 'greeting',
  visitedParagraphs: ['intro', 'greeting'],
  choicesMade: {'intro': 'approach'},
  isCompleted: false,
  startedAt: DateTime.now().millisecondsSinceEpoch,
);
```

---

## Story Flow Example

```
StorylineElement: "Old Fisherman Quest"
├── Character: Old Fisherman
│   ├── Name: "Old Fisherman"
│   ├── Personality: "Wise and weathered"
│   └── Image: "old_fisherman.png"
│
├── Paragraph: "intro"
│   ├── Text: "You see an old fisherman..."
│   ├── Character: old_fisherman
│   └── Choices:
│       ├── "approach" → "greeting"
│       └── "ignore" → "ignored"
│
├── Paragraph: "greeting"
│   ├── Text: "Ah, a traveler!"
│   ├── Character: old_fisherman
│   └── Choices:
│       ├── "ask_advice" → "advice"
│       └── "ask_story" → "marsh_lore"
│
├── Paragraph: "advice"
│   ├── Text: "The best spots are..."
│   ├── Character: old_fisherman
│   └── Choices: [] (ends story)
│
├── Paragraph: "marsh_lore"
│   ├── Text: "These marshes hold secrets..."
│   ├── Character: old_fisherman
│   └── Choices: [] (ends story)
│
└── Paragraph: "ignored"
    ├── Text: "You continue on your way..."
    ├── Character: null (narrator)
    └── Choices: [] (ends story)
```

**Possible Player Paths**:
1. intro → greeting → advice (learns fishing tips)
2. intro → greeting → marsh_lore (learns marsh secrets)
3. intro → ignored (misses opportunity)

---

## Integration with Game

### Repository Usage

```dart
// Initialize repository
final repo = StorylineRepository();
repo.initialize();

// Get available stories based on player stats
final availableStories = repo.getAvailableStories(
  fishCount: playerFishCount,
  storyCount: playerStoryCount,
);

// Start a story
final progress = repo.startStory('old_fisherman_quest');
final story = repo.getStorylineElement('old_fisherman_quest');
final currentParagraph = story?.getParagraph(progress.currentParagraphId!);

// Player makes a choice
final choice = currentParagraph?.choices.first;
repo.makeChoice(
  'old_fisherman_quest',
  currentParagraph!.id,
  choice!.id,
  choice.nextParagraphId,
);

// Complete the story
repo.completeStory('old_fisherman_quest');
final rewards = story?.rewards; // Apply rewards to player
```

### UI Integration Points

1. **Story Trigger**: During gameplay, check if player encounters a story trigger
2. **Story Dialog**: Display paragraph text with character avatar
3. **Choice Selection**: Show available choices as buttons
4. **Progress Tracking**: Update UI based on story progress
5. **Rewards**: Apply story rewards to player stats

---

## Future Enhancements

1. **Dynamic Content Loading**: Load stories from JSON files or Firebase
2. **Conditional Text**: Paragraph text that changes based on player stats
3. **Timed Choices**: Choices that disappear after a time limit
4. **Story Dependencies**: Stories that unlock other stories
5. **Multiplayer Stories**: Shared story experiences with choices affecting all players
6. **Achievements**: Special rewards for completing story paths
7. **Story Replay**: Ability to replay completed stories with different choices
8. **Voice Acting**: Audio files for character dialogue
9. **Animations**: Character expressions and environmental effects
10. **Localization**: Multi-language support for stories

---

## Data Structure Examples

### JSON Export Format (for Firebase or file storage)

```json
{
  "id": "old_fisherman_quest",
  "title": "The Old Fisherman",
  "description": "A chance meeting with a wise fisherman",
  "startParagraphId": "intro",
  "triggerRequirements": {
    "fishCount": 1
  },
  "rewards": {
    "score": 50,
    "storyCount": 1
  },
  "characters": {
    "old_fisherman": {
      "name": "Old Fisherman",
      "personality": "Wise and weathered",
      "imagePath": "assets/images/characters/old_fisherman.png"
    }
  },
  "paragraphs": {
    "intro": {
      "text": "You see an old fisherman by the river...",
      "characterId": "old_fisherman",
      "choices": [
        {
          "id": "approach",
          "text": "Approach the fisherman",
          "nextParagraphId": "greeting"
        },
        {
          "id": "ignore",
          "text": "Keep moving",
          "nextParagraphId": "ignored"
        }
      ]
    }
  }
}
```

### Player Progress Export

```json
{
  "old_fisherman_quest": {
    "currentParagraphId": "greeting",
    "visitedParagraphs": ["intro", "greeting"],
    "choicesMade": {
      "intro": "approach"
    },
    "isCompleted": false,
    "startedAt": 1704067200000
  }
}
```

---

## Best Practices

### Story Design

1. **Clear Choices**: Make choice text action-oriented and distinct
2. **Meaningful Consequences**: Choices should lead to noticeably different outcomes
3. **Character Voice**: Keep character dialogue consistent with personality
4. **Pacing**: Balance narrative text length with player engagement
5. **Dead Ends**: Ensure all paths lead to satisfying conclusions

### Technical Implementation

1. **ID Naming**: Use descriptive, consistent naming for IDs
2. **Paragraph Linking**: Verify all nextParagraphId references exist
3. **Character References**: Ensure all characterId values match defined characters
4. **Requirements Balance**: Don't gate stories too aggressively
5. **Rewards Balance**: Ensure rewards are proportional to story length/difficulty

### Performance

1. **Lazy Loading**: Load story content as needed, not all at once
2. **Progress Caching**: Cache player progress in memory during gameplay
3. **Asset Preloading**: Preload character images before displaying story
4. **Memory Management**: Unload completed story content from memory

---

## Testing Checklist

- [ ] All paragraph IDs in choices exist in the story
- [ ] All character IDs in paragraphs exist in characters map
- [ ] Start paragraph ID exists in paragraphs map
- [ ] All story paths lead to end paragraphs (no infinite loops)
- [ ] Requirement values are balanced and achievable
- [ ] Reward values are appropriate for story complexity
- [ ] Character images exist at specified paths
- [ ] Story can be completed via all possible paths
- [ ] Progress tracking updates correctly
- [ ] Choices with requirements show/hide correctly
- [ ] Completed stories mark as completed
- [ ] Rewards apply correctly on completion

---

## Summary

The storyline system provides a flexible, data-driven approach to interactive narratives. By separating story content (models) from story management (repository), the system allows for easy creation of new stories without code changes. The branching structure supports complex narratives while maintaining clear data relationships and progress tracking.
