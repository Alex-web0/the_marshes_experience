/// Storyline Models
///
/// This file contains the core models for the game's interactive storyline system.
/// The storyline is composed of characters, story elements, paragraphs, and choices
/// that allow players to interact with the narrative and influence the story flow.

/// Represents a character in the storyline
///
/// Characters are the NPCs (non-player characters) that the player interacts with
/// throughout the game. Each character has a unique personality and visual representation.
class StoryCharacter {
  /// Unique identifier for the character
  /// Example: 'old_fisherman', 'marsh_guardian', 'lost_child'
  final String id;

  /// Display name of the character
  /// This is shown in the UI during dialogues and interactions
  /// Example: 'Old Fisherman', 'Marsh Guardian'
  final String name;

  /// Brief description of the character's personality traits
  /// Helps define how the character speaks and behaves in the story
  /// Example: 'Wise and patient, speaks in riddles', 'Protective but mysterious'
  final String personality;

  /// Path to the character's profile/avatar image
  /// Used to display the character's face or icon in dialogue boxes
  /// Example: 'assets/images/characters/old_fisherman.png'
  final String imagePath;

  StoryCharacter({
    required this.id,
    required this.name,
    required this.personality,
    required this.imagePath,
  });

  /// Creates a StoryCharacter from a map (for Firebase/JSON deserialization)
  factory StoryCharacter.fromMap(String id, Map<dynamic, dynamic> map) {
    return StoryCharacter(
      id: id,
      name: map['name'] ?? '',
      personality: map['personality'] ?? '',
      imagePath: map['imagePath'] ?? '',
    );
  }

  /// Converts the character to a map (for Firebase/JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'personality': personality,
      'imagePath': imagePath,
    };
  }
}

/// Represents a single paragraph of story content
///
/// Paragraphs are the building blocks of the storyline. Each paragraph contains
/// narrative text and may present the player with choices that branch the story.
class StoryParagraph {
  /// Unique identifier for this paragraph
  /// Example: 'intro_001', 'fisherman_greeting', 'choice_help_or_ignore'
  final String id;

  /// The narrative text content of this paragraph
  /// This is the story text that will be displayed to the player
  /// Can be multi-line and contain dialogue or descriptions
  /// Example: 'The old fisherman looks at you with knowing eyes. "The marshes hold many secrets," he says.'
  final String text;

  /// Optional character ID who is speaking or present in this paragraph
  /// If null, this is narrator text. If set, the character's avatar and name appear
  /// Example: 'old_fisherman', 'marsh_guardian'
  final String? characterId;

  /// List of choices available to the player at the end of this paragraph
  /// If empty, the paragraph auto-continues or ends the story element
  /// Choices allow branching narrative based on player decisions
  final List<StoryChoice> choices;

  StoryParagraph({
    required this.id,
    required this.text,
    this.characterId,
    this.choices = const [],
  });

  /// Creates a StoryParagraph from a map (for Firebase/JSON deserialization)
  factory StoryParagraph.fromMap(String id, Map<dynamic, dynamic> map) {
    final choicesList = <StoryChoice>[];
    if (map['choices'] != null) {
      final choicesData = map['choices'] as List<dynamic>;
      for (var i = 0; i < choicesData.length; i++) {
        choicesList.add(StoryChoice.fromMap(i.toString(), choicesData[i]));
      }
    }

    return StoryParagraph(
      id: id,
      text: map['text'] ?? '',
      characterId: map['characterId'],
      choices: choicesList,
    );
  }

  /// Converts the paragraph to a map (for Firebase/JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'characterId': characterId,
      'choices': choices.map((c) => c.toMap()).toList(),
    };
  }
}

/// Represents a player choice within a story paragraph
///
/// Choices are the interactive elements that allow players to influence the story.
/// Each choice can lead to a different paragraph, creating branching narratives.
class StoryChoice {
  /// Unique identifier for this choice (usually an index or descriptive key)
  /// Example: '0', '1', 'help', 'ignore'
  final String id;

  /// The text displayed on the choice button
  /// This is what the player sees and clicks on to make their decision
  /// Example: 'Help the fisherman', 'Walk away', 'Ask about the marshes'
  final String text;

