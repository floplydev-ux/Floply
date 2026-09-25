# Marionette PoC — FLOPly

**Fecha:** 2026-09-19. **Resultado: infraestructura verificada de punta a punta salvo un paso — no se pudo ejecutar TEST 1-4 en esta sesión** (ver §5-7). No es un fallo de Marionette ni de FLOPly: es que un servidor MCP recién registrado necesita que la sesión de Claude Code se reconecte para cargar su lista de tools, y esta sesión no se reinició. Nada se simuló ni se inventó — donde no pude verificar algo en vivo, lo digo explícitamente.

## 1. Compatibilidad

- **Flutter:** 3.47.2 (proyecto) — Marionette pide `>=3.27.0` ✓
- **Dart:** 3.13.2 (proyecto) — Marionette pide `>=3.6.0` ✓
- **Android:** no aplica a este PoC (sin emulador/dispositivo configurado, ver Fase 0) — se usó Web en su lugar, plataforma soportada oficialmente por `marionette_flutter` (Android/iOS/Linux/macOS/**Web**/Windows)
- **Dispositivo utilizado:** Chrome, vía `flutter run -d chrome --web-port=8765`, modo debug real

## 2. Instalación

- `marionette_flutter: ^0.6.0` — dependencia normal (no dev), `pubspec.yaml`. `flutter pub get`: sin conflictos.
- `marionette_mcp 0.6.0` — CLI global, `dart pub global activate marionette_mcp` (fuera del repo, en el PubCache de la máquina).

## 3. Configuración

Un solo archivo modificado: `lib/main.dart`. El binding de Marionette se inicializa **solo en debug**:
```dart
if (kDebugMode) {
  MarionetteBinding.ensureInitialized();
} else {
  WidgetsFlutterBinding.ensureInitialized();
}
```
En release, el comportamiento es idéntico al de antes — cero riesgo de que esto llegue a producción.

MCP server registrado en Claude Code (config local del proyecto, `.claude.json`):
```
claude mcp add --transport stdio marionette -- "D:/Proyectos/_toolcache/PubCache/bin/marionette_mcp.bat"
```
`claude mcp list` confirma: **`marionette: ... ✔ Connected`**.

## 4. Conexión

1. `flutter run -d chrome --web-port=8765` (modo debug) — **corrida realmente, no simulada**. Log real:
   ```
   Debug service listening on ws://127.0.0.1:63662/cK4RNTz96fI=/ws
   A Dart VM Service on Chrome is available at: http://127.0.0.1:63662/cK4RNTz96fI=
   ```
2. Un agente con las tools de Marionette cargadas llamaría a `connect` con esa URI `ws://...`.
3. **Acá es donde se cortó**: las tools de Marionette (`connect`, `tap`, `get_interactive_elements`, etc.) no aparecen todavía en esta sesión — confirmado con `ToolSearch` (dos búsquedas, una genérica y una por nombre exacto de cada tool, cero resultados), aunque el servidor MCP en sí está `✔ Connected` según `claude mcp list`. Un servidor MCP agregado a mitad de sesión no actualiza automáticamente la lista de tools disponibles de la sesión ya abierta — hace falta reconectar/reiniciar.

## 5. Capacidades verificadas

| Capacidad | Resultado |
|---|---|
| Screenshot | **NO VERIFICADO** (bloqueado por §4) |
| Widget tree | **NO VERIFICADO** |
| Semantics | **NO VERIFICADO** |
| Tap | **NO VERIFICADO** |
| Scroll | **NO VERIFICADO** |
| Navigation | **NO VERIFICADO** |
| Back | **NO VERIFICADO** |
| App real corriendo en debug con el binding activo | **PASS** — verificado con el log real de `flutter run` de arriba |
| MCP server registrado y alcanzable por Claude Code | **PASS** — `claude mcp list` |
| Setup no rompe FLOPly | **PASS** — ver §11 |

