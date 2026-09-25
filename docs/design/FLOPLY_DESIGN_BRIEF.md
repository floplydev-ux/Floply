# FLOPly — Design Brief

Documento maestro de identidad. Cubre auditoría del producto actual, análisis de identidad, direcciones visuales exploradas y la dirección elegida. Los detalles ejecutables (color, tipografía, spacing, componentes, tokens, patrones UX, motion, reglas anti-genéricas, QA) viven en los documentos hermanos listados al final de `FLOPLY_ANTI_GENERIC.md` y en el índice de `/docs/design/`.

**Alcance de esta fase:** solo investigación y documentación. No se modificó código, widgets, navegación, currículo ni ningún archivo de `lib/`.

---

## A. Auditoría del diseño actual

Metodología: lectura completa de `lib/theme/`, `lib/widgets/`, `lib/screens/root/`, `lib/screens/home/`, `lib/screens/academy/`, `lib/screens/laboratory/`, `lib/screens/tools/`, `lib/screens/bankroll/`, `lib/screens/stats/`, `lib/screens/placeholder/` y la implementación completa de `PokerTableView`/`TableLayout`. Sin tocar tests ni código.

### A.1 Qué existe hoy

**Sistema de tema (`lib/theme/`, 2 archivos):**
- `AppColors`: paleta plana de ~20 colores con intención declarada ("nada de `Color(0x...)` suelto fuera de acá") — violeta (`violetPrimary #8B5CF6`, `violetBright #A78BFA`, `violetDeep #3B1670`) para Academia; verde neón (`neonGreen #22E584`, `neonGreenBright #5CFFA8`) para Laboratorio; `gold #FFC94A`, `diamondBlue #4FD1FF`, `danger #FF5C6E`, `warning #FFA84A`; fondo casi negro (`background #060812`); texto `textPrimary/Secondary/Muted`.
- `AppTheme`: un solo `ThemeData` oscuro (Material 3), sin tipografía propia (fuente del sistema), sin escala de spacing, sin escala de radios, sin tokens de sombra/elevación ni de duración.
- **No existe una cuarta capa de tokens** (spacing, radius, motion) en ningún lugar del código — cada pantalla inventa sus propios números.

**Navegación:** `AppShell` con `IndexedStack` de 5 tabs (Home, Academia, Laboratorio, Stats, Cuenta) + un FAB violeta persistente ("Table Mode"). Sin `AppBar` de Flutter en ningún lado — cada pantalla arma su propio header a mano (patrón repetido: círculo-ícono + título + subtítulo).

**Home:** la pantalla más prolija del proyecto — 100% dirigida por `AppColors`, cero literales hardcodeados, animación de entrada escalonada cuidada, ya con dos fixes de contraste WCAG AA documentados en comentarios.

**Academia:** el módulo más maduro y con más peso pedagógico. Ya tiene un vocabulario propio en construcción: `GlassCard`, `PressableScale`, `EducationalPanel`, `LessonNavControls`, badges de rating, secciones de teoría color-codeadas por función semántica (QUÉ ES / POR QUÉ IMPORTA / CÓMO FUNCIONA / CUÁNDO SÍ / CUÁNDO NO / EJEMPLO / ERROR COMÚN). El piloto visual mesa+burbuja (`TableWithBubble`, `SpeechBubble`, `Highlightable`) es la pieza más nueva y mejor pensada de interacción pedagógica: guía la mirada del alumno sobre la mesa real en vez de texto suelto.

**PokerTableView** (`lib/screens/academy/widgets/table/*` + `poker_chip.dart`): es, con diferencia, **la parte con más artesanía visual de todo el proyecto**. Rail de madera con gradiente y luz superior, fieltro con vignette radial y textura de puntos, sombra de contacto que "apoya" la mesa sobre el fondo, cartas con gradiente marfil y dorso propio, y fichas de póker con render físico real (pared con altura, muescas, brillo especular, sombra de apoyo). Tiene su propia paleta interna (`TableMaterial`) — madera, fieltro, marfil, dorado — que **nunca importa `AppColors`** y vive completamente desconectada del resto del sistema visual.

**Laboratorio:** reutiliza casi toda la cromía y chrome de Academia (mismo fondo, mismas cards, mismo `PressableScale`), diferenciándose solo por el acento (verde neón) y por mayor densidad de información (frecuencias GTO, puntaje doble decisión/razonamiento, veredictos de 4 niveles). Cuando reutiliza la mesa jugable de Academia, la mitad interior de esa pantalla (barra de progreso, chips de sizing, botón "seguir") sigue en violeta — la identidad verde de Laboratorio no penetra del todo en sus propias pantallas de mesa.

**Tools:** una gaveta de utilidades con chrome idéntico al resto (mismo `ToolHeader`/`ToolCard` que imita el patrón de header de Home/Academia), pero cada calculadora tiene su propio color de acento sin relación entre sí (5 gradientes de fondo casi idénticos, un color distinto cada uno, repetidos sin factorizar).

**Bankroll:** no es un dashboard financiero — es un módulo de teoría en prosa, estructuralmente idéntico a una lección de Academia (importa literalmente los widgets de navegación de lección de Academia). Usa oro como acento dominante, de forma decorativa/temática, no para codificar ganancia/pérdida real (no hay datos monetarios reales en pantalla).

**Stats:** solo lee progreso de Academia; el bloque de Laboratorio muestra honestamente un estado vacío (no hay historial persistido todavía) en vez de simular números — decisión correcta que hay que preservar.

