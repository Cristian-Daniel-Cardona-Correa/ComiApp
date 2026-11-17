import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/timer_provider.dart';
import 'active_timers_sheet.dart';

class GlobalTimerBanner extends StatelessWidget {
  const GlobalTimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final timerProv = context.watch<TimerProvider>();
    final activeTimers = timerProv.activeTimers;

    if (activeTimers.isEmpty) {
      return const SizedBox.shrink();
    }

    final runningTimer =
        activeTimers.firstWhere((t) => t.isRunning, orElse: () => activeTimers.first);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: GestureDetector(
          onTap: () => ActiveTimersSheet.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.highlightYellow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outlineDark, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.outlineDark.withValues(alpha: 0.15),
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timer_rounded,
                    color: AppColors.primaryTeal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${activeTimers.length} temporizador${activeTimers.length > 1 ? 'es' : ''} en curso',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.textDark,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${runningTimer.label}: ${runningTimer.formattedTime}',
                        style: AppTypography.titleMedium.copyWith(fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => ActiveTimersSheet.show(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textDark,
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    elevation: 0,
                  ),
                  child: const Text('Ver', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
