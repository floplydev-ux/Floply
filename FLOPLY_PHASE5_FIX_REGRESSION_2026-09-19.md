# FLOPly Phase 5 — Fix + Regression

**Fecha:** 2026-09-19. Corrige BUG-001 (HIGH) y BUG-002 (LOW), ambos confirmados con causa de código en `FLOPLY_HUMAN_QA_PHASE4_5_2026-09-19.md`. Incluye diseño previo a la implementación, tests automatizados nuevos (probados en rojo contra el código sin arreglar antes de aceptarlos como válidos), regresión completa (`flutter analyze` + suite completa), y regresión Human QA en vivo con `floply-human-qa` contra la app real.

## 1. Objective

Corregir ambos bugs con la solución arquitectónicamente más chica y general posible, sin tocar nada fuera de su alcance real, y demostrar con evidencia automatizada + en vivo que quedaron resueltos sin regresiones.

## 2. Baseline

Antes de cualquier cambio:
- `flutter analyze` → **0 issues**.
- `flutter test` → **972/972**, sin cambios de código Dart desde la corrida de la Fase 4 (reutilizada, no repetida sin motivo).

## 3. Root Causes

Ya establecidas con evidencia de código en la Fase 4.5 (`FLOPLY_HUMAN_QA_PHASE4_5_2026-09-19.md`, §13) — no se re-derivan acá, se resumen:

- **BUG-001:** `AppShell` (`lib/screens/root/app_shell.dart`) monta un único `Scaffold.floatingActionButton` ("Ayuda rápida"), compartido a propósito por las 5 pestañas. `PlayableTableExerciseView` (`lib/screens/academy/widgets/playable_table_exercise_view.dart`) — el mismo widget que usan Academia (`lesson_flow.dart`) y Laboratorio (`laboratory_screen.dart`) — dibuja su fila de acciones a todo el ancho, sin reservar ningún margen consciente del FAB. En Laboratorio, con 3 botones de ancho igual, el tercero (RAISE) queda con su centro bajo el área de hit-test del FAB.
- **BUG-002:** 3 strings de `lib/l10n/app_strings.dart` (sección "Auth — cuenta"/"conflicto de cuentas") decían "Floply" en vez de "FLOPly".

## 4. Fix Design

### Root Cause
(Ver §3 — no se repite.)

### Candidate Solutions

1. **Parche específico** (`if (action.action == PokerAction.raise) ...`, o coordenadas hardcodeadas): descartado de entrada — viola la Regla 2/3 del encargo explícitamente, y no generaliza a `_AnsweredBar`/`_SizeButtons`/`_ReasoningButtons`, ni a un futuro ejercicio con 4 acciones.
2. **Mover el FAB** (`floatingActionButtonLocation: startFloat` u otra posición): descartado. El FAB es un componente deliberadamente compartido por las 5 pestañas (comentario propio de `AppShell`); moverlo no resuelve el principio general (el problema es que *algo* puede terminar en su esquina, sea cual sea esa esquina) y arriesga las 3 pestañas que hoy no tienen ningún problema (Home, Estadísticas, Perfil) sin necesidad. Regla 4 del encargo pide evitar esto salvo justificación arquitectónica fuerte, que acá no existe.
3. **Reservar un margen consciente del FAB en el lado del contenido** (`PlayableTableExerciseView`, en la fila de acciones): resuelve el principio general directamente donde vive el conflicto real.

### Selected Solution

La opción 3: un `Padding` con un ancho reservado a la derecha (`kFabAvoidanceWidth`) alrededor de `bottomBar` (la fila de acciones, sea `_ActionButtons`, `_SizeButtons`, `_ReasoningButtons` o `_AnsweredBar`) en `PlayableTableExerciseView.build()`. El valor reservado es el tamaño default de un `FloatingActionButton` de Material (56.0) más su margen público estándar (`kFloatingActionButtonMargin`, 16.0) — una constante con nombre y documentación, no un número mágico.

### Why

- **Localizado** (Regla 1): un solo archivo, la clase ya identificada como causa raíz — no toca `AppShell`, navegación, curriculum, progreso, pedagogía, ni lógica de póker.
- **General** (Regla 3): al envolver `bottomBar` (la variable que ya decide cuál de las 4 barras mostrar), la solución aplica exactamente igual sin importar cuántas acciones haya, cuál quede última, ni si el host es Academia o Laboratorio — la reflow de `Row`/`Wrap`/`Column` hace el resto automáticamente.
- **No mueve el FAB** (Regla 4): cero riesgo para Home, Estadísticas o Perfil.
- **Sin números mágicos propios**: reutiliza la constante pública de Flutter para el margen; documenta de dónde sale el 56.0 (default de Material, sin constante pública equivalente).

