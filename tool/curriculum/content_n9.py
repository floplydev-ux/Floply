# -*- coding: utf-8 -*-
"""
PASO 4 — Contenido redactado del NIVEL 9: "Turn y river".
25 teorías, 5 subniveles. Banda AVANZADO, estadio DECIDIR (9.1-9.4) y
EXPLICAR (9.5). Voz: profesor de póker rioplatense.

Fuente de verdad: curriculum_spec.json.

Meta de N9: terminar de jugar la mano completa. En el turn, reevaluar con
la carta nueva y decidir si seguís apostando (barrel) o frenás (pot
control). En el river, ya no hay más cartas: se juega por valor, por
farol, o como bluff catcher — y se empieza a pensar en rangos
polarizados.

Vocabulario nuevo de N9: carta buena/mala/blank/scare card, barrel/double
barrel, pot control, value fino (thin value), bluff catcher (uso
práctico), check back, check/fold, bet/fold, polarización, rango de
valor/farol (del río).

NO se enseña todavía: lectura de rango por línea completa acumulada a lo
largo de toda la mano (N10 — acá se lee calle por calle, no la secuencia
entera), ventaja de rango/nuts/posicional formales, bloqueadores, MDF,
GTO/explotación (N11).
"""

N9 = {

# ============================================================
# 9.1 — Reevaluar en el turn
# ============================================================

"T186": dict(  # La segunda decisión postflop
 que_es="La segunda decisión postflop es volver a evaluar toda la mano "
        "cuando aparece la carta del turn: lo que sabías con el flop "
        "puede cambiar, para bien o para mal.",
 por_que_importa="El turn no es 'una carta más': es información nueva "
        "que puede completar proyectos, parear el board, o no cambiar "
        "casi nada. Tratarlo como un trámite es un error caro.",
 como_funciona="Volvés a mirar tu mano, el board completo (ahora con "
        "cuatro cartas) y el rango probable del rival, exactamente como "
        "hiciste en el flop — pero con una carta más de información.",
 cuando_lo_uso="Cada vez que aparece la carta del turn, antes de "
        "decidir cualquier acción.",
 cuando_no=None,
 ejemplo="Tenías un proyecto de color en el flop. Llega el turn: si "
        "completó, tu mano cambió por completo — no es la misma "
        "decisión que tenías antes.",
 error_comun="Seguir con el plan del flop sin revisar si la carta del "
        "turn cambió algo importante.",
 idea_clave="El turn siempre merece una revisión completa: nunca es "
        "'la misma mano de antes, una carta más'.",
),

"T187": dict(  # Una carta buena para nosotros
 que_es="Una carta del turn que mejora tu situación: completa tu "
        "proyecto, te da una mano mejor, o empeora las chances del "
        "rival.",
 por_que_importa="Reconocerla te dice que podés jugar más agresivo de "
        "lo que venías jugando en el flop — tu equity subió.",
 como_funciona="Comparás tu mano antes y después de esa carta: si "
        "mejoró tu fuerza real (no solo 'se ve mejor'), es una carta "
        "buena para vos.",
 cuando_lo_uso="Al revisar el turn, como primera pregunta: ¿esta carta "
        "me ayudó a mí?",
 cuando_no=None,
 ejemplo="Tenías un proyecto de escalera abierta y el turn completa "
        "justo la carta que necesitabas: tu mano pasó de proyecto a "
        "mano hecha — una carta claramente buena para vos.",
 error_comun="No notar que una carta te mejoró porque estabas "
        "concentrado solo en si 'asustaba' o no (eso es otra cosa, ver "
        "T190).",
 idea_clave="Carta buena para vos = tu equity subió con esa carta "
        "concreta.",
),

"T188": dict(  # Una carta buena para el rival
 que_es="Una carta del turn que mejora la situación del rival: completa "
        "sus proyectos posibles, o empareja el board de una forma que "
        "lo favorece más a él que a vos.",
 por_que_importa="Así como hay cartas que te ayudan, hay cartas que "
        "ayudan al rival: reconocerlas te dice cuándo conviene frenar "
        "en vez de seguir apostando igual que antes.",
 como_funciona="Pensá en el rango probable del rival (según su acción "
        "en el flop) y preguntate si esa carta del turn completa algo "
        "de ese rango con más frecuencia de la que te ayuda a vos.",
 cuando_lo_uso="Al revisar el turn, como segunda pregunta: ¿esta carta "
        "ayudó más al rival que a mí?",
 cuando_no=None,
 ejemplo="El rival pagó tu c-bet en un flop con dos cartas del mismo "
        "palo, y el turn trae la tercera carta de ese palo: todavía no "
        "hay color hecho en el board, pero esa carta favorece más a un "
        "rango que incluya ese proyecto que a vos, que no lo tenías.",
 error_comun="Seguir apostando con el mismo entusiasmo del flop sin "
        "notar que la carta del turn benefició más al rango del rival "
        "que al tuyo.",
 idea_clave="Carta buena para el rival = completa más manos de SU rango "
        "probable que del tuyo.",
),

"T189": dict(  # Una carta blank
 que_es="Un blank es una carta del turn que casi no cambia nada: no "
        "completa proyectos obvios, no empareja el board, no mejora "
        "claramente a ninguno de los dos.",
 por_que_importa="Reconocer un blank te dice que la situación sigue "
        "prácticamente igual que en el flop — tu plan no debería "
        "cambiar mucho.",
 como_funciona="Preguntate si esa carta completa algún proyecto visible "
        "en el board o empareja alguna carta ya existente. Si la "
        "respuesta es no a las dos, probablemente sea un blank.",
 cuando_lo_uso="Al revisar el turn y notar que, en principio, no "
        "cambió gran cosa respecto al flop.",
 cuando_no=None,
 ejemplo="Board K♠7♦2♣ y el turn trae un 9♥: no completa color, no "
        "completa escalera, no empareja nada — un blank típico.",
 error_comun="Tratar cualquier carta 'rara' o que no jugás seguido como "
        "si fuera peligrosa, cuando en realidad no cambió nada real en "
        "la mano.",
 idea_clave="Blank = no completa nada visible ni empareja el board. La "
        "situación sigue casi igual que en el flop.",
),

"T190": dict(  # Una scare card
 que_es="Una scare card ('carta que asusta') es una carta del turn que "
        "completa visiblemente un proyecto posible en el board — aunque "
        "ninguno de los dos jugadores lo haya completado en realidad.",
 por_que_importa="Estas cartas cambian cómo se juega la mano incluso "
        "cuando tu mano real no cambió: tanto vos como el rival tienen "
        "que tener en cuenta que el OTRO podría haber completado algo "
        "ahí.",
 como_funciona="Mirá el board: si la carta del turn completa la cuarta "
        "de un mismo palo, o la carta que cierra una escalera visible, "
        "es una scare card — asusta, exista o no exista realmente esa "
        "mano del lado del rival.",
 cuando_lo_uso="Al revisar el turn, para anticipar que tanto vos como "
        "el rival van a jugar con más cautela, aunque ninguno haya "
        "completado nada en verdad.",
 cuando_no=None,
 ejemplo="Board con tres picas, y el turn trae la cuarta pica: esa "
        "carta es una scare card — cualquiera de los dos podría tener "
        "el color, y los dos van a jugar teniéndolo en cuenta.",
 error_comun="Ignorar el impacto de una scare card en cómo va a "
        "reaccionar el rival, incluso cuando vos sabés que tu mano no "
        "cambió.",
 idea_clave="Scare card = completa un proyecto visible en el board. "
        "Cambia cómo se juega la mano, exista o no esa mano en "
        "concreto.",
),

"T197": dict(  # Los cambios de equity
 que_es="Con cada carta que sale, la equity (N6) de cada mano en juego "
        "cambia — a veces poco, a veces por completo.",
 por_que_importa="Formaliza lo que ya veníamos viendo con ejemplos "
        "concretos (carta buena, mala, blank, scare card): todo eso son "
        "formas distintas de decir 'la equity de cada uno cambió'.",
 como_funciona="Antes del turn, cada mano tenía una equity según sus "
        "outs. Con la carta nueva, esos outs se resuelven (para bien o "
        "para mal) y la equity de cada mano se recalcula desde cero.",
 cuando_lo_uso="Como marco general para entender por qué revisás la "
        "mano completa en cada calle nueva, en vez de seguir con la "
        "lectura del flop.",
 cuando_no=None,
 ejemplo="Tu proyecto de color tenía cierta equity en el flop. Si el "
        "turn lo completa, tu equity salta a un porcentaje mucho más "
        "alto; si no lo completa, tu equity baja porque te quedó una "
        "sola carta para el river.",
 error_comun="Seguir pensando en la equity del flop después de que "
        "salió el turn, sin recalcularla con la carta nueva.",
 idea_clave="Cada carta nueva recalcula la equity de todas las manos en "
        "juego — por eso cada calle merece su propia revisión.",
),

# ============================================================
# 9.2 — Barrel o pot control
# ============================================================

"T191": dict(  # El barrel
 que_es="Un barrel es seguir apostando en el turn después de haber "
        "c-beteado el flop — mantener la presión en vez de frenar.",
 por_que_importa="Muchas manos que fallaron el flop siguen fallando el "
        "turn: seguir apostando aprovecha que el rival, con un rango "
        "más flojo, tiene motivos para retirarse de nuevo.",
 como_funciona="Si tenías la iniciativa (N8) y c-beteaste el flop, "
        "apostar otra vez en el turn es hacer un barrel — sostener la "
        "misma presión una calle más.",
 cuando_lo_uso="Después de c-betear el flop, cuando el turn (revisado "
        "con T187-190) sigue favoreciendo que apuestes de nuevo.",
 cuando_no=None,
 ejemplo="C-beteaste el flop con un farol en board seco, el turn es un "
        "blank: seguir apostando (barrel) mantiene la misma presión de "
        "antes, porque nada cambió.",
 error_comun="Hacer barrel en piloto automático, sin revisar si la "
        "carta del turn en realidad favoreció al rival (T188).",
 idea_clave="Barrel = seguir apostando en el turn, sosteniendo la "
        "presión del flop.",
),

"T192": dict(  # El double barrel
 que_es="El double barrel es el nombre específico para la SEGUNDA "
        "apuesta consecutiva: c-bet en el flop + apuesta en el turn.",
 por_que_importa="Te da un vocabulario preciso para hablar de esta "
        "secuencia concreta, distinta de seguir apostando en el río "
        "también (esa tercera apuesta seguida se suele llamar triple "
        "barrel, aunque acá no la desarrollamos como concepto aparte).",
 como_funciona="Es simplemente el barrel (T191) nombrado por su "
        "posición en la secuencia: la segunda apuesta seguida del "
        "mismo jugador.",
 cuando_lo_uso="Para nombrar con precisión la secuencia c-bet + "
        "apuesta en el turn, y pensar en ella como un plan de dos "
        "calles, no como dos decisiones sueltas.",
 cuando_no=None,
 ejemplo="C-beteaste el flop y apostaste de nuevo en el turn: eso es un "
        "double barrel.",
 error_comun="Pensar cada apuesta como una decisión aislada, en vez de "
        "planificar el double barrel desde el flop, sabiendo qué cartas "
        "del turn te van a dejar seguir.",
 idea_clave="Double barrel = c-bet + apuesta en el turn, la misma idea "
        "del barrel con nombre propio.",
),

"T193": dict(  # Check en el turn
 que_es="Pasar en el turn: decidir no apostar, después de haber (o no) "
        "apostado el flop.",
 por_que_importa="No todo turn conviene apostarlo. A veces el board "
        "cambió en tu contra, o tu mano no gana lo suficiente apostando "
        "de nuevo.",
 como_funciona="Si la carta del turn favoreció al rango del rival "
        "(T188), o si tu mano es media y preferís ver el river sin "
        "arriesgar más fichas, pasar es la decisión correcta.",
 cuando_lo_uso="Cuando el turn no te da motivos para seguir apostando "
        "con confianza.",
 cuando_no=None,
 ejemplo="C-beteaste el flop con un farol, pero el turn trae una scare "
        "card (T190) que favorece bastante al rango del rival: pasar en "
        "vez de seguir apostando es razonable ahí.",
 error_comun="Sentir que 'ya apostaste el flop, tenés que seguir' — el "
        "turn es una decisión nueva, no una continuación automática.",
 idea_clave="Pasar en el turn es una decisión válida, no una "
        "rendición: a veces el board o la mano lo piden.",
),

"T194": dict(  # Bet en el turn
 que_es="Apostar el turn, ya sea por valor (tenés una mano buena que "
        "busca pago) o como segundo farol (buscás que el rival se "
        "retire con la presión sostenida).",
 por_que_importa="Es la decisión contraria a T193: juntá lo que ya "
        "sabés del barrel (T191) para decidir cuándo apostar en vez de "
        "pasar.",
 como_funciona="Con una mano fuerte que quiere pago, o con un farol que "
        "sigue teniendo buenos motivos para funcionar (el rival tiene "
        "motivos para retirarse), apostás de nuevo.",
 cuando_lo_uso="Después de revisar el turn (T187-190), cuando la "
        "situación sigue favoreciendo que apuestes.",
 cuando_no=None,
 ejemplo="Tenés una mano fuerte y el turn es un blank: apostar por "
        "valor sigue teniendo sentido, nada cambió en tu contra.",
 error_comun="Apostar el turn solo porque 'ya venías apostando', sin "
        "distinguir si es por valor o por farol y si la carta todavía "
        "acompaña esa decisión.",
 idea_clave="Apostar el turn puede ser por valor o como segundo farol "
        "— sostener el barrel con un motivo concreto.",
),

"T195": dict(  # Pot control
 que_es="El pot control es pasar (o apostar chico) a propósito con una "
        "mano media, para no inflar el bote en una mano que no aguanta "
        "mucha presión.",
 por_que_importa="No toda mano decente quiere un bote grande. Con una "
        "mano media, mantener el bote chico limita cuánto podés perder "
        "si el rival en realidad tiene algo mejor.",
 como_funciona="Con una mano que le gana a parte del rango del rival "
        "pero no a todo, pasar en el turn (en vez de apostar) evita "
        "construir un bote grande que te obligue a tomar una decisión "
        "más difícil y más cara en el river.",
 cuando_lo_uso="Con una mano media, cuando apostar de más te expone a "
        "perder un bote grande contra las manos que sí te ganan.",
 cuando_no=None,
 ejemplo="Tenés una pareja media que le gana a algunos faroles del "
        "rival pero pierde contra sus manos de valor: pasar el turn "
        "mantiene el bote manejable en vez de agrandarlo.",
 error_comun="Apostar cada mano que 'no es mala', sin pensar si en "
        "realidad conviene mantener el bote chico dada su fuerza real.",
 idea_clave="Pot control = mantener el bote chico a propósito, con una "
        "mano que no quiere jugarse por mucho más.",
),

"T196": dict(  # Proyectos que siguen en el turn
 que_es="Distinguir, en el turn, qué proyectos siguen vivos (todavía "
        "tienen outs reales para el river) de los que ya se murieron "
        "(fallaron sin ninguna chance más).",
 por_que_importa="Un proyecto vivo sigue teniendo equity real, aunque "
        "sea con una sola carta por venir (regla del 2, N6). Un "
        "proyecto muerto ya no tiene ningún valor futuro — solo cuenta "
        "lo que tenga hecho, si tiene algo.",
 como_funciona="Mirá tus outs originales del flop: si ninguna de esas "
        "cartas salió en el turn, tu proyecto sigue vivo, con una "
        "carta menos por venir. Si el board ya cerró esa posibilidad "
        "(por ejemplo, ya no hay forma de completar esa escalera), "
        "está muerto.",
 cuando_lo_uso="Al revisar el turn, para saber si todavía te queda "
        "equity de proyecto para el river.",
 cuando_no=None,
 ejemplo="Tenías un proyecto de color en el flop y el turn no trajo "
        "ninguna carta de ese palo: tu proyecto sigue vivo, ahora con "
        "la regla del 2 (una sola carta por venir) en vez de la regla "
        "del 4.",
 error_comun="Seguir contando outs del flop sin actualizar cuántos te "
        "quedan realmente después del turn.",
 idea_clave="Un proyecto vivo en el turn tiene equity real con la "
        "regla del 2. Uno muerto ya no vale nada, salvo lo que tengas "
        "hecho aparte.",
),

# ============================================================
# 9.3 — El river: valor
# ============================================================

"T198": dict(  # El river: no quedan cartas
 que_es="En el river ya salieron las cinco cartas del board: no hay más "
        "cartas por venir. La mano de cada jugador está completamente "
        "definida.",
 por_que_importa="Cambia el tipo de pensamiento: en el flop y el turn "
        "pensabas en outs y equity futura; en el río, ya no hay futuro "
        "— solo importa quién tiene la mejor mano AHORA.",
 como_funciona="Ya no hay proyectos vivos (T196): o completaste, o no. "
        "Toda decisión en el river se basa en comparar tu mano final "
        "contra el rango final del rival, sin ningún 'todavía puede "
        "mejorar'.",
 cuando_lo_uso="Al llegar al river, como primer paso: entender que la "
        "pregunta cambió por completo respecto al flop y al turn.",
 cuando_no=None,
 ejemplo="Tenías un proyecto de color que no completó en el river: ya "
        "no hay ninguna carta más por venir que lo salve. Tu mano es "
        "la que es, definitivamente.",
 error_comun="Seguir pensando 'todavía puedo mejorar' en el river, "
        "cuando ya no queda ninguna carta por salir.",
 idea_clave="River = no quedan cartas. Se juega por lo que cada mano "
        "ES, no por lo que podría llegar a ser.",
),

"T199": dict(  # La value bet
 que_es="Apostar por valor en el river: con una mano fuerte, buscando "
        "que el rival pague con algo peor.",
 por_que_importa="Es el caso más limpio de apostar por valor (ya visto "
        "en N6, T125): sin más cartas por venir, es pura comparación "
        "entre tu mano final y lo que el rival podría tener.",
 como_funciona="Con una mano que le gana a buena parte del rango final "
        "del rival, apostás buscando cobrar de las manos peores que "
        "todavía están dispuestas a pagar.",
 cuando_lo_uso="En el river, con una mano fuerte, contra un rango del "
        "rival que puede incluir manos peores dispuestas a pagar.",
 cuando_no=None,
 ejemplo="Completaste tu color en el river: apostar por valor busca que "
        "el rival, con una pareja fuerte pero peor, pague.",
 error_comun="No apostar una mano fuerte en el río 'por las dudas', "
        "regalando valor que se podría haber cobrado.",
 idea_clave="Value bet en el río = tu mano final le gana a suficientes "
        "manos del rango del rival como para que valga la pena apostar.",
),

"T200": dict(  # El value fino (thin value)
 que_es="Un value bet fino es apostar una mano que gana, pero por poco "
        "margen: no es obviamente la mejor mano, pero igual le gana a "
        "una porción razonable del rango del rival.",
 por_que_importa="Muchas apuestas de valor rentables no vienen de manos "
        "espectaculares: vienen de manos medias que, bien leídas, "
        "siguen ganando más seguido de lo que parece.",
 como_funciona="Antes de descartar apostar 'porque mi mano no es tan "
        "buena', preguntate específicamente qué manos peores del rango "
        "del rival te seguirían pagando (esto se desarrolla en T209).",
 cuando_lo_uso="Con una mano media-fuerte, cuando dudás si apostar por "
        "no sentirla lo bastante buena.",
 cuando_no=None,
 ejemplo="Tenés una pareja alta con kicker mediano: no es una mano "
        "espectacular, pero contra un rango de defensa que incluye "
        "varias manos peores, una apuesta chica de value fino puede "
        "seguir siendo rentable.",
 error_comun="Solo apostar por valor con manos obviamente fuertes, "
        "dejando pasar apuestas finas rentables por 'no sentirlas tan "
        "buenas'.",
 idea_clave="Value fino = apostás aunque tu mano no sea espectacular, "
        "porque le sigue ganando a una parte real del rango del rival.",
),

"T209": dict(  # ¿Qué manos peores te pagan?
 que_es="Antes de apostar por valor en el river, preguntarte "
        "concretamente: de todas las manos que el rival podría tener, "
        "¿cuáles son PEORES que la mía Y además pagarían mi apuesta?",
 por_que_importa="Tener la mejor mano no alcanza: si ninguna mano peor "
        "del rango del rival va a pagar (todas se retiran, o todas te "
        "ganan), apostar por valor no suma nada.",
 como_funciona="Pensá en el rango del rival y filtralo dos veces: "
        "primero, ¿qué manos son peores que la mía? Segundo, de esas, "
        "¿cuáles pagarían esta apuesta en particular (y no se "
        "retirarían)?",
 cuando_lo_uso="Cada vez que pensás en apostar por valor en el río, "
        "antes de decidir el tamaño.",
 cuando_no=None,
 ejemplo="Tenés una mano fuerte, pero el board es tan feo para el "
        "rango del rival que las únicas manos peores que le quedan casi "
        "seguro se retiran frente a cualquier apuesta: ahí, apostar "
        "grande no suma mucho valor real.",
 error_comun="Apostar por valor solo porque 'tengo la mejor mano', sin "
        "chequear si de verdad hay manos peores dispuestas a pagar.",
 idea_clave="Apostar por valor solo tiene sentido si existen manos "
        "peores que realmente van a pagar esa apuesta.",
),

# ============================================================
# 9.4 — El river: farol y bluff-catch
# ============================================================

"T201": dict(  # El farol (bluff)
 que_es="Farolear el river es apostar con una mano floja, buscando que "
        "el rival se retire con manos MEJORES que la tuya.",
 por_que_importa="En el río, un farol es la forma más pura de fold "
        "equity (N6): no hay ninguna carta futura que te vaya a "
        "salvar, así que todo el valor del farol viene de que el rival "
        "se retire ahora mismo.",
 como_funciona="Elegís una mano sin valor de showdown y apostás, "
        "buscando que el rival, con una mano mejor que la tuya, decida "
        "retirarse igual.",
 cuando_lo_uso="Con una mano floja en el río, contra un rival que "
        "tiene motivos reales para retirarse frente a tu apuesta.",
 cuando_no="Contra un rival que paga casi cualquier cosa en el río: "
        "ahí no hay fold equity que aproveche el farol.",
 ejemplo="Fallaste por completo tu proyecto en el river: farolear ahí "
        "busca que una mano media del rival, que sí le ganaría a la "
        "tuya, se retire igual.",
 error_comun="Farolear el river con cualquier mano floja, sin evaluar "
        "si la línea completa de la mano cuenta una historia creíble "
        "de fuerza.",
 idea_clave="Farol en el río = gana por fold equity pura, sin ninguna "
        "carta futura de por medio.",
),

"T202": dict(  # El bluff catcher (uso)
 que_es="Usar tu mano como bluff catcher (N4, T100): decidir si pagar "
        "una apuesta en el río con una mano que solo le gana a un "
        "farol.",
 por_que_importa="Es una de las decisiones más difíciles del póker: "
        "estás apostando sobre el rival, no sobre tus cartas — ¿creés "
        "que está faroleando o no?",
 como_funciona="Juntás todo: la línea completa de la mano (¿tiene "
        "sentido que tenga una mano de valor ahí?), pot odds y equity "
        "necesaria (N6) contra la frecuencia con la que creés que "
        "está faroleando.",
 cuando_lo_uso="En el río, con una mano que solo le gana a un farol, "
        "frente a una apuesta del rival.",
 cuando_no=None,
 ejemplo="Tenés una pareja fuerte en un board donde ya no hay proyectos "
        "posibles. El rival apuesta grande: si tiene una mano de valor, "
        "perdés; si farolea, ganás. Ahí es donde entra la decisión de "
        "bluff catcher.",
 error_comun="Pagar como bluff catcher 'por curiosidad', sin pensar en "
        "serio si la historia de apuestas del rival parece un farol de "
        "verdad.",
 idea_clave="Pagar como bluff catcher es apostar a que el rival está "
        "mintiendo con su línea de apuestas.",
),

"T210": dict(  # ¿Qué manos mejores foldean?
 que_es="Antes de farolear en el river, preguntarte concretamente: de "
        "todas las manos que el rival podría tener, ¿cuáles son MEJORES "
        "que la mía Y además se retirarían frente a mi apuesta?",
 por_que_importa="Así como con la value bet (T209), un farol solo "
        "funciona si existe una porción real del rango del rival que "
        "sea mejor que tu mano pero igual se retire.",
 como_funciona="Pensá en el rango del rival: si sus manos mejores que "
        "la tuya son del tipo que nunca se retira (por ejemplo, manos "
        "muy fuertes que van a pagar cualquier cosa), tu farol no tiene "
        "con qué ganar.",
 cuando_lo_uso="Cada vez que pensás en farolear en el río, antes de "
        "decidir el tamaño.",
 cuando_no=None,
 ejemplo="El board favorece mucho a un tipo de mano muy fuerte y poco "
        "probable que se retire: farolear ahí, aunque el rival tenga "
        "manos mejores que la tuya, puede no funcionar si esas manos "
        "casi nunca foldean.",
 error_comun="Farolear pensando solo en 'el rival puede tener algo "
        "peor', sin chequear si sus manos mejores realmente se "
        "retirarían.",
 idea_clave="Farolear solo tiene sentido si existen manos mejores del "
        "rival que realmente se van a retirar frente a tu apuesta.",
),

# ============================================================
# 9.5 — Líneas de río y polarización
# ============================================================

"T203": dict(  # Check back
 que_es="Check back es pasar en el río sin apostar, cuando tenías la "
        "opción de hacerlo — normalmente con una mano media que no "
        "quiere apostar ni tiene motivos para foldear si el rival ya "
        "había pasado antes.",
 por_que_importa="No todo river se apuesta. Con una mano media, a "
        "veces lo mejor es simplemente ir al showdown sin arriesgar "
        "fichas de más ni exponerte a un check-raise.",
 como_funciona="Con una mano que no gana lo suficiente como para "
        "apostar por valor (T209) ni tiene sentido farolear (T210), "
        "pasás y vas directo a mostrar las cartas.",
 cuando_lo_uso="Con una mano media en el river, cuando ni apostar por "
        "valor ni farolear tienen un motivo real detrás.",
 cuando_no=None,
 ejemplo="Tenés una pareja media contra un rango donde casi no hay "
        "manos peores dispuestas a pagar (T209) ni manos mejores "
        "dispuestas a foldear (T210): check back y listo.",
 error_comun="Apostar 'porque sí' en el río con una mano media, sin un "
        "motivo real de valor o farol detrás.",
 idea_clave="Check back = pasar en el río porque ni apostar por valor "
        "ni farolear tienen sentido con esa mano.",
),

"T204": dict(  # Check/fold
 que_es="Check/fold es la línea completa de pasar en el río y, si el "
        "rival apuesta, retirarte — con una mano que no aguanta ni "
        "para pagar.",
 por_que_importa="Es distinta del check back (T203): ahí pasabas "
        "porque tu mano no tenía motivo para apostar, pero SÍ iba al "
        "showdown si el rival también pasaba. Acá, directamente no "
        "tenés intención de pagar si te apuestan.",
 como_funciona="Con una mano floja que no le gana a casi nada del "
        "rango del rival, pasás sabiendo que, si apuestan, vas a "
        "retirarte.",
 cuando_lo_uso="Con una mano floja en el river, cuando ni siquiera "
        "tenés intención de pagar una apuesta del rival.",
 cuando_no=None,
 ejemplo="Fallaste todo en el río y tu mano no le gana a casi nada: "
        "pasás con la intención de foldear apenas el rival apueste.",
 error_comun="Confundir el check/fold con el check back — con una mano "
        "que sí le ganaría a un farol, foldear automático regala valor "
        "como bluff catcher (T202).",
 idea_clave="Check/fold = pasás sin intención de pagar nada si te "
        "apuestan. Distinto del check back, donde sí ibas al showdown.",
),

"T205": dict(  # Bet/fold
 que_es="Bet/fold es apostar el río con tu mano, pero con la intención "
        "de retirarte si el rival responde subiendo tu apuesta.",
 por_que_importa="Apostar no siempre significa estar dispuesto a pagar "
        "cualquier cosa después: con ciertas manos, la apuesta tiene "
        "sentido, pero una subida cambia completamente el panorama.",
 como_funciona="Apostás con una mano de valor razonable, pero si el "
        "rival responde con un raise (algo que no haría con manos "
        "medias, solo con las más fuertes), te retirás en vez de pagar.",
 cuando_lo_uso="Con una mano que gana contra la mayoría del rango del "
        "rival, pero pierde contra las pocas manos que responderían "
        "con un raise.",
 cuando_no=None,
 ejemplo="Apostás por valor fino (T200) en el río. Si el rival te sube, "
        "esa subida casi siempre representa algo mejor que tu mano "
        "media — te retirás sin pagar esa subida.",
 error_comun="Pagar automáticamente cualquier raise en el río solo "
        "porque ya habías apostado — la subida es información nueva.",
 idea_clave="Bet/fold = apostás, pero un raise del rival te hace "
        "retirarte en vez de pagar.",
),

"T206": dict(  # Polarización
 que_es="Un rango polarizado está compuesto casi por completo por dos "
        "extremos: manos muy fuertes (valor) y faroles — con muy poco "
        "en el medio.",
 por_que_importa="Entender la forma de tu rango (o el del rival) te "
        "ayuda a leer o construir apuestas grandes en el río: una "
        "apuesta grande con un rango polarizado tiene sentido porque "
        "combina 'gano mucho' con 'gano por fold equity'.",
 como_funciona="Pensá en las líneas de esta lección: check back "
        "(T203) y check/fold (T204) sacan las manos medias del rango "
        "que apuesta; lo que queda apostando en el río tiende a ser "
        "valor fuerte o farol — un rango polarizado.",
 cuando_lo_uso="Al leer una apuesta grande del rival en el río, o al "
        "construir la tuya propia.",
 cuando_no=None,
 ejemplo="Si pasás tus manos medias (check back) y también tus manos "
        "muy flojas sin potencial (check/fold), lo que te queda "
        "apostando en el río — tus mejores manos y tus mejores "
        "faroles — es un rango polarizado.",
 error_comun="Pensar que una apuesta grande siempre significa 'mano muy "
        "fuerte', sin considerar que un rango polarizado también "
        "incluye faroles.",
 idea_clave="Polarizado = casi todo valor fuerte o farol, casi nada en "
        "el medio.",
),

"T207": dict(  # El rango de valor
 que_es="Tu rango de valor en el río es el conjunto de manos con las "
        "que apostás buscando que te paguen — la mitad 'fuerte' de un "
        "rango polarizado (T206).",
 por_que_importa="Definirlo de antemano te ayuda a mantener consistencia: "
        "no cada mano suelta, sino un conjunto pensado de manos que "
        "realmente ganan lo suficiente como para apostar por valor.",
 como_funciona="Juntás las manos que, según T209, tienen suficientes "
        "manos peores del rival dispuestas a pagar.",
 cuando_lo_uso="Al planificar, de antemano, con qué manos vas a "
        "apostar por valor en un río determinado.",
 cuando_no=None,
 ejemplo="Tu rango de valor en un río concreto puede incluir tus manos "
        "más fuertes (color, escalera) y algunas de valor fino (T200) "
        "que igual le ganan a buena parte del rango del rival.",
 error_comun="No tener un rango de valor definido y apostar por valor "
        "'a ojo', mano por mano, sin ningún criterio consistente.",
 idea_clave="Rango de valor = las manos con las que apostás buscando "
        "pago, pensadas como conjunto.",
),

"T208": dict(  # El rango de farol
 que_es="Tu rango de farol en el río es el conjunto de manos con las "
        "que apostás sin valor real, buscando que el rival se retire — "
        "la mitad 'floja' de un rango polarizado (T206).",
 por_que_importa="Un rango de farol bien pensado hace que tu rango de "
        "apuesta completo (valor + farol) sea difícil de leer para el "
        "rival: no puede asumir que siempre tenés lo mejor.",
 como_funciona="Elegís, de las manos que se quedaron sin valor de "
        "showdown, las que mejor cumplen T210 (que el rival tenga "
        "manos mejores dispuestas a retirarse) para incluirlas en tu "
        "rango de farol.",
 cuando_lo_uso="Al planificar, de antemano, con qué manos vas a "
        "farolear en un río determinado.",
 cuando_no=None,
 ejemplo="Tu rango de farol en un río concreto puede incluir manos que "
        "fallaron por completo pero cuya línea previa (apostaste flop y "
        "turn) sigue contando una historia creíble de fuerza.",
 error_comun="Farolear siempre con la misma mano floja 'de siempre', "
        "en vez de pensar cuál de tus manos sin valor cuenta la "
        "historia más creíble en cada situación.",
 idea_clave="Rango de farol = las manos sin valor con las que apostás "
        "buscando que se retiren, pensadas como conjunto.",
),

}
