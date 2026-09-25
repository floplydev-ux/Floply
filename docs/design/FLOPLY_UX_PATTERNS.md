# FLOPly — UX Patterns

Patrones de interacción propios de FLOPly (no solo un sistema visual) y la matriz de diferenciación entre áreas. Estos patrones son los que deberían convertirse en flujos reutilizables cuando se implemente el sistema.

---

## Patrones de interacción propios

### Aprender: teoría → comprensión → ejemplo → consolidación

1. **Teoría** se presenta en `component.card.reading` (superficie marfil) — el cambio de superficie (de `background` oscuro a `surfaceReading` claro) es en sí mismo la señal de "ahora estás leyendo, no decidiendo". Esto reemplaza la necesidad de un ícono "modo lectura": el cambio de superficie ya lo comunica.
2. **Comprensión** se verifica con una `_CheckCard` (pregunta de opción simple) — sin penalización visual fuerte si falla, es una verificación, no un examen.
3. **Ejemplo** se muestra siempre **sobre la mesa real** cuando el concepto lo permite (patrón ya validado por el piloto visual mesa+burbuja) — nunca un diagrama separado si la mesa puede mostrarlo directamente. Cuando el concepto es abstracto (ej. bankroll, historial), se usa `card.reading` con un `chip.numeric` como ancla concreta.
4. **Consolidación** es el ejercicio interactivo — vuelve a la superficie `background`/`surfaceFelt` (ya no es lectura, es decisión), marcando el cambio de modo con el mismo mecanismo de superficie.

### Decidir: situación → decisión → feedback → explicación

1. **Situación**: la mesa (o el bloque de ejercicio) se presenta sobre `surfaceFelt` — la temperatura fría/tensa de Laboratorio, o la variante de Academia cuando el ejercicio es parte de una lección.
2. **Decisión**: opciones en `exercise.block`, sin revelar nada hasta confirmar — nunca mostrar la frecuencia GTO ni ninguna pista de la respuesta antes de decidir (esto ya se respeta hoy y debe blindarse como regla).
3. **Feedback**: inmediato, con `motion.duration.settle` (nunca instantáneo — un instante de "peso" antes de revelar el color, para que la decisión se sienta considerada, no como un semáforo).
4. **Explicación**: siempre disponible, nunca opcional-oculta detrás de un tercer tap si el usuario fue el que erró — el patrón actual de "explicación paso a paso dentro del panel fijo" (`table_explanation_view.dart`) es correcto y se conserva.

### Equivocarse: error → diagnóstico → explicación → oportunidad de reintentar

1. **Error** se muestra con `color.semantic.error` (terroso, no rojo-alarma) — nunca con lenguaje que implique fracaso personal ("MAL", "PERDISTE") sino descriptivo ("no es la mejor opción aquí").
2. **Diagnóstico**: se muestra el dato real (qué frecuencia tenía la jugada correcta, qué opción era mejor y por qué) usando `chip.numeric` — el error se convierte en información, no en un veredicto moral.
3. **Explicación**: la misma superficie de feedback, expandible a "por qué" sin cambiar de pantalla.
4. **Reintentar**: siempre visible como camino hacia adelante, nunca un dead-end — mantener el patrón ya existente de `lesson_result_view.dart` con recuperación.

### Progresar: avance → dominio → siguiente desafío

1. **Avance** se comunica con `component.progress.linear`, animado (nunca un salto instantáneo de valor — el usuario debe *ver* la barra moverse para sentir que el sistema registró su esfuerzo).
2. **Dominio** (no solo "completado") se comunica con datos reales cuando existen (barras de maestría por concepto, ya presentes en `ConceptMasteryBar` — se conserva el principio, se migra el color a los tokens semánticos).
3. **Siguiente desafío** se ofrece explícitamente al terminar (CTA primaria "seguir a X"), nunca dejando al usuario que tenga que volver al mapa a buscar qué sigue.

### Practicar: ejercicio → decisión → resultado → siguiente ejercicio

