import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Servicio para reproducir sonidos de alerta suaves y no estridentes
/// cuando un temporizador de cocina finaliza.
class TimerSoundService {
  static final TimerSoundService _instance = TimerSoundService._internal();
  factory TimerSoundService() => _instance;
  TimerSoundService._internal();

  AudioPlayer? _player;

  /// Reproduce una pequeña alarma suave (chime/campanilla de 0.8s)
  Future<void> playTimerAlarm() async {
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.setVolume(0.7);
      await _player!.play(AssetSource('sounds/timer_alarm.wav'));
      debugPrint('[comiAPP TimerSoundService] Alarma suave reproducida para temporizador terminado.');
    } catch (e) {
      debugPrint('[comiAPP TimerSoundService] Nota: No se pudo reproducir sonido de alarma: $e');
    }
  }

  void dispose() {
    try {
      _player?.dispose();
      _player = null;
    } catch (_) {}
  }
}
