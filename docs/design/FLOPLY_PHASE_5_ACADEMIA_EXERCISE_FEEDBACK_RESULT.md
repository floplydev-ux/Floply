# FLOPly — Fase 5: cierre visual del recorrido de Academia (Exercise → Feedback → Result)

Migración a "Sala Verde" de las fases Exercise/Feedback/Result del recorrido
de Academia, para que dejen de sentirse como un sistema visual distinto del
ya migrado (Home, mapa, teoría, `LessonFlowHeader`, Bankroll).

## 1. Auditoría

La arquitectura real es más compleja que "una pantalla de ejercicio":
`AcademyPhase.exercise` se resuelve a 1 de 4 experiencias distintas según
el tipo de `AcademyItem` actual (`lesson_flow.dart`):

```text
AcademyPhase.exercise
  ├─ item.isPlayable     → PlayableTableExerciseView   (mesa, self-contained)
  ├─ item.isInteractive  → InteractiveTableExerciseView (mesa, LEGACY)
  ├─ item.isEngine       → ExerciseView → ExerciseCard  (sin mesa, compartido con Laboratorio)
  └─ item.check != null  → ExerciseView → _CheckCard    (sin mesa, local)

AcademyPhase.feedback   → FeedbackView → FeedbackPanel (Laboratorio) | EducationalPanel
AcademyPhase.result     → LessonResultView (siempre, sin importar el tipo de ítem)
```

