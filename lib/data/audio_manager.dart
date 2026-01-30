import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  bool _isMuted = false;
  SharedPreferences? _prefs;

  // Stream controller for broadcasting mute state changes
  final StreamController<bool> _muteStateController =
      StreamController<bool>.broadcast();

  bool get isMuted => _isMuted;
  Stream<bool> get muteStateStream => _muteStateController.stream;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _isMuted = _prefs?.getBool('audio_muted') ?? false;
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _prefs?.setBool('audio_muted', _isMuted);
    _muteStateController.add(_isMuted);
  }

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    await _prefs?.setBool('audio_muted', _isMuted);
    _muteStateController.add(_isMuted);
  }

  void dispose() {
    _muteStateController.close();
  }
}
