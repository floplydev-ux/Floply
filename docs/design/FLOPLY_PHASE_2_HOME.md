# FLOPly — Fase 2: Migración de Home a "Sala Verde"

Primera migración de producción del sistema visual validado en Fases 0.5-1.75. Alcance: exclusivamente `lib/screens/home/` y los 2 archivos nuevos que necesitó (`lib/theme/sala_verde/sala_verde_tokens.dart`, `lib/widgets/sala_verde/sala_verde_widgets.dart`, más un componente Home-scoped, `sv_home_link_card.dart`). Ningún otro archivo de producción se modificó.

## A. Estado anterior

| Elemento | Función actual | Debe conservarse | Tratamiento visual nuevo |
|---|---|---|---|
| `HomeScreen` (Scaffold + fondo + scroll + animación de entrada) | Compositor puro, arma orden de secciones, sin lógica propia | Sí, íntegro | Fondo plano en vez de degradé de 2 colores (`FLOPLY_ANTI_GENERIC.md` regla 5) |
| `HomeHeader` (avatar + saludo + botón ajustes) | Identidad de usuario, abre perfil | Sí, íntegro | Tipografía Public Sans, sin cambios de estructura/accesibilidad |
| `UserAvatar` (compartido) | Círculo de foto/inicial | Sí — **no migrado**, widget compartido fuera de este alcance | Sin cambios (sigue con su gradiente violeta propio) |
| `ContinueLearningCard` (4 estados: cargando/nuevo/progreso/completo) | Responde "¿dónde estoy? ¿qué sigue?" desde `AcademyController` real | Sí, los 4 branches exactos, mismas strings, mismo `_continue()` | Superficie plana `surfaceElevated` (no degradé violeta), CTA en `brass` (único relleno brass de la pantalla), progreso en `feltGreenBright`, título de lección en Fraunces |
| `PracticeRoomCard` | Delegaba en `HomeLinkCard` compartido, acento `neonGreen` | Sí, mismo comportamiento | Migra a `SvHomeLinkCard` propio de Home, acento `steelBlueBright` (temperatura de Laboratorio) |
| 3× `HomeLinkCard` (Bankroll/Tools/Coach) inline en `home_screen.dart` | Navegación a Bankroll/Tools/placeholder Coach | Sí, mismas rutas | Migran a `SvHomeLinkCard`, acentos `brass`/`graphiteSteelBright`/`textMuted` |
| `lib/widgets/home_link_card.dart` | Compartido con `ToolsScreen` | Sí — **no migrado**, fuera de alcance (tocarlo afectaría Tools) | Sin cambios |
| Animación de entrada (`_entranceController`, 700ms, stagger por sección) | Aparición escalonada al abrir Home | Sí, sin cambios | No es parte del sistema de motion canónico (`instant/fast/normal/emphasis`) — es una animación de entrada de pantalla ya validada, fuera de alcance de esta migración visual |

## B. Cambios visuales

- Fondo: degradé `AppColors.backgroundGradient` → `SalaVerdeColors.background` plano.
- Hero de Academia: degradé violeta con borde/sombra tintada → superficie plana `surfaceElevated` + borde sutil + sombra de contacto (elevación nivel 1) — la misma card tocable que usa el resto de la pantalla, no un tratamiento especial.
- CTA de la hero: degradé `violetGradient` con texto blanco fijo → `SvButtonPrimary` (relleno `brass`, color de texto elegido por contraste real).
- Barra de progreso: degradé violeta, 900ms → `SvProgressLinear`, color plano `feltGreenBright`, 320ms (`emphasis`, sistema canónico).
- Ícono de "completado": `neonGreen`/`neonGreenBright` (temperatura de Laboratorio, semánticamente incorrecta para un logro de Academia) → `success` (semántico real, ya pasa contraste sin necesitar variante Bright).
- Practice Room / Tools / Bankroll / Coach: cards con fondo teñido por el color de acento → superficie plana + ícono chico teñido (patrón validado en el playground, Fase 1.5).
- Tipografía: sistema → Fraunces (título de lección/logro), Public Sans (todo lo demás), IBM Plex Mono (el % de progreso).

## C. Componentes reutilizados

`PressableScale` (sin cambios), `UserAvatar` (sin cambios, no migrado), `AcademyController`/`AppUser`/`AppStrings`/`NavDestination` (sin cambios — capa de datos intacta).

## D. Componentes nuevos

