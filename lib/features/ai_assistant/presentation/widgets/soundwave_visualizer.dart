import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/ai_session_state.dart';

/// Visualizador de espectro de barras estilo CAVA (Console-based Audio Visualizer)
/// reactivo al 100% a la voz REAL:
/// - Se modula exclusivamente con la amplitud RMS de la voz del usuario y de la IA
/// - En silencio absoluto, las barras permanecen en reposo (sin animaciones por defecto)
/// - Caída con efecto de gravedad (peak decay) idéntico a los ecualizadores de consola CAVA
class SoundwaveVisualizer extends StatefulWidget {
  final AiAssistantStatus status;
  final Stream<double>? voiceLevelStream;
  final int barCount;

  const SoundwaveVisualizer({
    super.key,
    required this.status,
    this.voiceLevelStream,
    this.barCount = 20,
  });

  @override
  State<SoundwaveVisualizer> createState() => _SoundwaveVisualizerState();
}

class _SoundwaveVisualizerState extends State<SoundwaveVisualizer> {
  late List<double> _barHeights;
  StreamSubscription<double>? _levelSub;
  double _lastLevel = 0.0;

  static const double _restHeight = 0.06;

  @override
  void initState() {
    super.initState();
    _barHeights = List.filled(widget.barCount, _restHeight);
    _subscribeToStream();
  }

  @override
  void didUpdateWidget(covariant SoundwaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.voiceLevelStream != oldWidget.voiceLevelStream) {
      _subscribeToStream();
    }
  }

  void _subscribeToStream() {
    _levelSub?.cancel();
    _levelSub = widget.voiceLevelStream?.listen((level) {
      _processVoiceLevel(level);
    });
  }

  void _processVoiceLevel(double rawLevel) {
    final level = rawLevel.clamp(0.0, 1.0);
    final wasSilent = _lastLevel <= 0.005;
    final isSilent = level <= 0.005;

    // Si sigue en silencio y las barras ya están en la base, no redibujar
    if (wasSilent && isSilent && _barHeights.every((h) => (h - _restHeight).abs() < 0.001)) {
      return;
    }

    _lastLevel = level;

    setState(() {
      for (int i = 0; i < widget.barCount; i++) {
        if (isSilent) {
          // Decaimiento rápido hacia el nivel de reposo (gravedad de CAVA)
          _barHeights[i] = math.max(_restHeight, _barHeights[i] * 0.75);
        } else {
          // Curva espectral de voz humana (más energía en medios-bajos)
          final x = i / (widget.barCount - 1);
          final bell = math.sin(math.pow(x, 0.75) * math.pi);
          // Variación armónica por barra para simular bandas de frecuencia
          final harmonic = math.sin((i * 1.9) + (level * 6.0)).abs() * 0.3;
          final targetHeight = (_restHeight + (level * (bell * 0.75 + harmonic + 0.15)))
              .clamp(_restHeight, 1.0);

          if (targetHeight > _barHeights[i]) {
            // Ataque rápido al hablar
            _barHeights[i] = targetHeight;
          } else {
            // Caída suave con gravedad
            _barHeights[i] = math.max(_restHeight, _barHeights[i] * 0.7 + targetHeight * 0.3);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _levelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final isChefSpeaking = status == AiAssistantStatus.hablando;
    final hasVoiceActivity = _lastLevel > 0.005;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF142421), // Fondo oscuro estilo consola CAVA
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineDark, width: 2),
        boxShadow: hasVoiceActivity
            ? [
                BoxShadow(
                  color: (isChefSpeaking
                          ? AppColors.accentOrange
                          : AppColors.primaryTeal)
                      .withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (i) {
          final normalizedIndex = i / (widget.barCount - 1);
          final height = _barHeights[i];

          // Determinación del color del espectro
          Color barColor;
          if (!hasVoiceActivity) {
            // Reposo / Silencio: barras tenues inmóviles
            barColor = const Color(0xFF264640);
          } else if (isChefSpeaking) {
            // Chef comiAPP hablando: Degradado cálido fuego (Naranja a Amarillo)
            barColor = Color.lerp(
              AppColors.accentOrange,
              AppColors.highlightYellow,
              normalizedIndex,
            )!;
          } else {
            // Usuario hablando: Degradado Verde Menta a Turquesa
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
                heightFactor: height,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(2.5),
                    ),
                    boxShadow: hasVoiceActivity && height > 0.2
                        ? [
                            BoxShadow(
                              color: barColor.withValues(alpha: 0.5),
                              blurRadius: 2.5,
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
  }
}
