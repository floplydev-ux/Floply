# FLOPly Human QA — Phase 4.5

**Fecha:** 2026-09-19. Auditoría corta y estrictamente dirigida sobre los dos bugs confirmados en la Fase 4 (`FLOPLY_HUMAN_QA_PHASE4_2026-09-19.md`). Combina lectura de código real (no solo inferencia desde comportamiento) con re-verificación en vivo. **No se modificó ningún archivo de FLOPly** — todo lo de abajo es lectura + `grep` + interacción real vía Marionette, cero ediciones.

## 1. Objective

Determinar, con evidencia de código y no solo de comportamiento, el alcance exacto y la causa técnica de BUG-001 (RAISE bloqueado por el FAB) y BUG-002 (branding "Floply"), diferenciando explícitamente overlap visual de intercepción real de hit-test, y dejando el terreno preparado para una futura fase de fix sin que esa fase tenga que re-descubrir nada.

## 2. Baseline

Se reutiliza el baseline de la Fase 4 (`flutter analyze` → 0 issues; `flutter test` → 972/972, sin cambios de código Dart desde entonces). No se volvió a correr porque, otra vez, no se tocó ningún archivo `.dart` — esta fase fue lectura + Marionette, no edición.

## 3. Scope

Exclusivamente BUG-001 y BUG-002. El hallazgo del "bottom sheet fantasma" (Fase 3/4) se tocó solo lo mínimo necesario para confirmar que no tiene relación con BUG-001 (§9 de este documento) — no se investigó más a fondo, tal como pedía el encargo.

## 4. FAB Component Audit

El FAB vive en un único lugar: `lib/screens/root/app_shell.dart`, dentro de `_AppShellState.build()`:

```dart
return Scaffold(
  body: IndexedStack(index: _currentIndex, children: screens),
  floatingActionButton: FloatingActionButton(
    heroTag: 'tableModeFab',
    tooltip: AppStrings.tableModeFabTooltip,
    backgroundColor: AppColors.violetPrimary,
    onPressed: () => showTableModeSheet(context),
    child: const Icon(Icons.bolt_rounded, color: Colors.white),
  ),
  bottomNavigationBar: AppBottomNavigation(...),
);
```

Respuestas directas a las 13 preguntas del encargo:

1. **¿Dónde se crea?** `AppShell` (raíz de navegación por pestañas), una sola vez.
2. **¿Es reutilizable?** No es un widget propio extraído — es el `floatingActionButton:` estándar de un único `Scaffold` de Material.
3. **¿En qué pantallas aparece?** En las 5 pestañas (`IndexedStack` con Home/Academia/Laboratorio/Estadísticas/Perfil como `body`) — el comentario del propio archivo lo confirma explícitamente: *"visible en las 5 pestañas a propósito: es 'ayuda rápida'... pensada para abrirse desde donde sea"*.
4. **¿Está dentro de un `Stack`?** No de uno escrito a mano — `Scaffold` arma su propio `Stack` interno (mecanismo estándar de Flutter Material) para superponer `floatingActionButton` sobre `body`.
5. **¿Orden dentro del Stack?** El de `Scaffold`: el FAB se pinta y se hit-testea **por encima** del `body` — comportamiento nativo de Material, no una decisión de este código.
6. **Área visual:** confirmada en vivo — `bounds: {x:288, y:662, width:56, height:56}` en el viewport de 360×800 usado en todas las fases (posición default `FloatingActionButtonLocation.endFloat`: abajo a la derecha, por encima de `bottomNavigationBar`).
7. **Área real de hit testing:** la misma — no hay ningún `IgnorePointer`/`AbsorbPointer` ni redefinición de `HitTestBehavior` en el FAB ni en su entorno. Es un `FloatingActionButton` de Material estándar.
8. **¿Coinciden área visual y área de hit testing?** Sí, exactamente — es el comportamiento nativo de Material, no hay ninguna manipulación custom.
9. **¿Puede su bounding box cubrir otros controles?** Sí — cualquier contenido del `body` que cualquiera de las 5 pantallas dibuje en esa esquina.
10. **¿Existe alguna protección explícita contra solapamiento?** **No.** Ni `AppShell` reserva espacio en el `body` para el FAB, ni ninguna de las pantallas hijas consulta la posición del FAB al armar su propio layout.
11. **¿Depende de la resolución/tamaño de pantalla?** El FAB en sí no — su posición default es fija en dp respecto al borde. Lo que sí depende del tamaño es *cuánto contenido* del body cae bajo esa esquina (ver §10 de este documento).
12. **¿Depende del contenido de la pantalla?** Sí — ver §5, §6.
13. **¿Depende del estado del ejercicio?** Sí, indirectamente: solo el estado "eligiendo acción" (`_ActionButtons`) o "ya respondido, con Continuar" (`_AnsweredBar`) de `PlayableTableExerciseView` pone contenido interactivo en esa franja inferior; otros estados del mismo ejercicio (mesa mostrando el resultado, sin botones) no.

