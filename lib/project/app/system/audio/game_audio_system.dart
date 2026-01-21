import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_home_page/project/app/config/game_audio_config.dart';

class GameAudioSystem {
  DateTime _lastHoverTime = DateTime.now();

  Future<void> _safePlay(String file, {double volume = 1.0}) async {
    try {
      await FlameAudio.play(file, volume: volume);
    } catch (_) {
      // Ignore autoplay errors
    }
  }

  Future<void> initialize() async {
    // Preload important SFX to avoid latency
    await FlameAudio.audioCache.loadAll([
      GameAudioConfig.ambientBgm,
      GameAudioConfig.enterSfx,
      GameAudioConfig.titleLoadedSfx,
      GameAudioConfig.slideInSfx,
      GameAudioConfig.bouncyArrowSfx,
      GameAudioConfig.boldTextSwell,
    ]);

    // Start BGM loop (can be toggled in settings later)
    playBgm();
  }

  void playBgm() {
    /*_safePlay(
      GameAudioConfig.ambientBgm,
      volume: GameAudioConfig.bgmVolume,
    );*/
  }

  void stopBgm() {
    // FlameAudio.bgm.stop();
  }

  void playHover() {
    /*final now = DateTime.now();
    if (now.difference(_lastHoverTime).inMilliseconds >
        GameAudioConfig.hoverThrottleMs) {
      _safePlay(
        GameAudioConfig.hoverSfx,
        volume: GameAudioConfig.hoverVolume,
      );
      _lastHoverTime = now;
    }*/
  }

  void playClick() {
    /* _safePlay(
      GameAudioConfig.clickSfx,
      volume: GameAudioConfig.sfxVolume,
    );*/
  }

  void playEnterSound() {
    _safePlay(GameAudioConfig.enterSfx, volume: GameAudioConfig.enterSfxVolume);
  }

  void playTitleLoaded() {
    _safePlay(
      GameAudioConfig.titleLoadedSfx,
      volume: GameAudioConfig.titleLoadedVolume,
    );
  }

  void playSlideIn() {
    _safePlay(GameAudioConfig.slideInSfx, volume: GameAudioConfig.sfxVolume);
  }

  void playBouncyArrow() {
    _safePlay(
      GameAudioConfig.bouncyArrowSfx,
      volume: GameAudioConfig.sfxVolume,
    );
  }

  AudioPlayer? _boldTextPlayer;

  Future<void> syncBoldTextAudio(
    double progress, {
    double velocity = 0.5,
  }) async {
    if (_boldTextPlayer == null) {
      _boldTextPlayer = AudioPlayer();
      await _boldTextPlayer!.setSource(
        AssetSource('audio/${GameAudioConfig.boldTextSwell}'),
      );
      await _boldTextPlayer!.setReleaseMode(ReleaseMode.stop);
    }

    final duration = await _boldTextPlayer!.getDuration();
    if (duration == null) return;

    final targetMillis = (duration.inMilliseconds * progress).round();
    double vol = (0.2 + (velocity.abs() * 5.0)).clamp(0.0, 1.0);
    if (progress < 0.1) vol *= (progress / 0.1);

    await _boldTextPlayer!.setVolume(vol);

    if (_boldTextPlayer!.state != PlayerState.playing ||
        _boldTextPlayer!.state == PlayerState.completed) {
      try {
        await _boldTextPlayer!.resume();
      } catch (_) {}
    }

    await _boldTextPlayer!.seek(Duration(milliseconds: targetMillis));
    if (progress <= 0.01 || progress >= 0.99) {
      if (_boldTextPlayer!.state == PlayerState.playing) {}
    }
  }

  void stopBoldTextAudio() {
    _boldTextPlayer?.stop();
  }

  void playTing() {
    _safePlay(GameAudioConfig.tingSfx, volume: GameAudioConfig.sfxVolume);
  }

  void playScrollTick() {
    // Optional: Very quiet tick for scrolling
    // FlameAudio.play(GameAudioConfig.scrollTickSfx, volume: 0.1);
  }
}
