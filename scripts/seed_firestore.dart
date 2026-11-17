import 'dart:convert';
import 'dart:io';

/// Script de inicialización y carga de las 10 recetas de ejemplo en Firestore
/// Ejecución:
///   dart run scripts/seed_firestore.dart
void main() async {
  final jsonFile = File('assets/data/initial_recipes.json');
  if (!jsonFile.existsSync()) {
    stdout.writeln('Error: Archivo assets/data/initial_recipes.json no encontrado.');
    exit(1);
  }

  final content = await jsonFile.readAsString();
  final List<dynamic> recipes = json.decode(content);

  stdout.writeln('=== comiAPP: Cargador de Recetas a Firestore ===');
  stdout.writeln('Recetas listas para sembrar: ${recipes.length}\n');

  for (final recipe in recipes) {
    final title = recipe['title'];
    final id = recipe['id'];
    final steps = (recipe['steps'] as List).length;
    final ingredients = (recipe['ingredients'] as List).length;
    stdout.writeln('✓ [$id] "$title" ($steps pasos, $ingredients ingredientes)');
  }

  stdout.writeln('\nInstrucciones para aplicar en Firebase CLI:');
  stdout.writeln('1. Asegúrate de haber iniciado sesión: firebase login');
  stdout.writeln('2. Selecciona el proyecto: firebase use <tu-proyecto>');
  stdout.writeln('3. Las recetas se cargan automáticamente desde la app móvil en su primer inicio,');
  stdout.writeln('   o puedes subirlas a la colección "recipes" usando el SDK de Firebase Admin.');
}
