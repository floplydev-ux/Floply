# FLOPly — Auditoría contra el checklist maestro
**Fecha:** 2026-09-18 (última actualización de este documento: misma sesión extendida — ver nota al final)
**Método:** lectura directa del código (`lib/`, `test/`, `assets/curriculum/curriculum_spec.json`, configs de build/Firebase), sin modificar nada. `flutter analyze` corrido en vivo; `flutter test` corrido en vivo (resultado al final del documento). No se ejecutaron builds Android/Web en esta sesión — se marcan 🔵 donde corresponde re-verificar.

**Nota:** las secciones §1 y §9 (Home/Estadísticas) se actualizaron después de la auditoría original del 2026-09-18: se implementó una pantalla real de Estadísticas (ver el bloque de cambios al final del documento). El resto del documento describe el estado tal como se auditó originalmente y sigue vigente salvo donde se indica lo contrario.

Leyenda: ✅ implementado · 🟡 parcial/en progreso · 🔴 faltante · 🔵 implementado pero requiere auditoría · ⚪ no prioritario/futuro

---

## 1. 🏠 INICIO / HOME

### Navegación
- [✅] Home principal — pantalla real y poblada (`home_screen.dart`)
- [✅] Academia — tab real (`AcademyScreen`)
- [✅] Laboratorio — tab real (`LaboratoryScreen`)
- [🔴] Herramientas — no es tab de navegación inferior; solo una tarjeta en Home que abre `ComingSoonScreen`
- [✅] Estadísticas — tab real (`StatsScreen`) desde esta sesión — ver §9 actualizado
- [✅] Perfil — tab real (`AccountScreen`, con login/logout/cuenta)
- [✅] Navegación responsive — `AppBottomNavigation`; suite de tests cubre 320/360/390/412/430dp

### Home
- [✅] Estado/progreso del alumno — `AcademyProgressCard`
- [✅] Acceso rápido a Academia — `onGoToAcademy`
- [✅] Acceso rápido a Laboratorio — `PracticeRoomCard` + `ContinueLearningCard`
- [🟡] Acceso rápido a Tools — tarjeta existe (`HomeLinkCard` → `kToolsDestination`) pero destino es `ComingSoonScreen`
- [✅] Bankroll — tarjeta real → `BankrollScreen` con contenido propio (fichas de bankroll management)
- [🔴] Fichas / FlopCoins — no existe ningún sistema de moneda/currency en el código (verificado por grep, sin falsos positivos relevantes)
- [✅] Continuar aprendizaje — `ContinueLearningCard`, abre la lección real vía `AcademyController` compartido
- [✅] Continuar entrenamiento — mismo patrón hacia Laboratorio
- [⚪] Accesos rápidos configurables — orden fijo, sin personalización; el propio checklist lo marca como "si corresponde" (no crítico hoy)

---

## 2. 🎓 ACADEMIA

### Currículo
- [✅] Currículo completo — fuente única `assets/curriculum/curriculum_spec.json`
- [✅] 13 niveles — confirmado en `meta.niveles`
- [✅] Subniveles — 64, confirmado
- [✅] 326 teorías — confirmado (`meta.total_teorias`, conteo real del array `teorias`)
- [✅] IDs estables — 0 IDs duplicados, 0 referencias rotas (verificado también en auditoría previa 2026-09-12)
- [✅] Prerrequisitos — 325/326 teorías tienen `prerrequisitos` poblado (cadena lineal T002→T001, etc.); `unlock_modes_soportados` incluye `linear` y `prerequisites`
- [✅] Desbloqueos — `unlock_mode: linear` activo; `LessonState.locked/available/completed` implementado
- [✅] Progreso — `AcademyProgress`/`LessonProgress` (completed, attempts, bestScore, lastScore, passed)
- [✅] Persistencia — local (`FileAcademyStore`) + remota (`FirestoreAcademyStore`) vía `SyncingAcademyStore`

