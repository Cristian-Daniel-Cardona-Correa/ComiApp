import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class PortionSelector extends StatelessWidget {
  final int portions;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const PortionSelector({
    super.key,
    required this.portions,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineDark, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline_rounded,
              color: AppColors.primaryDarkTeal),
          const SizedBox(width: 8),
          Text(
            'Porciones:',
            style: AppTypography.titleMedium.copyWith(fontSize: 16),
          ),
          const SizedBox(width: 14),
          // Botón menos
          InkWell(
            onTap: portions > 1 ? onDecrement : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: portions > 1 ? Colors.white : Colors.white54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineDark, width: 1.5),
              ),
              child: const Icon(Icons.remove_rounded,
                  size: 20, color: AppColors.textDark),
            ),
          ),
          const SizedBox(width: 14),
          // Contador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineDark, width: 1.5),
            ),
            child: Text(
              '$portions',
              style: AppTypography.titleLarge.copyWith(fontSize: 20),
            ),
          ),
          const SizedBox(width: 14),
          // Botón más
          InkWell(
            onTap: portions < 20 ? onIncrement : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: portions < 20
                    ? AppColors.accentOrange
                    : AppColors.accentOrange.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineDark, width: 1.5),
              ),
              child: const Icon(Icons.add_rounded,
                  size: 20, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