- `lib/theme/sala_verde/sala_verde_tokens.dart` — colores/spacing/radius/elevación/motion/tipografía de producción (promovidos del playground, con las correcciones de Fase 1.5/1.75 ya incorporadas).
- `lib/widgets/sala_verde/sala_verde_widgets.dart` — `SvTappableCard`, `SvButtonPrimary`, `SvChipNumeric`+`SvChipNumericGroup` (guardrail), `SvProgressLinear`.
- `lib/screens/home/widgets/sv_home_link_card.dart` — link card scoped a Home (no se tocó `lib/widgets/home_link_card.dart`, compartido con Tools).

Ninguno de los 3 fue una sorpresa — los 3 estaban previstos desde el cierre de Fase 1.75 (`FLOPLY_DESIGN_DECISIONS.md`).

## E. Tokens utilizados

Colores: `background`, `surface`/`surfaceElevated`, `brass`/`brassBright`, `feltGreen`/`feltGreenBright`, `steelBlueBright`, `graphiteSteelBright`, `success`, `textPrimary`/`textSecondary`/`textMuted`, `borderSubtle`. Spacing: `sm/md/lg/xl`. Radius: `sharp/control`. Elevación: nivel 1. Motion: `emphasis` (320ms, barra de progreso). Tipografía: los 3 roles + el rol numérico.

Ningún token nuevo tuvo que improvisarse — los 2 que Home necesitaba y no existían todavía (`steelBlueBright`, `graphiteSteelBright`) se agregaron de forma controlada a `sala_verde_tokens.dart` (no como constantes locales sueltas).

## F. Tipografía integrada

