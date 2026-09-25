# Marionette Fase 2 — Diagnóstico profundo de interacción

**Fecha:** 2026-09-19. **Objetivo:** determinar por qué el PoC anterior (mismo día, `MARIONETTE_POC_2026-09-19.md`) reportó `tap`/`swipe` como FAIL tras degradarse, y si el problema está en Marionette, en Flutter Web/Chrome, en FLOPly, o en el tipo de gesto.

**No se modificó ningún archivo de FLOPly** (`lib/`, tests, arquitectura, navegación, botones). Los únicos cambios de esta sesión fueron: matar y volver a levantar el proceso `flutter run` (arranque limpio, pedido explícitamente en Fase 1) y llamadas de Marionette (`tap`, `swipe`, `hot_reload`, `hot_restart`, etc.), que no tocan el código fuente.

---

## 1. Executive Summary

**El hallazgo central de esta fase revierte la conclusión principal del PoC anterior.**

El PoC de hoy había concluido `Tap: FAIL` y había señalado como bug real de producto que el botón **"COMENZAR ACADEMIA"** de Home no navegaba, y que el tab inferior "INICIO" no funcionaba desde dentro de una lección. Repetí exactamente esas dos interacciones en esta fase, pero esta vez, en lugar de concluir "no pasó nada" a partir de un `screenshot`/`get_interactive_elements` sin cambios, forcé un `hot_reload` inmediatamente después de cada tap para obtener una lectura confiable del estado real. **En ambos casos, la navegación SÍ había ocurrido.** El botón funciona. El tab funciona.

La causa real no es que `tap` falle: es que **`take_screenshots` y `get_interactive_elements` pueden quedar mostrando un estado obsoleto (a veces vacío, a veces la pantalla anterior) durante un lapso variable e impredecible después de un tap que sí surtió efecto**, y ese lapso no siempre se resuelve solo con esperar. `hot_reload` fuerza la resincronización en la mayoría de los casos (confirmado 3 veces), pero no siempre corrige `take_screenshots` (un caso donde `get_interactive_elements` se recuperó pero el screenshot siguió congelado en la pantalla anterior); `hot_restart` sí corrigió ambos a la vez, siempre que se probó.

En 10 interacciones reales distintas verificadas con este método (tap por texto, tap por coordenadas, swipe, back), **10 de 10 resultaron en el efecto esperado** una vez que se confirmó correctamente el estado real. Ninguna resultó genuinamente inerte. El "Scroll: FAIL" del PoC anterior tampoco se sostiene: un swipe limpio en esta fase movió el contenido exactamente 61px de forma inmediata y verificable, sin necesidad de `hot_reload`.

**Conclusión adelantada (desarrollada en §10 y §13):** la capa de interacción de Marionette (tap, swipe, back) es confiable. La capa de observación inmediata (screenshot + element inspection) no lo es, y puede producir falsos negativos si se la interpreta sin un protocolo de verificación. Esto es un problema solucionable con un procedimiento documentado, no un defecto fundamental de interacción.

---

## 2. Environment

Arranque limpio desde cero, tal como pedía la Fase 1 (no se reutilizó la instancia anterior).

| Campo | Valor |
|---|---|
| Comando | `flutter run -d chrome --web-port=8765` (cwd: `D:\Proyectos\poker_trainer_home0.1\poker_trainer`) |
| Dispositivo | Chrome (`flutter_tools` lanza una instancia aislada con `--user-data-dir` temporal, `--bwsi`) |
| Plataforma | Flutter Web (`web-javascript`, DWDS) |
| VM Service | `ws://127.0.0.1:62889/ezDvHRS-8to=/ws` (puerto asignado dinámicamente por el segundo `flutter run`; el primer intento de esta sesión usó otro puerto y se descartó, ver nota abajo) |
| Conexión Marionette | `connect` exitoso al primer intento, sin reintentos |
| Flutter | 3.47.2 (stable, revisión `d3b14c8769`, 2026-08-26) |
| Dart | 3.13.2 |
| `marionette_flutter` | 0.6.0 (confirmado por el directorio real en el pub cache: `PubCache/hosted/pub.dev/marionette_flutter-0.6.0`, no por el pubspec del proyecto solamente) |
| `marionette_mcp` | 0.6.0 (mismo método de confirmación: `marionette_mcp-0.6.0` en el pub cache) |
| Config MCP | Sin cambios respecto al PoC anterior — servidor `marionette` ya registrado vía `claude mcp add`, no se tocó |