## 5. FAB Usage Inventory

| Pantalla | FAB visible | Contenido debajo (franja inferior) | Posible solapamiento | Verificado |
|---|---|---|---|---|
| Home | Sí (las 5 pestañas) | Ninguno — el contenido es scrolleable, sin fila de acciones ancladas abajo a la derecha | No | Sí, en vivo (Fases 2-4) |
| Academia — mapa de nivel | Sí | Lista de lecciones, sin fila de acciones inferior | No | Sí, en vivo |
| Academia — teoría (`TheoryView`, `VisualTheoryStageView`, etc.) | Sí | Varía según el tipo de teoría; no se auditó cada variante en esta fase corta (fuera del alcance: solo BUG-001/002) | No verificado exhaustivamente | Parcial |
| **Academia — ejercicio jugable** (`PlayableTableExerciseView` vía `lesson_flow.dart`) | Sí | `_ActionButtons` (elegir acción) o `_AnsweredBar` (botón "Continuar") | **Sí, visual** | Sí, en vivo (Fase 2-3) |
| **Laboratorio — ejercicio** (`PlayableTableExerciseView` vía `laboratory_screen.dart`) | Sí | `_ActionButtons` (FOLD/CALL/RAISE) | **Sí, visual + funcional** | Sí, en vivo (Fase 4 y esta fase) |
| Estadísticas | Sí | Listas y tarjetas, sin fila de acciones ancladas | No | Sí, en vivo |
| Perfil | Sí | Un solo botón "Crear cuenta" centrado, lejos de la esquina | No | Sí, en vivo |

**Conclusión de inventario:** de las 5 pestañas y sus sub-pantallas, el conflicto real está acotado a **exactamente un componente compartido**: `PlayableTableExerciseView` (`lib/screens/academy/widgets/playable_table_exercise_view.dart`), usado por sus dos únicos hosts de producción reales: `lesson_flow.dart` (Academia) y `laboratory_screen.dart` (Laboratorio). Se encontró un tercer lugar que importa el widget (`lib/screens/laboratory/widgets/playable_table_exercise_preview.dart`) pero es, según su propio comentario de cabecera, un **archivo de Flutter Widget Preview para desarrollo — "no se usa en producción — ningún screen real lo importa"**. No cuenta para el inventario de pantallas reales afectadas.

**Respuesta a la pregunta del §2 del encargo:** el problema es **C — transversal del componente FAB**, combinado con **D — de composición específica**: transversal porque el FAB es uno solo, compartido por las 5 pestañas por diseño; específico de composición porque solo se manifiesta en las pantallas cuyo `body` decide, por su cuenta, dibujar una fila de controles a todo el ancho justo en esa franja inferior — que resultan ser, exactamente, las dos que hostean `PlayableTableExerciseView`.

## 6. Hit-Test Analysis

**Visual bounds del FAB:** `{x:288-344, y:662-718}` (56×56, confirmado en vivo, estable en todas las fases).

**Visual bounds de RAISE** (fila de 3 acciones, cálculo confirmado con los bounds reales de FOLD/CALL, que se reproducen idénticos hand tras hand): el `Row` de `_ActionButtons` ocupa el ancho completo disponible (`18` a `342`, 324px totales, coincide exactamente con `MediaQuery` menos el padding de `laboratory_screen.dart`, `pad=18` a cada lado sobre un viewport de 360). Con 3 acciones y 2 separadores de 8px, cada botón mide `(324-16)/3 = 102.67px`. RAISE, al ser el tercer y último elemento, ocupa `x: 239.33 → 342`.

