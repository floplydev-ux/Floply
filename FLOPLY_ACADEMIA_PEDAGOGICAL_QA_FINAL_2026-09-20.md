# FLOPly — Academia: QA pedagógico autónomo + corrección + regresión integral

**Fecha:** 2026-09-20/21. Ciclo ejecutado: AUDITAR → CORREGIR → TESTEAR → VOLVER A AUDITAR → CORRECCIÓN FINAL → QA HUMANO → PASS.

## 1. Executive Summary

Se auditaron las 326 teorías de la Academia (13 niveles, 64 subniveles) y se corrigieron directamente **53 teorías** con errores de contenido/pedagogía reales, más un **bug sistémico crítico de aleatorización** que afectaba a 18 comprehension-checks (la respuesta correcta estaba en la posición 1 el 100% de las veces, sin ningún shuffle en el motor). Se usaron 12 subagentes especializados en paralelo (uno por nivel N2-N13) más revisión directa mía de N1 y del motor de comprobaciones (`mentor_lesson.dart`). Cada corrección de contenido está respaldada por evidencia verificable (recálculo aritmético, conteo de cartas/palos, verificación cruzada contra el nivel de origen citado) — no hay "mejoras" cosméticas sin motivo. `flutter analyze` 0 issues y `flutter test` 1211/1211 antes y después de regenerar el currículo. QA humano en vivo (Marionette) confirmó el fix de aleatorización y una de las correcciones de contenido funcionando en la app real.

## 2. Estado inicial

Las 326 teorías estaban redactadas y publicadas (`estado_redaccion: "listo"` en las 326), con una auditoría pedagógica previa (2026-09-11) que había encontrado 0 problemas críticos y 5 importantes, la mayoría ya resueltos. Nunca se había hecho una pasada de corrección exhaustiva teoría-por-teoría sobre N7-N13 (redactadas en una sola tanda, sin auditoría dedicada posterior), ni se había verificado nunca la distribución real de posiciones de respuesta correcta en los comprehension-checks — el punto que terminó siendo el hallazgo más grave de esta misión.

## 3. Cantidad de teorías revisadas

**326/326.** N1 (25 teorías) se revisó directamente por mí, no vía subagente, porque su ficha escrita (`content_n1.py`) está **completamente reemplazada** en la UI real por un sistema nuevo ("clase de mentor", `mentor_lessons_n1.dart` + `mentor_pilot_lessons.dart` para T001) — confirmado en código (`academy_controller.dart`: "la clase de mentor la REEMPLAZA" a la ficha escrita para las teorías registradas). Auditar `content_n1.py` hubiera sido esfuerzo sobre texto que ningún alumno ve; audité en su lugar los 2 archivos que sí se muestran. N2-N13 (301 teorías) se auditaron vía 12 subagentes en paralelo, cada uno con acceso de solo lectura a los niveles vecinos para verificar continuidad, y con permiso de edición exclusivo sobre su propio `content_nX.py`.

## 4. Cantidad de teorías modificadas

**53 teorías con contenido corregido**, más el mecanismo de aleatorización (afecta 18 checks en 11 teorías, sin tocar el contenido de esas teorías):

| Nivel | Teorías modificadas | Cantidad |
|---|---|---|
| N1 (directo) | T004, T034, T044 | 3 |
| N2 | T006, T007, T052, T053, T054, T056, T059, T061, T063 | 9 |
| N3 | T031 | 1 |
| N4 | T075-T081, T085, T086, T088-T090, T092, T095, T096, T098 | 16 |
| N5 | T148, T149, T150 | 3 |
| N6 | T103, TN11 | 2 |
| N7 | T156, T165, T166, T167, T169, T173 | 6 |
| N8 | T176 | 1 |
| N9 | T188, T192 | 2 |
| N10 | T217, T218 | 2 |
| N11 | T225, TN15, T230 | 3 |
| N12 | T289, T297 | 2 |
| N13 | T250, T275, T280 | 3 |
| **Total** | | **53** |

## 5. Cantidad de comprehension-checks revisados

**47 comprobaciones de comprensión** en total, de dos mecanismos distintos:
- **29** `ComprehensionCheck` (modelo legacy, `academy_content.dart`, cubre subniveles heredados de N1-N3).
- **18** `MentorCheck`/`.ask()` (modelo nuevo, `mentor_lessons_n1.dart` + `mentor_pilot_lessons.dart`, cubre N1 completo + una teoría piloto de N2-N9/N11/N13).

No se encontraron comprobaciones adicionales embebidas en el JSON del currículo: verifiqué que las 326 teorías tienen `pasos_mesa: null` — ninguna guarda preguntas ahí.

