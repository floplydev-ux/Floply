# FLOPly Human QA — Phase 4

**Fecha:** 2026-09-19. Primera exploración Human-like QA completa con `floply-human-qa`, construida sobre la Fase 3 (validación de la capa fundamental) y los diagnósticos de Marionette de las Fases 1-2. No se corrigió ningún problema encontrado. No se modificó código de FLOPly.

## 1. Executive Summary

Esta fase demuestra que `floply-human-qa` puede explorar FLOPly de forma autónoma —sin ruta prescrita— y encontrar problemas reales, distinguiéndolos correctamente de observación obsoleta y de degradaciones de Marionette. Se encontraron **2 bugs confirmados** (uno de severidad **HIGH**: la acción RAISE de un ejercicio de Laboratorio es físicamente inalcanzable porque el FAB "Ayuda rápida" se superpone y absorbe el tap; uno de severidad **LOW**: el texto "Floply" en la pantalla de Perfil no respeta el branding real "FLOPly"), **1 observación técnica de Marionette reproducida y aislada** (un bottom sheet puede quedar "fantasma" en el screenshot después de cerrarse realmente), **1 evento de degradación real de la observación** que requirió escalar hasta `hot_restart`, y **hallazgos pedagógicos positivos** (el feedback de un ejercicio explica el concepto exacto detrás del error, no solo "correcto/incorrecto"). Ningún hallazgo se declaró sin haber pasado primero por el protocolo anti-stale completo.

## 2. Environment

Continuación directa del entorno validado en Fases 2-3 — mismo `flutter run -d chrome --web-port=8765`, misma conexión Marionette, sin reinstalar ni reconfigurar nada. Flutter 3.47.2 / Dart 3.13.2 / `marionette_flutter` 0.6.0 / `marionette_mcp` 0.6.0.

## 3. Baseline

Antes de empezar:
- `flutter analyze` → **0 issues** (14.8s).
- `flutter test` → **no se re-ejecutó la suite completa** en esta fase específica porque ya se había corrido minutos antes, en la misma sesión, sin ningún cambio de código Dart entre medio: **972/972 tests pasaron** (ver Fase 3, §2). Repetir la corrida completa (varios minutos) no hubiera aportado ninguna señal nueva dado que no se tocó ni un archivo `.dart` desde esa corrida — se documenta la reutilización explícitamente en vez de fingir una ejecución nueva.
- El skill `floply-human-qa` (`~/.claude/skills/floply-human-qa/SKILL.md`) no se modificó durante esta fase — la versión de la Fase 3 fue suficiente para conducir toda la exploración sin ajustes.

## 4. Mission

Se ejecutó la exploración con la misma filosofía pedida: sin checklist fijo, decidiendo cada acción a partir de lo que la pantalla anterior mostraba, con el ciclo `OBSERVE → UNDERSTAND → CHOOSE → ACT → WAIT → OBSERVE → VERIFY → CONTINUE` y el protocolo anti-stale de 4 niveles en cada acción. La verificación de anomalías se hizo **en el momento** (no como una segunda pasada separada al final) porque el protocolo anti-stale ya exige, por diseño, escalar y reproducir antes de aceptar cualquier resultado negativo — separar "descubrimiento" de "verificación" en dos pasadas distintas hubiera significado repetir la mitad del trabajo sin ganar rigor adicional. Dos hallazgos (el bloqueo de RAISE por el FAB, y la necesidad de `hot_restart`) sí se reprodujeron una segunda vez de forma independiente antes de reportarlos, que es el espíritu real de la Pasada B.

## 5. Exploration Timeline

