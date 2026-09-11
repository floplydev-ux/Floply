# -*- coding: utf-8 -*-
"""
PASO 6 — Contenido redactado del NIVEL 3: "La mesa: posiciones y dinero".
22 teorías, 5 subniveles. Banda FUNDAMENTAL, estadio RECONOCER.
Voz: un buen profesor a alguien que empieza. Completo, no largo. Rioplatense.

Fuente de verdad: curriculum_spec.json (IDs, títulos, objetivos, orden y
prerrequisitos no se tocan acá).

Meta de N3: el alumno termina entendiendo qué es una posición, el botón y su
rotación, las ciegas, el orden de acción pre y postflop, estar en/fuera de
posición (sentido básico), stack, stack efectivo, la BB como unidad, el bote
y que cada decisión tiene un precio.

Vocabulario: NO se asume RFI, equity, pot odds, EV, 3-bet, c-bet, blockers,
MDF ni estrategia avanzada. Donde una teoría roza algo de eso, se señala el
nivel futuro sin enseñarlo. Se evita la palabra "rango" (concepto de N5):
se dice "abanico de manos" / "qué manos jugás".
"""

N3 = {

# ============================================================
# 3.1 — La mesa 6-max y las 6 sillas
# ============================================================

"T011": dict(  # La mesa 6-max
 que_es="Una mesa de 6-max es una mesa de póker con seis asientos como máximo. Es "
        "el formato más común para aprender y para jugar cash online.",
 por_que_importa="Casi todo lo que vas a estudiar —posiciones, orden de acción, qué "
        "manos jugar— está pensado para 6 jugadores. Con más o menos gente, algunas "
        "cosas cambian.",
 como_funciona="Los seis asientos tienen nombre según dónde están respecto del "
        "botón. Cada mano, todos reciben 2 cartas y se juega en el orden que marca la "
        "mesa. Si alguien se levanta, se sigue jugando con los que haya, pero el "
        "6-max es la referencia.",
 cuando_lo_uso="Siempre que te sentás a jugar: mirás cuántos hay en la mesa y en "
        "qué asiento estás.",
 cuando_no=None,
 ejemplo="Mesa llena: 6 jugadores. Se reparte, cada uno decide en su turno, se "
        "resuelve la mano y el botón se corre un asiento para la mano siguiente.",
 error_comun="Jugar una mesa de 6 igual que una de 9 (o al revés). Con menos "
        "jugadores, las manos que conviene jugar y el ritmo cambian.",
 idea_clave="6-max = seis asientos. Es el formato de referencia de la Academia.",
),

"T012": dict(  # El botón (BTN)
 que_es="El botón (BTN) es una ficha redonda que marca un asiento. Ese jugador es "
        "'el botón' esa mano. Después de cada mano, el botón se corre un asiento a la "
        "izquierda.",
 por_que_importa="El botón define todo lo demás: desde dónde se reparte, quién paga "
        "las ciegas y en qué orden se actúa. Además es la mejor posición de la mesa "
        "(lo vas a ver en 3.3).",
 como_funciona="Se reparten las cartas empezando por el jugador a la izquierda del "
        "botón. El botón actúa último en el flop, el turn y el river. Como rota, "
        "todos pasan por el botón por turno: nadie tiene la ventaja fija.",
 cuando_lo_uso="Lo primero que mirás en una mano: '¿dónde está el botón?, ¿dónde "
        "estoy yo respecto de él?'.",
 cuando_no=None,
 ejemplo="Sos el botón. Preflop hablás anteúltimo (solo faltan las dos ciegas). Del "
        "flop en adelante, hablás último siempre: ves lo que hacen todos antes de "
        "decidir.",
 error_comun="Olvidarte de que el botón rota. La posición no es tuya: es del "
        "asiento, y va cambiando mano a mano.",
 idea_clave="El botón marca el reparto y el orden. Rota un asiento por mano. Es la "
        "mejor posición.",
),

"T013": dict(  # La ciega chica (SB)
 que_es="La ciega chica (SB, 'small blind') es el asiento inmediatamente a la "
        "izquierda del botón. Ese jugador pone una apuesta obligatoria chica antes de "
        "ver las cartas.",
 por_que_importa="Ya puso fichas sin haber visto nada y, del flop en adelante, es "
        "el primero en hablar. Es una de las peores posiciones de la mesa.",
 como_funciona="Antes del reparto, la SB pone su ciega (media ciega grande en la "
        "mayoría de las mesas). Preflop actúa anteúltima, antes de la BB. Postflop "
        "actúa primera de todas.",
 cuando_lo_uso="En la SB arrancás la mano ya con fichas puestas y vas a jugar de "
        "atrás: hay que ser más selectivo con qué manos entrás.",
 cuando_no=None,
 ejemplo="Sos la SB. Ponés media ciega grande de entrada. Todos foldean hasta vos. "
        "Podés completar (igualar la ciega grande), subir, o foldear y perder solo "
        "esa media ciega.",
 error_comun="Jugar la SB como si fuera una posición normal. Estás fuera de "
        "posición contra todos menos la BB: entrá con menos manos.",
 idea_clave="SB = a la izquierda del botón. Pone ciega obligatoria y postflop habla "
        "primera. Mala posición.",
),

"T014": dict(  # La ciega grande (BB)
 que_es="La ciega grande (BB, 'big blind') es el asiento a la izquierda de la ciega "
        "chica. Pone la apuesta obligatoria más grande —una ciega grande entera— "
        "antes de ver las cartas.",
 por_que_importa="Preflop es el último en hablar: si nadie subió, tiene 'la opción' "
        "de pasar y ver el flop gratis, o subir. Postflop habla segundo, apenas mejor "
        "que la SB.",
 como_funciona="La BB pone 1 ciega grande antes del reparto. Como ya tiene fichas "
        "puestas, seguir le sale más barato que a los demás: le falta poner menos "
        "para igualar una subida.",
 cuando_lo_uso="En la BB, si te suben, ya tenés parte del precio pagado: podés "
        "seguir con más manos que desde otras posiciones (esto se estudia a fondo en "
        "el Nivel 7).",
 cuando_no=None,
 ejemplo="Sos la BB, ponés 1 ciega grande. El botón sube a 2,5. Para seguir solo te "
        "falta poner 1,5 más, y vas a jugar la mano: pagás con bastantes manos.",
 error_comun="Foldear la BB demasiado seguido ante una subida. Ya pusiste una "
        "ciega: tirarla siempre es regalar fichas.",
 idea_clave="BB = a la izquierda de la SB. Pone la ciega grande (la unidad de "
        "medida). Preflop habla última.",
),

"T015": dict(  # UTG
 que_es="UTG ('under the gun', 'bajo el arma') es el asiento inmediatamente a la "
        "izquierda de la ciega grande. Es el primero en hablar preflop.",
 por_que_importa="Habla primero, sin información de nadie, y con cinco jugadores por "
        "detrás que todavía pueden tener una mano fuerte. Es la posición más "
        "incómoda para entrar a un bote.",
 como_funciona="Preflop, UTG decide antes que nadie: foldear, o abrir subiendo. Si "
        "sigue en la mano, postflop también habla temprano (solo después de las "
        "ciegas).",
 cuando_lo_uso="En UTG entrás con muy pocas manos: solo las que aguantan que "
        "cualquiera de los cinco de atrás te juegue.",
 cuando_no=None,
 ejemplo="Estás en UTG. Sos el primero en decidir preflop. Con A-K abrís; con K-9 "
        "del mismo palo foldeás: desde acá esa mano trae más problemas que ganancias.",
 error_comun="Abrir manos flojas desde UTG 'porque son lindas'. Cuantos más "
        "jugadores hablan después tuyo, más fuerte tiene que ser tu mano.",
 idea_clave="UTG = a la izquierda de la BB. Habla primero preflop. La posición más "
        "apretada: pocas manos.",
),

"T016": dict(  # El hijack (HJ)
 que_es="El hijack (HJ) es la posición media de la mesa 6-max: está entre UTG y el "
        "cutoff. Habla segundo preflop, justo después de UTG.",
 por_que_importa="Ya no es tan apretada como UTG —tenés un jugador menos por "
        "detrás— pero todavía quedan cuatro por hablar (CO, BTN y las dos ciegas) "
        "que pueden tener una mano fuerte.",
 como_funciona="Preflop, el HJ actúa después de UTG y antes del CO. Con cuatro "
        "jugadores por detrás en vez de cinco, puede abrir un poco más de manos que "
        "UTG.",
 cuando_lo_uso="En el HJ, el abanico de manos con las que entrás se abre un poco "
        "respecto de UTG, pero seguís siendo cauto: el CO y el botón todavía no "
        "hablaron.",
 cuando_no=None,
 ejemplo="Estás en el HJ. UTG foldeó, te toca. Podés abrir manos un escalón más "
        "flojas que desde UTG, pero todavía te falta pasar el CO y el botón.",
 error_comun="Tratar el HJ como si fuera el botón. Es posición media: más manos que "
        "UTG, muchas menos que el botón.",
 idea_clave="HJ = posición media, habla segundo preflop. Un poco más de manos que "
        "UTG.",
),

"T017": dict(  # El cutoff (CO)
 que_es="El cutoff (CO) es el asiento justo antes del botón. Habla tercero preflop; "
        "después de vos solo quedan el botón y las dos ciegas.",
 por_que_importa="Es una posición fuerte: solo el botón puede quitarte la posición. "
        "Si el botón foldea, jugás el resto de la mano como si el botón fueras vos.",
 como_funciona="Preflop, el CO actúa después del HJ y antes del botón. Con solo "
        "tres jugadores por detrás (BTN, SB, BB), abre bastantes más manos que el "
        "HJ.",
 cuando_lo_uso="En el CO abrís muchas más manos que desde el HJ. Si el botón "
        "foldea, jugás el bote con posición sobre las ciegas.",
 cuando_no=None,
 ejemplo="Estás en el CO. UTG y HJ foldearon, abrís. Si el botón también foldea, "
        "jugás contra las ciegas y hablás último postflop: gran situación.",
 error_comun="Abrir de más 'porque es posición tardía' y olvidarte de que el botón "
        "todavía puede subirte y dejarte fuera de posición toda la mano.",
 idea_clave="CO = la silla anterior al botón. Habla tercero preflop. Posición "
        "tardía: muchas manos jugables.",
),

# ============================================================
# 3.2 — El orden de acción
# ============================================================

"T018": dict(  # El orden de acción preflop
 que_es="El orden fijo en que se habla antes del flop: UTG → HJ → CO → BTN → SB → "
        "BB. Siempre el mismo, mano tras mano.",
 por_que_importa="Saber quién habla antes y quién después te dice cuánta "
        "información tenés al decidir y cuántos jugadores pueden todavía "
        "sorprenderte.",
 como_funciona="La acción arranca a la izquierda de la ciega grande (UTG) y da la "
        "vuelta a la mesa. La BB habla última y tiene 'la opción': si nadie subió, "
        "puede pasar (ver el flop gratis) o subir. Regla general: cuanto más "
        "temprano hablás (UTG, HJ), menos sabés y más fuerte tiene que ser tu mano; "
        "cuanto más tarde (CO, BTN), más manos podés jugar.",
 cuando_lo_uso="Antes de cada decisión preflop: '¿quién ya habló?, ¿cuántos faltan "
        "detrás mío?'.",
 cuando_no=None,
 ejemplo="UTG abre a 2,5 BB. HJ y CO foldean. El botón paga. La SB foldea. La BB "
        "decide con toda la información de la ronda: sabe que hay dos jugadores en el "
        "bote y cuánto le cuesta seguir.",
 error_comun="Contar mal a los jugadores de atrás. En UTG hablan cinco después "
        "tuyo; en el CO, solo tres.",
 idea_clave="Preflop: UTG → HJ → CO → BTN → SB → BB. La BB habla última.",
),

"T019": dict(  # El orden de acción postflop
 que_es="Después del flop, el orden cambia: arranca la ciega chica (o, si foldeó, "
        "el primer jugador vivo a su izquierda) y el botón habla último.",
 por_que_importa="Es la razón por la que el botón es tan buena posición y las "
        "ciegas tan malas. Preflop las ciegas hablan últimas; postflop —las tres "
        "calles que quedan— hablan primeras.",
 como_funciona="En el flop, el turn y el river, la acción empieza en la SB y "
        "termina en el botón. El mismo orden las tres calles.",
 cuando_lo_uso="Cada vez que sale el flop: 'ahora yo hablo antes/después que él en "
        "todas las calles que faltan'.",
 cuando_no=None,
 ejemplo="La SB y el botón llegan al flop. La SB habla primero las tres calles; el "
        "botón, último las tres. El botón siempre ve qué hizo la SB antes de "
        "decidir.",
 error_comun="Seguir pensando en el orden preflop cuando ya salió el flop. Del flop "
        "en adelante, las ciegas van primeras.",
 idea_clave="Postflop el orden se da vuelta: la SB abre, el botón cierra. Las tres "
        "calles.",
),

# ============================================================
# 3.3 — Posición
# ============================================================

"T020": dict(  # Estar en posición
 que_es="Estás 'en posición' (IP) sobre un rival cuando actuás después que él en la "
        "calle. En 6-max, el botón está en posición sobre todos.",
 por_que_importa="Actuar último es una de las ventajas más grandes y confiables del "
        "póker. Ves qué hace el rival antes de decidir: si apuesta, si pasa, cuánto. "
        "Con esa información decidís mejor.",
 como_funciona="En posición podés: pagar o apostar con más información, controlar "
        "el tamaño del bote (si el rival pasa, podés pasar también y ver una carta "
        "gratis) y arriesgar menos cuando faroleás. No es una jugada: es una "
        "condición de la mano que te favorece.",
 cuando_lo_uso="Cuando elegís qué manos jugar: en posición podés jugar más manos, "
        "porque vas a decidir mejor en cada calle.",
 cuando_no=None,
 ejemplo="Sos el botón. En el flop, la BB pasa. Ya sabés que probablemente no tiene "
        "una mano fuerte: podés apostar para llevártelo, o pasar y ver el turn "
        "gratis. Ella nunca tiene esa información sobre vos.",
 error_comun="No aprovechar la posición. Si estás en posición y el rival pasa dos "
        "veces, muchas veces el bote es tuyo con solo apostar.",
 idea_clave="En posición = actuás último = ves antes de decidir. Es una ventaja "
        "enorme.",
),

"T021": dict(  # Estar fuera de posición
 que_es="Estás 'fuera de posición' (OOP) sobre un rival cuando actuás antes que él. "
        "Las ciegas están fuera de posición contra casi todos.",
 por_que_importa="Es lo contrario de la ventaja anterior: decidís a ciegas y el "
        "rival reacciona a vos con más información. Todo cuesta más: farolear, "
        "cobrar con una mano buena, controlar el bote.",
 como_funciona="Fuera de posición, cada vez que hablás tenés menos datos que el "
        "rival. Si pasás, le dejás el control de la apuesta; si apostás, no sabés qué "
        "va a hacer. Por eso, fuera de posición se juegan menos manos y con más "
        "cuidado.",
 cuando_lo_uso="Cuando estás en las ciegas, o cuando abriste desde una posición "
        "temprana y te pagó alguien de atrás: vas a jugar la mano de adelante.",
 cuando_no=None,
 ejemplo="Sos la BB. En el flop hablás primero contra el botón. Pases o apuestes, "
        "él decide sabiendo lo que hiciste. Esa desventaja se repite en el turn y en "
        "el river.",
 error_comun="Jugar demasiadas manos fuera de posición 'para no dejarte pisar'. "
        "Casi siempre, la respuesta correcta fuera de posición es entrar con menos "
        "manos.",
 idea_clave="Fuera de posición = actuás primero = decidís a ciegas. Menos manos, "
        "más cuidado.",
),

"T022": dict(  # Posición relativa
 que_es="La posición no se mide por el asiento a secas, sino entre los jugadores "
        "que siguen en la mano. Lo que importa es quién actúa antes y quién después "
        "de vos, ahora.",
 por_que_importa="Un mismo asiento puede estar en posición en una mano y fuera de "
        "posición en otra, según quién se quedó.",
 como_funciona="Cerrados los folds preflop, mirá quiénes quedaron y ubicá tu turno "
        "respecto de ellos para las calles que vienen. Los jugadores que ya "
        "foldearon no cuentan.",
 cuando_lo_uso="Cerrada la acción preflop, antes del flop: 'de los que quedamos, "
        "¿yo hablo antes o después?'.",
 cuando_no=None,
 ejemplo="Abrís desde el CO y solo te paga la BB. El botón y la SB foldearon: vos "
        "quedás en posición sobre la BB toda la mano, como si fueras el botón.",
 error_comun="Creer que estás fuera de posición porque 'hay gente a mi izquierda', "
        "sin fijarte en que esos jugadores ya foldearon.",
 idea_clave="La posición se cuenta entre los que siguen en la mano, no entre los "
        "asientos.",
),

# ============================================================
# 3.4 — Fichas y stacks
# ============================================================

"T023": dict(  # El stack
 que_es="Tu stack son las fichas que tenés sobre la mesa: lo máximo que podés "
        "apostar o perder en una mano.",
 por_que_importa="El stack define cuánto está en juego. No podés ganarle a un rival "
        "más de lo que el más corto de los dos tiene sobre la mesa, ni perder más de "
        "lo que trajiste.",
 como_funciona="Empezás la mano con el stack que tengas. Baja cuando apostás o "
        "pagás, y sube cuando ganás un bote. Lo que tenés fuera de la mesa (en tu "
        "cuenta, en el bolsillo) no juega: no lo podés apostar en esa mano.",
 cuando_lo_uso="Antes de cada mano importante: '¿cuánto tengo?, ¿cuánto tiene el "
        "rival?, ¿cuánto puede llegar a costar esto?'.",
 cuando_no=None,
 ejemplo="Te sentás con 200 en una mesa de ciegas 1/2. Ese es tu stack. Si perdés "
        "un bote grande y quedás en 40, ese es tu stack ahora, hasta que recargues.",
 error_comun="Pensar en 'toda tu plata' en vez de en el stack de la mano. Solo se "
        "juega lo que está sobre la mesa.",
 idea_clave="Stack = tus fichas en la mesa. Es el techo de lo que podés ganar o "
        "perder en una mano.",
),

"T024": dict(  # La ciega grande como unidad
 que_es="En el póker se mide todo en ciegas grandes (BB), no en pesos ni dólares. "
        "Tu stack, las apuestas, el bote: todo se cuenta en BB.",
 por_que_importa="Así, la misma situación se juega igual en una mesa de 1/2 que en "
        "una de 25/50. El dinero cambia; la estrategia, no. Y pensar en BB te saca la "
        "emoción de la cifra de encima.",
 como_funciona="Dividís cualquier cantidad por el tamaño de la ciega grande. Ciegas "
        "1/2: un stack de 200 son 100 BB, una apuesta de 6 son 3 BB. Ciegas 5/10: un "
        "stack de 1.000 son 100 BB, una apuesta de 30 son 3 BB. La misma foto.",
 cuando_lo_uso="Siempre: cuando leas una guía, cuando cuentes el bote, cuando midas "
        "una apuesta. En BB.",
 cuando_no=None,
 ejemplo="'Abrí a 2,5 BB desde el CO.' No importa si la ciega grande son 2 pesos o "
        "200: abrís a dos ciegas y media.",
 error_comun="Volver a pensar en dinero cuando el bote se pone grande y ponerte "
        "nervioso por la cifra. Contá en BB y decidí igual que siempre.",
 idea_clave="Todo se mide en ciegas grandes. El dinero cambia; la estrategia, no.",
),

"T025": dict(  # El stack de 100 BB
 que_es="100 ciegas grandes es el stack de referencia del póker: el 'stack "
        "completo' con el que se supone que arrancás una mano de cash.",
 por_que_importa="Casi todo lo que vas a estudiar —qué manos abrir, cuánto apostar, "
        "cuándo jugarte el stack— asume que los stacks rondan las 100 BB. Con stacks "
        "muy distintos, algunas cosas cambian.",
 como_funciona="En las mesas de cash se suele entrar con 100 BB (a veces se permite "
        "más). Si ganás manos, tu stack pasa de 100; si perdés, baja y conviene "
        "recargar a 100 para volver a jugar 'completo'.",
 cuando_lo_uso="Como vara para medir: 'tengo 140 BB, tengo margen'; 'me quedan 25 "
        "BB, estoy corto y juego distinto'.",
 cuando_no=None,
 ejemplo="Te sentás con 100 BB y el rival tiene 100 BB. Es la situación estándar: "
        "todo lo que aprendas se aplica directo.",
 error_comun="Estudiar una jugada pensada para 100 BB y aplicarla con 20 BB (o con "
        "300). Tener muchas o pocas fichas cambia qué conviene hacer.",
 idea_clave="100 BB es el stack de referencia. Casi toda la teoría lo da por "
        "sentado.",
),

"T032": dict(  # El stack efectivo
 que_es="El stack efectivo es el más chico de los dos stacks que se enfrentan en "
        "una mano. Es lo máximo que se puede llegar a jugar entre esos dos "
        "jugadores.",
 por_que_importa="Aunque vos tengas 300 BB, si el rival tiene 40, solo se pueden "
        "mover 40: el resto de tu stack no está en juego contra él. El stack efectivo "
        "es el número que importa para planear la mano.",
 como_funciona="Mirás tu stack y el del rival, y te quedás con el menor. Si hay "
        "varios jugadores en la mano, el stack efectivo contra cada uno puede ser "
        "distinto.",
 cuando_lo_uso="Antes de jugar un bote grande: 'el stack efectivo es 40 BB, así que "
        "como mucho se juegan 40, no mi stack entero'.",
 cuando_no=None,
 ejemplo="Tenés 100 BB, el rival tiene 30 BB. El stack efectivo es 30: si van los "
        "dos con todo, se juegan 30 cada uno y a vos te sobran 70 sobre la mesa.",
 error_comun="Planear una mano por tu propio stack cuando el rival tiene mucho "
        "menos. Contra un stack corto, el bote máximo es chico.",
 idea_clave="Stack efectivo = el más corto de los dos. Es el máximo que se puede "
        "jugar en la mano.",
),

# ============================================================
# 3.5 — El bote y las apuestas (checkpoint del nivel)
# ============================================================

"T026": dict(  # La ciega chica (aporte)
 que_es="Antes de que se repartan las cartas, el jugador en la ciega chica pone una "
        "apuesta obligatoria: media ciega grande en la mayoría de las mesas.",
 por_que_importa="Es una de las dos fichas que arrancan el bote. Sin las ciegas, "
        "nadie estaría obligado a poner nada y todos esperarían solo manos enormes: "
        "no habría juego.",
 como_funciona="La SB pone su aporte a ciegas, sin ver las cartas —por eso se llama "
        "'ciega'—. Si después decide seguir en la mano, esa media ciega ya cuenta "
        "como parte de lo que puso.",
 cuando_lo_uso="Cuando estás en la SB: ya tenés media ciega en el bote antes de "
        "decidir nada.",
 cuando_no=None,
 ejemplo="Ciegas 1/2. La SB pone 1 (media ciega grande). Si todos foldean hasta "
        "ella y ella también foldea, pierde ese 1 y nada más.",
 error_comun="Sentir que la ciega chica 'ya está pagada' y por eso completar "
        "siempre. Si te vas perdés media ciega; pagar de más con manos malas cuesta "
        "mucho más.",
 idea_clave="La SB pone media ciega grande obligatoria, a ciegas. Es una de las dos "
        "fichas que arrancan el bote.",
),

"T027": dict(  # La ciega grande (aporte)
 que_es="El jugador en la ciega grande pone, antes del reparto, una apuesta "
        "obligatoria de una ciega grande entera (1 BB). Es la apuesta mínima de "
        "referencia de la mano.",
 por_que_importa="Es la otra ficha que arranca el bote, y fija el precio de "
        "entrada: para jugar preflop, todos tienen que igualar por lo menos esa ciega "
        "grande.",
 como_funciona="La BB pone 1 BB a ciegas. Si nadie sube, ya 'pagó' su entrada y "
        "tiene la opción de pasar y ver el flop, o subir. Si alguien sube, para "
        "seguir completa la diferencia.",
 cuando_lo_uso="En la BB ya tenés 1 BB puesto: eso te abarata seguir cuando te "
        "suben.",
 cuando_no=None,
 ejemplo="Ciegas 1/2. La BB pone 2 (una ciega grande). Nadie sube: la BB pasa y ve "
        "el flop sin poner una ficha más.",
 error_comun="Foldear la BB ante una subida chica sin pensar. Ya pusiste una ciega: "
        "muchas veces el precio para seguir es bueno.",
 idea_clave="La BB pone 1 BB obligatorio. Fija el precio mínimo para jugar "
        "preflop.",
),

"T028": dict(  # El bote (pot)
 que_es="El bote es el montón de fichas en el centro de la mesa: todo lo que se "
        "apostó en la mano hasta ahora. Se lo lleva el ganador.",
 por_que_importa="El bote es el premio. Su tamaño decide cuánto vale la pena "
        "arriesgar para llevártelo: cuanto más grande, más peleado.",
 como_funciona="Arranca con las dos ciegas. Cada vez que alguien apuesta, paga o "
        "sube, esas fichas van al bote. Al final de la mano, el bote entero va para "
        "el ganador (o se reparte si hay empate).",
 cuando_lo_uso="Todo el tiempo: antes de cada decisión mirás cuánto hay en el "
        "bote.",
 cuando_no=None,
 ejemplo="La SB pone 0,5 BB, la BB pone 1 BB: bote 1,5 BB. UTG abre a 3 BB y la BB "
        "paga (pone 2 BB más, hasta 3). La SB foldea. Bote: 0,5 + 1 + 3 + 2 = 6,5 BB "
        "antes del flop.",
 error_comun="Perder de vista el bote y decidir 'por sensación'. El tamaño del bote "
        "es un dato duro que tenés que tener siempre.",
 idea_clave="El bote = todo lo apostado, en el centro. Es el premio de la mano.",
),

"T029": dict(  # El tamaño del bote
 que_es="Saber leer, en cualquier momento de la mano, cuántas fichas hay en el "
        "bote — y mantener esa cuenta actualizada mano tras mano, con varios "
        "jugadores y varias calles de por medio.",
 por_que_importa="Casi todas las decisiones importantes se comparan contra el "
        "tamaño del bote: cuánto apostar, si vale la pena pagar. Si no sabés cuánto "
        "hay, estás adivinando — y con más de un jugador pagando en cada calle, "
        "es fácil perder la cuenta.",
 como_funciona="En cada calle nueva, sumás lo que ya traía el bote más TODO lo "
        "que se apostó y se pagó en esa ronda — si pagaron dos o tres jugadores, "
        "cada pago suma por separado. Muchas salas te muestran el número, pero "
        "conviene saber contarlo solo.",
 cuando_lo_uso="Antes de cada apuesta o pago, sobre todo del flop en adelante, y "
        "en botes con más de dos jugadores todavía activos.",
 cuando_no=None,
 ejemplo="El bote llega al flop con 6 BB y quedan TRES jugadores. El que abrió "
        "apuesta 3 BB y los otros dos pagan: 6 + 3 + 3 + 3 = 15 BB. En el turn, "
        "apuesta 8 BB y esta vez paga un solo rival (el otro foldea): "
        "15 + 8 + 8 = 31 BB para el river.",
 error_comun="Sumar una sola vez el pago de un jugador cuando en realidad pagaron "
        "varios, o contar solo la última apuesta y olvidar lo que ya venía "
        "acumulado de calles anteriores.",
 idea_clave="El tamaño del bote se recalcula en cada calle: lo que ya había, más "
        "CADA pago de esa ronda — no un solo pago si hay varios jugadores.",
),

"T030": dict(  # La apuesta
 que_es="Una apuesta es poner fichas en el bote por decisión propia, no obligada "
        "como las ciegas. Incluye abrir, apostar en una calle, pagar y subir.",
 por_que_importa="Cada apuesta que hacés o que pagás sale de tu stack y va al bote. "
        "Es la moneda con la que se juega: entender qué te cuesta cada apuesta es el "
        "principio de jugar bien.",
 como_funciona="Cuando apostás, elegís el monto (dentro de lo que permita la mesa). "
        "Los demás deciden pagar (poner lo mismo), subir (poner más) o foldear. El "
        "tamaño se suele expresar en relación al bote: 'media apuesta al bote', "
        "'apuesta del tamaño del bote'.",
 cuando_lo_uso="En cada calle, cuando te toca: '¿apuesto?, ¿cuánto?, ¿qué me cuesta "
        "si me pagan o me suben?'.",
 cuando_no=None,
 ejemplo="El bote es 20 BB. Apostás 10 BB: es 'media apuesta al bote'. Si el rival "
        "paga, pone 10 y el bote pasa a 40.",
 error_comun="Elegir el tamaño de la apuesta al azar. El monto tiene que tener una "
        "razón; por ahora, alcanzá con medirlo siempre en relación al bote.",
 idea_clave="Apuesta = fichas que ponés por decisión propia. Medila en relación al "
        "bote.",
),

"T031": dict(  # El coste de una decisión
 que_es="Cada vez que pagás, apostás o subís, esa decisión te cuesta fichas. "
        "Empezá a mirar cada jugada como una compra: pago X para poder ganar Y.",
 por_que_importa="Es la base de todo lo que viene. Foldear cuesta 0. Pagar cuesta "
        "lo que valga la apuesta. Antes de poner una ficha, la pregunta siempre es: "
        "'¿lo que puedo ganar justifica lo que me cuesta?'.",
 como_funciona="Ponés en la balanza dos cosas: lo que te cuesta seguir (la apuesta "
        "que tenés delante) y lo que podés llevarte (el bote, más lo que el rival "
        "ponga después). Todavía no hace falta ningún cálculo fino: alcanza con "
        "acostumbrarte a hacerte la pregunta.",
 cuando_lo_uso="Antes de cada pago y de cada apuesta, sin excepción.",
 cuando_no=None,
 ejemplo="El bote es 20 BB y el rival apuesta 10. Seguir te cuesta 10 y podés ganar "
        "30 (los 20 del bote + sus 10). Con eso sobre la mesa: ¿tu mano gana "
        "suficientes veces como para que valga la pena? Esa pregunta se aprende a "
        "responder en el Nivel 6.",
 error_comun="Pagar sin pensar en el precio, solo porque 'quiero ver'. Cada pago "
        "que no se justifica es una fuga.",
 idea_clave="Toda decisión tiene un precio. Foldear cuesta 0. Antes de pagar, "
        "pensá qué ganás y qué te cuesta.",
),

}
