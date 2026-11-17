import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/ai_session_state.dart';

class SoundwaveVisualizer extends StatefulWidget {
  final AiAssistantStatus status;

  const SoundwaveVisualizer({super.key, required this.status});

  @override
  State<SoundwaveVisualizer> createState() => _SoundwaveVisualizerState();
}

class _SoundwaveVisualizerState extends State<SoundwaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color barColor = AppColors.primaryTeal;
    if (widget.status == AiAssistantStatus.hablando) {
      barColor = AppColors.accentOrange;
    } else if (widget.status == AiAssistantStatus.pensando) {
      barColor = AppColors.highlightYellow;
    } else if (widget.status == AiAssistantStatus.interrumpido) {
      barColor = AppColors.errorCoral;
    }

    final isAnimated = widget.status == AiAssistantStatus.hablando ||
        widget.status == AiAssistantStatus.escuchando;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            double height = 16.0;
            if (isAnimated) {
              final wave = (_controller.value + (index * 0.2)) % 1.0;
              height = 12.0 + (wave * 36.0);
            }
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: height,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.outlineDark, width: 1.5),
              ),
            );
          }),
        );
      },
    );
  }
}
