# Storyline System - Complete Example

## Real Story Data Flow Example

This document shows exactly how a complete story flows through the system with real data.

---

## 📖 Story: "The Lost Child"

### Story Setup

```dart
// STEP 1: Create the character
final lostChild = StoryCharacter(
  id: 'lost_child',
  name: 'Maya',
  personality: 'Scared but brave, 8 years old',
  imagePath: 'assets/images/characters/lost_child.png',
);

// STEP 2: Create all paragraphs
final intro = StoryParagraph(
  id: 'intro',
  text: 'You hear soft crying from behind the reeds. A small child sits alone, clutching a worn teddy bear.',
  characterId: null, // Narrator
  choices: [
    StoryChoice(
      id: 'help',
      text: 'Approach and help',
      nextParagraphId: 'greeting',
    ),
    StoryChoice(
      id: 'leave',
      text: 'Keep rowing',
      nextParagraphId: 'guilty',
    ),
  ],
);

final greeting = StoryParagraph(
  id: 'greeting',
  text: 'The child looks up with tear-filled eyes. "I\'m lost... I can\'t find my way home. Can you help me?"',
  characterId: 'lost_child',
  choices: [
    StoryChoice(
      id: 'help_navigate',
      text: 'Offer to guide her home',
      nextParagraphId: 'helping',
      requirements: {'fishCount': 2}, // Need to have caught fish
    ),
    StoryChoice(
      id: 'comfort_only',
      text: 'Comfort her but stay',
      nextParagraphId: 'comforting',
    ),
  ],
);

final helping = StoryParagraph(
  id: 'helping',
  text: '"Really? Thank you so much!" She climbs into your boat. Using your knowledge of the marshes, you safely guide her back to the village. Her mother runs out, crying with relief.',
  characterId: 'lost_child',
  choices: [], // Story ends - good ending
);

final comforting = StoryParagraph(
  id: 'comforting',
  text: 'You sit with her for a while, sharing your fish. She stops crying and smiles weakly. "Thank you for staying with me." Eventually, her parents find her.',
  characterId: 'lost_child',
  choices: [], // Story ends - okay ending
);

final guilty = StoryParagraph(
  id: 'guilty',
  text: 'You row away, but the sound of her crying haunts you for the rest of the day.',
  characterId: null, // Narrator
  choices: [], // Story ends - bad ending
);

// STEP 3: Assemble the complete story
final lostChildStory = StorylineElement(
  id: 'lost_child_quest',
  title: 'The Lost Child',
  description: 'A child needs help finding her way home',
  paragraphs: {
    'intro': intro,
    'greeting': greeting,
    'helping': helping,
    'comforting': comforting,
    'guilty': guilty,
  },
  startParagraphId: 'intro',
  characters: {
    'lost_child': lostChild,
  },
  triggerRequirements: null, // Always available
  rewards: {
    'score': 150,      // High reward for helping
    'storyCount': 1,
  },
);
```

---

## 🎮 Player Experience: Path 1 (Hero Path)

### State 1: Story Starts
```dart
// Player stats
PlayerStats {
  fishCount: 3,
  storyCount: 1,
  score: 100,
}

// Repository initializes progress
progress = StoryProgress(
  storyElementId: 'lost_child_quest',
  currentParagraphId: 'intro',
  visitedParagraphs: [],
  choicesMade: {},
  isCompleted: false,
  startedAt: 1704067200000,
);
```

### UI Display 1: Introduction
```
┌──────────────────────────────────┐
│    The Lost Child           [×]  │
├──────────────────────────────────┤
│                                  │
│  You hear soft crying from       │
│  behind the reeds. A small       │
│  child sits alone, clutching     │
│  a worn teddy bear.              │
│                                  │
│  ┌────────────────────────────┐ │
│  │  Approach and help         │ │
│  └────────────────────────────┘ │
│  ┌────────────────────────────┐ │
│  │  Keep rowing               │ │
│  └────────────────────────────┘ │
└──────────────────────────────────┘
```

### State 2: Player Chooses "Approach and help"
```dart
// Update progress
progress = progress.copyWith(
  currentParagraphId: 'greeting',
  visitedParagraphs: ['intro', 'greeting'],
  choicesMade: {'intro': 'help'},
);

// Progress now:
StoryProgress {
  storyElementId: 'lost_child_quest',
  currentParagraphId: 'greeting',
  visitedParagraphs: ['intro', 'greeting'],
  choicesMade: {'intro': 'help'},
  isCompleted: false,
  startedAt: 1704067200000,
}
```

