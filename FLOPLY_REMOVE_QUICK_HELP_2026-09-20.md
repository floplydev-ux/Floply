# FLOPly — Eliminación completa de "Ayuda rápida"

**Fecha:** 2026-09-20. Decisión de producto: FLOPly ya no tiene el botón flotante "Ayuda rápida" (Table Mode). No se reemplazó por otro FAB ni se diseñó una solución alternativa para conservarlo — se eliminó por completo, siguiendo el encargo `FLOPLY_REMOVE_QUICK_HELP` y descartando explícitamente la Fase 6.5 de diseño para preservarlo que las auditorías anteriores habían dejado sugerida.

## 1. Resumen

Se eliminó el `FloatingActionButton` persistente que vivía en `AppShell` (visible en las 5 pestañas) y toda su funcionalidad asociada: el bottom sheet "Table Mode" que abría (6 accesos directos a las calculadoras de Tools), sus 3 strings exclusivas, y el padding de reserva de espacio (`kFabAvoidanceWidth`) que un fix anterior (Fase 5, BUG-001) había agregado en Academia/Laboratorio para esquivarlo.

Ninguna de las 6 herramientas que el FAB abría se perdió: las 6 (Pot Odds, Equity, EV, Combos, Rangos, Blockers) ya eran accesibles — y lo siguen siendo — desde `ToolsScreen`, alcanzable desde la card "TOOLS" de Home.

## 2. Implementación anterior

- El FAB se creaba una única vez en `lib/screens/root/app_shell.dart` (`Scaffold.floatingActionButton`), compartido a propósito por las 5 pestañas (Home, Academia, Laboratorio, Estadísticas, Perfil) vía `IndexedStack`.
- `onPressed` llamaba a `showTableModeSheet` (`lib/screens/tools/table_mode_sheet.dart`), un modal bottom sheet con 6 `_QuickTile` que empujaban exactamente las mismas pantallas que ya abre `ToolsScreen` — sin cálculo ni pantalla nueva, confirmado leyendo ambos archivos antes de tocar nada.
- Un fix anterior (Fase 5, BUG-001: el FAB interceptaba el tap de RAISE en Laboratorio) había agregado `kFabAvoidanceWidth` en `playable_table_exercise_view.dart` — un padding derecho reservado exclusivamente para no quedar debajo del FAB, documentado como tal en su propio comentario.
- Fase 6 había detectado dos hallazgos adicionales del mismo FAB (ACADEMIA-001/002: overlap visual sobre "CONTINUAR" y sobre una opción de comprehension-check en `lesson_flow.dart`) y sugería extender el mismo fix ahí. Esa extensión ya no hace falta: al eliminar el FAB, ambos hallazgos quedan resueltos de raíz, sin tocar `lesson_flow.dart` (que nunca tuvo código específico de FAB-avoidance).

## 3. Archivos modificados

- `lib/screens/root/app_shell.dart` — se quitó `floatingActionButton: FloatingActionButton(...)` del `Scaffold`, el comentario de clase que lo describía, y los imports que quedaron sin uso (`app_strings.dart`, `app_colors.dart`, `table_mode_sheet.dart`).
- `lib/l10n/app_strings.dart` — se quitaron las 3 strings exclusivas de Table Mode (`tableModeFabTooltip`, `tableModeTitle`, `tableModeSubtitle`). Las strings de las 6 herramientas (`toolsPotOddsTitle`, `toolsEquityTitle`, etc.) se conservaron intactas: las sigue usando `ToolsScreen`.
- `lib/screens/academy/widgets/playable_table_exercise_view.dart` — se quitó la constante `kFabAvoidanceWidth` y el `Padding` que envolvía la fila de acciones (`bottomBar`) exclusivamente para reservarle espacio al FAB; la fila vuelve a ocupar el ancho completo.
- `test/ui/app_shell_test.dart` — reescrito: los 2 tests que antes verificaban que el FAB abría Table Mode ahora verifican que no existe ningún `FloatingActionButton`, en Home y al cambiar a Academia.
- `test/ui/fab_avoidance_test.dart` — reescrito: se mantienen las verificaciones funcionales de FOLD/CALL/RAISE (incluido el sweep de anchos de teléfono) porque siguen siendo una regresión real y válida, pero el contrato cambió de "el FAB no intercepta el tap" a "no existe ningún FAB" — se agregaron aserciones explícitas de ausencia y se quitaron los 2 tests que abrían el FAB a propósito (ya no aplican).
- `integration_test/flows/tools_flow_test.dart` — el flujo E2E que navegaba Home → FAB → Pot Odds ahora navega Home → card "TOOLS" → Pot Odds, usando el acceso real que ya existía en `home_screen.dart` (`_openTools`, `AppStrings.toolsTitle`).

