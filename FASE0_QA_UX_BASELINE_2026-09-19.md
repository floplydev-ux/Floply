# FLOPly — Fase 0: Baseline de QA + UX/UI

**Fecha:** 2026-09-19
**Alcance:** construir infraestructura de QA/UX (Flutter + Web), medir el estado real del proyecto, documentar hallazgos. **No se rediseñó nada.** Los hallazgos de UX/UI/accesibilidad listados acá quedan pendientes de corrección para una fase posterior — ver §12.

---

## 1. Executive Summary

FLOPly está en buen estado técnico de base: `flutter analyze` en 0 issues, 960/960 tests preexistentes en verde, build web exitoso. La Fase 0 agregó una capa de infraestructura de QA que no existía (golden testing, accessibility testing automatizado, integration testing) sin tocar ningún archivo de producto, y esa infraestructura ya corre y ya encontró un hallazgo real (un botón por debajo del tamaño mínimo de tap target).

El sistema de diseño existente es más fuerte en colores (`AppColors`, centralizado, bien organizado) que en tipografía/spacing/componentes (ver §9): hay duplicación de componentes real y un tema tipográfico (`AppTheme.dark.textTheme`) que ningún screen usa. Nada de esto es urgente ni bloqueante — es exactamente el tipo de información que esta fase debía producir.

Dos limitaciones reales de entorno quedaron documentadas, no resueltas: no hay emulador/dispositivo Android configurado, y el proyecto no tiene scaffold de Windows desktop — ambas cosas bloquean la ejecución (no la preparación) de `integration_test`/Patrol hoy.

## 2. QA Stack

**Ya existía:** `flutter_test` (SDK) + `flutter_lints ^4.0.0`. Sin CI (`.github/` no existe), sin golden tests, sin `integration_test/`, sin accessibility testing automatizado.

**Agregado en Fase 0** (`pubspec.yaml`, dev_dependencies):

| Paquete | Versión | Rol | Compatibilidad verificada |
|---|---|---|---|
| `integration_test` | SDK (Flutter 3.47.2) | Integration testing oficial | Ships con el SDK, sin versión propia |
| `patrol` | ^4.10.0 | E2E con automatización nativa (Android/iOS) | Pide Dart `>=3.8.0`/Flutter `>=3.32.0`; este proyecto tiene 3.13.2/3.47.2 — cubierto de sobra |
| `alchemist` | ^0.14.0 | Golden/visual regression testing | Mismos requisitos que patrol — cubierto |
| `flutter_test` matchers (`meetsGuideline`) | SDK | Accessibility testing automatizado | Ya incluido, cero dependencia nueva |

`flutter pub get` corrió sin conflictos (`Changed 16 dependencies!`, todas transitivas de patrol/alchemist, ninguna pisa una dependencia existente). `flutter analyze` se mantuvo en 0 issues antes y después.

**Del lado Claude Code** (de la fase de preparación anterior, sin cambios acá): plugins `frontend-design` y `playwright`; skills propias `ux-audit-flutter`, `flutter-ui-design`, `accessibility-audit-flutter`, `flutter-qa`, `educational-ux-audit`.

## 3. Test Inventory

| Categoría | Antes de Fase 0 | Agregado en Fase 0 |
|---|---|---|
| Unit (`test/engine/`) | 55 archivos | — |
| Widget (`test/ui/`) | 36 archivos | — |
| Helpers (`test/support/`) | 1 (`mentor_walk.dart`) | +2 (`app_harness.dart`, `responsive_widths.dart`) |
| Golden (`test/golden/`) | No existía | 2 archivos, 8 `goldenTest()` (3 componentes core + 5 pantallas) |
| Accessibility (`test/accessibility/`) | No existía | 1 archivo, 2 tests |
| Integration (`integration_test/`) | No existía | 1 archivo, 1 flujo (preparado, ver §10 — no ejecutable en este entorno hoy) |
| E2E nativo (Patrol) | No existía | No implementado — sin device Android/iOS no hay nada que verificar (ver §10) |
| CI | No existe (`.github/` ausente) | Sin cambios — fuera de alcance de esta fase |