### UI Display 2: Child Speaks
```
┌──────────────────────────────────┐
│    The Lost Child           [×]  │
├──────────────────────────────────┤
│         ╭─────────╮              │
│         │  (◕‿◕)  │              │
│         ╰─────────╯              │
│           Maya                   │
│                                  │
│  "I'm lost... I can't find       │
│  my way home. Can you help me?"  │
│                                  │
│  ┌────────────────────────────┐ │
│  │  Offer to guide her home   │ │  ← Enabled (has 2+ fish)
│  └────────────────────────────┘ │
│  ┌────────────────────────────┐ │
│  │  Comfort her but stay      │ │
│  └────────────────────────────┘ │
└──────────────────────────────────┘
```

### State 3: Player Chooses "Offer to guide her home"
```dart
// Check requirements
choice.requirements = {'fishCount': 2}
playerStats.fishCount = 3  // ✅ Meets requirement!

// Update progress
progress = progress.copyWith(
  currentParagraphId: 'helping',
  visitedParagraphs: ['intro', 'greeting', 'helping'],
  choicesMade: {
    'intro': 'help',
    'greeting': 'help_navigate',
  },
);
```

### UI Display 3: Resolution
```
┌──────────────────────────────────┐
│    The Lost Child           [×]  │
├──────────────────────────────────┤
│         ╭─────────╮              │
│         │  (◕‿◕)  │              │
│         ╰─────────╯              │
│           Maya                   │
│                                  │
│  "Really? Thank you so much!"    │
│  She climbs into your boat.      │
│  Using your knowledge of the     │
│  marshes, you safely guide       │
│  her back to the village. Her    │
│  mother runs out, crying with    │
│  relief.                         │
│                                  │
│  ┌────────────────────────────┐ │
│  │        Continue            │ │
│  └────────────────────────────┘ │
└──────────────────────────────────┘
```

### State 4: Story Completes
```dart
// No more paragraphs - complete story
progress = progress.copyWith(
  isCompleted: true,
  completedAt: 1704070800000,
);

// Final progress:
StoryProgress {
  storyElementId: 'lost_child_quest',
  currentParagraphId: 'helping',
  visitedParagraphs: ['intro', 'greeting', 'helping'],
  choicesMade: {
    'intro': 'help',
    'greeting': 'help_navigate',
  },
  isCompleted: true,
  startedAt: 1704067200000,
  completedAt: 1704070800000,
}

// Apply rewards
PlayerStats {
  fishCount: 3,          // Unchanged
  storyCount: 2,         // +1
  score: 250,            // +150
}
```

---

## 🎮 Player Experience: Path 2 (Moderate Path)

Same start, but different choices:

### Choices Made
1. intro → "Approach and help" → greeting
2. greeting → "Comfort her but stay" → comforting

### Final Progress
```dart
StoryProgress {
  storyElementId: 'lost_child_quest',
  currentParagraphId: 'comforting',
  visitedParagraphs: ['intro', 'greeting', 'comforting'],
  choicesMade: {
    'intro': 'help',
    'greeting': 'comfort_only',
  },
  isCompleted: true,
  startedAt: 1704067200000,
  completedAt: 1704070500000,
}
```

### Rewards (Same)
```dart
PlayerStats {
  storyCount: 2,    // +1
  score: 250,       // +150
}
```

---

## 🎮 Player Experience: Path 3 (Dark Path)

Same start, but immediate rejection:

### Choices Made
1. intro → "Keep rowing" → guilty

### Final Progress
```dart
StoryProgress {
  storyElementId: 'lost_child_quest',
  currentParagraphId: 'guilty',
  visitedParagraphs: ['intro', 'guilty'],
  choicesMade: {
    'intro': 'leave',
  },
  isCompleted: true,
  startedAt: 1704067200000,
  completedAt: 1704067300000, // Completed quickly
}
```

### Rewards (Same - or could be reduced)
```dart
PlayerStats {
  storyCount: 2,    // +1 (encountered story)
  score: 250,       // +150 (or less if you want to penalize)
}
```

---

## 🔄 Repository State Over Time

