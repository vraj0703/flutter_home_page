import 'dart:math' as math;
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter_home_page/project/app/config/game_audio_config.dart';

class GameAudioSystem {
  late Soundpool _pool;
  int _waterdropId = -1;

  Future<void> _safePlay(String file, {double volume = 1.0}) async {
    try {
      await FlameAudio.play(file, volume: volume);
    } catch (_) {
      // Ignore autoplay errors
    }
  }

  Future<void> initialize() async {
    // 1. Initialize Soundpool for high-concurrency SFX (waterdrops)
    _pool = Soundpool.fromOptions(
      options: const SoundpoolOptions(streamType: StreamType.music),
    );

    try {
      // Load waterdrop sound into pool
      final data = await rootBundle.load(
        'assets/audio/${GameAudioConfig.waterdropSfx}',
      );
      _waterdropId = await _pool.load(data);
    } catch (e) {
      // Handle loading error
    }

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
        GameAudioConfig.thunderRollSfx,
        GameAudioConfig.thunderCrackSfx,
        GameAudioConfig.glassBreakSfx,
        GameAudioConfig.waterdropSfx,
      ]);
    } catch (e) {
      // Ignore audio loading errors (likely format issues on web)
      // Audio load error: $e
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

  void playPhilosophyTitleHover() {
    // User requested specifically 'mi.wav' for title hover
    _safePlay('mi.wav', volume: GameAudioConfig.sfxVolume);
  }

  void playSpatialThunder(double intensity) {
    // 1. Randomize the "Source" of the lightning
    // -1.0 is far left, 1.0 is far right
    // Note: FlameAudio doesn't support panning yet, reserved for future use
    // double pan = (_rng.nextDouble() * 2.0) - 1.0;

    // 2. Calculate Distance (Simulated)
    // Higher intensity lightning sounds "closer" (louder, less delay)
    double distance = 1.0 - intensity;
    double volume = (intensity * 0.8).clamp(0.1, 1.0);

    // 3. The "Speed of Sound" Delay
    // Wait a few milliseconds before playing to simulate distance
    int delayMs = (distance * 1000).toInt();

    Future.delayed(Duration(milliseconds: delayMs), () async {
      // Choose between a sharp 'crack' (close) or a long 'roll' (far)
      String soundFile = intensity > 0.8
          ? 'thunder_crack.mp3'
          : 'thunder_roll.wav';

      try {
        // Play with calculated volume
        // Note: FlameAudio.play doesn't support panning directly
        // For full stereo control, would need audioplayers package directly
        await FlameAudio.play(soundFile, volume: volume);
      } catch (_) {
        // Ignore if audio files don't exist yet
      }
    });
  }

  void playWaterdrop() {
    // Play with some pitch randomization for variety
    if (_waterdropId != -1) {
      _pool.play(_waterdropId);
    }
  }

  // Inside GameAudioSystem class

  void playSpatialWaterdrop(double normalizedX) {
    if (_waterdropId == -1) return;

    // Randomize rate slightly [0.9 - 1.1]
    double rate = 0.9 + math.Random().nextDouble() * 0.2;

    // Randomize volume [0.3 - 0.7]
    double vol = 0.3 + math.Random().nextDouble() * 0.4;

    // Calculate ID
    // Note: Default soundpool might not support stereo balance directly via play
    // but high concurrency is more important here.
    // Also, soundpool doesn't support 'balance' or 'pan' in play parameters easily
    // without using stream control, which is heavy.
    // _pool.play returns a streamId, we can use it to set volume if needed,
    // but currently soundpool 2.x supports volume in play?
    // Actually, soundpool 2.4.1 has `play(soundId, rate: rate)`.
    // Volume is set via `setVolume(streamId, volume)`.

    _pool.play(_waterdropId, rate: rate).then((streamId) {
      _pool.setVolume(streamId: streamId, volume: vol);
    });
  }

  /// Duck ambient loops (beach wind, rain, birds) with linear volume ramp
  /// Duration: 500ms, with "vacuum silence" low-pass effect at 400ms
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
    try {
      // Layer 1: Heavy shatter (glass + bass)
      playHeavyShatter();

      // Layer 2: Thunder crack for impact
      Future.delayed(const Duration(milliseconds: 100), () async {
        await FlameAudio.play(GameAudioConfig.thunderCrackSfx, volume: 0.5);
      });

      // Layer 3: High-pitched tinnitus ring
      // TODO: Add actual tinnitus sound file (sine wave ~8kHz)
      // For now, using a placeholder
      // The ring should decay over 800ms alongside the flash
      Future.delayed(const Duration(milliseconds: 150), () async {
         await FlameAudio.play(GameAudioConfig.glassBreakSfx, volume: 0.1);
      });

      // Camera shake for physical impact
      // This will be triggered from the component
    } catch (_) {
      // Ignore if audio files don't exist
    }
  }
}