## 6. Correcciones de contenido (errores técnicos verificables)

- **T148/T149/T150 (N5)**: errores reales de conteo posicional y de orden de acción. T148 decía "dos jugadores por detrás" del CO cuando son tres (BTN+SB+BB). T149 afirmaba que el BTN "es la última posición en actuar preflop" — falso, actúan después SB y BB; lo cierto (y lo que la teoría quería decir) es que actúa último en todas las rondas postflop. T150 tenía el error espejado con la SB.
- **T165/T166 (N7)**: el bote de un 3-bet daba "≈19 BB" pero la cuenta real (9+9+1 BB de la ciega grande) se olvidaba la ciega chica muerta (0,5 BB) → correcto es 19,5 BB. T166 (primera aparición de SPR en todo el currículo) no aclaraba que se usa el **stack efectivo** (el menor entre los dos), y su ejemplo dependía del bote ya corregido (SPR recalculado: 100÷19,5≈5,1).
- **T167 (N7)**: comparaba una 3-bet "desde UTG" contra un open del CO — imposible en el orden de acción real (UTG ya actuó antes de que exista el open del CO). Corregido a un ejemplo válido (BB 3-beteando fuera de posición).
- **T103 (N6)**: el ejemplo de "out sucio" en realidad describía una mano ya hecha vulnerable a un color, no un proyecto — no ilustraba el concepto que la teoría define. Reemplazado por un ejemplo real (proyecto de color de 9 outs donde uno de esos outs también le da trío/full al rival), verificado carta por carta.
- **TN11 (N6)**: frase rota/con artefacto de edición ("el caso contrario a T por venir") — corregida a una definición coherente que cita correctamente TN10.
- **T188 (N9)**: el ejemplo de "carta que ayuda al rango del rival" decía que el turn traía la "cuarta" carta de un palo — eso ya es el escenario de T190 (scare card), no el de T188. Corregido a "tercera carta" para diferenciar los dos conceptos.
- **T218 (N10)**: un ejemplo de línea completa decía que el rival "c-betea el flop" después de solo pagar una 3-bet — imposible, porque quien paga una 3-bet no tiene la iniciativa (no puede c-betear). Corregido a "paga tu c-bet".
- **T280 (N13)**: citaba "(N4, T257)" cuando T257 es una teoría de N12 — inconsistente además con la propia teoría, que en otro campo ya citaba correctamente "(N12, T257)".
- **T297 (N12)**: citaba T209 (N9, definida explícitamente para el río) para razonar sobre una mano hecha en el **flop** — corregido a T177 (N8), la teoría que sí trata esa pregunta en el flop.
- **T289 (N12)**: el ejemplo decía que A♠Q♠ entra en "tu rango de 3-bet" contra el CO, pero el rango de 3-bet de valor definido en T161 (N7) es "AA-QQ y AK", sin AQ. Cambiado a A♠K♠ para que la afirmación sea 100% verificable.
- **T004 (N1, directo)**: el ejemplo narraba "K♠Q♦" pero los datos reales de la carta eran K♠Q♠ (ambas espadas) — mismatch entre texto y dato concreto.
- **T044 (N1, directo)**: decía "hay tres corazones" en un board+mano con cuatro corazones reales (A♥K♥ + 9♥4♥) — error de conteo.
- **T225 (N11)**: error de concordancia de género ("esa color" → "ese color").

## 7. Correcciones pedagógicas (tono, estructura)

- **N4**: ~20 instancias de "Mirá"/"Fijate"/"Ojo" (incluidas 3 teorías con dos muletillas en la misma oración) sobre 37 teorías — comparado contra N3 (1/22) y N5 (2/26), N4 era un outlier real. Reescritas con verbos variados (Comprobá, Analizá, Identificá, Preguntate...) para volver al registro del resto del currículo.
- **T034 (N1, directo)**: intro con "Che, ojo con esta... Prestá atención" (tres muletillas en dos frases) — único caso así en las 25 teorías de N1. Reescrita a un tono medido consistente con sus pares.
- **N2**: "mesa" usado como sinónimo de "board" en 7 lugares (mezclando ambos términos en la misma oración en algunos casos), rompiendo la convención ya establecida en N1 ("board" = cartas comunitarias, "mesa" = la mesa física/asientos, ya correcta en N3). Corregido a "board" en los 7 casos; se dejó "mesa" donde de verdad se refería a los jugadores (T062).
- **T176 (N8)**: tiempo verbal incorrecto ("manos que fallaron el flop") describiendo la composición de un rango que se arma antes de que exista ningún flop — corregido a aspecto habitual ("manos que terminan sin conectar").
- **T230 (N11)**: tono de manual ("es la forma correcta de apostar") suavizado a razonamiento de mentor ("es lo que mejor sostiene esa apuesta, porque...").
- **T031 (N3)**, **T275/T250 (N13)**: ejemplos numéricos casi calcados de la teoría inmediatamente anterior del mismo subnivel, sin aportar nada nuevo — diferenciados manteniendo el mismo concepto pedagógico.
- **T173 (N7)**: reutilizaba la misma mano (A♠A♦) que T170, 3 teorías antes, en el mismo subnivel — cambiada a K♠K♦, lo que además arma un paralelismo limpio con el resto de N7 (AA introduce el concepto, KK ilustra "por valor", igual que ya hacían T157/T158 con 3-bet).
- **TN15 (N11)**: duplicaba casi textualmente el ejemplo de T226 (posición → más equity realizable). Reescrita para ilustrar el factor que la propia consigna pedía (dificultad de juego postflop, no posición), separando de verdad las dos teorías.