## 4. Baseline Results (números reales)

**Antes de tocar nada** (ver más abajo — se repitió después de instalar la infraestructura nueva, para confirmar cero regresiones):

| Comando | Resultado | Duración |
|---|---|---|
| `flutter analyze` | 0 issues | 2.4s |
| `flutter test --concurrency=1` | 960/960 passed | 281s |
| `flutter build web` | Éxito (`build/web`) | 66s |

**Después de agregar infraestructura** (misma corrida, todo el árbol `test/`):

| Comando | Resultado | Duración |
|---|---|---|
| `flutter analyze` | 0 issues | 2.3–2.5s (estable) |
| `flutter test --concurrency=1` | 969 corridos: 968 passed, **1 failed** | 278s |

El único failure es un hallazgo real de accesibilidad, dejado en rojo a propósito (ver §6) — **no es una regresión**: los 960 tests preexistentes siguen exactamente en verde; el +9 nuevo son 8 golden (todos verdes) + 2 accessibility (1 verde, 1 rojo documentado).

## 5. Visual Baseline (goldens)

8 goldens generados en `test/golden/goldens/ci/` (modo CI de Alchemist: texto reemplazado por bloques de color determinísticos, independiente de fuentes instaladas — así el baseline es reproducible en cualquier máquina, no solo en esta Windows local).

| Componente/Pantalla | Cubierto | Nota |
|---|---|---|
| `GlassCard` | ✅ (2 variantes: default, gradiente) | Core UI |
| `AppBottomNavigation` | ✅ (5 variantes, una por tab activo) | Core UI |
| `HomeLinkCard` | ✅ (2 variantes: default, muted) | Core UI |
| `HomeScreen` | ✅ (usuario nuevo, 390dp) | — |
| `ToolsScreen` (hub) | ✅ (390dp) | — |
| `BankrollScreen` | ✅ (390dp) | — |
| `AcademyScreen` (mapa de niveles) | ✅ (390dp, estado inicial) | — |
| `LaboratoryScreen` (inicio) | ✅ (390dp, antes de "Empezar a practicar") | — |
| Academia: teoría / ejercicio / feedback / progreso (pasos intermedios) | ❌ Diferido | Necesitan fixtures de estado más profundas (avanzar el controller a un paso específico) — no esenciales para "tener una base", quedan identificadas para cuando se audite Academia en profundidad |
| Laboratorio: acciones / feedback / estados intermedios | ❌ Diferido | Mismo motivo |

Recordatorio explícito (pedido por el usuario, tal cual): **estos goldens representan el estado visual ACTUAL, no lo certifican como correcto.** Sirven para detectar cambios no intencionales de acá en adelante.

**Bug de arnés encontrado y corregido en el camino** (no es un bug de la app): la primera versión de los goldens de pantalla completa usaba solo `scenarioConstraints` (un `BoxConstraints`) para fijar el ancho, sin fijar `MediaQuery` — como varios widgets miden su layout contra `MediaQuery.of(context).size` y no solo contra las constraints del padre, esto producía overflows falsos (`HomeHeader`, `PracticeRoomCard`, `HomeLinkCard`) que **no existen** a 390dp real (los mismos widgets ya pasan sin overflow en `test/ui/home_screen_test.dart`, que sí fija `tester.view.physicalSize`). Se corrigió envolviendo cada escenario en un `MediaQuery` explícito de 390×844. Confirmado con una segunda corrida limpia.

## 6. Accessibility Baseline

Capa automatizada agregada con los matchers oficiales de `flutter_test` (`meetsGuideline`), sobre `AppShell` (Home, invitado) y `ToolsScreen`:

- `androidTapTargetGuideline` (mínimo 48×48dp)
- `iOSTapTargetGuideline` (mínimo 44×44dp)
- `labeledTapTargetGuideline` (todo elemento tocable tiene label)
- `textContrastGuideline` (contraste WCAG 2.1 AA)

