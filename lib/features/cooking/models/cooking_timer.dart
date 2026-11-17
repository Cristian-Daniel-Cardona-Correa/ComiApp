import 'dart:convert';

/// Estados requeridos por la especificación: sugerido, corriendo, pausado, terminado
enum TimerStatus {
  sugerido,
  corriendo,
  pausado,
  terminado,
}

extension TimerStatusExt on TimerStatus {
  String get label {
    switch (this) {
      case TimerStatus.sugerido:
        return 'Sugerido';
      case TimerStatus.corriendo:
        return 'En curso';
      case TimerStatus.pausado:
        return 'Pausado';
      case TimerStatus.terminado:
        return '¡Listo!';
    }
  }
}

/// Modelo de Temporizador Culinario Simultáneo
class CookingTimer {
  final String id;
  final String label;
  final String recipeId;
  final String stepId;
  final int totalDurationSeconds;
  final int remainingSeconds;
  final DateTime? deadline;
  final TimerStatus status;

  const CookingTimer({
    required this.id,
    required this.label,
    required this.recipeId,
    required this.stepId,
    required this.totalDurationSeconds,
    required this.remainingSeconds,
    this.deadline,
    this.status = TimerStatus.sugerido,
  });

  bool get isRunning => status == TimerStatus.corriendo;
  bool get isPaused => status == TimerStatus.pausado;
  bool get isFinished => status == TimerStatus.terminado || remainingSeconds <= 0;

  double get progress {
    if (totalDurationSeconds <= 0) return 0;
    final elapsed = totalDurationSeconds - remainingSeconds;
    return (elapsed / totalDurationSeconds).clamp(0.0, 1.0);
  }

  /// Formato mm:ss para temporizadores culinarios
  String get formattedTime {
    final secs = remainingSeconds < 0 ? 0 : remainingSeconds;
    final minutes = secs ~/ 60;
    final seconds = secs % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  CookingTimer copyWith({
    String? id,
    String? label,
    String? recipeId,
    String? stepId,
    int? totalDurationSeconds,
    int? remainingSeconds,
    DateTime? deadline,
    TimerStatus? status,
  }) {
    return CookingTimer(
      id: id ?? this.id,
      label: label ?? this.label,
      recipeId: recipeId ?? this.recipeId,
      stepId: stepId ?? this.stepId,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'recipeId': recipeId,
      'stepId': stepId,
      'totalDurationSeconds': totalDurationSeconds,
      'remainingSeconds': remainingSeconds,
      'deadline': deadline?.toIso8601String(),
      'status': status.name,
    };
  }

  factory CookingTimer.fromMap(Map<String, dynamic> map) {
    return CookingTimer(
      id: map['id'] as String,
      label: map['label'] as String,
      recipeId: map['recipeId'] as String,
      stepId: map['stepId'] as String,
      totalDurationSeconds: map['totalDurationSeconds'] as int,
      remainingSeconds: map['remainingSeconds'] as int,
      deadline: map['deadline'] != null
          ? DateTime.tryParse(map['deadline'] as String)
          : null,
      status: TimerStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TimerStatus.sugerido,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory CookingTimer.fromJson(String source) =>
      CookingTimer.fromMap(json.decode(source) as Map<String, dynamic>);
}
