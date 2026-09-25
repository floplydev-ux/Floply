# FLOPly — Fase 4: `LessonFlowHeader` + migración visual de Bankroll

Migración a "Sala Verde" del encabezado compartido de recorrido
(`LessonFlowHeader`, usado por Academia y Bankroll) y del cuerpo de
Bankroll, para cerrar la costura visual documentada en
`FLOPLY_PHASE_3_ACADEMIA.md` §15/§P.

## 1. Auditoría inicial

`grep -rn "LessonFlowHeader(" lib/` da exactamente 2 sitios de construcción
reales (fuera de la definición de la clase):

| Consumidor | Archivo:línea | Uso | Props pasadas |
| --- | --- | --- | --- |
| Academia | `lesson_flow.dart:34` | Encabezado de TODAS las fases de un lesson (teoría/ejercicio/feedback/resultado), no solo teoría | `title`, `subtitle`, `onBack` |
| Bankroll | `bankroll_screen.dart:42` | Encabezado de toda la pantalla | `title`, `subtitle`, `onBack` |

`lesson_widgets.dart` tiene 12 importadores en total, pero los otros 10
solo usan `LessonNavControls`/`LessonItemProgress`/`ratingBadge` — no
construyen `LessonFlowHeader`. No hay consumidores ocultos.

**Propiedades comunes:** `title`, `subtitle`, `onBack` — idénticas en
ambos consumidores, ningún comportamiento a preservar diverge entre ellos
(back siempre hace `pop`/`exitLesson`, subtitle siempre se muestra en
mayúsculas).

**Propiedad específica encontrada:** el *acento* del subtítulo. La versión
vieja usaba `AppColors.violetSoft` fijo para los dos consumidores (de ahí
la costura: ni Academia ni Bankroll tienen violeta como temperatura en
Sala Verde). Se resolvió con un `variant` (`academy`/`bankroll`), no con
dos componentes.

**Hallazgo adicional (no en el header, pero relevante para no dejar una
costura peor):** el cuerpo de `bankroll_screen.dart` (`_TopicCard`)
todavía tenía el patrón "7 secciones con ícono/color propio + IDEA CLAVE en
gradiente dorado-violeta" — el mismo anti-patrón que
`written_theory_view.dart` tenía antes de la Fase 3. Migrar solo el header
y dejar ese cuerpo habría creado un contraste más evidente (header Sala
Verde nuevo sobre cuerpo dorado-violeta viejo), así que el cuerpo de
Bankroll entra en el alcance de esta fase — reutilizando componentes que
ya existen, sin agregar superficie nueva.

## 2. Arquitectura elegida

Un solo `LessonFlowHeader` (mismo nombre, mismo archivo
`lesson_widgets.dart` — no se crearon `AcademiaLessonFlowHeader`/
`BankrollLessonFlowHeader`), con un enum `LessonFlowHeaderVariant` que
resuelve internamente el acento correcto — mismo patrón guardrail que
`SvSectionHeaderVariant` (Fase 3): la API no expone un `Color` libre.

```dart
enum LessonFlowHeaderVariant {
  academy(SalaVerdeColors.feltGreenBright),
  bankroll(SalaVerdeColors.brassBright);
  ...
}
```

`variant` tiene default `academy`, así que `lesson_flow.dart` (el
consumidor de Academia) no necesitó ningún cambio en su call site.
`bankroll_screen.dart` agrega `variant: LessonFlowHeaderVariant.bankroll`
explícito.

### Por qué `brassBright` y no `brassDeep` para Bankroll

