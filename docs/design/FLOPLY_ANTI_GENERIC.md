# FLOPly Anti-Generic Rules

Reglas explícitas para que futuras implementaciones no vuelvan a una UI genérica. Cada regla nace de un hallazgo concreto de la auditoría (`FLOPLY_DESIGN_BRIEF.md` sección A) o de una restricción explícita del brief — no son gustos sueltos.

## Materialidad (añadido tras crítica de Fase 0.5 — riesgo "casino premium")

0. **No usar textura de veta de madera, vignette de fieltro renderizado, ni brillo especular metálico fuera de `PokerTableView`.** Esos efectos existen para hacer creíble un objeto físico real (la mesa); reproducidos en el chrome de la app (botones, cards, headers) dejan de comunicar "materialidad" y empiezan a comunicar "casino online" o, peor, "interfaz skeuomórfica de 2012". La materialidad fuera de la mesa se expresa como **color plano** (`surfaceFelt`, `brass`), nunca como textura.
0.1. **`surfaceFelt` nunca es fondo de pantalla completa.** Como máximo, una franja acotada alrededor de una mesa embebida. Una pantalla enteramente verde-fieltro es, por definición, una mesa de casino disfrazada de app de estudio.
0.2. **`brass` aparece como máximo una vez como relleno de superficie por pantalla.** Puede aparecer más veces como borde fino, ícono o texto, pero no como color de fondo repetido — el oro que empapa una pantalla entera es la señal visual más asociada a "casino"/"lujo falso" que existe; su escasez es lo que le da autoridad.
0.3. **Ninguna superficie de lectura de alta frecuencia** (teoría, bloque de ejercicio, cualquier pantalla vista cientos de veces a lo largo del currículo) **lleva textura, gradiente o efecto decorativo.** La materialidad se reserva para momentos de baja frecuencia y alta carga emocional (la mesa, un resultado, la voz del mentor) — aplicarla a una pantalla de lectura repetida cansa la vista y agrega ruido, no identidad.
0.4. **No repetir el conjunto "madera + fieltro + dorado" como composición completa en más de una superficie por flujo, fuera de la mesa misma.** Si Academia, Laboratorio y Bankroll reproducen la misma combinación completa de materiales en sus propias cards, el producto entero empieza a leerse como una sala de casino con distintos carteles, no como un sistema con secciones diferenciadas.

## Superficies y cards

1. **No usar una card si no agrega jerarquía.** Si el contenido es una sola línea o un solo dato, un separador (`color.border.separator`) alcanza — no envolverlo en `Container`+`BoxDecoration`. *(La auditoría encontró ≥6 implementaciones ad hoc del patrón "card con borde de acento" para callouts que podrían ser una regla vertical + label.)*
2. **No convertir cada sección de una pantalla en una card distinta.** Una pantalla puede tener una sola superficie contenedora; las subdivisiones internas se resuelven con tipografía y espaciado, no con cajas anidadas.
3. **No apilar más de 2 niveles de elevación real** (`elevation.level0/1/2` de `FLOPLY_DESIGN_LANGUAGE.md` §5.5). Una card dentro de una card dentro de un sheet es la señal más clara de "UI genérica generada sin criterio".

## Color

4. **No introducir un color nuevo fuera del sistema de tokens.** Si una pantalla "necesita" un color que no está en `FLOPLY_DESIGN_TOKENS.md`, el problema es de jerarquía o de temperatura de sección, no de falta de color — se resuelve ahí, no agregando un hex nuevo. *(La auditoría encontró 3 paletas paralelas sin relación — `TableMaterial`, gradientes de Tools, "mentor gold" — exactamente este error, cometido tres veces.)*
5. **No usar gradients decorativos porque sí.** Un gradiente solo se permite donde tiene función física real: el fieltro (iluminación radial de una superficie real), el rail (luz sobre un objeto de madera), un CTA de metal (`brass`) que imita una superficie pulida. Un gradiente de fondo de pantalla de dos colores sin ninguna razón material (como los 5 de las calculadoras de Tools hoy) queda prohibido.
6. **No usar sombras con color de acento (glow decorativo) fuera del mecanismo de foco pedagógico documentado.** Un botón no "brilla" porque sí — solo el mecanismo de `Highlightable` (atención dirigida sobre la mesa) puede usar un halo de color, y solo mientras cumple su función de señalar.
7. **`color.section.*` no es intercambiable entre áreas.** Si Laboratorio empieza a usar `feltGreen` "porque queda bien", se pierde la única señal de temperatura que distingue a las secciones — la reutilización de la mesa jugable entre Academia y Laboratorio hoy ya mostró este riesgo (la mitad interior queda "violeta" dentro de una pantalla verde).

