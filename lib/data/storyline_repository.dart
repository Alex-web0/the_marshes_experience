import '../domain/storyline_models.dart';

/// Repository for managing storyline elements and player story progress
///
/// This class handles loading story content, tracking player progress through stories,
/// and managing story-related game state. It can load stories from local data or
/// potentially from Firebase for dynamic content updates.
class StorylineRepository {
  static final StorylineRepository _instance = StorylineRepository._internal();
  factory StorylineRepository() => _instance;
  StorylineRepository._internal();

  // Cache of all available storyline elements
  final Map<String, StorylineElement> _storylineElements = {};

  // Player's progress through each story
  final Map<String, StoryProgress> _playerProgress = {};

  /// Initializes the repository with default storyline elements
  ///
  /// This loads all the story content into memory. In the future, this could
  /// load from JSON files or Firebase for dynamic content.
  void initialize() {
    _loadDefaultStories();
  }

  /// Loads the default storyline elements
  ///
  /// Currently loads hardcoded stories. Can be expanded to load from assets
  /// or Firebase in the future.
  void _loadDefaultStories() {
    // Example stories covering all scenarios
    final oldFishermanStory = _createOldFishermanStory();
    _storylineElements[oldFishermanStory.id] = oldFishermanStory;

    final lostChildStory = _createLostChildStory();
    _storylineElements[lostChildStory.id] = lostChildStory;

    final marshGuardianStory = _createMarshGuardianStory();
    _storylineElements[marshGuardianStory.id] = marshGuardianStory;

    final simpleNarratorStory = _createSimpleNarratorStory();
    _storylineElements[simpleNarratorStory.id] = simpleNarratorStory;

    final longTextStory = _createLongTextStory();
    _storylineElements[longTextStory.id] = longTextStory;
  }

  /// Creates the "Old Fisherman" story element as an example
  StorylineElement _createOldFishermanStory() {
    // Create the old fisherman character
    final oldFisherman = StoryCharacter(
      id: 'old_fisherman',
      name: 'Old Fisherman',
      personality: 'Wise and weathered, speaks slowly with a knowing smile',
      imagePath: 'assets/images/characters/old_fisherman.png',
    );

    // Create story paragraphs
    final introParagraph = StoryParagraph(
      id: 'intro',
      text:
          'You notice an old fisherman sitting by the river\'s edge, his boat gently rocking in the water. He waves you over with a weathered hand.',
      characterId: 'old_fisherman',
      choices: [
        StoryChoice(
          id: 'approach',
          text: 'Approach the fisherman',
          nextParagraphId: 'greeting',
        ),
        StoryChoice(
          id: 'ignore',
          text: 'Keep moving',
          nextParagraphId: 'ignored',
        ),
      ],
    );

    final greetingParagraph = StoryParagraph(
      id: 'greeting',
      text:
          '"Ah, a traveler! The marshes have been kind to you, I see. I\'ve been fishing these waters for fifty years, and the river always provides... if you know how to ask."',
      characterId: 'old_fisherman',
      choices: [
        StoryChoice(
          id: 'ask_advice',
          text: 'Ask for fishing advice',
          nextParagraphId: 'advice',
        ),
        StoryChoice(
          id: 'ask_story',
          text: 'Ask about the marshes',
          nextParagraphId: 'marsh_lore',
        ),
      ],
    );

    final adviceParagraph = StoryParagraph(
      id: 'advice',
      text:
          'The old man chuckles. "The best spots are where the reeds grow thick and the water runs slow. But watch out for the currents - they\'ve claimed many a careless boat." He hands you a small carved fish charm. "For luck."',
      characterId: 'old_fisherman',
      choices: [], // End of this branch
    );

    final loreParagraph = StoryParagraph(
      id: 'marsh_lore',
      text:
          '"These marshes hold ancient secrets," he whispers, eyes twinkling. "They say the spirits of the river watch over those who respect the water. I\'ve seen strange lights at night, heard songs with no singer..."',
      characterId: 'old_fisherman',
      choices: [], // End of this branch
    );

    final ignoredParagraph = StoryParagraph(
      id: 'ignored',
      text:
          'You continue on your way. Behind you, the old fisherman returns to his fishing, unbothered by your choice.',
      characterId: null, // Narrator text
      choices: [], // End of story
    );

    return StorylineElement(
      id: 'old_fisherman_encounter',
      title: 'The Old Fisherman',
      description: 'A chance meeting with a wise old fisherman by the river',
      paragraphs: {
        'intro': introParagraph,
        'greeting': greetingParagraph,
        'advice': adviceParagraph,
        'marsh_lore': loreParagraph,
        'ignored': ignoredParagraph,
      },
      startParagraphId: 'intro',
      characters: {
        'old_fisherman': oldFisherman,
      },
      rewards: {
        'score': 50,
        'storyCount': 1,
      },
    );
  }

