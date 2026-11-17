import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/cooking_timer.dart';

class TimerCard extends StatelessWidget {
  final CookingTimer timer;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onAddMinute;
  final VoidCallback onRemoveMinute;
  final VoidCallback onCancel;

  const TimerCard({
    super.key,
    required this.timer,
    required this.onPause,
    required this.onResume,
    required this.onAddMinute,
    required this.onRemoveMinute,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isFinished = timer.isFinished;
    final isRunning = timer.isRunning;

    Color borderColor = AppColors.outlineDark;
    Color headerBg = AppColors.mintSoft;

    if (isFinished) {
      borderColor = AppColors.errorCoral;
      headerBg = AppColors.errorCoral.withValues(alpha: 0.15);
    } else if (isRunning) {
      headerBg = AppColors.highlightYellow.withValues(alpha: 0.4);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.outlineDark.withValues(alpha: 0.08),
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cabecera
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isFinished
                          ? Icons.notifications_active_rounded
                          : Icons.timer_outlined,
                      color: isFinished
                          ? AppColors.errorCoral
                          : AppColors.primaryTeal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timer.label,
                      style: AppTypography.titleMedium.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isFinished
                        ? AppColors.errorCoral
                        : (isRunning
                            ? AppColors.primaryTeal
                            : AppColors.mintMedium),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    timer.status.label,
                    style: AppTypography.badge.copyWith(
                      color: (isFinished || isRunning)
                          ? Colors.white
                          : AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cuerpo: tiempo y barra de progreso
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  timer.formattedTime,
                  style: AppTypography.displayMedium.copyWith(
                    fontSize: 36,
                    color: isFinished
                        ? AppColors.errorCoral
                        : AppColors.textDark,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: timer.progress,
                    minHeight: 8,
                    backgroundColor: AppColors.mintSoft,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFinished ? AppColors.errorCoral : AppColors.primaryTeal,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Fila 1: Pausar/Reanudar + Cancelar
                if (!isFinished)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isRunning ? onPause : onResume,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          icon: Icon(
                            isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 20,
                          ),
                          label: Text(isRunning ? 'Pausar' : 'Reanudar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.errorCoral),
                        tooltip: 'Cancelar temporizador',
                        onPressed: onCancel,
                      ),
                    ],
                  ),
                const SizedBox(height: 8),

                // Fila 2: -1 min y +1 min
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRemoveMinute,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          side: const BorderSide(
                              color: AppColors.outlineDark, width: 1.5),
                        ),
                        icon: const Icon(Icons.remove, size: 18),
                        label: const Text('-1 min'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAddMinute,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          backgroundColor: AppColors.highlightYellow,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('+1 min'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
