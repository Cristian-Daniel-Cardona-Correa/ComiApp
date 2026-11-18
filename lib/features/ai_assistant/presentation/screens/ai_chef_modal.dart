import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/ai_chef_provider.dart';
import '../../models/ai_session_state.dart';
import '../widgets/soundwave_visualizer.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/chat_fallback_sheet.dart';

class AiChefModal extends StatelessWidget {
  const AiChefModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiChefModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiProv = context.watch<AiChefProvider>();
    final status = aiProv.status;
    final isSpeaking = status == AiAssistantStatus.hablando;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(22),
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

            // Cabecera del Chef
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.mintSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.psychology_alt_rounded,
                          color: AppColors.primaryTeal, size: 26),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('El Chef comiAPP',
                                style: AppTypography.titleLarge),
                          ],
                        ),
                        Text(
                          'Gemini Live • Voz y Cámara',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primaryDarkTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Indicador de estado (escuchando / pensando / hablando)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: status == AiAssistantStatus.error
                        ? AppColors.errorCoral
                        : (status == AiAssistantStatus.hablando
                            ? AppColors.accentOrange
                            : (status == AiAssistantStatus.pensando
                                ? AppColors.highlightYellow
                                : AppColors.mintSoft)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outlineDark, width: 1.5),
                  ),
                  child: Text(
                    status.label,
                    style: AppTypography.badge.copyWith(
                      color: status == AiAssistantStatus.error
                          ? Colors.white
                          : AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Aviso de límites de sesión si aplica
            if (aiProv.sessionLimitWarning != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.highlightYellow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineDark, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        aiProv.sessionLimitWarning!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Vista previa de cámara si está activa
            if (aiProv.isCameraActive)
              CameraPreviewWidget(
                onCloseCamera: () => aiProv.toggleCamera(),
                onFrameCaptured: (bytes) => aiProv.sendCameraFrame(bytes),
              ),

            // Visualizador de ondas sonoras estilo CAVA reactivo a la voz
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineDark, width: 2),
              ),
              child: SoundwaveVisualizer(
                status: status,
                voiceLevelStream: aiProv.voiceLevelStream,
              ),
            ),
            const SizedBox(height: 14),

            // Burbuja de transcripción en tiempo real
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mintSoft.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.outlineDark, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        aiProv.messages.isNotEmpty && aiProv.messages.last.isUser
                            ? Icons.mic_rounded
                            : Icons.record_voice_over_outlined,
                        size: 16,
                        color: AppColors.primaryDarkTeal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        aiProv.messages.isNotEmpty && aiProv.messages.last.isUser
                            ? 'Tú dijiste:'
                            : 'La Chef comiAPP:',
                        style: AppTypography.badge
                            .copyWith(color: AppColors.primaryDarkTeal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    aiProv.messages.isNotEmpty
                        ? aiProv.messages.last.text
                        : 'La chef te escucha. Habla con naturalidad o muéstrale tus ingredientes...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontStyle: aiProv.messages.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Chip de confirmación de acción ejecutada por voz
            if (aiProv.lastToolActionResult != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.highlightYellow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineDark, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 16, color: AppColors.primaryTeal),
                    const SizedBox(width: 6),
                    Text(
                      'Acción: ${aiProv.lastToolActionResult!}',
                      style: AppTypography.badge,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Botón de Interrumpir (Barge-in manual) si la chef está hablando
            if (isSpeaking)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: OutlinedButton.icon(
                  onPressed: () => aiProv.interruptChef(),
                  icon: const Icon(Icons.pan_tool_rounded,
                      color: AppColors.errorCoral),
                  label: const Text('Interrumpir a la Chef'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorCoral,
                    side: const BorderSide(
                        color: AppColors.errorCoral, width: 2),
                    minimumSize: const Size(double.infinity, 46),
                  ),
                ),
              ),

            // Botón principal Push-to-Talk / Tap-to-Talk (estilo asistente de voz IA)
            Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: GestureDetector(
                onTap: () => aiProv.toggleMic(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: aiProv.isRecordingSpeech
                        ? AppColors.errorCoral
                        : AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.outlineDark, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: (aiProv.isRecordingSpeech
                                ? AppColors.errorCoral
                                : AppColors.primaryTeal)
                            .withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        aiProv.isRecordingSpeech
                            ? Icons.stop_circle_rounded
                            : Icons.mic_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        aiProv.isRecordingSpeech
                            ? 'Escuchando... Toca para enviar'
                            : 'Toca para hablar',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Barra de controles secundarios: Cámara, Chat Fallback, Terminar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Toggle Cámara
                IconButton.filled(
                  icon: Icon(aiProv.isCameraActive
                      ? Icons.videocam_rounded
                      : Icons.videocam_off_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: aiProv.isCameraActive
                        ? AppColors.accentOrange
                        : Colors.white,
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(
                        color: AppColors.outlineDark, width: 2),
                    padding: const EdgeInsets.all(14),
                  ),
                  tooltip: aiProv.isCameraActive
                      ? 'Desactivar cámara'
                      : 'Mostrar cámara',
                  onPressed: () => aiProv.toggleCamera(),
                ),

                // Fallback a chat de texto
                IconButton.filled(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(
                        color: AppColors.outlineDark, width: 2),
                    padding: const EdgeInsets.all(14),
                  ),
                  tooltip: 'Chat de texto (fallback)',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const ChatFallbackSheet(),
                    );
                  },
                ),

                // Terminar sesión
                ElevatedButton.icon(
                  onPressed: () async {
                    await aiProv.endSession();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Terminar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorCoral,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