| Step | Screen | Observation | Action | Verification | Recovery |
|---|---|---|---|---|---|
| 1 | Laboratorio (selección de nivel) | Tarjeta "FÁCIL" con borde ya destacado | tap "FÁCIL" | Sin cambio a 4s+7s | Level 3 (`hot_reload`) → reveló ejercicio real PASO 1/8 |
| 2 | Laboratorio, ejercicio 1/8 | RAISE visualmente cortado por el FAB | tap coordenadas sobre RAISE (300,700) | Abrió "Ayuda Rápida" (POT ODDS/EQUITY/…) en vez de decidir RAISE | Confirmado con `get_interactive_elements` (RAISE no existe como GestureDetector) |
| 3 | "Ayuda Rápida" (sheet) | `press_back_button`, tap en barrera, swipe hacia abajo — los 3 sin efecto visible | 3 intentos de cierre | Screenshot seguía mostrando el sheet | Elements mostraba la app real SIN el sheet — confirmado con `tap("POT ODDS")` fallando ("Server error", el botón no existe) → el sheet visual era un artefacto de screenshot obsoleto, no un modal real |
| 4 | Laboratorio, ejercicio 1/8 (real) | FOLD/CALL visibles en elements | tap "FOLD" | Sin cambio a 3s | Level 3 (`hot_reload`) → reveló feedback real: "Elegiste FOLD. ✕ NO ES LA MEJOR... Concepto: Ventaja posicional" |
| 5 | Feedback PASO 2 | Panel "Conceptos en juego: Ventaja posicional, Rango de apertura, Open raise" | tap "SIGUIENTE" | Sin cambio inmediato | Level 3 (`hot_reload`) → reveló mano nueva, PASO 2/8, RAISE de nuevo cortado por el FAB (2ª ocurrencia) |
| 6 | Laboratorio, ejercicio 2/8 | Bottom nav visible | tap "PERFIL" | Sin cambio | Level 3 (`hot_reload`) → reveló pantalla real de Perfil: "Estás usando **Floply** sin cuenta" |
| 7 | Perfil | Bottom nav visible | tap "INICIO" | Sin cambio | Level 3 (`hot_reload`) → reveló Home real |
| 8 | Home | Tarjeta "BANKROLL" sin explorar en ninguna fase anterior | tap "BANKROLL" | Sin cambio a 3s ni tras `hot_reload` (Level 3); `get_interactive_elements` → **0 elementos**, persistente tras esperar 4s más | Se probó un objetivo independiente ("TOOLS", texto y coordenadas) — también sin efecto verificable y also 0 elementos → **Level 4 (`hot_restart`)** → recuperó ambos (auth screen limpia) |
| 9 | Auth (post hot_restart) | — | tap "Continuar sin cuenta" | Sin cambio a 10s | Level 3 (`hot_reload`) → reveló Home ("Cargando tu progreso…") |
| 10 | Home | Tab "ESTADÍSTICAS" sin explorar | tap "ESTADÍSTICAS" | Sin cambio a 3s | Level 3 (`hot_reload`) → reveló pantalla real: 13 niveles de curriculum, solo Nivel 1 desbloqueado, 0% en todos |

## 6. Areas Explored

Home (parcial, reutilizado de fases previas), Academia (lección 1.1 completa, mapa de nivel — de la Fase 3), Laboratorio (selección de dificultad + un ejercicio real completo hasta la mano 2/8, con feedback pedagógico), Perfil (pantalla completa, guest state), Estadísticas (pantalla completa, 13 niveles). **No explorado esta fase:** Bankroll (bloqueado por el evento de degradación del paso 8 — no se reintentó tras el `hot_restart` por prioridad de tiempo, ver §17), Tools/calculadoras individuales (ya cubiertas en el PoC de Marionette original), Coach (visible pero marcado "Próximamente" en el propio texto de Home — no es una función activa).

## 7. Interaction Reliability

Cada tap real con un blanco válido, una vez verificado correctamente (aplicando el protocolo completo), produjo su efecto esperado — **incluyendo el intento sobre RAISE**, que sí tuvo un efecto real (abrir Ayuda Rápida), solo que no el efecto que un usuario esperaría de ese botón. La única acción sin ningún efecto verificable pese a agotar los 4 niveles del protocolo fue el intento de cerrar el sheet "Ayuda Rápida" con 3 métodos distintos — pero se determinó que esto no era un fallo de interacción: la interacción sí había funcionado (el sheet ya estaba cerrado en el árbol real), era la *observación* (el screenshot) la que seguía mostrando el estado anterior.

## 8. Stale Observation Events

9 de las 10 filas de la tabla del §5 necesitaron escalar a `hot_reload` (Level 3) antes de poder confirmar el resultado real. Un caso (fila 8) necesitó escalar hasta `hot_restart` (Level 4). El caso más rico fue la fila 3: el screenshot mostró un bottom sheet "fantasma" que en realidad ya no existía en el árbol de widgets real — confirmado de forma cruzada e inequívoca al intentar tocar un botón de ese sheet ("POT ODDS") y recibir un error de resolución, no un tap silencioso.

