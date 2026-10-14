import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  late final AudioPlayer _player;
  late final AudioSession _session;
  bool _initialized = false;
  bool _usedFallback = false;

  bool consumeFallbackWarning() {
    final used = _usedFallback;
    _usedFallback = false;
    return used;
  }

  Future<void> initialize() async {
    _player = AudioPlayer();
    _session = await AudioSession.instance;
    await _session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        androidAudioAttributes: AndroidAudioAttributes(
          usage: AndroidAudioUsage.alarm,
          contentType: AndroidAudioContentType.sonification,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );
    _initialized = true;
  }

  Future<void> playAlarmSound(String assetPath, {bool loop = true}) async {
    try {
      await _player.setAsset(assetPath);
      await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      await _player.play();
    } on Exception {
      if (assetPath == 'assets/sounds/default_alarm.mp3') return;
      _usedFallback = true;
      try {
        await _player.setAsset('assets/sounds/default_alarm.mp3');
        await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
        await _player.play();
      } on Exception {
        _usedFallback = true;
      }
    }
  }

  Future<void> stopAlarmSound() async {
    if (!_initialized) return;
    await _player.stop();
    await _player.dispose();
    _initialized = false;
  }

  bool get isPlaying => _initialized && _player.playing;
}
