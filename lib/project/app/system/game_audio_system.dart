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
      GameAudioConfig.boldTextSfx,
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

  void playBoldText() {
    FlameAudio.play(
      GameAudioConfig.boldTextSfx,
      volume: GameAudioConfig.sfxVolume,
    );
  }

  void playScrollTick() {
    // Optional: Very quiet tick for scrolling
    // FlameAudio.play(GameAudioConfig.scrollTickSfx, volume: 0.1);
  }
}
