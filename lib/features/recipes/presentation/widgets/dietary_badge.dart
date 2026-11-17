import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class DietaryBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;

  const DietaryBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = backgroundColor ?? AppColors.mintSoft;
    Color fg = textColor ?? AppColors.textDark;

    if (label.toLowerCase().contains('vegano') ||
        label.toLowerCase().contains('vegetariano')) {
      bg = AppColors.mintMedium;
    } else if (label.toLowerCase().contains('rápido')) {
      bg = AppColors.highlightYellow;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineDark, width: 1.5),
      ),
      child: Text(
        label,
        style: AppTypography.badge.copyWith(color: fg),
      ),
    );
  }
}
