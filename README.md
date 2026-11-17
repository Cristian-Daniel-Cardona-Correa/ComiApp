# comiAPP – Asistente Inteligente de Cocina con Gemini Live

<p align="center">
  <strong>Convierte cualquier receta en una experiencia culinaria guiada, con control de múltiples tiempos y un chef de IA conversacional por voz y cámara en tiempo real.</strong>
</p>

---

## 1. Contexto del Proyecto

- **Nombre:** comiAPP (también conocido como ComIA).
- **Institución:** Unidad Central del Valle del Cauca (UCEVA) – Proyecto de Ingeniería de Software I.
- **Equipo de Desarrollo:**
  - Johan Eliu Salgado Castro – 230232033
  - Brahian Andrés Tenorio – 230232017
  - Cristian Daniel Cardona Correa – 230232024
- **Problema que resuelve:** Quien tiene poca o mediana experiencia cocinando suele abandonar la receta porque no entiende un término, duda sobre el punto de cocción o pierde el control al manejar varios tiempos a la vez.
- **Público Objetivo:** Personas de 18 a 40 años que viven solas o cocinan en el hogar (estudiantes y profesionales jóvenes).
- **Diferenciador:** Mientras apps como *Kitchen Stories* y *SideChef* ofrecen contenido estático, **comiAPP** incorpora **Gemini Live**, un chef interactivo capaz de responder por voz con manos libres, interrumpirse (barge-in) y ver lo que hay en la sartén vía cámara en tiempo real.

---

## 2. Arquitectura y Tecnologías

El proyecto sigue una arquitectura limpia por capas desacopladas:

```
lib/
├── core/                         # Fundamentos transversales
│   ├── constants/                # Constantes de negocio, audio Gemini Live y Habeas Data
│   ├── theme/                    # Paleta de color culinaria, tipografías y tema global
│   └── utils/                    # Calculadora matemática de reescalado de porciones
├── features/
│   ├── auth/                     # Autenticación, perfiles y consentimiento de privacidad
│   │   ├── models/               # UserProfile, DietaryPreferences
│   │   ├── presentation/         # Splash, Onboarding, Login, Register, Profile, Consent
│   │   ├── providers/            # AuthProvider
│   │   └── repositories/         # AuthRepository (Firebase / Local Storage)
│   ├── recipes/                  # Catálogo de recetas y ficha de detalle
│   │   ├── data/                 # 10 recetas completas de ejemplo con datos reales
│   │   ├── models/               # Recipe, Ingredient, CookingStep
│   │   ├── presentation/         # CatalogScreen ("La Despensa"), RecipeDetailScreen, Widgets
│   │   ├── providers/            # RecipeProvider (filtros, búsqueda y porciones)
│   │   └── repositories/         # RecipeRepository
│   ├── cooking/                  # Modo Cocina guiado y temporizadores múltiples
│   │   ├── models/               # CookingTimer, CookingSession
│   │   ├── presentation/         # CookingModeScreen, ActiveTimersSheet ("Mis Tiempos"), Banner
│   │   ├── providers/            # TimerProvider, CookingSessionProvider
│   │   ├── repositories/         # CookingRepository (persistencia de sesión y deadline)
│   │   └── services/             # NotificationService (alarmas nativas exactas en background)
│   ├── ai_assistant/             # Asistente conversacional Gemini Live
│   │   ├── models/               # AiAssistantStatus, AiMessage, AiToolCall
│   │   ├── presentation/         # AiChefModal, SoundwaveVisualizer, CameraPreview, ChatFallback
│   │   ├── providers/            # AiChefProvider (gestión de voz, cámara y function calling)
│   │   └── services/             # AsistenteIA (interfaz), GeminiLiveClient, MockGeminiLiveClient
│   └── home/                     # Navegación principal
│       └── presentation/screens/ # HomeShellScreen (Tabs: Despensa, Tiempos, Perfil)
└── main.dart                     # Entrada principal, inyección de dependencias con MultiProvider
```

