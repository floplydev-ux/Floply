# FLOPly Human QA — Fase 3 (Interaction & Observation)

**Fecha:** 2026-09-19. Primera misión real del skill `floply-human-qa`, creado en esta misma sesión a partir de la evidencia de `MARIONETTE_POC_2026-09-19.md` y `MARIONETTE_PHASE2_DIAGNOSTIC_2026-09-19.md`. No se auditó UX/UI, no se corrigió nada, no se construyó nada más allá del skill mínimo pedido.

## 1. Objective

Determinar si un agente puede **usar FLOPly como una persona** — observar, decidir una acción razonable, actuar, verificar el resultado y seguir explorando — sin una secuencia de taps prescrita, y aplicando correctamente el protocolo anti-stale documentado en la Fase 2 en vez de declarar "roto" ante la primera lectura sin cambios.

## 2. Environment

Reutiliza el mismo entorno validado en la Fase 2, con un `hot_restart` al comienzo de la misión para arrancar desde la pantalla real de login (estado "recién abrí la app"):

- Flutter 3.47.2 / Dart 3.13.2, `marionette_flutter` 0.6.0, `marionette_mcp` 0.6.0.
- `flutter run -d chrome --web-port=8765`, conexión Marionette activa desde la Fase 2, sin reconectar.
- Antes de la misión: `flutter analyze` → 0 issues; `flutter test` → **972/972 tests pasaron**. Esto confirma que el repo sigue sano, **no** que el skill haya manejado la app correctamente — eso solo lo confirma la misión en sí (regla de honestidad, §23 del pedido original).
- El skill vive en `~/.claude/skills/floply-human-qa/SKILL.md` — no toca ningún archivo Dart. Por eso `flutter analyze`/`flutter test` no podían fallar por su culpa; se corrieron igual como sanity check general del repo, tal como se pidió.

## 3. Skill Architecture

Un único archivo de instrucciones (`SKILL.md`, ~110 líneas), sin scripts ni tooling adicional — coherente con el resto de skills del proyecto (`ux-audit-flutter`, `flutter-qa`, etc., todos de una sola página). Contiene:

- El ciclo obligatorio `OBSERVE → IDENTIFY → CHOOSE ACTION → ACT → WAIT → OBSERVE → VERIFY`.
- Los tres estados a mantener separados: ACTION STATE / APP STATE / OBSERVATION STATE.
- El protocolo anti-stale de 5 niveles (0 a 4), con la regla absoluta de que una primera lectura obsoleta nunca es un FAIL.
- El procedimiento de detección de degradación de Marionette (`MARIONETTE_INTERACTION_DEGRADED`) vs. problema real de la app.
- Las cuatro etiquetas de clasificación: APP BUG / TOOL FAILURE / STALE OBSERVATION / INCONCLUSIVE.
- Los no-objetivos explícitos de esta fase (nada de auditoría, scoring, fixes, ni secuencias prescritas).

No se necesitó modificar el skill durante la misión — funcionó como estaba escrito.

## 4. Mission

Texto exacto ejecutado (el mismo que pidió el usuario, sin agregar ni quitar nada):

> Entrá a FLOPly como un usuario nuevo. Explorá Home durante aproximadamente 5 minutos. Seguí las rutas que parezcan naturales para un usuario que acaba de abrir la aplicación. Interactuá con los elementos visibles y verificá que las acciones produzcan los resultados esperados. Si una acción parece no funcionar, no concluyas inmediatamente que existe un problema: aplicá el protocolo anti-stale y verificá que Marionette siga pudiendo interactuar antes de sacar conclusiones. No corrijas nada.

No se le dio ninguna lista de pantallas ni de taps. Cada acción de la tabla de abajo fue decidida en el momento, a partir de lo que la pantalla anterior mostraba.

## 5. Exploration Timeline

