import '../../recipes/models/recipe.dart';
import '../../recipes/models/cooking_step.dart';
import '../../cooking/models/cooking_timer.dart';
import '../../auth/models/user_profile.dart';

class AiCookingContext {
  final Recipe recipe;
  final CookingStep currentStep;
  final int portions;
  final List<CookingTimer> activeTimers;
  final DietaryPreferences preferences;

  const AiCookingContext({
    required this.recipe,
    required this.currentStep,
    required this.portions,
    required this.activeTimers,
    required this.preferences,
  });
}

class AiContextBuilder {
  AiContextBuilder._();

  /// Construye las instrucciones de sistema (System Instruction) para Gemini Live
  static String buildSystemInstruction(AiCookingContext context) {
    final recipe = context.recipe;
    final step = context.currentStep;
    final timers = context.activeTimers;
    final prefs = context.preferences;

    final timerSummaries = timers.isEmpty
        ? 'Ninguno activo'
        : timers
            .map((t) => '${t.label}: ${t.formattedTime} (${t.status.name})')
            .join(', ');

    final allergiesSummary = prefs.allergies.isEmpty
        ? 'Ninguna declarada'
        : prefs.allergies.join(', ');

    return '''
Eres "La Chef", la asistente de cocina de voz en tiempo real de la aplicación comiAPP.
Reglas estrictas de comportamiento:
1. Identidad y género femenino: Tienes voz de mujer. Cuando te refieras a ti misma, habla SIEMPRE en género femenino (por ejemplo: "estoy lista", "encantada de ayudarte", "como tu chef personal", "estoy atenta", "preparada", "concentrada"). Sé paciente, cálida, amigable y profesional. Responde SIEMPRE en español.
2. Frases ultra-cortas y directas: El usuario está cocinando activamente. Responde en máximo 1 o 2 oraciones breves y directas al grano, sin saludos repetitivos ni introducciones innecesarias, para que el audio de voz comience de inmediato con mínima latencia.
3. Seguridad alimentaria: Sé rigurosa con temperaturas, tiempos de cocción de carnes y pollo. No inventes datos.
4. Si el usuario te muestra la cámara o pregunta por el estado visual de la comida, analiza con precisión el punto de cocción, dorado o textura.
5. Puedes ejecutar acciones en la app invocando herramientas (tools): siguiente_paso, paso_anterior, iniciar_temporizador, cancelar_temporizador, leer_ingredientes_del_paso.

Contexto actual de la cocina:
- Receta en preparación: "${recipe.title}" (${recipe.prepTimeMinutes} min, ${context.portions} porciones).
- Paso actual (Paso ${step.stepNumber} de ${recipe.steps.length}): "${step.title}".
- Instrucción del paso: "${step.instruction}".
- Tip del chef para este paso: "${step.chefTip ?? 'Sin notas adicionales'}".
- Temporizadores activos en este momento: [$timerSummaries].
- Restricciones del usuario: Vegetariano: ${prefs.isVegetarian}, Vegano: ${prefs.isVegan}, Sin Gluten: ${prefs.isGlutenFree}, Alergias: $allergiesSummary.
- Nivel de experiencia del cocinero: ${prefs.experience.name}.
''';
  }

  /// Declaración oficial de herramientas (Function Calling) para Gemini Live API
  static List<Map<String, dynamic>> getToolDeclarations() {
    return [
      {
        'name': 'siguiente_paso',
        'description':
            'Avanza al siguiente paso de la receta cuando el usuario indica que terminó el paso actual o dice "siguiente".',
        'parameters': {
          'type': 'OBJECT',
          'properties': {},
        },
      },
      {
        'name': 'paso_anterior',
        'description':
            'Retrocede al paso anterior de la receta si el usuario necesita repasar o dice "anterior" o "vuelve atrás".',
        'parameters': {
          'type': 'OBJECT',
          'properties': {},
        },
      },
      {
        'name': 'iniciar_temporizador',
        'description':
            'Inicia un nuevo temporizador culinario en la app (ej: "ponme un temporizador de 8 minutos para la pasta").',
        'parameters': {
          'type': 'OBJECT',
          'properties': {
            'nombre': {
              'type': 'STRING',
              'description': 'Nombre o etiqueta del temporizador (ej: "Pasta", "Salsa", "Pollo")',
            },
            'minutos': {
              'type': 'INTEGER',
              'description': 'Duración del temporizador en minutos enteros (mínimo 1)',
            },
          },
          'required': ['nombre', 'minutos'],
        },
      },
      {
        'name': 'cancelar_temporizador',
        'description':
            'Cancela o detiene un temporizador activo por su nombre.',
        'parameters': {
          'type': 'OBJECT',
          'properties': {
            'nombre': {
              'type': 'STRING',
              'description': 'Nombre o etiqueta del temporizador que se desea cancelar',
            },
          },
          'required': ['nombre'],
        },
      },
      {
        'name': 'leer_ingredientes_del_paso',
        'description':
            'Lee en voz alta o lista los ingredientes necesarios y sus cantidades exactas para el paso actual.',
        'parameters': {
          'type': 'OBJECT',
          'properties': {},
        },
      },
    ];
  }
}