### Tecnologías Clave:
- **Flutter 3.44+ & Dart 3.12+**
- **Gestión de Estado:** `Provider` con `ChangeNotifier` reactivo.
- **Persistencia Local:** `shared_preferences` para sesiones de cocina y persistencia de alarmas con deadline.
- **IA Conversacional en Tiempo Real:** Google Gemini Live API vía WebSocket con audio PCM bidireccional (16 kHz in, 24 kHz out) y transmisión de fotogramas de cámara JPEG a 1 FPS (768×768).
- **Desacoplamiento (Plan B):** La IA está aislada tras la interfaz abstracta `AsistenteIA`, permitiendo cambiar dinámicamente entre el cliente real WebSocket y el simulador interactivo `MockGeminiLiveClient` sin romper el flujo de la aplicación.
- **Habeas Data (Ley 1581 de 2012):** Pantalla de consentimiento explícito previo y política estricta de **no almacenamiento** de datos biométricos, audio ni video en el dispositivo ni en Firestore.

---

## 3. Paleta Visual Culinaria

Diseñada para transmitir calidez, contraste claro y fácil manipulación en cocina (áreas táctiles $\ge 56$ dp, texto de instrucción $\ge 24$ sp):

| Elemento | Color | Hex |
|---|---|---|
| **Fondo principal** | Crema cálido | `#FBF3E3` |
| **Primario** | Verde azulado (Teal) | `#58B098` |
| **Superficie suave** | Menta suave | `#E0F0E8` / `#C0E0D0` |
| **Acción principal** | Naranja tostado | `#F8A840` / `#F89858` |
| **Resaltado y temporizadores** | Amarillo maíz | `#F8E080` |
| **Texto de alto contraste** | Verde casi negro | `#12332E` |
| **Alerta y finalización** | Rojo coral | `#E5533D` |

---

## 4. Flujo de Trabajo GitFlow y Colaboración

El proyecto sigue una estrategia estricta de **GitFlow**:

1. **Ramas Principales:**
   - `main`: Código estable y probado para producción.
   - `dev`: Rama de integración donde convergen las funcionalidades terminadas.
2. **Ramas de Funcionalidad (`feature/*`):**
   - Se ramifican a partir de `dev`.
   - Nomenclatura descriptiva: `feature/nombre-de-la-funcionalidad`.
   - Se realizan commits atómicos uno a uno siguiendo la convención Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `chore:`).
   - Al finalizar, se fusiona hacia `dev` mediante merge commit (`git merge --no-ff feature/...`).
3. **Paso a Producción:**
   - Una vez comprobada la estabilidad en `dev` y superadas las pruebas unitarias y de widgets, `dev` se fusiona hacia `main`.

---

## 5. Instrucciones de Instalación y Ejecución

### Prerrequisitos:
- Flutter SDK instalado y configurado en el PATH (`flutter doctor`).
- Emulador Android/iOS o dispositivo físico conectado por USB o Wi-Fi.

### Pasos:

```bash
# 1. Clonar el repositorio
git clone https://github.com/Cristian-Daniel-Cardona-Correa/ComiApp.git
cd ComiApp

# 2. Configurar variables de entorno
cp .env.example .env

# 3. Obtener dependencias
flutter pub get

# 4. Ejecutar la suite de pruebas unitarias y de widgets
flutter test

# 5. Ejecutar la aplicación en modo desarrollo
flutter run
```

---

## 6. Variables de Entorno (`.env`)

Crea un archivo `.env` en la raíz del proyecto (basado en `.env.example`):

```ini
# API Key de Google Gemini (requerida para conexión directa o Cloud Function)
GEMINI_API_KEY=tu_gemini_api_key

# Modelo Gemini Live recomendado
GEMINI_MODEL=gemini-2.5-flash-native-audio-preview-12-2025

# Configuración de Firebase
FIREBASE_PROJECT_ID=comiapp-uceva
FIREBASE_APP_ID=1:1234567890:android:abcdef
FIREBASE_API_KEY=tu_firebase_api_key

# Endpoint seguro para obtención de Tokens Efímeros (Opción B)
EPHEMERAL_TOKEN_URL=https://us-central1-comiapp-uceva.cloudfunctions.net/getGeminiEphemeralToken
```

