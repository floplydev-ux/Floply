# FLOPly — Fase 1 / Bloque 1: Home + Navegación Global — AUDIT

**Fecha:** 2026-09-19. **Método:** lectura completa del código real (no solo grep) de `home_screen.dart` y sus 4 widgets hijos, `app_shell.dart`, `bottom_navigation.dart`, `table_mode_sheet.dart`, `home_header.dart`, `home_link_card.dart`, `glass_card.dart`, `pressable_scale.dart`, `app_colors.dart`/`app_theme.dart`, `app_strings.dart` (las cadenas reales, no solo sus nombres), y los tests existentes (`home_screen_test.dart`, `app_shell_test.dart`). **No se ejecutó la app en un dispositivo/browser real** para este primer corte — todo lo de abajo es verificable en código y en los 965 tests que ya protegen esta superficie; donde el juicio depende de "cómo se siente" en una pantalla real, lo marco explícitamente como pendiente de verificación visual, no como hallazgo cerrado.

**No se modificó ningún archivo de código en este paso.**

---

## 1. Estado actual

Home es un **compositor puro** (su propio doc-comment lo dice y el código lo cumple): no calcula progreso ni decide desbloqueos, solo arma el orden de 7 secciones verticales y cablea sus CTAs a la navegación real de `AppShell`. Es la pantalla de aterrizaje de las 5 tabs (`kTabHome = 0`), con `IndexedStack` manteniendo su estado al cambiar de tab.

Funciona bien en lo básico: los 3 estados reales de la Academia (usuario nuevo / con progreso / completada) están cubiertos con datos reales del `AcademyController`, sin números inventados (el propio código lo señala explícitamente para `PracticeRoomCard`: "no hay ninguna sesión persistida todavía, así que no se inventa un número"). La navegación a Bankroll/Tools/Coach funciona y está probada. El sweep responsive de 320–430dp pasa sin overflow.

## 2. Arquitectura relevante

```
AuthGate
  └─ AppShell (IndexedStack, 5 tabs + FAB global)
       ├─ tab 0: HomeScreen ← este bloque
       │     ├─ HomeHeader (avatar + saludo + botón settings)
       │     ├─ ContinueLearningCard (hero, 4 estados: loading/nuevo/progreso/completa)
       │     ├─ AcademyProgressCard (resumen de progreso, GlassCard)
       │     ├─ PracticeRoomCard (acceso a Laboratorio)
       │     ├─ HomeLinkCard × 3 (Bankroll, Tools, Coach→ComingSoonScreen)
       ├─ tab 1: AcademyScreen / tab 2: LaboratoryScreen / tab 3: StatsScreen / tab 4: AccountScreen
       └─ FAB (bolt) → showTableModeSheet → bottom sheet con las 6 calculadoras de Tools
```

Navegación: **imperativa** (`Navigator.push` con `MaterialPageRoute`), sin `GoRouter`. Bankroll y Tools se alcanzan solo desde tarjetas de Home (no son tabs) — decisión de diseño ya validada en Fase 0, no se cuestiona acá.

## 3. Componentes utilizados

| Componente | De dónde | Reusado fuera de Home |
|---|---|---|
| `GlassCard` | `lib/widgets/` | Sí, pero solo en `AcademyProgressCard` — el resto de las cards de Home NO lo usan |
| `PressableScale` | `lib/widgets/` | Sí, ampliamente (20+ usos en toda la app) |
| `HomeLinkCard` | `lib/widgets/` | Sí, también en `ToolsScreen` |
| `AppBottomNavigation` | `lib/widgets/` | Solo en `AppShell` |
| `_HeroShell`, `_CtaButton` (en `continue_learning_card.dart`) | Privados de ese archivo | No — un `Container`+`BoxDecoration` a mano |
| El `Container`+`BoxDecoration` de `PracticeRoomCard` | Privado de ese archivo | No — otra receta de card a mano, distinta de `GlassCard` y de `_HeroShell` |

**Dato concreto:** dentro de esta única pantalla conviven **4 recetas visuales distintas para "card"** (`GlassCard`, `_HeroShell`, el `Container` de `PracticeRoomCard`, y el `Container` interno de `HomeLinkCard`) — mismo patrón de duplicación que ya señaló el baseline de Fase 0 (§7 de `FASE0_QA_UX_BASELINE_2026-09-19.md`), ahora con evidencia local y específica de este bloque.