### Contenido
- [✅] Teoría presentada como mentor/profesor — `academy_mentor_lessons.dart`, guiones `mentor_lessons_n1..n13`
- [🔵] Explicaciones claras — 326/326 en `estado_redaccion: 'listo'`; auditoría de contenido previa fue por muestra dirigida (14 de 326), no línea por línea completa
- [✅] Ejemplos — campo `ejemplo` presente en el JSON de teorías
- [✅] Conceptos relacionados — `teorias_relacionadas` + `ConceptRegistry`
- [🔵] Consolidación — existen sublevels de tipo `challenge`/`assessment`; no se verificó a fondo la calidad pedagógica de la consolidación
- [🔵] Sin introducir conceptos antes de tiempo — la regla está forzada a nivel de motor (`UserKnowledge.isTaught`, "regla fundamental"), pero la verificación de contenido en sí fue muestral, no exhaustiva
- [🔵] Sin duplicaciones conceptuales innecesarias — memoria de sesiones previas indica hallazgos ya corregidos (`academia-auditoria-pedagogica`), pero no hay una pasada de verificación 100% reciente

### Ejercicios
- [✅] Ejercicios interactivos — motor extenso en `lib/engine/exercises/` + `lib/engine/pedagogy/scripts/`
- [✅] Situaciones de mesa — `TableExercise`, `PlayableTableExerciseView`
- [✅] Feedback — `FeedbackEngine`, `feedback_view.dart`
- [🟡] Best / Acceptable / Poor / Dependent — el motor usa `StrategicRating` de **5** niveles (Óptima/Muy buena/Viable/Dudosa/Mala), conceptualmente equivalente pero no la nomenclatura exacta de 4 categorías pedida
- [✅] Aleatorización — `exercise_generator.dart`, `hand_picker.dart`
- [🔵] Repetición — `UserKnowledge.weakConcepts()` existe como primitiva de "conceptos débiles", pero no se confirmó un flujo activo de repetición espaciada que lo consuma
- [✅] Evaluación basada únicamente en conceptos enseñados — regla forzada en `UserKnowledge.isTaught`/`recordAttempt`

### Mesa educativa
- [✅] PokerTableView
- [✅] Hero
- [✅] Villains — `academy_players.dart`
- [✅] Cartas — `playing_card.dart`
- [✅] Board — `community_cards.dart`
- [✅] Pot — `pot_and_bets.dart`
- [✅] Fichas — `poker_chip.dart`
- [✅] Paneles — `player_seat.dart`
- [✅] Acciones
- [✅] Feedback — `table_bubble.dart`, `visual_theory_stage.dart`
- [✅] Responsive vertical — extensamente testeado (`table_geometry_test.dart`, `academy_level*_test.dart` a múltiples dp)

### Calidad
- [🔵] Auditoría de las 326 teorías — 100% estructural, muestra manual de 14/326 (ver auditoría previa)
- [🔵] Auditoría de todos los ejercicios — parcial (memoria: `academia-ejercicios-n5-n13`, errores reales ya corregidos, pero no hay confirmación de cobertura 100%)
- [🔵] Verificación teoría ↔ ejercicio — no se encontró una pasada exhaustiva y documentada
- [✅] Verificación de conceptos — `concept_graph_test.dart`
- [✅] Tests — suite extensa (ver §16)
- [✅] Flutter analyze — **0 issues**, corrido en esta sesión
- [🔵] Android build — no corrido en esta sesión (hay cambios sin commitear en `android/`, incluyendo rename de package a `com.floply.app`); re-verificar
- [🔵] Web build — no corrido en esta sesión; re-verificar

---

## 3. 🧪 LABORATORIO

### Motor
- [✅] Poker Engine reutilizable — `lib/engine/poker/**`, compartido con Academia (no hay `AcademyEngine`/`LaboratoryEngine` separados)
- [✅] Generación de situaciones — `poker_situation.dart`, `scenario_builder.dart`
- [✅] Generación de manos — `deck.dart`, `hand_picker.dart`
- [✅] Generación de boards — `board_generator.dart`
- [✅] Posiciones — `position.dart`
- [✅] Stacks — en `player_state.dart`/`game_state.dart`
- [✅] Acciones — `poker_action.dart`, `action_resolver.dart`
- [✅] Pot — `pot_manager.dart`
- [✅] Ranges — `hand_range.dart`, `opening_ranges.dart`, y ahora `preflop_range_book.dart` (call/3-bet valor/3-bet farol/4-bet valor/empuje-o-fold, con anclas reales para BB-vs-CO, BTN-vs-UTG, BTN-vs-CO, CO-encarando-3-bet-de-BTN y BB-vs-CO a stack corto — ver "Best/Acceptable/Poor/Dependent" abajo)
- [✅] Evaluación — `hand_strength.dart`, `hand_category.dart`