## 4. Archivos eliminados

- `lib/screens/tools/table_mode_sheet.dart` — sin consumidores tras quitar el FAB; sus 6 tiles eran duplicados exactos de lo que ya ofrece `ToolsScreen`.
- `test/ui/table_mode_sheet_test.dart` — probaba exclusivamente el archivo anterior.

## 5. Tests actualizados

- `test/ui/app_shell_test.dart` (reescrito, ver §3).
- `test/ui/fab_avoidance_test.dart` (reescrito, ver §3).
- `test/ui/table_mode_sheet_test.dart` (eliminado, ver §4).
- `integration_test/flows/tools_flow_test.dart` (actualizado, ver §3).

No se tocó ningún otro test — en particular, `test/ui/tools_screen_test.dart` (las 6 herramientas dentro de `ToolsScreen`) se dejó intacto porque nunca dependió del FAB.

## 6. Verificación de referencias

Búsqueda exhaustiva antes y después del cambio (`Ayuda rápida`, `Quick Help`, `quickHelp`, `quick_help`, `tableModeFabTooltip`, `tableModeTitle`, `tableModeSubtitle`, `showTableModeSheet`, `TableModeSheet`, `kFabAvoidanceWidth`, `floatingActionButton`, `FloatingActionButton`):

- En `lib/`: **0 referencias** tras el cambio (antes: `app_shell.dart`, `app_strings.dart`, `playable_table_exercise_view.dart`, `tools/table_mode_sheet.dart`).
- En `test/`/`integration_test/`: solo quedan menciones documentales en comentarios/nombres de grupo de `app_shell_test.dart` y `fab_avoidance_test.dart` que explican el contrato nuevo ("Ayuda rápida eliminada") — no código muerto.
- Documentación histórica (`FLOPLY_HUMAN_QA_PHASE*.md`, `FLOPLY_PHASE5_FIX_REGRESSION_2026-09-19.md`, `MARIONETTE_POC_2026-09-19.md`, `AUDITORIA_CHECKLIST_2026-09-18.md`, `docs/design/...`) **no se modificó**: son reportes fechados que documentan el estado del producto en ese momento (incluida la existencia del FAB), no documentación activa que describa el producto actual. Reescribirlos retroactivamente falsearía el historial.

## 7. Human QA (Marionette, instancia real en Chrome, puerto 8767)

Se corrió la app modificada en modo debug real y se navegó como usuario, con el protocolo anti-stale ya documentado en fases anteriores (la observación de Marionette puede quedar un frame atrás; se usó `hot_reload` + relectura cuando hizo falta, nunca se declaró un bug sin confirmar con `get_interactive_elements`).

| Pantalla | Resultado |
|---|---|
| Home | Sin FAB (confirmado por árbol de widgets y visualmente). Cards PRACTICE ROOM / BANKROLL / TOOLS / COACH intactas. |
| Academia — mapa de nivel | Sin FAB. |
| Academia — lección 1.1, mesa (`PlayableTableExerciseView`-like, pasos 1-8) | Sin FAB. "CONTINUAR" se lee completo (antes se veía recortado "CONTINUA" por el FAB — **ACADEMIA-001 resuelto**). |
| Academia — sub-sección "OBJETIVO DEL JUEGO", comprehension check (paso 4/5) | Sin FAB. Ambas opciones de respuesta se leen completas, incluida "Para ganar esta mano en particular, siempre" (antes se cortaba a "sie...") — **ACADEMIA-002 resuelto**. Se probó la respuesta incorrecta: feedback completo y correcto, sin overlap. |
| Laboratorio — selector de nivel | Sin FAB. |
| Laboratorio — FÁCIL | Sin FAB. RAISE tocado de punta a punta: eligió tamaño (2 BB), avanzó a la devolución completa ("≈ TAMBIÉN VÁLIDO", con conceptos). |
| Laboratorio — EXPERTO | Sin FAB. Family c-bet: BET tocado, eligió tamaño (1 BB), devolución "✓ CORRECTO" con concepto (Continuation bet, Textura de board). |
| Perfil | Sin FAB. Branding "FLOPly" correcto (regresión de BUG-002 sigue en verde). |
| Estadísticas | Sin FAB. |
| Tools (vía card de Home, no vía FAB) | Hub completo: POT ODDS, EQUITY, EV, COMBOS, RANGOS, BLOCKERS, los 6 accesibles. |
| Blocker Explorer | Abierto desde Tools, cálculo real (AhKd vs QQ+,AKs,AKo → 13/34 bloqueados, detalle por clase). |
| Combo Calculator | Abierto desde Tools, cálculo real (AKs → 4 combos, 0 bloqueados, 4 combos físicos listados). |

