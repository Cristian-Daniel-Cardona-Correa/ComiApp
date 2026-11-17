/// Utilidad para el cálculo y reescalado de porciones en recetas
class PortionCalculator {
  PortionCalculator._();

  /// Re-escala la cantidad de un ingrediente según las porciones objetivo
  static double scaleQuantity({
    required double baseQuantity,
    required int basePortions,
    required int targetPortions,
  }) {
    if (basePortions <= 0) return baseQuantity;
    if (targetPortions <= 0) return 0;
    final ratio = targetPortions / basePortions;
    return baseQuantity * ratio;
  }

  /// Formatea la cantidad para presentación limpia (ej: 2.0 -> '2', 1.5 -> '1.5', 0.25 -> '1/4')
  static String formatQuantity(double quantity) {
    if (quantity <= 0) return 'al gusto';

    // Redondear a 2 decimales para evitar problemas de coma flotante
    final rounded = (quantity * 100).round() / 100;

    // Si es entero
    if (rounded == rounded.truncateToDouble()) {
      return rounded.toInt().toString();
    }

    // Fracciones comunes de cocina
    final integerPart = rounded.truncate();
    final decimalPart = (rounded - integerPart);

    String fraction = '';
    if ((decimalPart - 0.25).abs() < 0.05) {
      fraction = '1/4';
    } else if ((decimalPart - 0.33).abs() < 0.05) {
      fraction = '1/3';
    } else if ((decimalPart - 0.50).abs() < 0.05) {
      fraction = '1/2';
    } else if ((decimalPart - 0.66).abs() < 0.05) {
      fraction = '2/3';
    } else if ((decimalPart - 0.75).abs() < 0.05) {
      fraction = '3/4';
    }

    if (fraction.isNotEmpty) {
      return integerPart > 0 ? '$integerPart $fraction' : fraction;
    }

    return rounded.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }
}
