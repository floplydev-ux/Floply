# Auditoría completa — Floply (poker_trainer)
**Fecha:** 2026-09-12
**Alcance:** taller de diseño (control total) + auditoría de todo el proyecto (tests, código, contenido).
**Estado del repo:** rama `main`, HEAD en el tag `v0.2.0` (`9656fff`). Todo lo descrito abajo sigue **sin commitear**, tal como se viene trabajando toda la sesión.

---

## 1. Resumen ejecutivo

| Área | Resultado |
|---|---|
| `flutter analyze` (proyecto completo) | ✅ 0 issues |
| `flutter test --concurrency=1` (proyecto completo) | ✅ 254/254 |
| `dart format` | ⚠️ 101 de 160 archivos tienen diffs de formato (ver §4.1) — no aplicado |
| Higiene del repo | 🔧 3 archivos de debug sueltos en la raíz — **borrados** |
| Bugs reales encontrados | 2 — **ambos corregidos** (ver §3) |
| Contenido (326 teorías) | ✅ estructuralmente sano, sin errores factuales en la muestra revisada |
| Taller · control total | ✅ implementado (editor de contenido + ~20 controles nuevos de color/opacidad) |

No se rompió nada: los 254 tests son los mismos que ya pasaban antes de esta sesión de auditoría, más las correcciones descritas abajo.

---

## 2. Taller Mesa Academia — control total

URL (sin cambios): https://claude.ai/code/artifact/3f9d46d9-1c0d-4c98-ae75-bd2c4858ed0a

### 2.1 Editor de contenido (lo que faltaba)

Antes, las cartas/nombres/stacks/apuestas de cada paso venían fijas en `theorySnapshot()`/`exerciseSnapshot()` — no había forma de probar una combinación distinta sin editar código. Ahora hay una sección **"Contenido de la mesa"** (arriba de todo, abierta por default) con, por cada uno de los 6 asientos:

- Nombre, posición (BTN/SB/BB/UTG/HJ/CO), stack (BB), cartas (código de 2 caracteres, ej. `Ah`, o `?` para dorso), apuesta (BB).
- Foldeado / En turno / Ganador (toggles).

Más, a nivel mesa: board (hasta 5 cartas), bote (BB), asiento del dealer.

Cada campo vacío usa lo que trae el guion del paso actual (el "guion" no se toca); cualquier campo cargado queda fijo en todos los pasos hasta que se borra (botón "Restablecer contenido"). Probado en vivo: cambié cartas/nombre/stack/apuesta/ganador de un asiento y el board completo — todo se renderizó correctamente y en el lugar correcto.

### 2.2 Color/opacidad — huecos que quedaban sin control

Se agregaron ~20 controles nuevos que antes eran valores fijos en el HTML/CSS:

- **Cartas:** color de cara (arriba/abajo del degradé), rojo y negro del palo.
- **Avatares:** color 1 y 2 de los rivales (antes hardcodeado, ahora vive junto al resto de colores).
- **Panel de jugador:** color + opacidad del fondo normal y del fondo "ganador" por separado; opacidad del fondo y del borde de la marca de ganador; opacidad de las cartas de un rival foldeado.

Con esto, el taller ahora cubre prácticamente todo lo que se ve en pantalla: posición/tamaño/color/opacidad de paño, riel, cartas, fichas, panel, avatar, dealer, bote, board, burbuja educativa, botones y encabezado — más de 130 constantes con slider, todas con su descripción.

### 2.3 Bug real encontrado al cruzar valores (ver §3.1)

Al portar los colores de las cartas a constantes, se detectó que el rojo que usaba el taller (`#C43A3A`) **no coincidía** con el rojo real de la app (`#D63A3A`, `_TableMaterial.cardRed`). Era un valor que había quedado hardcodeado desde antes de que el taller tuviera este sistema de constantes, nunca se había cruzado contra el original. **Corregido.**

### 2.4 Qué queda deliberadamente fuera

No se agregó control para detalles de renderizado muy finos que no son decisiones de diseño (radio de blur de una sombra de 2px, ángulo exacto del brillo de una ficha, espaciado de la grilla de puntos del paño). Si en algún momento se necesita tocar alguno de esos, es una constante más para agregar — el patrón ya está establecido y es mecánico.

