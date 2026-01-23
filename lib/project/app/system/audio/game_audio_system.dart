import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_home_page/project/app/config/game_audio_config.dart';

class GameAudioSystem {
  Future<void> _safePlay(String file, {double volume = 1.0}) async {
    try {
      await FlameAudio.play(file, volume: volume);
    } catch (_) {
      // Ignore autoplay errors
    }
  }

  Future<void> initialize() async {
    // Preload important SFX to avoid latency
    try {
      await FlameAudio.audioCache.loadAll([
        GameAudioConfig.ambientBgm,
        GameAudioConfig.enterSfx,
        GameAudioConfig.titleLoadedSfx,
        GameAudioConfig.slideInSfx,
        GameAudioConfig.bouncyArrowSfx,
        GameAudioConfig.boldTextSwell,
        GameAudioConfig.philosophyEntrySfx,
        GameAudioConfig.philosophyCompleteSfx,
        GameAudioConfig.trailCard1Sfx,
        GameAudioConfig.trailCard2Sfx,
        GameAudioConfig.trailCard3Sfx,
        GameAudioConfig.trailCard4Sfx,
      ]);
    } catch (e) {
      // Ignore audio loading errors (likely format issues on web)
      print('Audio load error: $e');
    }

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

  void playPhilosophyEntry() {
    _safePlay(
      GameAudioConfig.philosophyEntrySfx,
      volume: GameAudioConfig.sfxVolume,
    );
  }

  void playPhilosophyComplete() {
    _safePlay(
      GameAudioConfig.philosophyCompleteSfx,
      volume: GameAudioConfig.sfxVolume,
    );
  }

  void playTrailCardSound(int index) {
    String sfx;
    switch (index) {
      case 0:
        sfx = GameAudioConfig.trailCard1Sfx;
        break;
      case 1:
        sfx = GameAudioConfig.trailCard2Sfx;
        break;
      case 2:
        sfx = GameAudioConfig.trailCard3Sfx;
        break;
      case 3:
        sfx = GameAudioConfig.trailCard4Sfx;
        break;
      default:
        return;
    }
    _safePlay(sfx, volume: GameAudioConfig.sfxVolume);
  }

  void playScrollTick() {
    // Optional: Very quiet tick for scrolling
    // FlameAudio.play(GameAudioConfig.scrollTickSfx, volume: 0.1);
  }

  void playAsset(String file, {double volume = 1.0}) {
    _safePlay(file, volume: volume);
  }
}
