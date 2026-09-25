# FLOPly — Fase 1 / Bloque 2: Academia — Mapa y Navegación — AUDIT

**Fecha:** 2026-09-19. **Alcance:** `LevelMap` (`lib/screens/academy/widgets/level_map.dart`) y su entrada desde `AcademyScreen` — mapa de niveles, subniveles, progreso, estados bloqueado/desbloqueado/completado, navegación, jerarquía, orientación. **No incluye** teoría ni ejercicios (Bloques 3/4) ni la lógica de `AcademyController`/`AcademyEngine`/unlock (fuera de alcance por regla explícita). **No se modificó código en este paso.**

**Método:** lectura completa de `level_map.dart`, `academy_screen.dart`, y el enum `LevelState`/`LessonState` real (`academy_progress.dart`) — no se infirió ningún estado, se verificó contra la fuente. Cruzado contra los hallazgos ya confirmados de Bloque 1 (mismo tipo de problema reapareciendo en una superficie distinta cuenta como evidencia más fuerte, no como hallazgo aislado).

## 1. Estado actual

`LevelMap` es la vista de fase `map` de `AcademyScreen` (la otra fase es `LessonFlow`, fuera de este bloque). Estructura: header → `_ProgressStrip` (nivel actual + barra + lecciones + conceptos dominados) → una `_LevelCard` por nivel, cada una con sus `_LessonRow`. El sistema de estados (`LevelState`/`LessonState`) está bien diseñado en el engine — el problema encontrado es que la UI no lo refleja completo (ver §5).

## 2. Arquitectura relevante

```
AcademyScreen (fase map)
  └─ LevelMap
       ├─ _AcademyHeader (ícono + título, sin interacción)
       ├─ _ProgressStrip (nivel actual, barra, lecciones, conceptos)
       └─ _LevelCard × N
            ├─ _LevelBadge (número o candado — decorativo, no tappable por sí solo)
            └─ _LessonRow × N (tappable si no está locked)
```

## 3. Componentes utilizados

Ninguno de `lib/widgets/` (`GlassCard`, `HomeLinkCard`, etc.) — `_ProgressStrip` y `_LevelCard` reimplementan `Container`+`BoxDecoration` desde cero, igual que encontramos en Home antes de P1-A. `PressableScale` sí se reusa (en `_LessonRow`).

## 4. Design tokens utilizados

- Colores: 100% `AppColors`, igual que en Home — consistente.
- Radios: 16 (`_ProgressStrip`), 18 (`_LevelCard`), 12 (`_LessonRow`) — tres valores más, ninguno coincide con los 20/22/26 que ya vimos en Home.
- El breakpoint `constraints.maxWidth >= 480 ? 24.0 : 18.0` (línea 24) es el MISMO patrón sin efecto práctico que ya señalamos como P2 #10 en Bloque 1 — confirma que es sistémico, no un caso aislado de Home.

## 5. Problemas UX

**[P1] `LevelState.available` y `LevelState.inProgress` se ven idénticos.** El engine distingue 4 estados de nivel (`locked`/`available`/`inProgress`/`completed` — verificado en `academy_progress.dart:14`), pero `_LevelCard` (línea 185) solo branchea sobre `locked` (sí/no) y por separado sobre `completed` (para el ícono de verificado) — `available` e `inProgress` reciben exactamente el mismo tratamiento visual. Un usuario no puede distinguir de un vistazo "un nivel que ya empecé" de "un nivel que todavía no toqué" — información que el engine ya calcula y la UI descarta.

**[P2] Tap "fantasma" en lecciones bloqueadas.** `_LessonRow` envuelve TODAS las filas en `PressableScale` (línea 309), incluidas las bloqueadas (`onTap: onTap ?? () {}` — un no-op, pero la animación de "presionado" corre igual). Un usuario que toca una lección bloqueada ve el feedback táctil de que "algo pasó" sin que pase nada, y sin ninguna explicación de qué falta para desbloquearla.

## 6. Problemas UI

**[P1] Misma duplicación de cards que Bloque 1, ahora en Academia.** `_ProgressStrip` (padding 16/radius 16/gradient/border) y `_LevelCard` (padding 16/radius 18/color/border condicional) reimplementan exactamente lo que `GlassCard` ya resuelve — `GlassCard` ya soporta `gradient`, `borderColor` y `borderRadius` como parámetros, así que ambos podrían construirse sobre `GlassCard` sin perder ningún caso de uso actual. Esto no es un hallazgo aislado: es el mismo patrón de Bloque 1 (P1-A) apareciendo en una segunda superficie, lo que sugiere que vale la pena resolverlo como principio del design system, no parche por parche.

**[P2] La barra de progreso de `_ProgressStrip` usa un gradiente distinto al de Home.** Línea 137-141: `[AppColors.violetBright, AppColors.violetPrimary]` a mano, en vez de `AppColors.violetGradient` ( `[violetPrimary, violetDeep]`, ya el token oficial de "barra de progreso violeta" desde que se usa así en `ContinueLearningCard` y en `_LevelBadge` de esta misma pantalla, línea 266). El mismo elemento conceptual (barra de progreso de Academia) se ve con dos gradientes distintos según en qué pantalla esté.

## 7. Problemas accessibility