---

## 3. Bugs encontrados y corregidos

### 3.1 Taller: rojo de cartas no coincidía con la app real
**Archivo:** taller (artifact), constante `cardRed`.
**Antes:** `#C43A3A`. **Real (`_TableMaterial.cardRed`):** `#D63A3A`.
**Corregido:** valor actualizado para que el taller muestre el color real.

### 3.2 Documentación desactualizada en `TableLayout` (poker_table_view.dart)
**Archivo:** `lib/screens/academy/widgets/poker_table_view.dart`, docstring de la clase `TableLayout`.
**El problema:** el comentario decía "una excepción deliberada en `panel`: el asiento de arriba" (singular), pero el código tiene **dos** excepciones — el héroe (slot 0, t propio + offset horizontal) y el asiento de arriba. Alguien leyendo solo el comentario podía asumir que el héroe usa la fórmula genérica, cuando no es así.
**Corregido:** el comentario ahora describe las dos excepciones correctamente.

No se encontraron bugs funcionales (nada que produjera un resultado visual o de datos incorrecto) fuera de estos dos — el resto de la revisión de código (persistencia, `TablePositions`, `SeatState`/`TableSnapshot`, la burbuja educativa) no encontró errores, solo patrones ya defensivos y bien testeados.

### 3.3 Observación (no corregida, no es un bug)
La burbuja educativa (`visual_theory_stage.dart`) ancla un paso de tipo "seat" al punto del **borde de la elipse** (`layout.seat(slot)`), no a la posición real del panel (`layout.panel(slot)`) — que para el héroe y el asiento de arriba ya no coinciden exactamente (tienen su propio offset). La diferencia es chica y ningún test ni revisión visual mostró un problema real; lo dejo anotado por si en algún momento se nota la burbuja "un poco corrida" respecto al panel en esos dos asientos.

---

## 4. Higiene del repo

### 4.1 Formato (`dart format`)
`dart format --set-exit-if-changed .` marca 101 de 160 archivos con diferencias de formato. No es un problema de lint (`flutter analyze` da 0 issues — son reglas distintas), es que el proyecto nunca pasó por `dart format`. **No lo apliqué**: es un cambio de ~100 archivos sin relación con el trabajo de esta sesión, y mezclarlo en el próximo commit haría el diff ilegible. Recomendación: correrlo aparte, en su propio commit (`dart format .` + commit "chore: format"), en un momento donde no haya cambios de código en vuelo.

### 4.2 Archivos sueltos — borrados
Encontré y borré 3 archivos de debug que habían quedado en la raíz del proyecto de turnos anteriores de esta misma sesión (capturas de pantalla / logs de verificación con Chrome headless que no se limpiaron): `_check1.png`, `_chrome_log.txt`, `_dump.txt`. No estaban trackeados por git, así que no afectan ningún commit — pero ensuciaban el árbol de trabajo.

Quedan sin tocar (por instrucción explícita de sesiones anteriores) los 4 subproductos conocidos de `gen_curriculum.py`: `niveles_resumen.tsv` (×2), `tree_fragment.html` (×2).

### 4.3 Dependencias
`pubspec.yaml` tiene solo 2 dependencias de producción (`cupertino_icons`, `path_provider`) + `flutter_lints` como dev — superficie mínima, sin nada para actualizar que valga la pena revisar hoy.

### 4.4 Alcance de lo no commiteado
```
 M lib/engine/pedagogy/scripts/table_builder.dart
 M lib/engine/pedagogy/table_lesson.dart
 M lib/screens/academy/widgets/poker_table_view.dart      (+1084 / -543 líneas)
 M lib/screens/academy/widgets/visual_theory_stage.dart
 M test/ui/visual_theory_pilot_test.dart
?? lib/engine/pedagogy/table_position.dart
?? test/engine/table_geometry_test.dart
?? test/engine/table_position_test.dart
?? test/ui/table_demo_hand_test.dart
```
Todo esto es el trabajo de rediseño visual de la mesa de esta sesión (v0.3.0 en curso). Sigue sin commitear a propósito.

---

