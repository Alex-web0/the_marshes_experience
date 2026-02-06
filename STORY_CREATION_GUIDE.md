# Quick Story Creation Guide

## Step-by-Step: Creating a New Story

### 1. Define Your Characters

```dart
// Create character(s) that will appear in your story
final character = StoryCharacter(
  id: 'character_id',           // Unique ID (use snake_case)
  name: 'Character Name',       // Display name
  personality: 'Personality description',
  imagePath: 'assets/images/characters/character_name.png',
);
```

### 2. Write Your Paragraphs

```dart
// Start with the opening paragraph
final introParagraph = StoryParagraph(
  id: 'intro',                  // Unique ID within this story
  text: 'Your narrative text here...',
  characterId: 'character_id',  // null if narrator
  choices: [
    // Add choices here (see step 3)
  ],
);

// Create additional paragraphs for each story branch
final paragraph2 = StoryParagraph(
  id: 'paragraph_2',
  text: 'What happens next...',
  characterId: 'character_id',
  choices: [
    // More choices
  ],
);

// Create ending paragraphs (no choices = story ends)
final ending = StoryParagraph(
  id: 'ending',
  text: 'The conclusion...',
  characterId: null,
  choices: [], // Empty = story ends here
);
```

### 3. Add Player Choices

```dart
// Simple choice (always available)
StoryChoice(
  id: 'choice_id',              // Unique within this paragraph
  text: 'Button text',          // What player sees
  nextParagraphId: 'next_para', // Where it leads
),

// Gated choice (requires player to have certain stats)
StoryChoice(
  id: 'special_choice',
  text: 'Special option',
  nextParagraphId: 'special_path',
  requirements: {
    'fishCount': 5,             // Need 5+ fish
    'storyCount': 2,            // Need 2+ completed stories
  },
),
```

### 4. Assemble the Story

```dart
final myStory = StorylineElement(
  id: 'my_story_id',
  title: 'Story Title',
  description: 'Brief description for menus',
  
  // Map of all paragraphs
  paragraphs: {
    'intro': introParagraph,
    'paragraph_2': paragraph2,
    'ending': ending,
  },
  
  // Where story begins
  startParagraphId: 'intro',
  
  // Map of all characters
  characters: {
    'character_id': character,
  },
  
  // Optional: when story becomes available
  triggerRequirements: {
    'fishCount': 3,
  },
  
  // Optional: rewards for completion
  rewards: {
    'score': 100,
    'storyCount': 1,
  },
);
```

### 5. Add to Repository

Open `lib/data/storyline_repository.dart` and add your story to `_loadDefaultStories()`:

```dart
void _loadDefaultStories() {
  // Existing stories...
  
  // Add your new story
  final myStory = _createMyStory();
  _storylineElements[myStory.id] = myStory;
}

// Add your story creation method
StorylineElement _createMyStory() {
  // Your character, paragraph, and story code here
  return myStory;
}
```

---

## Story Structure Patterns

### Linear Story (No Choices)

```
intro (1 choice: "Continue") 
  → middle (1 choice: "Continue")
    → ending (no choices)
```

### Simple Branch (2 Paths)

```
intro
  ├─ choice A → path_a → ending_a
  └─ choice B → path_b → ending_b
```

### Complex Branch (Rejoining Paths)

```
intro
  ├─ choice A → path_a ┐
  └─ choice B → path_b ┴→ middle → ending
```

### Deeply Nested Branches

```
intro
  ├─ choice A → path_a
  │              ├─ choice C → ending_c
  │              └─ choice D → ending_d
  └─ choice B → path_b
                 ├─ choice E → ending_e
                 └─ choice F → ending_f
```

---

## Example: Complete Simple Story

```dart
StorylineElement _createSimpleQuest() {
  // Character
  final merchant = StoryCharacter(
    id: 'merchant',
    name: 'River Merchant',
    personality: 'Friendly but shrewd trader',
    imagePath: 'assets/images/characters/merchant.png',
  );

  // Paragraphs
  final intro = StoryParagraph(
    id: 'intro',
    text: 'A merchant waves at you from his boat. "Care to trade?"',
    characterId: 'merchant',
    choices: [
      StoryChoice(
        id: 'trade',
        text: 'See what he has',
        nextParagraphId: 'shop',
      ),
      StoryChoice(
        id: 'decline',
        text: 'Politely decline',
        nextParagraphId: 'goodbye',
      ),
    ],
  );

  final shop = StoryParagraph(
    id: 'shop',
    text: 'The merchant shows you his wares. "Best fish in the marshes!"',
    characterId: 'merchant',
    choices: [
      StoryChoice(
        id: 'buy',
        text: 'Trade for fish',
        nextParagraphId: 'bought',
        requirements: {'fishCount': 1}, // Must have fish to trade
      ),
      StoryChoice(
        id: 'leave',
        text: 'Just browsing',
        nextParagraphId: 'goodbye',
      ),
    ],
  );

  final bought = StoryParagraph(
    id: 'bought',
    text: 'The merchant smiles. "A fair trade! Come back anytime!"',
    characterId: 'merchant',
    choices: [], // Story ends
  );

  final goodbye = StoryParagraph(
    id: 'goodbye',
    text: 'The merchant waves as you continue your journey.',
    characterId: 'merchant',
    choices: [], // Story ends
  );

  // Assemble story
  return StorylineElement(
    id: 'merchant_trade',
    title: 'The River Merchant',
    description: 'A chance to trade with a wandering merchant',
    paragraphs: {
      'intro': intro,
      'shop': shop,
      'bought': bought,
      'goodbye': goodbye,
    },
    startParagraphId: 'intro',
    characters: {
      'merchant': merchant,
    },
    rewards: {
      'score': 25,
      'fishCount': 1,
    },
  );
}
```