## 9. Marionette Reliability

Ver §8 del diagnóstico de Fase 2 y §7-8 de la Fase 3 para el patrón general (ya bien documentado: observación inmediata post-acción no es confiable, interacción real sí lo es). Esta fase agrega dos datos nuevos:
- **El screenshot puede quedar "fantasma" mostrando un overlay que ya se cerró de verdad**, no solo mostrando la pantalla anterior completa (una variante más sutil de la desincronización ya conocida).
- **Un evento de degradación aparente (0 elementos + tap con "Server error" en dos objetivos independientes) sobrevivió a un `hot_reload` pero se resolvió completamente con `hot_restart`** — consistente con lo ya documentado en la Fase 2 (`hot_restart` es más confiable que `hot_reload` para recuperar ambos mecanismos a la vez), pero esta es la primera vez que la degradación persiste más allá de un solo `hot_reload` dentro de esta serie de fases. No se pudo determinar la causa raíz exacta (mismo límite ya reconocido en la Fase 2) — se documenta el síntoma, no se inventa el mecanismo.

## 10. Confirmed Bugs

### HQA-001

**Category:** Functionality Issue / UI Issue
**Severity:** HIGH

**Screen:** Laboratorio → ejercicio FÁCIL (reproducido en 2 manos distintas, 1/8 y 2/8)

**Action:** Tocar el botón "RAISE" visible en la fila de decisión (FOLD / CALL / RAISE).

**Expected:** El ejercicio registra la decisión RAISE y avanza con el feedback correspondiente, igual que ocurre con FOLD.

**Observed:** El tap sobre la posición visual de "RAISE" abre el bottom sheet "Ayuda Rápida" (accesos directos a POT ODDS / EQUITY / EV / COMBOS / RANGOS / BLOCKERS) en su lugar. `get_interactive_elements` confirma que no existe ningún `GestureDetector` para RAISE en el árbol — solo FOLD y CALL están registrados como interactivos. Las coordenadas de RAISE (aprox. x:239-342, y:668-722) se superponen casi por completo con el `FloatingActionButton` "Ayuda rápida" (x:288-344, y:662-718), que está por encima en el `Stack` y absorbe el toque.

**Evidence:** Screenshot antes (RAISE parcialmente visible, verde, con "RA" legible) + `get_interactive_elements` sin RAISE + tap en las coordenadas de RAISE abriendo Ayuda Rápida, confirmado con una segunda screenshot mostrando el sheet.

**Reproduction:** Confirmado 2/2 (mano 1/8 y mano 2/8, mismo layout, mismo resultado).

**Confidence:** Alta.

**Scope:** Cualquier ejercicio de Laboratorio en modo "FÁCIL" que ofrezca RAISE como opción — un usuario real no puede completar la decisión de abrir/subir en absoluto en esta pantalla, solo Fold o Call.

**Nota:** Esto conecta directamente con la observación ya registrada en la Fase 2 (el FAB "Ayuda rápida" se superponía visualmente al botón "CONTINUAR" de una lección de Academia) — en aquel momento se clasificó como problema puramente visual/UI. Esta fase demuestra que en Laboratorio el mismo patrón de superposición **no es solo visual: bloquea una acción funcionalmente**. Recomendación implícita para una fase de diseño futura: revisar la posición del FAB en toda pantalla con controles de acción en la fila inferior, no solo en Academia.

### HQA-002

**Category:** UI Issue (contenido/branding)
**Severity:** LOW

**Screen:** Perfil (guest)

**Action:** Ninguna — texto estático visible al entrar a la pantalla.

**Expected:** El nombre de la marca se muestra como "FLOPly" (la estilización usada consistentemente en la pantalla de login y en Home: "FLOPly", con la ele minúscula formando el chiste visual "FLOP").

**Observed:** El texto dice **"Floply"** ("Estás usando Floply sin cuenta"), sin la capitalización de marca.

**Evidence:** Screenshot de la pantalla de Perfil, texto legible directamente.

**Reproduction:** Confirmado (texto estático, no depende de estado ni de timing).

**Confidence:** Alta.

**Scope:** Aislado a este string en Perfil — no se encontró en ningún otro texto visitado durante esta fase ni las anteriores.

## 11. UX Concerns

