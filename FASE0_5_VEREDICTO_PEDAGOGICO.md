# FLOPly — "Fase 0.5": veredicto pedagógico preflop (calidad ≠ frecuencia)
**Fecha de esta nota:** 2026-09-18 (misma sesión larga que la Fase 0 del motor de póker, en un tramo posterior)

## Por qué existe este documento

El informe de diseño original de esta iniciativa ("FLOPly — Fase 0.5", citado por nombre en varios doc-comments del código) se escribió en el chat de una sesión anterior de esta misma conversación. Esa sesión fue tan larga que sufrió una compactación de contexto, y el informe en sí **no sobrevivió en ningún archivo** — solo sobrevivió el código que ya se había escrito a partir de él (`preflop_verdict.dart`, `preflop_authoring.dart`, sus tests), con doc-comments que citaban secciones del informe ("sección C", "sección D", "secciones 8-9") sin que el informe mismo quedara en el repo.

Este documento reconstruye lo que se pudo inferir con certeza de esa evidencia (código + tests + doc-comments), y documenta qué se hizo para completar el plan. Si en algún momento aparece el informe original y contradice algo de acá, el informe original manda.

## El diagnóstico original (con evidencia directa)

El motor preflop viejo (`StrategyEngine.openRaiseStrategy` y
`PreflopStrategy._openOverLimpersStrategy`) calculaba la CALIDAD
(`StrategicRating`) de una acción a partir de un umbral sobre su
FRECUENCIA en el rango de referencia:

```dart
rating: freq >= 0.4 ? StrategicRating.veryGood : StrategicRating.viable,
```

Esto mezcla dos preguntas distintas: "¿qué tan seguido se juega esto?"
(un hecho del rango) y "¿qué tan buena es esta decisión?" (un juicio
estratégico). El código ya escrito antes de esta sesión (`preflop_
authoring.dart`) definía el vocabulario para separarlas:

- **`QualityTier`** (agrupa `StrategicRating` en top/mid/low) — la
  calidad real.
- **`MixShare`** (pure/primary/secondary/negligible) — qué tan presente
  está una acción en un mix real, **puramente informativo**, nunca
  determina el veredicto.
- **`ContextSensitivity`** — si la calidad de una acción depende de una
  variable que el ejercicio no le muestra al alumno (perfil del rival,
  su rango, etc.).
- **`StrategyRole`** — value/bluff/defend/fold/... , por qué una acción
  pertenece a la estrategia (para autoría, no consumido por la lógica de
  veredicto).
- **`isCoherentCell`** — guarda de autoría: nunca `QualityTier.top` +
  `MixShare.negligible` a la vez (contradicción: "es la mejor jugada" +
  "casi nunca se juega").
- **`preflopVerdict(quality, contextSensitivity)`** — la fórmula final:
  `top→BEST`, `mid→ACCEPTABLE`, `low`+dependiente-no-revelado→`DEPENDS`,
  `low` en cualquier otro caso→`ERROR`. **Nunca mira `frequency`.**

Todo esto ya existía, probado con datos sintéticos, **sin ningún call
site en el motor real** — `StrategyOption` todavía no tenía los campos
`role`/`contextSensitivity`, y `AnswerEvaluator.evaluate` seguía
calculando `dependent` de la forma vieja (`strategy.isMixed &&
option.frequency >= 0.15`).

## Qué se completó en este bloque

### 1. `StrategyOption` — campos reales
`role: StrategyRole?` (nullable — no todo ejercicio tiene una noción de
value/bluff/defend, ej. comparar manos) y `contextSensitivity:
ContextSensitivity` (default `.stable()`) en `strategy/strategy.dart`.
Opcionales con default seguro a propósito: `StrategyOption` es un tipo
compartido con el sistema LEGACY (`evaluation/answer_evaluator.dart` y
los templates de `exercises/templates/`), que no debía tocarse — los
nuevos campos no rompen ni exigen nada de esos call sites.

### 2. `StrategyEngine.openRaiseStrategy` — frontera sin umbral de frecuencia
Antes: banda 0<freq<0.75 dividía raise/fold en veryGood/viable según
`freq >= 0.4`. Ahora: **ambas acciones `viable`** — dentro de la
frontera, ninguna domina a la otra por definición (`frequency` sigue
guardando el dato real para el texto informativo, pero ya no decide la
calidad). Además: la banda "justo fuera de rango" (`dubious`, antes
plana) ahora se marca `ContextSensitivity.dependent([opponentProfile])`
— es defendible o no según qué tan explotable sea la mesa, una variable
que el ejercicio no muestra. La banda "bien fuera de rango" (`bad`)
queda estable — es un error sin importar el rival.

