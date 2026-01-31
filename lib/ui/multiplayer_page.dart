import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/multiplayer_service.dart';
import '../domain/multiplayer_models.dart';
import '../domain/game_status.dart';
import '../domain/multiplayer_constants.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController.text =
        'Player${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
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
      final game = await _service.createGame(_nameController.text.trim());
      setState(() {
        _currentGame = game;
        _status = 'waiting';
        _isCreator = true;
      });

      // Listen to game updates
      _service.watchGame(game.gameId).listen((updatedGame) {
        if (mounted && updatedGame != null) {
          setState(() {
            _currentGame = updatedGame;
            if (updatedGame.status == GameStatus.playing) {
              _status = 'queued';
            }
          });
        }
      });
    } catch (e) {
      setState(() {
        _status = 'error';
        _errorMessage = 'Failed to create game: $e';
      });
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
      _service.watchGame(game.gameId).listen((updatedGame) {
        if (mounted && updatedGame != null) {
          setState(() {
            _currentGame = updatedGame;
            if (updatedGame.status == GameStatus.playing) {
              _status = 'queued';
            }
          });
        }
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
    await _service.leaveGame();
    setState(() {
      _currentGame = null;
      _status = 'idle';
      _isCreator = false;
      _codeController.clear();
    });
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
              style: GoogleFonts.pixelifySans()),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.withOpacity(0.8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      }
                      widget.onBack();
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
    );
  }

  Widget _buildContent() {
    if (_status == 'idle' || _status == 'error') {
      return _buildIdleState();
    } else if (_status == 'loading') {
      return _buildLoadingState();
    } else if (_status == 'waiting') {
      return _buildWaitingState();
    } else if (_status == 'queued') {
      return _buildQueuedState();
    }
    return Container();
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
            hint: 'Enter 6-digit code',
            icon: Icons.tag,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
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
                  style: GoogleFonts.pixelifySans(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentGame?.code ?? '',
                      style: GoogleFonts.pixelifySans(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(width: 15),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      onPressed: _copyCode,
                    ),
                  ],
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
            '${_currentGame?.currentPlayers ?? 0} / ${_currentGame?.maxPlayers ?? kMaxPlayers} Players',
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
            '${_currentGame?.currentPlayers ?? 0} / ${_currentGame?.maxPlayers ?? kMaxPlayers} Players',
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

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCurrentPlayer
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
              color: isCurrentPlayer
                  ? Colors.cyanAccent
                  : Colors.white.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCreator ? Icons.star : Icons.person,
                color: isCreator ? Colors.amber : Colors.white70,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  player.name,
                  style: GoogleFonts.pixelifySans(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight:
                        isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (player.isReady)
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