**Overlap real:** `[239.33, 342] ∩ [288, 344] = [288, 342]` → **el FAB cubre el 51.5% del ancho de RAISE, incluyendo su mitad derecha completa y, crucialmente, gran parte de su zona central.**

**Interactive bounds según Marionette:** RAISE **no aparece nunca** en `get_interactive_elements`, en ninguna de las 4 veces que se lo buscó a lo largo de las Fases 2-4-4.5, en manos distintas. FOLD y CALL sí aparecen siempre, con los mismos bounds "teóricos" de 3-vías (102.67px) — es decir, el layout se calcula como si los 3 botones existieran, pero solo 2 quedan listados como interactivos.

**Covered bounds:** exactamente la porción de RAISE calculada arriba — nada de FOLD ni CALL, que están completamente a la izquierda de x=288.

**Effective hit target:** confirmado en vivo, dos veces en esta fase (además de las dos de la Fase 4): un tap en `(300, 700)` — dentro de RAISE visualmente, dentro del FAB por hit-test — abre el `FloatingActionButton` (`showTableModeSheet`), nunca la acción RAISE.

**Interpretación técnica de por qué RAISE nunca aparece en `get_interactive_elements` (no solo falla al tocarlo):** el widget de RAISE existe en el árbol de Flutter (el código lo construye incondicionalmente, sin lógica que lo omita) — lo que pasa es que su comportamiento coincide exactamente con el de un usuario real: si el punto que Marionette usaría para dirigir un tap ahí en realidad resuelve, por hit-testing normal de Flutter, al `FloatingActionButton` (que está por encima), entonces esa "interactividad" no existe de forma efectiva — y `get_interactive_elements` no lo lista. Esto es consistente con que **CONTINUAR** (en `_AnsweredBar`, ver §8) sí aparece siempre: su caja es mucho más ancha (`Expanded(flex: 6)` sobre un `Row` de 2 elementos) y su centro geométrico queda claramente a la izquierda del FAB, aunque su borde derecho quede visualmente tapado.

**Conclusión de esta sección: `[Categoría 11 del encargo] Laboratorio = Caso 3 (hit-test interception real), Academia = Caso 2 (overlap visual, botón sigue siendo interactivo en su punto lógico de tap)`** — con el matiz de riesgo real señalado en §8.

## 7. BUG-001 Verification

**Reproducido de nuevo, 2 veces, en esta fase (independiente de las 2 veces ya documentadas en la Fase 4 — total acumulado: 4/4):**

1. Se entró a Laboratorio → FÁCIL → ejercicio real (mano 1/8, BTN con FOLD/CALL/RAISE disponibles). `get_interactive_elements` mostró únicamente FOLD y CALL, con bounds consistentes con un layout de 3 columnas (confirmando indirectamente que RAISE existe pero no es hit-testeable). Un tap en `(300, 700)` abrió el sheet "Ayuda Rápida" (confirmado con un `Semantics(label: "Scrim", hint: "Close Bottom Sheet")` real en el árbol tras el tap — la prueba más limpia obtenida hasta ahora de que el modal realmente se abrió).
2. Repetido una vez más sobre la misma mano, mismo resultado.

**No cambió respecto a la Fase 4.** Mismo mecanismo, misma pantalla, mismo resultado.

## 8. Academia FAB Verification

Se revisó el código de `_AnsweredBar` (mismo archivo, usado por ambos hosts) en vez de re-explorar la app en vivo para esto — el comportamiento en vivo de "Continuar" ya está extensamente probado y funcionando en las Fases 2 y 3 (avanzó lecciones sin fallar ni una vez, una vez aplicado el protocolo anti-stale).

`_AnsweredBar` es un `Row` de 2 elementos: un chip de solo-lectura (`Flexible(flex: 4)`, muestra qué acción se eligió) y el botón real "Continuar" (`Expanded(flex: 6)`). Sobre los 324px de ancho disponibles (menos 10px de separador), el botón "Continuar" mide aproximadamente 188px, ubicado aproximadamente en `x: 136 → 324` (más el padding del contenedor raíz) — su **centro** cae claramente antes de x=288 (el borde izquierdo del FAB), mientras que su **borde derecho** sí quedaba dentro de la zona del FAB — consistente con el clipping visual observado ("CONTINUA" en vez de "CONTINUAR" en los screenshots de la Fase 2).