Fraunces (variable, `wght`+`opsz`) + Public Sans (variable, `wght`) + IBM Plex Mono SemiBold (estático) — empaquetados como assets reales en `assets/fonts/` y declarados en `pubspec.yaml` (`flutter: fonts:`), sin el paquete `google_fonts` (sin dependencia de red en runtime). Las 3 bajo SIL OFL 1.1, verificado (ver `FLOPLY_DESIGN_DECISIONS.md` #3).

**Verificación real (Paso 4) — completada con éxito.** El sandbox de `flutter test` no tiene shaper de fuentes representativo (confirmado en Fase 1.75 — todo cae a un glifo de reemplazo genérico). Para esta fase se sirvió la Home real de producción (con `AcademyController` local, sin Firebase — mismo patrón que `test/ui/home_screen_test.dart`) en un navegador real vía `flutter run -d web-server` + Chromium (Playwright), a 400×860 (tamaño de teléfono). Resultado: **las 3 fuentes cargan y renderizan correctamente** — el título de lección se ve en un serif distintivo (Fraunces, claramente diferenciado del resto), el cuerpo en Public Sans es limpio y legible, y el "0%" numérico junto a la barra de progreso usa la fuente monoespaciada. Caracteres españoles con tilde ("Empezá a aprender póker") renderizan sin problema. Este es el primer render real de "Sala Verde" con tipografía de producción en toda la Fase 2-1.75-1.5-1 — resuelve la limitación de la Fase 1.75 (esa vez el sandbox de test no podía shapear ninguna fuente).

## G. Motion utilizado

Solo `emphasis` (320ms) en la barra de progreso, migrada desde el valor ad hoc anterior (900ms). El resto de Home no tiene motion propio más allá de `PressableScale` (110ms, `instant`, sin cambios) y la animación de entrada de pantalla (fuera del sistema canónico, ver tabla A).

## H. Estados probados

Usuario nuevo, con progreso, Academia completa, cargando (los 4 branches reales de `ContinueLearningCard`, sin ninguno nuevo ni eliminado) — los 4 ya cubiertos por `test/ui/home_screen_test.dart`, que sigue pasando sin modificar sus aserciones de comportamiento. No existe un "empty state"/"error state" real en la Home de producción hoy (a diferencia del prototipo, que sí construyó ese patrón como ejercicio) — no se inventó uno.

## I. Responsive

Barrido ampliado de 5 a 9 anchos (300/320/360/375/390/412/414/430/480dp, antes solo 320/360/390/412/430) + 2 casos de altura reducida (375×568, usuario nuevo y con progreso) — todos sin overflow. Ver `test/ui/home_screen_test.dart`.

## J. Accesibilidad

`test/accessibility/core_screens_accessibility_test.dart` (ya existente, cubre `AppShell`/Home real, no un mock) encontró una falla de contraste real durante la migración — ver §L. Corregida y re-verificada: la suite completa de accesibilidad pasa.

## K. Comparación antes/después

El golden baseline (`test/golden/screens_golden_test.dart`, "HomeScreen (usuario nuevo)") se regeneró tras revisar la imagen resultante — confirma visualmente: fondo plano, hero con superficie `surfaceElevated` + barra de progreso verde + un único CTA dorado, Practice Room con ícono azulado, Bankroll con ícono dorado (sin relleno dorado de card), Tools con ícono grisáceo-azulado, Coach visiblemente más apagado (`muted`). La composición/orden/densidad es idéntica a la Home anterior — solo cambió la piel visual, confirmando "MISMA HOME, NUEVO LENGUAJE".

Verificación en navegador real (Chromium vía Playwright, `flutter run -d web-server`, `AcademyController` local sin Firebase): confirmó todo lo anterior con tipografía real cargada, y expuso el problema del track de progreso (§L.2) que ningún test automatizado había detectado — a 0% de progreso, la barra era literalmente invisible.

## L. Problemas encontrados

1. **Falla de contraste real en el CTA "COMENZAR ACADEMIA"** (`test/accessibility/core_screens_accessibility_test.dart`): 2.16:1 (falla AA) entre `textPrimary` y `brass`. Causa: `SvButtonPrimary` decidía el color de texto con un umbral de luminancia adivinado (`computeLuminance() > 0.4`) — `brass` mide 0.36, por debajo del umbral, así que elegía la pareja incorrecta. El mismo bug ya vivía en el playground (`ProtoButtonPrimary`) sin que ningún test lo hubiera medido hasta ahora.
2. **Barra de progreso invisible a 0% (usuario nuevo)** — encontrado únicamente al mirar la Home real en un navegador, no por ningún test automatizado. Causa: `SvProgressLinear` pintaba su track con `surfaceElevated`, el mismo color exacto que la card (`_HeroShell`) donde vive — track y fondo se fundían en uno solo.
3. Golden test desactualizado dos veces durante esta fase (esperado — cada uno fue un cambio visual intencional, no un bug: primero el rediseño completo, después el color del track).

## M. Problemas corregidos

1. `SvButtonPrimary` (y `ProtoButtonPrimary` en el playground, mismo bug) ahora comparan el contraste real contra las 2 opciones (`background` vs. `textPrimary`) y usan la que mida más — sin umbral fijo. Verificado con un test dedicado (`test/widgets/sala_verde_widgets_test.dart`) que reproduce exactamente el caso real (`brass`) y uno adicional (`steelBlueBright`) para confirmar que la solución generaliza.
2. `SvProgressLinear` (y `ProtoProgressLinear` en el playground, mismo bug) ahora usa `borderSubtle` para el track — un paso más claro que `surfaceElevated`, visible incluso sin relleno. Confirmado visualmente en el navegador tras el fix.
3. Golden de Home regenerado dos veces, cada vez tras revisión visual de la imagen resultante.

## N. Problemas pendientes

- Las cifras embebidas en oraciones (`AppStrings.academyLessonsDone`, "8 de 13 lecciones completadas") siguen en Public Sans — separar los dígitos a IBM Plex Mono requeriría `RichText`/`TextSpan` y se dejó fuera de esta fase por riesgo/alcance; el % standalone junto a la barra de progreso sí usa la fuente numérica.
- La verificación tipográfica se hizo en Chromium (navegador de escritorio) vía Playwright — no en un dispositivo Android real ni un emulador (ninguno disponible en este entorno). El shaping de fuentes en Chromium usa un motor distinto al de un dispositivo Android/iOS real; confirma que las 3 fuentes cargan y se aplican correctamente, pero no reemplaza una verificación en el motor de render móvil real antes de un lanzamiento a producción.
- `SvSectionHeader` (el otro componente con guardrail pendiente de Fase 1.75) sigue sin promoverse — Home no lo necesita; queda para cuando se migre Academia/Tools/Laboratorio.

## O. Impacto sobre el resto de la app

Ninguno funcional. Cambios de superficie compartida, acotados: `pubspec.yaml` (declaración de 3 fuentes nuevas — aditivo, no quita nada) y `assets/fonts/` (3 archivos nuevos). `AppColors`/`AppTheme` sin tocar. `lib/widgets/home_link_card.dart` (usado por Tools) sin tocar. `PokerTableView`/`PlayableTableExerciseView`/currículo/progreso/unlocks/motor de póker: sin tocar, confirmado por `git diff`.

## P. Recomendación para la siguiente migración

Academia (mapa de niveles + teoría) es el siguiente candidato natural: ya tiene el componente que le falta a Home (`SvSectionHeader`, con su guardrail todavía pendiente de diseñar) y permite probar `surfaceReading`/`ProtoReadingCard` en producción con contenido real por primera vez. No migrar Laboratorio/Tools todavía — ambos comparten el widget de mesa jugable (`PlayableTableExerciseView`), el de mayor blast radius del proyecto.
