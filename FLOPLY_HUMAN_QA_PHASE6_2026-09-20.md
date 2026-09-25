# FLOPly Human QA — Phase 6 (Academia + Laboratorio, auditoría profunda)

**Fecha:** 2026-09-20. Continuación de Fase 2 (PoC Marionette), Fase 3 (exploración autónoma inicial), Fase 4 (Human QA autónomo), Fase 4.5 (auditoría dirigida) y Fase 5 (FIX + TEST + regresión en vivo de BUG-001/BUG-002). Esta fase amplía la cobertura a Academia (varias teorías + comprensión + ejercicio) y Laboratorio (FÁCIL/MEDIO/EXPERTO, FOLD/CALL/RAISE, regresión de BUG-001) con el mismo protocolo anti-stale. **No se modificó ningún archivo de FLOPly.**

## 1. Executive Summary

- **Duración aproximada:** ~2 horas de interacción real contra la app corriendo (compilación inicial + exploración).
- **Pantallas exploradas:** Auth (guest), Home, Academia (lección 1.1 completa hasta el inicio de su 3ª sub-sección, con comprensión check correcta e incorrecta), Laboratorio (FÁCIL, MEDIO, EXPERTO — CUSTOM solo observado, no jugado), Perfil.
- **Acciones realizadas:** ~40 acciones reales verificadas (taps por texto/coordenadas, hot_reload de recuperación, una sesión completa de exercise-flow en 3 dificultades de Laboratorio, un comprehension-check con ambas ramas).
- **Findings:** 2 UI_ISSUE confirmados (visual, no bloqueantes), 1 evento de observación obsoleta (resuelto, no es bug), 0 CONFIRMED_BUG nuevos, 0 eventos de degradación de Marionette.
- **Por categoría:** UI_ISSUE: 2. STALE OBSERVATION (resuelto): 1. PEDAGOGICAL (observación, no bug): 1. NAVIGATION: 0 problemas (todo lo probado funcionó). ACCESSIBILITY: sin hallazgos nuevos (cobertura limitada esta fase, ver §7).
- **Regresión de Fase 5:** **BUG-001 y BUG-002 confirmados corregidos en vivo**, reproducidos varias veces contra la instancia real (ver §9).
- **No reproducible / tooling:** 0 esta fase.

## 2. Environment

- `flutter run -d chrome --web-port=8766` (modo debug real, instancia nueva lanzada para esta fase — la de la Fase 5 en el puerto 8765 seguía viva pero sin log accesible para extraer su URI de VM service, así que se levantó una segunda instancia limpia en 8766, capturando el log completo esta vez).
- VM service: `ws://127.0.0.1:55947/-4Y6yQvpYac=/ws`.
- Conexión Marionette establecida sin reintentos tras esperar a que la app terminara de compilar en DDC (el primer intento de `connect` falló porque el isolate todavía no había registrado la extensión — esperar y reintentar lo resolvió, no fue necesario relanzar nada).
- Viewport: 360×800 (default de Chrome debug de `flutter run`, consistente con todas las fases anteriores).

## 3. Baseline

- `flutter analyze` (antes de empezar y al finalizar) → **0 issues**.
- `flutter test --concurrency=1` (al finalizar) → **1219/1219 tests pasaron**. La suite creció significativamente respecto de los 985 de la Fase 5 — refleja trabajo de ingeniería sustancial hecho en sesiones/fases intermedias no cubiertas por los reportes de QA leídos (motor preflop nuevo completo, cbet postflop, motor matemático de equity/pot-odds/EV, sistema de diseño "Sala Verde"). No se re-corrió al inicio por duración (varios minutos); se corrió una vez al final, que es el momento que importa para certificar que esta fase no rompió nada.
- Árbol de trabajo: `git status` muestra 246 archivos con cambios sin commitear. **Esto es estado preexistente de fases de ingeniería anteriores en esta misma sesión de trabajo, no algo producido por esta Fase 6** — esta fase no ejecutó un solo `Write`/`Edit` de código; solo lectura, Marionette, y comandos de verificación (`flutter analyze`/`flutter test`). Se documenta con honestidad en vez de afirmar un árbol limpio que no es real.

## 4. Academia

### Timeline real