**Determinación para las 5 categorías pedidas:**

- **Caso 1 (solo overlap visual):** no exactamente — hay overlap visual, pero no es "solo" eso.
- **Caso 2 (overlap visual + el botón sigue siendo interactivo):** **este es el caso real.** Confirmado tanto por la geometría (el centro del botón está fuera del área del FAB) como por el comportamiento en vivo (CONTINUAR nunca falló en 2 fases de uso real).
- **Caso 3 (el FAB intercepta la acción):** no — a diferencia de RAISE, cuyo centro completo cae bajo el FAB.
- **Caso 4 (ya no existe):** no, el clipping visual sigue presente en el código actual (no se tocó nada).
- **Caso 5 (depende de contenido/tamaño):** parcialmente cierto — ver §10: a un ancho de pantalla distinto, la proporción del botón cubierta por el FAB cambiaría, pero el mecanismo de fondo (ningún padding reservado para el FAB) es el mismo.

**Riesgo real no capturado por "el centro sigue siendo interactivo":** un usuario real no necesariamente toca el centro geométrico exacto de un botón — puede tocar cualquier punto que perciba como parte del botón, incluida su mitad derecha, que en este caso está física y visualmente ocupada por el FAB. Es decir: **Academia no está "arreglada" solo porque el centro funcione** — el riesgo de que un toque real caiga sobre el FAB en vez de "Continuar" es menor que en Laboratorio (mucha más área del botón queda libre), pero no es cero. Se documenta este matiz explícitamente para que una futura fase de fix no lo pierda de vista.

## 9. Cross-Screen FAB Comparison

Academia y Laboratorio usan **exactamente el mismo componente** (`PlayableTableExerciseView`, mismo archivo, mismas clases privadas `_ActionButtons`/`_AnsweredBar`) — no son implementaciones distintas con apariencia similar. La diferencia de severidad entre ambas pantallas no viene del componente en sí, sino de:

1. **Cuántos elementos comparten la fila** (`_ActionButtons`: 2 o 3 acciones, cada una obligada a competir por el mismo ancho total; `_AnsweredBar`: siempre 2 elementos, con un reparto de flex 4/6 en vez de partes iguales).
2. **Qué tan ancho es el elemento que termina en la esquina derecha** (RAISE con flex igualitario entre 3 ≈ 102px; "Continuar" con flex 6 de 2 ≈ 188px).

Ninguna de las dos pantallas host (`lesson_flow.dart`, `laboratory_screen.dart`) reserva padding consciente del FAB — ambas solo agregan un colchón inferior genérico (`bottomInset` en Academia, `12` fijo en Laboratorio) pensado para el inset del sistema (gesture bar), no para el FAB. Esto confirma que la causa raíz es una — **la ausencia de cualquier mecanismo, en cualquiera de las dos pantallas o en el propio `AppShell`, que reserve espacio para el FAB persistente** — y que se manifiesta con severidad distinta por una razón puramente geométrica (cantidad y ancho de los elementos en la fila), no por código distinto.

## 10. Responsive / Viewport Findings

- **Viewport utilizado en toda la auditoría en vivo:** 360×800 (el que reporta Marionette consistentemente en Chrome debug, ver Fases 1-4).
- **¿El layout usa valores fijos o relativos?** Mixto: el `Row` de botones usa `Expanded`/`Flexible` (relativo, se adapta al ancho disponible); el padding lateral de cada pantalla host es un valor discreto por breakpoint (`18.0` bajo 480px de ancho, `24.0` en o por encima — ver `laboratory_screen.dart:73` y `lesson_flow.dart:43`); el FAB usa la posición default de Material, que es un offset fijo en dp desde el borde, no relativo al ancho.
- **¿Tiene el FAB posición absoluta?** Sí, en el sentido de Material: es un offset fijo respecto al borde de la pantalla, no relativo al contenido.
- **¿Los controles afectados tienen posición fija?** No — son relativos (`Expanded`), lo que significa que a un ancho de pantalla mayor, cada botón sería más ancho en términos absolutos, y la porción de RAISE cubierta por el FAB (que sigue siendo 56px fijos) sería proporcionalmente menor — pero mientras el ancho total no supere significativamente los ~360-400px de un teléfono angosto, el overlap real seguramente persiste.
- **Segundo viewport:** **NOT VERIFIED.** No fue técnicamente sencillo dentro del alcance de esta fase — Marionette no expone un control directo para redimensionar la ventana de Chrome sin relanzar `flutter run` con otro tamaño, y hacerlo hubiera significado perder el estado de la sesión en curso sin aportar certeza adicional sobre el mecanismo (que ya está confirmado por código, no depende de conjeturas de viewport). Se documenta como limitación real, no se inventa un resultado de Android ni de otro ancho.

