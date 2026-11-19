import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/ai_session_state.dart';
import 'asistente_ia.dart';
import 'ai_context_builder.dart';

/// Cliente oficial para la Live API de Gemini por WebSocket bidireccional
/// Compatible con Gemini 3.8 Live (gemini-3.8-live) en v1beta.
class GeminiLiveClient implements AsistenteIA {
  final String apiKey;
  final String model;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final _statusController = StreamController<AiAssistantStatus>.broadcast();
  final _transcriptController = StreamController<String>.broadcast();
  final _userTranscriptController = StreamController<String>.broadcast();
  final _audioOutputController = StreamController<List<int>>.broadcast();
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
    _setStatus(AiAssistantStatus.conectando);

    try {
      // Endpoint oficial v1beta para Gemini 3.8 Live
      final wsUrl = Uri.parse(
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$apiKey',
      );

      debugPrint('[comiAPP GeminiLiveClient] Conectando a Gemini Live WebSocket (v1beta)...');
      _channel = WebSocketChannel.connect(wsUrl);
      await _channel!.ready;

      // Normalizar nombre del modelo (asegurar prefijo 'models/')
      final modelResource =
          model.startsWith('models/') ? model : 'models/$model';

      // Instrucciones del sistema y declaración de herramientas (Function Calling)
      final systemInstruction =
          AiContextBuilder.buildSystemInstruction(context);
      final tools = AiContextBuilder.getToolDeclarations();

      // Setup handshake oficial según especificación Gemini 3.8 Live:
      // - Modalidad de respuesta: exclusivamente AUDIO
      // - outputAudioTranscription: {} para obtener subtítulos de voz del modelo
      // - inputAudioTranscription: {} para transcripción de lo que habla el usuario
      final setupMessage = {
        'setup': {
          'model': modelResource,
          'generationConfig': {
            'responseModalities': ['AUDIO'],
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
          'outputAudioTranscription': {},
          'inputAudioTranscription': {},
        },
      };

      debugPrint('[comiAPP GeminiLiveClient] Enviando BidiGenerateContentSetup: $modelResource');
      _channel!.sink.add(json.encode(setupMessage));
      _listenToMessages();
      _setStatus(AiAssistantStatus.escuchando);
    } catch (e) {
      debugPrint('[comiAPP GeminiLiveClient] Error al conectar a Gemini Live: $e');
      _setStatus(AiAssistantStatus.error);
    }
  }