### Expected Impact

RAISE (y cualquier último botón de la fila) se desplaza a la izquierda lo suficiente para que su centro —y en la práctica casi toda su área— quede fuera del área de hit-test del FAB. Efecto colateral esperado y deseable: el clipping visual que ya tenía "Continuar" en Academia (Fase 2) desaparece también, sin ningún cambio adicional.

### Regression Risks

- Botones ligeramente más angostos — mitigado por el `overflow: TextOverflow.ellipsis, maxLines: 1` que esos widgets ya tenían antes del fix.
- Ningún golden test existente cubre este widget (confirmado buscando en `test/` antes de escribir nada nuevo) — no hay que actualizar snapshots.
- El padding se aplica siempre, incluso en el archivo de Flutter Widget Preview (`playable_table_exercise_preview.dart`, que **no se usa en producción**) — sin efecto real, ese archivo no tiene FAB alrededor.

## 5. Implementation

Cambios de código, exactamente los descriptos en el diseño — nada más:

- **`lib/screens/academy/widgets/playable_table_exercise_view.dart`**: agrega la constante pública documentada `kFabAvoidanceWidth`; extrae el `if/else if/else` que arma la barra inferior a una variable `bottomBar` (mismo contenido, sin cambios de comportamiento); envuelve esa variable en `Padding(padding: EdgeInsets.only(right: kFabAvoidanceWidth))`.
- **`lib/l10n/app_strings.dart`**: 3 reemplazos exactos, "Floply" → "FLOPly", en `accountMethodsBody`, `accountGuestTitle`, `accountConflictTitle`. Ningún otro string tocado.

Verificado con `grep` tras el cambio: no quedó ningún `if (raise)`, coordenada, ni excepción por pantalla en el archivo — ver §14 más abajo (Fase L del encargo).

## 6. BUG-001 Verification

### Automatizada
`test/ui/fab_avoidance_test.dart` (nuevo), usando el mismo harness real de `app_shell_test.dart` (`AppShell` completo, FAB incluido — a propósito, porque `laboratory_new_engine_test.dart` monta `LaboratoryScreen` sin el FAB alrededor y nunca hubiera detectado nada).

**Hallazgo metodológico real durante la escritura de los tests** (documentado con honestidad, no ocultado): la primera versión de estos tests pasaba igual **con el bug todavía presente**, porque el tamaño default de la superficie de test de Flutter es mucho más ancho que un teléfono real, y a ese ancho RAISE y el FAB no llegan a superponerse. Se corrigió fijando el viewport a 360×800 (el mismo usado en todas las verificaciones en vivo) con el helper ya existente `test/support/responsive_widths.dart` (`setResponsiveWidth`) — reutilizado, no duplicado. **Se verificó explícitamente que los tests fallan contra el código sin el fix** (revirtiendo `Padding` temporalmente, corriendo la suite, viendo 3 fallos reales con el mismo warning de hit-test que reproduce el bug real, y recién ahí restaurando el fix) antes de darlos por buenos — ver evidencia completa en §8.

Cobertura final (13 tests):
- RAISE recibe el tap real (no abre Ayuda rápida) — 1 vez simple + 1 vez repetida 2x en ejercicios distintos + 1 vez por cada uno de los 5 anchos de teléfono que la propia suite de FLOPly ya usa (`kResponsivePhoneWidths`: 320/360/390/412/430).
- FOLD y CALL siguen funcionando igual que antes.
- El FAB sigue abriendo "Ayuda rápida" durante un ejercicio activo, se puede cerrar, y los controles de decisión (RAISE) siguen respondiendo después.

### En vivo (Marionette, `floply-human-qa`)
Ver §9 — RAISE reproducido 2/2 veces reales contra la instancia corriendo, con el árbol de widgets mostrando el bounds exacto de RAISE (`x:191-270`) completamente afuera del FAB (`x:288-344`), antes y después de completar el flujo de tamaño → feedback.

## 7. BUG-002 Verification