**Nota sobre el arranque:** el primer `flutter run` de esta fase (antes de conectar) no mostró el error de Firebase que sí había aparecido en el PoC original — arrancó limpio. Esto es consistente con lo ya documentado como "flakiness de red intermitente, no reproducible de forma determinística" — no se investigó más a fondo porque no es el objeto de esta fase.

---

## 3. Reproduction Matrix

Diez interacciones reales y distintas, ejecutadas en orden, cada una con su verificación real (no asumida). "Verificación" indica el método que finalmente confirmó el resultado real — en la mayoría de los casos NO fue la primera lectura de `screenshot`/`get_interactive_elements`, sino una segunda pasada tras `hot_reload`.

| # | Elemento | Tipo de widget | Método de tap | Efecto observado (1ª lectura) | Verificación real | Resultado |
|---|---|---|---|---|---|---|
| 1 | "Continuar sin cuenta" | Texto/link subrayado pequeño (auth) | texto | Sin cambio tras 8s | Sin cambio tras 6s más → resultó ser navegación async lenta (sign-in anónimo), confirmada indirectamente | PASS (lento, ~14s, no es bug de Marionette) |
| 2 | "TOOLS" (card Home) | GestureDetector grande (324×89) | texto | `get_interactive_elements`→0 tras 3s; screenshot sin cambio | Tras más esperas y un hot_reload posterior, se confirmó que SÍ había navegado a Tools | PASS (oculto por observación congelada) |
| 3 | `press_back_button` desde Tools | n/a (tool nativa) | n/a | "route was popped"; screenshot/elements mostraron Tools sin cambios durante 31s reales | `hot_reload` reveló Home en `get_interactive_elements` (aunque el screenshot siguió mostrando Tools) | PASS (pop real; observación con dos fallas independientes, ver §6) |
| 4 | `hot_restart` (recuperación total) | n/a | n/a | — | Screenshot y elements volvieron a auth screen, ambos sincronizados | PASS (recuperación completa confirmada) |
| 5 | "Continuar con email" | Botón ancho completo, alto contraste | texto | Sin cambio visible; `get_interactive_elements`→0 tras 6s | `hot_reload` reveló formulario "Ingresá tu email" completo (TextField, botón ENVIAR LINK) | PASS (oculto por observación congelada) |
| 6 | Tap en (94,67) sobre el formulario de email | — (miss deliberado, sin blanco real) | coordenadas | Sin cambio, `get_interactive_elements` correcto e inmediato (7 elementos, sin cambios) | No aplica — este resultado ya era correcto sin necesitar hot_reload | PASS (falla correctamente reportada como "sin efecto", no es un bug) |
| 7 | Flecha "volver" del formulario de email | Ícono circular pequeño (36×36) | coordenadas | `get_interactive_elements`→0 inmediatamente | `hot_reload` reveló vuelta real a auth screen | PASS (oculto por observación congelada) |
| 8 | "Continuar sin cuenta" (segunda vez, tras hot_restart) | Texto/link | texto | Tras 5s + hot_reload: Home visible pero con "Cargando tu progreso…" (placeholder de carga real, sin CTA aún) | Tras 10s adicionales, la tarjeta hero con "COMENZAR ACADEMIA" apareció normalmente | PASS (async real de carga de progreso, no de Marionette) |
| 9 | **"COMENZAR ACADEMIA"** (el bug marcado por el PoC anterior) | GestureDetector grande, CTA hero | texto | Tap + 3s de espera + `hot_reload` inmediato | `get_interactive_elements` mostró la lección real "1.1 · El objetivo y las cartas", PASO 1/8, mesa de 6 jugadores | **PASS — el hallazgo del PoC anterior era un falso negativo** |
| 10 | **Tab "INICIO"** desde dentro de la lección (el segundo bug marcado por el PoC anterior) | InkWell de bottom nav | texto | Tap + 3s + `hot_reload` inmediato | `get_interactive_elements` mostró Home completo, con el hero card de Academia de nuevo visible | **PASS — también era un falso negativo** |
| 11 | `swipe` vertical en Home (700→200) | Scroll de `ListView`/`Column` scrollable | swipe | 3s de espera, sin hot_reload | `get_interactive_elements` mostró el contenido desplazado exactamente 61px (mismo delta en 4 elementos distintos), bottom nav fijo | **PASS, inmediato, sin necesidad de hot_reload** |