  /// Creates the "Lost Child" story - tests character with choices and requirements
  StorylineElement _createLostChildStory() {
    final lostChild = StoryCharacter(
      id: 'lost_child',
      name: 'Maya',
      personality: 'Scared but brave, 8 years old',
      imagePath: 'assets/images/characters/lost_child.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'You hear soft crying from behind the reeds. A small child sits alone, clutching a worn teddy bear. Tears stream down her face.',
      characterId: null,
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
      text:
          '"I\'m lost... I can\'t find my way home. Can you help me?" Her voice trembles with fear.',
      characterId: 'lost_child',
      choices: [
        StoryChoice(
          id: 'help_navigate',
          text: 'Offer to guide her home',
          nextParagraphId: 'helping',
          requirements: {'fishCount': 2},
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
      text:
          '"Really? Thank you so much!" She climbs into your boat. Using your knowledge of the marshes, you safely guide her back to the village. Her mother runs out, crying with relief. "How can I ever thank you?" she asks, pressing a bag of coins into your hand.',
      characterId: 'lost_child',
      choices: [],
    );

    final comforting = StoryParagraph(
      id: 'comforting',
      text:
          'You sit with her for a while, sharing your fish and telling her stories. She stops crying and smiles weakly. "Thank you for staying with me." Eventually, her parents find her, grateful that someone watched over their daughter.',
      characterId: 'lost_child',
      choices: [],
    );

    final guilty = StoryParagraph(
      id: 'guilty',
      text:
          'You row away, but the sound of her crying haunts you for the rest of the day. The marshes feel colder somehow.',
      characterId: null,
      choices: [],
    );

    return StorylineElement(
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
      triggerRequirements: null,
      rewards: {
        'score': 150,
        'storyCount': 1,
      },
    );
  }

  /// Creates "Marsh Guardian" story - tests long dialogue and multiple branches
  StorylineElement _createMarshGuardianStory() {
    final guardian = StoryCharacter(
      id: 'marsh_guardian',
      name: 'The Guardian',
      personality: 'Ancient and mysterious, speaks in riddles',
      imagePath: 'assets/images/characters/marsh_guardian.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'A shimmering figure materializes from the mist ahead. It appears to be made of water and light, shifting between human and something else entirely. Its voice echoes across the marshes.',
      characterId: 'marsh_guardian',
      choices: [
        StoryChoice(
          id: 'greet',
          text: 'Greet the guardian',
          nextParagraphId: 'greeting',
        ),
        StoryChoice(
          id: 'flee',
          text: 'Row away quickly',
          nextParagraphId: 'flee_ending',
        ),
      ],
    );

    final greeting = StoryParagraph(
      id: 'greeting',
      text:
          '"Welcome, traveler. Few have the courage to face me. The marshes test all who enter - some with water, some with time, and some with truth. Which trial will you choose?"',
      characterId: 'marsh_guardian',
      choices: [
        StoryChoice(
          id: 'water',
          text: 'Trial by Water',
          nextParagraphId: 'water_trial',
        ),
        StoryChoice(
          id: 'time',
          text: 'Trial by Time',
          nextParagraphId: 'time_trial',
        ),
        StoryChoice(
          id: 'truth',
          text: 'Trial by Truth',
          nextParagraphId: 'truth_trial',
        ),
      ],
    );

    final waterTrial = StoryParagraph(
      id: 'water_trial',
      text:
          '"You have chosen the path of water - adaptable, flowing, persistent. The river teaches us to move around obstacles, not through them. Remember this wisdom." The guardian dissolves into the water, leaving behind a glowing pearl.',
      characterId: 'marsh_guardian',
      choices: [],
    );

    final timeTrial = StoryParagraph(
      id: 'time_trial',
      text:
          '"You have chosen the path of time - patient, enduring, inevitable. The marshes have stood for millennia, weathering all storms. Learn to wait, and all things will come." The guardian fades like morning mist, leaving a golden hourglass.',
      characterId: 'marsh_guardian',
      choices: [],
    );

    final truthTrial = StoryParagraph(
      id: 'truth_trial',
      text:
          '"You have chosen the path of truth - honest, clear, unwavering. The water always reveals what lies beneath, given time. Speak your truth, and the world will listen." The guardian vanishes in a flash of light, leaving a crystal mirror.',
      characterId: 'marsh_guardian',
      choices: [],
    );

    final fleeEnding = StoryParagraph(
      id: 'flee_ending',
      text:
          'You row away as fast as you can. The guardian\'s laughter echoes behind you - not mocking, but understanding. "Another time, perhaps," the voice whispers.',
      characterId: null,
      choices: [],
    );

    return StorylineElement(
      id: 'marsh_guardian_trial',
      title: 'The Marsh Guardian',
      description: 'A mystical guardian offers you a trial',
      paragraphs: {
        'intro': intro,
        'greeting': greeting,
        'water_trial': waterTrial,
        'time_trial': timeTrial,
        'truth_trial': truthTrial,
        'flee_ending': fleeEnding,
      },
      startParagraphId: 'intro',
      characters: {
        'marsh_guardian': guardian,
      },
      triggerRequirements: {'storyCount': 1},
      rewards: {
        'score': 200,
        'storyCount': 1,
      },
    );
  }

  /// Creates simple narrator story - tests narrator-only text (no character)
  StorylineElement _createSimpleNarratorStory() {
    final para1 = StoryParagraph(
      id: 'para1',
      text:
          'The sun begins to set over the marshes, painting the sky in brilliant oranges and purples. Birds call out their evening songs.',
      characterId: null,
      choices: [
        StoryChoice(
          id: 'continue',
          text: 'Keep watching',
          nextParagraphId: 'para2',
        ),
      ],
    );

    final para2 = StoryParagraph(
      id: 'para2',
      text:
          'As darkness falls, fireflies emerge, dancing like tiny stars above the water. The marshes transform into a magical realm.',
      characterId: null,
      choices: [
        StoryChoice(
          id: 'continue',
          text: 'Stay a moment longer',
          nextParagraphId: 'para3',
        ),
      ],
    );

    final para3 = StoryParagraph(
      id: 'para3',
      text:
          'The moon rises, full and bright, casting silver light across the water. You feel at peace here, among the ancient reeds and gentle waves.',
      characterId: null,
      choices: [],
    );

    return StorylineElement(
      id: 'evening_peace',
      title: 'Evening Peace',
      description: 'A quiet moment in the marshes',
      paragraphs: {
        'para1': para1,
        'para2': para2,
        'para3': para3,
      },
      startParagraphId: 'para1',
      characters: {},
      rewards: {
        'score': 25,
      },
    );
  }

  /// Creates story with very long text - tests scrolling
  StorylineElement _createLongTextStory() {
    final storyteller = StoryCharacter(
      id: 'storyteller',
      name: 'Elder Storyteller',
      personality: 'Loves to talk, full of ancient tales',
      imagePath: 'assets/images/characters/storyteller.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'An elderly person sits on a dock, looking out at the water. They turn to you with a warm smile.',
      characterId: 'storyteller',
      choices: [
        StoryChoice(
          id: 'listen',
          text: 'Ask for a story',
          nextParagraphId: 'long_story',
        ),
        StoryChoice(
          id: 'decline',
          text: 'Politely decline',
          nextParagraphId: 'decline_ending',
        ),
      ],
    );

    final longStory = StoryParagraph(
      id: 'long_story',
      text:
          '"Ah, a listener! Let me tell you the tale of the Great Marsh...\n\n'
          'Long ago, before your grandparents\' grandparents were born, these marshes were just a small pond. '
          'But a great flood came, waters rising higher and higher, until the whole valley was covered. '
          'The people fled to the hills, thinking their homes lost forever.\n\n'
          'But when the waters receded, they found something miraculous - the land had been transformed into these beautiful marshes, '
          'teeming with life. Fish filled the waters, birds nested in the reeds, and plants grew in abundance.\n\n'
          'The people learned to live with the water, not against it. They built boats instead of bridges, '
          'planted rice in the shallows, and caught fish in the channels. The marshes became their home, their livelihood, their heritage.\n\n'
          'And that, young one, is why we say: the water gives, the water takes, but mostly the water gives. '
          'Respect it, and it will provide for you all your days."',
      characterId: 'storyteller',
      choices: [],
    );

    final declineEnding = StoryParagraph(
      id: 'decline_ending',
      text:
          '"Another time, perhaps," they say with understanding, turning back to watch the sunset.',
      characterId: 'storyteller',
      choices: [],
    );

    return StorylineElement(
      id: 'tale_of_the_great_marsh',
      title: 'Tale of the Great Marsh',
      description: 'An elder shares ancient wisdom',
      paragraphs: {
        'intro': intro,
        'long_story': longStory,
        'decline_ending': declineEnding,
      },
      startParagraphId: 'intro',
      characters: {
        'storyteller': storyteller,
      },
      rewards: {
        'score': 75,
        'storyCount': 1,
      },
    );
  }

  /// Gets a storyline element by its ID
  /// Returns null if not found
  StorylineElement? getStorylineElement(String id) {
    return _storylineElements[id];
  }

  /// Gets all available storyline elements
  List<StorylineElement> getAllStorylineElements() {
    return _storylineElements.values.toList();
  }

  /// Gets storyline elements that match the player's current requirements
  ///
  /// Filters stories based on trigger requirements (e.g., fish count, story count)
  List<StorylineElement> getAvailableStories({
    required int fishCount,
    required int storyCount,
  }) {
    return _storylineElements.values.where((story) {
      if (story.triggerRequirements == null) return true;

      final reqs = story.triggerRequirements!;
      if (reqs['fishCount'] != null && fishCount < reqs['fishCount']!) {
        return false;
      }
      if (reqs['storyCount'] != null && storyCount < reqs['storyCount']!) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Starts a new story for the player
  ///
  /// Creates initial progress tracking for the story
  StoryProgress startStory(String storyElementId) {
    final progress = StoryProgress(
      storyElementId: storyElementId,
      currentParagraphId: _storylineElements[storyElementId]?.startParagraphId,
      startedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _playerProgress[storyElementId] = progress;
    return progress;
  }

  /// Records a choice made by the player
  ///
  /// Updates the progress to reflect the player's decision and moves to the next paragraph
  StoryProgress makeChoice(
    String storyElementId,
    String currentParagraphId,
    String choiceId,
    String nextParagraphId,
  ) {
    final currentProgress = _playerProgress[storyElementId];
    if (currentProgress == null) return startStory(storyElementId);

    final newVisited = List<String>.from(currentProgress.visitedParagraphs)
      ..add(nextParagraphId);

    final newChoices = Map<String, String>.from(currentProgress.choicesMade)
      ..[currentParagraphId] = choiceId;

    final updatedProgress = currentProgress.copyWith(
      currentParagraphId: nextParagraphId,
      visitedParagraphs: newVisited,
      choicesMade: newChoices,
    );

    _playerProgress[storyElementId] = updatedProgress;
    return updatedProgress;
  }

  /// Marks a story as completed
  ///
  /// Updates the progress to reflect completion
  StoryProgress completeStory(String storyElementId) {
    final currentProgress = _playerProgress[storyElementId];
    if (currentProgress == null) return startStory(storyElementId);

    final updatedProgress = currentProgress.copyWith(
      isCompleted: true,
      completedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _playerProgress[storyElementId] = updatedProgress;
    return updatedProgress;
  }

  /// Gets the player's progress for a specific story
  /// Returns null if the story hasn't been started
  StoryProgress? getProgress(String storyElementId) {
    return _playerProgress[storyElementId];
  }

  /// Gets all story progress records
  Map<String, StoryProgress> getAllProgress() {
    return Map.from(_playerProgress);
  }

  /// Checks if a story has been completed
  bool isStoryCompleted(String storyElementId) {
    return _playerProgress[storyElementId]?.isCompleted ?? false;
  }

  /// Gets the count of completed stories
  int getCompletedStoriesCount() {
    return _playerProgress.values.where((p) => p.isCompleted).length;
  }

  /// Resets all story progress (useful for testing or new game)
  void resetProgress() {
    _playerProgress.clear();
  }

  /// Loads progress from a map (for save/load or Firebase sync)
  void loadProgress(Map<String, dynamic> progressData) {
    _playerProgress.clear();
    progressData.forEach((key, value) {
      _playerProgress[key] = StoryProgress.fromMap(key, value);
    });
  }

  /// Exports progress to a map (for save/load or Firebase sync)
  Map<String, dynamic> exportProgress() {
    return _playerProgress.map(
      (key, value) => MapEntry(key, value.toMap()),
    );
  }
}