| Paso | Pantalla | Acción | Resultado verificado |
|---|---|---|---|
| 1 | Home (guest, "Hola, Juan") | tap "COMENZAR ACADEMIA" | Stale 1 lectura → `hot_reload` → Lección 1.1 "El objetivo y las cartas", PASO 1/8, mesa real |
| 2-8 | Lección 1.1, mesa (PASO 1→8) | 7× tap "CONTINUAR" | Cada paso avanzó correctamente: bote, apuesta con fichas reales, flop (Ks 7h 2d), turn (Qs), showdown ("tu trío de reyes gana el bote") — arco narrativo completo, coherente, sin saltos |
| 9-13 | Lección 1.1, sub-sección "OBJETIVO DEL JUEGO" (5 pasos) | 5× tap "CONTINUAR"/tocar una respuesta | Incluye un **comprehension check real**: "¿Para qué jugás cada mano?" con 2 opciones. Se probó la opción incorrecta ("para ganar esta mano en particular") → feedback ✕ con explicación de por qué es el error típico de un principiante, más una frase-puente ("ganás fichas ganando botes... no hace falta ganar todas las manos") |
| 14 | Lección 1.1, sub-sección "LA BARAJA" (paso 1/5) | (solo observación) | Nueva sub-sección; no se completó por prioridad de tiempo (se priorizó Laboratorio) |
| 15 | — | tap flecha "volver" | Sin cambio a 3s → `hot_reload` → misma pantalla (aún en paso 1 de "LA BARAJA" — comportamiento esperado, "volver" en un paso 1 de sub-sección no navega fuera todavía) |
| 16 | Lección 1.1 | tap "LABORATORIO" (bottom nav) | Navegó directo a Laboratorio sin pasar por el mapa de nivel — confirma que el bottom nav es una salida directa válida desde cualquier punto de una lección |

### Findings

**ACADEMIA-001 — UI_ISSUE, MEDIUM, CONFIRMED**
- **Pantalla:** Lección 1.1, tanto en los pasos de mesa (`TableLesson`) como en los de teoría escrita (`WrittenTheoryView`/similar) — el botón "CONTINUAR" (y "ATRÁS" cuando aparece) de `lesson_flow.dart`.
- **Pasos:** Cualquier paso de una lección con el FAB "Ayuda rápida" visible en la esquina inferior derecha.
- **Esperado:** El texto "CONTINUAR" se lee completo, sin superposición.
- **Observado:** El botón se extiende hasta `x≈342`, y el FAB ocupa `x:288-344` a la misma altura — su borde derecho visual queda parcialmente tapado por el FAB (visible como "CONTINUA" en vez de "CONTINUAR" en varios screenshots). El **centro** del texto del botón siempre queda a la izquierda del FAB, así que la interacción no se bloqueó en ningún intento (confirmado con 9 taps reales exitosos).
- **Por qué esto es un finding nuevo y no una repetición de BUG-001:** el fix de la Fase 5 (`kFabAvoidanceWidth`) se aplicó específicamente a `PlayableTableExerciseView` (el widget de FOLD/CALL/RAISE), **no** a `lesson_flow.dart`, que es un componente distinto para los pasos narrados de teoría. El mismo patrón de causa raíz (el FAB no reserva espacio, ninguna pantalla lo consulta) persiste acá, sin corregir, en un componente hermano que la Fase 5 no tocó porque no era su alcance.
- **Evidencia:** Screenshots de los pasos 4-8 de la mesa y de los 5 pasos de "OBJETIVO DEL JUEGO" muestran el clipping de forma consistente; `get_interactive_elements` confirma los bounds del botón (`x:175-342` o similar según el ancho del texto) solapando el FAB (`x:288-344`).
- **Severidad:** MEDIUM, no HIGH — a diferencia de BUG-001 original, acá la interacción **sí funciona** en todos los intentos reales (el centro del botón nunca cae bajo el FAB). Es un problema visual con riesgo residual, no un bloqueo funcional confirmado.

**ACADEMIA-002 — UI_ISSUE, MEDIUM, CONFIRMED**
- **Pantalla:** Lección 1.1, sub-sección "OBJETIVO DEL JUEGO", paso 4/5 (el comprehension check "¿Para qué jugás cada mano?").
- **Observado:** La segunda opción de respuesta ("Para ganar esta mano en particular, siempre...") tiene su `GestureDetector` en `x:18-342`, con su **texto** llegando hasta `x≈317` — es decir, una porción real del texto de la respuesta (no solo el margen del botón) queda geométricamente bajo el FAB (`x:288-344`). Visualmente la palabra final ("siempre") se corta a "sie" en el screenshot.
- **Por qué importa más que ACADEMIA-001:** acá no es un botón de "continuar", es el texto de una **opción de respuesta real** en un ejercicio de comprensión — un alumno que no puede leer la opción completa está en desventaja real para responder con criterio, no solo estética.
- **Verificado funcionalmente:** el tap (por texto, que targeteó el texto legible) sí registró la opción correcta y mostró el feedback correspondiente — no hubo bloqueo en este intento puntual, pero el texto SÍ está parcialmente oculto detrás del FAB en la porción final.
- **Evidencia:** screenshot + `get_interactive_elements` (texto completo "Para ganar esta mano en particular, siempre" vs. lo visible en pantalla).
- **Severidad:** MEDIUM — mismo mecanismo de causa raíz que ACADEMIA-001, pero sobre contenido semánticamente más importante (una opción de respuesta, no un botón de navegación).