### Entrenamiento
- [✅] Sesiones — `lab_session_controller.dart`
- [✅] Ejercicios
- [✅] Aleatorización
- [✅] Dificultad — `difficulty_level.dart`
- [✅] Feedback — `feedback_panel.dart`
- [✅] Scoring — `preflop_session_summary.dart`
- [✅] Resumen de sesión — `session_summary.dart` / `preflop_session_summary_view.dart`
- [✅] Calidad de decisión — `decisionScore` en `EvaluationResult`
- [✅] Best / Acceptable / Poor / Dependent — mismo motor de 5 niveles que Academia (ver arriba). **Fase 1 del rediseño preflop completa** (memoria del proyecto `laboratorio-motor-preflop`, los 8 pasos del plan): la vieja `PreflopStrategy._facingRaiseStrategy` (un único percentil de Chen para toda decisión de "encarar una subida", ignorando posición/rango real del rival/sizing) queda reemplazada por 3 clases reales sobre `PreflopRangeBook` — `DefenseVsOpenStrategy` (BB vs CO, BTN vs UTG), `FacingThreeBetStrategy` (CO encarando un 3-bet real de BTN, ya no un rango fijo `{AA,KK,AKs}`) y `ShortStackStrategy` (empuje-o-fold a ~8bb, BB vs CO). `OpponentPolicy` también consulta el mismo libro de rangos para el perfil `balanced`, para que el rival simulado nunca diverja del criterio que evalúa al alumno. Un banco de texto real (`PreflopRationaleBank`) cubre las 24 claves nuevas; las claves viejas (`facing_raise.*`, `open_over_limpers.*`) siguen con el texto genérico por veredicto — deuda reconocida, no silenciada. Cualquier situación sin ancla real sigue cayendo al fallback de percentil de siempre, nunca inventa un rango sin fuente

### Integración
- [✅] UserKnowledge — compartido con Academia
- [✅] ConceptRegistry — compartido
- [🔵] Conceptos débiles — `weakConcepts()` existe; no se confirmó que el Laboratorio lo use activamente para armar sesiones
- [🔴] Repetición adaptativa — no hay scheduler/algoritmo de repaso espaciado más allá de la primitiva de arriba
- [🔵] Relación Academia → Laboratorio — comparten motor y conceptos, pero no se confirmó un flujo explícito "practicar mis conceptos débiles desde Laboratorio"
- [🔴] Laboratorio → Estadísticas — no aplica: no existe pantalla de Estadísticas
- [⚪] Futuro → Coach — explícitamente etapa futura (§10)

### Mesa
- [✅] Mesa vertical — `laboratory_screen.dart` + `poker_bits.dart`
- [✅] Paneles / Cartas / Board / Pot / Fichas
- [🟡] Botones Check / Call / Raise / Fold — **actualizado**: el Laboratorio ya tiene una primera familia postflop real (`PreflopScenarioKind.cbetDecision`, ver `LABORATORIO_POSTFLOP_AUDITORIA_DISENO.md`, alcance "Modelo A" aprobado por el usuario 2026-09-19) — el héroe decide check/bet en el flop tras haber sido el agresor preflop, en un board que favorece a su rango. Sigue sin cubrir call/raise postflop, turn/river, ni ninguna otra situación — una única familia, deliberadamente acotada
- [🟡] Tamaños de apuesta — `open_sizing_template.dart` cubre sizing de apertura preflop; `cbetDecision` ofrece 2 tamaños de c-bet (mínimo legal y medio bote, ver `ExerciseScenarioAdapter._recommendedSizes`) pero sigue sin un selector genérico de bet-sizing postflop
- [✅] Feedback post-decisión
- [🔵] Sensación de mesa online real — criterio subjetivo/visual, requiere revisión manual en dispositivo

### Calidad
- [✅] Tests — suite extensa en `test/ui/laboratory_*`, `test/engine/*`
- [✅] Analyze — 0 issues
- [🔵] Android build — re-verificar
- [🔵] Web build — re-verificar
- [🔵] Auditoría de ejercicios — no hay pasada dedicada documentada
- [🔵] Auditoría de scoring — no hay pasada dedicada documentada

---

## 4. 🧰 TOOLS — V1