### A.2 Qué funciona (conservar)

1. **El renderer de la mesa y las fichas** (`table_surface.dart`, `poker_chip.dart`, `playing_card.dart`): es la única parte del producto que ya tiene una voz visual propia, no genérica. Cualquier dirección nueva debe *partir* de este lenguaje, no reemplazarlo.
2. **La ausencia deliberada de gamificación infantil**: no hay XP visible, no hay rachas, no hay confeti (las strings de XP/racha existen pero están muertas — decisión de producto ya tomada de no mostrarlas). Esto hay que blindarlo en las reglas anti-genéricas.
3. **El estado vacío honesto de Laboratorio en Stats** en vez de simular datos.
4. **Los fixes de accesibilidad ya hechos** (contraste de `textMuted`, gradiente de CTA, radios de tap ampliados) — evidencia de que el equipo ya presta atención a esto; la nueva dirección no puede retroceder ahí.
5. **La separación semántica de color por sección** (violeta=Academia, verde=Laboratorio) como *principio* — el problema no es tener acentos por sección, es que el acento es la única diferencia real entre secciones.
6. **`GlassCard`, `PressableScale`, `LessonNavControls`, `EducationalPanel`**: nombres y responsabilidades correctas para ser la base de un sistema de componentes formal.

### A.3 Qué es inconsistente

1. **Dos sistemas de color paralelos que no se hablan**: `AppColors` (chrome de app) y `TableMaterial` (mesa) — más una tercera paleta *de facto* repartida en las 5 calculadoras de Tools y otra en el "mentor gold" (`#E0B860`) de la burbuja pedagógica.
2. **Sin escala de radios**: 14 valores numéricos distintos de `BorderRadius.circular` en uso, sin un solo call site usando una constante compartida.
3. **Sin escala de duraciones**: 15 valores de `Duration(milliseconds:...)` distintos; una misma interacción (tap-scale) usa 110/140/180ms según el archivo.
4. **Sin escala de spacing**: 132 literales de `EdgeInsets` sin ningún token de por medio.
5. **El patrón "card con borde de acento"** (`Container` + `BoxDecoration(border: color)`) está reimplementado a mano al menos 6 veces con ligeras variaciones en vez de existir como un único componente.
6. **4 barras de progreso** casi idénticas, cada una re-escrita en su archivo.
7. **La identidad de Laboratorio no penetra sus propias pantallas de mesa** (queda violeta por dentro).

### A.4 Qué parece genérico

1. **La combinación fondo casi negro + violeta primario + verde neón secundario + cards translúcidas con borde** es, hoy, una paleta que cualquier app de fintech, SaaS B2B o edtech generada en los últimos dos años podría tener — es precisamente el arquetipo "dark mode moderno" que ya no comunica nada específico de FLOPly ni de póker.
2. **El patrón "todo es una card con borde y esquinas redondeadas de ~14-20px"** se repite en más de 15 lugares distintos sin razón semántica — exactamente el antipatrón "convertir cada sección en una card" que el brief pide evitar.
3. **`ToolHeader`/headers de sección**: réplica visual del patrón de header de cualquier app de utilidades — ícono en círculo + título + subtítulo — sin nada que diga "esto es de FLOPly" si se le saca el logo.
4. Los 5 gradientes de fondo de las calculadoras de Tools son variaciones triviales de un mismo patrón sin identidad propia (2 colores, diagonal, un hue distinto cada vez).

### A.5 Qué debería evolucionar

1. La materialidad de la mesa (madera / fieltro / marfil / oro / fichas físicas) debería **dejar de ser un rincón aislado** y convertirse en el lenguaje raíz de todo el sistema — superficies, profundidad, acentos.
2. El acento por color-de-sección debe complementarse con diferenciación real de **composición, densidad y motion**, no solo de hue.
3. Los números (stacks, %, EV, frecuencias, saldo) deberían tener un tratamiento tipográfico propio y consistente — hoy son texto normal con distinto peso según el archivo.
4. Las "cards con borde de acento" que hoy comunican jerarquía por caja deberían evolucionar hacia un sistema donde la jerarquía se comunique primero por tipografía/espaciado y la caja sea la excepción, no la regla.

### A.6 Qué debería desaparecer

1. Las 3 paletas paralelas sin relación (`TableMaterial`, gradientes de Tools, "mentor gold") — deben integrarse a un único sistema de tokens con capas con nombre, no eliminarse su función sino su desconexión.
2. Los radios y duraciones "inventados por archivo".
3. El patrón de header repetido 1:1 en cada módulo sin variación semántica.
4. Las strings muertas de XP/racha (fuera de alcance de esta fase, pero documentado para la implementación).

### A.7 Qué podría convertirse en patrón propio de FLOPly

1. **La mesa como "escenario de verdad"**: en vez de que texto flote sobre íconos, la burbuja+mesa+glow ya demuestra que FLOPly puede enseñar señalando sobre el objeto real. Este patrón (anotar sobre el objeto, no al lado) puede generalizarse a Tools (anotar sobre el grid de rangos) y Laboratorio (anotar sobre la decisión).
2. **Cifras como firma visual**: si se trata a los números (BB, %, EV) con una tipografía tabular/monoespaciada consistente en todo el producto, se convierte en una marca de fábrica reconocible sin depender de color.
3. **Luz radial "de mesa"** (vignette centrado, más claro en el centro, oscurece hacia el borde) como metáfora de foco/atención, reutilizable como principio de profundidad más allá del fieltro literal.