**Hallazgo real (no corregido, documentado a propósito):**

| Severidad | Archivo | Problema |
|---|---|---|
| Major | `lib/screens/home/widgets/home_header.dart:53-67` | El botón de configuración (ícono `settings_rounded`) mide 38×38dp — por debajo del mínimo de 48×48 (Android) y 44×44 (iOS). Es el único elemento que falla de los 4 guidelines chequeados. |

`ToolsScreen` pasa las 4 guidelines sin hallazgos.

**Fuera del alcance automatizable esta fase** (documentado, no un olvido):
- Orden real de lectura de un screen reader y si los anuncios dinámicos (ej. feedback de un ejercicio) efectivamente se leen en voz alta — `meetsGuideline` no lo verifica.
- Juicio sobre si un label tiene sentido en español natural.
- Accesibilidad dentro de Academia/Laboratorio en estados intermedios (mismo motivo que los goldens diferidos, §5).

## 7. UX/UI Baseline

Pase inicial con las skills `ux-audit-flutter` / `flutter-ui-design`, apoyado en un inventario de arquitectura real (no readings superficiales) — **no es una auditoría exhaustiva**, es el primer corte que esta fase pedía.

**Navegación / IA:** consistente. 5 tabs (`IndexedStack`) + FAB global de acceso rápido a Tools + Tools/Bankroll alcanzables desde tarjetas de Home (no son tabs, decisión de diseño razonable dado que son módulos secundarios). Sin hallazgos de fricción de navegación en este pase.

**Consistencia visual — el hallazgo más consistente de esta fase:**
- **Componentes duplicados:** `GlassCard` (el "card base" documentado como "usado en casi toda la Home") en la práctica solo se usa en 1 lugar; `ToolsScreen` reimplementa la misma receta desde cero como `ToolCard` (mismo `BoxDecoration`, radios/paddings ligeramente distintos, sin el `boxShadow`); **29 archivos** más definen su propio `BoxDecoration` con `AppColors.surface` en vez de reusar `GlassCard`.
- **Botones:** casi no se usan los widgets reales de Material (`ElevatedButton`/`TextButton`/`OutlinedButton` — 2 usos en total en `lib/screens`+`lib/auth`+`lib/widgets`). Cada pantalla define su propio `_CtaButton`/`_PrimaryButton`/`_ProviderButton` privado sobre `GestureDetector`+`PressableScale`.
- **Estados de carga/error/vacío:** no hay un `LoadingView`/`ErrorView`/`EmptyView` compartido — cada pantalla resuelve el spinner y el mensaje de error a mano (funcionalmente correcto, estructuralmente repetido).

Ninguno de estos hallazgos es un bug visible para el usuario final — son deuda de mantenibilidad que hace más caro el próximo cambio visual grande.

## 8. Learning UX Baseline

Esta fase se enfocó en infraestructura, no en una auditoría pedagógica nueva — el trabajo previo ya documentado en la memoria del proyecto (`academia-auditoria-pedagogica`) cubre el diagnóstico pedagógico real hecho anteriormente en esta misma iniciativa, con sus hallazgos ya implementados en una etapa posterior. No se encontraron hallazgos pedagógicos NUEVOS en este pase — decirlo explícitamente es preferible a inventar hallazgos para llenar la sección. Una auditoría de `educational-ux-audit` en profundidad (contenido real, nivel por nivel) es trabajo de Fase 1, no de esta.

## 9. Design System Baseline

*"Qué tenemos realmente" — sin veredicto de si está bien o mal.*

