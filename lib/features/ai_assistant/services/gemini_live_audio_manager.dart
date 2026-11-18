import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

/// Administrador de audio en tiempo real para Gemini Live:
/// - Captura el audio del micrófono en formato PCM 16-bit 16kHz mono y lo transmite
/// - Reproduce el audio de respuesta del Chef (PCM 24kHz) usando un buffer WAV en memoria
/// - Detiene la reproducción inmediatamente en caso de interrupción del usuario (Barge-in)
class GeminiLiveAudioManager {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<Uint8List>? _micStreamSub;
  final List<int> _incomingPcmBuffer = [];
  bool _isMicActive = false;

  bool get isMicActive => _isMicActive;

  /// Inicia la captura continua de voz del micrófono para transmitir a Gemini Live
  Future<bool> startMicrophoneStream({
    required void Function(List<int> pcmChunk) onPcmChunk,
  }) async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('[comiAPP AudioManager] Permiso de micrófono no concedido.');
        return false;
      }

      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }

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
      _micStreamSub?.cancel();
      _micStreamSub = stream.listen(
        (chunk) {
          if (_isMicActive) {
            onPcmChunk(chunk);
          }
        },
        onError: (err) {
          debugPrint('[comiAPP AudioManager] Error en stream de micrófono: $err');
        },
      );

      _isMicActive = true;
      debugPrint('[comiAPP AudioManager] Transmisión de micrófono iniciada (PCM 16kHz).');
      return true;
    } catch (e) {
      debugPrint('[comiAPP AudioManager] Error iniciando captura de micrófono: $e');
      _isMicActive = false;
      return false;
    }
  }

  /// Pausa o silencia la captura de micrófono
  void setMicMuted(bool muted) {
    _isMicActive = !muted;
    debugPrint('[comiAPP AudioManager] Micrófono ${muted ? "silenciado" : "activo"}.');
  }

  /// Detiene la captura del micrófono
  Future<void> stopMicrophoneStream() async {
    _isMicActive = false;
    await _micStreamSub?.cancel();
    _micStreamSub = null;
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
    } catch (_) {}
  }

  /// Acumula chunks de audio PCM 24kHz generados por Gemini Live
  void addPcmAudioChunk(List<int> pcmBytes) {
    _incomingPcmBuffer.addAll(pcmBytes);
  }

  /// Reproduce el audio acumulado de la respuesta del Chef
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

      await _audioPlayer.stop();
      await _audioPlayer.play(BytesSource(wavBytes));
    } catch (e) {
      debugPrint('[comiAPP AudioManager] Error reproduciendo audio del Chef: $e');
    }
  }

  /// Detiene cualquier reproducción en curso inmediatamente (Barge-in / interrupción)
  Future<void> stopPlayback() async {
    _incomingPcmBuffer.clear();
    try {
      await _audioPlayer.stop();
    } catch (_) {}
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
    await _audioRecorder.dispose();
    await _audioPlayer.dispose();
  }
}