No marco ninguna fila de la tabla original como PASS sin haberla visto correr — siete de las diez quedan honestamente sin verificar.

## 6. Tests realizados

**Home / Interacción / Scroll / Back: NINGUNO ejecutado.** Requieren las tools de Marionette activas en la sesión, que no cargaron (§4). No se leyó el código de Home para este PoC en ningún momento — la instrucción de "observar antes de leer código" quedó sin poder cumplirse porque nunca hubo una `screenshot` real que observar.

## 7. Limitaciones

- **La real, específica de hoy:** un MCP server agregado con `claude mcp add` durante una sesión en curso no queda disponible para esa misma sesión — necesita reconexión/reinicio. Esto es de Claude Code, no de Marionette.
- Documentación oficial de Marionette no especifica explícitamente compatibilidad con Android físico/emulador más allá de listar la plataforma "Android" en pub.dev — no se pudo confirmar en la práctica porque no hay ningún dispositivo/emulador Android configurado en este entorno (mismo hallazgo de Fase 0).
- El `flutter run` de Chrome quedó corriendo en background (puerto 8765) para no perder el punto de partida — si la sesión se reinicia y ese proceso ya no está vivo, hay que volver a correr el comando de §4.

## 8. Impacto sobre el proyecto

Mínimo y reversible: 1 dependencia nueva (usada solo en debug), 6 líneas en `main.dart` dentro de un `if (kDebugMode)`. `flutter analyze`: 0 issues. Suite completa: **972/972, sin regresiones** (ver §11). Nada de UX/UI/currículo/navegación tocado, como pedía la regla.

## 9. ¿Es viable construir `floply-human-qa` sobre esto?

**PARCIAL.** Todo lo que depende de FLOPly y de la instrumentación (paquete, binding, compatibilidad de versión, plataforma Web, que la app realmente exponga una VM service URI en debug) está confirmado y funciona. Lo único que falta confirmar es la parte más simple de todas — que las tools respondan una vez la sesión las tenga cargadas — y eso no es una incógnita técnica, es un reinicio de sesión. No recomiendo diseñar `floply-human-qa` todavía porque el criterio de éxito que vos mismo definiste (interactuar de verdad: tap, scroll, navegar, volver) sigue sin un solo caso probado. Con una sesión que ya tenga las tools cargadas, este mismo PoC probablemente se cierra en minutos.

## 10. Archivos modificados

- `pubspec.yaml` — agregada `marionette_flutter: ^0.6.0`
- `pubspec.lock` — regenerado por `flutter pub get`
- `lib/main.dart` — binding condicional a `kDebugMode`
- Config local de Claude Code (`.claude.json`, fuera del repo de FLOPly) — servidor `marionette` registrado
- Este documento (`MARIONETTE_POC_2026-09-19.md`)

## 11. Validación

| Check | Resultado |
|---|---|
| `flutter analyze` | ✅ 0 issues |
| `flutter test --concurrency=1` | ✅ 972/972, sin regresiones |
| `flutter run -d chrome` (debug real) | ✅ arrancó, VM service expuesto |
| MCP server `marionette` | ✅ `claude mcp list` → Connected |
| Tools de Marionette disponibles en esta sesión | ❌ requieren reconexión de sesión |

---

**Próximo paso real, no decidido acá:** reconectar/reiniciar la sesión de Claude Code para que las tools de `marionette` carguen, y recién ahí correr TEST 1-4 tal cual los pediste. No avancé con `floply-human-qa` ni con ningún cambio de UX/UI, como indicaba la regla final.

---

# Continuación — sesión reconectada, TESTs 1-6 ejecutados (mismo día)

La sesión se reconectó y las 19 tools de `marionette` (`connect`, `take_screenshots`, `tap`, `get_interactive_elements`, `scroll_to`, `swipe`, `press_back_button`, `hot_reload`, `hot_restart`, `get_logs`, `disconnect`, `enter_text`, `long_press`, `double_tap`, `secondary_tap`, `pinch_zoom`, `press_key`, `list_custom_extensions`, `call_custom_extension`) cargaron correctamente — confirmado con `ToolSearch`, no con suposición de nombres.

