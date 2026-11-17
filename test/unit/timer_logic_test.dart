import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:comiapp/features/cooking/models/cooking_timer.dart';
import 'package:comiapp/features/cooking/providers/timer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CookingTimer model tests', () {
    test('Formatted time handles minutes and seconds correctly', () {
      const timer = CookingTimer(
        id: 't1',
        label: 'Pasta',
        recipeId: 'r1',
        stepId: 's1',
        totalDurationSeconds: 540,
        remainingSeconds: 540, // 9 min
      );
      expect(timer.formattedTime, '09:00');
    });

    test('Progress calculation behaves correctly', () {
      const timer = CookingTimer(
        id: 't2',
        label: 'Salsa',
        recipeId: 'r1',
        stepId: 's2',
        totalDurationSeconds: 100,
        remainingSeconds: 50,
      );
      expect(timer.progress, 0.5);
    });
  });

  group('TimerProvider business logic tests', () {
    test('startTimer creates running timer with positive remaining seconds', () {
      final provider = TimerProvider();
      final timer = provider.startTimer(
        label: 'Prueba Arroz',
        recipeId: 'r1',
        stepId: 's1',
        minutes: 10,
      );

      expect(timer.isRunning, isTrue);
      expect(timer.remainingSeconds, 600);
      expect(provider.timers.length, 1);
      expect(provider.hasActiveTimers, isTrue);

      provider.dispose();
    });

    test('addOneMinute adds 60 seconds to existing timer', () {
      final provider = TimerProvider();
      final timer = provider.startTimer(
        label: 'Prueba Salmón',
        recipeId: 'r2',
        stepId: 's2',
        minutes: 4,
      );

      provider.addOneMinute(timer.id);
      final updated = provider.timers.firstWhere((t) => t.id == timer.id);
      expect(updated.remainingSeconds, 300); // 240 + 60
      expect(updated.totalDurationSeconds, 300);

      provider.dispose();
    });

    test('removeOneMinute subtracts 60 seconds from existing timer', () {
      final provider = TimerProvider();
      final timer = provider.startTimer(
        label: 'Prueba Té',
        recipeId: 'r3',
        stepId: 's3',
        minutes: 5,
      );

      provider.removeOneMinute(timer.id);
      final updated = provider.timers.firstWhere((t) => t.id == timer.id);
      expect(updated.remainingSeconds, 240); // 300 - 60
      expect(updated.totalDurationSeconds, 240);

      provider.dispose();
    });

    test('Multiple concurrent timers run in parallel', () {
      final provider = TimerProvider();
      final timer1 = provider.startTimer(
        label: 'Pasta',
        recipeId: 'r1',
        stepId: 's1',
        minutes: 8,
      );
      final timer2 = provider.startTimer(
        label: 'Salsa',
        recipeId: 'r1',
        stepId: 's2',
        minutes: 5,
      );

      expect(provider.activeTimers.length, 2);
      expect(provider.getTimerForStep('r1', 's1')?.id, timer1.id);
      expect(provider.getTimerForStep('r1', 's2')?.id, timer2.id);

      provider.cancelTimer(timer1.id);
      expect(provider.activeTimers.length, 1);

      provider.cancelAllTimers();
      expect(provider.activeTimers.isEmpty, isTrue);

      provider.dispose();
    });
  });
}
