# FLOPly — Prototipo visual Fase 1 ("Sala Verde" en producto real)

Registro de lo aprendido al prototipar el lenguaje visual en 3 pantallas reales del proyecto Flutter. Esta fase **no migró nada**: es un prototipo aislado y reversible, pensado para descubrir qué del sistema documentado (`FLOPLY_DESIGN_LANGUAGE.md`, `FLOPLY_COMPONENTS.md`, `FLOPLY_DESIGN_TOKENS.md`, `FLOPLY_MOTION.md`, `FLOPLY_ANTI_GENERIC.md`) sostiene en código real y qué no.

## 1. Qué se prototipó

Tres pruebas, cada una un archivo `@Preview` bajo `lib/dev/design_playground/`, visible con `flutter widget-preview start` (infraestructura ya existente en el proyecto — ver §"Arquitectura del prototipo" abajo):

1. **Home** (`home_prototype_preview.dart`) — recomposición completa de la pantalla de inicio: header, hero de "seguir aprendiendo", sección "seguí explorando" con 3 destinos.
2. **Academia / Teoría** (`academy_theory_prototype_preview.dart`) — **T093 "Set"**, una teoría real del currículo (nivel 4, subnivel 4.5 "Tu mano hecha en el flop"; contenido copiado verbatim de `lib/engine/pedagogy/curriculum_spec_data.g.dart:1368`), con sus 6 secciones + idea clave.
3. **Laboratorio / Ejercicio** (`laboratory_exercise_prototype_preview.dart`) — el mismo ejercicio jugable real que ya usa `playable_table_exercise_preview.dart` (BTN con A♠J♠, decisión FOLD/ABRIR con 3 tamaños), con la mesa real (`PokerTableView`) embebida sin modificar.

Ningún archivo de producción fue tocado. `AppColors`/`AppTheme` no se modificaron. `AppShell`, la navegación, el currículo, el progreso y `PokerTableView`/`TableMaterial` quedaron exactamente como estaban.

## Arquitectura del prototipo (Paso 3 del orden de ejecución)

Antes de escribir código se auditó qué infraestructura de prototipado ya existe en el proyecto: `lib/screens/academy/widgets/poker_table_view_preview.dart` y `lib/screens/laboratory/widgets/playable_table_exercise_preview.dart` ya usan **Flutter Widget Preview** (`package:flutter/widget_previews.dart`, anotación `@Preview`, scaffold en `.widget_preview/`) exactamente para este propósito: iterar visualmente sobre un widget sin pasar por navegación real, sin afectar producción, con hot reload. Se reutilizó esa misma infraestructura para las 3 pruebas de esta fase en vez de crear una ruta/pantalla "Design Playground" nueva — cumple al pie de la letra la restricción del prompt maestro ("si ya existe infraestructura equivalente, reutilízala, no dupliques sistemas") y automáticamente satisface "no debe alterar el flujo normal de usuarios / no debe aparecer en navegación normal": estos archivos no los importa ningún screen real.

## 2. Qué componentes fueron reutilizados (sin modificar)

- `PressableScale` (`lib/widgets/pressable_scale.dart`) — primitivo de interacción puro, sin colores propios; reutilizado tal cual en los 3 prototipos.
- `PokerTableView` (`lib/screens/academy/widgets/poker_table_view.dart`) — embebido sin cambios en el prototipo de Laboratorio, con una `TableSnapshot` real.
- Modelos de motor reales, sin copia paralela: `TableSnapshot`, `TableAnchor`, `TableBuilder`, `PlayableTableExercise`, `ActionChoice`, `BetSizeOption`, `ExerciseRating`, `ExerciseExplainStep` — la situación de Laboratorio es literalmente la misma que ya vive en `playable_table_exercise_preview.dart` (mismas cartas, mismos tamaños, mismos textos de feedback), no una inventada para la ocasión.
- `AppStrings` (copy real: `homeGreeting`, `continueLearningEyebrow`, `bankrollDescription`, `toolsDescription`, `coachDescription`, `practiceRoomTitle/Body`, `academyContinue`, etc.) y `AppUser.current` — usados verbatim en el prototipo de Home.
- La infraestructura de Flutter Widget Preview ya existente (ver arriba), en vez de construir una ruta nueva.

