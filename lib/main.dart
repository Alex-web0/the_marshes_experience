import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'game/marshes_game.dart';
import 'ui/ui_layers.dart';
import 'ui/game_over_menu.dart';
import 'ui/team_page.dart';
import 'ui/pause_menu.dart';
import 'ui/mute_button.dart';
import 'data/heritage_repository.dart';
import 'data/score_repository.dart';
import 'data/audio_manager.dart';
import 'domain/game_stats.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioManager().initialize();
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
  bool _showTeamPage = false; // Team page state
  bool _showPauseMenu = false; // Pause menu state
  HeritageFact? _activeStory;
  int _score = 0;
  int _fishCount = 0;
  int _storyCount = 0; // Stories encountered counter
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
      onStoryCountUpdate: (s) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _storyCount = s);
        });
      },
      onPauseTriggered: _showPauseDialog,
    );

    // Start menu music after game loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _showMenu) {
          _game.playMenuMusic();
        }
      });
    });
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
      _showMenu =
          false; // We use GameOverMenu explicitly distinct from MainMenu if we want
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

  void _showPauseDialog() {
    setState(() {
      _showPauseMenu = true;
    });
  }

  void _handleResume() {
    setState(() {
      _showPauseMenu = false;
    });
    _game.resumeGameFromPause();
  }

  void _handleRestart() {
    setState(() {
      _showPauseMenu = false;
    });
    _startGame();
  }

  void _handlePauseToMenu() {
    setState(() {
      _showPauseMenu = false;
    });
    _goToMainMenu();
  }

  void _startGame() {
    _game.stopBackgroundMusic(); // Stop menu music
    setState(() {
      _showMenu = false;
      _gameOver = false;
      _lives = 3;
      _score = 0;
      _fishCount = 0;
      _storyCount = 0;
      _lastStats = null;
    });
    _game.startGame();
  }

  void _goToMainMenu() {
    _game.resetToMenu();
    _game.playMenuMusic(); // Start menu music
    setState(() {
      _gameOver = false;
      _showMenu = true;
      _showTeamPage = false;
      _lastStats = null;
    });
  }

  void _showTeam() {
    setState(() {
      _showTeamPage = true;
      _showMenu = false;
    });
  }

  void _hideTeam() {
    setState(() {
      _showTeamPage = false;
      _showMenu = true;
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
              if (!_showMenu && _activeStory == null && !_showPauseMenu)
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
                          Text("DIST: ${_score}m",
                              style: kGameFont.copyWith(fontSize: 20)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.set_meal,
                                  color: Colors.cyanAccent, size: 16),
                              const SizedBox(width: 4),
                              Text("$_fishCount",
                                  style: kGameFont.copyWith(
                                      fontSize: 16, color: Colors.cyanAccent)),
                              const SizedBox(width: 12),
                              const Icon(Icons.menu_book,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text("$_storyCount",
                                  style: kGameFont.copyWith(
                                      fontSize: 16, color: Colors.amber)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Lives indicator
                          ...List.generate(
                              3,
                              (index) => Icon(
                                    index < _lives
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.redAccent,
                                  )),
                          const SizedBox(width: 12),
                          // Pause button
                          GestureDetector(
                            onTap: () {
                              _game.playButtonSound();
                              _game.pauseGame();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                'assets/images/pause_button.png',
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

              // 3. MENU LAYER (Liquid Glass)
              if (_showMenu && !_showTeamPage)
                LiquidGlassMenu(
                  onPlay: _startGame,
                  onTeam: _showTeam,
                  onVisitWebsite: () =>
                      launchUrl(Uri.parse('https://heritage.alqaba.com')),
                  onButtonSound: _game.playButtonSound,
                ),

              // 3.1. MUTE BUTTON (Main Menu)
              if (_showMenu && !_showTeamPage)
                Positioned(
                  bottom: 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: MuteButton(
                      onButtonSound: _game.playButtonSound,
                    ),
                  ),
                ),

              // 3.4. TEAM PAGE
              if (_showTeamPage)
                TeamPage(
                  onBack: _hideTeam,
                  onButtonSound: _game.playButtonSound,
                ),

              // 3.5. GAME OVER LAYER
              if (_gameOver && _lastStats != null)
                GameOverMenu(
                  stats: _lastStats!,
                  onPlayAgain: _startGame,
                  onMainMenu: _goToMainMenu,
                  repository: _scoreRepository,
                  onButtonSound: _game.playButtonSound,
                ),

              // 3.6. PAUSE MENU LAYER
              if (_showPauseMenu)
                PauseMenu(
                  onResume: _handleResume,
                  onRestart: _handleRestart,
                  onMainMenu: _handlePauseToMenu,
                  onButtonSound: _game.playButtonSound,
                ),

              // 3.7. MUTE BUTTON (Pause Menu)
              if (_showPauseMenu)
                Positioned(
                  bottom: 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: MuteButton(
                      onButtonSound: _game.playButtonSound,
                    ),
                  ),
                ),

              // 4. DIALOG LAYER
              if (_activeStory != null)
                HeritageStoryDialog(
                  fact: _activeStory!,
                  onDismiss: _dismissStory,
                  onButtonSound: _game.playButtonSound,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