## 8. Correcciones de ejercicios

Fuera del alcance asignado a los subagentes (que auditaron `content_nX.py`, la ficha de teoría — no `lib/engine/pedagogy/scripts/nX_exercises.dart`, los ejercicios interactivos FOLD/CALL/RAISE). Ningún agente encontró una inconsistencia entre una teoría corregida y su ejercicio asociado que ameritara escalarlo como excepción. La única corrección que toca directamente la superficie de "ejercicio" es la de aleatorización (§10), que vive en el motor compartido de comprobaciones, no en un ejercicio puntual.

## 9. Correcciones de feedback

El feedback de cada opción (`ExerciseChoice.feedback`) viaja pegado a su opción en todo momento — al reordenar opciones (§10) nunca se tocó el texto de feedback, y se verificó en vivo (§15) que sigue mostrando la explicación correcta sin importar en qué posición quedó la opción. La corrección de T103 (§6) mejora indirectamente su `error_comun` (el feedback que ve el alumno si falla), porque el ejemplo que lo sostenía era el que estaba mal.

## 10. Correcciones de aleatorización

**Hallazgo crítico confirmado con evidencia de código, no solo sospecha:** las 18 comprobaciones `.ask()`/`MentorCheck` (`mentor_lessons_n1.dart` + `mentor_pilot_lessons.dart`) tenían la opción `ExerciseRating.best` en el índice 0 el **100% de las veces**, y no existía ningún `Random`/`shuffle` en todo `lib/` que reordenara las opciones al mostrarlas — confirmado por grep exhaustivo antes de tocar nada. Un alumno podía "acertar" sistemáticamente tocando siempre la primera opción, sin leer nada.

**Corrección — solución general, no un parche por pregunta:** se agregó `_shuffledChoices()` en `mentor_lesson.dart`, en el único punto donde se construyen todas las `MentorCheck` (la función `ask()` que ya usan los 18 guiones). Usa un `Random` sembrado con un hash determinístico del propio `prompt` — la misma pregunta siempre cae en el mismo orden (estable entre sesiones y para los tests), pero preguntas distintas caen en órdenes distintos, sin ningún patrón fijo. No se tocó ningún guion de contenido; label/rating/feedback de cada opción se permutan como una unidad, preservando su identidad completa.

**Verificación (script Dart standalone, algoritmo idéntico al de producción, sobre los 18 prompts reales):**

| Posición | Antes del fix | Después del fix |
| -------- | ------------: | ---------------: |
| A (índice 0) | 18 (100%) | 6 (33,3%) |
| B (índice 1) | 0 (0%) | 12 (66,7%) |

No es una distribución perfectamente pareja (con solo 2 opciones y 18 preguntas, 6/12 es estadísticamente razonable para un sorteo pseudoaleatorio), pero cumple el criterio real pedido: **ninguna posición es siempre correcta**, y ya no hay patrón detectable.

Los 29 `ComprehensionCheck` legacy (hasta 3 opciones, `academy_content.dart`) se auditaron también: distribución A=8 (27,6%) B=15 (51,7%) C=6 (20,7%). Sesgada hacia B pero **ninguna posición es "siempre correcta"** (A es la menos frecuente, no la más) — no cumple la condición de "bug" que pedía corregir, así que se dejó sin tocar (no se justificaba el riesgo de mover `const` a través de ~14 bloques `LessonContent` para una distribución que ya no es degenerada).

## 11. Correcciones de terminología