**[P1, predicho — no verificado todavía con el test real, a diferencia de los hallazgos ya confirmados de Bloque 1]** `_ProgressStrip` usa `AppColors.textMuted` (línea 156, "lecciones completadas") sobre `violetStripGradient` (fondo oscuro) — el mismo patrón de color que ya falló contraste WCAG AA tres veces en Bloque 1 (Home). Alta probabilidad de que también falle acá; queda marcado como predicción a confirmar con `meetsGuideline(textContrastGuideline)` antes de decidir el fix, no asumido a ciegas.

**[P1]** Ningún estado (locked/completed/available/inProgress) se expone vía `Semantics` explícito — un screen reader solo tiene el ícono (candado/check/tipo de lección) para inferir el estado, sin un label como "Bloqueado" o "Completado". Mismo tipo de hallazgo que P1-D en Home (ausencia total de semantics en un control con estado), ahora en varios lugares a la vez (badge de nivel, fila de lección).

**[P2]** `Opacity(0.5)` sobre toda la fila de una lección bloqueada (línea 311) reduce el contraste de TODO lo que hay adentro (texto, ícono, borde) a la mitad — si el texto ya está en el límite del contraste mínimo sin la opacidad, con `Opacity(0.5)` seguro lo pierde. Contenido bloqueado no necesita el mismo contraste que contenido accionable, pero sí debe seguir siendo legible.

## 8. Problemas responsive

Ninguno nuevo — mismo patrón de `LayoutBuilder`+`SingleChildScrollView` que ya está probado en `academy_level1/2/3_test.dart` (recorren el nivel completo a 320-430dp sin overflow).

## 9. Problemas de consistencia

Cubiertos arriba: 2 recetas de card más sin usar `GlassCard` (§6), gradiente de progreso inconsistente entre Home y Academia (§6), radios sin escala (§4).

## 10. Problemas de navegación

Ninguno — la navegación mapa↔lección es clara (`AcademyScreen` branchea por `phase`, `openLesson` lleva a `LessonFlow`), y las lecciones bloqueadas correctamente no navegan (`onTap: null`).

## 11. Hallazgos P0/P1/P2

| # | Severidad | Hallazgo |
|---|---|---|
| 1 | **P1** | `available` e `inProgress` (2 de los 4 `LevelState`) se ven idénticos — el usuario no distingue "nivel nuevo" de "nivel en curso" |
| 2 | **P1** | `_ProgressStrip`/`_LevelCard` reimplementan lo que `GlassCard` ya resuelve — mismo patrón de Bloque 1, segunda aparición |
| 3 | **P1** | Ningún estado de nivel/lección se expone vía `Semantics` — solo color/ícono |
| 4 | **P1 (predicho, sin confirmar)** | `textMuted` sobre fondo oscuro en `_ProgressStrip` — mismo patrón que ya falló 3 veces en Bloque 1 |
| 5 | **P2** | Tap fantasma en lecciones bloqueadas (feedback táctil sin acción ni explicación) |
| 6 | **P2** | Gradiente de la barra de progreso inconsistente entre Home y Academia |
| 7 | **P2** | `Opacity(0.5)` en filas bloqueadas reduce contraste de todo el contenido |

**0 P0.** Cada hallazgo cita archivo y línea real.

## 12. Cambios propuestos (dirección, no implementación)

- **#1:** dar a `inProgress` un tratamiento visual propio (ej. borde con el color de acento en vez de `surfaceBorder`, o un badge chico "en curso") sin tocar cuándo el engine asigna ese estado — es puramente de presentación.
- **#2:** migrar `_ProgressStrip` y `_LevelCard` a construirse sobre `GlassCard` (mismo espíritu que P1-A de Bloque 1).
- **#3:** agregar `Semantics(label: ...)` explícito en `_LevelBadge` y `_LessonRow` describiendo el estado en palabras.
- **#4:** confirmar con el accessibility test real antes de decidir el fix (probablemente `textMuted` → `textSecondary`, igual que en Bloque 1, pero se verifica, no se asume).
- **#5:** en lecciones bloqueadas, quitar el `PressableScale`/reemplazar por un feedback distinto (ej. un tooltip o snackbar breve explicando qué falta) en vez de una animación de "presionado" sin efecto.
- **#6:** unificar en `AppColors.violetGradient`.
- **#7:** evaluar si reducir la opacidad es necesario dado que ya hay un ícono de candado + texto en `textMuted`/`iconColor` distintos — quizás alcanza con el color sin la opacidad extra.

## 13. Tests que deberán proteger el cambio

`test/ui/academy_level1_test.dart`/`level2`/`level3` ya cubren que el mapa no rompe/desborda al recorrer un nivel completo — deberían seguir en verde sin tocarlos. Un cambio a `GlassCard` necesita el mismo chequeo que P1-A (goldens de `academy_screen_level_map`). El fix de `Semantics` necesita un test de accesibilidad nuevo específico de `LevelMap` (hoy el único accessibility test cubre `AppShell`/`ToolsScreen`, no Academia).

## 14. Riesgos

Bajo en general. El más delicado es #1 (estados de nivel): hay que confirmar con datos reales qué combinaciones de nivel producen `inProgress` de verdad (probablemente cualquier nivel con al menos una lección completada pero no todas) antes de diseñar el tratamiento visual, para no adivinar un caso que no ocurre en la práctica.

---

**No se implementó nada de lo anterior.** Quedo a la espera de tu prioridad antes de pasar a DESIGN → IMPLEMENT.