No se encontró ningún rastro visual, funcional ni en el árbol de widgets del FAB o de "Ayuda rápida" en ninguna pantalla explorada.

## 8. Regresión

- **Laboratorio RAISE**: funciona igual que antes (FÁCIL y EXPERTO probados en vivo), y ahora sin ningún elemento superpuesto porque no hay FAB que esquivar.
- **Academia CONTINUAR**: funciona igual, y el clipping visual que tenía (ACADEMIA-001) desapareció como efecto colateral de la eliminación.
- **Academia comprehension checks**: funcionan igual (se probó una rama incorrecta con feedback completo), y el texto de las opciones ya no queda parcialmente oculto (ACADEMIA-002).
- **Tools**: sigue 100% accesible y funcional, sin ninguna herramienta perdida ni duplicada — el único cambio es que ya no hay un segundo camino (el FAB) para llegar a ellas, solo el que ya existía desde Home.

## 9. Resultado final

```
flutter analyze: PASS (0 issues)
flutter test --concurrency=1: PASS (1211/1211)
Marionette QA: PASS (Home, Academia, Laboratorio, Perfil, Estadísticas, Tools — sin FAB en ninguna, todo funcional)
Quick Help references: 0 en lib/, 0 código muerto en test/ (solo menciones documentales del contrato nuevo)
```

(1211 = 1219 de la Fase 6 menos los 8 tests de `table_mode_sheet_test.dart`, eliminado junto con el archivo que probaba.)

## 9.1 Diff review (git)

El repo tenía un árbol de trabajo grande ya sucio antes de empezar esta tarea (trabajo de ingeniería de sesiones previas, nunca commiteado — documentado también en `FLOPLY_HUMAN_QA_PHASE6_2026-09-20.md` §3). Por eso `git diff --stat` de `app_shell.dart`/`app_strings.dart` contra `HEAD` muestra cientos de líneas que **no** son de esta tarea (auth, `AcademyStore`, `StatsScreen`, etc., ya presentes cuando se leyó el archivo por primera vez).

Verificación puntual: se confirmó con `git show HEAD:...` que el FAB, `table_mode_sheet.dart` y las 3 strings de Table Mode **no existían en el último commit** — todo el feature del FAB era, también, trabajo sin commitear de esta misma sesión de trabajo (no algo introducido antes por otra persona). El resultado de esta tarea deja `app_shell.dart` con el mismo `Scaffold` (sin FAB) que ya tenía `HEAD`, y no toca ninguna línea de las demás features sin commitear. Diff revisado manualmente: sin cambios ajenos a la eliminación de Ayuda rápida.

## 10. Scope check

No se modificó: curriculum, teorías, ejercicios, navegación (las 5 pestañas y sus rutas siguen igual), progreso, unlocks, persistencia, motor de póker/estrategia, cuentas, monetización, ni el diseño/contenido de ninguna pantalla más allá de quitar el FAB y el padding que existía únicamente por su causa. `lesson_flow.dart` (Academia) no se tocó: nunca tuvo código de FAB-avoidance, y su overlap (ACADEMIA-001/002) se resolvió solo por la desaparición del FAB, sin necesidad de tocarlo.

No se pasa a ninguna fase posterior automáticamente.