### Initial State
```dart
StorylineRepository {
  _storylineElements: {
    'lost_child_quest': lostChildStory,
    'old_fisherman_quest': oldFishermanStory,
  },
  _playerProgress: {},
}
```

### After Starting Story
```dart
StorylineRepository {
  _storylineElements: { ... },
  _playerProgress: {
    'lost_child_quest': StoryProgress {
      currentParagraphId: 'intro',
      isCompleted: false,
      ...
    },
  },
}
```

### After Making First Choice
```dart
StorylineRepository {
  _storylineElements: { ... },
  _playerProgress: {
    'lost_child_quest': StoryProgress {
      currentParagraphId: 'greeting',
      visitedParagraphs: ['intro', 'greeting'],
      choicesMade: {'intro': 'help'},
      isCompleted: false,
      ...
    },
  },
}
```

### After Completion
```dart
StorylineRepository {
  _storylineElements: { ... },
  _playerProgress: {
    'lost_child_quest': StoryProgress {
      currentParagraphId: 'helping',
      visitedParagraphs: ['intro', 'greeting', 'helping'],
      choicesMade: {
        'intro': 'help',
        'greeting': 'help_navigate',
      },
      isCompleted: true,
      completedAt: 1704070800000,
      ...
    },
  },
}
```

---

## 💾 Firebase/JSON Export

### Story Data (Static - could be in assets or Firebase)
```json
{
  "lost_child_quest": {
    "title": "The Lost Child",
    "description": "A child needs help finding her way home",
    "startParagraphId": "intro",
    "triggerRequirements": null,
    "rewards": {
      "score": 150,
      "storyCount": 1
    },
    "characters": {
      "lost_child": {
        "name": "Maya",
        "personality": "Scared but brave, 8 years old",
        "imagePath": "assets/images/characters/lost_child.png"
      }
    },
    "paragraphs": {
      "intro": {
        "text": "You hear soft crying...",
        "characterId": null,
        "choices": [
          {
            "id": "help",
            "text": "Approach and help",
            "nextParagraphId": "greeting"
          },
          {
            "id": "leave",
            "text": "Keep rowing",
            "nextParagraphId": "guilty"
          }
        ]
      }
      // ... more paragraphs
    }
  }
}
```

### Player Progress (Dynamic - saved/synced)
```json
{
  "lost_child_quest": {
    "currentParagraphId": "helping",
    "visitedParagraphs": ["intro", "greeting", "helping"],
    "choicesMade": {
      "intro": "help",
      "greeting": "help_navigate"
    },
    "isCompleted": true,
    "startedAt": 1704067200000,
    "completedAt": 1704070800000
  },
  "old_fisherman_quest": {
    "currentParagraphId": "advice",
    "visitedParagraphs": ["intro", "greeting", "advice"],
    "choicesMade": {
      "intro": "approach",
      "greeting": "ask_advice"
    },
    "isCompleted": true,
    "startedAt": 1704065000000,
    "completedAt": 1704065500000
  }
}
```

---

## 🎯 All Three Endings Comparison

| Path | Choices | Paragraphs Visited | Moral | Time |
|------|---------|-------------------|-------|------|
| **Hero** | help → help_navigate | intro → greeting → helping | Helped child home | 3-4 min |
| **Kind** | help → comfort_only | intro → greeting → comforting | Comforted until found | 3 min |
| **Dark** | leave | intro → guilty | Ignored child | 30 sec |

All paths give same rewards (or could be adjusted), but offer different narrative experiences and player satisfaction.

---

## 🎨 Visual Story Graph

```
                    START
                      │
                   [intro]
                   Narrator
              "You hear crying..."
                      │
        ┌─────────────┴─────────────┐
        │                           │
    "help"                      "leave"
        │                           │
        ↓                           ↓
   [greeting]                   [guilty]
      Maya                      Narrator
  "I'm lost..."           "Sound haunts you"
        │                           │
        ├──────────┐                END
        │          │              (Quick)
   "help_      "comfort_
    navigate"    only"
        │          │
        ↓          ↓
   [helping]  [comforting]
      Maya         Maya
   "Thank     "Thank you
    you!"      for staying"
        │          │
        END        END
     (Hero)     (Kind)
```

---

This example shows the complete data flow from story creation through player interaction to completion and persistence! 🎮