## 5. Contenido pedagógico (326 teorías)

Fuente: `assets/curriculum/curriculum_spec.json`.

### 5.1 Chequeos estructurales (automatizados, sobre las 326 entradas)
- IDs duplicados: **0**.
- Referencias rotas (`prerrequisitos`/`teorias_relacionadas` apuntando a un ID que no existe): **0**.
- `orden_global`: 326 valores, todos únicos y contiguos.
- `estado_redaccion`: **326/326 en `'listo'`** — el pipeline de redacción (N1 a N13) está completo (esto confirma y actualiza cualquier nota anterior que hablara de niveles "pendientes"; ya no los hay).
- Mojibake / doble codificación de acentos: **0** ocurrencias.
- Doble espacio en campos de texto: **0** ocurrencias.
- Palabras repetidas consecutivas: 6 coincidencias, las 6 falsos positivos (son manos de póker escritas letra por letra, ej. "K K K Q 4", no errores de tipeo).

### 5.2 Revisión de contenido (muestra manual, 14 teorías repartidas de T001 a T308, una cada ~25)
Se revisó título, ejemplo e idea clave de cada una. Verificación factual puntual sobre las afirmaciones de estrategia/reglas:
- T006 (ranking de manos): color le gana a escalera — correcto.
- T233 (removal): con A♠A♦ en mano quedan 0 combos de AA para el rival, no 6 — correcto.
- T165 (bote 3-bet): el cálculo del bote aproximado es consistente (aclarado como aproximado en el propio texto).
- T150 (rango de apertura de SB): rango más angosto que desde el botón pese a haber menos rivales detrás, por jugar el resto de la mano fuera de posición — correcto y es un matiz real que muchos principiantes se saltean.
- El resto de la muestra (T001, T020, T076, T128, TN10, TN07, T206, T290, T271, T308) — consistente, sin errores de reglas ni de terminología.

No se encontró ningún error factual en la muestra. Dado el volumen (326 teorías, ~8300 campos de texto), esta no es una lectura palabra por palabra de cada una — es un chequeo estructural exhaustivo (100% de las entradas) más una muestra dirigida y verificada a mano. Si se quiere una revisión línea por línea de un nivel puntual, es un trabajo aparte y bien acotable (un nivel a la vez, como se hizo en el "PASO 4" original).

### 5.3 Tests de contenido ya existentes
`curriculum_spec_test.dart`, `theory_content_test.dart`, `academy_content_test.dart` — corren dentro del `flutter test` de 254/254 y ya validan consistencia estructural en cada corrida (parte de por qué los chequeos de §5.1 salieron limpios).

---

## 6. Recomendaciones para retomar mañana

1. **Nada roto, nada bloqueando.** Se puede seguir directo con el trabajo visual de la mesa (v0.3.0) o pasar a commitear el estado actual.
2. Cuando se decida cerrar esta etapa: recordar que `pubspec.yaml` sigue en `version: 0.2.0` — hay que bump a `0.3.0` (o lo que corresponda) antes de tagear.
3. `dart format .` pendiente como tarea de limpieza aparte (no mezclar con el próximo commit de funcionalidad) — ver §4.1.
4. Si en algún momento se nota la burbuja educativa "corrida" respecto al panel del héroe o del asiento de arriba, revisar la nota de §3.3.
5. El taller ahora tiene "Contenido de la mesa" — antes de seguir afinando posiciones/colores, vale la pena probar escenarios que hoy el guion no cubre (alguien más que el héroe ganando con revancha visible, dos rivales con cartas reveladas a la vez, stacks muy cortos/largos) para ver cómo se comporta el layout en casos que las 5 teorías del guion no ejercitan.

---

## 7. Comandos ejecutados (para referencia)
```
flutter analyze                              # proyecto completo, 0 issues
flutter test --concurrency=1                 # proyecto completo, 254/254 (corrido 3 veces en esta sesión)
dart format --output=none --set-exit-if-changed .   # 101/160 archivos con diffs, no aplicado
git status --porcelain=v1                    # relevado antes y después de la limpieza
git log --oneline -5 / git tag / git diff --stat HEAD
python … (revisión estructural de assets/curriculum/curriculum_spec.json)
```
