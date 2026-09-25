# FLOPly — Fase 3: Migración de Academia (mapa + teoría piloto) a "Sala Verde"

Segunda migración de producción. Alcance: `lib/screens/academy/widgets/level_map.dart` (mapa de niveles) y `lib/screens/academy/widgets/written_theory_view.dart` (ficha de teoría redactada, genérica para las 326 teorías), validada con T093 "Set" (corta) y TN10 "Implied odds" (larga, 7 secciones). Ejercicios, feedback, resultado y Bankroll — todos consumidores de `lesson_widgets.dart` compartido — quedaron fuera de alcance deliberadamente.

## 1. Qué se migró

- `LevelMap` y sus widgets privados (`_AcademyHeader`, `_ProgressStrip`, `_LevelCard`, `_LevelBadge`, `_LessonRow`): íntegro.
- `WrittenTheoryView` y sus widgets privados (`_TheoryCard`, `_SectionView`, `_Progress`): íntegro, más un footer de navegación nuevo y local (`_TheoryNavControls`).
- Como consecuencia de migrar el widget GENÉRICO de teoría (no un caso especial por ID), **las 326 teorías del currículo heredan automáticamente el nuevo lenguaje visual** la próxima vez que se abran — no fue necesario tocarlas una por una.

## 2. Qué NO se tocó

- `lesson_widgets.dart` completo (`LessonNavControls`, `LessonFlowHeader`, `LessonItemProgress`, `LessonPrimaryButton`, `LessonSecondaryButton`, `ratingBadge()`) — compartido con `exercise_view.dart`, `feedback_view.dart`, `lesson_result_view.dart`, `interactive_table_lesson.dart`, `mentor_lesson_stage_view.dart`, `visual_theory_stage.dart`, `theory_view.dart` **y `bankroll_screen.dart`**. Tocarlo hubiera sido exactamente el "cambio global no justificado" que esta fase prohíbe.
- `GlassCard` (`lib/widgets/glass_card.dart`) — quedó sin usar en `level_map.dart` (se reemplazó su uso por `SvSurfacePanel`), pero el archivo en sí no se modificó ni se borró.
- Currículo, IDs, prerrequisitos, desbloqueos, progreso, persistencia, evaluación pedagógica, contenido de las teorías, motor de póker, `PokerTableView`, `PlayableTableExerciseView`, Laboratorio, Tools, Bankroll funcional, Home (ya migrada en Fase 2, sin retocar), navegación/`AppShell`.
- El piloto visual mesa+burbuja (T093/T082/T098/T099, `academy_visual_theories.dart`/`visual_theory_stage.dart`) — sigue exactamente igual; la migración de esta fase empieza recién donde termina esa experiencia (la ficha escrita).

## 3. Archivos modificados / creados

Modificados: `lib/screens/academy/widgets/level_map.dart`, `lib/screens/academy/widgets/written_theory_view.dart`, `lib/theme/sala_verde/sala_verde_tokens.dart` (+`surfaceReading`/`ink*`/`brassDeep`), `lib/widgets/sala_verde/sala_verde_widgets.dart` (+`SvSurfacePanel`, `SvButtonSecondary`, `SvCalloutAccent`, `SvReadingCard`, `SvSectionHeader`).

Nuevos: `test/ui/academy_visual_migration_test.dart`, entradas nuevas en `test/widgets/sala_verde_widgets_test.dart` (`SvSectionHeader`).

## 4. Componentes creados/reutilizados

**Nuevos (Checkpoint 2):** `SvSectionHeader` (con guardrails — `variant` en vez de `Color` libre, 4 valores cerrados: `academy`/`laboratory`/`tools`/`brand`, cada uno ya resuelto a su variante `*Bright` segura), `SvSurfacePanel`, `SvButtonSecondary`, `SvCalloutAccent`, `SvReadingCard`.

**Reutilizados sin cambios:** `PressableScale`, `SvButtonPrimary`, `SvProgressLinear` (de Fase 2).

**Descartados explícitamente:** un `SvAcademyLevelCard`/`SvLessonRow` dedicados — se evaluó (pregunta 23 del prompt maestro: "¿ya existe? ¿se usa en más de un contexto?") y no se justificaba: son composiciones de `SvSurfacePanel`+`PressableScale`+tokens que solo aparecen en este archivo, sin repetirse en otro contexto de Academia todavía.

## 5. Decisiones visuales

