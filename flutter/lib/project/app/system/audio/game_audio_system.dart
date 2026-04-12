import 'dart:math' as math;
import 'package:flutter_home_page/project/app/utils/logger_util.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_home_page/project/app/config/game_audio_config.dart';

class GameAudioSystem {
  bool _waterdropReady = false;
  bool _muted = false;

  bool get isMuted => _muted;

  void toggleMute() {
    _muted = !_muted;
  }

  Future<void> _safePlay(String file, {double volume = 1.0}) async {
    if (_muted) return;
    try {
      await FlameAudio.play(file, volume: volume);
    } catch (_) {
      // Ignore autoplay errors
    }
  }

  /// Full initialization — kept for backward compatibility.
  /// Calls initCritical() then loadDeferred() sequentially.
  Future<void> initialize() async {
    await initCritical();
    await loadDeferred();
  }

  /// Load only the audio needed before first frame (logo + title + scroll).
  /// Contact section audio is deferred to [loadDeferred].
  Future<void> initCritical() async {
    // Critical SFX: needed for logo → title → bold text scroll sequence
    try {
      await FlameAudio.audioCache.loadAll([
        GameAudioConfig.enterSfx,
        GameAudioConfig.titleLoadedSfx,
        GameAudioConfig.slideInSfx,
        GameAudioConfig.bouncyArrowSfx,
        GameAudioConfig.boldTextSwell,
      ]);
    } catch (e) {
      // Ignore audio loading errors on web
    }

    playBgm();
  }

  /// Load deferred audio — contact section, trail cards, thunder, etc.
  /// Call after flutter-ready has been sent and the game is interactive.
  Future<void> loadDeferred() async {
    try {
      await FlameAudio.audioCache.loadAll([
        GameAudioConfig.contactEntrySfx,
        GameAudioConfig.contactCompleteSfx,
        GameAudioConfig.trailCard1Sfx,
        GameAudioConfig.trailCard2Sfx,
        GameAudioConfig.trailCard3Sfx,
        GameAudioConfig.trailCard4Sfx,
        GameAudioConfig.thunderRollSfx,
        GameAudioConfig.thunderCrackSfx,
        GameAudioConfig.glassBreakSfx,
        GameAudioConfig.waterdropSfx,
        GameAudioConfig.gearTickSfx,
        GameAudioConfig.selectionClickSfx,
        GameAudioConfig.contactButtonSfx,
      ]);
    } catch (e) {
      // Ignore audio loading errors on web
    }
  }

  void playBgm() {
    // BGM disabled — space_ambient.mp3 removed (37.8 MB, too large for web)
  }

  void stopBgm() {
    // FlameAudio.bgm.stop();
  }

