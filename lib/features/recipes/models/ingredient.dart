import '../../../core/utils/portion_calculator.dart';

/// Modelo de ingrediente de una receta
class Ingredient {
  final String id;
  final String name;
  final double baseQuantity;
  final String unit;
  final String? notes;
  final String? category;

  const Ingredient({
    required this.id,
    required this.name,
    required this.baseQuantity,
    required this.unit,
    this.notes,
    this.category,
  });

  /// Calcula la cantidad reescalada según las porciones deseadas
  double getScaledQuantity(int basePortions, int targetPortions) {
    return PortionCalculator.scaleQuantity(
      baseQuantity: baseQuantity,
      basePortions: basePortions,
      targetPortions: targetPortions,
    );
  }

  /// Retorna la cantidad formateada (ej: "200 g", "1 1/2 cda", "al gusto")
  String getFormattedQuantity(int basePortions, int targetPortions) {
    if (baseQuantity <= 0) return 'al gusto';
    final scaled = getScaledQuantity(basePortions, targetPortions);
    final formattedNum = PortionCalculator.formatQuantity(scaled);
    return unit.isEmpty ? formattedNum : '$formattedNum $unit';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'baseQuantity': baseQuantity,
      'unit': unit,
      'notes': notes,
      'category': category,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as String,
      name: map['name'] as String,
      baseQuantity: (map['baseQuantity'] as num).toDouble(),
      unit: map['unit'] as String? ?? '',
      notes: map['notes'] as String?,
      category: map['category'] as String?,
    );
  }
}