- **Colors:** ✅ centralizados en `lib/theme/app_colors.dart` — única fuente, con gradientes documentados por módulo (violeta=Academia, verde=Laboratorio). El punto más sólido del design system actual.
- **Typography:** ⚠️ `AppTheme.dark` define un `textTheme` (headlineSmall/titleMedium/bodyMedium/labelLarge) que **ningún screen usa** — 0 referencias a `textTheme` en `lib/screens`, contra 204 literales `TextStyle(...)` ad-hoc, con tamaños no redondos (`14.5`, `12.5`, `11.5`, `9.5`) que sugieren ajuste manual por widget en vez de una escala.
- **Spacing:** ⚠️ sin constante/token — los valores de `SizedBox`/`EdgeInsets` agrupan sueltamente alrededor de 2/4/6/8/10/12/14/16/18/20, pero con suficientes valores atípicos (3, 5, 7, 9, 13, 15, 22, 48) como para no ser un sistema gobernado.
- **Components:** 6 widgets reusables reales en `lib/widgets/` (`GlassCard`, `AppBottomNavigation`, `PressableScale` — el más reusado con 20+ usos, `HomeLinkCard`, `UserAvatar`, `ConceptMasteryBar` — extraído correctamente para evitar una 3ª copia, buen ejemplo a seguir). Tools tiene su propio mini design-system (`tool_widgets.dart`) no compartido con el resto.
- **States:** ad-hoc por pantalla (ver §7).
- **Navigation:** imperativa (`Navigator.push`, sin `GoRouter`), raíz de 5 tabs vía `IndexedStack`.

## 10. Critical Flows

| Flujo | Viabilidad técnica | Estado |
|---|---|---|
| Tools: Home → Tools (FAB) → Calculadora → Volver | ✅ Viable hoy | **Implementado** como `integration_test/flows/tools_flow_test.dart`, usando el mismo harness sin Firebase real que ya prueban los widget tests existentes (`test/ui/app_shell_test.dart` ejercita una secuencia casi idéntica y está en verde) |
| Academia: Home → Academia → Nivel → Teoría → Ejercicio → Respuesta → Feedback → Siguiente → Progreso | ✅ Viable (el patrón ya existe en `test/ui/academy_level*_test.dart`, que recorren el currículo completo) | No portado a `integration_test/` todavía — trabajo de adaptación real, no técnico-imposible, diferido |
| Laboratorio: Home → Laboratorio → Ejercicio → Decisión → Feedback → Siguiente | ✅ Viable (patrón ya en `test/ui/laboratory_screen_test.dart`) | Mismo diferimiento que Academia |

**Limitación real de entorno (no resuelta, documentada):** ningún flujo de `integration_test/` puede EJECUTARSE en esta máquina hoy:
- No hay emulador/dispositivo Android configurado (`adb`/`emulator` están instalados, pero `emulator -list-avds` no devuelve ningún AVD).
- El proyecto no tiene carpeta `windows/` (soporte desktop no scaffoldeado) — `flutter test integration_test/... -d windows` falla con "No Windows desktop project configured".
- `flutter test integration_test/... -d chrome` falla: *"Web devices are not supported for integration tests yet"* — correr en web requiere `flutter drive` + chromedriver, una pieza de infraestructura aparte que esta fase no instaló (hubiera sido agregar alcance no pedido explícitamente).

El archivo del flujo de Tools **analiza limpio** y usa exactamente el mismo código ya probado en widget tests — es infraestructura real, lista para el día que exista un target donde correr.

## 11. Known Issues

1. **(Accesibilidad, real)** Botón de settings en Home header, 38×38dp — ver §6.
2. **(Mantenibilidad, real)** `GlassCard` subutilizado + reimplementado como `ToolCard` + 29 archivos con su propio `BoxDecoration` — ver §7/§9.
3. **(Mantenibilidad, real)** Tema tipográfico definido pero no usado — ver §9.
4. **(Mantenibilidad, real)** Sin escala de spacing — ver §9.
5. **(Entorno, no bloquea el uso de la app)** Sin emulador Android configurado.
6. **(Entorno, no bloquea el uso de la app)** Sin scaffold de Windows desktop.
7. **(Entorno, no bloquea el uso de la app)** Web E2E necesita `flutter drive`+chromedriver, no instalado todavía.
8. **(Higiene de repo, preexistente — NO originado en esta fase)** `git status` muestra 212 archivos con cambios sin commitear, de trabajo anterior a esta fase (motor preflop, EV avanzado, etc.). Se señala porque es relevante para el usuario, no porque esta fase lo haya causado — ningún archivo de ese listado fue tocado acá salvo los explícitamente listados en §14.