`brassDeep` está documentado (`FLOPLY_DESIGN_DECISIONS.md` #7) como la
variante de brass para texto/ícono sobre **superficie clara**
(`surfaceReading`, 5.39:1) — `brass` puro falla ahí (2.17:1). El header
vive sobre `background` **oscuro**, el mismo contexto que ya usa
`feltGreenBright`/`steelBlueBright`/`graphiteSteelBright` para texto. Usar
`brassDeep` ahí habría sido aplicar la variante equivocada por analogía
superficial ("Bankroll = dorado, dorado = brassDeep") en vez de por la
regla real (superficie clara vs. oscura). `brassBright` ya estaba
verificado como seguro sobre fondo oscuro (más claro que `brass`, que mide
7.63:1 contra `background`).

## 3. API final de `LessonFlowHeader`

```dart
LessonFlowHeader({
  required String title,
  required String subtitle,
  required VoidCallback onBack,
  LessonFlowHeaderVariant variant = LessonFlowHeaderVariant.academy,
})
```

Internamente: `SalaVerdeColors.surfaceElevated` + borde `borderSubtle` para
el botón volver (antes sin borde), ícono `textSecondary` (antes color por
defecto del tema), título en `SalaVerdeType.bodyStrong()`, subtítulo en
`SalaVerdeType.label(color: variant.accent)`. Título y subtítulo ahora
tienen `overflow: TextOverflow.ellipsis` explícito (la versión vieja no lo
tenía — ver §12, bug encontrado en el barrido responsive).

## 4. Componentes nuevos / promovidos

- `LessonFlowHeaderVariant` (enum, en `lesson_widgets.dart`) — nuevo.
- `SvLessonNavControls` (en `sala_verde_widgets.dart`) — **promovido**
  desde `_TheoryNavControls`, privado de `written_theory_view.dart` desde
  la Fase 3. En ese momento tenía un solo consumidor real y no se
  justificaba compartirlo (`FLOPLY_PHASE_3_ACADEMIA.md` §P, deuda
  documentada). Con Bankroll como segundo consumidor real del mismo
  patrón (ATRÁS/CONTINUAR de un recorrido de lectura paso a paso), se
  promovió — misma API, mismo comportamiento, cero componentes nuevos de
  superficie.

Ningún componente de superficie nuevo: Bankroll reutiliza
`SvReadingCard`/`SvCalloutAccent`/`SvProgressLinear`/`SvButtonSecondary`
tal cual existían desde la Fase 2/3.

## 5. Componentes explícitamente NO tocados

`LessonNavControls`, `LessonItemProgress`, `LessonPrimaryButton`,
`LessonSecondaryButton`, `ratingBadge` (`lesson_widgets.dart`) — siguen
compartidos por `exercise_view.dart`, `feedback_view.dart`,
`lesson_result_view.dart`, `interactive_table_lesson.dart`,
`mentor_lesson_stage_view.dart`, `visual_theory_stage.dart`, fuera de
alcance de esta fase. `PokerTableView`, `PlayableTableExerciseView`,
Laboratorio, Tools, Home, currículo, navegación, `AppShell`, rutas, auth,
economía — sin cambios (confirmado por auditoría de git, ver §16).

## 6. Integración en Academia

`lesson_flow.dart:34` no cambió una sola línea — `variant` default
(`academy`) preserva el comportamiento exacto. El header ahora se ve
consistente en las 4 fases del recorrido (teoría/ejercicio/feedback/
resultado), ya que es el mismo widget en las 4.

`written_theory_view.dart`: único cambio funcional es el reemplazo de
`_TheoryNavControls` (ahora eliminado) por `SvLessonNavControls`
compartido — mismo comportamiento, mismo texto, mismos callbacks.
Validado con T093 (corta) y TN10 (larga) — los mismos 2 pilotos de la
Fase 3.

## 7. Integración en Bankroll

`bankroll_screen.dart` — reescritura completa del árbol visual, sin
cambios de lógica (`_step`, `_topics`, callbacks de navegación
idénticos):

- `Scaffold.backgroundColor`: `AppColors.background` → `SalaVerdeColors.background`.
- Header: `variant: LessonFlowHeaderVariant.bankroll` explícito.
- Barra de progreso: `LessonItemProgress` → un `_Progress` local (mismo
  patrón que `written_theory_view.dart`), con `SvProgressLinear` en
  `brassDeep` — ver §8 para por qué no `brass`/`brassBright`.
- `_TopicCard`: de "7 secciones con ícono+color propio" a `SvReadingCard`
  + `SvCalloutAccent` (OBJETIVO e IDEA CLAVE, ambas en `brassDeep` — texto
  sobre `surfaceReading`, misma regla que Academia) + secciones sin
  color/ícono propio (regla anti-fragmentación de la Fase 3, aplicada acá
  por primera vez fuera de las 326 teorías).
- Navegación: `LessonNavControls` → `SvLessonNavControls`.
- `_BankrollDone`: mismo contenido, tipografía y colores Sala Verde
  (`SalaVerdeType.title()`/`body()`, ícono `brassBright`, botón
  `SvButtonSecondary`).

No se tocó: la lista de 7 temas (`BankrollTopics.all`), el contenido de
cada tema, la lógica de `_step`/`done`, ni el hecho de que Bankroll vive
fuera del currículo de 326 teorías (sin ID, sin prerrequisitos).

## 8. Decisión de color: por qué el progreso de Bankroll usa `brassDeep` y no `brass`/`brassBright`

Bankroll ya tiene un uso brillante de brass en la pantalla (el botón
CONTINUAR/VER RESULTADO, vía `SvButtonPrimary` con su `accent` default).
Si la barra de progreso *también* usara `brass`/`brassBright`, la pantalla
tendría dos acentos dorados brillantes compitiendo — exactamente el patrón
que `FLOPLY_ANTI_GENERIC.md` 0.2 busca evitar ("brass como máximo un
acento protagonista por pantalla"). `brassDeep` da un dorado
perceptiblemente más apagado: se distingue del track (`borderSubtle`, más
oscuro) y comunica la misma temperatura, pero queda claramente detrás del
botón. Es una aplicación nueva del token (documentada como tal, no una
regla preexistente): `brassDeep` había sido definido solo para texto sobre
superficie clara; acá se usa como relleno silencioso sobre fondo oscuro.
Si una fase futura encuentra que esto lee mal, es un cambio de una sola
línea (`_Progress.color` en `bankroll_screen.dart`).

## 9. Responsive

Barrido 300/320/360/375/390/412/414/430/480dp + 375×568 (altura reducida),
para el header (con título/subtítulo intencionalmente largos, ver §12) y
para toda la pantalla de Bankroll con los 7 temas reales — sin overflow en
ningún punto (`test/widgets/lesson_flow_header_test.dart`,
`test/ui/bankroll_visual_migration_test.dart`).

## 10. Accesibilidad

Sin cambios de semántica: `LessonFlowHeader` no tenía (ni tiene)
`Semantics` propios — el botón volver sigue siendo un `Icon` dentro de
`PressableScale`/`GestureDetector`, igual que antes. No se identificaron
regresiones en `test/accessibility/` (ver §15, regresión completa).

## 11. Goldens

Único afectado: `BankrollScreen` (`test/golden/goldens/ci/bankroll_screen.png`)
— cambio visual intencional (violeta/7-cajas-de-color → Sala Verde),
inspeccionado manualmente (`test/golden/failures/bankroll_screen_
{master,test}Image.png`) antes de regenerar con `--update-goldens`.
`AcademyScreen (mapa de niveles)` **no** se ve afectado: el mapa no
muestra `LessonFlowHeader` (ese solo aparece dentro de un lesson en
curso), así que ese golden queda sin tocar. `HomeScreen`/`ToolsScreen`/
`LaboratoryScreen` sin cambios.

## 12. Visual QA (navegador real)

Chromium real vía Playwright, sirviendo un entry point temporal
(`lib/main_fase4_preview_scratch.dart`, borrado al terminar) con
`AppTheme.dark` real (la primera pasada sin el tema real hizo aparecer una
pantalla color crema en `lesson_result_view` — era el harness, no
producción; ver nota abajo).

- **Bankroll, 390×844:** header con acento `brassBright`, botón volver
  con borde visible, barra de progreso `brassDeep` distinguible del
  track, `SvReadingCard` con OBJETIVO/IDEA CLAVE en `brassDeep`, secciones
  sin color propio, botón CONTINUAR en `brass`. Recorridos los 7 temas
  reales con CONTINUAR, ATRÁS entre temas, y VER RESULTADO → pantalla
  final (ícono + texto + `VOLVER AL MAPA`) — todo sin overflow ni
  artefactos.
- **Bankroll, 320×640:** mismo resultado, sin overflow, título/subtítulo
  del header y el card completo legibles.
- **Academia, lesson 4.5 (llega a T093 "Set"), 390×844:** header con
  acento `feltGreenBright`, mismo patrón que Bankroll pero con su propia
  temperatura — confirmado visualmente que las dos variantes se
  distinguen entre sí sin ambigüedad.
- **`PokerTableView` confirmado sin tocar:** al llegar a la fase de mesa
  (piloto visual de T093), la mesa (fieltro verde, borde de madera,
  cartas) se ve exactamente igual que antes de esta fase — consistente
  con el diff de git (§16).

**Hallazgo real de la sesión de QA (no un bug de producción):** la
primera pasada, con un `MaterialApp` de scratch sin `theme: AppTheme.dark`,
mostró un área color crema debajo de `lesson_result_view` ("¡Lección
completada!"). Se investigó antes de reportarlo — era el harness de QA
(scratch) usando el tema claro por defecto de Flutter, no un bug real:
`lesson_result_view.dart` depende del tema ambiente para su fondo, y el
scratch no lo estaba configurando. Se corrigió el scratch (agregar
`theme: AppTheme.dark`) y se re-verificó: la pantalla es oscura como se
espera. Ningún archivo de producción cambió por este hallazgo.

**Hallazgo real de producción, encontrado por mi propio test (no por
QA visual) y corregido:** ver §13/§14 — el label "BANKROLL" duplicado
entre el header y la barra de progreso.

**Seam confirmado, ya documentado como riesgo (§18):** al avanzar de T093
a la fase de ejercicio/resultado de esa misma lección, el header (ahora
verde) queda visualmente por encima de la barra de progreso violeta del
piloto visual mesa+burbuja y del botón "VOLVER AL MAPA" en gradiente
violeta de `lesson_result_view.dart` — ambos fuera de alcance de esta
fase. Antes de la Fase 4 esta costura existía pero era invisible (el
header viejo también era violeta); al migrar el header a verde, la
costura con el resto del recorrido se vuelve más notoria, no nueva.

## 13. Problemas encontrados

- El `LessonFlowHeader` viejo no tenía `overflow: TextOverflow.ellipsis`
  en título ni subtítulo — con un título real largo (`lesson_flow.dart`
  concatena `'${lesson.id}  ${lesson.title}'`) a 300dp esto podía
  desbordar en dispositivos angostos. Se agregó `ellipsis` a los dos
  `Text` como parte de la migración (no estaba en el alcance original,
  pero es la misma clase de bug real que motivó `Flexible` en
  `SvChipNumeric` en la Fase 1.5 — se corrigió al tocar el widget).
- El `_Progress` de Bankroll usaba la etiqueta `'BANKROLL'` — el mismo
  texto literal que `AppStrings.bankrollTitle`, ya mostrado por el header
  arriba. No era un overflow ni un fallo visual grave, pero sí una
  repetición real e innecesaria dentro de la misma pantalla. Lo encontró
  mi propio test (`test/ui/bankroll_visual_migration_test.dart`, "header
  usa el título/subtítulo reales de Bankroll" — `findsOneWidget` falló
  con "Found 2 widgets with text 'BANKROLL'"), no la inspección visual.
- Harness de QA (scratch, no producción): ver nota en §12 sobre el fondo
  crema de `lesson_result_view` — causado por el `MaterialApp` de scratch
  sin `AppTheme.dark`, corregido en el scratch, cero impacto en código de
  producción.

## 14. Bugs corregidos

- Overflow de título/subtítulo largos (§13, primer punto) — `ellipsis`
  agregado a `LessonFlowHeader`.
- Duplicación "BANKROLL"/"BANKROLL" (§13, segundo punto) — la etiqueta de
  `_Progress` en `bankroll_screen.dart` pasó de `'BANKROLL'` a `'TEMA'`
  (mismo criterio que `'TEORÍA'` en `written_theory_view.dart`: nombra el
  tipo de contenido, no repite el nombre de la sección).

## 15. Regresión

`flutter analyze`: 0 issues.

`flutter test`: base antes de Fase 4: 1171. Nuevos tests: 36
(`test/widgets/lesson_flow_header_test.dart`: 21 — 3 fijos + barrido
9 anchos × 2 variantes; `test/ui/bankroll_visual_migration_test.dart`: 15
— 9 anchos + 6 fijos). Total esperado: 1207. Total ejecutado: **1207,
1207 passed, 0 failed** (verificado en un run final completo, después de
regenerar el golden de `BankrollScreen` dos veces — una tras el rediseño
del cuerpo, otra tras el fix del label "TEMA", ver §14). Sin regresiones
en ningún test preexistente de Home/Academia/Laboratorio/Tools/
accesibilidad.

## 16. Git — cambios preexistentes vs. de esta fase

`git diff --stat -- lib/screens/academy/widgets/poker_table_view.dart` →
`96 insertions(+), 909 deletions(-)`, idéntico al valor ya registrado en
`FLOPLY_PHASE_3_ACADEMIA.md` — sin cambios de esta fase.

Archivos EXPECTED (Fase 4): `lib/screens/academy/widgets/lesson_widgets.dart`
(modificado), `lib/screens/academy/widgets/written_theory_view.dart`
(modificado), `lib/screens/bankroll/bankroll_screen.dart` (reescrito),
`lib/widgets/sala_verde/sala_verde_widgets.dart` (agregado
`SvLessonNavControls`), `test/widgets/lesson_flow_header_test.dart` (nuevo),
`test/ui/bankroll_visual_migration_test.dart` (nuevo),
`test/golden/goldens/ci/bankroll_screen.png` (regenerado), este documento.

Todo lo demás en `git status` (Android/gradle, `.gitignore`, `.metadata`,
`lib/engine/**`, `lib/models/**`, widgets de Home eliminados, etc.) es
PREEXISTENTE — trabajo en curso ajeno a esta sesión, sin tocar.

## 17. Estado de identidad visual

Bankroll deja de ser la única pantalla del árbol de navegación con el
lenguaje visual viejo (violeta + secciones con color propio). Junto con
Home (Fase 2) y Academia (Fase 3), Bankroll y el encabezado de recorrido
completan la migración de todo el camino "Home → Academia → lesson →
Bankroll" a Sala Verde. Quedan fuera: Laboratorio, Tools, pantallas de
ejercicio/feedback/resultado de Academia (siguen en `AppColors`, uso
explícitamente fuera de alcance).

## 18. Riesgos restantes

- `brassDeep` como relleno de progreso (§8) es una aplicación nueva del
  token fuera de su rol documentado original — vale la pena revisarlo con
  luz real de dispositivo, no solo en el navegador de escritorio.
- El resto de Academia (ejercicio/feedback/resultado) ahora muestra un
  header Sala Verde por encima de un cuerpo todavía en `AppColors` — la
  misma clase de costura parcial que esta fase resolvió para teoría/
  Bankroll, ahora desplazada un nivel más adentro del recorrido.

## 19. Recomendación para Fase 5

Candidatos, sin implementar nada de esto todavía: (a) migrar
`exercise_view.dart`/`feedback_view.dart`/`lesson_result_view.dart` para
que el resto del recorrido de Academia deje de tener la costura descrita
en §18; o (b) Laboratorio, que es la sección más grande sin tocar. La
decisión es del usuario — no se avanza automáticamente.