### Positivo

- El arco de la lección 1.1 (mesa: bote → apuesta → flop → turn → river/showdown, todo con la MISMA mano concreta del alumno) es exactamente el patrón "mentor → situación → observación" que pedía el encargo, no "libro → definición". El texto habla en primera persona al alumno ("quiero que veas algo", "decime: ¿para qué jugás cada mano?").
- El feedback del comprehension check no se limita a "incorrecto": explica el error conceptual específico y lo conecta con el principio que sostiene el resto del curso.
- La navegación por bottom-nav desde dentro de una lección funciona sin fricción ni estados raros.

## 5. Laboratorio

### Timeline real

| Paso | Modalidad | Mano / decisión | Resultado |
|---|---|---|---|
| 1 | FÁCIL | RFI, RAISE 2BB | **RAISE llevó a selección de tamaño, no al FAB** — BUG-001 no reproduce |
| 2 | FÁCIL | RFI, K3o, FOLD | "✓ BUENA ELECCIÓN" |
| 3 | FÁCIL | RFI, 52o, CALL | "✕ NO ES LA MEJOR" |
| 4 | FÁCIL | (salida de sesión) | tap "✕" cerrar → volvió limpio al selector de nivel, sin arrastrar estado |
| 5 | MEDIO | RFI, RAISE 2.5BB | Feedback correcto; **evento de observación obsoleta** al pasar a la mano 2 (ver LAB-STALE-001) |
| 6 | MEDIO | Facing open (BB), FOLD | "✕ NO ES LA MEJOR" — feedback correcto tras resolverse el evento de stale |
| 7 | EXPERTO | Facing 3-bet (CO con T7s), RAISE 12.5BB (4-bet) | "✕ NO ES LA MEJOR" — **feedback específico y consciente de rango**: *"Pagar acá no tiene sustento: tu mano queda afuera de lo que puede seguir del rango de 3-bet del rival. Repasá: Call, 3-bet."* |

### BUG-001 — Regresión

**CONFIRMADO CORREGIDO**, reproducido 2 veces en esta fase (FÁCIL y EXPERTO), en manos distintas, con `get_interactive_elements` mostrando el bounds real de RAISE completamente afuera del FAB en ambos casos, y el tap llevando siempre al flujo correcto (selección de tamaño → feedback), nunca a "Ayuda rápida". Sumado a las 2 reproducciones de la Fase 5, son **4/4 verificaciones en vivo exitosas** del fix a través de dos fases distintas.

### LAB-STALE-001 — Stale Observation (resuelto, no es bug)

- Al pasar de la mano 1 a la mano 2 en MEDIO (tap "SIGUIENTE" tras la explicación de la mano 1), la mesa mostró correctamente la mano nueva (posiciones rotadas, bote reiniciado) pero **tanto el screenshot como una primera lectura de `get_interactive_elements` siguieron mostrando el texto de feedback de la mano anterior** ("Elegiste RAISE (2.5 BB)...") superpuesto al banner de la mano nueva.
- **Nivel de escalada:** esto sobrevivió a un primer `hot_reload` (Level 3) — algo no visto en esta forma en fases anteriores, donde normalmente un solo `hot_reload` resincroniza `get_interactive_elements` aunque el screenshot tarde más. Acá ambos mecanismos coincidieron en mostrar contenido viejo al mismo tiempo, brevemente.
- **Verificación funcional durante el evento:** se tocó "FOLD" igual, sin esperar más — la acción **sí se registró correctamente** (aparecio el check y "SIGUIENTE"), lo que ya sugería que el estado real de la app estaba bien y solo la observación estaba atrasada.
- **Resolución:** una segunda lectura de `get_interactive_elements` (sin acción adicional de por medio) mostró el contenido 100% correcto y coherente con la mano 2 ("Conceptos en juego acá: Call, Defensa de BB, 3-bet, 3-bet por valor" — exactamente lo esperable para una decisión de defensa de BB). El siguiente screenshot confirmó lo mismo visualmente.
- **Clasificación: STALE OBSERVATION, resuelta en un Level 3 extendido (dos lecturas en vez de una).** No se declara `CONFIRMED_BUG` porque el estado real de la app (verificado por la acción funcionando y por la lectura posterior) siempre fue correcto — coherente con el patrón ya documentado en las Fases 2-4 de que la capa de *observación* de Marionette es la parte no confiable, nunca la app en sí.