---

## A.8 Análisis de identidad (qué debería sentir el usuario)

Antes de proponer direcciones visuales, se tradujeron los adjetivos vacíos del brief ("moderno, premium, elegante") a comportamientos visuales concretos.

**Personalidad.** FLOPly es el compañero serio de estudio de un jugador que quiere dejar de improvisar. No es un profesor de escuela (Academia no es una enciclopedia) ni un casino (no vende adrenalina). Es más parecido a un mentor de club privado: exigente, cálido, sin condescendencia, sin lenguaje infantil.

**Tono.** Habla en cifras exactas, no en superlativos. Donde una app genérica diría "¡Excelente trabajo!" con confeti, FLOPly muestra el número real (frecuencia, EV, % de acierto) y deja que el número hable. El tono visual es afirmativo y calmado — nunca grita, nunca usa signos de exclamación visuales (glow excesivo, badges gigantes) para cosas rutinarias.

**Actitud.** La diferencia frente a una app educativa convencional es que FLOPly **no separa aprender de jugar**: la misma mesa que se usa para explicar un concepto es la mesa donde después se decide bajo presión. Una app educativa convencional ilustra con diagramas separados de la práctica; FLOPly señala directamente sobre el objeto real.

**Sensación por momento:**
- *Abrir la app:* llegar a un espacio propio, ya preparado — no una pantalla de carga con logo, sino un tablero de "dónde quedaste" inmediato (esto ya lo resuelve bien `ContinueLearningCard` hoy).
- *Estudiar:* concentración sin ruido — una sola cosa iluminada a la vez (el mismo principio que ya usa el glow de la mesa, generalizado).
- *Enfrentar una decisión:* tensión controlada — el pulso sube (motion más rápido, contraste más alto) pero el layout no cambia de estructura, para que la decisión se sienta seria sin sentirse caótica.
- *Equivocarse:* nunca vergüenza — el error se muestra como dato (qué frecuencia tenía la jugada correcta), no como fracaso (nada de "✗ MAL", tratamiento ya alineado con el `FeedbackPanel` actual, que hay que preservar y extender).
- *Acertar:* confirmación seca y precisa, no celebración ruidosa — un check y el número, no una animación de fuegos artificiales.
- *Progresar:* sensación de acumulación real (algo que se puede releer/repasar), no de "barra que sube" abstracta.
- *Usar una herramienta:* sensación de precisión instrumental — como tomar una herramienta de un cajón bien organizado, usarla y devolverla, no "abrir una app nueva".

**Metáfora central.** *El cuarto de preparación antes de sentarse a la mesa* — en inglés, el "green room": el espacio (real, en teatro y en salas de póker) donde uno se prepara, repasa, y afina antes de la actuación/partida real. Une aprendizaje (ahí se estudia), póker (ahí se guardan los materiales de la mesa: fieltro, cartas, fichas), decisión (ahí se ensaya bajo presión antes de la mesa real) y progreso (uno vuelve al mismo cuarto, cada vez mejor preparado). No es "casino" — es el backstage serio de un jugador, no el salón de neón.

---

## B. Direcciones visuales exploradas

Se exploraron 5 direcciones deliberadamente distintas — no cinco variaciones de "dark poker app". Cada una fue evaluada contra el mismo objetivo (aprendizaje + dominio + precisión + concentración + progreso + poker) desde un ángulo diferente.

### B.1 — Sala Verde *(elegida — ver sección C)*

**Concepto:** el "green room" de un jugador serio — el cuarto de preparación antes de sentarse a la mesa real. Materialidad física (madera, fieltro, marfil, latón/oro, cuero) extendida desde `PokerTableView` a todo el producto, en vez de quedar aislada en la mesa.

**Personalidad:** cálida, seria, artesanal, de club privado — no de casino de neón ni de dashboard SaaS.

**Referencias visuales (inspiración, no copia):** salas de estudio de ajedrez de alto nivel, cuadernos de anotación de jugadores profesionales, encuadernación de libros técnicos, instrumentos de precisión con acabado en latón, mesas de trabajo de relojero.

**Paleta conceptual:** grafito cálido casi negro como base (no azul-negro tipo SaaS), fieltro verde profundo como superficie "activa", marfil/crema como superficie de lectura, latón/oro como metal de acento único (reemplaza al violeta como "color de marca"), acero azulado frío reservado para tensión/decisión (Laboratorio).

**Tipografía conceptual:** una familia con carácter editorial para títulos (no geométrica genérica) + una familia tabular/monoespaciada dedicada a números.

**Formas:** esquinas suavizadas pero no "pill" en todo — rectángulos con corte sutil en vez de radios grandes uniformes; los radios grandes se reservan para elementos "tocables" (botones, chips).

**Superficies:** capas con nombre material (papel/fieltro/madera/metal), no "surface/surfaceElevated" genéricos.

**Profundidad:** sombras de contacto (objeto que se apoya) en vez de blur/glow decorativo; el vignette radial de la mesa se generaliza como principio de foco.

**Iconografía:** trazo fino, geometría con esquinas ligeramente cortadas (no completamente redondeadas ni completamente rectas) para evocar objetos tallados/grabados.

**Motion:** decidido y físico — llega y se asienta (ease-out con pequeño overshoot), nunca rebota infantil.

**Cómo funciona en mobile:** superficies materiales se aplanan visualmente a poca distancia (menos gradiente, más color plano + un solo highlight) para no saturar pantallas chicas; jerarquía por tipografía prioritaria sobre jerarquía por caja.