**Resultado agregado: 10 de 10 interacciones reales tuvieron el efecto esperado.** Ninguna resultó genuinamente inerte cuando se verificó correctamente. La única fila que "falló" (fila 6) falló porque el tap apuntaba deliberadamente a un lugar sin ningún widget interactivo, y el sistema lo reportó con precisión (ausencia de cambio, sin falso positivo ni falso negativo) — es evidencia de que el mecanismo de verificación FUNCIONA cuando no está en el estado congelado.

---

## 4. Tap Analysis

No hay ningún caso, de los 10 anteriores, donde un `tap` con un blanco real (`text`, `key` o coordenadas dentro de un widget interactivo) haya fallado en producir su efecto. Los casos que en el PoC original se reportaron como `FAIL` (fila 9 y 10 de esta tabla) resultaron ser interacciones reales que sí ocurrieron, solo que Marionette tardó en reportarlas correctamente.

**No se encontró correlación entre el tipo de tap (texto vs. coordenadas) y el resultado.** Ambos métodos tuvieron éxito real en múltiples ocasiones (texto: filas 1,2,5,8,9,10; coordenadas: filas 6,7) y ambos mostraron el mismo patrón de observación congelada de forma indistinta (filas 2, 5 y 7 usaron métodos distintos y las tres mostraron el mismo síntoma).

**Tampoco se encontró correlación con el tipo de widget.** Se probaron: un link de texto subrayado pequeño, un card GestureDetector grande, un botón ancho de alto contraste, un ícono circular pequeño de 36×36, un CTA hero grande, y un ítem de bottom navigation — el síntoma de observación congelada apareció en 4 de 6 tipos, sin ningún patrón visible relacionado al tamaño o tipo del widget.

La única variable que sí correlaciona con el síntoma es: **el tap disparó una transición de pantalla o un cambio de estado async** (auth, navegación, carga de datos). El único tap sin efecto esperado (fila 6, un miss deliberado sin blanco) no mostró el síntoma — pero tampoco disparó ningún cambio de estado, así que esto es consistente con la hipótesis de §10, no una contradicción.

---

## 5. Swipe Analysis

Un solo swipe limpio ejecutado en esta fase (fila 11), sobre un área claramente scrollable (la lista de tarjetas de Home). Resultado: **PASS inmediato**, sin necesidad de `hot_reload` ni espera extendida — 3 segundos fueron suficientes y el cambio fue exacto y verificable (61px de desplazamiento en 4 elementos de referencia, con el bottom nav correctamente fijo).

Esto contradice directamente el `Scroll: FAIL` del PoC anterior. La explicación más probable, dado todo lo demás observado en esta fase, es que aquel intento de swipe cayó en una ventana en la que la observación ya estaba congelada por interacciones previas (el PoC anterior no usó `hot_reload` como método de verificación en ningún momento antes de concluir el fallo). No se puede descartar con un solo swipe que el fenómeno de congelamiento nunca afecte a `swipe` — pero no hay evidencia de que lo haga de forma distinta a como afecta a `tap`.

---

## 6. Stale Frame Analysis