## 3. Qué componentes nuevos fueron realmente necesarios

Los widgets reales que estos prototipos reemplazan visualmente (`HomeHeader`, `ContinueLearningCard`, `HomeLinkCard`, las secciones de `written_theory_view.dart`, `PlayableTableExerciseView` y su chrome interno) están escritos **directamente sobre `AppColors`** — no hay forma de "reskinearlos" con un `ThemeData` distinto sin editar esos archivos, algo que esta fase prohíbe explícitamente. Por eso se creó una capa paralela, mínima y deliberadamente pequeña:

- `proto_tokens.dart` — traducción directa de `FLOPLY_DESIGN_TOKENS.md` a `ProtoColor`/`ProtoSpace`/`ProtoRadius`/`ProtoElevation`/`ProtoMotion`/`ProtoType`. Ninguna importación desde código de producción.
- `proto_components.dart` — **9 widgets**, no más: `ProtoSectionHeader`, `ProtoSurfacePanel`, `ProtoTappableCard`, `ProtoReadingCard`, `ProtoButtonPrimary`, `ProtoButtonSecondary`, `ProtoChipNumeric`, `ProtoChipStatus`, `ProtoCalloutAccent`, `ProtoProgressLinear`. Cada uno se usa en **al menos 2 de las 3 pantallas** — evidencia de que es un sistema compartido real, no un widget por pantalla (`FloplyCard`/`AcademyCard`/`LabCard` que el prompt maestro pide evitar explícitamente no existen acá).
- Una única composición local, deliberadamente **no** promovida a `proto_components.dart`: `_SizeChip` (elegir tamaño de apuesta en Laboratorio) — se documentó en el propio archivo por qué se queda local (solo aparece en una pantalla; subirla sería crear un componente sin necesidad real comprobada, algo que la Fase 1 pide evitar explícitamente).

## 4. Qué tokens se probaron

Colores: `background`, `surface`, `surfaceElevated`, `surfaceReading`, `surfaceFelt` (acotado), `brass`/`brassBright` (implícito en estados), `feltGreen`, `steelBlue`, `success`, `warning`, `error`, `textPrimary/Secondary/Muted`, `borderSubtle`. Spacing: las 7 escalas completas (`xs`→`section`). Radius: `sharp`, `panel`, `control`, `pill`. Elevation: nivel 0 (implícito, sin sombra) y nivel 1 (`ProtoElevation.level1`, usado en cards tocables y botón primario) — el nivel 2 (flotante/overlay) no se ejercitó porque ninguna de las 3 pruebas necesitó un sheet/dialog. Motion: `settle`/`reveal` (progreso, feedback) y `instant`/`quick` (selección de tamaño). Tipografía: la escala completa de roles (`display` → `numericMicro`), con `FontFeature.tabularFigures()` en los tres roles numéricos — **no** se probó una familia tipográfica real (display/mono con licencia): sigue fuera de alcance, tal como estableció `FLOPLY_DESIGN_TOKENS.md`.

No se ejercitó `graphiteSteel` (acento de Tools) porque Tools no es una de las 3 pruebas de esta fase.

## 5. Qué decisiones visuales funcionaron