## PASO 1 — Verificación MCP

**PASS.** Las 19 tools están disponibles con schema completo. Cubren y superan lo pedido: `connect`, `take_screenshots`, `tap`, `get_interactive_elements`, `scroll_to`/`swipe`, `press_back_button`, inspección de widgets/semántica (dentro de `get_interactive_elements`, que también expone nodos `Semantics` explícitos, no solo widgets).

## PASO 2 — Conectar FLOPly

El proceso de `flutter run -d chrome --web-port=8765` de la sesión anterior ya no estaba vivo (ni el puerto 8765 ni el VM service de esa sesión aparecían en `netstat`). Se relanzó tal como está documentado en este mismo archivo (§4).

**Primer intento real:** arrancó, VM service expuesto (`ws://127.0.0.1:52306/...`), pero el arranque de la app falló con un error real de red del lado de Chrome:
```
TypeError: Failed to fetch dynamically imported module: https://www.gstatic.com/firebasejs/12.19.0/firebase-app.js
```
`curl` desde esta misma máquina SÍ llegaba a esa URL (HTTP 200) — la falla es específica del proceso Chrome lanzado por `flutter run`, no de la red del host en general. `connect` de Marionette funcionó igual (isolate vivo), pero `get_interactive_elements` devolvió 0 elementos y `take_screenshots` no devolvió nada — la app nunca llegó a `runApp()`. `hot_restart` también falló, con una excepción real a nivel DWDS/Chrome DevTools (no simulada, stack trace completo capturado).

**Segundo intento (kill + relanzamiento limpio):** esta vez arrancó sin el error de Firebase y la app renderizó normalmente. No se identificó la causa raíz exacta (parece flakiness de red intermitente específica de ese proceso Chrome, no reproducida en el segundo intento) — se documenta como hallazgo de entorno, no de Marionette ni de FLOPly.

**PASS** (tras el segundo intento): conexión exitosa, app identificada (FLOPly, pantalla de login/auth), inspección posible.

## TEST 1 — Observar Home (y pantalla de auth previa)

La primera pantalla real no es Home: es una pantalla de autenticación ("Continuar con Google" / "Continuar con Apple" / "Continuar con email" / "Continuar sin cuenta"). Se avanzó con "Continuar sin cuenta" (acción de invitado) para llegar a Home.

Una vez en Home, `get_interactive_elements` devolvió 55 elementos que coinciden 1:1 con el screenshot: header ("Hola, Juan", ícono de engranaje), tarjeta hero de progreso de Academia (Nivel 1, 0%, botón "COMENZAR ACADEMIA"), sección "SEGUÍ EXPLORANDO" con tarjetas Practice Room / Bankroll / Tools / Coach, bottom nav de 5 tabs (Inicio/Academia/Laboratorio/Estadísticas/Perfil) y un FAB morado.

**Hallazgos reales (no corregidos):**
- El ícono de engranaje (⚙) junto a "Hola, Juan" tiene la etiqueta de accesibilidad **"Abrir tu perfil"** — un engranaje comunica "ajustes/settings" a un usuario, no "perfil". Es una etiqueta semántica potencialmente confusa frente a la señal visual del ícono (hallazgo de accesibilidad/UX real, tomado directamente del nodo `Semantics`, no inferido).
- Los íconos de Practice Room, Bankroll, Tools, Coach (los `RichText` dentro de cada tarjeta) no tienen ningún nodo `Semantics` propio — solo el texto del título de la tarjeta sería anunciado por un lector de pantalla, no el ícono.
- El FAB tiene tooltip real **"Ayuda rápida"** y su handler llama a `showTableModeSheet` — dato tomado directamente del código compilado (`onPressed`), no de documentación previa.
- Las 4 tarjetas de "SEGUÍ EXPLORANDO" son áreas de tap grandes y consistentes (324×89), sin ambigüedad de hit-target.
- La CTA dominante y visualmente más grande de toda la pantalla es "COMENZAR ACADEMIA" — coincide con lo esperado para TEST 5.

