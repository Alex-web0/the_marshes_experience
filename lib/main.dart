import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'game/marshes_game.dart';
import 'ui/ui_layers.dart';
import 'ui/ui_layers.dart';
import 'ui/game_over_menu.dart';
import 'data/heritage_repository.dart';
import 'data/score_repository.dart';
import 'domain/game_stats.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Marshes Experience',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const GameContainer(),
    );
  }
}

class GameContainer extends StatefulWidget {
  const GameContainer({super.key});

  @override
  State<GameContainer> createState() => _GameContainerState();
}

class _GameContainerState extends State<GameContainer> {
  late MarshesGame _game;
  
  // UI State
  bool _showMenu = true;
  HeritageFact? _activeStory;
  int _score = 0;
  int _fishCount = 0; // New
  int _lives = 3; 
  bool _gameOver = false;
  GameStats? _lastStats; // Store stats for game over
  final ScoreRepository _scoreRepository = LocalScoreRepository();

  @override
  void initState() {
    super.initState();
    _game = MarshesGame(
      onGameOver: _handleGameOver,
      onStoryTrigger: _showStoryDialog,
      onScoreUpdate: (s) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _score = s);
        });
      },
      onHealthUpdate: (h) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _lives = h);
        });
      },
      onFishCountUpdate: (f) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _fishCount = f);
        });
      },
    );
  }

  void _handleGameOver(int score, int fish, int stories) {
    setState(() {
      _gameOver = true;
      _lastStats = GameStats(
        score: score,
        fishCount: fish,
        storyCount: stories,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      _showMenu = false; // We use GameOverMenu explicitly distinct from MainMenu if we want
    });
  }

  void _showStoryDialog(HeritageFact fact) {
    setState(() {
      _activeStory = fact;
    });
  }
  
  void _dismissStory() {
    setState(() {
      _activeStory = null;
    });
    _game.resumeGame();
  }


  void _startGame() {
    setState(() {
      _showMenu = false;
      _gameOver = false;
      _lives = 3;
      _score = 0;
      _fishCount = 0;
      _lastStats = null;
    });
    _game.startGame();
  }

  void _goToMainMenu() {
    _game.resetToMenu();
    setState(() {
        _gameOver = false;
        _showMenu = true;
        _lastStats = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 19.5, // Mobile Aspect Ratio Constraint
          child: Stack(
            children: [
              // 1. GAME LAYER
              GameWidget(game: _game),
              
              // 2. HUD LAYER (Only when playing)
              if (!_showMenu && _activeStory == null)
                Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text("DIST: ${_score}m", style: kGameFont.copyWith(fontSize: 20)),
                           Row(
                             children: [
                               const Icon(Icons.set_meal, color: Colors.cyanAccent, size: 16),
                               const SizedBox(width: 4),
                               Text("$_fishCount", style: kGameFont.copyWith(fontSize: 16, color: Colors.cyanAccent)),
                             ],
                           ),
                         ],
                       ),
                       Row(
                         children: List.generate(3, (index) => 
                           Icon(
                             index < _lives ? Icons.favorite : Icons.favorite_border,
                             color: Colors.redAccent,
                           )
                         ),
                       )
                    ],
                  ),
                ),

              // 3. MENU LAYER (Liquid Glass)
              if (_showMenu)
                LiquidGlassMenu(
                  onPlay: _startGame,
                  onVisitWebsite: () => launchUrl(Uri.parse('https://example.com')),
                ),

              // 3.5. GAME OVER LAYER
              if (_gameOver && _lastStats != null)
                GameOverMenu(
                    stats: _lastStats!,
                    onPlayAgain: _startGame,
                    onMainMenu: _goToMainMenu,
                    repository: _scoreRepository,
                ),

              // 4. DIALOG LAYER
              if (_activeStory != null)
                HeritageStoryDialog(
                  fact: _activeStory!, 
                  onDismiss: _dismissStory,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
