import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_session_state.dart';
import 'asistente_ia.dart';
import 'ai_context_builder.dart';

/// Simulación interactiva de Gemini Live para pruebas completas y entornos de desarrollo
class MockGeminiLiveClient implements AsistenteIA {
  final _uuid = const Uuid();
  final _statusController = StreamController<AiAssistantStatus>.broadcast();
  final _transcriptController = StreamController<String>.broadcast();
  final _userTranscriptController = StreamController<String>.broadcast();
  final _audioOutputController = StreamController<List<int>>.broadcast();
  final _toolCallController = StreamController<AiToolCall>.broadcast();

  AiAssistantStatus _currentStatus = AiAssistantStatus.desconectado;
  AiCookingContext? _context;
  Timer? _responseTimer;

  @override
  Stream<AiAssistantStatus> get statusStream => _statusController.stream;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<String> get userTranscriptStream => _userTranscriptController.stream;

  @override
  Stream<List<int>> get audioOutputStream => _audioOutputController.stream;

  @override
  Stream<AiToolCall> get toolCallStream => _toolCallController.stream;

  @override
  AiAssistantStatus get currentStatus => _currentStatus;

  void _setStatus(AiAssistantStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  @override
  Future<void> connect(AiCookingContext context) async {
    _context = context;
    _setStatus(AiAssistantStatus.conectando);
    await Future.delayed(const Duration(milliseconds: 500));
    _setStatus(AiAssistantStatus.escuchando);

    // Saludo inicial contextualizado al paso
    _speak(
      '¡Hola! Soy tu Chef de comiAPP. Te acompaño en "${context.recipe.title}". Estamos en el paso "${context.currentStep.title}". ¿En qué te ayudo?',
    );
  }

  @override
  Future<void> sendUserSpeechChunk(List<int> pcm16Bytes) async {
    // Simula detección de actividad de voz VAD
    if (_currentStatus == AiAssistantStatus.hablando) {
      interrupt(); // Barge-in automático al hablar el usuario
    }
  }

  @override
  Future<void> sendCameraFrame(List<int> jpegBytes) async {
    // Si la cámara está activa y el usuario pide análisis visual
    if (_currentStatus == AiAssistantStatus.escuchando) {
      _setStatus(AiAssistantStatus.pensando);
      await Future.delayed(const Duration(milliseconds: 800));
      _speak(
        'Veo bien el color en la sartén. Un minuto más de dorado y quedará en su punto.',
      );
    }
  }

  @override
  Future<void> sendAudioStreamEnd() async {
    // Al finalizar el turno de voz del usuario en mock, simula respuesta
    _setStatus(AiAssistantStatus.pensando);
    await Future.delayed(const Duration(milliseconds: 500));
    _speak('Te escuché perfectamente. Continúa cocinando y avísame si necesitas ayuda.');
  }

  @override
  Future<void> sendToolResponse({
    required String callId,
    required String name,
    required Map<String, dynamic> result,
  }) async {
    debugPrint('[MockGeminiLiveClient] toolResponse recibido para $name: $result');
  }

  @override
  Future<void> sendTextMessage(String text) async {
    final lower = text.toLowerCase().trim();
    _setStatus(AiAssistantStatus.pensando);
    await Future.delayed(const Duration(milliseconds: 600));

    // Detección de comandos por voz / function calling
    if (lower.contains('siguiente') || lower.contains('listo') || lower.contains('terminé')) {
      _toolCallController.add(
        AiToolCall(
          callId: _uuid.v4(),
          name: 'siguiente_paso',
          arguments: {},
        ),
      );
      _speak('¡Excelente trabajo! Pasamos al siguiente paso.');
      return;
    }

    if (lower.contains('anterior') || lower.contains('atrás')) {
      _toolCallController.add(
        AiToolCall(
          callId: _uuid.v4(),
          name: 'paso_anterior',
          arguments: {},
        ),
      );
      _speak('Volvemos al paso anterior.');
      return;
    }

    if (lower.contains('temporizador') || lower.contains('tiempo')) {
      // Extraer minutos o usar valor por defecto
      final regex = RegExp(r'(\d+)\s*(?:min|minuto|minutos)');
      final match = regex.firstMatch(lower);
      final minutes = match != null ? int.parse(match.group(1)!) : 5;

      _toolCallController.add(
        AiToolCall(
          callId: _uuid.v4(),
          name: 'iniciar_temporizador',
          arguments: {
            'nombre': _context?.currentStep.timerLabel ?? 'Cocción',
            'minutos': minutes,
          },
        ),
      );
      _speak('Inicié tu temporizador de $minutes minutos para ${_context?.currentStep.timerLabel ?? 'este paso'}.');
      return;
    }

    if (lower.contains('ingrediente') || lower.contains('cuánto')) {
      _toolCallController.add(
        AiToolCall(
          callId: _uuid.v4(),
          name: 'leer_ingredientes_del_paso',
          arguments: {},
        ),
      );
      _speak('Para este paso necesitas los ingredientes indicados en pantalla.');
      return;
    }

    // Respuesta culinaria inteligente
    if (lower.contains('sofrito') || lower.contains('cebolla')) {
      _speak('El sofrito está listo cuando la cebolla se vea transparente y brillante, sin llegar a quemarse.');
    } else if (lower.contains('crema') || lower.contains('sustituto')) {
      _speak('Puedes sustituir la crema de leche por leche evaporada, yogur griego sin azúcar o leche de coco para opción vegana.');
    } else {
      _speak('Entendido. Mantén el fuego controlado y avísame cuando desees que tome el tiempo o pasemos al siguiente paso.');
    }
  }

  void _speak(String text) {
    _responseTimer?.cancel();
    _setStatus(AiAssistantStatus.hablando);
    _transcriptController.add(text);

    _responseTimer = Timer(const Duration(seconds: 4), () {
      if (_currentStatus == AiAssistantStatus.hablando) {
        _setStatus(AiAssistantStatus.escuchando);
      }
    });
  }

  @override
  Future<void> interrupt() async {
    _responseTimer?.cancel();
    _setStatus(AiAssistantStatus.interrumpido);
    await Future.delayed(const Duration(milliseconds: 150));
    _setStatus(AiAssistantStatus.escuchando);
  }

  @override
  Future<void> disconnect() async {
    _responseTimer?.cancel();
    _setStatus(AiAssistantStatus.desconectado);
  }

  @override
  void dispose() {
    disconnect();
    _statusController.close();
    _transcriptController.close();
    _userTranscriptController.close();
    _audioOutputController.close();
    _toolCallController.close();
  }
}
