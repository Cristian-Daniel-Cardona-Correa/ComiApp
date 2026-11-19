import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/ai_session_state.dart';
import '../services/asistente_ia.dart';
import '../services/ai_context_builder.dart';
import '../services/gemini_live_client.dart';
import '../services/mock_gemini_live_client.dart';
import '../services/gemini_live_audio_manager.dart';

class AiChefProvider extends ChangeNotifier {
  AsistenteIA _assistant;
  final _uuid = const Uuid();
  final GeminiLiveAudioManager _audioManager = GeminiLiveAudioManager();

  String _currentApiKey = '';
  String _currentModel = AppConstants.defaultGeminiLiveModel;

  AiAssistantStatus _status = AiAssistantStatus.desconectado;
  bool _isMicMuted = true; // Por defecto SIEMPRE silenciado (Push-to-Talk)
  bool _isCameraActive = false;
  String _latestTranscript = '';
  final List<AiMessage> _messages = [];
  String? _lastToolActionResult;
  String? _currentRecipeId;

  // Control de agrupación de mensajes en streaming
  bool _isChefTurnActive = false;
  bool _isUserVoiceTurnActive = false;

  // Temporizador de duración de sesión y avisos de límites
  Timer? _sessionDurationTimer;
  int _sessionSeconds = 0;
  int _cameraActiveSeconds = 0;
  String? _sessionLimitWarning;
  String? _lastCapturedPhotoPath;

  // Watchdog: detecta estado "pensando" colgado y fuerza reconexión
  Timer? _watchdogTimer;
  static const Duration _watchdogTimeout = Duration(seconds: 14);

  // Contexto para reconexión automática
  AiCookingContext? _lastSessionContext;

  StreamSubscription? _statusSub;
  StreamSubscription? _transcriptSub;
  StreamSubscription? _userTranscriptSub;
  StreamSubscription? _audioOutputSub;
  StreamSubscription? _toolCallSub;

  // Callbacks para ejecutar acciones en la aplicación
  void Function()? onNextStepRequested;
  void Function()? onPreviousStepRequested;
  void Function(String label, int minutes)? onStartTimerRequested;
  void Function(String label)? onCancelTimerRequested;

  AiChefProvider({
    AsistenteIA? customAssistant,
    String apiKey = '',
    String model = AppConstants.defaultGeminiLiveModel,
  })  : _currentApiKey = apiKey,
        _currentModel = model,
        _assistant = customAssistant ??
            (apiKey.isNotEmpty && apiKey != 'mock_or_demo_key'
                ? GeminiLiveClient(apiKey: apiKey, model: model)
                : MockGeminiLiveClient()) {
    _subscribe();
  }

  bool get isRealGeminiLive => _assistant is GeminiLiveClient;
  String get currentApiKey => _currentApiKey;
  String get currentModel => _currentModel;

  Future<void> setApiKey(String key, {String? model}) async {
    final cleanKey = key.trim();
    _currentApiKey = cleanKey;
    if (model != null && model.isNotEmpty) {
      _currentModel = model;
    }

    if (cleanKey.isNotEmpty && cleanKey != 'mock_or_demo_key') {
      _assistant = GeminiLiveClient(apiKey: cleanKey, model: _currentModel);
    } else {
      _assistant = MockGeminiLiveClient();
    }

    _statusSub?.cancel();
    _transcriptSub?.cancel();
    _userTranscriptSub?.cancel();
    _audioOutputSub?.cancel();
    _toolCallSub?.cancel();
    _subscribe();
    notifyListeners();
  }

  AiAssistantStatus get status => _status;
  bool get isSessionActive =>
      _status != AiAssistantStatus.desconectado &&
      _status != AiAssistantStatus.error;
  bool get isMicMuted => _isMicMuted;
  bool get isRecordingSpeech => !_isMicMuted;
  bool get isCameraActive => _isCameraActive;
  Stream<double> get voiceLevelStream => _audioManager.voiceLevelStream;
  String get latestTranscript => _latestTranscript;
  List<AiMessage> get messages => _messages;
  String? get lastToolActionResult => _lastToolActionResult;
  String? get sessionLimitWarning => _sessionLimitWarning;
  int get sessionSeconds => _sessionSeconds;
  String? get currentRecipeId => _currentRecipeId;
  String? get lastCapturedPhotoPath => _lastCapturedPhotoPath;

