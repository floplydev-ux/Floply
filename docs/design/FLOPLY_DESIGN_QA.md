# FLOPly — Design QA Checklist

Checklist para auditar cualquier pantalla futura contra el sistema "Sala Verde". Pensado para usarse pantalla por pantalla, antes de dar por cerrada una implementación.

## Identidad

- [ ] Si se le quita el logo/nombre de la app, ¿un usuario que ya conoce FLOPly la reconocería igual? (superficie de lectura marfil, materialidad de la mesa, tipografía numérica)
- [ ] ¿Aparece `color.accent.brass` en algún elemento clave (CTA, progreso, marca), o la pantalla depende solo del color de sección para sentirse "de FLOPly"?
- [ ] ¿Toda cifra de póker (BB/%/EV/frecuencia/saldo) usa la familia numérica tabular?

## Jerarquía

- [ ] ¿El usuario entiende en menos de 2 segundos cuál es la acción/dato principal de la pantalla?
- [ ] ¿Hay más de un elemento compitiendo por máxima prominencia (dos CTAs primarios, dos textos en `type.headline`)?
- [ ] ¿La jerarquía se logra con tipografía/spacing, o se resolvió "a la fuerza" con una card nueva o un color nuevo?

## UX

- [ ] ¿La interfaz deja clara la decisión que el usuario debe tomar antes de que la tome (sin revelar la respuesta)?
- [ ] Si hay feedback de correcto/incorrecto, ¿respeta el patrón "Equivocarse" de `FLOPLY_UX_PATTERNS.md` (mismo tono, mismo motion, sin lenguaje punitivo)?
- [ ] ¿El siguiente paso siempre es evidente (no hay un dead-end sin CTA)?

## Consistencia

- [ ] ¿Todos los radios usados están en la escala de 5 valores de `FLOPLY_DESIGN_LANGUAGE.md` §5.4?
- [ ] ¿Todo el spacing está en la escala de `space.*`?
- [ ] ¿Se reutilizó `component.callout.accent`/`component.progress.linear`/`component.chip.*` en vez de reimplementar el patrón a mano?
- [ ] ¿El color de sección (`color.section.academy/laboratory/tools`) es coherente con dónde vive la pantalla, incluso si reutiliza un widget compartido con otra sección? (revisar especialmente mesas jugables compartidas entre Academia/Laboratorio)
- [ ] ¿Todo uso de `feltGreen`/`steelBlue`/`graphiteSteel`/`error` como TEXTO o ÍCONO usa la variante `*Bright` (nunca el valor base, calibrado para relleno/superficie)? Ver `FLOPLY_DESIGN_LANGUAGE.md` "Principio de contraste por contexto de uso" (Fase 1.75).
- [ ] ¿Cualquier grupo de 2+ `chip.numeric` está en `Wrap`, no en `Row`? ¿El label puede truncarse pero el valor numérico nunca se corta? (regla cerrada en Fase 1.75 tras un overflow real con copy de producción)

## Materialidad (añadido tras crítica de Fase 0.5)

- [ ] ¿Aparece textura de veta de madera, vignette de fieltro renderizado o brillo especular metálico en algún lugar fuera de `PokerTableView`?
- [ ] ¿`surfaceFelt` cubre la pantalla completa en vez de una franja acotada?
- [ ] ¿`brass` aparece como color de fondo/relleno en más de un elemento de la misma pantalla?
- [ ] ¿Una superficie de lectura de alta frecuencia (teoría, ejercicio) tiene textura, gradiente o efecto decorativo que no cumple ninguna función de legibilidad?
- [ ] Si se mira la pantalla en blanco y negro, ¿sigue existiendo jerarquía reconocible (por tipografía, spacing, forma) sin depender del color/material?

## Diferenciación

- [ ] Sacando el contenido de póker, ¿esta pantalla podría pertenecer a cualquier app de dashboard/SaaS/edtech genérica? Si la respuesta es sí, no está terminada.
- [ ] ¿Se violó alguna regla de `FLOPLY_ANTI_GENERIC.md`? Repasar la lista completa, no solo las que parecen aplicar a simple vista.

## Mobile

- [ ] ¿Funciona a 360-400px de ancho sin overflow ni texto cortado?
- [ ] ¿Los objetivos táctiles tienen al menos 44×44dp de área, incluso si el elemento visual es más chico (ver `Icon Button`/`UserAvatar`)?
- [ ] ¿La jerarquía sobrevive sin los efectos decorativos (probar mentalmente en escala de grises, sin sombras)?

## Poker

- [ ] ¿Toda información específica de póker (posición, stack, pot odds, rango) tiene una representación clara y no ambigua?
- [ ] ¿Se usa BB como unidad, nunca "$" simulado, salvo que el contexto sea explícitamente Bankroll real?
- [ ] Si hay una mesa involucrada, ¿se respetó su lenguaje visual existente (`FLOPLY_DESIGN_BRIEF.md` A.1, materialidad de `PokerTableView`) en vez de introducir un tratamiento de cartas/fichas alternativo?

## Pedagogía

- [ ] ¿La interfaz ayuda activamente a aprender (señala, contrasta, explica con datos) o solo presenta información pasivamente?
- [ ] ¿El error se convierte en diagnóstico accionable, no solo en un marcador de "mal"?
- [ ] ¿La densidad de información es apropiada para la sección (Academia = respirada, Laboratorio = densa) según la matriz de `FLOPLY_UX_PATTERNS.md`?

## Accesibilidad (complementa `accessibility-audit-flutter`)

- [ ] ¿Todo texto cumple contraste AA mínimo contra su superficie real (no asumir — el sistema ya tiene 2 fixes de contraste documentados en el código actual; no reintroducir el mismo error con `textMuted`/`disabled` sobre fondos oscuros)?
- [ ] ¿Los estados (bloqueado/correcto/incorrecto/en curso) se comunican con algo más que color (ícono, texto, `Semantics`)?
- [ ] ¿Hay algún motion en loop que debería respetar `prefers-reduced-motion`/reduced-motion del sistema?

---

## Cómo usar este checklist

1. Antes de una implementación: usarlo como lista de intención (qué debería cumplir la pantalla).
2. Después de implementar: repasarlo ítem por ítem contra la pantalla real, no contra el mockup.
3. Cualquier "no" debe tener una justificación explícita documentada (no un "se me pasó") o debe corregirse antes de considerar la pantalla terminada.