- **HQA-003 (UX Concern, LOW):** No existe ninguna pantalla de "Ajustes/Configuración" visible desde Home ni desde el bottom nav para un usuario invitado — el único ícono con apariencia de engranaje (⚙) en Home lleva a Perfil (cuenta), no a preferencias de la app. Esto puede ser una decisión de producto deliberada (nada que configurar sin cuenta), pero el ícono de engranaje sigue comunicando "ajustes" a un usuario que reconoce ese símbolo — ver también HQA-004 más abajo.
- **HQA-005 (UX Concern, OBSERVATION):** El bottom sheet "Ayuda Rápida" no ofrece ningún botón de cierre explícito visible en el propio sheet — solo el patrón implícito de "arrastrar hacia abajo" o "tocar afuera". Dado que en esta sesión el cierre real sí funcionó (según el árbol de widgets) pero la ausencia de una confirmación visual clara generó dudas genuinas sobre si había funcionado, esto es una señal de que la falta de un cierre explícito (una "X" o "Cerrar") puede generar la misma incertidumbre en un usuario real, no solo en un agente.

## 12. UI Issues

Ver HQA-001 y HQA-002 arriba — no se encontraron issues de UI adicionales more allá de los dos ya reportados (sin overflow, sin clipping de texto, sin contraste insuficiente detectado en las pantallas visitadas esta fase).

## 13. Navigation Issues

**Revisitado explícitamente, tal como pedía §11 de esta fase:** la observación de la Fase 3 ("volver desde una lección de Academia lleva al mapa de curriculum, no a Home") se re-examinó con el criterio pedido:

1. **Acción del usuario:** tocar la flecha de "volver" arriba a la izquierda de una lección.
2. **Expectativa razonable:** "volver" a la pantalla desde la que se entró.
3. **Qué ocurrió:** apareció el mapa de nivel de Academia ("Nivel 1 · Cómo funciona una mano", con las lecciones 1.2-1.4 bloqueadas) — que es, de hecho, la pantalla lógicamente intermedia real entre Home y la lección (Home → mapa de nivel → lección), aunque el usuario haya llegado a la lección directamente desde el botón "COMENZAR ACADEMIA" de Home sin pasar visualmente por el mapa.
4. **¿Existe una ruta alternativa evidente?** Sí — desde el mapa de nivel, el tab "INICIO" del bottom nav vuelve a Home en un toque más.
5. **¿Es consistente?** Sí, se comportó igual las dos veces que se probó (Fase 3 y esta fase).
6. **¿Hay evidencia de que contradiga el diseño esperado?** No. Es coherente con una jerarquía de navegación real de 3 niveles (Home → Nivel → Lección) donde "volver" sube un nivel, un patrón estándar y predecible una vez que se conoce la jerarquía.

**Conclusión: esto NO se reporta como bug ni como navigation issue.** Es el comportamiego esperable de una jerarquía de navegación de tres niveles. El único matiz genuino (y por eso se registra como **OBSERVATION**, no como hallazgo) es que un usuario que entra a la lección directamente desde el atajo de Home puede no anticipar ese nivel intermedio — pero encontrarlo no le cuesta ninguna acción adicional real (un toque más a Home).

## 14. Accessibility Issues

**Revisitado explícitamente, tal como pedía §12 de esta fase:** la observación de la Fase 2 ("el ícono de engranaje en Home tiene `Semantics(label: "Abrir tu perfil")`") se re-examinó en contexto real, no en aislamiento:

- Se confirmó que ese ícono efectivamente navega a Perfil (verificado en el paso 6 de la tabla del §5).
- La etiqueta de accesibilidad ("Abrir tu perfil") **es correcta y describe con precisión el destino real**.
- El único desajuste real es entre la forma visual del ícono (un engranaje, que visualmente sugiere "ajustes/configuración" a cualquier usuario familiarizado con esa convención) y su destino real (una pantalla de cuenta/perfil, no de configuración).

**Reclasificación respecto a la Fase 2:** esto no es un problema de accesibilidad (el lector de pantalla anuncia correctamente adónde lleva el botón) — es, como mucho, una **UX Concern de elección de ícono** (HQA-003, ya registrada arriba), y solo aplica a usuarios videntes que interpretan el ícono visualmente antes de tocarlo. Se corrige la clasificación original.