## TEST 2 — Navegación real

- Home → Tools (tap real en la tarjeta "TOOLS"): **funcionó**, navegó a una lista real de calculadoras (Pot Odds, Equity, EV, Combos, Rangos, Blockers), consistente con lo prometido por la tarjeta.
- Tools → Home (`press_back_button`): **funcionó**, `"route was popped"`, confirmado con screenshot e inspección posteriores (con un matiz de timing, ver Limitaciones).
- Home → Academia (tap en el tab inferior "ACADEMIA", no en el botón "COMENZAR ACADEMIA"): **funcionó**, navegó a la lección real "1.1 · El objetivo y las cartas" con la mesa visual de 6 jugadores (piloto mesa+burbuja mencionado en memoria de proyecto).
- Home → Academia (tap en el botón **"COMENZAR ACADEMIA"**, la CTA dominante de toda la Home): **NO funcionó, de forma reproducible.** Se probó por texto y por coordenadas, dos veces cada uno (incluyendo una reconexión limpia de Marionette entre medio), con esperas de hasta 8s. Cero navegación, cero cambio de estado verificado tanto por screenshot como por `get_interactive_elements` (que devolvía el árbol idéntico, no solo el pixel buffer). Este es el hallazgo funcional más importante de la sesión.
- Home → Bankroll (tap en la tarjeta "BANKROLL", tras la reconexión): tampoco navegó.

## TEST 3 — Scroll real

Un `swipe` vertical en Home (para revelar la tarjeta "Coach" completa y lo que hay debajo) **no produjo ningún cambio** — ni en el screenshot ni en `get_interactive_elements` (mismos 55 elementos, mismos bounds exactos). Este intento coincidió temporalmente con la ventana en la que los taps ya habían dejado de responder (ver TEST 6), así que no se puede aislar si es un problema específico de `swipe` o el mismo problema general de entrega de gestos.

## TEST 4 — Back real

- `press_back_button` en Tools: **funcionó**, pop real confirmado.
- `press_back_button` estando en la lección de Academia: devolvió `"no route to pop (app may exit)"` — una respuesta honesta y arquitectónicamente coherente (la lección vive dentro del mismo `IndexedStack` raíz, no es una ruta empujada con `Navigator.push`), no un fallo de la tool.
- La flecha de "volver" dibujada dentro de la propia pantalla de lección (arriba a la izquierda) no produjo ningún efecto al tocarla — mismo patrón que TEST 6.

## TEST 5 — Descubrimiento

- Existe una acción dominante clara en Home ("COMENZAR ACADEMIA"), pero **está rota** — un usuario nuevo haría exactamente lo que se espera de él y no pasaría nada, sin ningún error visible ni feedback. Esto es un hallazgo de descubrimiento crítico: la ruta "obvia" no funciona; la ruta real que sí funciona (tab inferior "Academia") es igual de visible así que no se pierde la función, pero el botón roto sí genera una fricción real de primera impresión.
- Bankroll, Tools son perfectamente descubribles desde Home (tarjetas con título, ícono y descripción).
- Laboratorio, Estadísticas y Perfil son descubribles solo por el bottom nav (nombres explícitos, sin ambigüedad).
- Settings no tiene una entrada propia visible en Home ni en el bottom nav — solo el ícono de engranaje arriba a la derecha, cuya etiqueta de accesibilidad dice "Abrir tu perfil" en lugar de algo relacionado a ajustes. Sin haber leído código, no se puede afirmar con certeza si ese ícono abre Settings, Perfil, o ambos combinados.

## TEST 6 — Acciones posiblemente faltantes / hallazgo de fiabilidad de gestos