| Step | Screen | Observation | Action | Verification | Recovery |
|---|---|---|---|---|---|
| 1 | Auth (login) | 4 opciones de login + "Continuar sin cuenta"; ninguna cuenta real disponible para un usuario nuevo explorando | tap "Continuar sin cuenta" (texto) | Sin cambio a 8s, sin cambio a 16s (Level 1) | **Level 3** (`hot_reload`) → reveló Home real. Sign-in de invitado genuinamente async (~19s totales), no relacionado con Marionette |
| 2 | Home | Hero card "COMENZAR ACADEMIA" es la CTA visualmente dominante | tap "COMENZAR ACADEMIA" (texto) | Cambio inmediato a Nivel 0 — lección real "1.1 · El objetivo y las cartas", PASO 1/8 | Ninguno necesario — PASS directo |
| 3 | Lección 1.1, PASO 1/8 | Botón "CONTINUAR" visible, mesa de 6 jugadores, panel educativo | tap "CONTINUAR" (texto) | Sin cambio a 3s (screenshot y elements coinciden en "sin cambio") | **Level 3** (`hot_reload`) → reveló PASO 2/8 ("EL BOTE", bote 1.5 BB) |
| 4 | Lección 1.1, PASO 2/8 | Aparece un botón nuevo "ATRÁS" junto a "CONTINUAR" | tap "CONTINUAR" (texto) | Sin cambio a 3s (Level 0); a 8s el screenshot mostró un frame **incongruente** (texto de PASO 1 + bote/dot de PASO 2) mientras `get_interactive_elements` ya mostraba PASO 2 completo y consistente | **Level 2→3**: se marcó UNCERTAIN por el desacuerdo, se confirmó con `get_interactive_elements` (ya correcto) y se forzó `hot_reload` de todos modos → reveló PASO 3/8 ("TUS CARTAS", Juan recibe K♦K♣) |
| 5 | Lección 1.1, PASO 3/8 | "ATRÁS" es la acción natural para repasar el paso anterior | tap "ATRÁS" (texto) | Sin cambio a 3s | **Level 3** (`hot_reload`) → reveló vuelta correcta a PASO 2/8 |
| 6 | Lección 1.1, PASO 2/8 | Flecha de volver arriba a la izquierda (ícono circular) — salida natural de la lección | tap por coordenadas (36,30) | Sin cambio a 3s | **Level 3** (`hot_reload`) → reveló el **mapa de nivel de Academia** ("Nivel 1 · Cómo funciona una mano", 0/64 lecciones, 1.2-1.4 bloqueadas) — un paso intermedio real entre la lección y Home, no visitado en fases anteriores |
| 7 | Mapa de nivel de Academia | Bottom nav con 5 tabs, "LABORATORIO" sin explorar todavía en esta sesión | tap "LABORATORIO" (texto, bottom nav) | Sin cambio a 3s | **Level 3** (`hot_reload`) → reveló Laboratorio real: niveles FÁCIL/MEDIO/EXPERTO + sección "MODO CLÁSICO (DESARROLLO)" con dos botones de práctica |

Tiempo real insumido por la misión interactiva: aproximadamente 5-6 minutos de reloj (7 acciones, cada una con su ciclo completo de espera/verificación), consistente con el objetivo de "~5 minutos" del pedido.

## 6. Interaction Reliability

**7 de 7 acciones reales tuvieron el efecto correcto y esperado**, verificado con evidencia (no supuesto). Ninguna acción resultó realmente inerte. Esto confirma, con una muestra independiente de la Fase 2, que la interacción de Marionette (`tap` por texto y por coordenadas) es confiable cuando se la verifica correctamente.

## 7. Stale Observation Events

6 de las 7 acciones necesitaron escalar hasta **Level 3** (`hot_reload`) antes de poder confirmar el resultado real — solo la acción #2 ("COMENZAR ACADEMIA") se resolvió en Level 0, sin ninguna escalada. Ninguna requirió Level 4 (`hot_restart`) durante la misión en sí (sí se usó `hot_restart` una vez, deliberadamente, al principio, para arrancar desde cero — eso no cuenta como "recuperación de stale", es el punto de partida de la misión).