  void _listenToMessages() {
    _subscription = _channel?.stream.listen(
      (data) {
        try {
          final rawString = data is String ? data : utf8.decode(data);
          final message = json.decode(rawString) as Map<String, dynamic>;

          // 0. Errores del servidor
          if (message.containsKey('error')) {
            debugPrint('[comiAPP GeminiLiveClient] Error recibido del servidor: ${message['error']}');
            _setStatus(AiAssistantStatus.error);
            return;
          }

          // 1. Confirmación de Setup completado
          if (message.containsKey('setupComplete')) {
            debugPrint('[comiAPP GeminiLiveClient] BidiGenerateContentSetupComplete recibido.');
            _setStatus(AiAssistantStatus.escuchando);
            return;
          }

          // 2. Manejo de contenido del servidor
          final serverContent = message['serverContent'] as Map<String, dynamic>?;
          if (serverContent != null) {
            // Manejo de Barge-in (Interrupción de voz del usuario)
            if (serverContent['interrupted'] == true) {
              debugPrint('[comiAPP GeminiLiveClient] Barge-in detectado (interrupted: true).');
              _setStatus(AiAssistantStatus.interrumpido);
              _setStatus(AiAssistantStatus.escuchando);
              return;
            }

            // 3. Transcripción de lo que dice el usuario (inputTranscription)
            final inputTranscription = serverContent['inputTranscription'];
            if (inputTranscription != null && inputTranscription['text'] != null) {
              final userText = inputTranscription['text'] as String;
              if (userText.trim().isNotEmpty) {
                debugPrint('[comiAPP GeminiLiveClient] Transcripción del usuario: "$userText"');
                _userTranscriptController.add(userText);
              }
            }

            // 4. Transcripción de lo que responde el Chef (outputAudioTranscription)
            final outputTranscription = serverContent['outputTranscription'];
            if (outputTranscription != null && outputTranscription['text'] != null) {
              final text = outputTranscription['text'] as String;
              if (text.isNotEmpty) {
                _setStatus(AiAssistantStatus.hablando);
                _transcriptController.add(text);
              }
            }

            // 5. ModelTurn: Chunks de audio PCM y texto alternativo
            final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>?;
            if (modelTurn != null) {
              _setStatus(AiAssistantStatus.hablando);
              final parts = modelTurn['parts'] as List<dynamic>? ?? [];
              for (final part in parts) {
                if (part is Map<String, dynamic>) {
                  // Texto directo (si viene incluido)
                  if (part['text'] != null) {
                    final text = part['text'] as String;
                    if (text.isNotEmpty) {
                      _transcriptController.add(text);
                    }
                  }
                  // Chunks de audio PCM (24kHz, 16-bit, mono)
                  if (part['inlineData'] != null && part['inlineData']['data'] != null) {
                    try {
                      final audioBytes = base64Decode(part['inlineData']['data'] as String);
                      _audioOutputController.add(audioBytes);
                    } catch (_) {}
                  }
                }
              }
            }

            if (serverContent['turnComplete'] == true) {
              _setStatus(AiAssistantStatus.escuchando);
            }
          }

          // 6. Manejo de llamadas a herramientas (Function Calling)
          final toolCall = message['toolCall'] as Map<String, dynamic>?;
          if (toolCall != null && toolCall['functionCalls'] != null) {
            final calls = toolCall['functionCalls'] as List<dynamic>;
            for (final call in calls) {
              if (call is Map<String, dynamic>) {
                final aiToolCall = AiToolCall(
                  callId: call['id'] as String? ?? 'call_${DateTime.now().millisecondsSinceEpoch}',
                  name: call['name'] as String? ?? '',
                  arguments: Map<String, dynamic>.from(call['args'] ?? {}),
                );
                debugPrint('[comiAPP GeminiLiveClient] Invocación de tool: ${aiToolCall.name}');
                _toolCallController.add(aiToolCall);
              }
            }
          }
        } catch (err) {
          debugPrint('[comiAPP GeminiLiveClient] Error procesando mensaje de WebSocket: $err');
        }
      },
      onError: (err) {
        debugPrint('[comiAPP GeminiLiveClient] Error en WebSocket Stream: $err');
        _setStatus(AiAssistantStatus.error);
      },
      onDone: () {
        debugPrint(
            '[comiAPP GeminiLiveClient] WebSocket cerrado. CloseCode: ${_channel?.closeCode}, CloseReason: ${_channel?.closeReason}');
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
    // Formato oficial WebSocket Gemini 3.8 Live para streaming y reapertura de turno
    final realtimeInput = {
      'realtimeInput': {
        'mediaChunks': [
          {
            'mimeType': AppConstants.inputAudioMimeType,
            'data': base64Audio,
          }
        ],
        'audio': {
          'mimeType': AppConstants.inputAudioMimeType,
          'data': base64Audio,
        },
      },
    };

    _channel!.sink.add(json.encode(realtimeInput));
  }

  @override
  Future<void> sendAudioStreamEnd() async {
    if (_channel == null || _currentStatus == AiAssistantStatus.desconectado) {
      return;
    }

    final endMessage = {
      'realtimeInput': {
        'audioStreamEnd': true,
      },
    };

    _channel!.sink.add(json.encode(endMessage));
    debugPrint('[comiAPP GeminiLiveClient] audioStreamEnd enviado (finalización inmediata de turno).');
  }

  @override
  Future<void> sendCameraFrame(List<int> jpegBytes) async {
    if (_channel == null || _currentStatus == AiAssistantStatus.desconectado) {
      return;
    }

    // Validar tamaño mínimo de un JPEG real
    if (jpegBytes.length < 100) {
      debugPrint('[comiAPP GeminiLiveClient] Fotograma ignorado (longitud insuficiente: ${jpegBytes.length} bytes)');
      return;
    }

    final base64Image = base64Encode(jpegBytes);
    // Formato oficial WebSocket Gemini 3.8 Live para imágenes
    final imageInput = {
      'realtimeInput': {
        'video': {
          'mimeType': 'image/jpeg',
          'data': base64Image,
        },
      },
    };

    _channel!.sink.add(json.encode(imageInput));
    debugPrint('[comiAPP GeminiLiveClient] Fotograma JPEG enviado exitosamente (${jpegBytes.length} bytes)');
  }

  @override
  Future<void> sendTextMessage(String text) async {
    if (_channel == null || _currentStatus == AiAssistantStatus.desconectado) {
      return;
    }

    _setStatus(AiAssistantStatus.pensando);
    // Usar clientContent con turnComplete:true para finalizar el turno correctamente
    // (realtimeInput.text no emite turnComplete automático del servidor)
    final textInput = {
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

    _channel!.sink.add(json.encode(textInput));
    debugPrint('[comiAPP GeminiLiveClient] Texto enviado con turnComplete: "$text"');
  }

  @override
  Future<void> sendToolResponse(
      String callId, String functionName, String result) async {
    if (_channel == null || _currentStatus == AiAssistantStatus.desconectado) {
      return;
    }

    // Formato oficial BidiGenerateContentToolResponse
    final toolResponse = {
      'toolResponse': {
        'functionResponses': [
          {
            'id': callId,
            'name': functionName,
            'response': {
              'output': result,
            },
          }
        ],
      },
    };

    _channel!.sink.add(json.encode(toolResponse));
    debugPrint(
        '[comiAPP GeminiLiveClient] toolResponse enviado para "$functionName" (id: $callId): "$result"');
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
    _userTranscriptController.close();
    _audioOutputController.close();
    _toolCallController.close();
  }
}