---

## 7. Backend: Firebase & Cloud Functions

### 7.1 Reglas de Seguridad de Firestore (`firestore.rules`)
Las reglas protegen las colecciones garantizando que los usuarios solo accedan a sus propios datos y bloqueando cualquier intento de almacenar audio o video.
Para desplegarlas:
```bash
firebase deploy --only firestore:rules
```

### 7.2 Cloud Function de Tokens Efímeros (`functions/index.js`)
Para cumplir con la directiva de seguridad de **nunca almacenar la API Key en la app móvil**, la Cloud Function `getGeminiEphemeralToken` autentica al usuario mediante Firebase Auth y solicita a Google Gemini un token efímero con un solo uso (`uses: 1`) y 60 segundos de validez.
Para desplegarla:
```bash
cd functions
npm install
firebase deploy --only functions
```

### 7.3 Carga inicial de recetas en Firestore
Ejecuta el script incluido para validar y sembrar las 10 recetas completas:
```bash
dart run scripts/seed_firestore.dart
```

---

## 8. Permisos Nativos Configurados

- **Android (`AndroidManifest.xml`):**
  - `RECORD_AUDIO`: Captura de voz para el chef conversacional.
  - `CAMERA`: Captura de video a 1 FPS para evaluar preparaciones.
  - `POST_NOTIFICATIONS`: Alertas locales de temporizadores.
  - `SCHEDULE_EXACT_ALARM` y `USE_EXACT_ALARM`: Alertas de cocción precisas con la app en segundo plano o pantalla bloqueada.
  - `WAKE_LOCK`: Modo cocina con pantalla encendida para cocinar sin tocar el teléfono.
- **iOS (`Info.plist`):**
  - `NSMicrophoneUsageDescription`: Explicación de uso para hablar con manos libres.
  - `NSCameraUsageDescription`: Explicación de uso para verificar el estado de los alimentos.

---

## 9. Lista de Pruebas Manuales en Dispositivo Físico

| # | Prueba | Procedimiento | Resultado Esperado |
|---|---|---|---|
| 1 | **Reescalado de porciones** | En la ficha de "Pasta Carbonara", cambiar de 2 a 4 porciones. | Las cantidades se duplican en tiempo real (ej. 200g $\rightarrow$ 400g de espaguetis). |
| 2 | **Temporizador en segundo plano** | Iniciar el temporizador de 6 minutos de panceta y bloquear la pantalla del teléfono. | A los 6 minutos exactos suena la alarma local nativa con los botones *Descartar* y *Posponer (+1 min)*. |
| 3 | **Temporizadores múltiples** | Iniciar temporizador de pasta y luego iniciar temporizador de salsa. | Ambos corren simultáneamente en la barra inferior flotante y en la hoja "Mis Tiempos". |
| 4 | **Pantalla encendida (Wakelock)** | Entrar al Modo Cocina y dejar el teléfono sobre la mesa 3 minutos sin tocarlo. | La pantalla no se atenúa ni se bloquea mientras el botón de sol esté activo. |
| 5 | **Salida segura** | Pulsar la "X" en Modo Cocina. Elegir "Cambiar de receta". | Regresa a la despensa y los temporizadores continúan corriendo en la barra flotante. |
| 6 | **Asistente Gemini Live (Voz)** | Tocar "Preguntarle al chef" y decir: *"Ponme un temporizador de 8 minutos para la pasta"*. | El asistente responde afirmativamente y se crea automáticamente el temporizador por Function Calling. |
| 7 | **Interrupción (Barge-in)** | Mientras el Chef está hablando, hablar encima o tocar "Interrumpir". | El audio del chef se corta de inmediato y pasa al estado "Escuchando". |
| 8 | **Cámara 1 FPS** | Activar la cámara en la sesión del chef y enfocar la preparación. | Se transmite el fotograma a Gemini Live y el chef comenta sobre el color o dorado. |
