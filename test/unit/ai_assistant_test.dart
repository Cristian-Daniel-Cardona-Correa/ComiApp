import 'package:flutter_test/flutter_test.dart';
import 'package:comiapp/features/ai_assistant/models/ai_session_state.dart';
import 'package:comiapp/features/ai_assistant/services/ai_context_builder.dart';
import 'package:comiapp/features/ai_assistant/services/mock_gemini_live_client.dart';
import 'package:comiapp/features/recipes/data/initial_recipes.dart';
import 'package:comiapp/features/auth/models/user_profile.dart';

void main() {
  final recipe = InitialRecipes.recipes.first;
  final step = recipe.steps.first;

  final context = AiCookingContext(
    recipe: recipe,
    currentStep: step,
    portions: 3,
    activeTimers: const [],
    preferences: const DietaryPreferences(
      allergies: ['Maní'],
    ),
  );

  group('AiContextBuilder tests', () {
    test('buildSystemInstruction includes recipe, step and allergy context', () {
      final instructions = AiContextBuilder.buildSystemInstruction(context);

      expect(instructions.contains(recipe.title), isTrue);
      expect(instructions.contains(step.title), isTrue);
      expect(instructions.contains('3 porciones'), isTrue);
      expect(instructions.contains('Maní'), isTrue);
    });

    test('getToolDeclarations contains all 5 required function tools', () {
      final tools = AiContextBuilder.getToolDeclarations();
      final toolNames = tools.map((t) => t['name']).toList();

      expect(toolNames, contains('siguiente_paso'));
      expect(toolNames, contains('paso_anterior'));
      expect(toolNames, contains('iniciar_temporizador'));
      expect(toolNames, contains('cancelar_temporizador'));
      expect(toolNames, contains('leer_ingredientes_del_paso'));
    });
  });

  group('MockGeminiLiveClient interaction tests', () {
    test('Connects and transitions to active state', () async {
      final client = MockGeminiLiveClient();
      await client.connect(context);

      expect(client.currentStatus,
          anyOf(AiAssistantStatus.escuchando, AiAssistantStatus.hablando));
      client.dispose();
    });

    test('sendTextMessage with "siguiente" emits siguiente_paso tool call', () async {
      final client = MockGeminiLiveClient();
      await client.connect(context);

      expectLater(
        client.toolCallStream,
        emits(predicate<AiToolCall>((call) => call.name == 'siguiente_paso')),
      );

      await client.sendTextMessage('siguiente paso');
      client.dispose();
    });

    test('sendTextMessage with "temporizador" emits iniciar_temporizador tool call', () async {
      final client = MockGeminiLiveClient();
      await client.connect(context);

      expectLater(
        client.toolCallStream,
        emits(predicate<AiToolCall>((call) => call.name == 'iniciar_temporizador')),
      );

      await client.sendTextMessage('pon un temporizador de 8 minutos para la pasta');
      client.dispose();
    });

    test('interrupt triggers barge-in and returns to listening', () async {
      final client = MockGeminiLiveClient();
      await client.connect(context);
      await client.interrupt();

      expect(client.currentStatus, equals(AiAssistantStatus.escuchando));
      client.dispose();
    });
  });
}
