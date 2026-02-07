import '../domain/storyline_models.dart';
import 'storyline/storyline_data_provider.dart';

/// Repository for managing storyline elements and player story progress
///
/// This class handles loading story content, tracking player progress through stories,
/// and managing story-related game state. It uses a StorylineDataProvider to load
/// content from different sources (local hardcoded data, Firebase, etc.).
class StorylineRepository {
  static final StorylineRepository _instance = StorylineRepository._internal();
  factory StorylineRepository() => _instance;
  StorylineRepository._internal();

  // Data provider for loading storyline content
  StorylineDataProvider? _dataProvider;

  // Cache of all available storyline elements
  final Map<String, StorylineElement> _storylineElements = {};

  // Player's progress through each story
  final Map<String, StoryProgress> _playerProgress = {};

  // Initialization state
  bool _isInitialized = false;

  /// Initializes the repository with a data provider
  ///
  /// This loads all story content from the provider. Must be called before
  /// using any other repository methods.
  Future<void> initialize(StorylineDataProvider dataProvider) async {
    if (_isInitialized) return;

    _dataProvider = dataProvider;

    // Load storyline elements from the provider
    final stories = await _dataProvider!.loadStorylineElements();
    _storylineElements.addAll(stories);

    _isInitialized = true;
  }

  /// Checks if the repository has been initialized
  bool get isInitialized => _isInitialized;

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
