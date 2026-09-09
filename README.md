# Floply

Floply es una aplicación móvil educativa para **aprender póker de forma
visual, progresiva e interactiva**.

En lugar de limitarse a teoría escrita, las lecciones muestran los
conceptos directamente **sobre una mesa de póker**: las acciones aparecen
de a una, cada situación lleva una **burbuja explicativa** asociada, y el
alumno avanza **paso a paso**. Después de la teoría vienen **ejercicios
interactivos** en los que el alumno **toma una decisión** sobre la mesa y
recibe feedback. La dificultad aumenta de forma progresiva a lo largo de
los niveles.

> El nombre del proyecto es **Floply**. La identidad visual / branding
> (logo, colores de marca, tipografías, splash) queda deliberadamente
> pendiente y se trabajará más adelante.

---

## Objetivo del proyecto

Construir una experiencia de aprendizaje de póker que combine:

- teoría **visual** en vez de solo texto;
- **situaciones reales de mesa** como escenario de enseñanza;
- **ejercicios interactivos** con decisiones del alumno;
- **progresión por niveles** con desbloqueos;
- **feedback inmediato** después de cada respuesta;
- aprendizaje **práctico** en lugar de memorización aislada.

---

## Estado actual

**Versión actual: `v0.1.1`** · Estado: **prototipo en desarrollo activo**.

Ya implementado:

- **Nivel 1** completo, construido sobre la mesa interactiva.
- **Nivel 2** completo (jerarquía de manos y showdowns reales sobre la mesa).
- **Lecciones interactivas sobre la mesa de póker** (situación → acción →
  explicación → paso siguiente → conclusión).
- **Ejercicios interactivos** con decisión del alumno y feedback.
- **Sistema de identidad de jugadores**: el usuario aparece en la mesa con
  su nombre; los rivales son personajes con nombre y avatar propios.
- **Layout responsive vertical** (mobile-first), verificado a 320 / 360 /
  390 / 412 / 430 dp.
- **Suite de tests automatizados** (motor + widgets).
- **Limpieza de arquitectura / refactor** (release técnica `v0.1.1`).

Los niveles 3 a 5 ya existen dentro del plan de estudios y son jugables
con ejercicios generados por el motor, pero **todavía no están migrados a
la experiencia completa sobre la mesa**.

Próximo bloque funcional: **`v0.2.0` — Nivel 3**. El Nivel 3 **no** está
implementado como experiencia interactiva sobre la mesa.

---

## Filosofía de aprendizaje

El enfoque pedagógico actual usa la mesa de póker como escenario de
enseñanza.

**En una lección**, el recorrido típico es:

1. se presenta una situación sobre la mesa;
2. ocurre una acción (una apuesta, un fold, el reparto de cartas…);
3. aparece una explicación contextual en una burbuja;
4. el alumno avanza al siguiente paso;
5. la situación continúa;
6. finalmente se llega a una conclusión o a una decisión.

**En un ejercicio**, el alumno observa la situación, **toma una decisión**
entre las opciones disponibles y luego recibe el feedback correspondiente.
Las respuestas no siempre son binarias: una decisión puede ser la mejor,
aceptable o pobre según el contexto.

---

## Arquitectura

Floply usa una arquitectura **orientada a contenido / pedagogía
reutilizable**, con el contenido separado de la presentación:

- **Motor** (`lib/engine/`): lógica pura de póker, estrategia, conceptos,
  generación y evaluación de ejercicios, y progresión de la Academia. No
  depende de Flutter y se puede testear en aislamiento.
- **Contenido pedagógico**: la teoría y los guiones viven como datos, no
  dentro de los widgets.
  - **Scripts de lecciones** y **scripts de ejercicios**, organizados por
    nivel.
  - **Modelos de mesa** (`TableSnapshot`, `TableStep`,
    `TableLessonScript`, `InteractiveTableExercise`).
- **Componentes reutilizables de mesa** (`PokerTableView`,
  `EducationalBubble`): los usan tanto la teoría como los ejercicios.
- **Controladores** (`ChangeNotifier`): coordinan el estado del recorrido
  sin conocer los widgets.
- **Widgets de presentación**: pintan el estado que expone el controlador.

El objetivo de esta separación es poder **agregar nuevos niveles y
lecciones sin duplicar toda la capa visual**: un nivel nuevo se agrega
como contenido y queda enganchado al recorrido existente.

---

## Estructura del proyecto

Vista simplificada (los nombres son los reales del repositorio):