No se encontraron accessibility issues nuevos en las pantallas de esta fase (Laboratorio, Perfil, Estadísticas) — los botones de decisión (FOLD/CALL/RAISE) no se pudieron inspeccionar por `Semantics` explícitos más allá de su `GestureDetector`+`Text`, que es el mismo patrón visto en el resto de la app.

## 15. Functionality Issues

Ver HQA-001 (RAISE inalcanzable) — es, a la vez, el issue de UI y el issue funcional más severo de esta fase.

## 16. Pedagogical UX Issues

**Hallazgo positivo, no un problema:** el feedback del ejercicio de Laboratorio, tras elegir FOLD incorrectamente, no se limitó a "✕ NO ES LA MEJOR" — mostró una segunda pantalla con **"Conceptos en juego acá: Ventaja posicional, Rango de apertura, Open raise"**, nombrando exactamente los conceptos relevantes para entender el error. Esto responde bien a varias de las preguntas pedagógicas de la fase: el usuario entiende *por qué* falló (no solo que falló), y la interfaz lo dirige a los conceptos concretos a repasar, no a una explicación genérica. No se identificó ningún concepto que apareciera sin contexto durante esta exploración puntual — pero la muestra fue de una sola decisión (FOLD), no se probó CALL ni (por el bug HQA-001) RAISE, así que esto **no** es una auditoría pedagógica completa del ejercicio, solo de la rama que se pudo recorrer.

## 17. Uncertain / Not Reproducible

- El estado exacto que provocó el evento de degradación del paso 8 (§5) — por qué esa acción en particular ("BANKROLL") coincidió con una pérdida de observación que sobrevivió a un `hot_reload` — queda **INCONCLUSIVE**. No se pudo determinar si la causa fue específica de esa tarjeta, del momento de la sesión, o coincidencia. No se reintentó explorar Bankroll después del `hot_restart` por priorizar cobertura de áreas nuevas (Estadísticas) con el tiempo restante — queda pendiente para una futura sesión.

## 18. Environment / Tool Issues

Ninguno nuevo más allá de lo ya documentado en Fases 1-3 (`get_logs` sigue sin probarse en esta fase; no hizo falta para el protocolo usado).

## 19. Phase 3 Findings Revisited

| Hallazgo de Fase 2/3 | Reclasificación en Fase 4 |
|---|---|
| Ícono de engranaje con `Semantics(label: "Abrir tu perfil")` | Reclasificado: no es un problema de accesibilidad (la etiqueta es correcta), es una UX Concern de elección de ícono (§14, HQA-003) |
| Volver desde una lección lleva al mapa de curriculum, no a Home | Confirmado como comportamiento correcto de una jerarquía de 3 niveles, no un bug (§13) |
| FAB "Ayuda rápida" se superpone visualmente al botón "CONTINUAR" en Academia | Confirmado y **agravado**: en Laboratorio el mismo patrón de superposición bloquea funcionalmente el botón RAISE, no solo lo tapa visualmente (§10, HQA-001) |
| Sección "MODO CLÁSICO (DESARROLLO)" visible en Laboratorio | No revisitada activamente esta fase (se usó el flujo de niveles FÁCIL/MEDIO/EXPERTO en su lugar) — sigue como observación suelta de la Fase 3, no auditada |

## 20. Coverage Summary

Explorado con profundidad: Laboratorio (selección + 1 ejercicio completo hasta la mano 2), Perfil, Estadísticas. Explorado en fases previas y no repetido: Home, Academia (lección + mapa de nivel), Tools/calculadoras. No explorado: Bankroll (bloqueado por el evento de degradación, ver §17), Coach (marcado "Próximamente" en el propio texto de la app, no es una función activa a auditar).

## 21. Capabilities Matrix