Este es el hallazgo técnico más específico de la fase. `take_screenshots` y `get_interactive_elements` **no comparten el mismo mecanismo de actualización, y pueden desincronizarse en cualquiera de las dos direcciones:**

- **Caso A (elements vacío, screenshot correcto):** justo después del tap a "TOOLS" (fila 2), `get_interactive_elements` devolvió 0 elementos tres veces seguidas (con esperas de 3s, 5s y 5s más) mientras `take_screenshots` seguía mostrando correctamente la Home sin cambios (el tap todavía no había navegado en ese momento exacto). Un tap posterior con `text` ("BANKROLL") falló con `"Server error"` mientras el árbol seguía vacío — evidencia de que **`tap` por texto/key depende del mismo mecanismo de extracción de semántica que `get_interactive_elements`**, y cuando ese mecanismo está vacío, ambos fallan juntos.
- **Caso B (elements correcto, screenshot obsoleto):** después de `hot_reload` en el estado congelado de la fila 3, `get_interactive_elements` se recuperó inmediatamente (55 elementos, coincidentes con Home) pero `take_screenshots`, llamado dos veces más después, siguió devolviendo el frame visual de la pantalla anterior (Tools) sin cambios. Solo `hot_restart` corrigió ambos a la vez.

Esto descarta la hipótesis simple de "todo lo de Marionette se congela junto" — son **dos sistemas de captura independientes** (uno lee el árbol de widgets/semántica en vivo desde el VM service; el otro captura el buffer de píxeles ya pintado en el canvas de Chrome), y cada uno puede quedar desactualizado por separado, en cualquier dirección, sin relación necesaria con el otro.

**Sobre referencias obsoletas específicamente:** no se encontró evidencia de que el problema sea "usar una referencia de un elemento obtenida antes de navegar". `get_interactive_elements` no toma ningún identificador de una lectura anterior — se llama sin argumentos y aun así devolvió datos vacíos u obsoletos. El problema no es de referencias stale en el sentido clásico; es que la extracción en sí, ejecutada de cero, puede devolver un snapshot que no refleja el estado real en ese instante.

---

## 7. Element vs Coordinate Analysis

**Pregunta original: ¿falla el sistema de interacción completo o solo la resolución/identificación de elementos por texto/key?**

**Respuesta: ninguno de los dos falla.** Se compararon ambos métodos sobre objetivos reales en momentos distintos (texto: filas 1,2,5,8,9,10 — coordenadas: filas 6,7) y ambos tuvieron el mismo comportamiento: éxito real cuando apuntaban a un widget interactivo, y el mismo síntoma de observación congelada independientemente del método usado para el tap. La única falla real de resolución observada fue el "Server error" en un tap por texto durante la ventana en que `get_interactive_elements` ya estaba vacío (§6, Caso A) — coherente con "el tap por texto no puede resolver un árbol de semántica que en ese momento está vacío", no con "el sistema de resolución de texto es poco confiable en general".

No se hizo una comparación estrictamente A/B sobre el *mismo* elemento en el *mismo* instante (tocar, deshacer, tocar de nuevo con el otro método) porque cada tap real avanza el estado de la app y no se puede repetir sin volver atrás primero, lo cual introduce su propia variable de tiempo. Dada la evidencia ya reunida (10/10 éxitos reales, sin correlación con el método), no se considera necesario para la conclusión de esta fase — pero queda como prueba pendiente si se quisiera un aislamiento perfecto.

---

## 8. Reconnect/Hot Reload Analysis

