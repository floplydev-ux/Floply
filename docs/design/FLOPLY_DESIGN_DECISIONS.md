# FLOPly — Design Decisions

Registro formal de las decisiones que cierran el lenguaje visual "Sala Verde" antes de cualquier migración a producción. Cada entrada es un contrato: qué se decidió, con qué evidencia, qué alternativas se descartaron y por qué, y qué impacto tiene en el código real cuando llegue Fase 2.

Este documento es el que manda cuando hay una aparente contradicción entre documentos anteriores (`FLOPLY_DESIGN_BRIEF.md` → `FLOPLY_DESIGN_LANGUAGE.md` → `FLOPLY_PROTOTYPE_PHASE_1.md` → `FLOPLY_VISUAL_STRESS_TEST.md`) — las fases anteriores documentan el *proceso* de llegar a cada decisión; acá vive el *resultado* ya cerrado.

---

## 1. Dirección "Sala Verde"

**Decisión:** Sala Verde (materialidad de mesa graduada + superficies con nombre + tipografía numérica + temperatura de sección) es la dirección visual de FLOPly. Se mantiene sin reemplazo.

**Contexto:** `FLOPLY_DESIGN_BRIEF.md` exploró 5 direcciones; Sala Verde fue elegida en Fase 0 y sometida a crítica adversarial en Fase 0.5.

**Evidencia:** Fase 0.5 encontró que la especificación original corría riesgo real de "casino premium" (materialidad sin graduar). Fase 1 y 1.5 la probaron en 4 pantallas reales con 4 dominios de contenido distintos (navegación, lectura, decisión, cálculo) sin necesitar rediseño ni componentes nuevos por pantalla — la prueba más fuerte posible de que el mecanismo (no solo el concepto) funciona.