### Automatizada
`test/ui/branding_strings_test.dart` (nuevo): 3 tests, uno por string, comprobando `contains('FLOPly')` y `isNot(contains('Floply'))` — sin convertirlo en una migración global (no se tocó `FloplyUser` ni ningún otro identificador de código, según lo pedía explícitamente el encargo).

### En vivo
Perfil muestra "Estás usando **FLOPly** sin cuenta" — confirmado con screenshot real tras el fix (§9).

## 8. Automated Tests

| Comando | Resultado |
|---|---|
| `flutter analyze` (archivo del fix) | 0 issues |
| `flutter analyze` (proyecto completo, post-fix) | 0 issues |
| `flutter test test/ui/fab_avoidance_test.dart test/ui/branding_strings_test.dart` (con el fix revertido temporalmente, solo para验证) | **3 tests fallaron** (los 3 que tocan RAISE), con el mismo síntoma real: `WidgetController.tap` reporta que el offset de RAISE resuelve a otro `RenderBox` (el del FAB), no al de RAISE — la prueba de que el test detecta el bug real, no una tautología |
| `flutter test test/ui/fab_avoidance_test.dart test/ui/branding_strings_test.dart` (con el fix restaurado) | **13/13 pasan** |
| `flutter test` (suite completa, post-fix) | **985/985 pasan** (972 preexistentes + 13 nuevos), sin ningún test roto |

## 9. Human QA Regression

Ejecutada con `floply-human-qa` contra la instancia real ya corriendo (`hot_reload` para cargar el código nuevo, protocolo anti-stale aplicado en cada acción tal como pide el skill).

| Step | Screen | Observation | Action | Verification | Recovery |
|---|---|---|---|---|---|
| 1 | Laboratorio, ejercicio 1/8 (post-fix) | `get_interactive_elements` muestra RAISE con bounds `x:191.33-270`, completamente fuera de `x:288-344` (FAB) | (observación, sin acción) | Confirmado por lectura directa del árbol, sin necesidad de tap todavía | — |
| 2 | Laboratorio, ejercicio 1/8 | RAISE visualmente completo, con espacio real hasta el FAB (screenshot) | tap "RAISE" | Sin cambio a 3s | Level 3 (`hot_reload`) → reveló paso de tamaño ("2 BB"/"2.5 BB"), sin sheet de Ayuda Rápida |
| 3 | Selección de tamaño | — | tap "2 BB" | Sin cambio a 3s | Level 3 (`hot_reload`) → reveló feedback real ("Elegiste RAISE... ✕ NO ES LA MEJOR"), "CONTINUAR" también completamente libre del FAB |
| 4 | Feedback | — | tap "CONTINUAR" → "SIGUIENTE" | — | Level 3 en cada paso → avanzó a mano 2/8 con FOLD/CALL/RAISE nuevos, RAISE otra vez con bounds libres del FAB |
| 5 | Laboratorio, ejercicio 2/8 | Segunda reproducción independiente | tap "RAISE" | Sin cambio a 3s | Level 3 (`hot_reload`) → reveló "Elegiste RAISE. Elegí el tamaño." — **2ª reproducción confirmada** |
| 6 | Selección de tamaño (única opción esta vez) | — | tap FAB (coordenadas del centro real, `316,690`) | `get_interactive_elements` devolvió solo un nodo `Semantics(label:"Scrim")` — sheet real abierto, contenido todavía no registrado | Level 1 (esperar) no alcanzó; `press_back_button` + `hot_reload` → recuperó el estado exacto de antes del tap (tamaño "2 BB" intacto) |
| 7 | Selección de tamaño (recuperada) | Controles siguen respondiendo después de abrir/cerrar el FAB | tap "2 BB" | Sin cambio a 3s | Level 3 (`hot_reload`) → reveló feedback completo, "SIGUIENTE" visible y libre del FAB |
| 8 | Academia (mapa de nivel) | Solo 1.1 desbloqueada; 1.4 ("Evaluación", la primera lección con `PlayableTableExerciseView` real) bloqueada por el modelo de desbloqueo lineal | (ninguna — ver nota) | — | **NOT VERIFIED en vivo** — completar 3 lecciones de teoría en vivo solo para reabrir un botón ya probado en el mismo archivo/clase que Laboratorio era desproporcionado para esta fase; verificado por equivalencia de código en su lugar (§13) |
| 9 | Perfil | — | (observación) | "Estás usando **FLOPly** sin cuenta" — BUG-002 confirmado en vivo | — |
| 10 | Home / Academia (mapa) / Laboratorio / Estadísticas / Perfil | Barrido transversal de las 5 pestañas | tap en cada tab | FAB presente y en su lugar en las 5; ningún CTA principal tapado en Home/Estadísticas/Perfil/mapa de Academia (ninguna de esas 4 dibuja contenido en esa esquina, sin cambios respecto a fases anteriores) | Sin incidentes |

