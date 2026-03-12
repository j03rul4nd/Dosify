# Dosify

Dosify es una app educativa para estudiantes de enfermeria y profesionales sanitarios que necesitan estudiar farmacos por sistemas y practicar con quizzes de forma estructurada.

## Estado actual

La app ya no es una plantilla de SwiftUI. El repositorio contiene una base funcional con:

- Biblioteca de farmacos por sistema y categoria.
- Dashboard de inicio con foco, recomendacion y repaso diario.
- Quiz jugable con sesiones configurables.
- Pantalla de progreso con temas fuertes, temas a reforzar y repaso para hoy.
- Persistencia local con `SwiftData`.
- Tests de dominio para seed data, validacion, progreso y view models clave.

## Arquitectura

```text
Dosify/
├── Dosify/
│   ├── Features/
│   │   ├── Drugs/
│   │   ├── Quiz/
│   │   ├── Root/
│   │   └── Shared/
│   ├── Models/
│   │   ├── Entities/
│   │   ├── Enums/
│   │   └── Persistence/
│   ├── Resources/
│   │   └── SeedData/
│   ├── Services/
│   ├── ContentView.swift
│   └── DosifyApp.swift
└── DosifyTests/
```

### Criterio de arquitectura

- `Models/Entities`: dominio puro, requests de sesion, snapshots y resumenes de aprendizaje.
- `Models/Persistence`: estado persistente del usuario en `SwiftData`.
- `Services`: carga de catalogo, indices de consulta, logging, grabacion de progreso y servicios de analitica/sesiones.
- `Features`: cada area de producto tiene su propio flujo.
- `Features/Shared`: componentes visuales reutilizables para no duplicar UI.
- Las features principales ya extraen `ViewModel` para separar narrativa de producto, estado derivado, filtros y presentacion.

## Flujo de producto

### 1. Inicio

- Dashboard con metricas globales.
- Recomendacion del siguiente tema.
- Logros ligeros para reforzar retencion sin saturar.
- Tarjeta de `Repasar hoy` basada en progreso e historial real.
- La recomendacion de repaso ya puede preconfigurar estrategia y longitud de sesion al entrar en quiz.

### 2. Farmacos

- Navegacion por sistemas.
- Busqueda por nombre, resumen y mecanismo.
- Filtro de biblioteca completa o favoritos.
- Accion directa para lanzar quiz relacionado desde un farmaco.
- Pantalla detalle de farmaco para conectar teoria, memoria clave y practica relacionada.

### 3. Quiz

- Configuracion por sistema, modo y dificultad.
- Entrada al quiz mediante `QuizSessionRequest`, no solo por tema.
- Colecciones inteligentes de temas:
  - todos
  - sin empezar
  - reforzar
  - dominados
  - errores recientes
- Sesiones rapidas con presets de longitud:
  - 5
  - 10
  - 20
  - todo
- Sesion estandar, repaso de errores recientes o simulacion de examen.
- Recomendaciones de `Repasar hoy` que pueden abrir una sesion ya preconfigurada y autoarrancada.
- Guardado de progreso y de historial por pregunta.
- Reanudacion de sesion cuando el usuario sale del quiz antes de terminar.
- Persistencia del borrador de sesion entre lanzamientos para recuperar una sesion pausada.
- Modo examen sin feedback inmediato y con revision final de errores.
- Pantalla final con siguiente paso recomendado para continuar sin friccion.

### 4. Progreso

- Resumen global de sesiones, precision y temas dominados.
- Vista de `Repasar hoy` para decidir el siguiente bloque de estudio.
- Recomendaciones que distinguen entre repaso de errores recientes y refuerzo breve por tema.
- Listado de temas mas fuertes y temas que necesitan refuerzo.
- Acceso directo desde progreso a la practica del tema correspondiente.

## Persistencia local

La persistencia esta pensada para escalar sin mezclar responsabilidades:

- `UserProgress`
  Progreso agregado por `topicID`.

- `QuestionHistory`
  Historial por pregunta para detectar errores recientes y personalizar el repaso.