```
lib/
├── main.dart                      # entry point → PokerTrainerApp
├── app.dart                       # MaterialApp + tema oscuro → AppShell
├── engine/                        # lógica pura, sin Flutter
│   ├── poker/                     # cartas, mazo, posiciones, acciones, calles
│   ├── strategy/                  # rangos de apertura, fuerza de mano
│   ├── concepts/                  # conceptos pedagógicos + mastery del usuario
│   ├── exercises/                 # generador y validador de ejercicios
│   ├── evaluation/                # evaluación de respuestas + feedback
│   ├── academy/                   # progresión: desbloqueos, progreso, store
│   ├── poker_trainer_engine.dart  # fachada del motor
│   └── pedagogy/
│       ├── scripts/
│       │   ├── table_builder.dart          # arma las mesas 6-max de los guiones
│       │   ├── level_1_lessons.dart …      # _2 _3 _4 _5 (teoría)
│       │   └── level_1_exercises.dart …    # _2 _5 (ejercicios interactivos)
│       ├── table_lesson.dart               # TableSnapshot, TableStep, TableLessonScript
│       ├── table_exercise.dart             # InteractiveTableExercise, ExerciseChoice
│       ├── curriculum.dart                 # plan de 5 niveles × 5 sub-niveles
│       ├── lesson_content.dart             # modelo de teoría (texto fuera de la UI)
│       ├── academy_content.dart            # el texto de teoría de cada sub-nivel
│       ├── academy_players.dart            # elenco de personajes (rivales NPC)
│       ├── academy_table_scripts.dart      # agregador de guiones de teoría
│       └── academy_exercise_scripts.dart   # agregador de sets de ejercicios
├── models/
│   └── app_user.dart              # identidad del usuario (fuente única del nombre)
├── persistence/                   # AcademyStore local (archivo en nativo, memoria en web)
├── theme/                         # paleta + ThemeData Material 3 oscuro
├── l10n/                          # copy centralizado (app_strings.dart)
├── widgets/                       # componentes compartidos (tarjetas, bottom nav…)
└── screens/
    ├── root/app_shell.dart        # shell de 5 pestañas (IndexedStack)
    ├── home/                      # Home / dashboard
    ├── laboratory/                # práctica libre con el motor de ejercicios
    ├── placeholder/               # pantallas "Próximamente" (Estadísticas, Perfil)
    └── academy/
        ├── academy_controller.dart    # estado del recorrido (ChangeNotifier)
        ├── academy_screen.dart        # shell de la Academia
        └── widgets/
            ├── level_map.dart                        # mapa de niveles
            ├── lesson_flow.dart                      # router del recorrido de una lección
            ├── theory_view.dart / exercise_view.dart # vistas por fase
            ├── feedback_view.dart / lesson_result_view.dart
            ├── poker_table_view.dart                 # render de la mesa
            ├── educational_bubble.dart               # burbuja explicativa
            └── interactive_table_lesson.dart / interactive_table_exercise.dart

test/                              # 23 archivos · 119 tests (motor + widgets)
```

---

## Tecnologías

- **Flutter** (canal stable) — SDK de Dart `>=3.3.0 <4.0.0`.
- **Dart**.
- **Flutter Web** — es el target usado para el desarrollo actual; el
  repositorio **no** incluye todavía las carpetas de Android / iOS / otras
  plataformas.
- **Git** / **GitHub** para el control de versiones.

Dependencias de runtime: `cupertino_icons`, `path_provider`. Dev:
`flutter_lints`. El estado se maneja con `ChangeNotifier` (sin paquete de
state management externo).

---

## Instalación y ejecución

```bash
git clone https://github.com/full710/Floply.git
cd Floply
flutter pub get
flutter run -d chrome
```

Comprobaciones:

```bash
flutter test        # 119/119
flutter analyze     # ver nota abajo
flutter build web   # build de producción web
```

> **Nota sobre `flutter analyze`:** actualmente reporta 43 avisos de nivel
> `info` (`withOpacity` deprecado y sugerencias de `const`), **todos** en
> los widgets de la Home. Son preexistentes y no afectan el
> funcionamiento; se resolverán junto con el trabajo de branding / Home.

---

## Versionado

- `v0.1.0` — baseline estable inicial.
- `v0.1.1` — refactor y limpieza arquitectónica, **sin cambios
  funcionales**.
- `v0.2.0` — siguiente bloque funcional importante: **Nivel 3**.
- Las versiones `0.x` representan etapas de desarrollo.
- `v1.0.0` queda reservada para la primera versión completa / release.

---

## Roadmap

- [x] Nivel 1
- [x] Nivel 2
- [x] Lecciones interactivas sobre la mesa
- [x] Ejercicios interactivos con decisión y feedback
- [x] Sistema de identidad de jugadores
- [x] Layout responsive vertical (mobile)
- [x] Suite de tests automatizados
- [x] Limpieza de arquitectura / refactor (v0.1.1)
- [ ] Nivel 3 (v0.2.0)
- [ ] Migración de los niveles 4–5 a la experiencia completa sobre la mesa
- [ ] Más contenido de aprendizaje
- [ ] Build de Android / iOS
- [ ] Persistencia del progreso en una build distribuible
- [ ] Identidad visual / branding
- [ ] Versión lista para producción

---

## Documentación del repositorio

- **`README.md`** — presentación y guía general del proyecto.
- **`CHANGELOG.md`** — cambios por versión.
- **`DEVELOPMENT_LOG.md`** — historial técnico y decisiones de desarrollo.

---

Licencia: pendiente de definir.
