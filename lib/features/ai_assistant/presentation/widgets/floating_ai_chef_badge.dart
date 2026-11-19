import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/ai_chef_provider.dart';
import '../../models/ai_session_state.dart';
import '../screens/ai_chef_modal.dart';

class FloatingAiChefBadge extends StatelessWidget {
  const FloatingAiChefBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final aiProv = Provider.of<AiChefProvider?>(context, listen: true);
    if (aiProv == null) {
      return const SizedBox.shrink();
    }
    final status = aiProv.status;

    if (status == AiAssistantStatus.desconectado) {
      return const SizedBox.shrink();
    }

    Color bgColor = AppColors.mintSoft;
    Color iconBg = AppColors.primaryTeal;
    IconData iconData = Icons.psychology_alt_rounded;

    if (status == AiAssistantStatus.hablando) {
      bgColor = AppColors.accentOrange.withValues(alpha: 0.15);
      iconBg = AppColors.accentOrange;
      iconData = Icons.record_voice_over_rounded;
    } else if (status == AiAssistantStatus.pensando) {
      bgColor = AppColors.highlightYellow.withValues(alpha: 0.3);
      iconBg = AppColors.highlightYellow;
      iconData = Icons.hourglass_top_rounded;
    } else if (status == AiAssistantStatus.escuchando) {
      bgColor = AppColors.mintSoft;
      iconBg = AppColors.primaryTeal;
      iconData = Icons.mic_rounded;
    } else if (status == AiAssistantStatus.error) {
      bgColor = AppColors.errorCoral.withValues(alpha: 0.2);
      iconBg = AppColors.errorCoral;
      iconData = Icons.error_outline_rounded;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: GestureDetector(
          onTap: () => AiChefModal.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.outlineDark, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.outlineDark.withValues(alpha: 0.15),
                  offset: const Offset(2, 3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    size: 16,
                    color: status == AiAssistantStatus.pensando
                        ? AppColors.textDark
                        : Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'La Chef activa',
                          style: AppTypography.badge.copyWith(
                            color: AppColors.primaryDarkTeal,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: iconBg,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      status.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outlineDark, width: 1),
                  ),
                  child: Text(
                    'Toca para abrir',
                    style: AppTypography.badge.copyWith(
                      color: AppColors.textDark,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => aiProv.endSession(),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
