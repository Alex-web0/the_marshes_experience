import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/multiplayer_service.dart';
import '../domain/multiplayer_models.dart';
import '../domain/game_status.dart';
import '../domain/multiplayer_constants.dart';
import 'multiplayer_game_page.dart';

class MultiplayerPage extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onButtonSound;

  const MultiplayerPage({
    super.key,
    required this.onBack,
    this.onButtonSound,
  });

  @override
  State<MultiplayerPage> createState() => _MultiplayerPageState();
}

class _MultiplayerPageState extends State<MultiplayerPage> {
  final MultiplayerService _service = MultiplayerService();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  MultiplayerGame? _currentGame;
  String _status = 'idle'; // idle, loading, waiting, queued, error
  String _errorMessage = '';
  bool _isCreator = false;
  StreamSubscription? _gameSubscription;

  @override
  void initState() {
    super.initState();
    _nameController.text =
        'Player${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _navigateToGame(MultiplayerGame game) {
    if (_status == 'playing') return; // Already navigated

    // Set status to playing to avoid re-triggering
    setState(() {
      _status = 'playing';
    });

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => MultiplayerGamePage(gameData: game),
      ),
    )
        .then((result) {
      if (result == 'main_menu') {
        widget.onBack();
        return;
      }

      // Handle explicit leave from game (pause menu -> leave game)
      // The user wants to "leave" playing but see the end screen / lobby,
      // but strictly speaking 'leaving' in multiplayer usually means disconnect.
      // However, the request says "reset multiplayer game as now it is rejoining".
      // We will attempt to fetch the game again to see the updated state (where this player might be offline).

      if (mounted) {
        setState(() {
          // If the game ended, we want to show the end screen or lobby, so we just clear 'playing'
          // The specific state shown will depend on _currentGame?.status in _buildContent
          if (_currentGame?.status == GameStatus.ended) {
            _status = 'ended';
          } else {
            // If we returned with 'leave', we effectively left the "playing" state.
            // If the game is still running, we might want to show lobby or just go back to idle.
            // But the user requested "reset multiplayer game as now it is rejoining automatically".
            // If we actually left the game in DB, we are no longer a player.
            // So we should probably go back to 'idle' or try to re-join if that's the intention?
            // "reset multiplayer game as now it is rejoining autmatically after kleave if the queue is full" - this is slightly ambiguous.
            // Assuming it means: If I leave, I should be taken back to the multiplayer menu (idle) or lobby.
            // If I actually CALLED leaveGame(), I am removed.

            if (result == 'leave') {
              // We fully left.
              _status = 'idle';
              _currentGame = null;
              _isCreator = false;
            } else {
              _status = _isCreator ? 'waiting' : 'queued';
            }
          }
        });
      }
    });
  }

  String _generateCode() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed ambiguous chars (0, O, 1, I, L)
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  void _createGame() {
    final playerName = _nameController.text.trim();
    if (playerName.isEmpty) {
      setState(() {
        _status = 'error';
        _errorMessage = 'Please enter a player name';
      });
      return;
    }
    _showCreateGameDialog(playerName);
  }

  void _showCreateGameDialog(String playerName) {
    _codeController.text = _generateCode();
    // Default race length
    RaceLength selectedLength = RaceLength.short;
    // Default max players from constants
    int selectedMaxPlayers = MultiplayerConstants.kMaxPlayers;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.black.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.cyanAccent, width: 2),
            ),
            title: Text('CREATE GAME',
                style: GoogleFonts.alexandria(
                    color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CODE:',
                          style: GoogleFonts.alexandria(
                              color: Colors.white70, fontSize: 14)),
                      Text(_codeController.text,
                          style: GoogleFonts.pixelifySans(
                              color: Colors.orangeAccent,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                      IconButton(
                        icon: const Icon(Icons.refresh,
                            color: Colors.cyanAccent, size: 20),
                        onPressed: () {
                          setStateDialog(() {
                            _codeController.text = _generateCode();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text('RACE LENGTH',
                    style: GoogleFonts.alexandria(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 5),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: RaceLength.values.map((length) {
                      final isSelected = selectedLength == length;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              selectedLength = length;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.cyanAccent.withOpacity(0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: Colors.cyanAccent)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  length.label.split(' ').first,
                                  style: GoogleFonts.alexandria(
                                    color: isSelected
                                        ? Colors.cyanAccent
                                        : Colors.white60,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "${length.distance}m",
                                  style: GoogleFonts.alexandria(
                                    color: isSelected
                                        ? Colors.cyanAccent.withOpacity(0.7)
                                        : Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 15),
                Text('MAX PLAYERS',
                    style: GoogleFonts.alexandria(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 5),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [2, 4, 16, 32].map((count) {
                      final isSelected = selectedMaxPlayers == count;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              selectedMaxPlayers = count;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orangeAccent.withOpacity(0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: Colors.orangeAccent)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '$count',
                                style: GoogleFonts.alexandria(
                                  color: isSelected
                                      ? Colors.orangeAccent
                                      : Colors.white60,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL',
                    style: GoogleFonts.alexandria(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                  side: const BorderSide(color: Colors.cyanAccent),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _performCreateGame(
                    playerName,
                    _codeController.text,
                    selectedLength,
                    selectedMaxPlayers,
                  );
                },
                child: Text('CREATE',
                    style: GoogleFonts.alexandria(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performCreateGame(
      String name, String code, RaceLength raceLength, int maxPlayers) async {
    widget.onButtonSound?.call();
    setState(() {
      _status = 'loading';
      _errorMessage = '';
    });

    try {
      final game = await _service.createGame(
        name: name,
        code: code,
        raceLength: raceLength,
        maxPlayers: maxPlayers,
      );
      setState(() {
        _currentGame = game;
        _status = 'waiting';
        _isCreator = true;
      });

      // Listen to game updates
      _gameSubscription?.cancel();
      _gameSubscription = _service.watchGame(game.gameId).listen((updatedGame) {
        if (!mounted) return;

        if (updatedGame == null) {
          setState(() {
            _status = 'idle';
            _currentGame = null;
            _isCreator = false;
          });
          return;
        }

        // Handle restart/migration
        if (updatedGame.status == GameStatus.restarted ||
            updatedGame.nextGameId != null) {
          final nextId = updatedGame.nextGameId;
          if (nextId == null) {
            // Fallback if no ID is provided
            setState(() {
              _status = 'idle';
              _currentGame = null;
              _isCreator = false;
            });
            return;
          }

          _service.switchToGame(nextId);
          // Re-subscribe to the new game
          _gameSubscription?.cancel();

          _gameSubscription = _service.watchGame(nextId).listen((newGame) {
            if (!mounted) return;

            if (newGame == null) {
              // New game not found (e.g. failed creation)
              setState(() {
                _status = 'idle';
                _currentGame = null;
                _isCreator = false;
              });
              return;
            }

            final bool amCreator =
                newGame.creatorId == _service.currentPlayerId;
            setState(() {
              _currentGame = newGame;
              _isCreator = amCreator;
              if (newGame.status != GameStatus.playing) {
                _status = _isCreator ? 'waiting' : 'queued';
              }
            });

            if (newGame.status == GameStatus.playing) {
              _navigateToGame(newGame);
            }
          });
          return;
        }

        setState(() {
          _currentGame = updatedGame;
          // If we are ended, we stay ended until user leaves or restarts.
          // But if we are playing, navigate.
          if (updatedGame.status == GameStatus.playing) {
            _navigateToGame(updatedGame);
          }
        });
      });
    } catch (e) {
      setState(() {
        _status = 'error';
        _errorMessage = 'Failed to create game: $e';
      });

      debugPrint(e.toString());
    }
  }

  Future<void> _joinGame() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() {
        _status = 'error';
        _errorMessage = 'Please enter a game code';
      });
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _status = 'error';
        _errorMessage = 'Please enter a player name';
      });
      return;
    }

    widget.onButtonSound?.call();
    setState(() {
      _status = 'loading';
      _errorMessage = '';
    });

    try {
      final game = await _service.joinGame(
        _codeController.text.trim(),
        _nameController.text.trim(),
      );

      if (game == null) {
        setState(() {
          _status = 'error';
          _errorMessage = 'Game not found or full';
        });
        return;
      }

      setState(() {
        _currentGame = game;
        _status = 'queued';
        _isCreator = false;
      });

      // Listen to game updates
      _gameSubscription?.cancel();
      _gameSubscription = _service.watchGame(game.gameId).listen((updatedGame) {
        if (!mounted) return;

        if (updatedGame == null) {
          // Game ended or cancelled
          setState(() {
            _status = 'idle';
            _currentGame = null;
            _isCreator = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Game ended', style: GoogleFonts.alexandria()),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        // Handle restart/migration
        if (updatedGame.status == GameStatus.restarted ||
            updatedGame.nextGameId != null) {
          final nextId = updatedGame.nextGameId;
          if (nextId == null) {
            setState(() {
              _status = 'idle';
              _currentGame = null;
              _isCreator = false;
            });
            return;
          }

          _service.switchToGame(nextId);
          _gameSubscription?.cancel();

          _gameSubscription = _service.watchGame(nextId).listen((newGame) {
            if (!mounted) return;

            if (newGame == null) {
              setState(() {
                _status = 'idle';
                _currentGame = null;
                _isCreator = false;
              });
              return;
            }

            final bool amCreator =
                newGame.creatorId == _service.currentPlayerId;
            setState(() {
              _currentGame = newGame;
              _isCreator = amCreator;
              if (newGame.status != GameStatus.playing) {
                _status = _isCreator ? 'waiting' : 'queued';
              }
            });

            if (newGame.status == GameStatus.playing) {
              _navigateToGame(newGame);
            }
          });
          return;
        }

        setState(() {
          _currentGame = updatedGame;
          if (updatedGame.status == GameStatus.playing) {
            _navigateToGame(updatedGame);
          }
        });
      });
    } catch (e) {
      setState(() {
        _status = 'error';
        _errorMessage = 'Failed to join game: $e';
      });
    }
  }

  Future<void> _leaveGame() async {
    widget.onButtonSound?.call();

    // If creator and in waiting/queued state, cancel the game for everyone
    if (_isCreator && (_status == 'waiting' || _status == 'queued')) {
      await _service.cancelGame();
    } else {
      // Otherwise just leave normally
      await _service.leaveGame();
    }

    _gameSubscription?.cancel();
    _gameSubscription = null;

    if (mounted) {
      setState(() {
        _status = 'idle';
        _currentGame = null;
        _isCreator = false;
      });
    }
  }

  Future<void> _startGame() async {
    if (_currentGame == null || !_isCreator) return;
    widget.onButtonSound?.call();
    await _service.startGame();
  }

  void _copyCode() {
    if (_currentGame != null) {
      Clipboard.setData(ClipboardData(text: _currentGame!.code));
      widget.onButtonSound?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Code copied: ${_currentGame!.code}',
              style: GoogleFonts.alexandria()),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.withOpacity(0.8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Resize to avoid keyboard overlay
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a3a2e),
              Color(0xFF0d1f1a),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        widget.onButtonSound?.call();
                        if (_status == 'waiting' || _status == 'queued') {
                          _leaveGame();
                        } else {
                          widget.onBack();
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'MULTIPLAYER',
                      style: GoogleFonts.pixelifySans(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_status == 'idle' || _status == 'error') {
      return _buildIdleState();
    } else if (_status == 'loading') {
      return _buildLoadingState();
    } else if (_currentGame?.status == GameStatus.ended) {
      return _buildEndedState();
    } else if (_status == 'waiting') {
      return _buildWaitingState();
    } else if (_status == 'queued') {
      return _buildQueuedState();
    }
    return Center(
      child: Text(
        "Status: $_status",
        style: GoogleFonts.pixelifySans(color: Colors.white54),
      ),
    );
  }

  Widget _buildEndedState() {
    final winnerId = _currentGame?.winnerId;
    final winnerName = _currentGame?.players[winnerId]?.name ?? 'Unknown';
    final players = _currentGame?.players.values.toList() ?? [];
    // Sort by distance (score) descending
    players.sort((a, b) => b.score.compareTo(a.score));

    final top3 = players.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('GAME OVER',
              style: GoogleFonts.pixelifySans(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('WINNER: $winnerName',
              style: GoogleFonts.alexandria(
                  fontSize: 24,
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),

          // Top 3 Visuals could be added here (e.g. podiums)
          // For now, simple list

          Text('LEADERBOARD',
              style: GoogleFonts.alexandria(
                  color: Colors.white70, letterSpacing: 2)),
          const SizedBox(height: 10),
          ...top3.asMap().entries.map((entry) {
            final index = entry.key;
            final p = entry.value;
            Color color = index == 0
                ? Colors.amber
                : (index == 1 ? Colors.grey.shade300 : Colors.brown.shade300);
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: color),
                  const SizedBox(width: 10),
                  Text('${index + 1}. ${p.name}',
                      style: GoogleFonts.pixelifySans(
                          color: Colors.white, fontSize: 18)),
                  const Spacer(),
                  Text('${p.score}m',
                      style: GoogleFonts.pixelifySans(
                          color: Colors.cyanAccent, fontSize: 18)),
                ],
              ),
            );
          }),

          const SizedBox(height: 30),
          Text('ALL PLAYERS',
              style: GoogleFonts.alexandria(color: Colors.white70)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                // Table Header
                Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text("Name",
                            style: GoogleFonts.alexandria(
                                color: Colors.grey, fontSize: 12))),
                    Expanded(
                        child: Text("Dist",
                            style: GoogleFonts.alexandria(
                                color: Colors.grey, fontSize: 12))),
                    Expanded(
                        child: Text("Fish",
                            style: GoogleFonts.alexandria(
                                color: Colors.grey, fontSize: 12))),
                    Expanded(
                        child: Text("Hits",
                            style: GoogleFonts.alexandria(
                                color: Colors.grey, fontSize: 12))),
                  ],
                ),
                const Divider(color: Colors.white24),
                ...players.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: Text(p.name,
                                  style: GoogleFonts.pixelifySans(
                                      color: p.isOnline
                                          ? Colors.white
                                          : Colors.redAccent
                                              .withOpacity(0.7)))),
                          Expanded(
                              child: Text('${p.score}',
                                  style: GoogleFonts.alexandria(
                                      color: Colors.cyanAccent))),
                          Expanded(
                              child: Text('${p.fishCount}',
                                  style: GoogleFonts.alexandria(
                                      color: Colors.orangeAccent))),
                          Expanded(
                              child: Text('${p.obstaclesHit}',
                                  style: GoogleFonts.alexandria(
                                      color: Colors.redAccent))),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 30),
          if (_isCreator)
            _buildActionButton(
              label: 'PLAY AGAIN / RESTART',
              icon: Icons.replay,
              onPressed: () {
                _service.duplicateGame();
              },
              color: Colors.greenAccent,
            ),
          const SizedBox(height: 10),
          _buildActionButton(
            label: 'LEAVE GAME',
            icon: Icons.exit_to_app,
            onPressed: _leaveGame,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Player name input
          _buildInputField(
            controller: _nameController,
            label: 'Player Name',
            hint: 'Enter your name',
            icon: Icons.person,
          ),
          const SizedBox(height: 20),

          // Join game section
          _buildInputField(
            controller: _codeController,
            label: 'Game Code',
            hint: 'Enter 6-character code',
            icon: Icons.tag,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            forceUppercase: true,
          ),
          const SizedBox(height: 15),

          // Error message
          if (_status == 'error')
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                _errorMessage,
                style: GoogleFonts.pixelifySans(
                  color: Colors.redAccent,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Join button
          _buildActionButton(
            label: 'JOIN GAME',
            icon: Icons.login,
            onPressed: _joinGame,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 30),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'OR',
                  style: GoogleFonts.pixelifySans(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
            ],
          ),
          const SizedBox(height: 30),

          // Create game button
          _buildActionButton(
            label: 'CREATE GAME',
            icon: Icons.add_circle,
            onPressed: _createGame,
            color: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading...',
            style: GoogleFonts.pixelifySans(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Game code display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.cyanAccent, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'GAME CODE',
                  style: GoogleFonts.alexandria(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _copyCode,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentGame?.code ?? '',
                        style: GoogleFonts.alexandria(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                          letterSpacing: 2, // Reuced spacing for Alexandria
                        ),
                      ),
                      const SizedBox(width: 15),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: _copyCode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Waiting for players...',
                  style: GoogleFonts.pixelifySans(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Player count
          Text(
            '${_currentGame?.players.length ?? 0} / ${_currentGame?.maxPlayers ?? MultiplayerConstants.kMaxPlayers} Players',
            style: GoogleFonts.alexandria(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Player list
          _buildPlayerList(),
          const SizedBox(height: 30),

          // Action buttons
          if (_isCreator && (_currentGame?.currentPlayers ?? 0) >= 2)
            _buildActionButton(
              label: 'START GAME',
              icon: Icons.play_arrow,
              onPressed: _startGame,
              color: Colors.greenAccent,
            ),
          const SizedBox(height: 15),
          _buildActionButton(
            label: 'LEAVE GAME',
            icon: Icons.exit_to_app,
            onPressed: _leaveGame,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildQueuedState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: Column(
              children: [
                const Icon(Icons.people, color: Colors.amber, size: 48),
                const SizedBox(height: 15),
                Text(
                  _currentGame?.status == GameStatus.playing
                      ? 'GAME STARTED!'
                      : 'IN QUEUE',
                  style: GoogleFonts.pixelifySans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _currentGame?.status == GameStatus.playing
                      ? 'Get ready to play!'
                      : 'Waiting for game to start...',
                  style: GoogleFonts.pixelifySans(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Player count
          Text(
            '${_currentGame?.players.length ?? 0} / ${_currentGame?.maxPlayers ?? MultiplayerConstants.kMaxPlayers} Players',
            style: GoogleFonts.pixelifySans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Player list
          _buildPlayerList(),
          const SizedBox(height: 30),

          // Leave button
          _buildActionButton(
            label: 'LEAVE GAME',
            icon: Icons.exit_to_app,
            onPressed: _leaveGame,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList() {
    if (_currentGame == null) return Container();

    final players = _currentGame!.players.values.toList()
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

    return Column(
      children: players.map((player) {
        final isCurrentPlayer = player.playerId == _service.currentPlayerId;
        final isCreator = player.playerId == _currentGame!.creatorId;
        final isOnline = player.isOnline;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: !isOnline
                  ? [Colors.grey.withOpacity(0.2), Colors.grey.withOpacity(0.1)]
                  : isCurrentPlayer
                      ? [
                          Colors.cyanAccent.withOpacity(0.3),
                          Colors.blueAccent.withOpacity(0.2)
                        ]
                      : [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05)
                        ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: !isOnline
                  ? Colors.grey.withOpacity(0.3)
                  : isCurrentPlayer
                      ? Colors.cyanAccent
                      : Colors.white.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCreator ? Icons.star : Icons.person,
                color: !isOnline
                    ? Colors.grey
                    : isCreator
                        ? Colors.amber
                        : Colors.white70,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          player.name,
                          style: GoogleFonts.pixelifySans(
                            fontSize: 16,
                            color: isOnline ? Colors.white : Colors.grey,
                            fontWeight: isCurrentPlayer
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (isCurrentPlayer)
                          Text(' (You)',
                              style: GoogleFonts.pixelifySans(
                                  fontSize: 12, color: Colors.cyanAccent)),
                      ],
                    ),
                    if (isCreator)
                      Text('LEADER',
                          style: GoogleFonts.alexandria(
                              fontSize: 10,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                  ],
                ),
              ),
              if (!isOnline)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'OFFLINE',
                    style: GoogleFonts.pixelifySans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                    ),
                  ),
                )
              else if (player.isReady)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'READY',
                    style: GoogleFonts.pixelifySans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool forceUppercase = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.pixelifySans(
            fontSize: 16,
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
          ),
          child: TextField(
            controller: controller,
            maxLength: maxLength,
            textCapitalization: textCapitalization,
            inputFormatters: forceUppercase
                ? [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return newValue.copyWith(
                          text: newValue.text.toUpperCase());
                    })
                  ]
                : null,
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.pixelifySans(
                color: Colors.white38,
              ),
              prefixIcon: Icon(icon, color: Colors.white70),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.black),
        label: Text(
          label,
          style: GoogleFonts.pixelifySans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