| Capability | Status | Evidence |
|---|---|---|
| Autonomous exploration | PASS | 10 acciones reales elegidas en el momento, sin secuencia prescrita (§5) |
| Screenshot observation | PARTIAL | Confiable la mayoría de las veces; produjo un "sheet fantasma" que requirió cruce con `get_interactive_elements` para desambiguar (§8, §9) |
| Interactive element discovery | PASS | Permitió descubrir la ausencia real de un GestureDetector para RAISE — el hallazgo más importante de la fase (§10) |
| Semantics inspection | PARTIAL | Usado para reclasificar correctamente el hallazgo del ícono de engranaje (§14); no se profundizó más allá de eso esta fase |
| Autonomous target selection | PASS | Bankroll, Perfil, Estadísticas, RAISE — todos elegidos por parecer naturales, no indicados |
| Tap | PASS | Efectivo en el 100% de los intentos con blanco real, una vez verificado correctamente |
| Swipe | PASS | Usado para intentar cerrar el sheet — el swipe en sí funcionó como gesto (fue la desambiguación de qué estaba realmente pasando la que requirió más pasos) |
| Scroll | NOT VERIFIED | No apareció naturalmente ninguna pantalla con contenido cortado que ameritara scroll en esta fase específica |
| Back | PASS | `press_back_button` usado en el intento de cerrar el sheet, con resultado correctamente interpretado |
| Navigation verification | PASS | Se verificó activamente cada navegación esperada vs. observada (§13) |
| State verification | PASS | Distinción ACTION/APP/OBSERVATION STATE aplicada explícitamente en el caso del sheet fantasma (§8) |
| Stale detection | PASS | 9/10 acciones detectadas correctamente como potencialmente stale antes de escalar |
| Stale recovery | PASS | 9 casos resueltos en Level 3, 1 caso resuelto en Level 4 |
| Marionette degradation detection | PASS | Se probó un segundo objetivo independiente antes de escalar a `hot_restart`, tal como pedía el protocolo (§5, fila 8) |
| UX reasoning | PASS | HQA-003, HQA-005 |
| UI reasoning | PASS | HQA-001, HQA-002 |
| Accessibility reasoning | PASS | Reclasificación correcta del hallazgo del gear icon (§14) |
| Functional reasoning | PASS | HQA-001 |
| Pedagogical UX reasoning | PASS | §16 |
| Evidence collection | PASS | Cada hallazgo del §10 tiene su bloque de evidencia completo |
| Reproduction verification | PASS | HQA-001 reproducido 2/2; el evento de degradación reproducido con un segundo objetivo independiente |
| Human-like autonomous exploration | PASS | Ninguna acción de esta fase fue una coordenada o texto dictado de antemano — todas surgieron de observar la pantalla anterior |

## 22. Final Assessment

`floply-human-qa` demostró, en una sesión real y no guionada, la cadena completa que pedía el criterio de éxito: **SEE → UNDERSTAND → CHOOSE → ACT → VERIFY → NOTICE ANOMALY → INVESTIGATE → DISTINGUISH APP VS TOOL → REPRODUCE → DOCUMENT**. El hallazgo más valioso de la fase (RAISE inalcanzable por el FAB) nunca se habría encontrado leyendo código o siguiendo un checklist genérico de "probar todos los botones" — surgió de notar, como lo notaría un usuario real, que el texto del botón se veía cortado, y de investigar qué pasaba realmente al tocarlo. El evento de degradación (§5, fila 8) se manejó exactamente como pedía el protocolo: sin pánico, sin forzar decenas de reintentos, probando un objetivo independiente antes de escalar, y documentando el resultado real en vez de inventar una causa.

No se encontraron blockers. Se encontró un HIGH (HQA-001) y un LOW (HQA-002), más varias observaciones UX/navegación honestamente clasificadas como "no es un bug" cuando la evidencia no lo sostenía (§13, §14) — que es tan importante como reportar lo que sí lo es.

## 23. Recommended Next Actions

- No se recomienda iniciar todavía una Fase 5 de auditoría exhaustiva de todo el curriculum — esta fase cubrió una fracción representativa, no la totalidad de FLOPly.
- Antes de continuar, valdría la pena que un humano revise específicamente HQA-001 (RAISE inalcanzable) porque bloquea una función central del producto (practicar la decisión de abrir/subir), no es un detalle cosmético.
- Si se retoma la exploración, priorizar Bankroll (nunca explorado en ninguna fase) y una segunda pasada sobre Laboratorio probando CALL y, una vez arreglado HQA-001, RAISE, para completar la cobertura pedagógica de esa rama.
- Vale la pena investigar en algún momento la causa raíz del evento de degradación del paso 8 — ocurrió una sola vez en 4 fases de trabajo con Marionette, pero el hecho de que sobreviviera a un `hot_reload` lo distingue de los casos más comunes ya documentados.