## Forma

8. **No crear un radio nuevo fuera de la escala de 5 valores** (`radius.sharp/panel/control/pill/sheet`). Si algo "casi" encaja con 14px pero no exactamente, se redondea al token más cercano, no se crea un sexto valor.
9. **No usar `radius.pill` en botones primarios grandes.** El pill queda reservado a elementos chicos de estado (badges, tabs) — un CTA grande con esquinas 999px es el look de "app genérica" más reconocible que existe hoy en el mercado.
10. **No hacer que todo tenga el mismo radio "porque es el default del framework".** La regla de FLOPly es que el radio comunica tocable vs. legible vs. de instrumento (§5.4) — copiar un único radio de Material 3 a ciegas anula esa señal.

## Tipografía

11. **No usar peso 800/900 como recurso de jerarquía por defecto.** La jerarquía se logra con familia (display vs. UI) y tamaño; el peso extremo es un parche típico de UI sin sistema tipográfico real.
12. **Todo BB/%/EV/frecuencia/saldo/contador usa la familia numérica tabular, sin excepción.** Mostrar una cifra de póker en la fuente de UI normal es, en este sistema, un bug de diseño, no un detalle menor — es la firma visual más importante del producto.

## Iconografía

13. **No usar íconos como decoración.** Si un ícono se puede quitar sin que se pierda información, se quita. Un título no necesita un ícono al lado "para que se vea más completo".
14. **No mezclar familias de ícono con pesos distintos en la misma pantalla.**

## Gamificación

15. **No usar gamificación infantil.** Nada de confeti, insignias coleccionables, puntos por cada micro-acción, barras de racha, o lenguaje de "¡GANASTE!". *(Esto ya es, en gran medida, una decisión de producto ya tomada — las strings de XP/racha existen pero están muertas en el código actual; esta regla formaliza esa decisión para que no se reintroduzca "porque otra app educativa lo tiene".)*
16. **El error nunca se penaliza visualmente más fuerte que el acierto se premia.** Misma velocidad de motion, mismo tratamiento de superficie — ver `FLOPLY_MOTION.md`.

## Patrones prohibidos por nombre

17. **No usar glassmorphism como estética de chrome de app.** `BackdropFilter` decorativo queda reservado, si acaso, a un overlay literal sobre la mesa (vidrio esmerilado sobre el fieltro) — nunca en tarjetas de menú o listas.
18. **No usar neumorphism.**
19. **No copiar Material 3 visualmente** (cards con `surfaceTint`, FABs extendidos genéricos, `Chip` de Flutter sin personalizar). Se puede usar la mecánica de Material (gestos, accesibilidad, `Semantics`) sin heredar su piel visual por defecto.
20. **No usar patrones SaaS por defecto**: nada de sidebars de dashboard, nada de "stat cards" con flechita de tendencia genérica en verde/rojo sin contexto poker, nada de badges "PRO"/"NEW" decorativos.
21. **No usar estética casino**: nada de neón saturado, nada de luces parpadeantes, nada de iconografía de fichas/dados genérica de casino online, nada de "$" como unidad (FLOPly enseña en BB — regla de producto ya vigente en la mesa, se extiende a todo dato monetario simulado).
22. **No usar estética "gaming" genérica**: nada de HUD con barras de vida, nada de tipografía "gamer" angulosa, nada de rangos/niveles con nombres tipo "Bronze/Silver/Gold" ajenos al póker.

## Regla de cierre

23. **Toda decisión visual nueva debe poder responder "por qué" en una frase que no sea "porque se ve bien".** Si la única justificación disponible es estética, no entra al sistema — entra si resuelve legibilidad, jerarquía, identidad de sección, o refuerza la metáfora "Sala Verde" (`FLOPLY_DESIGN_BRIEF.md` §C).
