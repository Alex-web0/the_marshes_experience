import 'package:firebase_core/firebase_core.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:the_marshes_experience/firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';
import 'game/marshes_game.dart';
import 'ui/ui_layers.dart';
import 'ui/game_over_menu.dart';
import 'ui/team_page.dart';
import 'ui/pause_menu.dart';
import 'ui/mute_button.dart';
import 'ui/multiplayer_page.dart';
import 'ui/debug_storyline_menu.dart';
import 'ui/storyline_dialog.dart';
import 'data/score_repository.dart';
import 'data/audio_manager.dart';
import 'data/storyline_repository.dart';
import 'data/storyline/local_storyline_provider.dart';
import 'domain/game_stats.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio manager
  await AudioManager().initialize();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize storyline repository with local data provider
  // This loads all story content in the background
  final storylineProvider = LocalStorylineProvider();
  await StorylineRepository().initialize(storylineProvider);

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
  bool _showMultiplayerPage = false; // Multiplayer page state
  bool _showPauseMenu = false; // Pause menu state
  bool _showDebugStorylineMenu = false; // Debug storyline menu state
  String? _activeStorylineId; // Active storyline being viewed
  bool _activeStorylineFromGame =
      false; // Track if storyline came from gameplay
  int _score = 0;
  int _fishCount = 0;
  int _storyCount = 0; // Stories encountered counter
  int _lives = 3;
  bool _gameOver = false;
  GameStats? _lastStats; // Store stats for game over
  final ScoreRepository _scoreRepository = LocalScoreRepository();
  final StorylineRepository _storylineRepository = StorylineRepository();

  @override
  void initState() {
    super.initState();

    // Storyline repository is already initialized in main()
    // No need to initialize again here

    _game = MarshesGame(
      onGameOver: _handleGameOver,
      onStorylineTriggered: _showGameStoryline,
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

  void _showMultiplayer() {
    setState(() {
      _showMultiplayerPage = true;
      _showMenu = false;
    });
  }

  void _hideMultiplayer() {
    setState(() {
      _showMultiplayerPage = false;
      _showMenu = true;
    });
  }

  void _showDebugStorylines() {
    setState(() {
      _showDebugStorylineMenu = true;
      _showMenu = false;
    });
  }

  void _hideDebugStorylines() {
    setState(() {
      _showDebugStorylineMenu = false;
      _showMenu = true;
    });
  }

  void _showStoryline(String storyId) {
    setState(() {
      _activeStorylineId = storyId;
      _activeStorylineFromGame = false;
      _showDebugStorylineMenu = false;
    });
  }

  void _showGameStoryline(String storyId) {
    setState(() {
      _activeStorylineId = storyId;
      _activeStorylineFromGame = true;
    });
  }

  void _closeStoryline() {
    final wasFromGame = _activeStorylineFromGame;
    setState(() {
      _activeStorylineId = null;
      _activeStorylineFromGame = false;
      if (!wasFromGame) {
        _showMenu = true;
      }
    });

    // Resume game if storyline was triggered during gameplay
    if (wasFromGame) {
      _game.resumeGame();
    }
  }

  void _handleStorylineRewards(Map<String, int>? rewards) {
    if (rewards == null) return;

    setState(() {
      if (rewards['score'] != null) {
        _score += rewards['score']!;
      }
      if (rewards['fishCount'] != null) {
        _fishCount += rewards['fishCount']!;
      }
      if (rewards['storyCount'] != null) {
        _storyCount += rewards['storyCount']!;
      }
    });

    // If storyline was from gameplay, also update game state
    if (_activeStorylineFromGame && rewards['storyCount'] != null) {
      _game.incrementStoryCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 19.5, // Mobile Aspect Ratio Constraint
          child: Stack(
            children: [
              // 1. GAME LAYER
              Focus(
                autofocus: true,
                child: GameWidget(game: _game),
              ),

              // 2. HUD LAYER (Only when playing)
              if (!_showMenu && !_showPauseMenu)
                Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("DIST: ${_score}m",
                                style: kGameFont.copyWith(fontSize: 20)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.set_meal,
                                    color: Colors.cyanAccent, size: 16),
                                const SizedBox(width: 4),
                                Text("$_fishCount",
                                    style: kGameFont.copyWith(
                                        fontSize: 16,
                                        color: Colors.cyanAccent)),
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
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                          const SizedBox(width: 8),
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

              // 2.5. On-screen Controls (Web/Desktop or if Gyro fails fallback)
              if (!_showMenu &&
                  !_showPauseMenu &&
                  (kIsWeb ||
                      defaultTargetPlatform == TargetPlatform.windows ||
                      defaultTargetPlatform == TargetPlatform.macOS ||
                      defaultTargetPlatform == TargetPlatform.linux))
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Button
                      GestureDetector(
                        onTapDown: (_) => _game.player.moveLeft(),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5)),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 30),
                        ),
                      ),
                      // Right Button
                      GestureDetector(
                        onTapDown: (_) => _game.player.moveRight(),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5)),
                          ),
                          child: const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 30),
                        ),
                      ),
                    ],
                  ),
                ),

              // 3. MENU LAYER (Liquid Glass)
              if (_showMenu && !_showTeamPage && !_showMultiplayerPage)
                LiquidGlassMenu(
                  onPlay: _startGame,
                  onMultiplayer: _showMultiplayer,
                  onTeam: _showTeam,
                  onVisitWebsite: () =>
                      launchUrl(Uri.parse('https://heritage.alqaba.com')),
                  onButtonSound: _game.playButtonSound,
                  onDebugStoryline: kDebugMode ? _showDebugStorylines : null,
                ),

              // 3.1. MUTE BUTTON (Main Menu)
              if (_showMenu && !_showTeamPage && !_showMultiplayerPage)
                Positioned(
                  bottom:
                      50, // Increased from 80 to avoid overlap on short screens
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SafeArea(
                      child: MuteButton(
                        onButtonSound: _game.playButtonSound,
                      ),
                    ),
                  ),
                ),

              // 3.4. TEAM PAGE
              if (_showTeamPage)
                TeamPage(
                  onBack: _hideTeam,
                  onButtonSound: _game.playButtonSound,
                ),

              // 3.45. MULTIPLAYER PAGE
              if (_showMultiplayerPage)
                MultiplayerPage(
                  onBack: _hideMultiplayer,
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
                  bottom:
                      140, // Increased from 80 to avoid overlap on short screens
                  left: 0,
                  right: 0,
                  child: Center(
                    child: MuteButton(
                      onButtonSound: _game.playButtonSound,
                    ),
                  ),
                ),

              // 4. DEBUG STORYLINE MENU
              if (_showDebugStorylineMenu)
                Center(
                  child: DebugStorylineMenu(
                    onStorySelected: _showStoryline,
                    onClose: _hideDebugStorylines,
                  ),
                ),

              // 5. ACTIVE STORYLINE DIALOG
              if (_activeStorylineId != null)
                Center(
                  child: StorylineDialog(
                    storyElementId: _activeStorylineId!,
                    onComplete: _closeStoryline,
                    onRewardsEarned: _handleStorylineRewards,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