**Superado por §5/§6** — `ToolsScreen` (`lib/screens/tools/`) reemplaza el `ComingSoonScreen` de la tarjeta de Home. El motor completo existe (`HandEvaluator`, `ComboEngine`, `EquityEngine`, `PotOddsEngine`, `EVEngine`, `BetSizingEngine` — ver `FASE0_AUDITORIA_ENGINE.md`) y las 6 herramientas que lo consumen ya están construidas — ver el detalle completo en §5 y §6, esta sección queda solo como referencia histórica del punto de partida.

- [✅] Range Explorer — `lib/screens/tools/range_explorer_screen.dart` (ver §5)
- [🔴] Preflop Charts como documento/vista separada de solo lectura — no existe aparte de Range Explorer; se consideró la misma herramienta (una grilla 13x13 por posición ya es, en sustancia, un preflop chart interactivo) en vez de duplicarla

---

## 5. 🧮 TOOLS — CALCULADORAS

**Actualizado** — el motor completo existe (ver §4). Tools V1 completo: las 5 calculadoras planeadas tienen UI real.

- [✅] Equity Calculator — `lib/screens/tools/equity_calculator_screen.dart`, sobre `EquityEngine`. Selector de 3 modos (mano vs mano, mano vs rango, rango vs rango) con notación de texto (`AhKd`, rangos `77+,ATs+,AKo`), win/tie/lose %, equity, explicación. Mano vs mano recalcula en vivo (barato); mano vs rango y rango vs rango calculan solo al tocar "Calcular equity" y corren en un isolate aparte vía `compute()` (nunca en el hilo de UI — ver el doc-comment de `EquityCalculatorScreen` y de `EquityEngine.rangeVsRange`, que advierte que es el caso más pesado del motor)
- [✅] Pot Odds Calculator — `lib/screens/tools/pot_odds_calculator_screen.dart`, sobre `PotOddsEngine`. Pot/call, equity necesaria, pot odds (X:1), explicación educativa, recalcula en vivo
- [✅] EV Calculator — `lib/screens/tools/ev_calculator_screen.dart`, sobre `EVEngine`. Selector de 2 modos: "Pagar un call" (`EVEngine.calculateCall` + `PotOddsEngine`, reutiliza el bote final, no lo recalcula dos veces) y "Apostar / subir" (`EVEngine.calculateBet`, EV Avanzado — ver §6). Ambos: pot/call(o apuesta)/equity → EV en BB, estado +EV/break-even/-EV con color, explicación
- [✅] Combo Calculator — `lib/screens/tools/combo_calculator_screen.dart`, sobre `ComboEngine.combosForHandClass`. Clase de mano (`AKs`, `77`, `AKo`) + cartas muertas opcionales, combos totales/disponibles/bloqueados, lista de combinaciones físicas concretas
- [✅] Range Explorer — `lib/screens/tools/range_explorer_screen.dart`, sobre `OpeningRanges`/`HandRange`. Selector de posición (UTG/HJ/CO/BTN/SB/BB) + grilla 13x13 clásica (pares en la diagonal, suited arriba, offsuit abajo) coloreada por frecuencia, detalle de mano al tocar una celda (frecuencia + combos), aviso explicativo para BB (no abre)
- [✅] Blocker Explorer — `lib/screens/tools/blocker_explorer_screen.dart`, sobre `ComboEngine.combosForRange`/`.comboCount` (mismo motor que Combo Calculator, corrido dos veces con distinto `deadCards`: solo board vs. board + tu mano). Tu mano + rango rival + board opcional (0/3/4/5 cartas) → combos totales/disponibles/bloqueados del rango, desglose por clase con chips coloreados (bloqueada del todo / parcial / sin afectar). Recalcula en vivo — es pura combinatoria, no enumera runouts

Widgets compartidos entre calculadoras extraídos a `lib/screens/tools/widgets/tool_widgets.dart` (`ToolHeader`, `ToolCard`, `ToolNumberField`, `ToolTextField`, `ToolErrorCard`, `ToolResultStat`) — cada calculadora nueva los reutiliza en vez de duplicar la pantalla.

---

