import 'package:flutter_test/flutter_test.dart';
import 'package:comiapp/core/utils/portion_calculator.dart';
import 'package:comiapp/features/recipes/models/ingredient.dart';

void main() {
  group('PortionCalculator unit tests', () {
    test('Calculates exact scaling when doubling portions', () {
      final scaled = PortionCalculator.scaleQuantity(
        baseQuantity: 200,
        basePortions: 2,
        targetPortions: 4,
      );
      expect(scaled, 400.0);
    });

    test('Calculates exact scaling when halving portions', () {
      final scaled = PortionCalculator.scaleQuantity(
        baseQuantity: 300,
        basePortions: 4,
        targetPortions: 2,
      );
      expect(scaled, 150.0);
    });

    test('Formats integers without decimals', () {
      expect(PortionCalculator.formatQuantity(4.0), '4');
      expect(PortionCalculator.formatQuantity(1.0), '1');
    });

    test('Formats culinary fractions correctly', () {
      expect(PortionCalculator.formatQuantity(0.5), '1/2');
      expect(PortionCalculator.formatQuantity(1.5), '1 1/2');
      expect(PortionCalculator.formatQuantity(0.25), '1/4');
      expect(PortionCalculator.formatQuantity(0.75), '3/4');
    });

    test('Handles zero and negative gracefully', () {
      expect(PortionCalculator.formatQuantity(0), 'al gusto');
    });
  });

  group('Ingredient model scaling tests', () {
    const ingredient = Ingredient(
      id: 'carb_1',
      name: 'Espaguetis',
      baseQuantity: 200,
      unit: 'g',
    );

    test('Ingredient scales and formats correctly for 3 portions from 2', () {
      final scaled = ingredient.getScaledQuantity(2, 3);
      expect(scaled, 300.0);
      expect(ingredient.getFormattedQuantity(2, 3), '300 g');
    });

    test('Ingredient with 0 base quantity displays al gusto', () {
      const pinchOfSalt = Ingredient(
        id: 'salt',
        name: 'Sal al gusto',
        baseQuantity: 0,
        unit: '',
      );
      expect(pinchOfSalt.getFormattedQuantity(2, 6), 'al gusto');
    });
  });
}