---

## Checklist for New Stories

### Planning Phase
- [ ] Story concept and theme defined
- [ ] Main characters designed (name, personality, image)
- [ ] Story branches mapped out
- [ ] Trigger requirements decided
- [ ] Rewards balanced

### Creation Phase
- [ ] All characters created with images
- [ ] All paragraphs written
- [ ] All choices added to paragraphs
- [ ] nextParagraphId references verified
- [ ] characterId references verified
- [ ] Requirements and rewards set

### Testing Phase
- [ ] All story paths tested
- [ ] No broken paragraph references
- [ ] No infinite loops
- [ ] Choices show/hide correctly based on requirements
- [ ] Rewards apply correctly
- [ ] Character images display
- [ ] Text reads well and fits theme
- [ ] Story completes properly

### Integration Phase
- [ ] Story added to repository
- [ ] Story accessible in game
- [ ] Progress tracking works
- [ ] UI displays correctly
- [ ] Performance acceptable

---

## Common Pitfalls

### ❌ Broken Reference
```dart
choices: [
  StoryChoice(
    id: 'go_forward',
    text: 'Move ahead',
    nextParagraphId: 'next', // This paragraph doesn't exist!
  ),
],
```
**Fix**: Make sure 'next' exists in the paragraphs map.

### ❌ Infinite Loop
```dart
final para1 = StoryParagraph(
  id: 'para1',
  text: 'You are here.',
  choices: [
    StoryChoice(id: 'loop', text: 'Continue', nextParagraphId: 'para1'),
  ],
);
```
**Fix**: Add an exit choice or progress to a different paragraph.

### ❌ Missing Character
```dart
StoryParagraph(
  id: 'intro',
  text: 'Character speaks...',
  characterId: 'missing_char', // Not in characters map!
  choices: [],
),
```
**Fix**: Add the character to the story's characters map.

### ❌ Unreachable Paragraph
```dart
paragraphs: {
  'intro': introPara,    // Starting paragraph
  'ending': endingPara,  // Referenced in intro
  'secret': secretPara,  // Never referenced by any choice!
},
```
**Fix**: Either remove unused paragraph or add a choice leading to it.

---

## Tips for Good Storytelling

1. **Hook Early**: Make the first paragraph engaging
2. **Show Consequences**: Choices should feel impactful
3. **Character Voice**: Keep dialogue consistent with personality
4. **Pacing**: Don't make paragraphs too long
5. **Multiple Endings**: Reward players for different choices
6. **Replayability**: Make choices interesting enough to try both paths
7. **Lore Building**: Connect stories to the game world
8. **Emotional Arc**: Give stories a beginning, middle, and end
9. **Visual Variety**: Use different characters for visual interest
10. **Balanced Rewards**: Match rewards to story length/difficulty

---

## Testing Your Story

### Manual Testing
```dart
// In your test file or main function
final repo = StorylineRepository();
repo.initialize();

final story = repo.getStorylineElement('your_story_id');
print('Story: ${story?.title}');
print('Characters: ${story?.characters.keys}');
print('Paragraphs: ${story?.paragraphs.keys}');
print('Start: ${story?.startParagraphId}');

// Test each path manually through UI
```

### Validation Checks
```dart
void validateStory(StorylineElement story) {
  // Check start paragraph exists
  assert(story.paragraphs.containsKey(story.startParagraphId));
  
  // Check all paragraph references
  for (var paragraph in story.paragraphs.values) {
    for (var choice in paragraph.choices) {
      assert(story.paragraphs.containsKey(choice.nextParagraphId),
        'Missing paragraph: ${choice.nextParagraphId}');
    }
    
    // Check character references
    if (paragraph.characterId != null) {
      assert(story.characters.containsKey(paragraph.characterId),
        'Missing character: ${paragraph.characterId}');
    }
  }
  
  print('✅ Story validation passed!');
}
```

---

## Quick Reference: Model Parameters

### StoryCharacter
- `id` - Unique identifier
- `name` - Display name
- `personality` - Character description
- `imagePath` - Path to image asset

### StoryChoice
- `id` - Choice identifier
- `text` - Button text
- `nextParagraphId` - Target paragraph
- `requirements` - Optional stat requirements

### StoryParagraph
- `id` - Paragraph identifier
- `text` - Narrative content
- `characterId` - Optional speaker
- `choices` - List of player choices

### StorylineElement
- `id` - Story identifier
- `title` - Display title
- `description` - Brief summary
- `paragraphs` - Map of all paragraphs
- `startParagraphId` - Entry point
- `characters` - Map of characters
- `triggerRequirements` - Optional unlock conditions
- `rewards` - Optional completion rewards

---

## Need Help?

Refer to:
- `STORYLINE_SYSTEM.md` - Complete documentation
- `lib/domain/storyline_models.dart` - Model definitions
- `lib/data/storyline_repository.dart` - Example story implementation
- `lib/ui/storyline_dialog.dart` - UI integration example