  void setCapturedPhoto(String path) {
    _lastCapturedPhotoPath = path;
    notifyListeners();
  }

  void clearCapturedPhoto() {
    _lastCapturedPhotoPath = null;
    notifyListeners();
  }

  void clearSessionLimitWarning() {
    _sessionLimitWarning = null;
    notifyListeners();
  }

  /// Reinicia el historial del chat para iniciar una conversación limpia
  void clearConversation() {
    _messages.clear();
    _latestTranscript = '';
    _lastToolActionResult = null;
    _isChefTurnActive = false;
    _isUserVoiceTurnActive = false;
    notifyListeners();
  }

  void _subscribe() {
    _statusSub = _assistant.statusStream.listen((newStatus) {
      final oldStatus = _status;
      _status = newStatus;

      // Si la Chef terminó de hablar o la sesión pasa a escuchar, finalizar turno de audio
      if (newStatus == AiAssistantStatus.escuchando && oldStatus == AiAssistantStatus.hablando) {
        _isChefTurnActive = false;
        _audioManager.signalEndOfChefTurn();
      } else if (newStatus == AiAssistantStatus.interrumpido) {
        _isChefTurnActive = false;
        _audioManager.stopPlayback();
      }

      // Watchdog: si entra en "pensando", armar temporizador de seguridad
      if (newStatus == AiAssistantStatus.pensando) {
        _startWatchdog();
      } else {
        _cancelWatchdog();
      }

      notifyListeners();
    });

    // 1. Transcripción de lo que responde el Chef (agrupa chunks continuos en un solo mensaje)
    _transcriptSub = _assistant.transcriptStream.listen((transcriptChunk) {
      _handleChefTranscriptChunk(transcriptChunk);
    });

    // 2. Transcripción de lo que habla el usuario por voz en tiempo real
    _userTranscriptSub = _assistant.userTranscriptStream.listen((userSpeechText) {
      _handleUserVoiceTranscript(userSpeechText);
    });

    // 3. Chunks de audio PCM generados por el modelo (24kHz)
    _audioOutputSub = _assistant.audioOutputStream.listen((pcmChunk) {
      _audioManager.addPcmAudioChunk(pcmChunk);
    });

    // 4. Invocación de herramientas (Function Calling)
    _toolCallSub = _assistant.toolCallStream.listen((toolCall) {
      _handleToolCall(toolCall); // fire-and-forget async
    });
  }

  /// Agrupa los fragmentos de streaming del Chef en un único mensaje cohesivo
  void _handleChefTranscriptChunk(String chunk) {
    if (chunk.isEmpty) return;
    _isUserVoiceTurnActive = false;

    if (_isChefTurnActive &&
        _messages.isNotEmpty &&
        _messages.last.sender == 'chef') {
      final lastMsg = _messages.last;
      _messages[_messages.length - 1] = AiMessage(
        id: lastMsg.id,
        sender: 'chef',
        text: lastMsg.text + chunk,
        timestamp: lastMsg.timestamp,
      );
    } else {
      _isChefTurnActive = true;
      _messages.add(
        AiMessage(
          id: _uuid.v4(),
          sender: 'chef',
          text: chunk,
          timestamp: DateTime.now(),
        ),
      );
    }

    _latestTranscript = _messages.last.text;
    notifyListeners();
  }