## 4. Design tokens utilizados

- **Colores:** 100% desde `AppColors` — cero hex sueltos en los 4 archivos leídos. Punto fuerte confirmado también acá.
- **Radios:** 14 (`_CtaButton`), 16 (`_QuickTile`), 20 (`PracticeRoomCard`, `HomeLinkCard`), 22 (default de `GlassCard`), 26 (`_HeroShell`) — 5 valores distintos para el mismo concepto ("card redondeada"), sin escala.
- **Tamaños de ícono contenedor:** 38×38 (settings de `HomeHeader` — el hallazgo de accesibilidad), 40×40 (avatar en `HomeHeader`... en realidad 46, ver abajo), 44×44 (`PracticeRoomCard`, `_CompletedBody`) — otra vez sin escala clara.
- **Tipografía:** `fontSize` ad-hoc en cada widget (11, 12, 12.5, 13, 13.5, 14, 14.5, 17, 18, 20, 21) — ninguno lee `Theme.of(context).textTheme`, igual que reportó el baseline de Fase 0.
- **Breakpoint propio:** `home_screen.dart:127` define `constraints.maxWidth >= 480 ? 24.0 : 18.0` — un breakpoint que **nunca se activa** en el sweep de anchos que la propia suite usa (320–430dp, todos <480) ni en ningún teléfono real. No es un bug, pero es código que hoy no hace nada en el target real de la app (mobile).

## 5. Problemas UX

**[P1] Redundancia de progreso de Academia.** `ContinueLearningCard` (hero) y `AcademyProgressCard`, apiladas una debajo de la otra, muestran la MISMA información dos veces: ambas tienen una barra de progreso, ambas muestran el % de la Academia, ambas llevan a Academia al tocarlas. La primera además muestra la lección actual con su propio CTA. Para un usuario nuevo esto son dos bloques consecutivos compitiendo por la misma acción — carga cognitiva innecesaria justo en la sección que más peso tiene en la pantalla.

**[P1] Demasiadas decisiones antes del scroll.** Contando desde arriba: header (con una acción propia, settings) → hero con 1 CTA → card de progreso (tappable) → practice room (tappable) → 3 link cards (tappable) = **6 elementos tocables independientes** en una sola pantalla de aterrizaje, antes de llegar a la bottom nav. Ninguno está mal por sí solo, pero juntos diluyen cuál es LA acción principal — el propio doc-comment de `HomeScreen` dice que la Academia "es el corazón del producto", pero la jerarquía visual no lo refuerza tanto como podría (ver §7 UI).

**[P2] Doble camino a Laboratorio en el estado "Academia completa".** Cuando la Academia está 100% hecha, `ContinueLearningCard` ofrece "practicar ahora" Y `PracticeRoomCard` sigue debajo ofreciendo lo mismo. Caso de borde (terminar las 326 teorías), no urgente.

**[P2] Bankroll solo se alcanza desde Home.** Si el usuario está en la tab de Academia/Laboratorio/Estadísticas/Perfil y quiere ir a Bankroll, tiene que volver primero a la tab Home — no hay atajo (el FAB solo lleva a las calculadoras de Tools, no a Bankroll). No es un bloqueo, es una vuelta extra.

## 6. Problemas UI

**[P1] 4 recetas de "card" distintas en una sola pantalla** — ver §3/§4. Es el hallazgo más concreto y accionable de este bloque.

**[P2] Jerarquía tipográfica de "título de card" inconsistente.** `BANKROLL`/`PRACTICE ROOM`/`TOOLS`/`COACH` (en `HomeLinkCard`) se renderizan en mayúsculas fijas (son literales `'BANKROLL'`, etc. en `app_strings.dart`, no `.toUpperCase()` en runtime) a 14.5sp/w800. El título equivalente de `AcademyProgressCard` (`'Tu camino en la Academia'`) es sentence-case a 13.5sp/w800. Mismo rol semántico (título de una card de Home), dos tratamientos tipográficos distintos.

**[P2] Mezcla de idioma en títulos de card.** La app entera (currículo, feedback, toda la navegación de tabs: "Inicio"/"Academia"/"Laboratorio"/"Estadísticas"/"Perfil") está en español cuidado. "PRACTICE ROOM" y "COACH" son inglés sin traducir en medio de esa consistencia (a diferencia de "BANKROLL"/"EQUITY"/"EV", que son jerga de póker ya naturalizada en español). Puede ser una decisión de branding deliberada — lo marco como pregunta a validar, no como error asumido.

