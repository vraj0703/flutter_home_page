import 'package:audioplayers/audioplayers.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_home_page/project/app/config/game_audio_config.dart';

class GameAudioSystem {
  DateTime _lastHoverTime = DateTime.now();

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
    /*FlameAudio.bgm.play(
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
      FlameAudio.play(
        GameAudioConfig.hoverSfx,
        volume: GameAudioConfig.hoverVolume,
      );
      _lastHoverTime = now;
    }*/
  }

  void playClick() {
    /* FlameAudio.play(
      GameAudioConfig.clickSfx,
      volume: GameAudioConfig.sfxVolume,
    );*/
  }

  void playEnterSound() {
    FlameAudio.play(
      GameAudioConfig.enterSfx,
      volume: GameAudioConfig.enterSfxVolume,
    );
  }

  void playTitleLoaded() {
    FlameAudio.play(
      GameAudioConfig.titleLoadedSfx,
      volume: GameAudioConfig.titleLoadedVolume,
    );
  }

  void playSlideIn() {
    FlameAudio.play(
      GameAudioConfig.slideInSfx,
      volume: GameAudioConfig.sfxVolume,
    );
  }

  void playBouncyArrow() {
    FlameAudio.play(
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
      await _boldTextPlayer!.resume();
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
    FlameAudio.play(GameAudioConfig.tingSfx, volume: GameAudioConfig.sfxVolume);
  }

  void playScrollTick() {
    // Optional: Very quiet tick for scrolling
    // FlameAudio.play(GameAudioConfig.scrollTickSfx, volume: 0.1);
  }
}