**Ventajas:** parte de algo que ya existe y funciona (la mesa); une "aprender" y "jugar" bajo una sola metáfora coherente (preparación → mesa); es difícil de confundir con otra app.

**Riesgos:** exige disciplina para no caer en "casino" si se abusa del dorado; requiere trabajo de sistematización (hoy la materialidad vive solo en 6 archivos).

**Qué potenciaría:** Academia (ya tiene la base), la mesa, Bankroll (el oro ya es su acento, ahora con lógica).

**Qué podría perjudicar:** Tools, si no se le da su propia variante "instrumento" dentro del mismo lenguaje (ver Fase 8).

---

### B.2 — Instrumento de Precisión

**Concepto:** FLOPly como panel de instrumentos de una cabina — el usuario "opera" el póker con la misma exactitud con que un piloto lee un altímetro.

**Personalidad:** fría, técnica, quirúrgica, orientada a datos.

**Referencias:** paneles de instrumentos de aviación, terminales de trading profesional, interfaces de control industrial — inspiración de *estructura* (retículas, hairlines, números grandes), nunca de marca.

**Paleta conceptual:** grafito oscuro neutro, retícula de líneas finas casi invisibles, un único color de acento tipo ámbar de instrumento o cian de radar, verde/rojo reservados estrictamente para estados (correcto/incorrecto), sin colores "de marca por sección".

**Tipografía:** monoespaciada como protagonista en todos lados (no solo en números), muy condensada, todo en mayúsculas para labels.

**Formas:** casi sin radio (esquinas rectas o de 2-4px), divisores en vez de cajas.

**Superficies:** planas, sin gradiente; la jerarquía la da el grosor de línea y el espaciado.

**Profundidad:** casi nula — todo vive en el mismo plano, la separación es por línea, no por sombra.

**Iconografía:** pictogramas técnicos, trazo muy fino, estilo "ISO".

**Motion:** instantáneo, sin easing orgánico — cambios de estado tipo "snap", como un instrumento que conmuta.

**Mobile:** exige pantallas grandes de texto pequeño; en mobile obliga a agrandar todo y pierde parte de su carácter "denso".

**Ventajas:** comunica precisión y dominio de forma inmediata; encaja perfecto con Laboratorio y Tools.

**Riesgos:** frío y poco motivador para la etapa de *aprender* (Academia); puede sentirse intimidante para un principiante; la ausencia de calidez puede leerse como "app de trader", no de póker.

**Qué potenciaría:** Laboratorio, Tools, Coach (si es analítico).

**Qué perjudicaría:** Academia (aprender se sentiría como operar una consola, no como progresar) y Bankroll.

---

### B.3 — Mentor Editorial

**Concepto:** FLOPly como un curso magistral bellamente editado — la sensación de un libro de texto de altísima calidad de producción, no de una app.

**Personalidad:** calmada, con autoridad, generosa en espacio en blanco (o "espacio en negro", en modo oscuro).

**Referencias:** tipografía editorial de manuales técnicos de ajedrez/bridge de alta gama, portadas de cursos "masterclass", diagramación de revistas de estrategia.

**Paleta conceptual:** fondo oscuro neutro muy contenido, un solo acento tenue, texto tratado casi como tinta sobre papel (paneles de lectura en tono crema/hueso incluso en modo oscuro, para las zonas de teoría).

**Tipografía:** una serif o slab con carácter para títulos y momentos de enseñanza, sans para UI/controles — jerarquía tipográfica fuerte en vez de color.

**Formas:** rectángulos limpios, radios mínimos, reglas y filetes en vez de cajas con relleno.

**Superficies:** casi sin "cards"; el contenido respira con márgenes, no con contenedores.

**Profundidad:** casi ninguna — todo plano, la jerarquía es tipográfica.

**Iconografía:** mínima, casi ausente; se prioriza el texto y las cifras.

**Motion:** lento, cadencioso, como pasar una página.

**Mobile:** exige mucha disciplina de longitud de texto; en pantallas chicas la ausencia de contenedores puede hacer perder la orientación si no se cuida el ritmo vertical.

**Ventajas:** comunica "dominio del conocimiento" mejor que cualquier otra dirección; distintivo frente a cualquier competidor de póker.

**Riesgos:** la mesa de póker (con toda su materialidad y color) puede sentirse "pegada" en vez de integrada si el resto del sistema es tan austero; Laboratorio pierde la tensión/urgencia que necesita.

**Qué potenciaría:** teoría escrita de Academia, Bankroll.

**Qué perjudicaría:** Laboratorio (falta de tensión), y exige rediseñar la relación mesa↔chrome desde cero.

---

### B.4 — Mesa Moderna (evolución conservadora)

**Concepto:** tomar el sistema actual (violeta/verde/oscuro) tal cual y simplemente sistematizarlo — spacing, radios y duraciones consistentes, sin cambiar la paleta ni la metáfora.

**Personalidad:** la misma de hoy, pulida.

**Referencias:** el propio FLOPly actual.

**Paleta conceptual:** la actual `AppColors`, sin cambios de fondo.

**Tipografía:** fuente del sistema actual, con una escala formalizada.

**Formas:** se elige una escala de radios (p. ej. 8/12/16/24) y se aplica de forma consistente sobre las mismas formas que hoy existen.

**Superficies:** mismas cards translúcidas con borde de hoy, ahora consistentes.

