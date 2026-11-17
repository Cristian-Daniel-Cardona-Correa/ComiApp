import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/ai_chef_provider.dart';

class ChatFallbackSheet extends StatefulWidget {
  const ChatFallbackSheet({super.key});

  @override
  State<ChatFallbackSheet> createState() => _ChatFallbackSheetState();
}

class _ChatFallbackSheetState extends State<ChatFallbackSheet> {
  final _textController = TextEditingController();

  final List<String> _quickPrompts = [
    '¿Cómo sé si está listo el paso?',
    'Siguiente paso',
    'Pon un temporizador de 5 minutos',
    '¿Qué ingredientes uso ahora?',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _textController.text;
    if (text.trim().isEmpty) return;
    context.read<AiChefProvider>().sendUserText(text.trim());
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final aiProv = context.watch<AiChefProvider>();
    final messages = aiProv.messages;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.creamBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chat de Respaldo con el Chef',
                  style: AppTypography.titleMedium),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          // Mensajes
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment: msg.isChef
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isChef ? Colors.white : AppColors.accentOrange,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.outlineDark, width: 1.5),
                    ),
                    child: Text(
                      msg.text,
                      style: AppTypography.bodyMedium.copyWith(
                        color: msg.isChef
                            ? AppColors.textDark
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Prompts rápidos
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  label: Text(prompt, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.mintSoft,
                  onPressed: () => _sendMessage(prompt),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Entrada de texto
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu duda al Chef...',
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: AppColors.textDark,
                ),
                onPressed: () => _sendMessage(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