- **Fondo plano, sin gradiente.** El Home real hoy pinta `AppColors.backgroundGradient` (dos tonos); el prototipo usa `ProtoColor.background` sólido. En las 3 pantallas se ve más calmo y no compite con el contenido — confirma en código la regla 5 de `FLOPLY_ANTI_GENERIC.md` ("no gradientes decorativos porque sí").
- **`surfaceReading` como señal de modo.** En la teoría T093, pasar de fondo oscuro a marfil plano se siente de inmediato como "ahora estás leyendo" — sin necesitar ningún ícono ni texto que lo diga, validando el patrón "Aprender" de `FLOPLY_UX_PATTERNS.md`.
- **Quitar el color-por-sección en las 7 secciones de teoría no perjudicó la lectura.** El código real (`_SectionView` en `written_theory_view.dart:150-179`) usa 7 combinaciones ícono+color distintas; el prototipo usa un solo estilo de eyebrow (uppercase, neutro) para las 6. Con el contenido real de T093 la jerarquía se sigue leyendo perfectamente bien solo con tipografía+espaciado — evidencia a favor del "presupuesto de materialidad" de la Fase 0.5, no solo en teoría sino con texto real.
- **La regla de escasez de `brass`** (máximo un relleno de superficie por pantalla) fue implementable sin sentirse pobre: cada pantalla tiene exactamente un momento dorado (el CTA principal) y se sigue sintiendo "de marca" — no hizo falta repetirlo para que la pantalla se sintiera FLOPly.
- **La franja de fieltro acotada alrededor de la mesa embebida** (Laboratorio) convive bien con la mesa real: la mesa se ve exactamente igual que siempre (no se tocó), y el fieltro alrededor no compite ni se confunde con la textura real de `TableSurfacePainter` porque es un color plano, no una textura — el criterio CONTROL del prompt maestro ("la mesa mantiene su materialidad sin contaminar el resto") se sostiene en código, no solo en documento.
- **Los chips numéricos tabulares** ("8/13", "76%", "2.5 BB") se leen como un registro visual distinto de la prosa incluso con la fuente de sistema — la firma tipográfica funciona parcialmente ya sin esperar a una tipografía nueva.
- **Elevación de 2 niveles alcanza.** Ninguna de las 3 pantallas echó en falta un tercer nivel ni glow/blur — las cards tocables (sombra de contacto corta) se distinguen bien de los paneles planos.

## 6. Qué decisiones no funcionaron / necesitaron ajuste

- **Overflow real en Home a 320-360dp.** El hero de "continuar" mostraba dos `ProtoChipNumeric` ("8/13 NIVELES" + "76% DOMINIO") en un `Row` fijo — desbordaba 70px a 320dp y 30px a 360dp (encontrado por el test automatizado de esta fase, `test/dev/design_playground_prototype_test.dart`, no a simple vista). **Corregido**: se cambió a `Wrap` (`home_prototype_preview.dart`, hero de continuar) — el segundo chip baja de línea en vez de desbordar. Aprendizaje: cualquier fila de `chip.numeric` necesita declarar wrap como comportamiento por defecto, no asumir que entra.
- **Deriva de duración entre `PressableScale` y los tokens nuevos.** El primitivo real usa 110ms fijos (`pressable_scale.dart:40`); los tokens de esta fase definen `instant=100ms`/`quick=160ms`. No rompe nada (110 está entre ambos y se siente bien), pero es una inconsistencia real entre "lo que ya existe" y "lo que se documentó" que Fase 2 tiene que resolver explícitamente, no ignorar.
- **Altura del fieltro en Laboratorio fue un número fijo (300dp)**, no derivado del ancho de pantalla real. La mesa real (`TableExplanationView.tableHeightFor`) sí calcula esto dinámicamente. El prototipo no lo necesitaba para validar la idea visual, pero una implementación real no puede usar un número mágico — tiene que reusar ese helper.
- **Contraste de `brass` como fondo de botón con texto oscuro** se ve bien a ojo pero no se midió formalmente en este prototipo (no hay una tipografía/peso final todavía) — queda como pendiente explícito, no como aprobado.

## 7. Qué problemas aparecieron