**Profundidad:** mismo uso ocasional de sombra de hoy, formalizado.

**Iconografía:** la misma familia Material `_rounded` ya en uso.

**Motion:** se unifican los ~15 valores de duración de hoy en 3-4 buckets.

**Mobile:** sin cambios de estrategia — ya funciona en mobile hoy.

**Ventajas:** menor riesgo de ejecución, cero curva de reaprendizaje para el equipo, mejora medible de consistencia con esfuerzo bajo.

**Riesgos:** **no resuelve el problema central** — el producto seguiría pareciendo "una app oscura más" salvo por la mesa; es la opción que menos cumple el objetivo del brief ("no debe sentirse como... una dashboard SaaS... Material 3 sin personalidad").

**Qué potenciaría:** velocidad de implementación a corto plazo.

**Qué perjudicaría:** la diferenciación de marca a mediano plazo — es la ruta que más se parece a quedarse con el problema diagnosticado en la Fase 1.

Se incluye como línea base de comparación, no como candidata real: sirve para medir cuánto valor agregan las otras direcciones por sobre "no hacer nada radical".

---

### B.5 — Cuaderno del Analista

**Concepto:** FLOPly como la libreta de un analista de solvers — terminal de datos, monoespaciado, denso, con micro-visualizaciones (sparklines, barras) en todos lados.

**Personalidad:** cuantitativa, moderna, "quant poker".

**Referencias:** terminales financieras, notebooks de análisis de datos, dashboards de solvers GTO (inspiración estructural, no de marca).

**Paleta conceptual:** grafito frío, azul-cian como acento único de dato, verde/rojo estrictamente para positivo/negativo (EV+, EV-), sin violeta.

**Tipografía:** monoespaciada en todos los números y en buena parte de la UI, sans neutra para prosa.

**Formas:** rectángulos, radios muy chicos, tablas y grillas como elemento central de layout.

**Superficies:** planas con divisores; uso de mini-gráficos (sparkline, barra horizontal) como decoración funcional en cards de resultado.

**Profundidad:** mínima, basada en contraste de grises, no en sombra.

**Iconografía:** casi inexistente; se reemplaza por tipografía y números.

**Motion:** rápido, funcional, sin adornos.

**Mobile:** la densidad de datos es un riesgo real en pantallas chicas; exige mucho trabajo de simplificación específico para mobile.

**Ventajas:** encaja perfecto con Tools y con el Laboratorio "avanzado"; conecta bien con jugadores que ya usan solvers.

**Riesgos:** intimidante para el alumno de Academia; no tiene ninguna calidez ni conexión emocional con "aprender"; se parece bastante a un dashboard SaaS de analytics (justo lo que el brief pide evitar).

**Qué potenciaría:** Tools, feedback avanzado de Laboratorio.

**Qué perjudicaría:** Academia, Bankroll, la sensación general de "premium" (se siente más "utilitario" que "premium").

---

## C. Dirección elegida: Sala Verde

### C.1 Por qué esta y no otra

La pregunta de oro del brief es: *¿qué hace que FLOPly sea visualmente FLOPly?* Sala Verde es la única dirección de las cinco cuya respuesta no depende de un color: depende de una **relación entre materiales** (fieltro, madera, marfil, latón, papel) que ya existe, probada y bien ejecutada, en un rincón del producto (`PokerTableView`), y que hoy simplemente no se dejó salir de ahí. Elegirla no es "porque se ve bonita" — es la única opción que resuelve directamente el hallazgo más importante de la auditoría (A.3/A.4): que el 90% del producto usa un lenguaje genérico de SaaS oscuro mientras el 10% restante (la mesa) tiene una voz real.

Instrumento de Precisión y Cuaderno del Analista son fuertes para Laboratorio/Tools pero matan la calidez que Academia necesita para "sentirse como un mentor, no una enciclopedia" (contexto del producto). Mentor Editorial tiene la autoridad correcta para enseñar pero no resuelve cómo convive con una mesa de póker llena de color y materialidad — la dejaría aislada otra vez. Mesa Moderna es la ruta de menor esfuerzo pero, por definición, no cambia el diagnóstico.

### C.2 Evaluación contra los 11 criterios de la Fase 4

| # | Criterio | Evaluación |
|---|---|---|
| 1 | Reconocimiento de marca | Alto. Ninguna otra app de póker o edtech usa madera/fieltro/marfil/latón como sistema completo (hoy en el mercado esto vive solo, de forma literal, en la mesa de juego, nunca en el chrome de la app). |
| 2 | Legibilidad | Alta si el marfil/crema se reserva para paneles de lectura de teoría (mejor contraste que texto gris sobre violeta oscuro) y el grafito se mantiene neutro (no azul-negro saturado que compite con el texto). |
| 3 | Aprendizaje | Alta — la metáfora "cuarto de preparación → mesa" mapea 1:1 con el flujo real de Academia (aprender → practicar). |
| 4 | Concentración | Alta — paleta cálida y de baja saturación de fondo reduce fatiga visual frente al violeta/verde neón actual, que compite por atención constantemente. |
| 5 | Escalabilidad (cientos de pantallas) | Alta — al basarse en *materiales con reglas* (no en decisiones caso por caso) es más fácil de aplicar consistentemente a 326 teorías y 47+ ejercicios que un sistema de "cada componente inventa su color". |
| 6 | Diferenciación | Muy alta — ninguna de las categorías que el brief pide evitar (casino, SaaS, edtech genérica, Material 3) usa esta combinación de materiales. |
| 7 | Mobile UX | Alta — el sistema se apoya en tipografía/jerarquía antes que en decoración, que es justamente lo que sobrevive mejor a pantallas chicas. |
| 8 | Poker | Máxima — nace directamente de los materiales reales de una mesa de póker física, sin caer en iconografía de casino (fichas de neón, cartas brillantes, luces de Vegas). |
| 9 | Sensación premium | Alta — madera/latón/marfil son materiales asociados a objetos de calidad (relojes, mesas de juego de club privado), no a "gratis"/"casual". |
| 10 | Capacidad de soportar cientos de pantallas/ejercicios | Alta — ver punto 5; además reduce la necesidad de una "card con borde de acento" por cada callout, porque la jerarquía ahora también vive en la tipografía numérica y en el color de superficie material. |
| 11 | Coherencia entre Academia/Laboratorio/Tools | Alta — un único sistema de materiales con variantes de temperatura (cálido=aprender, frío=decidir, metálico=herramienta) permite diferenciar sin fragmentar (ver matriz de la Fase 8 en `FLOPLY_UX_PATTERNS.md`). |