  /// The ID of the paragraph to navigate to when this choice is selected
  /// This creates the branching story structure
  /// Example: 'fisherman_grateful', 'fisherman_disappointed', 'marshes_lore'
  final String nextParagraphId;

  /// Optional: Requirements to show this choice (e.g., fish count, story count)
  /// If null, the choice is always available
  /// Example: {'fishCount': 3} - only show if player has 3+ fish
  final Map<String, int>? requirements;

  StoryChoice({
    required this.id,
    required this.text,
    required this.nextParagraphId,
    this.requirements,
  });

  /// Creates a StoryChoice from a map (for Firebase/JSON deserialization)
  factory StoryChoice.fromMap(String id, Map<dynamic, dynamic> map) {
    Map<String, int>? reqs;
    if (map['requirements'] != null) {
      reqs = Map<String, int>.from(map['requirements']);
    }

    return StoryChoice(
      id: id,
      text: map['text'] ?? '',
      nextParagraphId: map['nextParagraphId'] ?? '',
      requirements: reqs,
    );
  }

  /// Converts the choice to a map (for Firebase/JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'nextParagraphId': nextParagraphId,
      'requirements': requirements,
    };
  }
}

/// Represents a complete storyline element/encounter
///
/// A StorylineElement is a self-contained story segment that the player experiences.
/// It contains all the paragraphs, characters, and branching logic for one story arc.
/// Examples: "Meeting the Old Fisherman", "The Marsh Guardian's Test", "Finding the Lost Child"
class StorylineElement {
  /// Unique identifier for this storyline element
  /// Used to track which stories the player has completed
  /// Example: 'old_fisherman_quest', 'marsh_guardian_encounter'
  final String id;

  /// Display title of this story element
  /// Shown in UI menus or completion screens
  /// Example: 'The Old Fisherman's Tale', 'Secrets of the Marsh'
  final String title;

  /// Brief description of what this story element is about
  /// Can be shown in story selection menus or quest logs
  /// Example: 'An old fisherman needs help navigating the treacherous marshes'
  final String description;

  /// Map of all paragraphs in this story element, keyed by paragraph ID
  /// The story flow navigates through these paragraphs based on player choices
  /// Example: {'intro': paragraphObj, 'choice_help': paragraphObj2, ...}
  final Map<String, StoryParagraph> paragraphs;

  /// The ID of the starting paragraph
  /// This is where the story begins when the element is triggered
  /// Example: 'intro', 'opening_scene'
  final String startParagraphId;

  /// Map of characters involved in this story element, keyed by character ID
  /// Used to display character info when they appear in paragraphs
  /// Example: {'old_fisherman': characterObj, 'his_daughter': characterObj2}
  final Map<String, StoryCharacter> characters;

  /// Optional: Conditions required to trigger this story element
  /// If null, the story is always available when encountered
  /// Example: {'fishCount': 5, 'storyCount': 2} - need 5 fish and 2 completed stories
  final Map<String, int>? triggerRequirements;

  /// Optional: Rewards given when completing this story element
  /// Can include score points, fish, or other game resources
  /// Example: {'score': 100, 'fishCount': 2}
  final Map<String, int>? rewards;

  StorylineElement({
    required this.id,
    required this.title,
    required this.description,
    required this.paragraphs,
    required this.startParagraphId,
    required this.characters,
    this.triggerRequirements,
    this.rewards,
  });

  /// Creates a StorylineElement from a map (for Firebase/JSON deserialization)
  factory StorylineElement.fromMap(String id, Map<dynamic, dynamic> map) {
    final paragraphsMap = <String, StoryParagraph>{};
    if (map['paragraphs'] != null) {
      final paragraphsData = map['paragraphs'] as Map<dynamic, dynamic>;
      paragraphsData.forEach((key, value) {
        paragraphsMap[key.toString()] =
            StoryParagraph.fromMap(key.toString(), value);
      });
    }

    final charactersMap = <String, StoryCharacter>{};
    if (map['characters'] != null) {
      final charactersData = map['characters'] as Map<dynamic, dynamic>;
      charactersData.forEach((key, value) {
        charactersMap[key.toString()] =
            StoryCharacter.fromMap(key.toString(), value);
      });
    }

    Map<String, int>? triggerReqs;
    if (map['triggerRequirements'] != null) {
      triggerReqs = Map<String, int>.from(map['triggerRequirements']);
    }

    Map<String, int>? rewardsMap;
    if (map['rewards'] != null) {
      rewardsMap = Map<String, int>.from(map['rewards']);
    }

    return StorylineElement(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      paragraphs: paragraphsMap,
      startParagraphId: map['startParagraphId'] ?? '',
      characters: charactersMap,
      triggerRequirements: triggerReqs,
      rewards: rewardsMap,
    );
  }

