import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/ai_session_state.dart';
import 'asistente_ia.dart';
import 'ai_context_builder.dart';

/// Cliente oficial para la Live API de Gemini por WebSocket bidireccional
class GeminiLiveClient implements AsistenteIA {
  final String apiKey;
  final String model;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final _statusController = StreamController<AiAssistantStatus>.broadcast();
  final _transcriptController = StreamController<String>.broadcast();
  final _toolCallController = StreamController<AiToolCall>.broadcast();

  AiAssistantStatus _currentStatus = AiAssistantStatus.desconectado;

  GeminiLiveClient({
    this.apiKey = '',
    this.model = AppConstants.defaultGeminiLiveModel,
  });

  @override
  Stream<AiAssistantStatus> get statusStream => _statusController.stream;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

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
    _setStatus(AiAssistantStatus.conectando);

    try {
      final wsUrl = Uri.parse(
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey',
      );

      _channel = WebSocketChannel.connect(wsUrl);
      await _channel!.ready;

      // Envío del mensaje inicial de configuración (Setup Handshake)
      final systemInstruction =
          AiContextBuilder.buildSystemInstruction(context);
      final tools = AiContextBuilder.getToolDeclarations();

      final setupMessage = {
        'setup': {
          'model': 'models/$model',
          'generationConfig': {
            'responseModalities': ['AUDIO', 'TEXT'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {
                  'voiceName': 'Aoede', // Voz cálida en español
                },
              },
            },
          },
          'systemInstruction': {
            'parts': [
              {'text': systemInstruction}
            ],
          },
          'tools': [
            {'functionDeclarations': tools}
          ],
        },
      };

      _channel!.sink.add(json.encode(setupMessage));
      _listenToMessages();
      _setStatus(AiAssistantStatus.escuchando);
    } catch (e) {
      debugPrint('[comiAPP GeminiLiveClient] Error al conectar: $e');
      _setStatus(AiAssistantStatus.error);
    }
  }

  void _listenToMessages() {
    _subscription = _channel?.stream.listen(
      (data) {
        try {
          final message = json.decode(data is String ? data : utf8.decode(data));

          // 1. Manejo de Barge-in (Interrupción)
          // "al recibir interrupted, vaciar de inmediato el buffer de audio local"
          if (message['serverContent']?['interrupted'] == true) {
            debugPrint('[comiAPP GeminiLiveClient] Señal de interrupción recibida (Barge-in).');
            _setStatus(AiAssistantStatus.interrumpido);
            _setStatus(AiAssistantStatus.escuchando);
            return;
          }

          // 2. Transcripción y audio del modelo
          final modelTurn = message['serverContent']?['modelTurn'];
          if (modelTurn != null) {
            _setStatus(AiAssistantStatus.hablando);
            final parts = modelTurn['parts'] as List<dynamic>? ?? [];
            for (final part in parts) {
              if (part['text'] != null) {
                _transcriptController.add(part['text'] as String);
              }
            }
          }

          if (message['serverContent']?['turnComplete'] == true) {
            _setStatus(AiAssistantStatus.escuchando);
          }

          // 3. Manejo de llamadas a herramientas (Function Calling)
          final toolCall = message['toolCall'];
          if (toolCall != null && toolCall['functionCalls'] != null) {
            final calls = toolCall['functionCalls'] as List<dynamic>;
            for (final call in calls) {
              final aiToolCall = AiToolCall(
                callId: call['id'] as String? ?? 'call_default',
                name: call['name'] as String,
                arguments: Map<String, dynamic>.from(call['args'] ?? {}),
              );
              _toolCallController.add(aiToolCall);
            }
          }
        } catch (err) {
          debugPrint('[comiAPP GeminiLiveClient] Error procesando frame: $err');
        }
      },
      onError: (err) {
        debugPrint('[comiAPP GeminiLiveClient] Error en Stream: $err');
        _setStatus(AiAssistantStatus.error);
      },
      onDone: () {
        _setStatus(AiAssistantStatus.desconectado);
      },
    );
  }

  @override
  Future<void> sendUserSpeechChunk(List<int> pcm16Bytes) async {
    if (_channel == null || _currentStatus == AiAssistantStatus.desconectado) {
      return;
    }

    final base64Audio = base64Encode(pcm16Bytes);
    final realtimeInput = {
      'realtimeInput': {
        'mediaChunks': [
          {
            'mimeType': AppConstants.inputAudioMimeType,
            'data': base64Audio,
          }
        ],
      },
    };

    _channel!.sink.add(json.encode(realtimeInput));
  }

  @override
  Future<void> sendCameraFrame(List<int> jpegBytes) async {
    if (_channel == null || _currentStatus == AiAssistantStatus.desconectado) {
      return;
    }

    final base64Image = base64Encode(jpegBytes);
    final imageInput = {
      'realtimeInput': {
        'mediaChunks': [
          {
            'mimeType': 'image/jpeg',
            'data': base64Image,
          }
        ],
      },
    };

    _channel!.sink.add(json.encode(imageInput));
  }

  @override
  Future<void> sendTextMessage(String text) async {
    if (_channel == null || _currentStatus == AiAssistantStatus.desconectado) {
      return;
    }

    _setStatus(AiAssistantStatus.pensando);
    final clientContent = {
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': text}
            ],
          }
        ],
        'turnComplete': true,
      },
    };

    _channel!.sink.add(json.encode(clientContent));
  }

  @override
  Future<void> interrupt() async {
    _setStatus(AiAssistantStatus.interrumpido);
    _setStatus(AiAssistantStatus.escuchando);
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setStatus(AiAssistantStatus.desconectado);
  }

  @override
  void dispose() {
    disconnect();
    _statusController.close();
    _transcriptController.close();
    _toolCallController.close();
  }
}