### C.3 Qué NO cambia con esta elección

- No se toca el renderer de `PokerTableView` en esta fase (sigue fuera de alcance); Sala Verde **documenta su lenguaje como fuente de verdad** para extenderlo después, no lo reemplaza.
- No se elimina el violeta ni el verde neón de un plumazo — se redefine su rol dentro del nuevo sistema (ver `FLOPLY_DESIGN_LANGUAGE.md` §5.1, tabla de migración conceptual).
- Bankroll conserva el oro como acento — ahora con una razón sistémica (metal = valor) en vez de ser una elección aislada.

---

---

## D. Addendum — Fase 0.5: crítica independiente y ajustes

Antes de implementar, se sometió "Sala Verde" a una crítica adversarial deliberada (rol de Director de Diseño externo, sin defender la solución previa). Este addendum documenta el veredicto, los riesgos reales encontrados y los ajustes ya aplicados a los documentos hermanos. No se re-exploraron direcciones nuevas ni se tocó código.

### D.1 Veredicto conceptual

**¿"Sala Verde" es identidad propia o solo una extensión estética de `PokerTableView`?** Respuesta honesta: **tal como estaba redactada originalmente, corría un riesgo real de ser lo segundo.** El mecanismo que da identidad real (superficies con nombre, tipografía numérica, motion con dos familias, gradiente de temperatura por sección) es sólido y no depende de la mesa — pero la especificación original le daba a la materialidad literal (fieltro como fondo de pantalla en Laboratorio, latón sin límite de repetición) más superficie de la que su propio brief permite, acercándose exactamente a lo que el brief pidió evitar: "estética casino", "estética SaaS con piel de madera". El diagnóstico no invalida la dirección — la corrige. Con los ajustes de §D.3, la dirección pasa de "extensión estética de la mesa" a "sistema con mecanismo propio que además sabe citar a la mesa en los momentos correctos".

**Sobre representar Academia/Laboratorio/Tools/Coach/Bankroll:** el sistema alcanza cuando la materialidad se gradúa (§D.3, matriz D.5) — no alcanza si se aplica de forma pareja a las cinco áreas, porque entonces Tools y Bankroll (que deberían sentirse "de instrumento" y "de valor/ledger" respectivamente) terminan sintiéndose como salas de casino con distinto cartel.

### D.2 Riesgos encontrados (priorizados)

1. **Riesgo "casino premium" (crítico, corregido).** La combinación madera+fieltro+dorado, si se extiende sin límite fuera de la mesa (ej. `surfaceFelt` como fondo de pantalla completa en Laboratorio, `brass` repetido en múltiples superficies de una misma pantalla), pattern-matchea directamente con estética de casino/sportsbook — justo lo que el brief prohíbe explícitamente. *Corregido en `FLOPLY_DESIGN_LANGUAGE.md` (§5.1, nuevo principio "presupuesto de materialidad"), `FLOPLY_ANTI_GENERIC.md` (nueva sección "Materialidad") y `FLOPLY_UX_PATTERNS.md` (fila de Laboratorio).*
2. **Riesgo de skeuomorfismo dilatado (crítico, corregido).** Aplicar textura/gradiente/brillo especular fuera del renderer de la mesa reproduce, a nivel de sistema, el mismo error que la industria abandonó hace más de una década (iOS pre-7: cuero, papel, madera "de verdad" en el chrome) — se ve dated, no premium, y además compite con la legibilidad de 326 teorías leídas cientos de veces. *Corregido con el mismo set de ediciones que el punto 1, más el nuevo checklist de materialidad en `FLOPLY_DESIGN_QA.md`.*
3. **Riesgo pedagógico de fatiga visual (moderado, corregido).** Sin el "presupuesto de materialidad", una implementación bien intencionada podría decorar cada card de teoría con textura "para que se sienta FLOPly", cansando la lectura en un currículo de esta escala. *Corregido: `surfaceReading` se define explícitamente como plana.*
4. **Riesgo de sobre-fragmentación de componentes (menor, corregido).** `Badge`/`chip.status` y `callout.accent`/`Feedback Panel`/`Score-Progress` estaban documentados como si fueran componentes sin relación, cuando son la misma familia con variantes. *Corregido en `FLOPLY_COMPONENTS.md` con notas de consolidación explícitas.*
5. **Riesgo de identidad débil en zonas de baja densidad (menor, no bloqueante).** Home y las pantallas de listado (mapa de nivel, listado de Tools) son las que menos "material" tienen por diseño (baja densidad, sin mesa) — son las más expuestas al test de "quitar el logo" (§D.4). Se mitiga con la firma tipográfica numérica y el uso puntual (no ausente) de `brass`, pero requiere disciplina en implementación; se deja como punto de atención para el QA de esas pantallas específicas, no amerita un cambio de documento adicional en esta fase.

