import 'package:flutter/material.dart';
import '../data/audio_manager.dart';

class MuteButton extends StatefulWidget {
  final VoidCallback? onButtonSound;

  const MuteButton({super.key, this.onButtonSound});

  @override
  State<MuteButton> createState() => _MuteButtonState();
}

class _MuteButtonState extends State<MuteButton> {
  final AudioManager _audioManager = AudioManager();

  void _toggleMute() {
    // Play sound before toggling (if currently unmuted)
    if (!_audioManager.isMuted) {
      widget.onButtonSound?.call();
    }

    _audioManager.toggleMute();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _audioManager.muteStateStream,
      initialData: _audioManager.isMuted,
      builder: (context, snapshot) {
        final isMuted = snapshot.data ?? _audioManager.isMuted;

        return GestureDetector(
          onTap: _toggleMute,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Image.asset(
              !isMuted
                  ? 'assets/images/unmute_button.png'
                  : 'assets/images/mute_button.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}
