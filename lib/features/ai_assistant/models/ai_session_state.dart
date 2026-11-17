/// Estados claros del asistente requeridos por la guía de UX:
/// escuchando / pensando / hablando / interrumpido (barge-in)
enum AiAssistantStatus {
  desconectado,
  conectando,
  escuchando,
  pensando,
  hablando,
  interrumpido,
  error,
}

extension AiAssistantStatusExt on AiAssistantStatus {
  String get label {
    switch (this) {
      case AiAssistantStatus.desconectado:
        return 'Desconectado';
      case AiAssistantStatus.conectando:
        return 'Conectando con el Chef...';
      case AiAssistantStatus.escuchando:
        return 'Escuchando...';
      case AiAssistantStatus.pensando:
        return 'El Chef está pensando...';
      case AiAssistantStatus.hablando:
        return 'Chef hablando';
      case AiAssistantStatus.interrumpido:
        return 'Interrumpido';
      case AiAssistantStatus.error:
        return 'Error de conexión';
    }
  }
}

/// Mensaje en el diálogo de voz o fallback de texto
class AiMessage {
  final String id;
  final String sender; // 'usuario', 'chef', 'sistema'
  final String text;
  final DateTime timestamp;

  const AiMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  bool get isChef => sender == 'chef';
  bool get isUser => sender == 'usuario';
}

/// Solicitud de acción enviada por el modelo (Function Calling)
class AiToolCall {
  final String callId;
  final String name;
  final Map<String, dynamic> arguments;

  const AiToolCall({
    required this.callId,
    required this.name,
    required this.arguments,
  });
}