### D.3 Cambios realizados

```text
FLOPLY_DESIGN_LANGUAGE.md
→ §5.1 Color, tabla "Superficies base"
→ Se acota `surfaceFelt` a franja, se prohíbe como fondo de pantalla completa; se agrega principio "presupuesto de materialidad"
→ Motivo: riesgo de casino premium (D.2.1) y skeuomorfismo (D.2.2)

FLOPLY_DESIGN_LANGUAGE.md
→ §5.1 Color, tabla "Metal de acento"
→ `brass` limitado a un elemento de superficie por pantalla
→ Motivo: la repetición de dorado es la señal más asociada a "casino"/"lujo falso"

FLOPLY_DESIGN_LANGUAGE.md
→ §5.1 Color, "Comportamiento contextual"
→ Laboratorio ya no "predomina en surfaceFelt" — predomina en surface neutro + acento steelBlue, con fieltro acotado a la mesa embebida
→ Motivo: evitar que Laboratorio se lea como mesa de casino de punta a punta

FLOPLY_ANTI_GENERIC.md
→ Nueva sección "Materialidad" (reglas 0-0.4), antepuesta a "Superficies y cards"
→ Motivo: formalizar los límites de materialidad como regla dura, no como nota aislada en un solo documento

FLOPLY_DESIGN_QA.md
→ Nueva sección "Materialidad"
→ Motivo: dar a QA una herramienta explícita para detectar recaídas en casino/skeuomorfismo pantalla por pantalla

FLOPLY_UX_PATTERNS.md
→ Matriz de diferenciación, fila "Laboratorio"
→ Se corrige la descripción de superficie dominante
→ Motivo: coherencia con el cambio en FLOPLY_DESIGN_LANGUAGE.md

FLOPLY_COMPONENTS.md
→ Secciones "Badges", "Answer States / Feedback Panels", "Score / Progress"
→ Se agregan notas de consolidación explícitas (Status Indicator con 2 variantes; Feedback Panel = implementación de callout.accent; Score/Progress reclasificado como patrón de composición, no componente nuevo)
→ Motivo: reducir el conteo aparente de componentes y evitar duplicar sistemas que ya son la misma familia
```

### D.4 Test "quitar el logo" (resumen por pantalla)

| Pantalla | Sobrevive sin logo? | Por qué |
|---|---|---|
| Teoría (Academia) | Sí, alta confianza | `surfaceReading` marfil en una app de entrenamiento de póker oscura es una combinación que hoy no tiene competidores directos. |
| Ejercicio (Academia/Laboratorio) | Sí, alta confianza | Patrón "anotar sobre el objeto real" (mesa+burbuja) + tipografía numérica tabular. |
| Laboratorio (vista de decisión) | Sí, confianza media-alta tras el ajuste | Antes del ajuste corría el riesgo de leerse como "mesa de casino online cualquiera"; con fieltro acotado + acento frío `steelBlue` + densidad de datos, se diferencia. |
| Tools | Confianza media — el punto más débil | Una calculadora es, estructuralmente, parecida a cualquier calculadora. La firma que sobrevive es la tipografía numérica y el radio "sharp"/chaflán de íconos — deben aplicarse con disciplina o la pantalla cae en genérico. |
| Bankroll | Sí, alta confianza | Reutiliza el lenguaje de Academia (marfil+lectura) con `brass` como único acento de datos — coherente y distinguible. |
| Home | Confianza media | Es la pantalla de menor densidad material por diseño; se apoya en la tipografía y en el uso puntual de `brass` en el CTA de "continuar" — es la pantalla que más disciplina de implementación va a requerir para no sentirse "una dashboard más". |

### D.5 FLOPly Signature Elements (no dependen solo de color)

1. **Tipografía numérica tabular obligatoria** para todo BB/%/EV/frecuencia/saldo — la firma más reconocible del sistema, sobrevive incluso en escala de grises.
2. **Anotar sobre el objeto real, no al lado** (mesa+burbuja, extensible a grid de rangos en Tools) en vez de diagramas ilustrativos separados.
3. **Cambio de superficie como cambio de modo**: pasar a `surfaceReading` significa wordlessly "ahora estás leyendo", volver a `background`/`surfaceFelt` significa "ahora estás decidiendo".
4. **Metal de marca escaso y deliberado** (`brass`, máximo un uso de superficie por pantalla) — su rareza es la señal, no su presencia constante.
5. **Doctrina de error calmo**: mismo motion, mismo tono de superficie para acierto y error — ningún competidor de educación de póker trata el error con esta simetría.
6. **Temperatura de sección, no marca de sección**: Academia cálida / Laboratorio fría / Tools neutra, en vez de "un color por pestaña" arbitrario.
7. **Ausencia deliberada de gamificación aritmética** (sin XP, sin racha, sin confeti) — signature por sustracción, distintiva frente a casi todo el mercado edtech.
8. **Geometría chaflanada en íconos de marca** — un detalle de forma a la escala más pequeña posible del sistema.
9. **BB como única unidad monetaria simulada** — nunca "$", salvo Bankroll real.