### 3. `PreflopStrategy._openOverLimpersStrategy` — mismo fix
Misma frontera colapsada a `viable`/`viable`. (Nota: esta rama no es
alcanzable desde ninguna de las 5 familias de `ExerciseScenarioBuilder`
— ninguna simula un limp todavía — así que se verificó con un
`GameState` armado a mano en el test, ver más abajo.)

### 4. `PreflopStrategy._facingRaiseStrategy` — role + dependent real
Esta función no tenía el problema de calidad-desde-frecuencia (sus
ratings ya eran constantes por banda de percentil, no derivados de
`freq`), así que no necesitaba ese fix. Sí le faltaban `role`/
`contextSensitivity`:
- 3-bet premium → `role: value`, estable.
- call de defensa → `role: defend`.
- fold → `role: fold`.
- **3-bet liviano de la banda media (percentil 0.06-0.35, rating
  `dubious`)** → `role: bluff`, `ContextSensitivity.dependent([
  opponentProfile, villainRange])` — es correcto o no según el rango de
  apertura real del rival y con qué frecuencia se retira ante un 3-bet,
  ninguna de las dos visible en el ejercicio. Esta es la opción que
  ahora produce `AnswerVerdict.dependent` de verdad quien la elige.

### 5. `AnswerEvaluator.evaluate` — cableado real
Reemplazó el cálculo de `dependent` basado en frecuencia por
`preflopVerdict(quality: option.rating, contextSensitivity:
option.contextSensitivity)`. Se borró `_fromRating` (quedó muerto).

### 6. Guarda de coherencia contra el motor real
`preflop_authoring_coherence_test.dart` (nuevo): recorre las 169 clases
de mano × 5 posiciones (`StrategyEngine.openRaiseStrategy`) y las 5
familias de `ExerciseScenarioBuilder` × 60 semillas cada una
(`PreflopStrategy.forDecision`), y verifica `isCoherentCell` en cada
opción generada. Antes de este bloque, `isCoherentCell` solo se probaba
con datos sintéticos — nunca contra lo que el motor genera de verdad.

### 7. Tests dirigidos del redisño
`preflop_strategy_test.dart` (nuevo): la frontera de
`_openOverLimpersStrategy` (armada a mano, ver arriba) da `viable` en
ambas acciones — nunca `veryGood`; el 3-bet liviano de
`_facingRaiseStrategy` tiene `role: bluff` y produce `DEPENDS`.

## Decisiones propias (no evidenciadas directamente — juicio del
implementador, documentadas para que se puedan revisar)

1. **`role: null` en `openRaiseStrategy`/`_openOverLimpersStrategy`**: a
   diferencia de `_facingRaiseStrategy`, estas dos funciones no modelan
   ninguna distinción value/bluff (es solo "¿está en el rango o no?").
   Asignar `StrategyRole.value` a todo raise por default hubiera sido
   relleno sin información real — el propio doc-comment de
   `StrategyRole` dice explícitamente "nunca se infiere... del
   `ActionType` solo". Se dejó `null`, que el campo admite justo para
   este caso.
2. **Frontera colapsada a un único nivel (`viable`) en vez de una nueva
   sub-graduación**: es la lectura más simple y defendible de "la
   calidad no se deriva de la frecuencia" — cualquier sub-graduación
   alternativa (por ejemplo, basada en `MixShare`) hubiera sido
   reintroducir el mismo acoplamiento por la puerta de atrás.
3. **`ContextFactor`s elegidos para cada caso dependiente**
   (`opponentProfile` para el "justo fuera de rango"; `opponentProfile`
   + `villainRange` para el 3-bet liviano): inferidos de qué variable
   realmente cambia la corrección de esas líneas en la teoría de
   póker estándar, no de una tabla explícita del informe perdido.

## Resultado

`flutter analyze`: 0 issues. Tests nuevos: 6 (coherencia) + 8 (dirigidos
a `PreflopStrategy`) = 14. Regresión completa corrida sin fallos (ver el
chat de la sesión para el número final exacto). Ningún test preexistente
necesitó reescribirse — el único que tocaba esta área
(`answer_evaluator_test.dart`, caso "dependent: mano en la frontera")
seguía pasando porque el veredicto `dependent` sigue existiendo, solo
que ahora sale de una mano distinta (la banda "justo fuera de rango",
no la frontera mixta) — un cambio de comportamiento correcto, no una
regresión: antes cualquier mano con frecuencia ≥15% en una mixta podía
salir "dependent" aunque fuera claramente buena o mala; ahora solo sale
"dependent" cuando la calidad es baja Y depende de algo que el alumno no
puede ver.