**[Nota positiva]** La animación de entrada (`_reveal`, fade+slide escalonado, 700ms totales, un solo momento de carga) es exactamente el tipo de motion "un momento orquestado, no efectos dispersos" — no es sobre-diseño, es un buen ejemplo a conservar tal cual (§18 de tu prompt).

## 7. Problemas accessibility

**[P1, ya documentado en Fase 0 — reingresa acá por instrucción explícita]** El botón de settings de `HomeHeader` (`lib/screens/home/widgets/home_header.dart:53-67`) mide 38×38dp, por debajo del mínimo de 48×48 (Android)/44×44 (iOS). Test de regresión ya existe (`test/accessibility/core_screens_accessibility_test.dart`), hoy en rojo a propósito. Entra al ciclo de este bloque para decidir si se corrige acá.

**[P2, no verificado automáticamente todavía]** Los labels de la bottom nav se renderizan a 9.5sp (`bottom_navigation.dart:82`) — por debajo de los ~11-12sp que suele recomendarse como piso legible en móvil, y el color inactivo (`AppColors.textMuted = 0xFF6E7392`) sobre `backgroundSecondary` (0xFF0B0E1D) no está cubierto por el `textContrastGuideline` automatizado de hoy (ese test corre sobre `AppShell`/`ToolsScreen` en general, pero no aísla específicamente la bottom nav) — recomendable agregar una assertion específica.

**Fuera de lo automatizable esta fase (igual que en Fase 0):** si el orden de lectura de un screen reader al recorrer las 7 secciones de Home tiene sentido, y si "Ayuda rápida" como tooltip del FAB comunica bien su propósito a un lector de pantalla la primera vez.

## 8. Problemas responsive

Ninguno nuevo detectado — el sweep de 320/360/390/412/430dp ya está cubierto y en verde (`test/ui/home_screen_test.dart`, y confirmado de nuevo por los goldens de Fase 0 a 390dp). El único hallazgo es el breakpoint muerto de §4 (480px, código sin efecto práctico), que no es un bug de UX sino una limpieza posible.

## 9. Problemas de consistencia

Ya cubiertos en detalle arriba: 4 recetas de card (§6), tipografía de título de card (§6), radios sin escala (§4), tamaños de ícono-contenedor sin escala (§4). Todos apuntan a la misma causa raíz: no hay un token de "card"/"spacing"/"tipografía de card-title" — cada componente de Home se escribió de forma independiente y correcta en aislamiento, pero sin mirar a sus vecinos.

## 10. Problemas de navegación

Ninguno bloqueante. El único hallazgo real es el de Bankroll alcanzable solo desde Home (§5, P2) — el resto de la navegación (tabs, FAB, back desde pantallas empujadas) está probado y funciona como se espera.

## 11. Hallazgos P0/P1/P2

| # | Severidad | Hallazgo |
|---|---|---|
| 1 | **P1** | Redundancia: `ContinueLearningCard` + `AcademyProgressCard` muestran el mismo progreso dos veces seguidas |
| 2 | **P1** | 6 elementos tocables independientes antes del scroll — dilución de "cuál es LA acción" |
| 3 | **P1** | 4 recetas visuales de "card" distintas dentro de una sola pantalla |
| 4 | **P1** | Botón de settings 38×38dp — bajo el mínimo de tap target (heredado de Fase 0, reingresa acá) |
| 5 | **P2** | Doble CTA a Laboratorio cuando la Academia está 100% completa |
| 6 | **P2** | Bankroll solo alcanzable desde la tab Home |
| 7 | **P2** | Título de card: mayúsculas fijas vs. sentence-case para el mismo rol semántico |
| 8 | **P2** | "PRACTICE ROOM"/"COACH" en inglés en medio de una app en español — a confirmar si es deliberado |
| 9 | **P2** | Label de bottom nav a 9.5sp, sin assertion de contraste específica todavía |
| 10 | **P2** | Breakpoint de 480px sin efecto práctico en el target real (mobile) |

**No hay P0** — nada de lo encontrado bloquea el uso ni genera una regresión funcional. Cero hallazgos inventados para justificar cambios: cada uno cita archivo y línea.

## 12. Cambios propuestos (dirección, no implementación)

