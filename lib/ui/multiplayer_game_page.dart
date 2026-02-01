import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/multiplayer_models.dart';
import '../domain/multiplayer_constants.dart';
import '../domain/game_status.dart';
import '../data/multiplayer_service.dart';
import '../game/multiplayer_marshes_game.dart';

class MultiplayerGamePage extends StatefulWidget {
  final MultiplayerGame gameData;

  const MultiplayerGamePage({super.key, required this.gameData});

  @override
  State<MultiplayerGamePage> createState() => _MultiplayerGamePageState();
}

class _MultiplayerGamePageState extends State<MultiplayerGamePage> {
  late MultiplayerMarshesGame _game;
  final ValueNotifier<double> _speedNotifier = ValueNotifier(300.0);
  final ValueNotifier<int> _hazardCooldownNotifier = ValueNotifier(0);
  final ValueNotifier<MultiplayerGame?> _gameStateNotifier =
      ValueNotifier(null);
  Timer? _cooldownTimer;
  StreamSubscription? _gameStatusSubscription;

  @override
  void initState() {
    super.initState();
    _game = MultiplayerMarshesGame(
      initialGameData: widget.gameData,
      onSpeedUpdate: (speed) {
        // Only update if changed meaningfully to reduce redraws
        if ((_speedNotifier.value - speed).abs() > 1.0) {
          _speedNotifier.value = speed;
        }
      },
      onHazardDropped: () {
        _hazardCooldownNotifier.value = 9;
        _cooldownTimer?.cancel();
        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_hazardCooldownNotifier.value > 0) {
            _hazardCooldownNotifier.value -= 1;
          } else {
            timer.cancel();
          }
        });
      },
    );

    // Initialize notifier with initial data
    _gameStateNotifier.value = widget.gameData;

    // Listen for game status changes
    final service = MultiplayerService();
    _gameStatusSubscription =
        service.watchGame(widget.gameData.gameId).listen((gameData) {
      if (mounted) {
        _gameStateNotifier.value = gameData;
      }

      if (gameData?.status == GameStatus.ended && mounted) {
        // Game ended, navigate back to show results
        // Use post-frame callback to avoid navigator lock issues
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
        _gameStatusSubscription?.cancel();
      }
    });
  }

  final ValueNotifier<bool> _leftPressed = ValueNotifier(false);
  final ValueNotifier<bool> _rightPressed = ValueNotifier(false);

  @override
  void dispose() {
    _speedNotifier.dispose();
    _hazardCooldownNotifier.dispose();
    _gameStateNotifier.dispose();
    _leftPressed.dispose();
    _rightPressed.dispose();
    _cooldownTimer?.cancel();
    _gameStatusSubscription?.cancel();
    super.dispose();
  }

  void _onDropHazard() {
    _game.dropHazard();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyW ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _game.boostSpeed();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyS ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_hazardCooldownNotifier.value == 0) _onDropHazard();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _game.player.moveLeft();
        _leftPressed.value = true;
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _game.player.moveRight();
        _rightPressed.value = true;
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _leftPressed.value = false;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _rightPressed.value = false;
      }
    }
    return KeyEventResult.ignored;
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('GAME PAUSED',
                  style: GoogleFonts.alexandria(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [
                    const Icon(Icons.people, color: Colors.white70),
                    Text(
                        '${widget.gameData.players.length}/${MultiplayerConstants.kMaxPlayers}',
                        style: GoogleFonts.pixelifySans(
                            color: Colors.white, fontSize: 16)),
                  ]),
                  Column(children: [
                    const Icon(Icons.show_chart, color: Colors.cyanAccent),
                    Text('${_game.localDistanceTraveled.toInt()}m',
                        style: GoogleFonts.pixelifySans(
                            color: Colors.white, fontSize: 16)),
                  ]),
                ],
              ),
              const SizedBox(height: 30),
              // Buttons
              _dialogButton('CONTROLS', Colors.blueAccent, () {
                _showControlsDialog(context);
              }),
              const SizedBox(height: 10),
              _dialogButton(
                  'RESUME', Colors.green, () => Navigator.of(ctx).pop()),
              const SizedBox(height: 10),
              _dialogButton('MAIN MENU', Colors.red, () async {
                Navigator.of(ctx).pop(); // Close dialog
                // Stop game music before leaving
                FlameAudio.bgm.stop();
                FlameAudio.bgm.audioPlayer.setPlaybackRate(1.0);
                FlameAudio.bgm.audioPlayer.setVolume(0.5);
                await MultiplayerService().leaveGame();
                if (mounted) {
                  Navigator.of(context).pop('main_menu');
                }
              }),
              const SizedBox(height: 10),
              _dialogButton('LEAVE GAME', Colors.orangeAccent, () async {
                Navigator.of(ctx).pop(); // Close dialog
                // Stop game music before leaving
                FlameAudio.bgm.stop();
                FlameAudio.bgm.audioPlayer.setPlaybackRate(1.0);
                FlameAudio.bgm.audioPlayer.setVolume(0.5);
                await MultiplayerService().leaveGame();
                if (mounted) {
                  Navigator.of(context)
                      .pop('leave'); // Return to lobby with 'leave' signal
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogButton(String text, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onTap,
        child: Text(text,
            style: GoogleFonts.alexandria(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showControlsDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Controls',
      barrierColor: Colors.black54, // Overlay on top of pause menu
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(), // Unused
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.elasticOut);
        return ScaleTransition(
          scale: curve,
          child: AlertDialog(
            backgroundColor: Colors.black.withOpacity(0.95),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.blueAccent, width: 2)),
            title: Text('CONTROLS',
                textAlign: TextAlign.center,
                style: GoogleFonts.pixelifySans(
                    color: Colors.blueAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildKeyRow('W / UP', 'BOOST SPEED'),
                const SizedBox(height: 15),
                _buildKeyRow('A / LEFT', 'MOVE LEFT'),
                const SizedBox(height: 15),
                _buildKeyRow('D / RIGHT', 'MOVE RIGHT'),
                const SizedBox(height: 15),
                _buildKeyRow('S / DOWN', 'DROP HAZARD'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('CLOSE',
                    style: GoogleFonts.alexandria(color: Colors.white)),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeyRow(String keys, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(keys,
              style: GoogleFonts.pixelifySans(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        Text(action,
            style:
                GoogleFonts.alexandria(color: Colors.cyanAccent, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Stack(
          children: [
            // 1. The Game
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 768),
                child: GameWidget(game: _game),
              ),
            ),

            // 2. HUD
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.5),
                            width: 1.5),
                      ),
                      child: ValueListenableBuilder<MultiplayerGame?>(
                        valueListenable: _gameStateNotifier,
                        builder: (context, gameState, _) {
                          // Calculate Ranks
                          int myRank = 0;
                          String topPlayerName = '-';
                          int myFish = 0;

                          if (gameState != null) {
                            final players = gameState.players.values.toList();
                            players.sort((a, b) => b.score.compareTo(a.score));

                            final myId = MultiplayerService().currentPlayerId;
                            final myIndex =
                                players.indexWhere((p) => p.playerId == myId);
                            if (myIndex >= 0) {
                              myRank = myIndex + 1;
                              myFish = players[myIndex].fishCount;
                            }

                            if (players.isNotEmpty) {
                              final top = players.first;
                              topPlayerName = top.name.length > 5
                                  ? top.name.substring(0, 5)
                                  : top.name;
                            }
                          }

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ValueListenableBuilder<double>(
                                valueListenable: _speedNotifier,
                                builder: (context, speed, _) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 1. MY RANK (Compact)
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('RANK',
                                              style: GoogleFonts.alexandria(
                                                  fontSize: 10,
                                                  color: Colors.white60)),
                                          Text('#$myRank',
                                              style: GoogleFonts.alexandria(
                                                  fontSize: 18,
                                                  color: Colors.amber,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                          width: 1,
                                          height: 25,
                                          color: Colors.white24),
                                      const SizedBox(width: 10),

                                      // 2. TOP RANK (Compact)
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('TOP',
                                              style: GoogleFonts.alexandria(
                                                  fontSize: 10,
                                                  color: Colors.white60)),
                                          Text(topPlayerName,
                                              style: GoogleFonts.pixelifySans(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                          width: 1,
                                          height: 25,
                                          color: Colors.white24),
                                      const SizedBox(width: 10),

                                      // 3. SPEED (Middle)
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('SPEED',
                                              style: GoogleFonts.alexandria(
                                                  fontSize: 10,
                                                  color: Colors.white60)),
                                          Text('${speed.toInt()}',
                                              style: GoogleFonts.alexandria(
                                                  fontSize: 18,
                                                  color: speed > 800
                                                      ? Colors.redAccent
                                                      : Colors.cyanAccent,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                          width: 1,
                                          height: 25,
                                          color: Colors.white24),
                                      const SizedBox(width: 10),

                                      // 4. DIST
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('DIST',
                                              style: GoogleFonts.alexandria(
                                                  fontSize: 10,
                                                  color: Colors.white60)),
                                          Text(
                                              '${_game.localDistanceTraveled.toInt()}m',
                                              style: GoogleFonts.alexandria(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Secondary Pill: Fish
                    ValueListenableBuilder<MultiplayerGame?>(
                      valueListenable: _gameStateNotifier,
                      builder: (context, gameState, _) {
                        int myFish = 0;
                        if (gameState != null) {
                          final myId = MultiplayerService().currentPlayerId;
                          final players = gameState.players.values.toList();
                          final myIndex =
                              players.indexWhere((p) => p.playerId == myId);
                          if (myIndex >= 0) {
                            myFish = players[myIndex].fishCount;
                          }
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.orangeAccent.withOpacity(0.5),
                                width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.set_meal,
                                  color: Colors.orangeAccent, size: 14),
                              const SizedBox(width: 5),
                              Text('$myFish',
                                  style: GoogleFonts.alexandria(
                                      fontSize: 14,
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 3. Boost Button (Yellow/Amber, Flashy)
            Positioned(
              left: 30,
              bottom: 50,
              child: GestureDetector(
                onTap: () {
                  _game.boostSpeed();
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600.withOpacity(0.9),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.yellowAccent, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child:
                      const Icon(Icons.rowing, color: Colors.white, size: 40),
                ),
              ),
            ),

            // 4. Drop Hazard Button (Smaller)
            Positioned(
              left: 120,
              bottom: 60,
              child: ValueListenableBuilder<int>(
                  valueListenable: _hazardCooldownNotifier,
                  builder: (context, cooldown, _) {
                    final bool isReady = cooldown == 0;
                    return GestureDetector(
                      onTap: isReady ? _onDropHazard : null,
                      child: Container(
                        width: 50, // Smaller
                        height: 50,
                        decoration: BoxDecoration(
                          color: isReady
                              ? Colors.redAccent.withOpacity(0.9)
                              : Colors.grey.withOpacity(0.6),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.red.shade100, width: 2),
                          boxShadow: [
                            if (isReady)
                              BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 10),
                          ],
                        ),
                        child: Center(
                          child: isReady
                              ? const Icon(Icons.dangerous,
                                  color: Colors.white, size: 24)
                              : Text('$cooldown',
                                  style: GoogleFonts.pixelifySans(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  }),
            ),

            // 5. Steering Controls (Split Circle)
            Positioned(
              right: 30,
              bottom: 50,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.3),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Row(
                  children: [
                    // Left Half
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                          valueListenable: _leftPressed,
                          builder: (context, pressed, _) {
                            return GestureDetector(
                              onTap: () {
                                _game.player.moveLeft();
                                // Visual feedback handled by tap, but boolean for key press sync
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: pressed
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(60)),
                                ),
                                child: const Center(
                                    child: Icon(Icons.arrow_back_ios,
                                        color: Colors.white70)),
                              ),
                            );
                          }),
                    ),
                    // Right Half
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                          valueListenable: _rightPressed,
                          builder: (context, pressed, _) {
                            return GestureDetector(
                              onTap: () {
                                _game.player.moveRight();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: pressed
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(60)),
                                ),
                                child: const Center(
                                    child: Icon(Icons.arrow_forward_ios,
                                        color: Colors.white70)),
                              ),
                            );
                          }),
                    ),
                  ],
                ),
              ),
            ),

            // 6. Exit Button (With Dialog)
            Positioned(
              top: 50,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _showExitDialog,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