### "Modo clásico" — ya no está presente

En las Fases 3-4 se había registrado como observación suelta que la pantalla de Laboratorio mostraba una sección "MODO CLÁSICO (DESARROLLO)" con botones de práctica visibles para un usuario invitado. **En esta fase, esa sección no aparece en ningún lado** de la pantalla de selección de nivel (confirmado tanto visualmente como en `get_interactive_elements`, que lista únicamamente FÁCIL/MEDIO/EXPERTO/CUSTOM + bottom nav + FAB, sin ningún rastro de "modo clásico"). Se registra como **mejora positiva** respecto de las fases anteriores, no como algo que esta fase haya verificado como "arreglado" activamente (no se buscó en el código, se documenta solo el comportamiento observado en vivo).

### CUSTOM

Solo se observó la tarjeta en el selector ("Elegí exactamente qué áreas practicar, en vez de un nivel fijo") — **no se interactuó con la configuración real de Custom** por prioridad de tiempo frente a la cobertura de FÁCIL/MEDIO/EXPERTO con las 3 acciones. Queda **NOT VERIFIED** para una fase futura.

## 6. Pedagogical Findings

- **Positivo, y significativo:** el feedback de la familia "facing 3-bet" (EXPERTO) ya es cualitativamente distinto del de la familia RFI (FÁCIL/MEDIO) — explica la decisión en términos de qué puede seguir del rango del rival ("tu mano queda afuera de lo que puede seguir del rango de 3-bet del rival"), no solo "no es una buena elección". Esto es consistente con trabajo de rediseño del motor preflop referenciado en memoria de proyecto, ya en producción.
- **Observación (no bug):** las decisiones de apertura (RFI, familia más simple de FÁCIL/MEDIO) siguen mostrando un banner binario en la UI — "✓ BUENA ELECCIÓN" / "✕ NO ES LA MEJOR" — sin una categoría visible de "aceptable" o "depende" en los casos probados esta fase (2 FOLD/CALL/RAISE en RFI, ambos resueltos como uno de los dos extremos). No se determinó si esto es porque las manos que tocaron esta sesión eran genuinamente claras (no hay ambigüedad real que mostrar) o porque esa familia todavía no expone gradación en su texto — **no se puede afirmar cuál de las dos es la causa con la muestra de esta fase**; se documenta la observación sin acusar un problema no verificado.
- El comprehension check de Academia (§4) es un buen ejemplo de feedback que explica el *concepto* detrás del error, no solo "correcto/incorrecto" — cumple lo que pedía el encargo sobre "profesor/mentor" vs. "libro".

## 7. Accessibility

Cobertura limitada esta fase (prioridad puesta en funcionalidad e interacción). No se hizo una inspección sistemática de `Semantics` en Laboratorio ni en los nuevos pasos de Academia explorados. No se encontró ningún problema evidente (target pequeño, información solo por color, etc.) en el uso normal, pero esto **no equivale a una auditoría de accesibilidad** — se marca como **NOT VERIFIED en profundidad**, consistente con lo ya señalado en fases anteriores para las pantallas no revisitadas.

## 8. Navigation / State

- Home → Academia (CTA) → lección → sub-secciones → bottom nav → Laboratorio: todo verificado, sin estados fantasma ni pérdida de datos.
- Salida de sesión de Laboratorio (botón "✕"): probado una vez, volvió limpio al selector sin arrastrar el progreso de la sesión abandonada (comportamiento esperado, ya que `exitSession()` no persiste nada a medio resolver).
- Cambio de dificultad (FÁCIL → MEDIO → EXPERTO): cada cambio arrancó una sesión nueva real (bote reiniciado, jugadores nuevos), sin mezclar estado de la sesión anterior.
- No se detectó ningún bottom sheet fantasma esta fase (el fenómeno ya documentado en Fases 2-4) — no se abrió el FAB en ningún momento de esta fase, así que no había oportunidad de que apareciera.

## 9. Phase 5 Regression