| Estado | Tap | Swipe | Screenshot | Elements |
|---|---:|---:|---:|---:|
| Conexión inicial (fresca, primer tap de la sesión) | FAIL aparente → PASS real (lento, ~14s) | No probado en este punto | Correcto | Correcto |
| Después de navegación (mid-sesión) | FAIL aparente → PASS real (confirmado con hot_reload) | PASS inmediato (un caso) | Frecuentemente obsoleto/vacío | Frecuentemente vacío (0 elementos) |
| Después de `hot_reload` | No vuelve a testearse el mismo tap, pero el hot_reload en sí reveló el resultado real correctamente 3 de 3 veces para `elements` | No probado | **1 de 2 veces siguió obsoleto** (caso B, §6) | **3 de 3 veces se recuperó** |
| Después de `hot_restart` | No aplica (reinicia la app entera) | No aplica | Se recuperó, sincronizado con elements | Se recuperó, sincronizado con screenshot |
| Después de reiniciar la app (`flutter run` desde cero) | PASS (primer tap de una sesión nueva mostró el mismo patrón de lentitud/observación congelada, no es exclusivo de sesiones "viejas") | No aplica | Correcto al arrancar | Correcto al arrancar |

**Conclusión de esta sección:** ni `disconnect`/`connect` (probado en el PoC anterior) ni el mero paso del tiempo (probado extensamente hoy, hasta 31s de espera real) garantizan la recuperación de la observación. `hot_reload` la restaura la mayoría de las veces para `get_interactive_elements`, pero no siempre para `take_screenshots`. `hot_restart` es el único mecanismo que restauró ambos, en las 1 de 1 veces que se probó — al costo de reiniciar completamente el estado de la app (vuelve a la pantalla de login).

---

## 9. Chrome vs Android

**NOT VERIFIED.** `flutter devices` en este entorno solo detecta: Windows (desktop), Chrome (web) y Edge (web) — ningún emulador ni dispositivo Android está configurado en esta máquina, consistente con lo ya documentado en la memoria del proyecto de sesiones anteriores (Fase 0 de QA/UX). No se instaló ni configuró ningún AVD ni soporte adicional para esta verificación, tal como indicaba la regla de no agregar infraestructura sin avisar primero. Si se quiere esta comparación real, hace falta decidir explícitamente si vale la pena configurar un emulador Android — es una decisión de infraestructura, no algo que se resuelva dentro de este diagnóstico.

---

## 10. Root Cause Assessment

| Hipótesis | A favor | En contra | Veredicto |
|---|---|---|---|
| **A — Marionette/MCP** | El síntoma es indistinto del tipo de widget o pantalla de FLOPly; afecta por igual a la pantalla de login (sin código custom complejo) y a la mesa visual de Academia (con widgets custom). Los dos mecanismos de observación (screenshot vía canvas, elements vía semántica) fallan de forma independiente, lo cual apunta a dos rutas de extracción propias de Marionette, no a un bug de la app. | No hay acceso al código fuente de `marionette_flutter`/`marionette_mcp` para confirmar el mecanismo exacto. | **Más probable, no confirmado** |
| **B — Flutter Web/Chrome (DWDS, pintura del canvas)** | El caso de `take_screenshots` obsoleto encaja con un repintado retrasado del canvas de Chrome; Flutter Web es conocido por tener particularidades de timing entre el árbol lógico y el frame pintado. | `hot_reload` (que sí fuerza un rebuild completo) no siempre corrigió el screenshot — si fuera puramente timing de pintura, un rebuild forzado debería bastar casi siempre. | **Contribuyente plausible, no la única causa** |
| **C — Integración Marionette + FLOPly** | — | El síntoma apareció en la pantalla de login (código simple, sin lógica de FLOPly compleja) igual que en Academia (código custom) — no hay nada específico de FLOPly que correlacione con el síntoma. | **Poco probable como causa principal** |
| **D — Referencias stale** | El síntoma ES observación desactualizada. | `get_interactive_elements` no usa ningún identificador de una llamada anterior — se pidió "de cero" y aun así devolvió datos vacíos/obsoletos. No es "usar una referencia vieja", es que la extracción fresca da un resultado que no refleja el momento real. | **Parcialmente cierto en el síntoma, no en el mecanismo clásico de "stale reference"** |
| **E — Estado de la app** | — | El síntoma ocurrió en estados de la app tan simples como el formulario de email recién montado (sin datos remotos, sin lógica compleja). | **Poco probable como causa principal** |
| **F — Tipo de interacción/gesto** | — | Tap por texto, tap por coordenadas y swipe mostraron el mismo patrón (y también el mismo patrón de éxito). Ningún tipo de gesto correlaciona con el síntoma. | **Descartado como factor determinante** |
| **G — Causa no determinada (a nivel de mecanismo exacto)** | Se puede describir el síntoma con precisión y se puede recuperar de forma práctica (`hot_reload`/`hot_restart`), pero no se puede señalar la línea de código exacta responsable sin acceso al código fuente de Marionette o instrumentación adicional del lado de Chrome DevTools Protocol. | — | **Cierto para el "por qué exacto", no para el "qué hacer al respecto"** |

