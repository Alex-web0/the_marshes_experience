import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:ui';
import '../domain/storyline_models.dart';
import '../data/storyline_repository.dart';

/// Interactive storyline dialog - bottom half design with animated text
/// Matches the heritage dialog style with tap-to-skip functionality
class StorylineDialog extends StatefulWidget {
  final String storyElementId;
  final VoidCallback onComplete;
  final Function(Map<String, int>? rewards)? onRewardsEarned;

  const StorylineDialog({
    super.key,
    required this.storyElementId,
    required this.onComplete,
    this.onRewardsEarned,
  });

  @override
  State<StorylineDialog> createState() => _StorylineDialogState();
}

class _StorylineDialogState extends State<StorylineDialog>
    with SingleTickerProviderStateMixin {
  final StorylineRepository _repo = StorylineRepository();
  late StorylineElement? _story;
  late StoryProgress _progress;
  StoryParagraph? _currentParagraph;
  StoryCharacter? _currentCharacter;

  bool _isTextFinished = false;
  late AnimationController _cursorController;

  // Scroll controller for detecting scroll position
  final ScrollController _scrollController = ScrollController();
  bool _showTopIndicator = false;
  bool _showBottomIndicator = false;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _scrollController.addListener(_updateScrollIndicators);

    _initializeStory();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollIndicators);
    _scrollController.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  void _updateScrollIndicators() {
    if (!mounted || !_scrollController.hasClients) return;

    final showTop = _scrollController.offset > 10;
    final showBottom = _scrollController.offset <
        _scrollController.position.maxScrollExtent - 10;

    if (showTop != _showTopIndicator || showBottom != _showBottomIndicator) {
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _showTopIndicator = showTop;
            _showBottomIndicator = showBottom;
          });
        }
      });
    }
  }

  void _checkScrollableContent() {
    // Check after a short delay to ensure layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        final showTop = _scrollController.offset > 10;
        final showBottom = _scrollController.offset <
            _scrollController.position.maxScrollExtent - 10;

        if (mounted &&
            (showTop != _showTopIndicator ||
                showBottom != _showBottomIndicator)) {
          setState(() {
            _showTopIndicator = showTop;
            _showBottomIndicator = showBottom;
          });
        }
      }
    });
  }

  void _initializeStory() {
    _story = _repo.getStorylineElement(widget.storyElementId);
    if (_story == null) {
      widget.onComplete();
      return;
    }

    final existingProgress = _repo.getProgress(widget.storyElementId);
    if (existingProgress != null && !existingProgress.isCompleted) {
      _progress = existingProgress;
    } else {
      _progress = _repo.startStory(widget.storyElementId);
    }

    _loadCurrentParagraph();
  }

  void _loadCurrentParagraph() {
    if (_progress.currentParagraphId == null) {
      _completeStory();
      return;
    }

    setState(() {
      _isTextFinished = false;
      _currentParagraph = _story!.getParagraph(_progress.currentParagraphId!);

      if (_currentParagraph?.characterId != null) {
        _currentCharacter =
            _story!.getCharacter(_currentParagraph!.characterId!);
      } else {
        _currentCharacter = null;
      }
    });

    // Reset scroll position safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
        _checkScrollableContent();
      }
    });
  }

  void _makeChoice(StoryChoice choice) {
    _progress = _repo.makeChoice(
      widget.storyElementId,
      _currentParagraph!.id,
      choice.id,
      choice.nextParagraphId,
    );

    final nextParagraph = _story!.getParagraph(choice.nextParagraphId);
    if (nextParagraph == null) {
      _completeStory();
    } else {
      _loadCurrentParagraph();
    }
  }

  void _completeStory() {
    _repo.completeStory(widget.storyElementId);

    if (_story?.rewards != null && widget.onRewardsEarned != null) {
      widget.onRewardsEarned!(_story!.rewards);
    }

    widget.onComplete();
  }

  void _handleTap() {
    if (_isTextFinished && _currentParagraph!.choices.isEmpty) {
      // Auto-continue if no choices
      _completeStory();
    } else if (!_isTextFinished) {
      // Skip animation
      setState(() {
        _isTextFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentParagraph == null) {
      return const SizedBox.shrink();
    }

    final textStyle = GoogleFonts.pixelifySans(
      fontSize: 16,
      color: Colors.white,
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleTap,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.5,
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Character header (avatar + name + title in row)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey.shade800,
                              backgroundImage:
                                  _currentCharacter?.imagePath != null
                                      ? AssetImage(_currentCharacter!.imagePath)
                                      : null,
                              child: _currentCharacter?.imagePath == null
                                  ? Text(
                                      '📖',
                                      style: GoogleFonts.pixelifySans(
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentCharacter?.name ?? 'Narrator',
                                    style: GoogleFonts.pixelifySans(
                                      fontSize: 18,
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _story!.title,
                                    style: GoogleFonts.pixelifySans(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Text content area with scroll indicators
                        Expanded(
                          child: Stack(
                            children: [
                              SingleChildScrollView(
                                controller: _scrollController,
                                child: _isTextFinished
                                    ? Text(
                                        _currentParagraph!.text,
                                        style: textStyle,
                                      )
                                    : IgnorePointer(
                                        child: DefaultTextStyle(
                                          style: textStyle,
                                          child: AnimatedTextKit(
                                            animatedTexts: [
                                              TypewriterAnimatedText(
                                                _currentParagraph!.text,
                                                speed: const Duration(
                                                    milliseconds: 50),
                                                cursor: '▌',
                                              ),
                                            ],
                                            isRepeatingAnimation: false,
                                            onFinished: () {
                                              setState(
                                                  () => _isTextFinished = true);
                                              _checkScrollableContent();
                                            },
                                          ),
                                        ),
                                      ),
                              ),

                              // Top scroll indicator
                              if (_showTopIndicator)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 30,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.5),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.keyboard_arrow_up,
                                        color: Colors.amber.withOpacity(0.8),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),

                              // Bottom scroll indicator
                              if (_showBottomIndicator)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 30,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.5),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.amber.withOpacity(0.8),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Choices or continue indicator
                        if (_isTextFinished) ...[
                          if (_currentParagraph!.choices.isNotEmpty)
                            ..._currentParagraph!.choices
                                .map((choice) => Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: _buildChoiceButton(choice),
                                    ))
                          else
                            // No choices - show tap to continue
                            FadeTransition(
                              opacity: _cursorController,
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  '...tap to continue',
                                  style: GoogleFonts.pixelifySans(
                                    fontSize: 12,
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ] else
                          // Animation playing - show tap to skip
                          FadeTransition(
                            opacity: _cursorController,
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                '...tap to skip',
                                style: GoogleFonts.pixelifySans(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton(StoryChoice choice) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _makeChoice(choice),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.15),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: Colors.amber.withOpacity(0.5),
              width: 1.5,
            ),
          ),
        ),
        child: Text(
          choice.text,
          style: GoogleFonts.pixelifySans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