| Ítem | Resultado |
|---|---|
| FOLD funciona | ✅ Verificado (FÁCIL, MEDIO) |
| CALL funciona | ✅ Verificado (FÁCIL) |
| RAISE funciona | ✅ Verificado (FÁCIL, EXPERTO) — llega a selección de tamaño y feedback, nunca al FAB |
| RAISE no activa Ayuda Rápida | ✅ Confirmado 2/2 esta fase (4/4 acumulado con Fase 5) |
| FAB sigue funcionando | No se abrió deliberadamente esta fase (no hacía falta para el objetivo) — sin evidencia en contra, tampoco reverificado a propósito |
| FAB no bloquea controles (Laboratorio) | ✅ Confirmado con `get_interactive_elements` (bounds de RAISE siempre fuera del FAB) |
| Academia CONTINUAR sigue funcionando | ✅ Confirmado — con la salvedad de ACADEMIA-001 (overlap visual persistente en un componente que la Fase 5 no tocó) |
| Branding "FLOPly" (no "Floply") | ✅ Confirmado en vivo: login y Perfil, esta fase |

**Ninguna regresión encontrada respecto de la Fase 5.** Los dos fixes siguen corregidos. Lo nuevo de esta fase (ACADEMIA-001/002) es un problema **distinto**, en un componente **distinto** (`lesson_flow.dart`, no `PlayableTableExerciseView`), que nunca estuvo en el alcance de la Fase 5 — no es que el fix se haya roto, es que nunca cubrió esta otra superficie.

## 10. Positive Findings

- BUG-001 y BUG-002 siguen sólidamente corregidos, con evidencia en vivo fresca de esta fase.
- El feedback de "facing 3-bet" en EXPERTO ya razona sobre el rango del rival, no solo sobre la fuerza abstracta de la mano — evidencia en vivo de que el rediseño del motor preflop mencionado en el histórico del proyecto está realmente en producción y cambia la experiencia real, no solo el código.
- La lección 1.1 de Academia tiene una narrativa mentor-alumno genuina, con un comprehension check bien diseñado (explica el error, no solo lo señala).
- "MODO CLÁSICO (DESARROLLO)" ya no es visible para un usuario invitado — mejora real respecto de lo observado en Fases 3-4.
- Cero eventos de degradación de Marionette en toda la fase — la interacción fue confiable de punta a punta, con un solo evento de observación (no de interacción) que se resolvió sin necesitar `hot_restart`.

## 11. Finding Inventory

| ID | Área | Categoría | Severidad | Estado | Reproducible |
|---|---|---|---|---|---|
| ACADEMIA-001 | Academia (lesson_flow, CONTINUAR/ATRÁS) | UI_ISSUE | MEDIUM | CONFIRMED | Sí, en cada paso de la lección 1.1 revisado |
| ACADEMIA-002 | Academia (comprehension check, opción de respuesta) | UI_ISSUE | MEDIUM | CONFIRMED | Sí, en el paso 4/5 de "OBJETIVO DEL JUEGO" |
| LAB-STALE-001 | Laboratorio (transición entre manos, MEDIO) | UNCERTAIN → resuelto | INFO | NOT_REPRODUCIBLE como bug (resuelto en observación extendida) | Un evento; no reintentado a propósito para ver si repite |

## 12. Recommended Next Steps

*(No implementar — solo sugerencias para una fase posterior de fix/diseño.)*

- Extender el fix de la Fase 5 (`kFabAvoidanceWidth` o equivalente) a `lesson_flow.dart`, que hoy tiene el mismo problema geométrico que `PlayableTableExerciseView` tenía antes del fix — cubriría ACADEMIA-001 y ACADEMIA-002 con la misma solución ya validada, sin diseño nuevo.
- Priorizar ACADEMIA-002 sobre ACADEMIA-001 si solo se puede atender una: ahí el texto oculto es contenido evaluativo (una opción de respuesta), no solo un botón de navegación.
- Completar la exploración de CUSTOM (no cubierta esta fase) y de la lección 1.4 de Academia (el primer ejercicio jugable real, todavía bloqueado por el desbloqueo lineal en todas las fases hasta ahora — considerar una semilla de progreso para una futura fase de QA que empiece más adelante en el currículo).
- Si se retoma la exploración pedagógica, valdría la pena buscar deliberadamente un spot de RFI donde el motor sí deba mostrar una categoría intermedia (viable/frontera) en la UI, para confirmar si esa gradación ya llega al texto visible o si —como sugiere la auditoría teórica previa del proyecto— todavía es un trabajo pendiente específico de esa familia.
- Una pasada de accesibilidad dedicada (Semantics, contraste, tamaño de targets) sobre Laboratorio y los nuevos pasos de Academia no se hizo en profundidad esta fase.

---

**No se modificó código de FLOPly durante esta fase.** `flutter analyze` y `flutter test` (1219/1219) se corrieron al finalizar sin encontrar regresiones. No se comienza una Fase 7 automáticamente.