- **Regla anti-fragmentación aplicada por primera vez en producción:** las 7 secciones de una teoría (QUÉ ES/POR QUÉ IMPORTA/…) dejaron de tener un ícono+color propio cada una (7 combinaciones distintas en el código anterior) — ahora es un eyebrow tipográfico uniforme. Validado con TN10 (la más exigente) antes de aplicarse.
- **Corrección semántica real, no solo visual:** el acento "en progreso" de un nivel usaba `neonGreenBright` (temperatura de Laboratorio) en el código anterior — un mismatch preexistente. Ahora usa `feltGreenBright` (temperatura real de Academia).
- **Cifras con firma tipográfica real:** el número de nivel dentro del badge y el score (%) de una lección completada pasan a IBM Plex Mono — antes eran texto normal.
- **Brass permanece escaso:** ninguna de las 2 pantallas migradas usa `brass` como relleno de superficie más de una vez (el CTA "CONTINUAR"/"PRACTICAR" de la teoría es el único caso).

## 6. `SvSectionHeader`

Primer consumidor real: encabezado del mapa (`_AcademyHeader`). API deliberadamente angosta (`icon`/`title`/`subtitle`/`variant`/`trailing`) — `variant` es un enum de 4 valores, cada uno ya resuelto a su color de contraste correcto; no expone un parámetro `Color accent` libre que pudiera reintroducir el bug de contraste de Fase 2. Cubierto por 4 tests dedicados (título corto, título largo real a 300dp, contraste de las 4 variantes, con `trailing`).

## 7. `surfaceReading`

Primera validación real en producción — con contenido real, no de muestra. Resultado: **sostiene la lectura sin decoración**, en la teoría corta (T093, 6 secciones) y en la larga (TN10, 7 secciones, párrafos más extensos) con el mismo widget, sin ningún ajuste estructural entre una y otra. Responde las preguntas de QA del prompt maestro:

- ¿Ayuda a leer? Sí — el cambio de superficie oscura a marfil es una señal wordless de "ahora estás leyendo" (mismo hallazgo que Fase 1.5/1.75, ahora confirmado con datos reales de producción).
- ¿Separa contenido de navegación? Sí — la superficie de lectura vive dentro de un fondo general oscuro; los controles ATRÁS/CONTINUAR quedan claramente fuera de ella.
- ¿Funciona en teoría corta y larga? Sí, sin cambios entre una y otra.
- ¿Parece editorial o SaaS? Editorial — sin bordes de acento por sección, sin badges, sin sombras dentro de la superficie de lectura.

## 8. Responsive

38 tests nuevos en `test/ui/academy_visual_migration_test.dart`: mapa en 9 anchos (300-480dp) + altura reducida (375×568) con 5 puntos de progreso (0/1/50/99/100%); T093 y TN10 cada una en los mismos 9 anchos + altura reducida, navegando por el controller y la pantalla REALES (no un harness aislado). Sin overflow en ningún caso.

## 9. Accesibilidad

Sin fallas nuevas — todos los colores usados (`feltGreen`/`feltGreenBright`, `success`, `brassDeep`, `textMuted`) ya estaban verificados con contraste real en Fase 1.5/1.75/2 para exactamente estos contextos de uso (relleno vs. texto/ícono vs. superficie clara). `test/accessibility/core_screens_accessibility_test.dart` sigue verde.

## 10. QA

Ver sección "K. Estado del código" del informe final — `flutter analyze`: 0 issues; `flutter test`: 1171/1171. Visual QA real en navegador: ver §11.

## 11. Visual QA real (Chromium/Playwright)

Se sirvió `AcademyScreen` de producción real (sin Firebase, `AcademyController` local, progreso parcial real de 64 lecciones) en un navegador real vía `flutter run -d web-server` + Chromium (Playwright), a 400×900. Resultado:

- **Mapa:** header con ícono verde + "ACADEMIA" en Fraunces; tira de progreso con barra verde parcialmente llena (confirma que `SvProgressLinear` sí muestra el fill correcto cuando `value>0`, complementando la verificación de Fase 2 que solo cubrió 0%); niveles completados con borde/check verde; nivel bloqueado con candado gris, opacidad reducida y título atenuado — el estado se distingue por ícono Y color a la vez, no solo por uno.
- **TN10 (larga, 7 secciones) — validación completa:** superficie marfil claramente diferenciada del fondo oscuro general; título "Implied odds" en un serif distintivo (Fraunces real); las 7 secciones (QUÉ ES → ERROR COMÚN) uniformes, sin color/ícono por sección, perfectamente legibles con contenido real largo; "IDEA CLAVE" con la variante `brassDeep` (fix de Fase 1.75) claramente legible sobre el marfil — nunca se vio el bug original de `brass` puro (2.17:1); "OBJETIVO" en verde sobre marfil, legible; scroll interno funciona, sin overflow ni texto cortado; controles ATRÁS/CONTINUAR nuevos (`_TheoryNavControls`) con un único acento dorado (CONTINUAR).
- **T093 (corta) + piloto visual:** la mesa (`PokerTableView`/`VisualTheoryStageView`) se ve intacta — madera, fieltro, ficha de bote, burbuja de diálogo — exactamente como antes de esta fase, confirmando que no se tocó ni se filtró nada del chrome nuevo hacia la mesa.
- **Hallazgo real (no un bug, una confirmación del riesgo ya documentado):** en la pantalla de teoría se ve claramente la costura entre `LessonFlowHeader` (arriba, todavía en violeta — compartido, fuera de alcance) y la ficha de teoría migrada (abajo, marfil/Sala Verde) — visualmente confirma la limitación ya anotada en §15, no algo nuevo que corregir en esta fase.
- **Confirmación de aislamiento:** al avanzar de más (seis taps en vez de los necesarios), se llegó a la pantalla de resultado de lección ("¡Lección completada!") — sigue 100% en el lenguaje visual anterior (violeta), confirmando que `lesson_result_view.dart` (compartido, fuera de alcance) no se vio afectado por los cambios de esta fase.

No se encontraron bugs visuales nuevos en esta ronda (a diferencia de Fase 2, donde la verificación en navegador encontró la barra de progreso invisible). El único hallazgo fue la costura ya documentada del header compartido, que no es un bug sino el límite de alcance ya decidido y explicado en §2/§15.

## 12. Goldens

`AcademyScreen (mapa de niveles)` regenerado tras inspección visual manual de la imagen resultante (estructura, colores y estados confirmados correctos antes de aceptar el nuevo baseline) — no se usó `--update-goldens` como mecanismo ciego. Los otros 4 goldens (Home/Tools/Bankroll/Laboratorio) sin cambios.

## 13. Problemas encontrados

Ninguno nuevo. La única falla real fue en el propio test inicial de QA (`test/ui/academy_visual_migration_test.dart`), no en el código de producción: el helper `_openTheory` no consideraba que T093 pasa primero por el piloto visual mesa+burbuja antes de la ficha escrita — el `find.text('Set')` fallaba porque la pantalla realmente mostrada todavía era la mesa visual, no `WrittenTheoryView`. Corregido agregando el mismo paso de "caminar" la UI visual que ya usa `test/ui/visual_theory_pilot_test.dart` (`walkVisualByUi`).

## 14. Bugs corregidos

Ninguno en código de producción — a diferencia de Fase 2 (que encontró y corrigió 2 bugs reales de contraste/visibilidad), esta fase no encontró ningún bug nuevo ni en los tests automatizados ni en la verificación visual real en navegador. Los 2 componentes nuevos de mayor riesgo (`SvSectionHeader`, con guardrails desde el diseño; `SvReadingCard`/`SvCalloutAccent`, ya usados y corregidos en el playground de Fase 1.5) llegaron a producción sin defectos propios.

## 15. Limitaciones / deuda visual

- El header de todo el recorrido de lección (`LessonFlowHeader`, mostrado arriba de la ficha de teoría) sigue en violeta/estilo anterior — es compartido con exercise/feedback/result/Bankroll, fuera de alcance. Esto crea una costura visible: chrome viejo arriba, contenido Sala Verde abajo, específicamente en la pantalla de teoría.
- Los controles ATRÁS/CONTINUAR de la teoría (`_TheoryNavControls`, nuevo) duplican la forma de `LessonNavControls` (compartido) en vez de generalizarlo — deuda de duplicación aceptada conscientemente por blast radius, documentada acá para no repetirla sin pensar en Fase 4.
- Ejercicios/feedback/resultado de Academia (fuera de alcance) siguen 100% en el lenguaje visual anterior — la sensación de "misma pantalla, mismo lenguaje" solo existe entre mapa y teoría hoy, no en el recorrido completo de una lección.

## 16. Blast radius confirmado

`GlassCard`: sin otros consumidores además de `level_map.dart` (ahora ninguno) — confirmado por grep antes de decidir no migrarlo. `lesson_widgets.dart`: 10 consumidores reales, incluido Bankroll — confirmado por grep antes de decidir no tocarlo.

## 17. Recomendaciones para Fase 4

Antes de migrar el resto de Academia (ejercicios/feedback/resultado), resolver la costura de `LessonFlowHeader` — es compartida con Bankroll, así que su migración probablemente deba ir junto con (o inmediatamente antes de) una migración de Bankroll, no aislada dentro de "más Academia". Laboratorio y Tools siguen recomendados como migraciones independientes posteriores, no antes.