1. Ciclo corto, sin pantallas de transición innecesarias — el patrón actual de `LabPhase` (idle/question/feedback/summary) ya es correcto estructuralmente; el sistema visual solo debe asegurarse de que la transición feedback→siguiente ejercicio sea `motion.duration.settle`, no un corte abrupto.
2. El resumen de sesión (`session_summary`) debe sentirse como "cerrar la sesión de estudio", no como una pantalla de puntaje de videojuego — cifras exactas, sin superlativos.

---

## Matriz de diferenciación entre áreas (Fase 8)

| Área | Sensación | Jerarquía | Acento | Densidad | Motion |
|---|---|---|---|---|---|
| **Academia** | Cálida, guiada, de mentor — "estás aprendiendo algo real" | Teoría primero (marfil/lectura), ejercicio después; título editorial (`type.headline` display) al frente de cada teoría | `color.section.academy` (feltGreen) para progreso/header; `surfaceReading` predominante | Media — una idea por pantalla, texto respirado | `motion.curve.settle`, ritmo pausado (320ms en transiciones de teoría) |
| **Laboratorio** | Tensa, activa, de sala de decisión — "esto se juega ahora" | La mesa/situación primero, siempre visible; feedback denso (frecuencias, doble puntaje) inmediatamente después | `color.section.laboratory` (steelBlue) para header/CTA/progreso; `surfaceFelt` **acotado** a la franja alrededor de la mesa embebida, no a la pantalla completa (ver `FLOPLY_ANTI_GENERIC.md` "Materialidad" — cubrir toda la pantalla de fieltro es el error de "casino premium"); casi nunca `surfaceReading` | Alta — GTO %, puntajes duales, veredictos de 4 niveles conviven en una pantalla | Más rápido (`motion.duration.quick`/`instant` dominan), sensación de pulso |
| **Tools** | Neutra, instrumental — "una caja de herramientas bien organizada" | Lista de herramientas plana, sin jerarquía de "una más importante que otra"; dentro de cada tool, el resultado numérico es el protagonista (`type.numeric.display`) | `color.section.tools` (graphiteSteel) uniforme para las 5+ herramientas (reemplaza los 5 hues sueltos de hoy) | Alta dentro de cada calculadora (inputs + resultado), baja en el listado | Instantáneo/funcional — sin transiciones largas, el usuario quiere el número ya |
| **Coach** *(capa futura — solo lenguaje visual, sin IA definida)* | Cercana, conversacional, pero con la misma autoridad que Academia — "el mentor te habla directamente" | Conversación/mensaje al frente, siempre con un anclaje concreto (mesa, cifra, lección) — nunca texto libre flotando sin referencia | Usa el mecanismo de burbuja ya validado (`SpeechBubble`/`TableWithBubble`), con `color.accent.brass` como acento de "esto lo dice el mentor" (distinto de los acentos de sección, para que Coach se sienta transversal a las 3 áreas) | Baja — un mensaje a la vez | `motion.curve.settle`, similar a Academia pero con entrada de burbuja más viva (ya validada en el piloto) |
| **Bankroll** | Seria, de "libro de cuentas" — valor y disciplina, no urgencia | Teoría en prosa igual que Academia; cualquier cifra usa `type.numeric.*` con acento `brass` (única área de contenido donde el metal de marca se usa como color de dato, no solo de marca) | `color.accent.brass` como acento propio (coherente: brass = valor) | Baja — es un módulo de lectura + cifras puntuales, no de decisión rápida | Igual que Academia (pausado) — refuerza que Bankroll es reflexión, no acción |

### Principio detrás de la matriz

La identidad global de FLOPly no depende de que las 5 áreas compartan un color — depende de que las 5 compartan **el mismo vocabulario de superficies, tipografía numérica y mecanismos de motion**, variando solo la temperatura de acento y la densidad. Esto es lo que permite que Laboratorio "no se sienta igual que Academia" (mandato explícito del brief) sin convertirse en una app distinta.