## 6. 🧠 TOOLS — V2
- [✅] Hand vs Range / Range vs Range — integrado como 2 modos más del Equity Calculator (ver §5) en vez de pantallas nuevas, sobre `EquityEngine.handVsRange`/`.rangeVsRange` (ya existían del motor)
- [✅] Blocker Explorer — `lib/screens/tools/blocker_explorer_screen.dart` (ver §5)
- [✅] EV avanzado — **alcance "Modelo A" únicamente** (ver `EV_AVANZADO_AUDITORIA_DISENO.md`, auditoría+diseño completos, aprobado por el usuario 2026-09-19): EV de apostar/subir con fold equity, integrado como 2do modo del EV Calculator (ver §5), sobre `EVEngine.calculateBet` (nuevo) + `EVBetResult` (nuevo, `lib/engine/poker/ev/ev_bet_result.dart`). Modela solo 2 ramas (fold del rival / call del rival) — la rama "el rival sube" queda deliberadamente fuera del cálculo y se le avisa al usuario cuando `foldProbability + callProbability < 1`, nunca se le inventa un valor. Preflop fuera de alcance (igual que el resto de Tools: solo board conocido). Modelo B (multi-calle) y Modelo C (árbol completo) quedan documentados en el informe pero sin implementar — B es el candidato natural si hace falta más adelante, C se superpone con el ítem ya pospuesto "GTO Decision / Postflop GTO" (P2)

---

## 7. 🎯 GTO TOOLS
- [🔴] GTO Preflop, GTO Decision, Postflop (flop/turn/river explorer) — nada implementado; correctamente, no se intentó ningún solver propio (cumple regla 11 del checklist por omisión, no por decisión activa registrada)

---

## 8. ⚡ TABLE MODE — AYUDA RÁPIDA
**Actualizado** — implementado como accesos directos, no como calculadoras nuevas (decisión del usuario, 2026-09-19): un FAB (`showTableModeSheet`, `lib/screens/tools/table_mode_sheet.dart`) visible en las 5 pestañas de `AppShell` abre un bottom sheet con las 6 herramientas de §5 como tiles compactos — cada uno empuja exactamente la misma pantalla que `ToolsScreen`, cero cálculo ni pantalla nueva.

- [✅] Quick Range, Quick Equity, Quick Pot Odds, Quick EV, Quick Combos, Quick Blockers — accesos directos desde cualquier pestaña, sin pasar por Home → Tools
- [🔴] Spot Analyzer — no implementado; era la interpretación "dashboard combinado" que el usuario explícitamente no eligió al definir el alcance (ver las opciones ofrecidas 2026-09-19). Sigue disponible como posible iteración futura si hace falta

---

## 9. 📊 ESTADÍSTICAS
**Actualizado — pantalla real implementada esta sesión** (`lib/screens/stats/stats_screen.dart`, cableada en `AppShell` reemplazando el `ComingSoonScreen` del tab). Puramente de lectura: no calcula nada que `AcademyController`/`AcademyEngine`/`masteryBuckets` no calcularan ya.

- [✅] Estadísticas de aprendizaje — nivel actual, % completado, lecciones hechas/total, y las 13 filas de nivel con su progreso individual (`AcademyController.snapshot`/`.levels`, mismos datos que ya usaban `AcademyProgressCard`/`LevelMap`)
- [✅] Conceptos dominados/débiles — dominio por concepto (`masteryBuckets`, el mismo helper que ya usaba el resumen de sesión del Laboratorio; extraído a un widget compartido `ConceptMasteryBar` para no duplicarlo)
- [🔴] Estadísticas de Laboratorio — **deliberadamente sin datos reales todavía**: `LabSessionController.results`/`newEngineResults` viven solo en memoria de la sesión en curso, no hay ningún store que persista sesiones de Laboratorio entre corridas de la app. La pantalla muestra un estado vacío honesto explicando esto, en vez de inventar números — implementar esto de verdad requiere agregar persistencia de historial de sesiones (fuera de alcance de este bloque, ver "próximo paso")
- [✅] Integración Academia → Estadísticas — completa, vía el mismo `AcademyController` que comparte `AppShell` con la pestaña Academia
- [🔴] Integración Laboratorio/Tools → Estadísticas — bloqueada por el punto anterior (no hay historial de Laboratorio que integrar) y por que Tools no existe

Tests: `test/ui/stats_screen_test.dart` (5 tests) — progreso real visible, estado vacío de dominio por concepto para un usuario nuevo, una barra real aparece tras enseñar+practicar un concepto, estado vacío honesto de Laboratorio, y responsive en 320/390/430dp.

---