## 11. BUG-002 Verification

**Dónde aparece "Floply" (texto de usuario, `lib/l10n/app_strings.dart`, sección "Auth — cuenta", Fases 8/16/17/18 y 9 según los propios comentarios del archivo):**

```dart
static const String accountMethodsBody =
    'Todos representan la misma cuenta Floply.';
...
static const String accountGuestTitle = 'Estás usando Floply sin cuenta';
...
static const String accountConflictTitle =
    'Este método de acceso ya está en otra cuenta Floply.';
```

**Confirmado visible en vivo:** solo `accountGuestTitle` — es el único de los tres alcanzable como usuario invitado (los otros dos requieren una cuenta con múltiples métodos vinculados o un conflicto real de autenticación, estados no alcanzables sin backend real de Firebase en este entorno). Los otros dos se confirman por código, no por pantalla — se documentan igual porque son el mismo tipo de string, en el mismo archivo, con el mismo casing incorrecto.

**Dónde debería decir "FLOPly":** confirmado como el casing de marca real y correcto en `lib/auth/widgets/auth_screen.dart:162` (el logo grande de la pantalla de login, visible y correcto en todas las fases anteriores).

**¿Está aislado a Perfil?** No — está aislado a estas **3 strings de un mismo archivo y una misma sección** (`app_strings.dart`, bloque "Auth — cuenta" + "Auth — conflicto de cuentas"), pero **no** a una sola pantalla: `accountGuestTitle` aparece en Perfil; los otros dos aparecerían en pantallas de vinculación de cuenta y de conflicto de login, no visitadas en esta auditoría por no ser alcanzables como invitado.

**¿Existen más variantes?** Se buscaron explícitamente `Floply`, `FLOPly`, `FLOPLY`, `FlopLy` en todo `lib/`. Además de las 3 strings de arriba:
- `FloplyUser` (la clase del modelo de usuario, `lib/auth/models/floply_user.dart`) y sus ~15 referencias en todo el módulo de auth — esto es un **identificador de código Dart** (nombre de clase), no texto visible para el usuario. PascalCase de Dart no preserva el juego visual "FLOP" de la marca de forma natural (`FLOPlyUser` sería un nombre inusual) — **no se cuenta como parte de BUG-002**, es una convención de nombres interna.
- `lib/engine/pedagogy/curriculum_spec_data.g.dart:8`: `'proyecto': 'Floply · Academia'` — metadata dentro de un **archivo generado** (`// GENERADO por tool/curriculum/gen_curriculum.py — NO editar a mano`, fuente real: `assets/curriculum/curriculum_spec.json`). Se verificó con `grep` que `kCurriculumSpecMeta` solo se lee una vez (`lib/engine/pedagogy/theory.dart:463`, para armar un `CurriculumSpec`) y que ninguna pantalla accede a su clave `'proyecto'` — **confirmado que nunca llega a la UI.** Se registra como `RELATED OBSERVATION`, no como bug nuevo, tal como pedía el encargo.

**Origen del string:** las 3 strings de `app_strings.dart` parecen haberse escrito directamente con "Floply" en el momento en que se redactó esa sección (Fases 8/9/16/17/18, según los comentarios) — no hay evidencia de que haya sido "FLOPly" alguna vez y se haya roto después; probablemente un simple desliz de tipeo no detectado, repetido 3 veces porque las 3 strings se escribieron en la misma sesión de trabajo.

## 12. Branding Usage Inventory

