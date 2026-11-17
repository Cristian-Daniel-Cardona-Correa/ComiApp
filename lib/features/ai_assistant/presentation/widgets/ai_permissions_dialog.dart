import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Diálogo modal para solicitar autorización de acceso a Micrófono y Cámara
/// para el Asistente Culinario Gemini Live, cumpliendo con la política de Habeas Data.
class AiPermissionsDialog extends StatelessWidget {
  const AiPermissionsDialog({super.key});

  static Future<bool> requestConsent(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AiPermissionsDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.creamBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.outlineDark, width: 2),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.mintSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.perm_camera_mic_rounded,
                color: AppColors.primaryTeal, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Permisos para Chef IA',
              style: AppTypography.titleLarge.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Para guiarte mientras cocinas con manos libres, comiAPP necesita:',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 14),

            // Permiso Micrófono
            _PermissionItem(
              icon: Icons.mic_rounded,
              title: 'Micrófono (Voz en Vivo)',
              description:
                  'Permite escucharte cuando digas "siguiente paso", "iniciar temporizador" o hagas preguntas al chef.',
              color: AppColors.primaryTeal,
            ),
            const SizedBox(height: 12),

            // Permiso Cámara
            _PermissionItem(
              icon: Icons.videocam_rounded,
              title: 'Cámara (Visión Culinaria)',
              description:
                  'Permite que el chef vea la textura de tu comida, dorados y puntos de cocción en tu sartén.',
              color: AppColors.accentOrange,
            ),
            const SizedBox(height: 14),

            // Habeas Data badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.mintSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineDark, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded,
                      size: 20, color: AppColors.primaryTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Uso efímero (Ley 1581 Habeas Data): Ni el audio ni las imágenes se almacenan en servidores.',
                      style: AppTypography.bodySmall
                          .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Autorizar y Continuar'),
        ),
      ],
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