  /// Converts the storyline element to a map (for Firebase/JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'paragraphs':
          paragraphs.map((key, value) => MapEntry(key, value.toMap())),
      'startParagraphId': startParagraphId,
      'characters':
          characters.map((key, value) => MapEntry(key, value.toMap())),
      'triggerRequirements': triggerRequirements,
      'rewards': rewards,
    };
  }

  /// Gets a paragraph by its ID
  /// Returns null if the paragraph doesn't exist
  StoryParagraph? getParagraph(String paragraphId) {
    return paragraphs[paragraphId];
  }

  /// Gets a character by their ID
  /// Returns null if the character doesn't exist
  StoryCharacter? getCharacter(String characterId) {
    return characters[characterId];
  }

  /// Gets the starting paragraph of this story element
  StoryParagraph? getStartParagraph() {
    return paragraphs[startParagraphId];
  }
}

/// Represents the player's progress through a specific storyline element
///
/// This tracks where the player is in a story, what choices they've made,
/// and whether they've completed it. Used for save/load and multiplayer sync.
class StoryProgress {
  /// The ID of the storyline element this progress is for
  final String storyElementId;

  /// The ID of the current paragraph the player is on
  /// If null, the story hasn't been started yet
  final String? currentParagraphId;

  /// List of paragraph IDs the player has visited (in order)
  /// Used to track the player's path through the story
  final List<String> visitedParagraphs;

  /// Map of choices the player has made, keyed by paragraph ID
  /// Example: {'intro': 'choice_help', 'crossroads': 'choice_left'}
  final Map<String, String> choicesMade;

  /// Whether the player has completed this story element
  final bool isCompleted;

  /// Timestamp when the story was started
  final int? startedAt;

  /// Timestamp when the story was completed
  final int? completedAt;

  StoryProgress({
    required this.storyElementId,
    this.currentParagraphId,
    this.visitedParagraphs = const [],
    this.choicesMade = const {},
    this.isCompleted = false,
    this.startedAt,
    this.completedAt,
  });

  /// Creates a StoryProgress from a map (for Firebase/JSON deserialization)
  factory StoryProgress.fromMap(
      String storyElementId, Map<dynamic, dynamic> map) {
    return StoryProgress(
      storyElementId: storyElementId,
      currentParagraphId: map['currentParagraphId'],
      visitedParagraphs: map['visitedParagraphs'] != null
          ? List<String>.from(map['visitedParagraphs'])
          : [],
      choicesMade: map['choicesMade'] != null
          ? Map<String, String>.from(map['choicesMade'])
          : {},
      isCompleted: map['isCompleted'] ?? false,
      startedAt: map['startedAt'],
      completedAt: map['completedAt'],
    );
  }

  /// Converts the progress to a map (for Firebase/JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'currentParagraphId': currentParagraphId,
      'visitedParagraphs': visitedParagraphs,
      'choicesMade': choicesMade,
      'isCompleted': isCompleted,
      'startedAt': startedAt,
      'completedAt': completedAt,
    };
  }

  /// Creates a new progress state with updated values
  StoryProgress copyWith({
    String? currentParagraphId,
    List<String>? visitedParagraphs,
    Map<String, String>? choicesMade,
    bool? isCompleted,
    int? startedAt,
    int? completedAt,
  }) {
    return StoryProgress(
      storyElementId: storyElementId,
      currentParagraphId: currentParagraphId ?? this.currentParagraphId,
      visitedParagraphs: visitedParagraphs ?? this.visitedParagraphs,
      choicesMade: choicesMade ?? this.choicesMade,
      isCompleted: isCompleted ?? this.isCompleted,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