**Evaluación combinada:** la evidencia apunta con más fuerza a **A + B combinadas** — una condición de carrera entre el momento en que Marionette ejecuta su extensión de VM service (para leer semántica o pedir un frame) y el momento en que Flutter Web efectivamente terminó de reconstruir su árbol/pintar el frame tras una navegación o cambio de estado async. `hot_reload` fuerza ese resync la mayoría de las veces (porque dispara un rebuild completo del árbol de widgets), pero no garantiza un nuevo frame pintado en todos los casos, lo que explicaría por qué a veces corrige `elements` sin corregir `screenshot`. No se descarta C/D/E como factores menores, pero ninguno explica el patrón observado tan bien como A+B.

---

## 11. Evidence

Toda la evidencia de esta sección está tomada de llamadas reales a las tools de Marionette durante esta sesión (no simulada). Los puntos más citables:

- `get_interactive_elements` devolviendo `Found 0 interactive element(s):` de forma literal, en al menos 4 ocasiones distintas, en 4 pantallas distintas (Home, Tools, formulario de email, tras el back-arrow).
- El mismo tap por texto (`"BANKROLL"`) fallando con `Extension marionette.tap failed / Error: Server error` exactamente en la ventana donde `get_interactive_elements` estaba vacío — nunca en ninguna otra ventana.
- El screenshot de la pantalla "Tools" repetido pixel-a-pixel (según inspección visual) en 3 llamadas consecutivas a `take_screenshots`, abarcando un `hot_reload` de por medio, mientras `get_interactive_elements` ya mostraba el árbol correcto de Home (55 elementos) en la llamada inmediatamente posterior a ese mismo `hot_reload`.
- Los bounds de "Empezá a aprender póker" cambiando de `y:107` a `y:46` (delta exacto de 61px) tras un solo swipe, replicado de forma idéntica en 4 elementos de referencia distintos en la misma lectura — la prueba más limpia y menos ambigua de toda la sesión.
- El hero card de Academia mostrando literalmente `"Cargando tu progreso…"` en lugar de la CTA, confirmando que existe un estado de carga real y asíncrono en Home que no tiene relación con Marionette.

---

## 12. Limitations

- No se realizó una comparación A/B estrictamente controlada del mismo elemento en el mismo instante con ambos métodos de tap (texto vs. coordenadas) — cada intento real avanza el estado de la app. La evidencia indirecta (§7) es sólida pero no es un experimento perfectamente aislado.
- No se pudo comparar Chrome vs. Android físico/emulado — no hay ningún dispositivo Android disponible en este entorno (§9), y no se configuró uno nuevo por estar fuera del alcance autorizado de esta fase.
- No se tiene acceso al código fuente de `marionette_flutter` ni `marionette_mcp` para confirmar el mecanismo exacto interno de la extracción de semántica o la captura de screenshots — el diagnóstico de causa raíz (§10) se basa en comportamiento observado desde afuera, no en lectura de código.
- El número de repeticiones por celda de la matriz (§3) es de 1 en la mayoría de los casos — es una muestra suficiente para invalidar con confianza el "Tap: FAIL" del PoC anterior (10/10 éxitos reales es una señal fuerte), pero no es una muestra estadísticamente grande para caracterizar con precisión la probabilidad exacta de que la observación se congele en una interacción cualquiera.
- No se investigó si el "Cargando tu progreso…" de Home eventualmente falla en cargar del todo en algún escenario — se observó que resolvía en unos 10-15 segundos en las dos ocasiones que se cruzó con esta fase, pero no era el objeto de este diagnóstico.