## 10. 🧠 COACH
Marcado explícitamente como "Futuro / última etapa" en el propio checklist.
- [⚪] Todo el bloque — no implementado como feature de usuario, pero la base técnica (`UserKnowledge`, `ConceptRegistry`, `weakConcepts()`) ya existe y está compartida desde Academia, lo cual reduce el trabajo futuro

---

## 11. 👤 CUENTAS
- [✅] Google — `google_sign_in`, `AuthProviderType.google`
- [🔵] Apple — `sign_in_with_apple` integrado en código; AUTH_SETUP.md admite que el login real contra Apple nunca se probó en vivo (requiere credenciales del equipo)
- [✅] Email — `email_link_screen.dart` (passwordless, Email Link)
- [✅] Login — `auth_screen.dart`
- [✅] Logout — `AuthController.signOut()`
- [✅] Persistent session — estado persistido vía Firebase Auth + flag de "invitado" local
- [🔴] Password recovery — no aplica tal como está diseñado: el login es passwordless (Google/Apple/email-link), no hay contraseñas que recuperar. Si se espera este flujo igual, falta.
- [✅] Link accounts — `account_conflict_sheet.dart` + lógica de conflicto de cuentas
- [✅] Delete account — `AuthController.deleteAccount()`; AUTH_SETUP.md nota que falta decidir si también se borran datos remotos asociados
- [✅] Migración de progreso local → cuenta — documentada e implementada (`SyncingAcademyStore`, sección 7 de AUTH_SETUP.md)
- [✅] Sincronización cloud — `FirestoreAcademyStore` + `SyncingAcademyStore`
- [🔵] Manejo offline — Firestore trae caché offline de fábrica (razón de la elección de Firebase sobre Supabase), pero no se verificó con una prueba real sin conexión

---

## 12. 💰 MONETIZACIÓN
No se encontró ningún rastro de sistema de moneda, ads o suscripción en `pubspec.yaml` ni en el código (sin dependencias de ads/IAP).
- [🔴] Fichas / FlopCoins — sistema, consumo, recuperación, persistencia, visualización
- [🔴] Ads — rewarded ads, recuperación de intentos, sesiones adicionales
- [🔴] Premium — suscripción, herramientas/rangos/GTO premium

---

## 13. 🔐 LEGAL / CUENTA
- [🔴] Terms of Service — no se encontró texto ni pantalla
- [🔴] Privacy Policy — no se encontró texto ni pantalla
- [🔴] Consentimiento de registro / de datos — no se encontró
- [✅] Delete account — ver §11 (cubierto ahí, no duplicado como feature legal)
- [🔴] Gestión de datos (exportar, ver qué se guarda, etc.) — no encontrada

---

## 14. 🎨 UX / UI

### Sistema visual
- [✅] Identidad FLOPly — `app_colors.dart`, `app_theme.dart`, branding consistente ("Floply", `com.floply.app`)
- [🔵] Tipografía — no se confirmó una tipografía custom (parece usar la fuente por defecto de Material); revisar si es decisión deliberada
- [✅] Colores — sistema amplio en `AppColors`
- [✅] Componentes reutilizables — `glass_card.dart`, `pressable_scale.dart`, `home_link_card.dart`, `user_avatar.dart`
- [✅] Botones / Cards / Panels / Chips / Fichas / Cartas

### Responsive
- [✅] 320 / 360 / 390 / 430 dp — cubiertos explícitamente en múltiples suites de test
- [✅] Web — target soportado (`web/` presente, build validado en auditoría previa)
- [✅] Android — target primario

### Mesa
- [🔵] Consistencia Academia/Laboratorio — ambas pantallas tienen sus propios widgets de mesa (`screens/academy/widgets/table/*` vs `screens/laboratory/widgets/poker_bits.dart`); no se confirmó si comparten los mismos componentes de bajo nivel o son dos implementaciones paralelas — **vale la pena auditar contra la regla 15 (evitar duplicar motores/UI que resuelven lo mismo)**
- [✅] Cartas realistas / Paneles / Fichas / Board / Pot / Acciones

---

## 15. ⚙️ ARQUITECTURA TÉCNICA

