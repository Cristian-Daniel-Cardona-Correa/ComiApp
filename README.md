# comiAPP – Asistente de cocina

Aplicación móvil desarrollada en Flutter que guía al usuario paso a paso en la
preparación de recetas, con temporizadores múltiples y perfil de usuario.
Proyecto académico de Ingeniería de Software I – UCEVA.

## Integrantes
- Johan Eliu Salgado Castro – 230232033
- Brahian Andrés Tenorio – 230232017
- Cristian Daniel Cardona Correa – 230232024

## Alcance actual
Guía de recetas paso a paso, temporizadores de cocción y perfil de usuario.
El componente de asistente por IA en tiempo real se retiró del desarrollo
para reducir complejidad y costos (ver Taller 2), y queda como visión futura.

## Metodología
El equipo trabaja con **Kanban** (con una revisión semanal de seguimiento),
adecuado para un equipo pequeño con dedicación parcial y un alcance que
puede reordenarse sin romper sprints fijos.

## Reglas de Colaboración

Seguimos un flujo tipo **GitHub Flow**:

1. La rama `main` siempre debe quedar en estado desplegable/estable.
2. Todo cambio se desarrolla en una rama nueva a partir de `main`,
   con nombre descriptivo: `feature/nombre-funcionalidad`,
   `fix/nombre-del-bug` o `docs/nombre-cambio`.
3. Al terminar, se abre un **Pull Request** hacia `main`.
4. Todo PR requiere **al menos 1 revisión aprobada** antes de fusionarse.
5. No se permiten cambios directos (push) sobre `main`; toda modificación
   pasa por PR.
6. Se usan commits pequeños y descriptivos (ej. `feat: agregar temporizador`,
   `fix: corregir cálculo de tiempo de cocción`).
7. Antes de fusionar, se aplica el checklist de revisión de código del
   equipo (ver documento del Taller 3).

## Tecnología
- Flutter / Dart
- Gestión de estado: Provider / Riverpod
- Persistencia local: Hive / SQLite
- Backend y notificaciones: Firebase (plan gratuito)

## Estado del proyecto
En planificación / desarrollo inicial (Taller 3 – Ingeniería de Software I).