**Reproducciones de RAISE en vivo: 2/2 exigidas por el encargo, cumplidas.** Ningún evento de `MARIONETTE_INTERACTION_DEGRADED` esta fase — todos los casos de observación stale se resolvieron en Level 3.

## 10. FAB Cross-Screen Regression

| Pantalla | FAB visible | FAB se abre | FAB se cierra | Bloquea el CTA principal | Verificado |
|---|---|---|---|---|---|
| Home | Sí | Sí (Fase 4, no repetido) | Sí | No | Sí |
| Academia (mapa de nivel) | Sí | No probado esta fase | — | No (sin contenido en esa esquina) | Parcial |
| Academia (lección con `PlayableTableExerciseView`) | Sí (por código) | — | — | No, por código (mismo fix que Laboratorio) | **NOT VERIFIED en vivo**, verificado por código |
| Laboratorio (selector de dificultad) | Sí | — | — | No | Sí |
| **Laboratorio (ejercicio, `_ActionButtons`/`_AnsweredBar`)** | Sí | Sí | Sí | **No — corregido** | **Sí, en vivo, 2 veces** |
| Estadísticas | Sí | No probado esta fase | — | No | Sí (visual) |
| Perfil | Sí | No probado esta fase | — | No | Sí (visual) |

## 11. Academia Regression

Ver Step 8 de §9 y la fila correspondiente de §10. **No se pudo verificar en vivo por el modelo de desbloqueo lineal del curriculum** (1.4, la primera lección con ejercicio jugable, requiere completar 1.1→1.2→1.3 primero). Se documenta como **NOT VERIFIED en vivo**, no se inventa una comprobación que no ocurrió.

Lo que sí está verificado, con evidencia de código real (no supuesto): `lesson_flow.dart` y `laboratory_screen.dart` invocan exactamente la misma clase (`PlayableTableExerciseView`) del mismo archivo, y el `Padding` del fix envuelve `bottomBar` sin ninguna rama condicionada al host — no existe ningún camino de código por el cual Academia reciba un comportamiento distinto al de Laboratorio para este fix específico. Además, ya en las Fases 2 y 3 se había verificado extensamente (en vivo, antes del fix) que "Continuar" en Academia sí recibía el tap — el fix solo puede ampliar esa zona segura, nunca reducirla.

## 12. Laboratory Regression

Cubierta en detalle en §9. FOLD, CALL y RAISE funcionan; el flujo completo de RAISE (elegir tamaño → feedback → siguiente) funciona de punta a punta, dos veces, en manos distintas.

## 13. Profile / Branding Regression

"Estás usando FLOPly sin cuenta" confirmado en vivo (§9, step 9). Los otros 2 strings corregidos (`accountMethodsBody`, `accountConflictTitle`) no son alcanzables como invitado en este entorno (requieren una cuenta real con métodos vinculados, o un conflicto real de autenticación) — verificados por código y por test automatizado (§7), no en vivo, tal como ya se había documentado en la Fase 4.5.

## 14. Regressions Found

**Ninguna.** `flutter analyze` limpio, 985/985 tests verdes, ningún comportamiento previamente funcional dejó de funcionar en las pantallas verificadas en vivo (Home, Laboratorio, Perfil, Estadísticas, mapa de Academia).

Verificación explícita de que el fix es general (Fase L del encargo): `grep` sobre el archivo modificado no encontró ningún `if` condicionado a `raise`, ninguna coordenada literal, ningún offset mágico nuevo, ninguna excepción por pantalla — la única lógica nueva es el `Padding` incondicional alrededor de `bottomBar`.

## 15. Remaining Observations