### Poker Engine
- [✅] Cards — `card.dart`
- [✅] Deck — `deck.dart`
- [✅] Hands — `hole_cards.dart`
- [✅] Hand evaluator — `hand_category.dart`, `hand_strength.dart`
- [✅] Combos — `poker/combos/combo_engine.dart`, módulo dedicado (enumeración física + card removal), consumido por Combo/Blocker Explorer y por `EquityEngine`
- [✅] Ranges — `hand_range.dart`, `opening_ranges.dart`
- [✅] Equity — `poker/equity/equity_engine.dart`, enumeración exacta (mano-mano, mano-rango, rango-rango), no Monte Carlo. Preflop (board vacío) queda fuera de alcance a propósito, ver su doc-comment
- [✅] Board — `board_generator.dart`
- [✅] Positions — `position.dart`
- [✅] Pot — `pot_manager.dart`
- [✅] Pot odds — `poker/pot_odds/pot_odds_engine.dart`, módulo reutilizable
- [✅] EV — `poker/ev/ev_engine.dart`: `calculateCall` (EV de pagar) + `calculateBet` (EV de apostar/subir, con fold equity — ver §6). El "EV" pedagógico de Academia (scoring de decisión) sigue siendo un concepto aparte, sin confundirse con este
- [✅] Actions — `poker_action.dart`, `action_resolver.dart`
- [🟡] Bet sizing — `poker/sizing/bet_sizing_engine.dart` cubre conversión BB↔fracción de pot postflop; sizing de apertura preflop sigue en `opening_ranges.dart`/`open_sizing_template.dart` — dos piezas separadas a propósito, no una laguna

### Reutilización
- [✅] Un solo `lib/engine/poker/**` consumido tanto por Academia como por Laboratorio — no se detectaron motores duplicados tipo `AcademyEngine`/`LaboratoryEngine` (cumple la regla explícita del checklist)

---

## 16. 🧪 QA

### Tests automáticos
- [✅] Unit tests / Engine tests — extenso (`test/engine/*`, ~34 archivos)
- [✅] Range tests — `hand_range_test.dart`
- [✅] Equity tests — `test/engine/equity_engine_test.dart` + tests de UI de cada modo del Equity Calculator
- [✅] Pot odds tests — `test/engine/pot_odds_engine_test.dart` + tests de UI
- [✅] EV tests — `test/engine/ev_engine_test.dart` (calculateCall) + `test/engine/ev_bet_engine_test.dart` (calculateBet) + tests de UI de ambos modos
- [✅] Curriculum tests — `curriculum_spec_test.dart`, `theory_content_test.dart`, `academy_content_test.dart`
- [✅] Exercise tests — `exercise_generator_test.dart`, `exercise_scenario_*_test.dart`
- [🔵] Navigation tests — cobertura parcial (`home_screen_test.dart`, `academy_screen_test.dart`), no exhaustiva de todos los flujos de navegación
- [✅] Persistence tests — `academy_store_test.dart`, `syncing_academy_store_test.dart`, `table_persistence_test.dart`

### Validación
- [✅] `flutter analyze` — **0 issues**, corrido en esta sesión
- [✅] `flutter test` — **601/601**, corrido en esta sesión (ver resultado al pie)
- [🔵] `flutter build web` — no corrido en esta sesión (última confirmación: 2026-09-12, con cambios de código desde entonces)
- [🔵] Android build — no corrido en esta sesión
- [✅] Responsive testing — extenso, ver §14

### QA visual
- [🔵] Home / Academia / Laboratorio / Perfil — con cobertura de test automatizado, no hay evidencia de una pasada visual manual reciente en dispositivo real
- [🔵] Tools / Estadísticas — cobertura de test automatizado extensa (ver §5/§6/§9); sin pasada visual manual en dispositivo real todavía, mismo criterio que el resto de esta fila

---

## 17. 🤖 AUTOMATIZACIÓN QA — FUTURO
- [⚪] Todo el bloque — explícitamente etapa futura ("después de estabilizar"), no iniciado. Correcto según la prioridad P2 del propio documento.

---

## 18. 🚀 RELEASE