El evento más interesante fue el paso 4: el screenshot mostró un frame **internamente incongruente** (texto de un paso mezclado con datos numéricos de otro) — ni "vacío" ni "la pantalla anterior completa", sino una mezcla parcial. Esto confirma y refina el hallazgo de la Fase 2: la obsolescencia de `take_screenshots` no siempre se manifiesta como "pantalla vieja completa" — puede ser un frame a medio transicionar. El protocolo (Level 2: comparar contra `get_interactive_elements`, que ya estaba correcto y consistente) funcionó exactamente como está escrito para resolver ese caso sin declarar un bug inexistente.

**Ningún caso de esta misión mostró a los dos mecanismos de observación de acuerdo entre sí y sin embargo equivocados** — cuando coincidían, coincidían en el estado real (aunque atrasado); el desacuerdo del paso 4 fue detectado correctamente por el protocolo, no ignorado.

## 8. Marionette Degradation Events

**Ninguno.** En ningún momento dos objetivos independientes dejaron de responder a la vez. Cada acción, una vez escalado el protocolo anti-stale hasta el nivel necesario, mostró el efecto esperado. No se emitió ningún `MARIONETTE_INTERACTION_DEGRADED` durante esta misión.

## 9. Tool Failures

**Ninguno.** `tap` (texto y coordenadas), `press_back_button` (no se usó esta vez — se usaron los controles propios de la UI, "ATRÁS" y la flecha, en su lugar, porque eran las acciones que un usuario real vería y tocaría), `hot_reload` y `hot_restart` funcionaron todas las veces que se invocaron, sin ningún error de la tool en sí. `get_logs` no se probó en esta misión (no fue necesario para el protocolo de verificación usado).

## 10. Unresolved Observations

- No se disparó ningún scroll de forma natural durante esta misión — ninguna de las 7 pantallas visitadas mostró contenido evidentemente cortado que invitara a desplazarse (a diferencia de Home en la Fase 2, donde "Coach" aparecía cortado). Coherente con la regla de "no forzar una ruta si la app no la presenta naturalmente" — se documenta como **NOT APPLICABLE en esta sesión**, no como fallo.
- **OBSERVATION** (no es un finding, no se audita ni se corrige): la pantalla de Laboratorio muestra una sección visible llamada **"MODO CLÁSICO (DESARROLLO)"** con dos botones de práctica ("EMPEZAR A PRACTICAR" y "PRACTICAR (MOTOR NUEVO)") — un rótulo de desarrollo/debug visible para un usuario invitado en lo que parece una pantalla de producción. Se registra tal cual se vio, sin puntaje ni severidad.
- **OBSERVATION**: la flecha de "volver" dentro de una lección no regresa a Home directamente — sube un nivel en la jerarquía real (lección → mapa de nivel de Academia → recién ahí Home). Es información de arquitectura real, no necesariamente un problema; se deja registrada para quien haga la auditoría formal de navegación.

## 11. Capabilities Matrix