  /// Registra en el chat lo que el usuario está diciendo por voz
  void _handleUserVoiceTranscript(String userText) {
    final clean = userText.trim();
    if (clean.isEmpty) return;

    _isChefTurnActive = false;

    if (_isUserVoiceTurnActive &&
        _messages.isNotEmpty &&
        _messages.last.sender == 'usuario') {
      final lastMsg = _messages.last;
      _messages[_messages.length - 1] = AiMessage(
        id: lastMsg.id,
        sender: 'usuario',
        text: clean,
        timestamp: lastMsg.timestamp,
      );
    } else {
      _isUserVoiceTurnActive = true;
      _messages.add(
        AiMessage(
          id: _uuid.v4(),
          sender: 'usuario',
          text: clean,
          timestamp: DateTime.now(),
        ),
      );
    }

    notifyListeners();
  }

  Future<void> _handleToolCall(AiToolCall toolCall) async {
    debugPrint('[comiAPP AiChefProvider] Ejecutando acción por voz: ${toolCall.name}');
    String resultText = '';

    switch (toolCall.name) {
      case 'siguiente_paso':
        onNextStepRequested?.call();
        resultText = 'Avanzando al siguiente paso';
        break;

      case 'paso_anterior':
        onPreviousStepRequested?.call();
        resultText = 'Volviendo al paso anterior';
        break;

      case 'iniciar_temporizador':
        final name = toolCall.arguments['nombre'] as String? ?? 'Cocción';
        final mins = toolCall.arguments['minutos'] as int? ?? 5;
        onStartTimerRequested?.call(name, mins);
        resultText = 'Temporizador "$name" de $mins minutos iniciado correctamente';
        break;

      case 'cancelar_temporizador':
        final name = toolCall.arguments['nombre'] as String? ?? '';
        onCancelTimerRequested?.call(name);
        resultText = 'Temporizador "$name" cancelado';
        break;

      case 'leer_ingredientes_del_paso':
        resultText = 'Ingredientes del paso disponibles en pantalla';
        break;

      default:
        resultText = 'Acción ejecutada';
    }

    _lastToolActionResult = resultText;
    notifyListeners();

    // CRÍTICO: Enviar toolResponse a Gemini Live para desbloquear la generación de audio/texto
    await _assistant.sendToolResponse(toolCall.callId, toolCall.name, resultText);
  }