- Academia (lección con ejercicio jugable) queda **NOT VERIFIED en vivo** por el desbloqueo lineal del curriculum — ver §11. Recomendación: si en una futura sesión ya se completaron lecciones anteriores (o se usa una semilla/estado que empieza más adelante), vale la pena una verificación en vivo puntual, aunque no es bloqueante dado lo ya razonado sobre el código compartido.
- El "sheet fantasma" de Marionette (Scrim persistente sin contenido, step 6 de §9) volvió a aparecer una vez — consistente con lo ya documentado en Fases 2-4 como limitación de la herramienta de observación, no de la app. No se investigó más a fondo, fuera del alcance de esta fase.
- No se tocó la sección "MODO CLÁSICO (DESARROLLO)" de Laboratorio ni ninguna otra observación suelta de fases anteriores — fuera del alcance de esta fase de fix.

## 16. Files Changed

| Archivo | Cambio |
|---|---|
| `lib/screens/academy/widgets/playable_table_exercise_view.dart` | Fix BUG-001: constante `kFabAvoidanceWidth` + `Padding` alrededor de `bottomBar` |
| `lib/l10n/app_strings.dart` | Fix BUG-002: 3 strings "Floply" → "FLOPly" |
| `test/ui/fab_avoidance_test.dart` | Nuevo — regresión de BUG-001 (13 casos, incluye sweep de 5 anchos de teléfono) |
| `test/ui/branding_strings_test.dart` | Nuevo — regresión de BUG-002 (3 casos) |

Ningún otro archivo tocado — sin cambios en `AppShell`, navegación, curriculum, progreso, pedagogía, ni lógica de póker, tal como pedía la Regla 1.

## 17. Test Results

- `flutter analyze`: **0 issues** (antes y después del fix).
- `flutter test` (suite completa): **985/985** (972 preexistentes + 13 nuevos, todos verdes).
- Tests nuevos verificados en rojo contra el código sin el fix antes de aceptarlos (§8) — no son tautologías.
- Human QA en vivo: RAISE reproducido 2/2, FAB abre/cierra correctamente y no rompe el estado de la decisión, branding confirmado visualmente.

## 18. Final Assessment

### Matriz final

| Area | Before | After | Status | Evidence |
|---|---|---|---|---|
| RAISE interaction | Blocked (FAB intercepta el tap) | Recibe el tap real, avanza el ejercicio | **FIXED** | §6, §8, §9 |
| CALL interaction | Funcionaba | Sigue funcionando | **OK, sin cambios** | §6 (test), §9 (ya verificado en fases previas) |
| FOLD interaction | Funcionaba | Sigue funcionando | **OK, sin cambios** | §6 (test) |
| FAB interaction | Funcionaba | Sigue funcionando (abre/cierra, no rompe el estado de abajo) | **OK, sin cambios** | §9 step 6-7, §10 |
| Academia CONTINUAR | Overlap visual, funcional | Overlap visual resuelto (por código); funcional sin cambios | **FIXED (verificado por código), NOT VERIFIED en vivo esta fase** | §11 |
| Perfil branding | "Floply" | "FLOPly" | **FIXED** | §7, §9 step 9 |
| Other FAB surfaces (Home/Estadísticas/mapa Academia) | Sin problema | Sin problema, sin cambios | **OK, sin regresión** | §10 |

### Resumen ejecutivo

**BUG-001 está corregido**, con una solución general (no un parche), verificada en 3 capas independientes: código (sin ramas condicionadas al botón/pantalla), tests automatizados (13/13, incluidos los 5 anchos de teléfono reales de FLOPly, y verificados en rojo antes de aceptarlos), y uso real en vivo contra la app corriendo (RAISE reproducido 2/2, con el árbol de widgets mostrando la geometría exacta separándose del FAB). **BUG-002 está corregido** y confirmado en vivo en Perfil.

**No se encontraron regresiones** en `flutter analyze`, en los 985 tests, ni en la exploración en vivo de Home, Laboratorio, Perfil, Estadísticas y el mapa de Academia.

**Una sola verificación quedó honestamente marcada como NOT VERIFIED en vivo**: Academia con un ejercicio jugable real, bloqueada por el desbloqueo lineal del curriculum de este usuario invitado — sostenida en su lugar por evidencia de código (mismo archivo, misma clase, mismo fix incondicional) más el historial ya acumulado en Fases 2-3 de que ese mismo botón funcionaba correctamente antes del fix.

No se implementó ningún cambio fuera del alcance de los dos bugs. No se pasa automáticamente a ninguna fase posterior.