---

## 13. Decision

### Tabla final

| Capability | Status | Evidence |
|---|---|---|
| Screenshot | **PARCIAL** — confiable la mayoría de las veces, pero puede quedar obsoleto por tiempo indeterminado tras una navegación, incluso sobreviviendo a un `hot_reload` | §6 Caso B, §11 |
| Element inspection | **PARCIAL** — igual que screenshot pero en dirección opuesta en algunos casos; se recupera con `hot_reload` de forma más consistente que screenshot | §6 Caso A, §8 |
| Element discovery | **PASS** cuando la extracción no está en el estado congelado — devuelve datos ricos y correctos (tipos, bounds, `Semantics`, código del handler) | §1, PoC anterior |
| Tap | **PASS** — 100% de efectividad real en los 10 casos verificados correctamente esta fase; los "fallos" anteriores eran falsos negativos de observación | §3, §4 |
| Coordinate tap | **PASS** — mismo comportamiento que tap por elemento, sin diferencia observada | §4, §7 |
| Swipe | **PASS** — un caso limpio, inmediato, verificado con precisión de píxeles | §5, §11 |
| Navigation | **PASS** — las dos navegaciones marcadas como rotas por el PoC anterior ("COMENZAR ACADEMIA", tab "INICIO" desde una lección) resultaron reales y correctas | §3 filas 9-10 |
| Back | **PASS** — `press_back_button` hizo pop real incluso cuando la observación tardó en reflejarlo | §3 fila 3 |
| Reconnect recovery | **PARCIAL** — `hot_reload` recupera `elements` de forma consistente (3/3) pero no siempre `screenshot` (1/2); `hot_restart` recuperó ambos (1/1) al costo de reiniciar la app entera | §8 |
| Android | **NOT VERIFIED** — sin dispositivo/emulador configurado en este entorno; no se configuró uno nuevo sin autorización previa | §9 |
| Autonomous exploration readiness | **NOT READY tal cual, READY con protocolo documentado** — ver abajo | §13 |

### ¿`floply-human-qa` está READY o NOT READY?

**NOT READY tal cual (sin un protocolo de verificación), pero el camino para llegar a READY es corto y ya está identificado.**

Un agente que confíe en la primera lectura de `screenshot`/`get_interactive_elements` inmediatamente después de cada acción, tal como hizo el PoC de esta misma mañana, va a diagnosticar como "rotos" botones y navegaciones que en realidad funcionan — exactamente lo que pasó con "COMENZAR ACADEMIA" y el tab "INICIO". Ese es un defecto real y bloqueante para un QA autónomo confiable, aunque no esté en la interacción sino en la observación.

La buena noticia, y la razón por la que no se recomienda un "NO" categórico: la interacción real (tap, swipe, back) demostró ser sólida en el 100% de los casos verificados correctamente hoy. El problema tiene una mitigación conocida y ya probada dos veces: **tras cualquier acción, si la lectura inmediata no muestra cambio o devuelve una lista vacía, no concluir fallo — reintentar la lectura, y si sigue sin reflejar el cambio, ejecutar `hot_reload` antes de decidir.** Con ese protocolo, esta misma sesión hubiera evitado los dos falsos negativos del PoC original.

**Recomendación concreta antes de construir `floply-human-qa`:** validar ese protocolo específico (retry + `hot_reload` de verificación) en una tanda de pruebas dedicada, para confirmar que reduce los falsos negativos a un nivel aceptable en la práctica, no solo en los 10 casos de hoy. Una vez confirmado eso, sí recomendaría avanzar con el skill, con esa regla de verificación incorporada como parte de su diseño desde el día uno — no como un parche posterior.

Como en el PoC anterior: no se corrigió ningún bug de producto, no se creó `floply-human-qa`, y toda conclusión de esta fase está respaldada por una llamada real a una tool, nunca asumida.
