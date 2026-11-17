import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/ai_session_state.dart';
import '../services/asistente_ia.dart';
import '../services/ai_context_builder.dart';
import '../services/gemini_live_client.dart';
import '../services/mock_gemini_live_client.dart';

class AiChefProvider extends ChangeNotifier {
  final AsistenteIA _assistant;
  final _uuid = const Uuid();

  AiAssistantStatus _status = AiAssistantStatus.desconectado;
  bool _isMicMuted = false;
  bool _isCameraActive = false;
  String _latestTranscript = '';
  final List<AiMessage> _messages = [];
  String? _lastToolActionResult;

  // Temporizador de duración de sesión y avisos de límites
  Timer? _sessionDurationTimer;
  int _sessionSeconds = 0;
  String? _sessionLimitWarning;

  StreamSubscription? _statusSub;
  StreamSubscription? _transcriptSub;
  StreamSubscription? _toolCallSub;

  // Callbacks para ejecutar acciones en la aplicación
  void Function()? onNextStepRequested;
  void Function()? onPreviousStepRequested;
  void Function(String label, int minutes)? onStartTimerRequested;
  void Function(String label)? onCancelTimerRequested;

  AiChefProvider({AsistenteIA? customAssistant, String apiKey = ''})
      : _assistant = customAssistant ??
            (apiKey.isNotEmpty && apiKey != 'mock_or_demo_key'
                ? GeminiLiveClient(apiKey: apiKey)
                : MockGeminiLiveClient()) {
    _subscribe();
  }

  AiAssistantStatus get status => _status;
  bool get isMicMuted => _isMicMuted;
  bool get isCameraActive => _isCameraActive;
  String get latestTranscript => _latestTranscript;
  List<AiMessage> get messages => _messages;
  String? get lastToolActionResult => _lastToolActionResult;
  String? get sessionLimitWarning => _sessionLimitWarning;
  int get sessionSeconds => _sessionSeconds;

  void _subscribe() {
    _statusSub = _assistant.statusStream.listen((newStatus) {
      _status = newStatus;
      notifyListeners();
    });

    _transcriptSub = _assistant.transcriptStream.listen((transcript) {
      _latestTranscript = transcript;
      _messages.add(
        AiMessage(
          id: _uuid.v4(),
          sender: 'chef',
          text: transcript,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    });

    _toolCallSub = _assistant.toolCallStream.listen((toolCall) {
      _handleToolCall(toolCall);
    });
  }

  void _handleToolCall(AiToolCall toolCall) {
    debugPrint('[comiAPP AiChefProvider] Ejecutando acción por voz: ${toolCall.name}');

    switch (toolCall.name) {
      case 'siguiente_paso':
        onNextStepRequested?.call();
        _lastToolActionResult = 'Avanzando al siguiente paso';
        break;

      case 'paso_anterior':
        onPreviousStepRequested?.call();
        _lastToolActionResult = 'Volviendo al paso anterior';
        break;

      case 'iniciar_temporizador':
        final name = toolCall.arguments['nombre'] as String? ?? 'Cocción';
        final mins = toolCall.arguments['minutos'] as int? ?? 5;
        onStartTimerRequested?.call(name, mins);
        _lastToolActionResult = 'Temporizador "$name" ($mins min) iniciado';
        break;

      case 'cancelar_temporizador':
        final name = toolCall.arguments['nombre'] as String? ?? '';
        onCancelTimerRequested?.call(name);
        _lastToolActionResult = 'Temporizador "$name" cancelado';
        break;

      case 'leer_ingredientes_del_paso':
        _lastToolActionResult = 'Ingredientes del paso leídos';
        break;
    }

    notifyListeners();
  }

  Future<void> startSession(AiCookingContext context) async {
    _sessionSeconds = 0;
    _sessionLimitWarning = null;
    _startSessionTimer();
    await _assistant.connect(context);
  }

  void _startSessionTimer() {
    _sessionDurationTimer?.cancel();
    _sessionDurationTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      _sessionSeconds++;

      // Límites de la UI requeridos por la especificación:
      // "solo audio ≈ 15 min; audio + video ≈ 2 min"
      if (_isCameraActive && _sessionSeconds >= AppConstants.maxVideoSessionMinutes * 60) {
        _sessionLimitWarning =
            'Límite de video alcanzado (2 min). La cámara se apagará para mantener el audio.';
        _isCameraActive = false;
        notifyListeners();
      } else if (_sessionSeconds >=
          (AppConstants.maxAudioSessionMinutes * 60 -
              AppConstants.sessionTimeoutWarningSeconds)) {
        _sessionLimitWarning =
            'La sesión de voz finalizará en 1 minuto por límite de conexión.';
        notifyListeners();
      }
    });
  }

  void toggleMic() {
    _isMicMuted = !_isMicMuted;
    notifyListeners();
  }

  void toggleCamera() {
    _isCameraActive = !_isCameraActive;
    if (_isCameraActive) {
      // Simulación de fotograma JPEG de cámara (768x768)
      _assistant.sendCameraFrame([0xFF, 0xD8, 0xFF, 0xE0]);
    }
    notifyListeners();
  }

  void interruptChef() {
    _assistant.interrupt();
  }

  Future<void> sendUserText(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(
      AiMessage(
        id: _uuid.v4(),
        sender: 'usuario',
        text: text.trim(),
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    await _assistant.sendTextMessage(text.trim());
  }

  Future<void> endSession() async {
    _sessionDurationTimer?.cancel();
    _sessionDurationTimer = null;
    await _assistant.disconnect();
    _isCameraActive = false;
    _isMicMuted = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionDurationTimer?.cancel();
    _statusSub?.cancel();
    _transcriptSub?.cancel();
    _toolCallSub?.cancel();
    _assistant.dispose();
    super.dispose();
  }
}