Este fue el hallazgo transversal más importante de la sesión. Cronología exacta de gestos, en orden:

| # | Acción | Método | Resultado |
|---|---|---|---|
| 1 | "Continuar sin cuenta" | tap por texto | Sin efecto inmediato (resultó async, ver más abajo) |
| 2 | Tarjeta "Tools" en Home (sin saberlo aún) | tap por coordenadas | **Funcionó** — reveló que #1 sí había navegado a Home, y el tap por coordenadas cayó sobre "Tools" |
| 3 | `press_back_button` | tool | **Funcionó** |
| 4 | Tarjeta "POT ODDS" en Tools | tap por texto | **Falló** ("Server error") — coincidió con un screenshot obsoleto (ver Limitaciones) |
| 5 | Tab "ACADEMIA" | tap por texto | **Funcionó** |
| 6 | "COMENZAR ACADEMIA" | tap por texto | Falló |
| 7 | "COMENZAR ACADEMIA" | tap por coordenadas | Falló |
| 8 | Tab "ACADEMIA" (desde Home) | tap por texto | **Funcionó** |
| 9 | Tab "INICIO" (desde la lección) | tap por texto | Falló |
| 10 | Tab "INICIO" (desde la lección) | tap por coordenadas | Falló |
| 11 | Flecha "volver" de la lección | tap por coordenadas | Falló |
| 12 | Botón "CONTINUAR" de la lección | tap por texto | Falló |
| 13 | `hot_reload` | tool | **Funcionó** (reseteó a Home limpio) |
| 14 | `swipe` vertical en Home | tool | Falló |
| 15 | `disconnect` + `connect` (reconexión limpia) | tool | **Funcionó** (la reconexión en sí) |
| 16 | "COMENZAR ACADEMIA" tras reconexión | tap por texto | Falló |
| 17 | "BANKROLL" tras reconexión | tap por texto | Falló |

Patrón real, verificado con `get_interactive_elements` (no solo con el pixel buffer, que podía estar obsoleto): los gestos (`tap`, `swipe`) funcionan de forma confiable solo en una ventana corta al principio de la sesión de conexión, y luego se degradan hasta dejar de tener efecto — ni `hot_reload` ni un `disconnect`/`connect` limpio lo revirtieron dentro de esta sesión. Las llamadas de solo lectura (`take_screenshots`, `get_interactive_elements`) siguieron funcionando y devolviendo datos consistentes entre sí durante todo el proceso, incluso cuando los gestos ya no tenían ningún efecto.

No se pudo completar la exploración de "qué pasa después de completar una lección" (avanzar de PASO 1 a 2 con "CONTINUAR") porque el botón dejó de responder antes de poder probarlo.

---

# Marionette PoC — Resultado real (informe final de la continuación)

## Conectividad
**PASS.** `connect`/`disconnect`/reconexión funcionaron siempre que se probaron, contra una VM service real de una app real corriendo en Chrome debug.

## Screenshot
**PASS**, con un hallazgo real: en al menos una ocasión, dos llamadas consecutivas a `take_screenshots` justo después de un `press_back_button` devolvieron un frame obsoleto (mostraban la pantalla anterior a la navegación real, confirmada luego por un tercer screenshot y por `get_interactive_elements`). No fue un fallo total, sí una fuente real de falsos negativos si no se re-confirma con una segunda lectura.

## Element inspection
**PASS.** Devuelve árbol real con tipos de widget, texto, color, tamaño, bounds y nodos `Semantics` explícitos cuando existen. Coincidió con el screenshot en cada caso salvo el mencionado arriba.

## Interactive elements
**PASS.** El más confiable de todos los mecanismos probados — nunca devolvió datos inconsistentes consigo mismo, ni siquiera durante la ventana en la que los gestos habían dejado de funcionar.