  /// Inicia el watchdog: si "pensando" dura más de [_watchdogTimeout], reconecta
  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(_watchdogTimeout, () {
      if (_status == AiAssistantStatus.pensando ||
          _status == AiAssistantStatus.error) {
        debugPrint('[comiAPP AiChefProvider] Watchdog activado — estado colgado, reconectando...');
        _isMicMuted = true;
        _isChefTurnActive = false;
        _isUserVoiceTurnActive = false;
        _audioManager.stopPlayback();
        if (_lastSessionContext != null) {
          _assistant.connect(_lastSessionContext!);
        }
      }
    });
  }

  void _cancelWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  /// Fuerza reconexión manual (por si el usuario lo necesita)
  Future<void> reconnect() async {
    if (_lastSessionContext == null) return;
    _cancelWatchdog();
    _isMicMuted = true;
    _isChefTurnActive = false;
    _isUserVoiceTurnActive = false;
    await _audioManager.stopPlayback();
    await _assistant.connect(_lastSessionContext!);
    notifyListeners();
  }

  Future<void> startSession(AiCookingContext context) async {
    // Si la sesión ya se encuentra activa para la misma receta, mantenerla viva sin reiniciar
    if (isSessionActive && _currentRecipeId == context.recipe.id) {
      debugPrint('[comiAPP AiChefProvider] Sesión ya activa para la receta ${context.recipe.id}. Continuando sin reiniciar conexión.');
      _lastSessionContext = context;
      notifyListeners();
      return;
    }

    _lastSessionContext = context;
    // Si es una receta distinta o nueva, reiniciar el historial de chat completamente
    if (_currentRecipeId != context.recipe.id) {
      _messages.clear();
      _latestTranscript = '';
      _lastToolActionResult = null;
      _currentRecipeId = context.recipe.id;
    }
    _sessionSeconds = 0;
    _cameraActiveSeconds = 0;
    _sessionLimitWarning = null;
    _lastCapturedPhotoPath = null;
    _isChefTurnActive = false;
    _isUserVoiceTurnActive = false;
    _startSessionTimer();

    // Por defecto el usuario siempre inicia silenciado
    _isMicMuted = true;

    // Conectar WebSocket con Gemini Live
    await _assistant.connect(context);
  }

  void _startSessionTimer() {
    _sessionDurationTimer?.cancel();
    _sessionDurationTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      _sessionSeconds++;

      // Límites de la UI requeridos por la especificación:
      // "solo audio ≈ 15 min; audio + video ≈ 2 min"
      if (_isCameraActive) {
        _cameraActiveSeconds++;
        if (_cameraActiveSeconds >= AppConstants.maxVideoSessionMinutes * 60) {
          _sessionLimitWarning =
              'Límite de cámara continua alcanzado (2 min). Se pausó la transmisión para mantener el audio fluido.';
          _isCameraActive = false;
          notifyListeners();
        }
      } else if (_sessionSeconds >=
          (AppConstants.maxAudioSessionMinutes * 60 -
              AppConstants.sessionTimeoutWarningSeconds)) {
        _sessionLimitWarning =
            'La sesión de voz finalizará en 1 minuto por límite de conexión.';
        notifyListeners();
      }
    });
  }

  /// Inicia la captura de voz del usuario (detiene audio previo y abre micrófono de forma segura)
  Future<void> startSpeaking() async {
    await _audioManager.stopPlayback();
    _isMicMuted = false;
    _status = AiAssistantStatus.escuchando;
    notifyListeners();

    await _audioManager.ensureMicrophoneStreaming(
      onPcmChunk: (pcmChunk) {
        _assistant.sendUserSpeechChunk(pcmChunk);
      },
    );
  }

  /// Finaliza la captura de voz y envía `audioStreamEnd: true` a Gemini Live
  /// para provocar la respuesta inmediata del Chef sin esperar silencios largos de VAD
  Future<void> stopSpeakingAndSend() async {
    if (_isMicMuted) return;
    _isMicMuted = true;
    await _audioManager.stopMicrophoneStream();
    await _assistant.sendAudioStreamEnd();
    _status = AiAssistantStatus.pensando;
    notifyListeners();
  }

  /// Alterna entre hablar y enviar (para pulsaciones simples de botón)
  Future<void> toggleMic() async {
    if (_isMicMuted) {
      await startSpeaking();
    } else {
      await stopSpeakingAndSend();
    }
  }

  void toggleCamera() {
    _isCameraActive = !_isCameraActive;
    if (_isCameraActive) {
      _cameraActiveSeconds = 0;
    }
    notifyListeners();
  }

  void sendCameraFrame(List<int> jpegBytes) {
    if (_isCameraActive && jpegBytes.isNotEmpty) {
      _assistant.sendCameraFrame(jpegBytes);
    }
  }

  void interruptChef() {
    _audioManager.stopPlayback();
    _isChefTurnActive = false;
    _assistant.interrupt();
  }

  Future<void> sendUserText(String text) async {
    if (text.trim().isEmpty) return;

    _isChefTurnActive = false;
    _isUserVoiceTurnActive = false;

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
    _cancelWatchdog();
    _sessionDurationTimer?.cancel();
    _sessionDurationTimer = null;
    await _audioManager.stopMicrophoneStream();
    await _audioManager.stopPlayback();
    await _assistant.disconnect();
    _isCameraActive = false;
    _cameraActiveSeconds = 0;
    _lastCapturedPhotoPath = null;
    _sessionLimitWarning = null;
    _isMicMuted = true;
    _isChefTurnActive = false;
    _isUserVoiceTurnActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelWatchdog();
    _sessionDurationTimer?.cancel();
    _statusSub?.cancel();
    _transcriptSub?.cancel();
    _userTranscriptSub?.cancel();
    _audioOutputSub?.cancel();
    _toolCallSub?.cancel();
    _audioManager.dispose();
    _assistant.dispose();
    super.dispose();
  }
}