| Variante | Dónde | Tipo | ¿Visible al usuario? |
|---|---|---|---|
| `FLOPly` | `auth_screen.dart:162` (logo de login) | UI string | Sí — correcto, es la marca real |
| `Floply` | `app_strings.dart` × 3 (`accountMethodsBody`, `accountGuestTitle`, `accountConflictTitle`) | UI string | Sí (1 de 3 confirmado en vivo; los otros 2 por código) — **incorrecto** |
| `FloplyUser` | `lib/auth/models/floply_user.dart` + ~15 referencias | Identificador Dart (nombre de clase) | No | 
| `Floply · Academia` | `curriculum_spec_data.g.dart:8` (generado) | Metadata interna | No, confirmado sin lectores en UI |

## 13. Root Cause Assessment

**BUG-001 — causa CONFIRMADA (no solo probable), desde código + ejecución:**
El `FloatingActionButton` de `AppShell` (`lib/screens/root/app_shell.dart`) es un único componente Material estándar, compartido por las 5 pestañas por diseño explícito, posicionado por Flutter en la esquina inferior derecha con hit-testing por encima del `body`. `PlayableTableExerciseView` (`lib/screens/academy/widgets/playable_table_exercise_view.dart`), el único widget que dibuja una fila de acciones ancladas a esa franja inferior, no reserva ningún margen consciente del FAB — ni tampoco lo hacen sus dos hosts reales (`lesson_flow.dart`, `laboratory_screen.dart`), que solo agregan un colchón genérico pensado para el inset del sistema. Cuando la fila tiene 3 elementos de ancho igual (Laboratorio: FOLD/CALL/RAISE), el tercero cae mayoritariamente bajo el FAB, incluido su centro — bloqueo funcional real. Cuando tiene 2 elementos con un reparto de ancho desigual que deja al botón de acción con un centro más a la izquierda (Academia: chip + "Continuar"), el bloqueo funcional no ocurre en la práctica, aunque el clipping visual sí.

**BUG-002 — causa CONFIRMADA:** 3 strings de contenido en `app_strings.dart`, todas de la misma sección de código (cuenta/auth-conflict), escritas con "Floply" en vez de "FLOPly" — un desliz de tipeo consistente dentro de esa sección, no una inconsistencia sistémica de branding en toda la app (el resto de la app, incluida la pantalla de login, usa el casing correcto).

## 14. Confirmed Findings

- **BUG-001 sigue siendo HIGH.** Confirmado por código (causa exacta identificada) y reproducido 4/4 veces en total entre Fase 4 y esta fase. Afecta exactamente 1 de las 2 pantallas que comparten el componente: Laboratorio (bloqueo funcional real). Academia comparte el mismo componente y el mismo overlap visual, pero no el bloqueo funcional, por una razón geométrica precisa y documentada (§8).
- **BUG-002 sigue siendo LOW.** Confirmado por código: 3 strings, 1 sección de `app_strings.dart`, no una inconsistencia de branding amplia. Alcance mayor de lo reportado en Fase 4 (3 strings, no 1) pero mismo origen y misma severidad — es contenido incorrecto, no un problema estructural.

## 15. Uncertain Findings

- El comportamiento exacto del FAB/overlap en un viewport más ancho que ~480px queda **NOT VERIFIED** (§10) — la causa raíz no depende de eso, pero la magnitud práctica del problema en pantallas más grandes no se confirmó en vivo.
- No se determinó si las otras 2 strings "Floply" (`accountMethodsBody`, `accountConflictTitle`) se ven exactamente como se esperaría en su contexto real — se confirmaron por código, no visualmente, porque sus pantallas no son alcanzables como invitado en este entorno.
- El comportamiento del FAB en Academia bajo otros tipos de teoría (`InteractiveTableLesson`, `MentorLessonStageView`, `WrittenTheoryView`) no se auditó — fuera del alcance explícito de esta fase (solo BUG-001/002).

## 16. Phase 4 Findings Reconciliation

