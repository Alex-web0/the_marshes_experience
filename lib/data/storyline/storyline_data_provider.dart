import '../../domain/storyline_models.dart';

/// Abstract interface for storyline data providers
///
/// This allows switching between different data sources (local hardcoded, Firebase, etc.)
/// without changing the repository implementation.
abstract class StorylineDataProvider {
  /// Loads all storyline elements from the data source
  ///
  /// Returns a map of story IDs to StorylineElement objects
  Future<Map<String, StorylineElement>> loadStorylineElements();

  /// Optional: Load player progress from remote storage
  ///
  /// Returns null if not implemented or no data available
  Future<Map<String, StoryProgress>?> loadPlayerProgress(String playerId);

  /// Optional: Save player progress to remote storage
  ///
  /// Returns true if successful, false otherwise
  Future<bool> savePlayerProgress(
      String playerId, Map<String, StoryProgress> progress);
}
