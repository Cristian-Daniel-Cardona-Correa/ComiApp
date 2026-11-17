import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/timer_provider.dart';

/// Diálogo para crear un temporizador personalizado sin estar en modo cocina.
/// El usuario escribe un nombre y elige la duración.
class AddManualTimerDialog extends StatefulWidget {
  const AddManualTimerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const AddManualTimerDialog(),
    );
  }

  @override
  State<AddManualTimerDialog> createState() => _AddManualTimerDialogState();
}

class _AddManualTimerDialogState extends State<AddManualTimerDialog> {
  final _labelController = TextEditingController();
  final _minutesController = TextEditingController(text: '5');
  String? _labelError;
  String? _minutesError;

  @override
  void dispose() {
    _labelController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _labelController.text.trim();
    final minutesText = _minutesController.text.trim();
    final minutes = int.tryParse(minutesText);

    setState(() {
      _labelError = label.isEmpty ? 'Escribe un nombre para el temporizador' : null;
      _minutesError = (minutes == null || minutes < 1 || minutes > 240)
          ? 'Ingresa un número entre 1 y 240 minutos'
          : null;
    });

    if (_labelError != null || _minutesError != null) return;

    final timerProv = context.read<TimerProvider>();
    timerProv.startManualTimer(
      label: label,
      minutes: minutes!,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.creamBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.outlineDark, width: 2),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.mintSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_alarm_rounded,
                color: AppColors.primaryTeal, size: 26),
          ),
          const SizedBox(width: 12),
          Text('Nuevo Temporizador', style: AppTypography.titleLarge),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _labelController,
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '¿Qué estás cocinando?',
              hintText: 'ej: Arroz, Salsa tomate…',
              prefixIcon: const Icon(Icons.restaurant_rounded),
              errorText: _labelError,
              errorStyle: const TextStyle(
                  color: AppColors.errorCoral, fontWeight: FontWeight.w600),
            ),
            onChanged: (_) {
              if (_labelError != null) setState(() => _labelError = null);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _minutesController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Duración (minutos)',
              hintText: 'ej: 10',
              prefixIcon: const Icon(Icons.timer_rounded),
              suffixText: 'min',
              errorText: _minutesError,
              errorStyle: const TextStyle(
                  color: AppColors.errorCoral, fontWeight: FontWeight.w600),
            ),
            onChanged: (_) {
              if (_minutesError != null) setState(() => _minutesError = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          // Botones rápidos de duración
          Wrap(
            spacing: 8,
            children: [1, 3, 5, 10, 15, 20, 30, 45, 60].map((min) {
              return ActionChip(
                label: Text('$min min'),
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.outlineDark),
                onPressed: () {
                  _minutesController.text = '$min';
                  if (_minutesError != null) setState(() => _minutesError = null);
                },
              );
            }).toList(),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentOrange,
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Iniciar'),
        ),
      ],
    );
  }
}