| Hallazgo | Fase 4 | Fase 4.5 |
|---|---|---|
| BUG-001 (RAISE bloqueado) | Observado y reproducido 2/2 en vivo; clasificado HIGH; causa "probable" (superposición del FAB en el Stack) | **Causa CONFIRMADA por código** (§4-§6, §13); reproducido 2/2 veces adicionales; alcance acotado a exactamente 2 pantallas de producción, ambas por el mismo componente compartido; distinguido explícitamente de Academia (Caso 2 vs. Caso 3) |
| BUG-002 ("Floply") | Un string observado en Perfil; clasificado LOW; alcance no determinado | **Alcance ampliado a 3 strings confirmadas por código**, misma sección de `app_strings.dart`, mismo origen; severidad sin cambios (LOW); descartado como inconsistencia sistémica |
| Bottom sheet fantasma | Observación de infraestructura/Marionette, sin investigar causa | No investigado más — solo se confirmó (§9) que el sheet real usa `showModalBottomSheet` estándar sin overrides, lo cual es consistente con "artefacto de observación de Marionette", no un bug de FLOPly. Se mantiene sin resolver como estaba. |

## 17. Recommended Fix Scope

**Únicamente para orientar una futura fase de FIX — nada de esto se implementó acá:**

- **BUG-001:** el fix más directo, a nivel de diseño, sería que `PlayableTableExerciseView` (o sus hosts) reserven un margen a la derecha equivalente al footprint del FAB (56px + su margen estándar) cuando la fila de acciones está en pantalla — o, alternativamente, ocultar/mover el FAB mientras el usuario está en medio de una decisión de ejercicio (`_ActionButtons`/`_AnsweredBar` activos), ya que en ese momento "Ayuda rápida" compite directamente con la acción principal de la pantalla. Cualquiera de las dos opciones necesita decidirse en una fase de diseño, no en esta.
- **BUG-002:** cambiar las 3 strings de `app_strings.dart` (líneas 487, 500, 508) de "Floply" a "FLOPly". Cambio de una sola sección, bajo riesgo, sin impacto de layout.

## 18. Final Matrix

| Finding | Phase 4 Status | Phase 4.5 Status | Reproduced | Scope | Confidence |
|---|---|---|---|---|---|
| FAB blocks RAISE | HIGH | **CONFIRMED** (causa de código + comportamiento) | Sí, 4/4 (2 Fase 4 + 2 Fase 4.5) | Laboratorio únicamente (1 de 2 pantallas que comparten el componente) | Alta |
| FAB overlaps Academia CTA | Observation | **CONFIRMED** como overlap visual; **NOT REPRODUCIBLE** como bloqueo funcional (centro del botón queda fuera del FAB) | Sí — comportamiento correcto reproducido en 2 fases previas; geometría confirmada por código en esta fase | Academia únicamente, mismo componente que Laboratorio | Alta |
| Perfil "Floply" | LOW | **CONFIRMED**, alcance ampliado a 3 strings | Sí — 1/3 en vivo, 3/3 por código | `app_strings.dart`, sección "Auth — cuenta" + "Auth — conflicto de cuentas" únicamente | Alta |
| Bottom sheet stale | Tool/Observation | **TOOL ISSUE** (sin cambios — confirmado que el código del sheet es estándar, sin causa de app) | No re-investigado a fondo (fuera de alcance) | N/A | Media (por diseño, no se profundizó) |

---

## Resumen ejecutivo

**BUG-001 sigue siendo HIGH — confirmado con causa de código, no solo con comportamiento.** Afecta exactamente a Laboratorio (bloqueo funcional real de RAISE) y, en menor medida, a Academia (overlap visual del botón "Continuar", sin bloqueo funcional confirmado pero con un riesgo residual real para un usuario que toque el borde derecho del botón). Ambas pantallas comparten el mismo componente (`PlayableTableExerciseView`) y la misma causa raíz: el FAB persistente de `AppShell` no tiene ningún mecanismo de exclusión mutua con el contenido de las pantallas que dibujan controles en su misma esquina.

**BUG-002 sigue siendo LOW — alcance ampliado de 1 a 3 strings**, todas en la misma sección de código, mismo origen, sin evidencia de una inconsistencia de branding más amplia en el resto de la app.

**No queda ninguna incertidumbre estructural sobre la causa de ninguno de los dos bugs** — la única incertidumbre real y explícitamente marcada es de alcance práctico en viewports más anchos (§10, §15), no de causa.

**No se modificó FLOPly.** No se pasó a una fase de fix.
