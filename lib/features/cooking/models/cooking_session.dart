import 'dart:convert';

/// Progreso guardado por ID de receta y ID de paso
class CookingSession {
  final String recipeId;
  final String currentStepId;
  final int portions;
  final List<String> completedStepIds;
  final bool keepScreenAwake;
  final DateTime startedAt;

  const CookingSession({
    required this.recipeId,
    required this.currentStepId,
    required this.portions,
    this.completedStepIds = const [],
    this.keepScreenAwake = true,
    required this.startedAt,
  });

  CookingSession copyWith({
    String? recipeId,
    String? currentStepId,
    int? portions,
    List<String>? completedStepIds,
    bool? keepScreenAwake,
    DateTime? startedAt,
  }) {
    return CookingSession(
      recipeId: recipeId ?? this.recipeId,
      currentStepId: currentStepId ?? this.currentStepId,
      portions: portions ?? this.portions,
      completedStepIds: completedStepIds ?? this.completedStepIds,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipeId': recipeId,
      'currentStepId': currentStepId,
      'portions': portions,
      'completedStepIds': completedStepIds,
      'keepScreenAwake': keepScreenAwake,
      'startedAt': startedAt.toIso8601String(),
    };
  }

  factory CookingSession.fromMap(Map<String, dynamic> map) {
    return CookingSession(
      recipeId: map['recipeId'] as String,
      currentStepId: map['currentStepId'] as String,
      portions: map['portions'] as int? ?? 2,
      completedStepIds:
          List<String>.from(map['completedStepIds'] ?? const []),
      keepScreenAwake: map['keepScreenAwake'] as bool? ?? true,
      startedAt: map['startedAt'] != null
          ? DateTime.tryParse(map['startedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CookingSession.fromJson(String source) =>
      CookingSession.fromMap(json.decode(source) as Map<String, dynamic>);
}
