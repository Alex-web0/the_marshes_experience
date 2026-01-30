import 'package:flutter/material.dart';
import '../domain/game_stats.dart';
import '../data/score_repository.dart';
import 'ui_layers.dart'; // For fonts/styles

// --- MVP Contracts ---
abstract class GameOverView {
  void showLoading();
  void showStats(int highScore, bool isNewRecord);
}

class GameOverPresenter {
  final GameOverView _view;
  final ScoreRepository _repository;

  GameOverPresenter(this._view, this._repository);

  Future<void> loadStats(GameStats currentStats) async {
    _view.showLoading();

    // Save session
    await _repository.saveGameSession(currentStats);

    // Check High Score
    bool isNewHigh = await _repository.saveHighScore(currentStats.score);
    int highScore = await _repository.getHighScore();

    _view.showStats(highScore, isNewHigh);
  }
}

// --- UI Widget (View) ---
class GameOverMenu extends StatefulWidget {
  final GameStats stats;
  final VoidCallback onPlayAgain;
  final VoidCallback onMainMenu;
  final ScoreRepository repository;
  final VoidCallback? onButtonSound;

  const GameOverMenu({
    required this.stats,
    required this.onPlayAgain,
    required this.onMainMenu,
    required this.repository,
    this.onButtonSound,
    super.key,
  });

  @override
  State<GameOverMenu> createState() => _GameOverMenuState();
}

class _GameOverMenuState extends State<GameOverMenu> implements GameOverView {
  late GameOverPresenter _presenter;

  bool _isLoading = true;
  int _highScore = 0;
  bool _isNewHighScore = false;

  @override
  void initState() {
    super.initState();
    _presenter = GameOverPresenter(this, widget.repository);
    _presenter.loadStats(widget.stats);
  }

  @override
  void showLoading() {
    setState(() => _isLoading = true);
  }

  @override
  void showStats(int highScore, bool isNewRecord) {
    setState(() {
      _isLoading = false;
      _highScore = highScore;
      _isNewHighScore = isNewRecord;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LiquidGlassContainer(
          padding: const EdgeInsets.all(24),
          opacity: 0.8, // Increased opacity as requested
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("GAME OVER",
                  style:
                      kDisplayFont.copyWith(fontSize: 30, color: Colors.white)),

              // Animated Score
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: widget.stats.score.toDouble()),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Text(
                    "${value.toInt()}m",
                    style: kGameFont.copyWith(
                        fontSize: 58,
                        color: _isNewHighScore ? Colors.amber : Colors.white),
                  );
                },
              ),

              // Subtitle
              Text(
                _isNewHighScore ? "NEW HIGH SCORE!" : "BEST: $_highScore",
                style: kGameFont.copyWith(
                    fontSize: 21,
                    color:
                        _isNewHighScore ? Colors.amberAccent : Colors.white70),
              ),

              const SizedBox(height: 10),

              // Distance Rank Display (System for distance passed range)
              _RankDisplay(distance: widget.stats.score),

              const SizedBox(height: 30),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                      icon: Icons.set_meal,
                      value: "${widget.stats.fishCount}",
                      label: "Fish"),
                  _StatItem(
                      icon: Icons.map,
                      value: "${widget.stats.score}m",
                      label: "Dist"),
                  _StatItem(
                      icon: Icons.import_contacts,
                      value: "${widget.stats.storyCount}",
                      label: "Stories"),
                ],
              ),

              const SizedBox(height: 40),

              // Actions
              _GlassButton(
                label: "PLAY AGAIN",
                onTap: widget.onPlayAgain,
                onButtonSound: widget.onButtonSound,
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  widget.onButtonSound?.call();
                  widget.onMainMenu();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: kGameFont.copyWith(fontSize: 16),
                ),
                child: const Text("MAIN MENU"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.black12.withValues(alpha: 0.225),
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 5),
          Text(value,
              style: kGameFont.copyWith(fontSize: 20, color: Colors.white)),
          Text(label,
              style: kGameFont.copyWith(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }
}

class _RankDisplay extends StatelessWidget {
  final int distance;
  const _RankDisplay({required this.distance});

  String getRank() {
    if (distance < 500) return "Novice";
    if (distance < 1500) return "Explorer";
    if (distance < 3000) return "Veteran";
    if (distance < 5000) return "Master";
    return "Legend";
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "Rank: ${getRank()}",
      style: kGameFont.copyWith(
          color: Colors.amber, fontSize: 16, letterSpacing: 1.2),
    );
  }
}

// Make _GlassButton public in ui_layers.dart or redefine here?
// For now, let's assume it's private in ui_layers. I will duplicate it for speed or expose it in ui_layers next step.
// I'll define a local version here to avoid conflict if I don't touch ui_layers immediately.
class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onButtonSound;

  const _GlassButton({
    required this.label,
    required this.onTap,
    this.onButtonSound,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onButtonSound?.call();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        decoration: BoxDecoration(
          color: Colors.black
              .withOpacity(0.7), // Matched to new black button style
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: kGameFont.copyWith(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
