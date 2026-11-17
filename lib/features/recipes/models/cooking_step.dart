/// Paso de preparación en el Modo Cocina
class CookingStep {
  final String id;
  final int stepNumber;
  final String title;
  final String instruction;
  final int? timerMinutes;
  final String? timerLabel;
  final List<String> relevantIngredientIds;
  final String? chefTip;

  const CookingStep({
    required this.id,
    required this.stepNumber,
    required this.title,
    required this.instruction,
    this.timerMinutes,
    this.timerLabel,
    this.relevantIngredientIds = const [],
    this.chefTip,
  });

  bool get hasTimer => timerMinutes != null && timerMinutes! > 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stepNumber': stepNumber,
      'title': title,
      'instruction': instruction,
      'timerMinutes': timerMinutes,
      'timerLabel': timerLabel,
      'relevantIngredientIds': relevantIngredientIds,
      'chefTip': chefTip,
    };
  }

  factory CookingStep.fromMap(Map<String, dynamic> map) {
    return CookingStep(
      id: map['id'] as String,
      stepNumber: map['stepNumber'] as int,
      title: map['title'] as String? ?? 'Paso ${map['stepNumber']}',
      instruction: map['instruction'] as String,
      timerMinutes: map['timerMinutes'] as int?,
      timerLabel: map['timerLabel'] as String?,
      relevantIngredientIds:
          List<String>.from(map['relevantIngredientIds'] ?? const []),
      chefTip: map['chefTip'] as String?,
    );
  }
}
