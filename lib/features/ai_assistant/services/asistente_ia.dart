import 'dart:async';
import '../models/ai_session_state.dart';
import 'ai_context_builder.dart';

/// Interfaz desacoplada del Asistente de IA (Plan B de contingencia del proyecto)
/// Permite intercambiar el motor Gemini Live WebSocket por un cliente simulado
/// o desactivarlo completamente sin afectar las demás funciones de la app.
abstract class AsistenteIA {
  Stream<AiAssistantStatus> get statusStream;
  Stream<String> get transcriptStream;
  Stream<AiToolCall> get toolCallStream;
  AiAssistantStatus get currentStatus;

  Future<void> connect(AiCookingContext context);
  Future<void> sendUserSpeechChunk(List<int> pcm16Bytes);
  Future<void> sendCameraFrame(List<int> jpegBytes);
  Future<void> sendTextMessage(String text);
  Future<void> interrupt();
  Future<void> disconnect();
  void dispose();
}