**Hallazgo 1 — `Interactive` es legado activo, `Playable` es el reemplazo.**
`AcademyController._buildItems()` prioriza `Playable` sobre `Interactive`
("tapa su equivalente… el contenido viejo no se borra, solo deja de
usarse en runtime" — comentario del propio código). Conteo real en
`lib/engine/`: `InteractiveTableExercise(`: 88 instancias (15 archivos) vs
`PlayableTableExercise(`: 7 instancias (4 archivos). Confirma que la
Sección 3 del prompt de fase ("no tocar `InteractiveTableExercise`") es
coherente: es el patrón que se abandona. `InteractiveTableExerciseView` e
`InteractiveTableLesson` quedan completamente fuera de alcance.

**Hallazgo 2 — hay una segunda "PokerTableView" oculta.**
`PlayableTableExerciseView` no dibuja la mesa+burbuja directamente: usa
`TableExplanationView`, que TAMBIÉN usa `InteractiveTableExerciseView`
(legado) e `InteractiveTableLesson` (teoría). Y `TableExplanationView`
renderiza `EducationalPanel` para el texto de la burbuja — la misma clase
que también usa `FeedbackView`. **Se trata `TableExplanationView` (y
`EducationalPanel` como clase) como superficie protegida, igual que
`PokerTableView`** — la migración de `PlayableTableExerciseView` solo
toca lo que está fuera de esa vista.

**Hallazgo 3 — `ExerciseCard`/`FeedbackPanel` son de Laboratorio.**
Confirmado por consumidores reales: ambos los usa también
`laboratory_screen.dart`. Se tratan como superficie protegida — se
envuelven desde afuera, no se editan.

**Hallazgo 4 — el camino sin mesa (`.engine`/`.check`) no tiene contenido
real hoy.** Un escaneo de las 64 lecciones del currículo real
(`AcademyController._buildItems()`, seed determinística) dio:
`interactive=53, playable=4, engine=0, check=0, empty=7` en el primer
ítem de cada lección con ejercicios — **ninguna lección real usa
`ExerciseCard` ni `_CheckCard` hoy**. El camino existe, compila, está
migrado, pero no es alcanzable con contenido actual (ver §M sobre cómo
esto afectó la estrategia de testing).

**Hallazgo 5 (fuera de alcance, documentado):** existe una tercera vista
de teoría, `theory_view.dart`/`_TheoryBlockView`, con el mismo anti-patrón
"bloque con ícono+color propio" ya corregido en `WrittenTheoryView` en la
Fase 3 — nunca migrada porque no apareció en esa auditoría. Es teoría, no
ejercicio: fuera de alcance de esta fase, queda como deuda documentada.

## 2. Qué se migró

- `exercise_view.dart` completo.
- `feedback_view.dart` completo.
- `lesson_result_view.dart` completo.
- `playable_table_exercise_view.dart`: solo `_TopBar`, `_ActionButtons`/
  `_ActionButton`, `_SizeButtons`, `_ReasoningButtons`, `_AnsweredBar`,
  `_ResultChip`, `_explanationStyle()` — todo lo que está fuera de
  `TableExplanationView`.
- `SvButtonPrimary` (compartido): se le agregó soporte de `onTap` nulo
  (deshabilitado, opacidad 0.4) — lo necesitaba el botón CONFIRMAR de
  Exercise; `LessonPrimaryButton`, al que reemplaza en 3 de sus 4
  consumidores, ya lo tenía.

## 3. Qué NO se tocó

`PokerTableView`, `TableExplanationView`, `EducationalPanel` (la clase),
`ExerciseCard`, `FeedbackPanel` (Laboratorio), `InteractiveTableExerciseView`,
`InteractiveTableLesson`, `mentor_lesson_stage_view.dart`,
`visual_theory_stage.dart`, `theory_view.dart`, `ratingBadge()` (función
compartida — mismo texto/semántica, ver §D), `LessonItemProgress`/
`LessonPrimaryButton`/`LessonSecondaryButton` originales (siguen
existiendo para sus otros consumidores fuera de alcance), Laboratorio,
Home, Tools, `AppShell`, currículo, engine, navegación.

## 4. Dependencias y blast radius

| Componente | Consumidores en esta fase | Otros consumidores | Decisión |
|---|---|---|---|
| `LessonItemProgress` | — (reemplazado) | `mentor_lesson_stage_view.dart`, `visual_theory_stage.dart` | No modificar; `SvItemProgress` nuevo en su lugar |
| `LessonPrimaryButton` | — (reemplazado) | `theory_view.dart` | No modificar; `SvButtonPrimary` (ya existente) en su lugar |
| `LessonSecondaryButton` | — (reemplazado) | ninguno más | `SvButtonSecondary` (ya existente) en su lugar |
| `ExerciseCard` (Laboratorio) | `exercise_view.dart` (sin uso real hoy) | `laboratory_screen.dart` | Protegido, se envuelve |
| `FeedbackPanel` (Laboratorio) | `feedback_view.dart` (sin uso real hoy) | `laboratory_screen.dart` | Protegido, se envuelve |
| `EducationalPanel` (clase) | — (reemplazado por `_CheckFeedbackPanel` local) | `table_explanation_view.dart` (Playable/Interactive/teoría) | Protegido |
| `TableExplanationView` | vía `PlayableTableExerciseView` (solo el `accent` que se le pasa) | `InteractiveTableExerciseView`, `InteractiveTableLesson` | Protegido |
| `ratingBadge()` | `playable_table_exercise_view.dart` (texto) | `interactive_table_exercise_view.dart`, `mentor_lesson_stage_view.dart` | Función sin cambios; el COLOR se recalcula localmente en `_ResultChip`/`_explanationStyle` (ver `_svColor()`), no en la función compartida |

## 5. Exercise

`exercise_view.dart`: `SvItemProgress` (nuevo, compartido) + `ExerciseCard`
sin envoltura extra (evita doble-card) + `_CheckCard`/`_OptionTile`
reescritos con `SvSurfacePanel`/tokens (acento `feltGreen`/`feltGreenBright`
en vez de violeta) + `SvButtonPrimary` para CONFIRMAR (con su nuevo soporte
de estado deshabilitado).

## 6. Feedback

`feedback_view.dart`: `SvItemProgress` + `FeedbackPanel` sin envoltura +
`_CheckFeedbackPanel` (nuevo, local) reemplaza el uso de `EducationalPanel`
para el camino de texto autoral — verde/rojo real (`success`/`errorBright`)
porque acá `correct` es un dato binario genuino (no la escala de 4 valores
de `ExerciseRating`, que si se colapsara a 2 colores rompería la
pedagogía existente) + `SvButtonPrimary` para SIGUIENTE/VER RESULTADO.

## 7. Result

`lesson_result_view.dart`: `SvSurfacePanel` (borde `feltGreenBright`/
`warning` según passed), tipografía Sala Verde, `SvButtonPrimary`/
`SvButtonSecondary`. Mismo scoring/outcome/conceptos flojos/callbacks
exactos.

## 8. Integración con `PokerTableView` / `PlayableTableExerciseView`

La mesa (`PokerTableView`, vía `TableExplanationView`) permanece
exactamente igual — confirmado visualmente (Chromium real) y por diff de
git (§Q). `PlayableTableExerciseView` pasa su propio `accent` (`feltGreen`
en estado "decidiendo", `feltGreenBright`/`warning`/`errorBright` según
rating) a `TableExplanationView`/`EducationalPanel` como parámetro — esto
SÍ tiñe la burbuja con la temperatura de Sala Verde sin tocar una sola
línea del archivo protegido, porque el color siempre fue un parámetro de
esa clase, nunca un valor hardcodeado ahí.

## 9. Tipografía

Sin cambios de familia — mismo Fraunces/Public Sans/IBM Plex Mono.

## 10. Responsive

Barrido 300–430–480dp + 375×568 (Exercise no tiene contenido real que
recorrer, ver Hallazgo 4 — validado vía `PlayableTableExerciseView`,
lección 5.3, incluida su fila de acciones FOLD/ABRIR con la reserva de
`kFabAvoidanceWidth`) y `LessonResultView` en 300/320/480dp.

## 11. Accesibilidad

Sin cambios de semántica (`ratingBadge()` y sus textos, sin tocar).
Contraste real calculado (no aproximado) para cada color nuevo:

| Uso | Contraste vs `surface`/`background` |
|---|---|
| `success` (texto/ícono, `_CheckFeedbackPanel`) | 6.02:1 |
| `errorBright` (texto/ícono) | 5.19:1 |
| `warning` (texto/ícono) | 5.54:1 |
| `textPrimary` sobre relleno `feltGreen` (botón ABRIR/BET) | 5.26:1 (se descartó `background` sobre `feltGreen`: 3.13:1, insuficiente para este tamaño de fuente) |

## 12. Goldens

Ninguno afectado — `test/golden/screens_golden_test.dart` no cubre
Exercise/Feedback/Result/`PlayableTableExerciseView` (solo Home, Tools,
Bankroll, mapa de Academia, Laboratorio). Confirmado antes de tocar
código y vuelto a confirmar al cerrar la fase.

## 13. Visual QA (navegador real)

Chromium real vía scratch temporal (`lib/main_fase5_preview_scratch.dart`,
con `AppTheme.dark` real, borrado al terminar). Lección 5.3 (RFI, real,
único ejercicio jugable) recorrida completa en 390dp y 320dp: guion
interactivo de teoría (violeta, sin tocar) → pregunta de comprensión
embebida (violeta, sin tocar) → ficha escrita (Sala Verde, Fase 3) →
`PlayableTableExerciseView` (mesa sin tocar, acciones/tamaño/razonamiento/
devolución en Sala Verde, burbuja teñida vía parámetro) → `LessonResultView`
(Sala Verde). Sin overflow, sin artefactos, sin recorte por el FAB de
"Ayuda rápida" en 320dp.

## 14. Continuidad del recorrido

Confirmada de punta a punta para el camino que SÍ tiene contenido real
(interactive/playable): el header (Fase 4) se mantiene consistente en las
4 fases, y ahora Exercise "sin mesa"/Feedback/Result también lo son
cuando les toca aparecer. La única costura real que persiste es la que
ya estaba fuera de alcance por diseño: el guion interactivo de teoría y
`InteractiveTableExerciseView` siguen en el lenguaje visual viejo — ver
§T.

## 15. Problemas encontrados

- `SvButtonPrimary` no soportaba `onTap` nulo (estado deshabilitado) —
  `LessonPrimaryButton`, al que reemplaza, sí. Necesario para CONFIRMAR
  en Exercise.
- El primer intento de color de relleno para BET/RAISE/ALL-IN usó
  `feltGreenBright` (la variante de TEXTO, no de relleno) — contraste
  real de `background`-como-texto contra ese relleno midió 3.13:1
  (insuficiente). Corregido a `feltGreen` (relleno) + `textPrimary`
  (5.26:1) antes de dar la migración por cerrada.
- `_Progress`/`_TopBar` con etiqueta redundante: no ocurrió en esta fase
  (ya se había corregido el caso análogo "BANKROLL"/"BANKROLL" en la
  Fase 4), pero se revisó explícitamente para no repetirlo.
- Falso positivo del harness de QA: el scratch sin `AppTheme.dark`
  mostraba fondo claro en pantallas que dependen del tema ambiente —
  ver nota de la Fase 4, mismo patrón, corregido en el scratch antes de
  sacar conclusiones.
- El primer intento de test de navegación real usó la lección 4.5, que
  no tiene ítems (`content.checks` vacío) — el controller salta directo
  a `AcademyPhase.result` sin pasar por `exercise`. Descubierto por el
  propio test fallando, no asumido — llevó al Hallazgo 4 (§1).

## 16. Bugs corregidos

Ver §15, primeros dos puntos (soporte de disabled en `SvButtonPrimary`,
color de relleno de las acciones agresivas).

## 17. Blast radius — confirmado, no solo planeado

`ratingBadge()` sigue devolviendo exactamente los mismos textos/colores
`AppColors` para sus otros 2 consumidores (`interactive_table_exercise_view.dart`,
`mentor_lesson_stage_view.dart`) — no se tocó la función, solo se
recalculó el color en un helper local (`_svColor()`) dentro de
`playable_table_exercise_view.dart`. `EducationalPanel`/`TableExplanationView`
sin diff (confirmado por git, §Q).

## 18. Deuda restante (no introducida por esta fase, pero ahora documentada)

- `theory_view.dart` (Hallazgo 5): mismo anti-patrón "ícono+color por
  bloque" ya resuelto en `WrittenTheoryView`, nunca migrado.
- El camino `ExerciseCard`/`_CheckCard`/`FeedbackPanel`/`EducationalPanel`
  vía `.engine`/`.check` está migrado pero sin contenido real que lo
  ejercite (Hallazgo 4) — si algún día se autora contenido que lo use,
  vale la pena una pasada de QA visual real en ese momento.
- `InteractiveTableExerciseView`/`InteractiveTableLesson` (la mayoría del
  currículo real de ejercicios interactivos) siguen en el lenguaje visual
  viejo — es la costura más grande que queda en todo el recorrido de
  Academia.

## 19. Regresión

`flutter analyze`: 0 issues.

`flutter test`: base antes de Fase 5: 1207. Nuevos tests: 20
(`test/ui/academy_playable_exercise_visual_test.dart`: 16 — barrido de 9
anchos + altura reducida + acción real + recorrido completo a Result,
todo sobre la lección 5.3 real; `test/widgets/sala_verde_widgets_test.dart`:
4 — `SvButtonPrimary` habilitado/deshabilitado, `SvItemProgress` en 0/N y
N/N). Total esperado: 1227. **Total ejecutado: 1227 — 1225 passed, 2
failed.**

Las 2 fallas son **preexistentes y ajenas a esta fase**, ambas en
`test/ui/academy_exercise_flow_test.dart` (archivo COMMITTEADO, ya
existía antes de esta sesión — no confundir con
`academy_playable_exercise_visual_test.dart`, nuevo de esta fase; ver
§21 sobre por qué casi terminan mezclados). Causa real, verificada:
ese test recorre las 64 lecciones asumiendo que un ítem es
`.interactive`, `.engine` o `.check` — nunca contempla `.isPlayable`
porque se escribió antes de que existiera `AcademyPlayableScripts`
(`lib/engine/pedagogy/academy_playable_scripts.dart`, no trackeado en
git — trabajo en curso previo a esta sesión, ver Hallazgo 1 de §1). Al
llegar a la lección 5.3 (la primera con un ítem `.playable`), cae al
`else` que asume `.check` y hace `item.check!.correctIndex` sobre un
`check` nulo. **No se tocó ni se corrigió este test** (lógica de
currículo/engine, fuera del alcance visual de esta fase) — se deja
documentado para que el usuario decida si corresponde arreglarlo ahora
o en otra instancia.

## 20. Incidente de sesión: colisión de nombre de archivo de test

Al crear los tests de esta fase usé el nombre
`test/ui/academy_exercise_flow_test.dart` para un archivo NUEVO, sin
verificar antes si ya existía uno con ese nombre — sí existía: un test
COMMITTEADO (`git log`: "feat: close v0.2.0…") que recorre las 64
lecciones reales del currículo y valida el flujo de recuperación de una
evaluación desaprobada. Lo sobreescribí sin darme cuenta.

Se detectó durante la auditoría de git de cierre (§19/§20 — el `git diff
--stat` de ese archivo mostraba inserciones Y eliminaciones en vez del
patrón `??` de archivo nuevo, lo que no encajaba), antes de reportar la
fase como terminada. Se restauró el archivo original exacto con `git
checkout -- test/ui/academy_exercise_flow_test.dart` y el contenido
nuevo de esta fase se movió a `test/ui/academy_playable_exercise_visual_test.dart`
(nombre sin colisión). Se confirmó que ambos archivos coexisten y que
el conteo final de regresión (§19) ya refleja el archivo original
restaurado, no la versión que lo había reemplazado.

Ningún contenido se perdió — se recuperó completo desde `git show
HEAD:...` antes de restaurar — pero el error en sí (no revisar si el
nombre ya existía antes de escribir) es real y evitable.

## 21. Recomendación para Fase 6

Sin decidir nada: el candidato más claro, dado el Hallazgo 1 y la deuda
de §18, es `InteractiveTableExerciseView`/`InteractiveTableLesson` — es
la superficie de ejercicios más grande que queda sin migrar y la que más
impacto real tendría (88 instancias reales vs las 7 de `Playable`).
Laboratorio sigue siendo el otro candidato de siempre. Decisión del
usuario, no se avanza automáticamente.
