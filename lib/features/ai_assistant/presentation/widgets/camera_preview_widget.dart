import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class CameraPreviewWidget extends StatelessWidget {
  final VoidCallback onCloseCamera;

  const CameraPreviewWidget({super.key, required this.onCloseCamera});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.textDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineDark, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Vista previa simulada de la cámara trasera
          Container(
            color: const Color(0xFF1B3B34),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_rounded,
                      size: 40, color: AppColors.mintSoft),
                  const SizedBox(height: 6),
                  Text(
                    'Cámara activa (1 FPS para Gemini Live)',
                    style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                  ),
                  Text(
                    'Apunta a tu sartén u olla para que el chef lo vea',
                    style: AppTypography.badge.copyWith(color: AppColors.highlightYellow),
                  ),
                ],
              ),
            ),
          ),
          // Visor y botón de cerrar
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black54,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 18, color: Colors.white),
                onPressed: onCloseCamera,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.errorCoral,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'LIVE • 768x768',
                style: AppTypography.badge.copyWith(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