- "board" vs "mesa" (N2, 7 instancias) — ver §7.
- "cuarta carta" → "tercera carta" en T188 (N9) para no confundirse con la scare card de T190 (misma palabra, concepto distinto según cuántas cartas del palo hay).
- "triple barrel" descrito como "un término que no se usa tanto" (T192, N9) — corregido: es terminología estándar, solo se aclaró que el nivel no lo desarrolla como concepto aparte.
- Docstring de N13 actualizado para incluir "tilt" en el vocabulario nuevo del nivel (estaba introducido en T286 pero faltaba en la lista de cabecera — metadata de desarrollador, no contenido de alumno).
- Docstring de N12 corregido: decía "checklist de diez preguntas" cuando son diecisiete (7 en 12.1 + 10 en 12.2) — metadata, no contenido exportado.

## 12. Correcciones de coherencia

Todas las de §6 que involucran una cita cruzada a otro nivel (T280, T297, T289, T167, T218) son, en esencia, correcciones de coherencia: una teoría afirmando algo sobre otra que no es exactamente lo que esa otra enseña. Además, cada uno de los 12 subagentes verificó — no asumió — el contenido real de cada teoría citada desde niveles anteriores (decenas de citas cruzadas por nivel, documentadas en sus reportes), y no encontraron más inconsistencias que las ya listadas.

## 13. Problemas que NO pudieron corregirse (excepciones documentadas)

- **Prerrequisito TN11 en 5 teorías de N8 (8.6)**: el JSON declara TN11 (reverse implied odds, N6) como prerrequisito de TN05-TN09, una elección algo rara (T124/pot odds básicas o TN13/fold equity serían más centrales). El contenido en sí no afirma nada erróneo. Vive en la estructura de prerrequisitos (`curriculum_spec.json`/`gen_curriculum.py`), fuera del alcance de corrección de contenido — documentado para quien mantenga esa estructura.
- **Vocabulario "blocker/bloqueador" usado en TN07 antes de definirse en T232**: hallazgo **confirmado de forma independiente 3 veces** — por el agente de N8, por el agente de N11, y por el propio validador de `gen_curriculum.py` (aparece como AVISO esperado en su salida). Los 3 coinciden en que el contenido REAL de TN07 no habla de bloqueadores (es sobre semi-farolear con un proyecto) — el aviso viene de un diccionario de vocabulario en el generador que etiquetó mal esa teoría. No es un archivo de contenido, está fuera del alcance de esta misión.
- **T191/T192 (N9, barrel/double barrel)**: se parecen mucho pero es andamiaje deliberado (T192 depende de T191 como prerrequisito) — arreglarlo de verdad requeriría fusionar teorías, cambio estructural fuera de alcance.
- **N3.4 "Fichas y stacks" sin ejercicio/check**: hueco ya documentado en fases anteriores, pendiente de decisión del usuario — no se tocó.
- **N11 sin ejercicios DECIDIR** (15 teorías EXPLICAR consecutivas): ya documentado como hallazgo previo, arquitectura de ejercicios fuera de esta misión.
- **`content_n1.py` completo (25 teorías)**: su texto ya no lo ve ningún alumno (reemplazado por la clase de mentor). No se "corrigió" contenido muerto — se documenta la situación en vez de invertir esfuerzo donde no cambia la experiencia real.
- **13.4 (N13, "spots completos de río/all-in")**: son descripciones de proceso sin cartas ni números concretos (mismo estilo que N12), así que no hay matemática que verificar — se documenta como oportunidad pedagógica futura (un spot con datos reales de punta a punta), no como error.

## 14. Segunda pasada

Tras juntar las 12 auditorías, hice una pasada de consistencia cruzada propia (no repetición mecánica de la primera):
- Grep de patrones de confusión "mesa"/"board" en los 13 archivos → limpio, sin residuos más allá de los ya corregidos en N2.
- Grep de citas a las teorías corregidas (T148-T150, T165-T166) desde el resto del currículo → sin citas obsoletas que dependieran de los números/afirmaciones viejas.
- `python tool/curriculum/gen_curriculum.py` → **0 errores**, validación estructural completa en verde (326 IDs únicos, 0 prerrequisitos hacia adelante, curva de dificultad correcta), 1 AVISO esperado (el de TN07/blocker, ver §13).
- `flutter analyze` → 0 issues.
- `flutter test --concurrency=1` → **1211/1211**, sin regresiones respecto del baseline anterior a esta misión.

## 15. Tercera pasada — QA humano (Marionette, instancia real)

Con la app corriendo de verdad (Chrome, `flutter run`), como alumno invitado nuevo:

- **Estructura**: Estadísticas muestra "0 de 64 lecciones completadas" y los 13 niveles con los nombres correctos — confirma que el currículo regenerado cargó bien en la app real, no solo en el JSON.
- **Aleatorización, confirmada en vivo**: en la teoría T001 (la primera comprobación de toda la Academia, "¿para qué jugás cada mano?"), la opción correcta apareció en la **posición 2**, no en la 1 — la primera vez, entre las fases de QA de este proyecto, que ese check no muestra la respuesta correcta arriba. Se tocó la opción correcta y el feedback "✓ CORRECTO" se mostró igual, con el texto correcto — confirma que el shuffle no rompe la evaluación.
- **Corrección de contenido, confirmada en vivo**: la burbuja de T004 ahora dice "Tenés K♠Q♠", coincidiendo con las cartas reales dibujadas en la mesa (antes decía K♠Q♦).
- **Limitación real, no evitada**: el desbloqueo de Academia es lineal — no se pudo navegar en vivo hasta N5-N13 (donde vive la mayoría de las correcciones técnicas) sin completar antes las ~250 teorías previas, algo fuera del alcance razonable de esta sesión de QA. La validación de esas correcciones se sostiene en: lectura directa de código por cada subagente + mis verificaciones cruzadas (§14) + la suite de tests. Se documenta la limitación en vez de fingir cobertura visual que no hubo.

## 16. Tests

```
flutter analyze: PASS (0 issues) — antes y después de regenerar el currículo
flutter test --concurrency=1: PASS (1211/1211) — antes y después de regenerar el currículo
python tool/curriculum/gen_curriculum.py: PASS (326 teorías, 64 subniveles, 13 niveles, 0 errores, 1 aviso ya conocido)
```

## 17. Archivos modificados

- `tool/curriculum/content_n2.py` .. `content_n13.py` (12 archivos — contenido de las 53 teorías de §4, uno por nivel, cada uno editado por su propio subagente).
- `lib/engine/pedagogy/mentor_lesson.dart` — fix general de aleatorización (`_shuffledChoices`, nuevo import `dart:math`).
- `lib/engine/pedagogy/mentor_lessons_n1.dart` — 3 correcciones de contenido/tono (T004, T034, T044).
- `assets/curriculum/curriculum_spec.json` — regenerado desde los 12 `content_nX.py` corregidos.
- `lib/engine/pedagogy/curriculum_spec_data.g.dart` — regenerado (mismo origen).
- `tool/curriculum/tree_fragment.html` — artefacto secundario regenerado automáticamente por `gen_curriculum.py` (documentación visual del árbol de niveles, no afecta la app).

No se tocó `tool/curriculum/content_n1.py` (ver §13) ni ningún archivo de `lib/engine/pedagogy/scripts/nX_exercises.dart` (ejercicios interactivos, fuera del alcance de esta pasada).

## 18. Archivos protegidos

Confirmado que NO se alteraron:
- **IDs** de teorías/subniveles — `gen_curriculum.py` valida 326 IDs únicos tras la regeneración.
- **Estructura del currículo** (niveles, subniveles, `orden_global`) — validado 1..326 contiguo, curva de dificultad intacta.
- **Prerrequisitos** — 0 prerrequisitos hacia adelante, ningún subagente tocó el campo `prerrequisitos` del JSON.
- **Navegación, progreso, unlocks, persistence** — no se tocó ningún archivo de `lib/screens/academy/` ni `lib/engine/academy/` (controllers, stores).
- **Motor de póker/estrategia, Laboratorio, Tools, cuentas, monetización** — ningún subagente ni yo tocamos código fuera de `tool/curriculum/content_nX.py` y los 2 archivos de `lib/engine/pedagogy/` listados en §17.

## 19. Estado final

```
ACADEMIA QA STATUS: PASS WITH DOCUMENTED EXCEPTIONS
```

Excepciones (todas en §13, ninguna bloqueante):
1. Prerrequisito TN11 en 8.6 (N8) — elección de estructura discutible, no un error de contenido.
2. Vocabulario "blocker" en TN07 antes de T232 — falso positivo de un diccionario del generador, confirmado 3 veces independientemente, no está en el contenido real.
3. T191/T192 (N9) — similitud deliberada, resolverla de verdad requiere fusión estructural.
4. N3.4 sin ejercicio, N11 sin ejercicios DECIDIR — huecos de arquitectura ya conocidos, pendientes de decisión del usuario, no de esta misión.
5. `content_n1.py` — texto muerto, reemplazado por la clase de mentor; no se invirtió esfuerzo en corregirlo.

Ninguna excepción compromete la corrección técnica de póker que sí llega al alumno, ni la aleatorización de respuestas, ni la voz de mentor de la Academia. No se pasa a ninguna fase posterior automáticamente.