- **Sobre #1 y #2 (redundancia + densidad):** fusionar `AcademyProgressCard` dentro de `ContinueLearningCard` (o eliminarla como card separada y mover "lecciones completadas/conceptos dominados" a un segundo estado colapsable del hero) — un solo bloque de progreso, no dos. Reduce de 6 a 5 elementos tocables y elimina la barra de progreso duplicada. *Por qué:* menos repetición de la misma información mejora comprensión sin perder nada (criterio de prioridad: comprensión antes que estética, §22 de tu prompt).
- **Sobre #3 (recetas de card):** definir si `GlassCard` es la base real y hacer que `PracticeRoomCard`/`HomeLinkCard`/`_HeroShell` lo envuelvan (con sus variantes de color/gradiente ya soportadas por sus parámetros actuales) en vez de reimplementar `BoxDecoration` cada vez. *Por qué:* menos superficie de mantenimiento, consistencia real en vez de "parecido a ojo".
- **Sobre #4 (tap target):** agrandar el contenedor tocable del botón de settings a 48×48 manteniendo el ícono visual en 18-20px adentro (el área tocable no tiene por qué ser del mismo tamaño que lo que se ve). Cambio aislado, bajo riesgo.
- **Sobre #5:** en el estado "Academia completa", ocultar `PracticeRoomCard` (ya redundante con el CTA de práctica del hero) en vez de mostrar ambos.
- **Sobre #6:** evaluar si Bankroll merece un atajo desde el FAB (junto a las calculadoras) — a decidir con el usuario, no autoevidente que sea necesario.
- **Sobre #7/#8:** unificar el tratamiento tipográfico de "título de card" en un solo estilo, y confirmar con el usuario si "Practice Room"/"Coach" son nombres de marca deliberados (en cuyo caso se documentan como tal) o se traducen.
- **Sobre #9:** subir el label a un tamaño mínimo legible (11-12sp) y agregar una assertion de contraste específica para la bottom nav.
- **Sobre #10:** eliminar el breakpoint de 480 o documentar explícitamente que es para tablet/desktop (fuera del target mobile-first actual).

Ninguno de estos cambios toca currículo, progreso, desbloqueos, autenticación o persistencia — todos son de presentación/composición, dentro de lo permitido por las reglas absolutas de esta fase.

## 13. Tests que deberán proteger el cambio

- `test/ui/home_screen_test.dart` — ya cubre los 3 estados de Academia + navegación a Bankroll/Tools/Coach + sweep responsive; si se fusionan `ContinueLearningCard`/`AcademyProgressCard`, varios `expect` van a necesitar actualizarse (no es una regresión, es que el test debe seguir al cambio intencional).
- `test/accessibility/core_screens_accessibility_test.dart` — el test del botón de settings debería pasar a verde real si se corrige el tap target (no hay que "arreglar el test", hay que arreglar el widget).
- `test/golden/screens_golden_test.dart` (`home_screen`) y `test/golden/core_ui_golden_test.dart` (si se toca `GlassCard`/`HomeLinkCard`) — van a fallar por diseño si el cambio es real; se regeneran conscientemente con `--update-goldens` y se documenta por qué, nunca a ciegas.
- Nuevo, si se toca la bottom nav: una assertion de `textContrastGuideline` específica sobre `AppBottomNavigation` en su estado inactivo (hoy no existe, el accessibility test actual cubre `AppShell` en general pero no aísla ese componente).

## 14. Riesgos

- Fusionar `ContinueLearningCard`+`AcademyProgressCard` es el cambio de mayor superficie — toca el elemento más probado de la pantalla; hay que revisar con cuidado los 4 estados (loading/nuevo/progreso/completa) para no perder ninguno.
- Cualquier cambio a `GlassCard` (si se decide que sea la base común) se propaga a `AcademyProgressCard`, y potencialmente a cualquier otro lugar que ya lo use — bajo riesgo hoy porque su uso real es mínimo (Fase 0 lo confirmó), pero hay que verificarlo de nuevo antes de tocarlo.
- Ninguno de los cambios propuestos toca `AcademyController`, `AuthController`, `AcademyStore` ni ningún archivo de `lib/engine/` — el riesgo funcional real es bajo; el riesgo principal es puramente de regresión visual/de tests, cubierto por goldens+accessibility+la suite existente.

---

**No se implementó nada de lo anterior todavía.** Quedo a la espera de tu confirmación sobre qué hallazgos priorizar (o si preferís que avance directo con los P1) antes de pasar a DESIGN → IMPLEMENT.