## 12. Recommended Phase 1

En orden de impacto/costo:
1. Arreglar el tap target de 38×38 del botón de settings (fix chico, aislado, con test de regresión ya escrito).
2. Decidir: ¿adoptar `GlassCard` como card base real (y por qué no se está usando hoy) o formalizar `ToolCard` como la versión canónica? Cualquiera de las dos decisiones reduce duplicación — elegir una.
3. Decidir sobre la escala tipográfica: ¿revivir `AppTheme.dark.textTheme` y migrar screens a usarlo, o aceptar el estilo ad-hoc y borrar el `textTheme` no usado? Ambas son mejores que el estado actual (definido-pero-ignorado).
4. Extraer un `LoadingView`/`ErrorView`/`EmptyView` compartido antes de que la próxima pantalla nueva agregue una 4ª variante.
5. Decisión de infraestructura (no de producto): ¿vale la pena configurar un AVD de Android para habilitar QA en dispositivo real (Patrol nativo, Maestro)? Es la única pieza que falta para cerrar el loop de integration testing end-to-end.

## 13. Exact Commands

```bash
# Static
flutter analyze

# Unit + Widget (toda la suite, incluye golden y accessibility)
flutter test --concurrency=1

# Solo golden (comparar contra baseline)
flutter test test/golden

# Regenerar baseline de golden (después de un cambio visual intencional)
flutter test test/golden --update-goldens

# Solo accessibility
flutter test test/accessibility

# Web
flutter build web

# Integration (bloqueado hoy — ver §10; funcionará apenas exista un target)
flutter test integration_test/flows/tools_flow_test.dart -d <device_id>

# Patrol (requiere patrol_cli + device Android/iOS; no configurado esta fase)
dart pub global activate patrol_cli
patrol test
```

## 14. Files Changed

Todo lo que esta fase tocó o creó — **nada más** (ver Known Issue #8: el resto de `git status` es trabajo anterior, no de acá):

**Modificado:**
- `pubspec.yaml` (agregadas `integration_test`, `patrol ^4.10.0`, `alchemist ^0.14.0`)
- `pubspec.lock` (regenerado por `flutter pub get`)

**Nuevo:**
- `dart_test.yaml`
- `test/support/app_harness.dart`
- `test/support/responsive_widths.dart`
- `test/golden/flutter_test_config.dart`
- `test/golden/core_ui_golden_test.dart`
- `test/golden/screens_golden_test.dart`
- `test/golden/goldens/ci/*.png` (8 imágenes: `glass_card`, `app_bottom_navigation`, `home_link_card`, `home_screen`, `tools_screen`, `bankroll_screen`, `academy_screen_level_map`, `laboratory_screen_start`)
- `test/accessibility/core_screens_accessibility_test.dart`
- `integration_test/flows/tools_flow_test.dart`
- Este documento (`FASE0_QA_UX_BASELINE_2026-09-19.md`)

Ningún archivo de Home/Academia/Laboratorio/Tools/Bankroll/currículo/navegación/autenticación/persistencia fue modificado.

## 15. Final Validation

| Check | Resultado |
|---|---|
| `flutter analyze` | ✅ 0 issues |
| Tests preexistentes (960) | ✅ 960/960, sin regresiones |
| Tests nuevos — golden (8) | ✅ 8/8 |
| Tests nuevos — accessibility (2) | ⚠️ 1/2 (1 hallazgo real documentado en §6, no un bug de infraestructura) |
| `flutter build web` | ✅ Éxito |
| Integration (`integration_test/`) | ⏸️ Preparado, no ejecutable en este entorno (§10) |

**Criterio de salida de Fase 0 (contra la lista original):** cumplido en su totalidad salvo el punto de "baseline funcional" de integration testing, que queda explícitamente documentado como bloqueado por limitación real de entorno (no por falta de preparación) — exactamente el caso que la regla de salida contempla.