| Capability | Result | Evidence |
|---|---|---|
| Connect | PASS | Conexión reutilizada de la Fase 2, activa durante toda la misión |
| Screenshot | PASS | Funcionó en las 7 acciones; obsoleto temporalmente en 6/7, siempre recuperable |
| Widget inspection | PASS | `get_interactive_elements` devolvió árboles ricos y correctos en cada verificación final |
| Semantics inspection | NOT VERIFIED | No fue necesario consultar nodos `Semantics` explícitos en esta misión (ya confirmado en fases anteriores) |
| Interactive element discovery | PASS | Cada pantalla nueva se identificó correctamente a partir de `get_interactive_elements`, sin coordenadas prefijadas |
| Autonomous target selection | PASS | Las 7 acciones fueron elegidas en el momento a partir de lo que la pantalla mostraba, sin ruta predefinida |
| Tap | PASS | 7/7 acciones reales confirmadas con el efecto esperado |
| Swipe | NOT VERIFIED | No apareció naturalmente ninguna pantalla con contenido cortado durante esta misión |
| Navigation | PASS | Home → Lección → mapa de Academia → Laboratorio, todo confirmado |
| Back | PASS | "ATRÁS" (in-lesson) y la flecha de salida de lección, ambas confirmadas correctas |
| Verification | PASS | Cada acción se verificó con evidencia real (screenshot + elements), nunca asumida |
| Stale detection | PASS | Detectado correctamente 6/7 veces, incluido el caso de frame incongruente (paso 4) |
| Stale recovery | PASS | `hot_reload` resolvió las 6 escaladas necesarias, 6/6 |
| Interaction degradation detection | NOT VERIFIED (por ausencia) | No hubo ningún caso real de degradación que detectar — el mecanismo de detección en sí no se puso a prueba con un caso positivo |
| Continued exploration | PASS | La misión encadenó 7 acciones distintas en 5 pantallas distintas sin detenerse tras la primera lectura obsoleta |

## 12. Final Assessment

### A. ¿El skill fue creado correctamente?
Sí. Un archivo, sin tocar Dart, validado con `flutter analyze`/`flutter test` (972/972) antes de la misión.

### B. ¿Pudo explorar Home sin recibir una secuencia predefinida?
Sí. La única instrucción fue la misión en lenguaje natural; cada acción de la tabla del §5 se decidió mirando la pantalla anterior, no una lista.

### C. ¿Pudo decidir acciones por sí mismo?
Sí — eligió la CTA hero en Home, "CONTINUAR" dentro de la lección, "ATRÁS" cuando apareció como opción nueva, la flecha de salida, y un tab de bottom nav no visitado, en ese orden, sin que ninguna fuera indicada de antemano.

### D. ¿Pudo interactuar?
Sí, 7/7 veces, confirmado con evidencia.

### E. ¿Pudo verificar resultados?
Sí, en las 7 acciones, sin excepción — ninguna se dio por buena ni por mala sin evidencia.

### F. ¿Pudo detectar/reconocer estado stale?
Sí, incluyendo el caso más difícil de esta misión: un frame de screenshot internamente incongruente (mezcla de dos pasos distintos), que resolvió correctamente comparándolo contra `get_interactive_elements` en vez de declarar un bug.

### G. ¿Pudo distinguir un problema de FLOPly de una degradación de Marionette?
Parcialmente verificado por ausencia: no hubo ningún caso real de degradación de Marionette ni de bug real de FLOPly esta vez, así que el mecanismo de distinción no se puso a prueba con un caso positivo de ninguno de los dos. Sí demostró, en cambio, no confundir "observación atrasada" con ninguna de las dos categorías — que era el riesgo principal identificado en la Fase 2.

### H. ¿Pudo continuar explorando?
Sí. Después de cada una de las 6 escaladas a `hot_reload`, la misión no se detuvo ni se reinició desde cero — siguió con la siguiente acción natural a partir del estado real recién confirmado.

---

## Resultado

**El skill mínimo funciona.** Un agente guiado por `floply-human-qa` puede observar FLOPly real, elegir una acción razonable sin que se la dicten, ejecutarla, detectar correctamente cuándo la observación inmediata no es confiable, recuperarse con `hot_reload` sin declarar falsos bugs, y seguir explorando — repitiéndolo 7 veces seguidas sin un solo falso negativo ni un solo falso positivo.

No se pasa a Fase 4 (auditoría exploratoria completa) en este documento, tal como se pidió. No se corrigió el rótulo "MODO CLÁSICO (DESARROLLO)" visible en Laboratorio ni ningún otro detalle observado — quedan anotados en §10 para una auditoría formal posterior.
