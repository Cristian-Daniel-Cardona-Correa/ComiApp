import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/timer_provider.dart';
import 'timer_card.dart';

class ActiveTimersSheet extends StatelessWidget {
  const ActiveTimersSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ActiveTimersSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerProv = context.watch<TimerProvider>();
    final timers = timerProv.timers;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.creamBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.outlineDark, width: 2.5),
          left: BorderSide(color: AppColors.outlineDark, width: 2.5),
          right: BorderSide(color: AppColors.outlineDark, width: 2.5),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Asa de arrastre
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.outlineDark.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cabecera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_rounded,
                        color: AppColors.primaryTeal, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Mis Tiempos (${timers.length})',
                      style: AppTypography.titleLarge,
                    ),
                  ],
                ),
                if (timers.isNotEmpty)
                  TextButton(
                    onPressed: () => timerProv.cancelAllTimers(),
                    child: Text(
                      'Cancelar todos',
                      style: AppTypography.button.copyWith(
                        color: AppColors.errorCoral,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Lista de temporizadores
            Flexible(
              child: timers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer_off_outlined,
                                size: 54, color: AppColors.primaryTeal),
                            const SizedBox(height: 12),
                            Text(
                              'No hay temporizadores activos',
                              style: AppTypography.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Inicia uno dentro de los pasos del modo cocina.',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: timers.length,
                      itemBuilder: (context, index) {
                        final timer = timers[index];
                        return TimerCard(
                          timer: timer,
                          onPause: () => timerProv.pauseTimer(timer.id),
                          onResume: () => timerProv.resumeTimer(timer.id),
                          onAddMinute: () => timerProv.addOneMinute(timer.id),
                          onCancel: () => timerProv.cancelTimer(timer.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