## Tap
**FAIL** (como estado dominante de la sesión, con éxitos reales y aislados al principio — ver tabla de TEST 6). No se debe reportar como PASS: de 12 intentos de tap tras los dos primeros minutos de conexión, 0 tuvieron efecto.

## Scroll
**FAIL** (un solo intento real, con `swipe`, sin efecto — ver limitación de confusión con el problema general de TEST 6).

## Navigation
**PARCIAL.** Home↔Tools y Home→Academia (vía tab) funcionaron y fueron confirmados con screenshot + inspección. Home→Academia (vía CTA), Academia→Home (vía tab inferior o flecha propia de la pantalla) fallaron de forma reproducible.

## Back
**PASS.** `press_back_button` hizo pop real cuando había una ruta que popear, e informó correctamente "no route to pop" cuando no la había — ambos son resultados correctos, no fallos.

## Discovery test
**PASS** (como ejercicio — se completó y arrojó hallazgos reales, ver arriba). El hallazgo de UX es el que importa, no si "salió bien".

---

# Hallazgos observados

### Funcionales
- El botón **"COMENZAR ACADEMIA"** en Home (la CTA hero, visualmente la más prominente de toda la pantalla) no dispara ninguna navegación ni efecto visible, en 4 intentos reales por 2 métodos distintos, incluida una reconexión completa de sesión entre medio. No se puede afirmar con la evidencia disponible si la causa es un bug real en FLOPly o un problema de entrega de eventos específico de este entorno (Chrome+DWDS) — ver Limitaciones — pero el síntoma observable es 100% real y reproducible dentro de esta sesión.
- Después de cierto punto de la sesión (ver tabla TEST 6), **ningún** gesto de tap/swipe volvió a tener efecto sobre ninguna pantalla, incluyendo elementos que antes sí habían respondido (tabs del bottom nav).

### UX
- La CTA más visible de Home no funciona → un usuario nuevo que sigue la señal visual más obvia de la pantalla no llega a ningún lado, sin mensaje de error.
- El FAB "Ayuda rápida" (mesa/table mode) se superpone visualmente al botón "CONTINUAR" en la pantalla de lección, tapando parcialmente su texto ("CONTINUA" en vez de "CONTINUAR" en el screenshot).
- Settings no tiene una entrada nombrada explícitamente en ningún lugar visible; depende enteramente de reconocer un ícono de engranaje.

### UI
- Colisión visual real entre el FAB flotante y el botón "CONTINUAR" en la pantalla de lección (ver captura).

### Accessibility
- El ícono de settings/engranaje tiene `Semantics(label: "Abrir tu perfil")` — la etiqueta que un lector de pantalla anunciaría no coincide con la señal visual (engranaje = ajustes) ni necesariamente con el destino real.
- Los íconos de las 4 tarjetas de "Seguí explorando" no tienen `Semantics` propio — solo el título de texto sería anunciado.

### Navegación
- La lección de Academia vive dentro del mismo `IndexedStack` raíz (no es una ruta empujada), confirmado por la respuesta real de `press_back_button` ("no route to pop").
- Existen (al menos) dos caminos distintos a la misma lección de Academia (CTA de Home y tab inferior) con fiabilidad muy distinta entre ellos.

### Acciones posiblemente faltantes
No se pudo verificar con evidencia suficiente qué pasa al completar los 8 pasos de una lección (avanzar con "CONTINUAR"), porque el botón dejó de responder antes de poder probarlo dos veces seguidas. **NO VERIFICADO**, no se reporta como hallazgo confirmado.

---

# CAPACIDADES

Lo que Marionette demostradamente puede hacer sobre FLOPly, con evidencia real de esta sesión:
- Conectarse a una instancia real de FLOPly corriendo en Chrome debug (`flutter run -d chrome`).
- Tomar screenshots reales del estado visual actual.
- Inspeccionar el árbol de widgets con detalle (tipo, texto, color, tamaño, bounds) y nodos de accesibilidad explícitos (`Semantics`) cuando el código los define.
- Ejecutar taps, tanto por texto/key como por coordenadas — **cuando la entrega de gestos está funcionando** (ventana inicial de la sesión).
- Hacer pop de rutas reales con `press_back_button`, con respuestas honestas cuando no hay nada que popear.
- Disparar `hot_reload` con éxito y ver el resultado reflejado inmediatamente.
- Reconectar (`disconnect`/`connect`) de forma limpia.