  void playHover() {
    /*final now = DateTime.now();
    if (now.difference(_lastHoverTime).inMilliseconds >
        GameAudioConfig.hoverThrottleMs) {*/
    //_safePlay(GameAudioConfig.hoverSfx, volume: GameAudioConfig.hoverVolume);
    // _lastHoverTime = now;
    //}
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
    if (_muted) return;
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

  /// Stop all currently playing audio
  void stopAll() {
    _boldTextPlayer?.stop();
    // FlameAudio doesn't have a global stop, but stopping individual players covers it
  }

  void playTing() {
    _safePlay(GameAudioConfig.tingSfx, volume: GameAudioConfig.sfxVolume);
  }

  void playContactEntry() {
    LoggerUtil.log('Audio', 'Playing contact Entry (Do)');
    _safePlay(
      GameAudioConfig.contactEntrySfx,
      volume: GameAudioConfig.sfxVolume,
    );
  }

  void playContactComplete() {
    _safePlay(
      GameAudioConfig.contactCompleteSfx,
      volume: GameAudioConfig.sfxVolume,
    );
  }

  void playContactButtonSound() {
    _safePlay(
      GameAudioConfig.contactButtonSfx,
      volume: GameAudioConfig.sfxVolume,
    );
  }

  void playTrailCardSound(int index) {
    LoggerUtil.log('Audio', 'Playing Trail Card Sound: $index');
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

  void playGearTick() {
    /* _safePlay(
      GameAudioConfig.gearTickSfx,
      volume: GameAudioConfig.sfxVolume * 0.8,
    );*/
  }

  /// Play whoosh sound when cards flip
  void playWhooshSound() {
    _safePlay(
      GameAudioConfig.slideInSfx,
      volume: GameAudioConfig.sfxVolume * 0.6,
    );
  }

  void playAsset(String file, {double volume = 1.0}) {
    _safePlay(file, volume: volume);
  }

  void playContactTitleHover() {
    LoggerUtil.log('Audio', 'Playing contact Title Hover (Do)');
    // User requested 'do.wav' for title hover (associated sound)
    _safePlay(
      GameAudioConfig.contactEntrySfx,
      volume: GameAudioConfig.sfxVolume,
    );
  }

  void playContactCardHover(int index) {
    LoggerUtil.log('Audio', 'Playing contact Card Hover: $index');
    playTrailCardSound(index);
  }

  void playcontactButtonHover() {
    LoggerUtil.log('Audio', 'Playing contact Button Hover (Sol)');
    _safePlay(
      GameAudioConfig.contactButtonSfx,
      volume: GameAudioConfig.sfxVolume,
    );
  }

  void playSpatialThunder(double intensity) {
    if (_muted) return;
    // 1. Randomize the "Source" of the lightning
    // -1.0 is far left, 1.0 is far right
    // Note: FlameAudio doesn't support panning yet, reserved for future use
    // double pan = (_rng.nextDouble() * 2.0) - 1.0;

    // 2. Calculate Distance (Simulated)
    // Higher intensity lightning sounds "closer" (louder, less delay)
    double distance = (1.0 - intensity).clamp(
      0.0,
      1.0,
    ); // Ensure non-negative distance
    // Allow volume to reach 1.0 if intensity > 1.0
    double volume = (intensity * 0.8).clamp(0.1, 1.0);

    // 3. The "Speed of Sound" Delay
    // Wait a few milliseconds before playing to simulate distance
    int delayMs = (distance * 1000).toInt();

    Future.delayed(Duration(milliseconds: delayMs), () async {
      // Choose between a sharp 'crack' (close) or a long 'roll' (far)
      String soundFile = intensity > 0.8
          ? GameAudioConfig.thunderCrackSfx
          : GameAudioConfig.thunderRollSfx;

      LoggerUtil.log(
        'Audio',
        'Playing Spatial Thunder: $soundFile (Vol: $volume)',
      );

      try {
        // Play with calculated volume
        // Note: FlameAudio.play doesn't support panning directly
        // For full stereo control, would need audioplayers package directly
        await FlameAudio.play(soundFile, volume: volume);
        LoggerUtil.log('Audio', 'Thunder Play Request Sent');
      } catch (e) {
        LoggerUtil.log('Audio', 'Error playing thunder: $e');
      }
    });
  }

  // Waterdrop SFX — replaced Soundpool (discontinued, dart2wasm incompatible)
  // with FlameAudio.play which works under both dart2js and dart2wasm.
  void playSpatialWaterdrop(double normalizedX) {
    if (_muted) return;

    // Randomize volume [0.3 - 0.7]
    double vol = 0.3 + math.Random().nextDouble() * 0.4;
    _safePlay(GameAudioConfig.waterdropSfx, volume: vol);
  }

  Future<void> duckAmbientLoops({int durationMs = 500}) async {
    // TODO: Implement when ambient loops are added
    // For now, this is a placeholder for the ducking sequence
    //
    // Implementation would:
    // 1. Ramp volume from current → 0.0 over durationMs using interpolation
    // 2. At 400ms, apply low-pass filter (requires DSP library)
    // 3. Fade to complete silence

    // Placeholder delay to simulate ducking time
    await Future.delayed(Duration(milliseconds: durationMs));
  }

  /// Play multi-layered heavy shatter sound effect
  /// Combines glass break + bass thump + reverb tail
  Future<void> playHeavyShatter() async {
    if (_muted) return;
    try {
      // Layer 1: Primary glass break
      await FlameAudio.play(GameAudioConfig.glassBreakSfx, volume: 0.9);

      // Layer 2: Bass thump (using thunder crack for low-end)
      // Delayed by 50ms for depth
      Future.delayed(const Duration(milliseconds: 50), () async {
        await FlameAudio.play(GameAudioConfig.thunderCrackSfx, volume: 0.3);
      });

      // Add haptic feedback
      HapticFeedback.heavyImpact();
    } catch (_) {
      // Ignore if audio files don't exist
    }
  }

  /// Play the full transition climax sequence
  /// Layers: Heavy shatter + Thunder + Tinnitus ring (10% volume, 800ms decay)
  Future<void> playTransitionClimax() async {
    if (_muted) return;
    try {
      // Layer 1: Heavy shatter (glass + bass)
      // Layer 1: Heavy shatter (Glass Crunch + Bass Thump) triggered immediately
      playHeavyShatter();

      // Layer 2: Thunder crack for extra impact (Simultaneous)
      // "Thump" layer reinforcement
      FlameAudio.play(GameAudioConfig.thunderCrackSfx, volume: 0.5);

      // Layer 3: High-pitched Tinkle (Tinnitus ring)
      // "Tinkle" layer
      // Reduced delay to 20ms to be effectively simultaneous but distinct
      Future.delayed(const Duration(milliseconds: 20), () async {
        await FlameAudio.play(GameAudioConfig.glassBreakSfx, volume: 0.1);
      });

      // Camera shake for physical impact
      // This will be triggered from the component
    } catch (_) {
      // Ignore if audio files don't exist
    }
  }
}
