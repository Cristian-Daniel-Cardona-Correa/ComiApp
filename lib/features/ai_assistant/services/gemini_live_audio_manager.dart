import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_stream_player/audio_stream_player.dart';
import 'package:permission_handler/permission_handler.dart';

/// Administrador de audio en tiempo real para Gemini Live:
/// - Captura el audio del micrófono en formato PCM 16-bit 16kHz mono y lo transmite
/// - Reproduce en STREAMING DIRECTO DE BAJA LATENCIA los chunks de audio de la Chef (PCM 24kHz)
///   a través de `AudioStreamPlayer` (AudioTrack nativo sin esperar a que termine la frase)
/// - Mantiene fallback con `AudioPlayer` estándar en memoria
/// - Calcula la amplitud RMS en tiempo real (voz de usuario y de IA) para el visualizador CAVA
class GeminiLiveAudioManager {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioStreamPlayer? _streamPlayer;
  bool _useStreamPlayer = true;

  StreamSubscription<Uint8List>? _micStreamSub;
  StreamSubscription? _playerCompleteSub;
  Timer? _playbackVisualizerTimer;
  final List<int> _incomingPcmBuffer = [];
  bool _isMicActive = false;
  bool _isChefSpeaking = false;

  final StreamController<double> _voiceLevelController =
      StreamController<double>.broadcast();

  /// Nivel de volumen de voz actual (0.0 = silencio, 1.0 = volumen alto)
  Stream<double> get voiceLevelStream => _voiceLevelController.stream;

  bool get isMicActive => _isMicActive;
  bool get isChefSpeaking => _isChefSpeaking;

  void setChefSpeaking(bool speaking) {
    _isChefSpeaking = speaking;
  }

  Future<void> _ensureStreamPlayer() async {
    if (!_useStreamPlayer) return;
    if (_streamPlayer == null) {
      try {
        _streamPlayer = await AudioStreamPlayer.create(
          sampleRate: 24000,
          channels: 1,
          format: PcmFormat.s16le,
        );
        await _streamPlayer!.play();
        debugPrint('[comiAPP AudioManager] AudioStreamPlayer nativo inicializado (24kHz s16le).');
      } catch (e) {
        debugPrint('[comiAPP AudioManager] AudioStreamPlayer no disponible, usando fallback WAV: $e');
        _useStreamPlayer = false;
      }
    }
  }

