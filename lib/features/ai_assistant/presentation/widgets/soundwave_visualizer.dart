import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/ai_session_state.dart';

/// Visualizador de espectro de barras estilo CAVA (Console-based Audio Visualizer)
/// Muestra un analizador de frecuencias dinámico (graves, medios, agudos)
/// con caída de picos y rebote elástico cuando el asistente está hablando o escuchando.
class SoundwaveVisualizer extends StatefulWidget {
  final AiAssistantStatus status;
  final int barCount;

  const SoundwaveVisualizer({
    super.key,
    required this.status,
    this.barCount = 18,
  });

  @override
  State<SoundwaveVisualizer> createState() => _SoundwaveVisualizerState();
}

class _SoundwaveVisualizerState extends State<SoundwaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final isActive = status == AiAssistantStatus.hablando ||
        status == AiAssistantStatus.escuchando;
    final isSpeaking = status == AiAssistantStatus.hablando;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final t = _animController.value * 2 * math.pi;

        return Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF142421), // Fondo oscuro estilo terminal CAVA
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineDark, width: 2),
            boxShadow: [
              BoxShadow(
                color: (isSpeaking ? AppColors.accentOrange : AppColors.primaryTeal)
                    .withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.barCount, (i) {
              // Simulación de espectro frecuencial CAVA
              // i va de 0 a barCount-1: graves (izq), medios (centro), agudos (der)
              final normalizedIndex = i / (widget.barCount - 1);
              final bellCurve = math.sin(normalizedIndex * math.pi); // curva de campana

              double heightFactor = 0.12; // reposo

              if (isActive) {
                // Múltiples armónicos superpuestos como un ecualizador CAVA
                final freq1 = math.sin(t * 3.2 + i * 0.7);
                final freq2 = math.cos(t * 1.8 - i * 0.4);
                final freq3 = math.sin(t * 5.0 + i * 1.2);
                final combined = (freq1 * 0.45 + freq2 * 0.35 + freq3 * 0.2).abs();

                // Mayor energía si está hablando el Chef
                final multiplier = isSpeaking ? 1.0 : 0.45;
                heightFactor = (0.15 + (combined * bellCurve * 0.85 * multiplier))
                    .clamp(0.08, 1.0);
              } else if (status == AiAssistantStatus.pensando) {
                // Onda viajera suave cuando está procesando
                final wave = (math.sin(t * 2.0 - i * 0.5) + 1) / 2;
                heightFactor = (0.15 + wave * 0.35).clamp(0.1, 0.7);
              }

              // Color gradual según la frecuencia (estilo degradado CAVA)
              Color barColor;
              if (isSpeaking) {
                // De naranja a amarillo fuego
                barColor = Color.lerp(
                  AppColors.accentOrange,
                  AppColors.highlightYellow,
                  normalizedIndex,
                )!;
              } else if (status == AiAssistantStatus.pensando) {
                barColor = AppColors.highlightYellow;
              } else if (status == AiAssistantStatus.interrumpido) {
                barColor = AppColors.errorCoral;
              } else {
                // Escuchando / reposo: de Verde Menta a Teal profundo
                barColor = Color.lerp(
                  AppColors.primaryTeal,
                  AppColors.mintSoft,
                  normalizedIndex,
                )!;
              }

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: heightFactor,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                        boxShadow: isSpeaking
                            ? [
                                BoxShadow(
                                  color: barColor.withValues(alpha: 0.6),
                                  blurRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
