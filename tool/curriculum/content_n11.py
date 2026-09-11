# -*- coding: utf-8 -*-
"""
PASO 4 — Contenido redactado del NIVEL 11: "Conceptos estratégicos".
15 teorías, 6 subniveles. Banda AVANZADO, estadio EXPLICAR en todo el
nivel. Voz: profesor de póker rioplatense.

Fuente de verdad: curriculum_spec.json.

Meta de N11: nombrar formalmente un puñado de ideas estratégicas que
venían apareciendo de forma intuitiva en niveles anteriores — ventaja de
rango/nuts, realización de equity, profundidad de stack, polarización
(uso estratégico), bloqueadores, MDF, GTO vs explotación — y dejar al
alumno pensando en decisiones como frecuencias, no como blanco o negro.

Vocabulario nuevo de N11: ventaja de rango, ventaja de nuts, realización
de equity, ventaja posicional (estratégica), profundidad de stack, SPR
(uso estratégico), condensación de rango, bloqueadores (blockers),
remoción de combos, relación farol/valor, MDF (frecuencia mínima de
defensa), GTO, explotar.

NO se enseña todavía: el checklist de integración (N12) ni las manos
completas de NL2 (N13) — acá se nombran los conceptos, la integración
práctica llega después.
"""

N11 = {

# ============================================================
# 11.1 — Ventajas
# ============================================================

"T224": dict(  # Ventaja de rango
 que_es="Tener ventaja de rango es que TODO tu rango, en promedio, esté "
        "mejor parado que todo el rango del rival en un board concreto "
        "— no una mano puntual, el conjunto completo.",
 por_que_importa="Ya usaste esta idea de forma intuitiva al estudiar "
        "por qué funciona la c-bet (N8, T176): 'tu rango en promedio "
        "suele estar mejor parado'. Acá le ponés nombre.",
 como_funciona="Comparás los dos rangos completos (rango contra rango, "
        "N6, T135) sobre ese board puntual: si el tuyo gana más seguido "
        "en promedio, tenés ventaja de rango ahí.",
 cuando_lo_uso="Al decidir cuánto podés presionar en un board "
        "determinado, más allá de tu mano puntual.",
 cuando_no=None,
 ejemplo="Sos el agresor preflop en un board con cartas altas: tu "
        "rango de apertura, en conjunto, suele tener más manos altas "
        "que el rango de defensa del rival — ventaja de rango en ese "
        "tipo de board.",
 error_comun="Confundir ventaja de rango con 'tengo la mejor mano': es "
        "una propiedad del CONJUNTO completo, no de tu mano puntual.",
 idea_clave="Ventaja de rango = tu rango completo, en promedio, gana "
        "más seguido que el del rival en ese board.",
),

"T225": dict(  # Ventaja de nuts
 que_es="Tener ventaja de nuts es tener más combinaciones de las "
        "manos MÁS fuertes posibles (o su potencial) que el rival en "
        "ese board — un caso más específico que la ventaja de rango.",
 por_que_importa="Podés tener ventaja de rango sin tener ventaja de "
        "nuts, o al revés. Distinguirlas te dice qué tipo de apuestas "
        "podés hacer con confianza: la ventaja de nuts es lo que te "
        "permite apostar grande sin miedo a que te resuban con algo "
        "mejor.",
 como_funciona="Contás, en cada rango, cuántos combos llegan a la "
        "combinación más fuerte posible en ese board (o tienen chance "
        "real de llegar). El que tenga más, tiene ventaja de nuts.",
 cuando_lo_uso="Al decidir si conviene apostar tamaños grandes: la "
        "ventaja de nuts es lo que sostiene una apuesta grande sin "
        "miedo.",
 cuando_no=None,
 ejemplo="En un board con proyecto de color visible, el jugador que "
        "3-beteó preflop suele tener más combos de esa color específico "
        "(por las manos que entran en un rango de 3-bet) que el que "
        "solo defendió — ventaja de nuts en ese board.",
 error_comun="Asumir que ventaja de rango y ventaja de nuts son lo "
        "mismo. Se puede tener una sin la otra.",
 idea_clave="Ventaja de nuts = tenés más combos de lo MÁS fuerte "
        "posible, específicamente, no solo 'en promedio mejor parado'.",
),

"TN15": dict(  # La realización de equity
 que_es="La realización de equity es cuánto de tu equity 'cruda' "
        "(N6) terminás cobrando de verdad — porque no siempre se "
        "cobra toda: la posición, las decisiones futuras y la habilidad "
        "influyen.",
 por_que_importa="Dos manos con la misma equity en el papel no ganan "
        "siempre lo mismo en la práctica: la que juega en posición, con "
        "más información en cada calle, suele cobrar una porción más "
        "grande de esa equity.",
 como_funciona="Tu equity cruda es un número fijo en el momento del "
        "flop. Lo que pasa después — cómo jugás las calles siguientes, "
        "si estás en posición o no — determina si terminás cobrando "
        "toda esa equity, una parte, o incluso más (si además ganás "
        "fichas extra con faroles bien elegidos).",
 cuando_lo_uso="Para entender por qué la posición (N3) vale tanto más "
        "allá de la equity cruda de tu mano.",
 cuando_no=None,
 ejemplo="Dos jugadores con la misma equity cruda en un flop: el que "
        "juega en posición, viendo la reacción del rival en cada calle, "
        "suele terminar cobrando una porción mayor de esa equity que el "
        "que juega a ciegas.",
 error_comun="Pensar que la equity cruda del flop ya define cuánto vas "
        "a ganar, sin considerar cuánto de esa equity realmente vas a "
        "poder cobrar.",
 idea_clave="Realización de equity = cuánto de tu equity cruda "
        "terminás cobrando de verdad. La posición ayuda a realizarla "
        "más.",
),

"T226": dict(  # Ventaja posicional (estratégica)
 que_es="La ventaja posicional estratégica es, específicamente, cuánto "
        "mejora la posición tu realización de equity (TN15) — el "
        "nombre formal para 'la posición vale más de lo que parece'.",
 por_que_importa="Junta todo lo que veníamos viendo de la posición "
        "desde N3: no es solo 'ver la reacción del rival antes', es que "
        "esa información extra te permite cobrar una porción mayor de "
        "tu equity en cada mano.",
 como_funciona="Al estar en posición, tenés más chances de: pot control "
        "con manos medias (N9), farolear con más criterio (viendo "
        "debilidad primero), y evitar decisiones difíciles a ciegas.",
 cuando_lo_uso="Como resumen estratégico de por qué jugar en posición "
        "es, en conjunto, más rentable que jugar fuera de ella con la "
        "misma mano.",
 cuando_no=None,
 ejemplo="Con la misma mano y la misma equity cruda, jugarla desde el "
        "botón (en posición todo el resto de la mano) suele terminar "
        "ganando más fichas en promedio que jugarla desde la ciega "
        "grande.",
 error_comun="Ver la ventaja posicional como algo abstracto, en vez de "
        "reconocerla como la consecuencia directa de realizar mejor tu "
        "equity.",
 idea_clave="Ventaja posicional (estratégica) = la posición mejora "
        "cuánta de tu equity terminás cobrando de verdad.",
),

# ============================================================
# 11.2 — Stacks y SPR
# ============================================================

"T228": dict(  # La profundidad de stack
 que_es="La profundidad de stack (medida en BB) cambia qué manos son "
        "más o menos jugables: con stacks profundos, algunas manos "
        "ganan valor; con stacks cortos, otras.",
 por_que_importa="Las mismas dos cartas no valen igual con 40 BB que "
        "con 200 BB: cuánto stack hay detrás cambia cuánto podés ganar "
        "(o perder) si tu mano se desarrolla bien.",
 como_funciona="Con stacks profundos, manos especulativas (conectores "
        "suited, parejas chicas) ganan valor: si conectan fuerte, hay "
        "mucho stack detrás para ganar con implied odds (N6, TN10). Con "
        "stacks cortos, ese potencial vale menos, y pesan más las manos "
        "con fuerza inmediata.",
 cuando_lo_uso="Al evaluar qué tan jugable es una mano especulativa, "
        "según cuánto stack tenés (y tiene el rival) detrás.",
 cuando_no=None,
 ejemplo="Una pareja de dos, floja de entrada, gana mucho más valor "
        "con 200 BB de profundidad (si liga trío, hay mucho para ganar) "
        "que con 25 BB, donde ese potencial extra vale bastante menos.",
 error_comun="Evaluar una mano especulativa igual sin importar la "
        "profundidad de stack, ignorando que su valor depende "
        "directamente de eso.",
 idea_clave="Stacks profundos favorecen manos especulativas con "
        "potencial; stacks cortos favorecen la fuerza inmediata.",
),

"T229": dict(  # El SPR (uso estratégico)
 que_es="Usar el SPR (N7, T166) para decidir si tu mano quiere jugarse "
        "por todo el stack o no: con SPR bajo, hace falta menos fuerza "
        "para comprometerte; con SPR alto, hace falta más.",
 por_que_importa="Ya sabés calcular el SPR (stack ÷ bote); ahora lo "
        "usás para tomar una decisión concreta: ¿esta mano, en este "
        "SPR, quiere ir por todo el stack?",
 como_funciona="Con SPR bajo (poco stack en relación al bote), incluso "
        "una mano 'buena pero no la mejor posible' (como top pair) "
        "puede ir por todo el stack, porque queda poco margen para "
        "protegerse. Con SPR alto, hace falta una mano mucho más fuerte "
        "para sentirte cómodo jugándote todo.",
 cuando_lo_uso="Al decidir si tu mano actual quiere comprometer todo el "
        "stack en esa situación puntual.",
 cuando_no=None,
 ejemplo="Con un SPR de 1 (poco stack respecto al bote), una pareja "
        "alta hecha puede ir cómoda por todo el stack. Con un SPR de "
        "15, esa misma pareja alta ya no alcanza para eso: hace falta "
        "mucho más.",
 error_comun="Jugarte todo el stack con la misma mano sin importar el "
        "SPR — lo que alcanza con SPR bajo puede no alcanzar con SPR "
        "alto.",
 idea_clave="SPR bajo = manos buenas alcanzan para ir por todo. SPR "
        "alto = hace falta mucho más.",
),

# ============================================================
# 11.3 — Polarización y estructura de rango
# ============================================================

"T230": dict(  # Polarización (uso estratégico)
 que_es="Decidir, a propósito, cuándo conviene polarizar tu propio "
        "rango de apuesta (N9, T206): combinar valor muy fuerte y "
        "faroles, dejando afuera las manos medias.",
 por_que_importa="Ya sabés qué es un rango polarizado; acá lo elegís "
        "como estrategia: es la forma correcta de apostar tamaños "
        "grandes, porque combina 'gano mucho si me pagan' con 'gano por "
        "fold equity si se retiran'.",
 como_funciona="Con tamaños de apuesta grandes, conviene polarizar: "
        "metés tus mejores manos (que quieren pago) y tus mejores "
        "faroles (que quieren que se retiren), dejando las manos medias "
        "para tamaños más chicos o directamente para pasar.",
 cuando_lo_uso="Al elegir un tamaño de apuesta grande, pensando en qué "
        "tipo de rango lo sostiene.",
 cuando_no=None,
 ejemplo="Con una apuesta del tamaño del bote o más grande en el río, "
        "conviene que tu rango ahí sea polarizado: tus mejores manos y "
        "tus mejores faroles, no manos medias que ni cobran valor fino "
        "ni sirven de farol.",
 error_comun="Apostar tamaños grandes con un rango que incluye muchas "
        "manos medias, que no se benefician ni del valor ni del farol.",
 idea_clave="Polarizar a propósito = reservar los tamaños grandes para "
        "tu mejor valor y tus mejores faroles.",
),

"T231": dict(  # Condensación de rango
 que_es="Un rango condensado (lo opuesto a polarizado) está compuesto "
        "sobre todo por manos medias — sin extremos marcados de muy "
        "fuerte o muy flojo.",
 por_que_importa="No todo momento de la mano pide un rango polarizado: "
        "a veces, por cómo se jugó la mano hasta ahí, lo que te queda "
        "es naturalmente un montón de manos parecidas entre sí.",
 como_funciona="Pensá en el pot control (N9, T195): cuando pasás tus "
        "manos más fuertes y también tus manos más flojas, lo que te "
        "queda apostando (o pagando) son mayormente manos medias — un "
        "rango condensado.",
 cuando_lo_uso="Al reconocer situaciones donde tu rango (o el del "
        "rival) quedó compuesto mayormente por manos parecidas, sin "
        "extremos.",
 cuando_no=None,
 ejemplo="Después de que ambos pasaron el turn con manos medias, el "
        "rango que llega al río de los dos lados suele estar "
        "condensado: ni manos muy fuertes ni faroles evidentes, "
        "mayormente fuerza media.",
 error_comun="Tratar un rango condensado como si fuera polarizado, "
        "esperando encontrar los mismos extremos de valor y farol.",
 idea_clave="Condensado = mayormente manos medias, sin los extremos "
        "marcados de un rango polarizado.",
),

# ============================================================
# 11.4 — Bloqueadores
# ============================================================

"T232": dict(  # Bloqueadores (blockers)
 que_es="Un bloqueador (blocker) es una carta en tu propia mano que "
        "reduce la cantidad de combos que el rival puede tener de una "
        "mano concreta — porque esa carta ya está en tu mano, no en el "
        "mazo.",
 por_que_importa="Ya usaste esta idea sin nombrarla (N7, T174: 'una "
        "carta que el rival necesitaría para sus manos más fuertes'). "
        "Acá le ponés el término formal y lo aplicás con más precisión.",
 como_funciona="Si tenés un As en la mano, hay un As menos disponible "
        "para que el rival tenga AA, AK, AQ, etc. — cada combo que "
        "necesita esa carta se vuelve menos probable.",
 cuando_lo_uso="Al elegir con qué mano farolear o al leer qué tan "
        "probable es que el rival tenga cierta mano, considerando qué "
        "cartas tenés vos.",
 cuando_no=None,
 ejemplo="Farolear con A♠5♦ en vez de con 6♠5♦ es mejor bloqueador "
        "para las manos de valor del rival que incluyen un As (como AK "
        "o AA), aunque ambas manos sean parecidas de fuerza para vos.",
 error_comun="Elegir la mano para farolear solo por su potencial "
        "propio, sin considerar si además bloquea las manos de valor "
        "del rival.",
 idea_clave="Bloqueador = una carta tuya que reduce los combos "
        "posibles de una mano del rival.",
),

"T233": dict(  # El efecto de remover combos (removal)
 que_es="El efecto de remoción (removal) es cómo cambia la probabilidad "
        "de cada mano del rival cuando 'sacás' del cálculo los combos "
        "que usan las cartas que vos ya tenés.",
 por_que_importa="Conecta el conteo de combos (N5, T133; N10, T219) "
        "con los bloqueadores (T232): no solo importa cuántos combos "
        "hay en total, importa cuántos siguen siendo POSIBLES dado lo "
        "que vos ya tenés en la mano.",
 como_funciona="Contás los combos de una mano como siempre, pero "
        "restás los que usan cartas que ya están en tu mano — esos "
        "combos, literalmente, no pueden existir en la mano del rival.",
 cuando_lo_uso="Al contar combos con precisión (N10, T219), teniendo en "
        "cuenta tus propias cartas.",
 cuando_no=None,
 ejemplo="Si tenés A♠A♦, ya no quedan combos de AA disponibles para el "
        "rival (los 6 combos totales de AA ya están completos en tu "
        "propia mano) — quedan 0, no 6.",
 error_comun="Contar combos del rival sin restar los que ya usan "
        "cartas que vos tenés en tu propia mano.",
 idea_clave="Remoción = restar del conteo de combos los que ya usan "
        "cartas que vos tenés en la mano.",
),

# ============================================================
# 11.5 — Frecuencias y equilibrio
# ============================================================

"T235": dict(  # La relación farol/valor
 que_es="La relación farol/valor es la proporción entre manos de valor "
        "y faroles en tu rango de apuesta, elegida para que el rival no "
        "pueda explotarte sin importar qué haga.",
 por_que_importa="Si apostás solo con valor, un rival atento deja de "
        "pagarte; si apostás con demasiado farol, un rival atento te "
        "paga siempre. Hay una proporción intermedia que hace tu "
        "apuesta difícil de explotar en cualquiera de los dos sentidos.",
 como_funciona="Cuanto más grande el tamaño de tu apuesta, más faroles "
        "podés incluir en tu rango de apuesta (relativo al valor) sin "
        "volverte explotable — porque el rival necesita ganar una "
        "porción mayor de las veces para que pagarte sea rentable.",
 cuando_lo_uso="Al pensar en la composición de tu rango de apuesta "
        "(T207, T208), no solo en manos individuales sueltas.",
 cuando_no=None,
 ejemplo="Con una apuesta del tamaño del bote, la relación farol/valor "
        "que te hace difícil de explotar es distinta (más faroles "
        "relativos) que con una apuesta chica, de un tercio del bote.",
 error_comun="Elegir cuántos faroles meter en tu rango 'a sentimiento', "
        "sin pensar en la proporción respecto a tu valor.",
 idea_clave="La relación farol/valor correcta cambia según el tamaño de "
        "la apuesta: apuestas más grandes admiten más faroles relativos "
        "sin volverse explotables.",
),

"T234": dict(  # La frecuencia mínima de defensa (MDF)
 que_es="La frecuencia mínima de defensa (MDF) es, de forma intuitiva, "
        "la idea de que si foldeás demasiado seguido frente a una "
        "apuesta, el rival puede farolearte con cualquier mano y ganar "
        "igual.",
 por_que_importa="Conecta directo con la relación farol/valor (T235): "
        "si el rival sabe que vas a foldear más de la cuenta, cualquier "
        "farol le funciona, sin importar su mano — te está regalando "
        "el bote gratis.",
 como_funciona="Cuanto más grande la apuesta del rival en relación al "
        "bote, MENOS necesitás defender (foldear más es tolerable) "
        "para que un farol con cualquier mano no le sea automáticamente "
        "rentable. Cuanto más chica la apuesta, MÁS necesitás defender.",
 cuando_lo_uso="Como marco intuitivo: 'si foldeo casi siempre contra "
        "esta apuesta, estoy regalando farol gratis' — sin necesitar el "
        "cálculo exacto para entender la idea.",
 cuando_no=None,
 ejemplo="Contra una apuesta chica (por ejemplo, un tercio del bote), "
        "foldear casi siempre le deja al rival farolear con cualquier "
        "mano de forma rentable — ahí necesitás defender una porción "
        "grande de tu rango.",
 error_comun="Foldear 'la mano no es tan buena' sin pensar en el "
        "patrón general: si foldeás así siempre, cualquier farol del "
        "rival funciona.",
 idea_clave="MDF = si foldeás de más contra una apuesta, cualquier "
        "farol del rival se vuelve rentable, sin importar su mano.",
),

"T236": dict(  # Pensar en frecuencias
 que_es="Empezar a pensar las decisiones como frecuencias ('esta mano "
        "la juego así el 70% de las veces, y de esta otra forma el "
        "30%') en vez de como blanco o negro ('siempre pago' o 'siempre "
        "foldeo').",
 por_que_importa="Casi ninguna decisión de póker de nivel avanzado es "
        "100%-0%: jugar SIEMPRE igual con una mano te vuelve "
        "predecible y explotable, sin importar qué tan 'correcta' te "
        "parezca esa decisión en promedio.",
 como_funciona="En vez de preguntarte '¿pago o foldeo?', pensá "
        "'¿con qué frecuencia conviene cada una?'. Esto es una forma de "
        "razonar, no todavía un cálculo exacto: la idea es soltar el "
        "hábito de decidir todo en blanco o negro.",
 cuando_lo_uso="Como cambio general de mentalidad, sobre todo en "
        "decisiones cercanas donde tanto pagar como foldear tienen "
        "sentido según lo que traiga el rival.",
 cuando_no=None,
 ejemplo="Con una mano de bluff catcher (N9, T202) en una decisión "
        "cerrada, pensar 'esta mano paga algunas veces y foldea otras' "
        "es más realista que buscar una única respuesta correcta "
        "siempre.",
 error_comun="Buscar SIEMPRE una respuesta única y fija para cada "
        "situación, en vez de aceptar que algunas decisiones se juegan "
        "con una frecuencia, no con una certeza.",
 idea_clave="Pensar en frecuencias = aceptar que algunas decisiones no "
        "tienen una única respuesta fija, sino una proporción.",
),

# ============================================================
# 11.6 — Explotar vs equilibrio
# ============================================================

"T237": dict(  # Explotar vs jugar equilibrado (GTO)
 que_es="Jugar equilibrado (GTO, 'game theory optimal') es jugar de "
        "forma que ningún rival, sin importar cómo juegue, pueda "
        "explotarte. Explotar es, en cambio, desviarte a propósito de "
        "eso para castigar un error concreto del rival.",
 por_que_importa="Son dos formas distintas de ganar: jugar equilibrado "
        "te protege de cualquier rival; explotar gana más fichas contra "
        "un rival concreto que comete errores identificables — pero te "
        "expone si te equivocás en la lectura.",
 como_funciona="Jugar equilibrado significa mantener las proporciones "
        "de T235-T236 sin importar el rival. Explotar significa romper "
        "esas proporciones a propósito: si un rival foldea demasiado, "
        "farolear más de lo 'equilibrado'; si paga demasiado, farolear "
        "menos y apostar más valor.",
 cuando_lo_uso="Al decidir si mantenés un juego equilibrado (contra "
        "rivales desconocidos o muy buenos) o explotás una tendencia "
        "concreta que ya identificaste en un rival.",
 cuando_no=None,
 ejemplo="Contra un rival que foldea casi siempre frente a una segunda "
        "apuesta, explotarlo significa farolear más seguido de lo que "
        "un juego 'equilibrado' recomendaría — porque ya sabés que va a "
        "foldear.",
 error_comun="Intentar explotar a un rival sin tener evidencia real de "
        "su tendencia, terminando por desviarte sin ninguna ventaja a "
        "cambio.",
 idea_clave="Equilibrado = protegido contra cualquiera. Explotar = "
        "desviarte a propósito contra un error concreto que ya viste.",
),

"T238": dict(  # Adaptarse al rival
 que_es="Adaptarse al rival es ajustar tu estrategia a las tendencias "
        "concretas que ya observaste en él, en vez de jugar siempre de "
        "la misma forma sin importar el rival.",
 por_que_importa="Es la aplicación práctica de explotar (T237): "
        "necesitás primero observar al rival para saber en qué sentido "
        "conviene desviarte.",
 como_funciona="Prestá atención a patrones que se repiten: ¿foldea "
        "demasiado? ¿paga demasiado? ¿c-betea siempre? ¿nunca "
        "farolea el río? Cada patrón real te da una forma concreta de "
        "ajustar tu juego contra ÉL en particular.",
 cuando_lo_uso="A lo largo de una sesión, a medida que juntás "
        "información real sobre cómo juega cada rival.",
 cuando_no=None,
 ejemplo="Si notás que un rival nunca farolea el río (siempre que "
        "apuesta ahí, tiene mano), podés foldear contra sus apuestas "
        "grandes en el río con mucha más confianza que 'en teoría'.",
 error_comun="Adaptarte a una supuesta tendencia basada en una sola "
        "mano, en vez de un patrón real que se repitió varias veces.",
 idea_clave="Adaptarse al rival = ajustar tu juego según patrones "
        "reales que ya observaste, no según lo que 'en general' se "
        "recomienda.",
),

}