### D.6 Retrospectiva de las 5 direcciones (con el sistema completo ya definido)

- **¿Sala Verde sigue siendo la correcta?** Sí, con la corrección de §D.3 — el mecanismo de identidad (superficies, tipografía numérica, motion, temperatura) no dependía en realidad de la materialidad literal; graduarla la fortalece en vez de debilitarla.
- **¿Combinación de dos direcciones superior?** No se encontró una combinación que reemplace a Sala Verde como columna vertebral — pero sí se incorporan principios puntuales de otras dos (ver abajo), sin diluir la dirección principal (no es un Frankenstein: ambos préstamos se expresan a través de los mismos tokens ya definidos, no agregan tokens nuevos).
- **De Instrumento de Precisión:** se adopta la disciplina de separadores/hairlines por sobre cajas, y el criterio de "snap"/inmediatez para Tools y para los datos densos de Laboratorio — ya reflejado en `radius.sharp` y en la familia de motion "Responder".
- **De Mentor Editorial:** se adopta la restricción de que las superficies de lectura (`surfaceReading`) permanezcan sobrias y tipográficamente jerarquizadas, sin decoración — reforzado ahora por el "presupuesto de materialidad" (§D.2.3).
- **De Cuaderno del Analista:** se adopta, solo para Tools y para el desglose avanzado de feedback de Laboratorio, el criterio de "el dato es la decoración" (layouts numéricos densos en vez de ícono+card) — no se adopta su frialdad total, que perjudicaría a Academia/Bankroll.

### D.7 Core vs. expresión por área

| Elemento | Core FLOPly (inmutable) | Academia | Laboratorio | Tools | Coach | Bankroll |
|---|---|---|---|---|---|---|
| Typography | Misma familia display/UI/numérica y misma escala en las 5 áreas | Display presente en títulos de teoría | Numérica más presente que display (datos densos) | Numérica protagonista, casi sin display | Tono conversacional, body-forward | Numérica + display, similar a Academia |
| Color (mecanismo) | Fondo grafito común + `brass` como único metal de marca transversal | Acento `feltGreen` | Acento `steelBlue` | Acento `graphiteSteel` | `brass` como "voz del mentor" | `brass` como acento de valor |
| Materiality | Mecanismo de profundidad (sombra de contacto, 2 niveles) + "presupuesto de materialidad" — inmutables; la textura literal es casi exclusiva de la mesa | Media — `surfaceReading` plana, sin textura | Media-baja — franja de fieltro acotada, resto neutro/instrumento | Baja — sin fieltro/madera, todo plano | Baja-media — burbuja con borde `brass`, sin superficie material propia | Media — `brass` como metal plano, sin brillo especular |
| Density | La escala de `space.*`/`radius.*` es la misma — solo cambia cuánto contenido se agrupa | Baja-media | Alta | Media-alta | Baja | Baja-media |
| Motion | Las 2 familias (asentarse/responder) y sus duraciones — inmutables | Ritmo pausado (`reveal` 320ms domina) | Ritmo rápido (`instant`/`quick` dominan) | Instantáneo/funcional | Pausado, con la entrada de burbuja ya validada | Pausado, igual que Academia |
| Surface | El vocabulario `background/base/elevated/reading/felt` existe igual en las 5 — inmutable | Domina `reading` | Domina `base` + franja acotada de `felt` | Domina `base`/`elevated`, sin `reading` ni `felt` | Domina `base` + burbuja | Domina `reading` |
| Accent | El mecanismo (1 acento de sección + `brass` transversal, con el límite de escasez de §D.3) — inmutable | `feltGreen` | `steelBlue` | `graphiteSteel` | `brass` | `brass` |

### D.8 Estado final

**B — Bueno pero necesita ajustes** (ya aplicados en esta misma fase). La dirección "Sala Verde" y su mecanismo de identidad (superficies con nombre, tipografía numérica, motion de dos familias, temperatura por sección) son correctos y no requieren re-exploración — el problema real detectado era de **grado de materialidad**, no de dirección, y ya quedó corregido mediante ediciones documentales puntuales (§D.3). No se encontraron problemas estructurales que ameriten un replanteamiento (opción C).

### D.9 Próxima fase

Sin cambios respecto a lo ya señalado en la sección L original: definir familias tipográficas candidatas con licencia real, migrar `AppColors`/`AppTheme` al árbol de tokens, crear `AppSpacing`/`AppRadius`/`AppMotion`, y decidir la relación entre `TableMaterial` y el nuevo sistema — ahora con la restricción adicional, ya documentada, de que ningún efecto de textura/vignette/brillo de `TableMaterial` se copia fuera del renderer de la mesa. Ninguna de estas tareas se comenzó en esta fase.

---

## Documentos relacionados

- `FLOPLY_DESIGN_LANGUAGE.md` — color, tipografía, spacing, forma, profundidad, iconografía y motion (especificación completa).
- `FLOPLY_DESIGN_TOKENS.md` — estructura conceptual de tokens.
- `FLOPLY_COMPONENTS.md` — componentes fundamentales.
- `FLOPLY_UX_PATTERNS.md` — patrones de interacción propios + matriz de diferenciación por área.
- `FLOPLY_MOTION.md` — lenguaje de movimiento en detalle.
- `FLOPLY_ANTI_GENERIC.md` — reglas anti-genéricas.
- `FLOPLY_DESIGN_QA.md` — checklist de auditoría de pantallas futuras.
