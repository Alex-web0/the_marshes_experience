import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/storyline_repository.dart';
import '../domain/storyline_models.dart';

/// Debug dialog for testing all storylines
/// Only visible in debug mode
class DebugStorylineMenu extends StatelessWidget {
  final Function(String storyId) onStorySelected;
  final VoidCallback onClose;

  const DebugStorylineMenu({
    super.key,
    required this.onStorySelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final repo = StorylineRepository();
    final allStories = repo.getAllStorylineElements();

    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.8,
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🐛 DEBUG: Test Storylines',
                    style: GoogleFonts.pixelifySans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.green),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Story list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allStories.length,
              itemBuilder: (context, index) {
                final story = allStories[index];
                return _buildStoryCard(story);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(StorylineElement story) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onStorySelected(story.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  story.title,
                  style: GoogleFonts.pixelifySans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  story.description,
                  style: GoogleFonts.pixelifySans(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),

                // Stats
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildTag('📖 ${story.paragraphs.length} paragraphs'),
                    _buildTag('👤 ${story.characters.length} characters'),
                    if (story.triggerRequirements != null)
                      _buildTag('🔒 Has requirements'),
                    if (story.rewards != null)
                      _buildTag('🎁 ${story.rewards!['score'] ?? 0} pts'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.pixelifySans(
          fontSize: 12,
          color: Colors.green,
        ),
      ),
    );
  }
}