- `FavoriteDrug`
  Favoritos del usuario para construir una biblioteca personalizada.

## Queries y filtros implementados

La capa de store ya expone consultas reutilizables para crecer sin meter reglas de negocio en las vistas:

- temas disponibles
- temas sin empezar
- temas que necesitan refuerzo
- temas dominados
- temas con errores recientes
- recomendacion del siguiente tema
- plan de repaso diario
- temas mas fuertes
- temas mas debiles
- preguntas falladas recientemente
- favoritos de biblioteca
- tema recomendado a partir de un farmaco
- requests de sesion con estrategia y modo de presentacion
- simulacion de examen reutilizando el mismo motor de sesion

Internamente, el `store` actua como fachada y delega las reglas de aprendizaje en servicios especializados:

- `StudyAnalyticsService`
  Recomendacion, colecciones inteligentes, resumenes, foco de estudio y repaso diario.

- `QuizSessionFactory`
  Construccion de sesiones a partir de `QuizSessionRequest`, catalogo e historial.

- `HomeDashboardViewModel`
  Estado derivado de la home para separar onboarding, retencion y acciones prioritarias del layout SwiftUI.

- `QuizHubViewModel`
  Seleccion, queries derivadas, metricas y construccion de requests de sesion para el hub de quiz.

- `DrugLibraryViewModel`
  Filtros, busqueda, agrupacion por categoria y resolucion de favoritos para la biblioteca.

- `ProgressOverviewViewModel`
  Resumen de rendimiento, repaso diario y ranking de temas fuertes o fragiles.

## Robustez y control de errores

Se han aplicado varias medidas para que el codigo sea mas mantenible y trazable:

- Validacion y saneado del catalogo de preguntas.
- Fallback controlado si faltan o fallan los JSON de seed data.
- Logging con `OSLog` para catalogo, quiz y persistencia.
- Errores tipados para creacion de sesiones, progreso y favoritos.
- Tests de dominio para piezas criticas y para los servicios de analitica.
- La simulacion de examen reutiliza el mismo motor de sesiones y evita duplicar logica.
- La navegacion de quiz ya acepta `QuizSessionRequest`, lo que permite abrir sesiones configuradas o autoarrancadas desde distintas entradas del producto.

## Tests

Actualmente hay cobertura de dominio para:

- `SeedDataLoader`
- validacion y saneado de `Question`
- `ProgressRecorder`
- `DosifyStore`
- `StudyAnalyticsService`
- `ProgressOverviewViewModel`
- `HomeDashboardViewModel`
- `QuizHubViewModel`
- `DrugLibraryViewModel`
- `QuizSessionViewModel`

## Validacion

Para una validacion reproducible fuera de Xcode, el repo incluye:

```bash
./scripts/validate.sh
./scripts/test.sh
```

Los scripts usan `xcodebuild`, guardan log en `/tmp`, reutilizan `DerivedData` en `/tmp` y desactivan firma para evitar ruido de configuracion local.

Nota:
- Si el error final menciona `CoreSimulator`, `actool` o ausencia de runtimes de simulador, el bloqueo es del entorno y no necesariamente del codigo Swift.
- Si el error menciona `swift-plugin-server`, `PersistentModelMacro` o `AttributePropertyMacro`, el problema viene del entorno local de Xcode/SwiftData antes de que la validacion termine de forma fiable.
- `scripts/test.sh` necesita un simulador concreto. Por defecto usa `platform=iOS Simulator,name=iPhone 16`, pero se puede sobreescribir con `TEST_DESTINATION=...`.

## Siguiente iteracion razonable

- Introducir repeticion espaciada real sobre `QuestionHistory`.
- Llevar el CTA de `continuar sesion` tambien a la home para recuperar contexto mas rapido.
- Persistir metadata resumida de la ultima sesion para reforzar continuidad y retencion.
- Añadir favoritos de temas o listas de estudio.
- Preparar monetizacion con anuncios y premium sin afectar el dominio actual.
