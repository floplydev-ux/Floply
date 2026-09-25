# FLOPly — Design Tokens (estructura conceptual)

Este documento define la **estructura** de tokens que debería existir cuando esta dirección se implemente en Flutter. No es código todavía — es el árbol de nombres y su intención, para que la implementación no reinvente nomenclatura pantalla por pantalla.

No sustituye a `FLOPLY_DESIGN_LANGUAGE.md` (que define los valores y sus reglas de uso) — este documento define **cómo se nombran y organizan** esos valores para que puedan traducirse 1:1 a clases Dart (`AppColors`, `AppTheme`, y las nuevas `AppSpacing`/`AppRadius`/`AppMotion` que hoy no existen).

---

## Estructura de namespaces

```text
color.*
  color.surface.background
  color.surface.recede
  color.surface.base            // hoy "surface"
  color.surface.elevated
  color.surface.reading          // marfil — exclusivo lectura larga
  color.surface.felt             // exclusivo Laboratorio / zonas de decisión

  color.accent.brass             // metal de marca, único acento "de marca"
  color.accent.brassBright
  color.accent.brassDeep

  color.section.academy          // = feltGreen — temperatura cálida
  color.section.laboratory       // = steelBlue — temperatura fría
  color.section.tools            // = graphiteSteel — temperatura neutra

  color.semantic.success
  color.semantic.warning
  color.semantic.error
  color.semantic.information
  color.semantic.disabled

  color.text.primary
  color.text.secondary
  color.text.muted
  color.text.onReading.primary   // ink sobre marfil
  color.text.onReading.secondary

  color.border.subtle
  color.border.focus
  color.border.separator

type.*
  type.display                   // familia display + tamaño 28/700
  type.headline                  // 22/700
  type.title                     // 17/700
  type.body                      // 15/400
  type.bodyStrong                // 15/600
  type.label                     // 12.5/700/uppercase
  type.caption                   // 11.5/500
  type.numeric.display           // 24/600 monoespaciada
  type.numeric.inline            // 14/600 monoespaciada
  type.numeric.micro             // 11.5/500 monoespaciada

space.*
  space.xs   // 4
  space.sm   // 8
  space.md   // 12
  space.lg   // 16
  space.xl   // 24
  space.xxl  // 32
  space.section // 48

radius.*
  radius.sharp    // 2
  radius.panel    // 10
  radius.control  // 14
  radius.pill     // 999
  radius.sheet    // 20 (solo esquinas superiores)

elevation.*
  elevation.level0   // en la mesa — sin sombra
  elevation.level1   // apoyado — sombra de contacto corta
  elevation.level2   // flotante — overlays reales

motion.*
  // Nombres cerrados en Fase 1.75 (ver FLOPLY_DESIGN_DECISIONS.md #5) —
  // instant=110ms, no 100: es el valor real de PressableScale en
  // producción, el token se adaptó al código existente.
  motion.duration.instant   // 110ms  — "responder"
  motion.duration.fast      // 160ms  — "responder"
  motion.duration.normal    // 220ms  — "asentarse"
  motion.duration.emphasis  // 320ms  — "asentarse", contenido más grande
  motion.curve.settle       // ease-out con leve overshoot físico (fichas/cartas)
  motion.curve.respond      // ease-in-out corto

component.*
  component.card.panel            // superficie de contenido sin interacción
  component.card.tappable         // superficie tocable (lección, tool, nivel)
  component.card.reading          // superficie marfil de teoría
  component.button.primary
  component.button.secondary
  component.button.icon
  component.chip.status           // pill semántico (correcto/aceptable/incorrecto)
  component.chip.numeric          // valor numérico inline (BB, %, EV)
  component.badge.state           // candado/disponible/en curso/completado
  component.progress.linear
  component.callout.accent        // regla vertical + label, reemplaza "card con borde"
  component.nav.bottom
  component.nav.fab
  component.sheet.bottom
  component.dialog
  component.emptyState
  component.loadingState
  component.errorState
```

---

## Reglas de esta estructura

1. **`color.section.*` nunca se usa directamente en un componente de contenido** (botón, chip, texto) — se usa solo en: header de la sección, acento de progreso de esa sección, FAB/CTA propio de esa sección. El contenido (correcto/incorrecto/aceptable) siempre usa `color.semantic.*`, nunca `color.section.*`, para que "correcto" signifique lo mismo en Academia y en Laboratorio.
2. **`color.accent.brass` es el único token que puede aparecer en las cinco áreas** (Academia, Laboratorio, Tools, Coach, Bankroll) como "esto es de FLOPly" — todo lo demás es contextual a la sección.
3. **`type.numeric.*` es obligatorio** para cualquier valor que sea: BB, %, EV, pot odds, frecuencia, saldo, contador "x/y". Nunca se usa `type.body`/`type.bodyStrong` para estos valores, ni siquiera en contextos donde "no hay una fuente monoespaciada a mano" — es una regla dura, no una preferencia.
4. **`component.callout.accent` reemplaza el patrón repetido "Container + BoxDecoration(border: color)"** encontrado ~6 veces en la auditoría (secciones de teoría, objective pill, idea clave, feedback correcto/incorrecto, caption de burbuja, result card). Un único componente con variantes de color semántico, no seis implementaciones ad hoc.
5. **`component.progress.linear` reemplaza las 4 barras de progreso duplicadas** encontradas en la auditoría (`level_map.dart`, `written_theory_view.dart`, `lesson_widgets.dart`, `interactive_table_exercise_view.dart`).
6. Ningún componente puede introducir un valor fuera de `space.*`/`radius.*`/`motion.duration.*` — si hace falta un valor nuevo, se agrega **al token**, no al call site.

## Qué falta para que esto sea código (fuera de alcance de esta fase)

- Confirmar las 2-3 familias tipográficas candidatas (display/UI/numérica) contra licencias disponibles para Flutter (Google Fonts u otra fuente embebida).
- Migrar `AppColors`/`AppTheme` a esta estructura sin romper los ~800 call sites que hoy referencian `AppColors.*` directamente (requiere un mapeo 1:1 documentado, ver tabla de migración en `FLOPLY_DESIGN_LANGUAGE.md` §5.1).
- Crear `AppSpacing`, `AppRadius`, `AppMotion` como clases nuevas (hoy no existen en absoluto).
- Decidir si `TableMaterial` se funde dentro de este árbol (`color.surface.felt`, `color.accent.brass*` derivan de ahí) o se mantiene como especialización de bajo nivel que el nuevo árbol *consume* — recomendado: la segunda opción, para no tocar el renderer de la mesa en la fase de implementación inicial.