### Android
- [✅] Application ID definitivo — `com.floply.app` (namespace y applicationId), aunque **sin commitear** (cambio en curso, ver `git status`)
- [🔵] Firebase producción — `firebase.json`/`firebase_options.dart` apuntan a un proyecto real (`floply-e5b45`, con IDs de Android/iOS/Web); **contradice** `AUTH_SETUP.md`, que dice que esto sigue en placeholder — la documentación quedó desactualizada respecto al código. Requiere confirmar en la consola de Firebase que el proyecto está realmente activo y con los proveedores habilitados.
- [🔵] Google login — código integrado; sin prueba en vivo confirmada (admitido en `AUTH_SETUP.md`)
- [🔵] Apple login — mismo estado que Google
- [🔴] Play Console — sin evidencia de configuración
- [🔴] Signing — `build.gradle.kts` firma el build de release con las claves de **debug** (`TODO: Add your own signing config`) — bloqueante real para publicar
- [🔴] Privacy / Terms — no existen (ver §13)
- [🔴] Store listing / Screenshots — sin evidencia
- [🔴] Internal / Closed testing / Production — no iniciado

### Web
- [🔵] Build — no corrido en esta sesión
- [✅] Responsive — cubierto
- [🔵] Firebase — mismo estado que Android (proyecto real configurado, sin confirmación de proveedores activos)
- [🔵] Authentication — el botón nativo de Google en Web está pendiente (`AUTH_SETUP.md` §13: "falta agregar el botón nativo de Google")
- [🔴] Deploy — no hay configuración de Firebase Hosting ni evidencia de deploy

### Calidad final
- [✅] 0 analyzer issues — confirmado en esta sesión
- [✅] Tests pasando — 601/601 (ver resultado al pie)
- [🔵] Android build OK — re-verificar (no corrido en esta sesión)
- [🔵] Web build OK — re-verificar (no corrido en esta sesión)
- [✅] No regresiones — analyze + 601/601 tests en verde sobre el estado actual del código (incluye cambios sin commitear)
- [⚪] Performance aceptable — no medido en esta sesión
- [🔵] Offline behavior definido — depende de Firestore cache, no probado explícitamente

---

## Resumen por prioridad (según la sección "PRIORIDAD GLOBAL" del checklist original)

| Prioridad | Ítem | Estado real |
|---|---|---|
| P0 | Academia | ✅ mayormente completa, con 🔵 en auditoría de contenido/ejercicios al 100% |
| P0 | Laboratorio | 🟡 motor y sesión sólidos; postflop arrancó (1 familia real, `cbetDecision`, ver §3) — falta ampliar más allá de esa única situación |
| P0 | Poker Engine compartido | ✅ sin duplicación, bien reutilizado |
| P0 | Accounts | ✅ sólido, con 🔵 en pruebas de login real y offline |
| P0 | Tools V1 | ✅ completo — 5 calculadoras reales (Pot Odds, EV, Equity, Combos, Rangos) |
| P0 | Estadísticas básicas | ✅ completa — `StatsScreen` (Academia + mastery de conceptos) |
| P0 | Home | ✅ completa para lo que hoy existe |
| P0 | Android release | 🔴 bloqueado por signing real + Play Console + legal |
| P1 | Tools V2 / Table Mode / GTO Preflop / Monetización / Estadísticas avanzadas / UX final | 🟡 Tools V2 completo en su alcance aprobado (ver §6) y Table Mode ✅ (accesos directos, ver §8) — GTO Preflop, Monetización y Estadísticas avanzadas siguen sin empezar |
| P2 | GTO Decision / Postflop GTO / Coach / Adaptativo / QA automático | ⚪ correctamente pospuesto |

**Conclusión corta:** el producto tiene un núcleo pedagógico (Academia + Laboratorio + motor de poker + cuentas) sólido y bien probado, y ahora también **Tools V1 completo** (6 calculadoras, incluyendo Blockers), **Tools V2 en su alcance aprobado** (Hand vs Range / Range vs Range, EV Avanzado Modelo A) y **Table Mode** (accesos directos desde cualquier pestaña). Lo que sigue en 🔴 sin empezar es GTO, y todo lo comercial/legal (Fichas, Ads, Premium, Terms, Privacy, signing real, Play Console). Antes de un release real de Android falta como mínimo: signing de producción, confirmar Firebase en vivo, y Terms/Privacy.

---

## Resultado de `flutter test` (esta sesión)
**601/601 — All tests passed!** (`flutter test --concurrency=1`, corrido en vivo en esta sesión). Junto con los 0 issues de `flutter analyze`, esto sube "Tests pasando" y "No regresiones" de §16/§18 de 🔵 a ✅ para lo que hoy tiene cobertura. Lo que sigue en 🔵 es exclusivamente lo que no se corrió esta sesión: `flutter build web` y el build Android.