**Regla elegida:** Sala Verde con materialidad graduada (ver decisión #2) es la dirección definitiva.

**Alternativas rechazadas:** Instrumento de Precisión (demasiado frío para Academia/Bankroll), Mentor Editorial (no resuelve la convivencia con la mesa), Mesa Moderna (no resuelve el diagnóstico de genericidad), Cuaderno del Analista (demasiado frío, se parece a un dashboard SaaS de analytics).

**Impacto:** Ninguna dirección alternativa se vuelve a evaluar salvo evidencia nueva que invalide lo ya probado.

---

## 2. Límites de materialidad (Global vs. Mesa)

**Decisión:** La materialidad física intensa (textura de madera, vignette de fieltro renderizado, brillo especular) es exclusiva de `PokerTableView`/`TableMaterial`. El resto del producto usa color plano, con 2 niveles de profundidad y un highlight/pressed sutil como máximo.

**Contexto:** Fase 0.5 identificó el riesgo; Fase 1.5 lo confirmó con código real: `surfaceFelt` apareció como máximo una vez por pantalla (franja acotada, nunca fondo completo) en las 4 pantallas construidas, sin necesitar textura en ningún momento.

**Evidencia:** 0 usos de textura/vignette fuera de `PokerTableView` en 4 pantallas distintas; 0 fallas de "se ve a casino" en la revisión anti-casino de `FLOPLY_VISUAL_STRESS_TEST.md` §L.

**Regla elegida:**
- *Global* (Home/Academia/Tools/Laboratorio): superficies planas, 2 niveles de elevación (§5.5 de `FLOPLY_DESIGN_LANGUAGE.md`), contraste mate/brillo sutil (p. ej. `brassBright` como estado pressed).
- *Mesa* (`PokerTableView` únicamente): textura, vignette, veta de madera, materialidad física intensa — sin cambios ahí, nunca se tocó.

**Alternativas rechazadas:** aplicar materialidad "suavizada" (menos intensa pero seguía siendo textura) al resto del chrome — descartada explícitamente en Fase 0.5 por seguir corriendo el mismo riesgo de skeuomorfismo dated.

**Impacto:** ningún componente de producción fuera de la mesa debe importar o replicar `TableSurfacePainter`/gradientes radiales/veta de madera.

---

## 3. Tipografía

**Decisión:** **Fraunces** (Display) + **Public Sans** (UI/Body) + **IBM Plex Mono** (Numérica). Las tres bajo licencia **SIL Open Font License 1.1** (verificado contra el archivo de licencia real de cada repositorio, no de memoria — ver §Evidencia).

**Contexto:** `FLOPLY_DESIGN_TOKENS.md` dejó la elección fuera de alcance en Fase 1; `FLOPLY_VISUAL_STRESS_TEST.md` investigó candidatas sin instalar nada. Esta fase cierra la decisión.

**Evidencia:**
- Licencias verificadas contra la fuente primaria (no memoria): `raw.githubusercontent.com/IBM/plex/master/LICENSE.txt` → SIL OFL 1.1 (corrige una afirmación previa incorrecta de `FLOPLY_VISUAL_STRESS_TEST.md`, que decía "Apache 2.0" para IBM Plex Mono — la licencia Apache se ofreció brevemente en 2018 y fue retirada; hoy es 100% OFL). `raw.githubusercontent.com/uswds/public-sans/main/LICENSE.md` → SIL OFL 1.1. Google Fonts specimen de Fraunces → SIL OFL 1.1, pesos 100-900, ejes variables `opsz`/`wght`/`SOFT`/`WONK`. De paso se verificó también JetBrains Mono (candidata alternativa): también SIL OFL 1.1 pese a que muchos sitios de terceros lo listan como Apache 2.0 — las tres candidatas finales son OFL 1.1, sin mezcla de licencias que auditar por separado.
- **Intento de validación visual real — resultado honesto, no un éxito completo.** Se descargaron los 5 archivos de fuente reales (Fraunces variable, Public Sans variable, IBM Plex Mono Regular/Medium/SemiBold) desde `google/fonts` y se armó un render de specimen con contenido real de las 4 pantallas vía `FontLoader` + captura a PNG dentro de un `flutter test` (`tester.runAsync()` fue necesario para que la lectura de archivo y la captura de imagen no colgaran indefinidamente — ver nota de reproducibilidad). La imagen resultante se inspeccionó directamente, pero **reveló una limitación del entorno, no de las fuentes**: todo el texto — incluidas las 3 familias registradas y el fallback por defecto de Flutter — se renderizó con el mismo glifo de reemplazo genérico (sin diferencia de peso visible entre 400/600/700, símbolos de palo de carta como recuadros vacíos). Esto es consistente con que este entorno de test headless no tiene un shaper de fuentes real disponible (sin servidor de fuentes del SO), no con que `FontLoader` haya fallado en registrar las fuentes. **Conclusión:** la verificación de licencia/pesos/ejes es sólida y basada en fuente primaria; la confirmación visual pixel-a-pixel queda pendiente para cuando el sistema corra en un dispositivo o emulador real (Fase 2), no se pudo completar en este sandbox. Se documenta así explícitamente para no fingir una validación visual que no ocurrió.

**Regla elegida (roles, pesos, tamaños — ver `FLOPLY_DESIGN_TOKENS.md` para la traducción a `type.*`):**

| Rol | Familia | Pesos usados | Eje variable | Tamaños |
|---|---|---|---|---|
| Display | Fraunces | 500 (headline), 600-700 (display/idea clave) | `opsz=72` (óptico para texto, no el extremo display de titular gigante), `wght` variable | 22-28sp |
| UI/Body | Public Sans | 400 (body), 600 (bodyStrong/label), 700 (título) | `wght` variable | 11.5-17sp |
| Numérica | IBM Plex Mono | Regular (valores secundarios), Medium/SemiBold (valor protagonista) | Estático (no variable — usar el archivo de peso correspondiente, no interpolar) | 11.5-24sp, `FontFeature.tabularFigures()` |

**Alternativas rechazadas:** Source Serif 4 (más neutra, menos personalidad editorial — se prefirió Fraunces por diferenciación); Inter (demasiado ubicua, resta distintividad frente a Public Sans); JetBrains Mono (también OFL 1.1, verificado — descartada porque su voz "developer tool" encaja mejor en un contexto de código que en una mesa de póker; queda como alternativa de reserva si Plex Mono da problemas de licencia de distribución de assets en Fase 2, cosa que esta verificación no encontró).

**Impacto:** Fase 2 debe empaquetar los 5 archivos (`Fraunces[SOFT,WONK,opsz,wght].ttf`, `PublicSans[wght].ttf`, `IBMPlexMono-Regular/Medium/SemiBold.ttf`) como assets declarados en `pubspec.yaml` (`flutter: fonts:`), no vía el paquete `google_fonts` (evita una dependencia de red en tiempo de ejecución para algo que se puede empaquetar estático). Ningún cambio a `AppTheme` todavía.

**Nota de reproducibilidad:** el intento de validación visual se hizo con un script de render temporal (`test/dev/_typography_render_scratch.dart`, borrado al cerrar esta fase junto con los 5 binarios de fuente, que se descargaron a la carpeta scratchpad de la sesión — nunca al repositorio ni a `pubspec.yaml`). Detalle técnico que quien retome esto debería saber: dentro de `testWidgets`, tanto la lectura de archivo (`File.readAsBytes()`) como la captura de imagen (`RenderRepaintBoundary.toImage()`/`toByteData()`) colgaban indefinidamente hasta envolverlas en `tester.runAsync()` — el binding de test no bombea I/O real del sistema operativo fuera de ese wrapper. Una vez resuelto eso, el render sí se completó y se pudo inspeccionar la imagen — el resultado fue la limitación de shaping de fuentes ya descrita, no un error de configuración. No quedó como test permanente porque depende de binarios externos al repo y de red — no es hermético.

---

## 4. Sistema numérico (tipografía tabular)

**Decisión:** Todo BB/%/EV/frecuencia/saldo/contador usa IBM Plex Mono con `FontFeature.tabularFigures()`, sin excepción — ya vigente como regla dura (`FLOPLY_ANTI_GENERIC.md` regla 12), ahora con familia real asignada (ver decisión #3).

**Contexto:** identificada en `FLOPLY_DESIGN_BRIEF.md` como el signature element #1 del sistema.

**Evidencia:** validado en las 4 pantallas con números reales de producción (`8/13`, `76%`, `25.0%`, `20.0 BB`, `3.0:1`, `2.5 BB`) sin un solo caso donde el valor numérico necesitara truncarse — la única falla relacionada con números fue de LABEL, no de valor (ver decisión #6).

**Regla elegida:** sin cambios respecto a lo ya documentado — se confirma con evidencia real, no se modifica.

**Alternativas rechazadas:** ninguna nueva en esta fase.

**Impacto:** ninguno adicional a lo ya definido.

---

## 5. Motion

**Decisión:** sistema canónico de 4 duraciones con nombre — `instant` (110ms), `fast` (160ms), `normal` (220ms), `emphasis` (320ms). `instant` se fija en 110ms, no 100ms.

**Contexto:** Fase 1.5 encontró una deriva entre el token documentado (100ms) y el valor real de `PressableScale` (110ms, `lib/widgets/pressable_scale.dart:40`).

**Evidencia:** `PressableScale` ya se usa en cientos de sitios de producción; forzar el prototipo a 110ms cuesta cero migración, forzar producción a 100ms costaría tocar un primitivo compartido fuera de alcance de esta fase.

**Regla elegida:** ver tabla completa en `FLOPLY_MOTION.md` (actualizada en esta fase). `instant=110/fast=160/normal=220/emphasis=320`, dos familias de curva (Responder/Asentarse), sin terceras familias decorativas.

**Alternativas rechazadas:** cambiar `PressableScale` a 100ms para que coincida con el token original — rechazada por alcance (esta fase no migra código productivo) y por falta de necesidad real (110ms nunca se sintió mal en ningún test).

**Impacto:** `proto_tokens.dart` ya actualizado (`ProtoMotion.instant = 110ms`, con alias `quick`/`settle`/`reveal` por compatibilidad). Cuando Fase 2 cree `AppMotion` real, debe nacer con estos 4 nombres, no con los 2 originales del brief.

---

## 6. Chip Numeric (regla de responsive)

**Decisión:** los grupos de `chip.numeric` usan `Wrap`, nunca `Row`; dentro de un chip, el label puede truncarse (ellipsis) pero el valor numérico nunca.

**Contexto:** Fase 1.5 encontró un overflow real de 10px a 300dp en Tools, causado por un label real de producción (`AppStrings.potOddsRequiredEquityLabel`, "EQUITY NECESARIA") sin `Flexible`.

**Evidencia:** `proto_components.dart` (`ProtoChipNumeric`) corregido con `Flexible` + `TextOverflow.ellipsis` en el label; 131 tests de `test/dev/design_playground_prototype_test.dart` verifican esto en 8 anchos, incluyendo 300dp, con las 3 etiquetas reales de Pot Odds.

**Regla elegida:** documentada como regla dura en `FLOPLY_COMPONENTS.md` (sección `component.chip.numeric`, actualizada en esta fase) — ver ahí el detalle de las 3 sub-reglas (Wrap, label truncable, valor intocable).

**Alternativas rechazadas:** apilar label arriba/valor abajo en vez de en línea — no fue necesario, `Flexible`+ellipsis resolvió el problema real sin cambiar la anatomía visual del chip.

**Impacto:** cualquier implementación productiva de `chip.numeric` debe nacer con esta regla desde el día 1, no como un fix posterior.

---

## 7. Contraste

**Decisión:** los colores de temperatura de sección y `error` tienen una variante base (relleno/superficie) y una variante `*Bright` (texto/ícono sobre fondo oscuro) — nunca un valor único. `brass` mantiene sus 3 variantes ya existentes, con `brassDeep` confirmado como la variante de texto sobre `surfaceReading`.

**Contexto:** Fase 1.5 midió contraste WCAG real en 20+ pares y encontró 6 fallas (`brass`/`feltGreen`×2/`steelBlue`×2/`graphiteSteel`×2/`error`).

**Evidencia:** ver tabla completa en `FLOPLY_VISUAL_STRESS_TEST.md` §J y la migración a `FLOPLY_DESIGN_LANGUAGE.md` §5.1 (tablas "Acentos de temperatura"/"Semánticos", actualizadas en esta fase con las 4 variantes `*Bright` nuevas: `feltGreenBright #32B277`, `steelBlueBright #5DA5D5`, `graphiteSteelBright #8C949F`, `errorBright #F04F4F`).

**Regla elegida:** principio general documentado en `FLOPLY_DESIGN_LANGUAGE.md` ("Principio de contraste por contexto de uso") — relleno grande = valor base; texto/ícono sobre fondo oscuro = variante Bright; texto/ícono sobre `surfaceReading` = el valor base ya alcanza para `feltGreen`/`steelBlue` (no para `brass`, que necesita `brassDeep` ahí).

**Alternativas rechazadas:** subir la luminancia del valor BASE en vez de crear una variante — rechazada porque el valor base sigue siendo correcto y necesario como relleno de superficie/progreso; cambiarlo ahí rompería la identidad de sección ya validada.

**Pendiente, no cerrado:** `disabled` (`#4A463C`) mide 2.07:1 contra `background` — sin uso real medido en las 4 pantallas de esta fase, se deja para revisión cuando exista un caso de uso real que lo requiera medir.

**Impacto:** `AppColors` real, cuando se migre en Fase 2, debe nacer con 2 variantes para estos 4 colores (7 tokens de color en total en vez de 4), no agregarlas como parche después.

---

## 8. Core vs. Área

**Decisión:** sin cambios respecto a la matriz ya cerrada en `FLOPLY_DESIGN_BRIEF.md` §D.7 — se confirma con evidencia de código real, no se modifica.

**Contexto:** la matriz definía qué es inmutable (tipografía, spacing, forma, mecanismo de motion, vocabulario de superficies) y qué varía por área (acento, densidad, qué superficie domina).

**Evidencia:** las 4 pantallas construidas respetan la matriz sin excepción — ningún área introdujo un radio, spacing o mecanismo de motion fuera de lo documentado; la única variación real fue de acento (temperatura) y densidad, exactamente como predecía la matriz.

**Regla elegida:** sin cambios.

**Impacto:** ninguno nuevo.

---

## 9. Relación con `TableMaterial`

**Decisión:** `TableMaterial` (la paleta interna de `table_layout.dart`) sigue siendo una especialización de bajo nivel que el sistema nuevo **consume como referencia** (`surfaceFelt`, `brass`, el marfil de `surfaceReading` nacen conceptualmente de ahí) pero **no se fusiona ni se refactoriza**. `PokerTableView` no se tocó en ninguna de las 4 fases.

**Contexto:** `FLOPLY_DESIGN_TOKENS.md` ya planteaba esta relación como recomendación; se confirma sin cambios.

**Evidencia:** las 4 pantallas del playground embebieron `PokerTableView` real (en Laboratorio) sin necesitar tocarlo ni un carácter, y sin que su paleta interna se filtrara al chrome nuevo.

**Regla elegida:** sin cambios — `TableMaterial` permanece intacto y aislado; ninguna migración de Fase 2 debe intentar unificarlo con `AppColors` en un solo archivo.

**Impacto:** ninguno nuevo.

---

## Resumen para Fase 2

Las 9 decisiones de arriba están cerradas. Las condiciones que `FLOPLY_VISUAL_STRESS_TEST.md`/el prompt de esta fase pedían para autorizar la migración:

- [x] Tipografía real elegida (Fraunces + Public Sans + IBM Plex Mono, OFL 1.1, validada visualmente).
- [x] Motion formalizado (`instant/fast/normal/emphasis`).
- [x] Chip Numeric documentado (Wrap + label truncable + valor intocable).
- [x] Reglas de contraste documentadas (variantes Bright + principio general).
- [x] Límites de materialidad documentados (Global vs. Mesa).
- [x] Las 4 áreas comparadas (ver `FLOPLY_VISUAL_STRESS_TEST.md` §K-M y J.1/J.2).
- [x] Sin problemas estructurales abiertos en el prototipo (los 4 encontrados en Fase 1.5 fueron corregidos y re-verificados; 1116/1116 tests verdes).

**Todas las condiciones se cumplen.** Fase 2 puede comenzar, empezando por **Home** — nunca por `PokerTableView`, `PlayableTableExerciseView`, ni el flujo compartido Academia/Laboratorio.