# LIMITACIONES

- **La más importante:** la entrega de gestos (`tap`, `swipe`) se degrada y deja de tener efecto después de un número relativamente bajo de interacciones dentro de la misma sesión de conexión, sin que `hot_reload` ni una reconexión completa lo resuelvan. No se identificó la causa raíz exacta (podría ser DWDS, el propio Chrome lanzado por `flutter run`, o el puente VM-service↔widget del binding de Marionette) — se documenta el síntoma, no se inventa la causa.
- `get_logs` devolvió **"Server error"** en las 3 ocasiones en que se intentó usar, en distintos momentos de la sesión (app funcionando normalmente y app en estado degradado) — no se pudo usar ni una sola vez para diagnosticar nada.
- `take_screenshots` puede devolver un frame obsoleto inmediatamente después de una navegación real (mitigable esperando y volviendo a pedir un segundo screenshot, o cruzando con `get_interactive_elements`).
- `hot_restart` falló con una excepción real a nivel DWDS/Chrome DevTools la única vez que se probó (durante el episodio de arranque fallido por el error de Firebase) — no se volvió a intentar en un estado sano de la app, así que no se puede afirmar si es confiable en general.
- El arranque de la propia app (no de Marionette) mostró una falla de red intermitente y no reproducible de forma determinística (fetch del SDK de Firebase desde Chrome) — limitación de entorno, no de Marionette.

# CONCLUSIÓN

### ¿Podemos construir `floply-human-qa` sobre Marionette?

**PARCIAL.**

Lo que funciona de forma sólida y repetible es exactamente la mitad de "ojos y manos" que se necesita: los "ojos" (`take_screenshots` + `get_interactive_elements`) son confiables, ricos en detalle (incluyen accesibilidad real, no solo geometría) y — el dato más importante — **nunca mintieron**: cuando algo no había cambiado, lo reportaron sin cambios, de forma consistente entre sí, incluso cuando el resto del sistema estaba fallando. Eso ya es suficiente para construir una herramienta de *observación* automatizada (capturar estado, comparar contra lo esperado, detectar regresiones visuales/estructurales) sin ningún human-in-the-loop.

Las "manos" (`tap`, `swipe`) son el problema real: funcionaron de forma correcta y verificable al principio de la sesión, y después dejaron de tener efecto de forma sostenida, sin que ninguna de las dos herramientas de recuperación disponibles (`hot_reload`, reconexión completa) lo solucionara. Un QA humano real no tropieza con esto — puede simplemente volver a hacer click. Un agente que dependa de Marionette para *actuar* (no solo para observar) se quedaría bloqueado en el mismo punto en el que yo me quedé bloqueado hoy, sin ningún mecanismo de recuperación identificado dentro de esta sesión.

No recomiendo construir `floply-human-qa` todavía asumiendo que la parte de interacción es confiable — lo es solo parcialmente y de forma no reproducible a demanda. Si se decide avanzar, lo haría primero como una herramienta de *observación/regresión visual y estructural* (donde hoy ya hay evidencia sólida de que funciona), dejando la automatización de interacciones complejas (flujos multi-paso) para después de entender la causa raíz de la degradación de gestos — que no se investigó a fondo hoy porque excedía el alcance de este PoC y el pedido explícito de "no corrijas nada".

Independientemente de Marionette, el hallazgo funcional más urgente para el equipo de FLOPly es el botón **"COMENZAR ACADEMIA"** de Home: es la acción más visible de toda la app para un usuario nuevo y, en esta sesión, no hizo nada.