  /// Asegura que el micrófono esté transmitiendo limpiamente.
  /// Si el stream anterior se cerró o Android lo suspendió, lo re-inicializa.
  Future<bool> ensureMicrophoneStreaming({
    required void Function(List<int> pcmChunk) onPcmChunk,
  }) async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('[comiAPP AudioManager] Permiso de micrófono no concedido.');
        _voiceLevelController.add(0.0);
        return false;
      }

      // Detener cualquier captura previa para garantizar stream fresco
      try {
        if (await _audioRecorder.isRecording()) {
          await _audioRecorder.stop();
        }
      } catch (_) {}
      await _micStreamSub?.cancel();
      _micStreamSub = null;

      // Configuración requerida por Gemini Live: PCM 16-bit little-endian, 16000 Hz, mono
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      );

      final stream = await _audioRecorder.startStream(config);
      _isMicActive = true;

      _micStreamSub = stream.listen(
        (chunk) {
          if (_isMicActive) {
            final level = calculatePcmRms(chunk);
            // Si la Chef no está hablando en el parlante, transmitimos la voz del usuario
            // Esto previene que el micrófono capture el parlante y corte el audio por falso barge-in
            if (!_isChefSpeaking) {
              _voiceLevelController.add(level);
              onPcmChunk(chunk);
            }
          }
        },
        onError: (err) {
          debugPrint('[comiAPP AudioManager] Error en stream de micrófono: $err');
          _isMicActive = false;
          _voiceLevelController.add(0.0);
        },
        onDone: () {
          debugPrint('[comiAPP AudioManager] Stream de micrófono completado por Android.');
          _isMicActive = false;
          _voiceLevelController.add(0.0);
        },
      );

      debugPrint('[comiAPP AudioManager] Captura de voz de usuario iniciada (PCM 16kHz).');
      return true;
    } catch (e) {
      debugPrint('[comiAPP AudioManager] Error iniciando captura de micrófono: $e');
      _isMicActive = false;
      _voiceLevelController.add(0.0);
      return false;
    }
  }

  /// Pausa o silencia la captura de micrófono
  void setMicMuted(bool muted) {
    _isMicActive = !muted;
    if (muted) {
      _voiceLevelController.add(0.0);
    }
    debugPrint('[comiAPP AudioManager] Micrófono ${muted ? "silenciado" : "activo"}.');
  }

  /// Detiene la captura del micrófono y libera el hardware de grabación
  Future<void> stopMicrophoneStream() async {
    _isMicActive = false;
    _voiceLevelController.add(0.0);
    await _micStreamSub?.cancel();
    _micStreamSub = null;
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
    } catch (_) {}
    debugPrint('[comiAPP AudioManager] Captura de micrófono detenida.');
  }

  /// Alimenta chunks de audio PCM 24kHz generados por Gemini Live directamente al reproductor
  /// nativo para que suene de inmediato sin esperar a que el servidor termine la oración
  Future<void> addPcmAudioChunk(List<int> pcmBytes) async {
    if (pcmBytes.isEmpty) return;

    // Calcular amplitud RMS en tiempo real para el ecualizador CAVA
    final level = calculatePcmRms(pcmBytes);
    _voiceLevelController.add(level);

    if (_useStreamPlayer) {
      await _ensureStreamPlayer();
      if (_streamPlayer != null) {
        try {
          await _streamPlayer!.feed(Uint8List.fromList(pcmBytes));
          return;
        } catch (e) {
          debugPrint('[comiAPP AudioManager] Error alimentando chunk en streaming: $e');
        }
      }
    }

    // Fallback: acumular para reproducir con WAV
    _incomingPcmBuffer.addAll(pcmBytes);
  }

  /// Notifica que la Chef terminó de enviar audio para el turno actual
  Future<void> signalEndOfChefTurn() async {
    if (_useStreamPlayer && _streamPlayer != null) {
      try {
        await _streamPlayer!.endOfStream();
      } catch (_) {}
    } else if (_incomingPcmBuffer.isNotEmpty) {
      await playAccumulatedAudio();
    }
    _voiceLevelController.add(0.0);
  }

  /// Reproducción fallback para audio acumulado (si AudioStreamPlayer no está activo)
  Future<void> playAccumulatedAudio() async {
    if (_incomingPcmBuffer.isEmpty) return;

    try {
      final pcmCopy = List<int>.from(_incomingPcmBuffer);
      _incomingPcmBuffer.clear();

      final wavBytes = _pcmToWav(
        pcmCopy,
        sampleRate: 24000,
        numChannels: 1,
        bitsPerSample: 16,
      );

      await stopPlayback();

      const chunkIntervalMs = 40;
      const bytesPerInterval = (24000 * 2 * chunkIntervalMs) ~/ 1000;
      int cursor = 0;

      _playbackVisualizerTimer = Timer.periodic(
        const Duration(milliseconds: chunkIntervalMs),
        (timer) {
          if (cursor >= pcmCopy.length) {
            timer.cancel();
            _playbackVisualizerTimer = null;
            _voiceLevelController.add(0.0);
            return;
          }
          final end = (cursor + bytesPerInterval).clamp(0, pcmCopy.length);
          final window = pcmCopy.sublist(cursor, end);
          cursor = end;
          final level = calculatePcmRms(window);
          _voiceLevelController.add(level);
        },
      );

      _playerCompleteSub?.cancel();
      _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
        _playbackVisualizerTimer?.cancel();
        _playbackVisualizerTimer = null;
        _voiceLevelController.add(0.0);
      });

      await _audioPlayer.stop();
      await _audioPlayer.play(BytesSource(wavBytes));
    } catch (e) {
      debugPrint('[comiAPP AudioManager] Error reproduciendo audio fallback: $e');
      _playbackVisualizerTimer?.cancel();
      _playbackVisualizerTimer = null;
      _voiceLevelController.add(0.0);
    }
  }

  /// Detiene cualquier reproducción en curso inmediatamente (Barge-in / interrupción)
  Future<void> stopPlayback() async {
    _isChefSpeaking = false;
    _playbackVisualizerTimer?.cancel();
    _playbackVisualizerTimer = null;
    _playerCompleteSub?.cancel();
    _playerCompleteSub = null;
    _voiceLevelController.add(0.0);
    _incomingPcmBuffer.clear();

    if (_streamPlayer != null) {
      try {
        await _streamPlayer!.stop();
        await _streamPlayer!.play(); // Listo para recibir audio nuevo de inmediato
      } catch (_) {}
    }

    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  /// Calcula la raíz cuadrática media (RMS) de un buffer PCM 16-bit little endian
  /// Retorna un valor entre 0.0 (silencio) y 1.0 (voz alta)
  static double calculatePcmRms(List<int> pcmBytes) {
    if (pcmBytes.length < 2) return 0.0;
    final numSamples = pcmBytes.length ~/ 2;
    double sumSquares = 0.0;
    final byteData = ByteData.sublistView(Uint8List.fromList(pcmBytes));
    for (int i = 0; i < numSamples; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      final normalized = sample / 32768.0;
      sumSquares += normalized * normalized;
    }
    final rms = math.sqrt(sumSquares / numSamples);
    if (rms < 0.012) return 0.0;
    return ((rms - 0.012) * 5.0).clamp(0.0, 1.0);
  }

  /// Convierte bytes crudos PCM en un archivo WAV estándar RIFF en memoria
  Uint8List _pcmToWav(
    List<int> pcmBytes, {
    int sampleRate = 24000,
    int numChannels = 1,
    int bitsPerSample = 16,
  }) {
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);
    final totalDataLen = pcmBytes.length;
    final totalAudioLen = totalDataLen + 36;

    final header = ByteData(44);
    // RIFF chunk descriptor
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, totalAudioLen, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    // fmt sub-chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 para PCM)
    header.setUint16(20, 1, Endian.little); // AudioFormat (1 para PCM lineal)
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data sub-chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, totalDataLen, Endian.little);

    final wav = Uint8List(44 + totalDataLen);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, 44 + totalDataLen, pcmBytes);
    return wav;
  }

  /// Limpia los recursos al terminar la sesión
  Future<void> dispose() async {
    await stopMicrophoneStream();
    await stopPlayback();
    try {
      await _streamPlayer?.dispose();
    } catch (_) {}
    await _voiceLevelController.close();
    await _audioRecorder.dispose();
    await _audioPlayer.dispose();
  }
}