- El overflow de Home (§6), encontrado y corregido durante esta misma fase — ver commit de este prototipo.
- Ausencia de familia tipográfica real: el "look" de Display (peso 700, 28sp, fuente de sistema) no logra todavía la voz "editorial" que `FLOPLY_DESIGN_LANGUAGE.md` §5.2 describe — es una limitación esperada y ya documentada como fuera de alcance, pero vale reconfirmarla habiendo visto el resultado real: la diferencia entre Display y Headline hoy es solo de tamaño, no de carácter.
- Se confirmó (ya sabido, no introducido por esta fase) que `PokerAction` significa cosas distintas según el archivo: en `poker_action.dart` es una clase con factories (`PokerAction.raiseTo(bb)`); en `playable_exercise.dart` es un `typedef PokerAction = ActionType` (el enum). No es un bug de esta fase, pero conviene que quede anotado para quien retome el código de Laboratorio.

## 8. Qué ajustes necesita "Sala Verde"

- Formalizar en `FLOPLY_COMPONENTS.md` que un grupo de `chip.numeric` usa `Wrap`, nunca `Row`, por defecto.
- Decidir explícitamente el valor canónico de "responder/instant": ¿110ms (el que ya vive en `PressableScale`) pasa a ser el token oficial, o `PressableScale` se parametriza a 100ms? Ambas son válidas; lo que no puede pasar es que sigan siendo dos números distintos sin que nadie lo haya decidido.
- Cuando se implemente de verdad, la altura de cualquier mesa embebida debe derivar de `TableExplanationView.tableHeightFor` (o equivalente), nunca un valor fijo.
- Medir contraste real de `brass`/`brassDeep` una vez que la tipografía y los pesos finales estén definidos — no asumir que el valor de `FLOPLY_DESIGN_LANGUAGE.md` es definitivo solo porque "se ve bien" en este prototipo.

## 9. Qué NO debería implementarse globalmente todavía

- **Ninguna familia tipográfica** — sigue sin decidirse (deliberado).
- **Los números de ejemplo de Home** ("8/13 niveles", "76% dominio") son de muestra para probar layout, no datos reales ni un contrato de qué debe mostrar el hero — no copiar esos valores a producción.
- **La altura fija de 300dp del fieltro de Laboratorio** — es un placeholder de prototipo, no un valor de diseño final.
- **La des-colorización de las secciones de teoría** se probó con una sola teoría corta (T093, 6 secciones cortas). Antes de aplicarla a las 326 teorías del currículo (algunas con `ejemplo`/`errorComun` mucho más largos) hace falta repetir esta misma prueba con al menos una teoría larga — no generalizar todavía a partir de un solo caso favorable.
- **Ningún componente real** (`written_theory_view.dart`, `HomeHeader`, `PlayableTableExerciseView`, etc.) debe reemplazarse por su versión `Proto*` — siguen siendo prototipos de validación, no reemplazos listos para producción.

## 10. Recomendación para Fase 2

1. Repetir esta misma prueba con **una teoría larga** (no T093) y con **Tools** (todavía no probado) antes de dar por validado el sistema completo — el punto 9 de este documento es el gap más importante que queda.
2. Resolver la deriva de duración `PressableScale` (110ms) vs. tokens (`instant`/`quick`) como una decisión explícita, documentada, antes de que existan dos números en paralelo en código real.
3. Elegir las familias tipográficas reales (display/UI/numérica) con licencia — es el bloqueador más grande para que el sistema deje de sentirse "de sistema" y empiece a sentirse "de FLOPly" (la propia Fase 0.5 lo identificó como signature element #1).
4. Recién después de 1-3: empezar una migración **incremental y acotada**, arrancando por Home (la pantalla más aislada, sin dependencias de controllers complejos) — nunca por el widget de mesa jugable compartido entre Academia y Laboratorio, que es el de mayor blast radius.

No se migra nada en esta fase. Este documento y los 3 archivos de `lib/dev/design_playground/` son el entregable completo de la Fase 1.
