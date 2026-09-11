# -*- coding: utf-8 -*-
"""
PASO 4 — Contenido redactado del NIVEL 1: "Cómo funciona una mano".
25 teorías, 4 subniveles. Voz: un buen profesor de póker a alguien que
empieza. Completo, no largo. Español rioplatense (vos / tenés).

Campos por teoría: que_es, por_que_importa, como_funciona, cuando_lo_uso,
cuando_no, ejemplo, error_comun, idea_clave. None = no aplica.

Vocabulario: se permite un término antes de su teoría formal si es natural,
se entiende por contexto y (si puede confundir) lleva una glosa breve. Su
DEFINICIÓN formal debe llegar antes de que una teoría más avanzada dependa
de él. No convertir esto en un diccionario.

Orden de 1.2 (cerrado): T008 showdown → T009 ganar por cartas → T010 ganar
porque el rival foldea.
"""

N1 = {

# ============================================================
# 1.1 — El objetivo y las cartas
# ============================================================

"T001": dict(  # Objetivo del juego
 que_es="El póker es un juego de apuestas con cartas. En cada mano, los jugadores "
        "van poniendo fichas en el centro de la mesa: ese montón se llama BOTE. "
        "El objetivo de la mano es llevarte el bote.",
 por_que_importa="Todo lo que vas a aprender —cuándo apostar, cuándo retirarte, qué "
        "manos jugar— existe para una sola cosa: ganar fichas a la larga. Si perdés "
        "de vista el objetivo, cada decisión se vuelve un capricho.",
 como_funciona="La mano se juega por rondas. En cada ronda, los jugadores que siguen "
        "apuestan, igualan o se retiran. La mano termina de dos formas: queda un solo "
        "jugador (los demás se retiraron) o los que quedan muestran las cartas. En los "
        "dos casos, el bote entero va para uno.",
 cuando_lo_uso="Siempre. Antes de cada decisión, preguntate: ¿esto me acerca a ganar "
        "el bote, o me está costando fichas sin necesidad?",
 cuando_no=None,
 ejemplo="Hay 8 fichas en el bote. Tu rival apuesta 4 más. Si pagás y ganás, te "
        "llevás 16. Si te retirás, perdés lo que ya pusiste pero no arriesgás más. "
        "Toda la tensión del póker está ahí: cuánto arriesgar para llevarte el bote.",
 error_comun="Jugar para 'ganar esta mano' a toda costa. No querés ganar todas las "
        "manos: querés ganar fichas. A veces la mejor jugada es tirar y perder un "
        "bote chico.",
 idea_clave="Ganás fichas ganando botes. No hace falta ganar todas las manos.",
),

"T002": dict(  # La baraja
 que_es="Se juega con una baraja de 52 cartas: 13 valores (2, 3, 4, 5, 6, 7, 8, 9, "
        "10, J, Q, K, A) en 4 palos (picas ♠, corazones ♥, diamantes ♦, tréboles ♣).",
 por_que_importa="Saber qué cartas existen y cuántas quedan por salir es la base de "
        "todo lo que viene después: cuánto vale tu mano, qué puede tener el rival, "
        "qué carta te ayudaría.",
 como_funciona="Los valores van del 2 (el más bajo) al As (el más alto). El As "
        "también puede hacer de carta más baja en una escalera A-2-3-4-5. Los 4 palos "
        "valen lo mismo entre sí: ninguno le gana a otro.",
 cuando_lo_uso="Cada vez que pensás '¿qué carta me ayudaría?' o '¿qué puede tener el "
        "rival?', estás contando cartas de la baraja.",
 cuando_no=None,
 ejemplo="Hay 4 ases en la baraja. Si vos tenés uno en la mano, quedan 3 dando "
        "vueltas: en el centro de la mesa, en la mano de un rival, o todavía en el "
        "mazo.",
 error_comun="Creer que un palo vale más que otro. Cinco picas y cinco tréboles "
        "valen exactamente lo mismo; lo que decide es el valor de las cartas.",
 idea_clave="52 cartas: 13 valores × 4 palos. El As es la más alta (y a veces la más "
        "baja).",
),

"T003": dict(  # Cartas privadas
 que_es="Al empezar la mano, cada jugador recibe 2 cartas boca abajo que solo ve él. "
        "Son tus cartas privadas (también: 'tu mano' o 'hole cards').",
 por_que_importa="Son tu información secreta. El póker es un juego de información "
        "incompleta: vos sabés tus 2 cartas, el rival sabe las suyas, y nadie ve las "
        "del otro. Toda la ventaja está en usar bien lo que sabés y estimar lo que no.",
 como_funciona="Las 2 cartas privadas se combinan con las 5 comunitarias del centro. "
        "Podés usar las 2, 1 o ninguna: siempre se arma la mejor mano de 5 cartas "
        "posible con las 7 disponibles.",
 cuando_lo_uso="Antes de que salga cualquier carta común, tus 2 cartas son toda la "
        "información que tenés. Elegir bien qué manos jugar y cuáles tirar es la "
        "decisión más rentable del póker.",
 cuando_no=None,
 ejemplo="Tenés A♠ K♠. Son dos cartas altas y del mismo palo: una mano fuerte para "
        "entrar. Con 7♦ 2♣ tenés la peor mano posible: casi siempre se tira.",
 error_comun="Enamorarte de cualquier mano solo porque es tuya. La mayoría de las "
        "manos que recibís no valen la pena jugarlas.",
 idea_clave="2 cartas que solo ves vos. Son tu información: usala bien y no juegues "
        "cualquier cosa.",
),

"T004": dict(  # Cartas comunitarias
 que_es="Son 5 cartas que se abren boca arriba en el centro de la mesa, a lo largo "
        "de la mano. Las comparten TODOS los jugadores. También se las llama 'el "
        "board'.",
 por_que_importa="Como son de todos, cambian la mano de todos a la vez. Una carta "
        "que te ayuda a vos también puede ayudar al rival. Leer bien el board es "
        "medio juego.",
 como_funciona="No salen todas juntas: primero 3 (el flop), después 1 (el turn) y "
        "por último 1 (el river). Entre carta y carta hay una ronda de apuestas.",
 cuando_lo_uso="Cada vez que sale una carta nueva en el centro, volvé a mirar el "
        "board: ¿mejoró tu mano?, ¿la de un rival?, ¿esta carta ayuda más a vos o "
        "a él?",
 cuando_no=None,
 ejemplo="Board: K♥ 8♥ 3♣. Tenés K♠ Q♠: pareja de reyes. Pero hay dos corazones en "
        "la mesa: si alguien tiene dos corazones más, le falta uno para cinco del "
        "mismo palo.",
 error_comun="Mirar solo si el board te ayudó a vos. El board es de los dos: siempre "
        "preguntate qué le pudo dar al rival.",
 idea_clave="5 cartas de todos, en el centro. Salen 3 + 1 + 1. Cambian la mano de "
        "todos.",
),

"T005": dict(  # La mano de 5 cartas
 que_es="Tu mano final son las 5 mejores cartas que podés armar entre tus 2 privadas "
        "y las 5 comunitarias. Nunca son más de 5 cartas.",
 por_que_importa="Al final de la mano se comparan manos de 5 cartas. Saber cuál es "
        "tu mejor combinación —y si de verdad usás tus cartas o no— es lo que te dice "
        "si vas ganando o perdiendo.",
 como_funciona="Tenés 7 cartas disponibles (2 + 5). Elegís las 5 que forman la mejor "
        "combinación y descartás las otras 2. Podés terminar usando tus 2 cartas, "
        "solo 1, o ninguna (jugando el board).",
 cuando_lo_uso="Antes de decidir en la última calle, armá mentalmente tu mejor mano "
        "de 5 y compará con lo que podría tener el rival.",
 cuando_no=None,
 ejemplo="Tenés A♠ 5♦. Board: A♥ K♦ 9♣ 7♠ 2♠. Tu mejor mano de 5: A♠ A♥ K♦ 9♣ 7♠ "
        "(pareja de ases). Las picas no alcanzan para cinco del mismo palo: solo "
        "tenés 3.",
 error_comun="Contar 6 o 7 cartas como si formaran una 'súper mano'. Siempre son 5, "
        "ni una más.",
 idea_clave="Tu mano son las 5 mejores de las 7 disponibles. El resto no cuenta.",
),

# ============================================================
# 1.2 — Ganar la mano
# Orden: showdown → ganar por cartas → ganar porque el rival foldea.
# ============================================================

"T008": dict(  # El showdown
 que_es="El showdown es el momento, al final de la mano, en que los jugadores que "
        "quedan dan vuelta sus cartas para ver quién gana.",
 por_que_importa="Es el juicio final de la mano: acá se define quién se lleva todo "
        "lo apostado. Saber si vas a llegar al showdown —y con qué mano— cambia todas "
        "las decisiones anteriores.",
 como_funciona="Ocurre solo si al menos dos jugadores llegan al final sin retirarse. "
        "Se comparan las mejores manos de 5 cartas y gana la más alta. Si hay empate "
        "exacto, el bote se reparte.",
 cuando_lo_uso="Todo el tiempo pensás en el showdown: '¿esta mano quiere llegar a "
        "mostrar, o me conviene ganar antes, haciendo que el rival se retire?'",
 cuando_no="Si todos menos uno se retiran (fold) antes del final, no hay showdown: "
        "nadie muestra y el bote va para el que quedó.",
 ejemplo="Dos jugadores llegan al final. Uno tiene pareja de ases; el otro, pareja "
        "de reyes. En el showdown gana la pareja de ases: se lleva el bote.",
 error_comun="Creer que el que apostó último 'gana automáticamente'. En el showdown "
        "gana la mejor mano de 5, no la última apuesta.",
 idea_clave="Showdown = se muestran las cartas. Gana la mejor mano de 5; empate "
        "exacto, bote repartido.",
),

"T009": dict(  # Ganar por cartas
 que_es="Ganás 'por cartas' cuando la mano llega al showdown y tu mano de 5 es la "
        "más alta. Es la forma más intuitiva de ganar: tenés lo mejor y cobrás.",
 por_que_importa="Es una de las dos únicas maneras de llevarte el bote. Para ganar "
        "así necesitás cartas de verdad: no alcanza con haber apostado fuerte.",
 como_funciona="Cerrada la última ronda de apuestas, los jugadores que quedan "
        "muestran. Se compara la mejor mano de 5 de cada uno y el bote va para la "
        "más alta.",
 cuando_lo_uso="Cuando tenés una mano fuerte, jugás para llegar al showdown: "
        "apostás para que el rival pague con manos peores y así cobrar más.",
 cuando_no="Con una mano floja no querés llegar al showdown: vas a perder la "
        "comparación. Ahí tu única chance es que el rival se retire.",
 ejemplo="Tenés pareja de reyes; el rival, pareja de ochos. Llegan los dos al final "
        "y muestran: tu pareja es más alta, el bote es tuyo.",
 error_comun="Pagar la última apuesta 'para ver' con una mano que no le gana a nada. "
        "Si no podés ganar la comparación, ese pago es tirar fichas.",
 idea_clave="Ganar por cartas = mostrar la mejor mano de 5 al final. Necesitás mano "
        "de verdad.",
),

"T010": dict(  # Ganar porque el rival foldea
 que_es="Ganás 'por fold' cuando todos los demás se retiran y quedás solo en la "
        "mano. El bote es tuyo sin mostrar las cartas.",
 por_que_importa="Es la otra forma de ganar el bote, y es enorme: podés llevarte "
        "manos sin tener nada, solo apostando de forma que al rival no le convenga "
        "seguir. Esto es lo que hace del póker un juego de decisiones y no de suerte.",
 como_funciona="Si apostás y todos se retiran, la mano termina ahí. No importa qué "
        "cartas tenías: nadie las ve y el bote va para vos.",
 cuando_lo_uso="Cuando tu mano es floja pero la historia que contás con tus apuestas "
        "es creíble y el rival tiene una mano con la que le duele pagar.",
 cuando_no="Contra un rival que paga siempre: si nunca se retira, farolear "
        "—apostar fuerte con una mano floja para que abandone— no sirve. Contra ese "
        "rival ganás solo por cartas.",
 ejemplo="El board muestra A♠ K♦ 4♣. Vos no ligaste nada, pero apostás como si "
        "tuvieras un as. El rival tiene una pareja chica, no le gusta ese board y se "
        "retira. Ganaste el bote con la peor mano.",
 error_comun="Farolear sin pensar en qué puede tener el rival. Si su mano es fuerte, "
        "no se va a ir, y vas a perder fichas de más.",
 idea_clave="Ganar por fold = todos se retiran. Se puede ganar el bote sin tener "
        "nada.",
),

# ============================================================
# 1.3 — Las acciones
# ============================================================

"T033": dict(  # Fold
 que_es="Foldear (o 'tirar', 'retirarse') es abandonar la mano. Devolvés tus cartas "
        "y perdés cualquier derecho al bote.",
 por_que_importa="Es la acción más usada y más subestimada. Foldear a tiempo te "
        "ahorra montañas de fichas. Un jugador ganador foldea mucho.",
 como_funciona="Podés foldear cuando hay una apuesta delante tuyo y no querés "
        "pagarla. Las fichas que ya pusiste quedan en el bote: no se devuelven.",
 cuando_lo_uso="Cuando el precio para seguir es más alto que lo que vale tu mano. "
        "Antes del flop: con manos flojas. Después: cuando el rival apuesta y tu mano "
        "no aguanta.",
 cuando_no="No foldees si no hay ninguna apuesta delante: eso es tirar una mano "
        "gratis. Ahí lo correcto es hacer check (pasar sin apostar).",
 ejemplo="Recibís 9♦ 4♠ y sos de los primeros en hablar. Es una mano mala: foldeás "
        "sin pensarlo dos veces y esperás una mejor.",
 error_comun="No foldear porque 'ya puse fichas'. Las fichas del bote ya no son "
        "tuyas: pagar de más para no 'perderlas' es cómo se pierde de verdad.",
 idea_clave="Foldear = abandonar la mano. Es gratis cuando no hay apuesta; si la "
        "hay, perdés lo ya puesto. Foldeá seguido.",
),

"T034": dict(  # Check
 que_es="Hacer check (o 'pasar') es no apostar cuando nadie apostó antes que vos. "
        "Seguís en la mano sin poner fichas.",
 por_que_importa="Te deja ver la carta siguiente gratis y controlar el tamaño del "
        "bote. Es la acción por defecto cuando tu mano no es lo bastante fuerte para "
        "apostar ni lo bastante débil para tirar.",
 como_funciona="Solo podés hacer check si no hay ninguna apuesta delante tuyo en "
        "esa ronda. Si todos hacen check, la ronda termina y sale la carta siguiente.",
 cuando_lo_uso="Con manos medias que no quieren agrandar el bote, con una mano a "
        "medio hacer que quiere ver la próxima carta gratis, o para tenderle una "
        "trampa a un rival agresivo.",
 cuando_no="No hagas check con una mano muy fuerte en un board peligroso: ahí querés "
        "apostar para cobrar antes de que una carta mala te empeore la mano.",
 ejemplo="Board: J♠ 7♦ 2♣. Tenés A♥ Q♦: no ligaste nada, pero tampoco querés tirar. "
        "Hacés check y ves el turn gratis.",
 error_comun="Confundir check con call. Check es 'paso, no pongo nada'; call es "
        "'pago lo que hay delante'. Si hay una apuesta, no podés hacer check.",
 idea_clave="Check = pasar sin apostar, cuando nadie apostó. Ves la carta siguiente "
        "gratis.",
),

"T035": dict(  # Call
 que_es="Hacer call (o 'igualar', 'pagar') es poner exactamente la misma cantidad "
        "que la apuesta que tenés delante, para seguir en la mano.",
 por_que_importa="Es cómo continuás sin subir la apuesta. Pero cada call cuesta "
        "fichas: pagar de más con manos flojas es una de las fugas más grandes de un "
        "principiante.",
 como_funciona="Igualás el monto de la última apuesta. Si nadie sube después, la "
        "ronda se cierra y sale la carta siguiente.",
 cuando_lo_uso="Cuando tu mano es buena para seguir pero no lo bastante fuerte para "
        "subir, o cuando estás esperando una carta que te haría ganar y el precio "
        "para seguir viéndola es razonable.",
 cuando_no="No pagues 'por curiosidad' o 'para ver qué tenía'. Si tu mano no le gana "
        "a casi nada de lo que el rival podría tener, foldeá.",
 ejemplo="El rival apuesta 5 en el flop. Tenés una pareja media y querés seguir "
        "viendo, pero no subir. Hacés call de 5.",
 error_comun="Pagar la última apuesta solo para no quedarte con la duda. Un call de "
        "curiosidad que no gana nunca es tirar fichas.",
 idea_clave="Call = igualar la apuesta para seguir. Cada call cuesta: no pagues "
        "cualquier cosa.",
),

"T036": dict(  # Bet
 que_es="Hacer bet (o 'apostar') es ser el primero en poner fichas en una ronda. "
        "Con eso obligás a los demás a pagar, subir o retirarse.",
 por_que_importa="Apostar es cómo ganás fichas: cobrás con las manos buenas y hacés "
        "retirar a los rivales cuando no querés que sigan. El que apuesta marca el "
        "ritmo de la mano.",
 como_funciona="Elegís un monto (dentro de lo que permita la mesa) y lo ponés en el "
        "bote. Los rivales, uno por uno, deciden qué hacer con tu apuesta.",
 cuando_lo_uso="Con manos fuertes que quieren pago. Con manos flojas que se "
        "benefician de que el rival se retire. Rara vez con manos medias.",
 cuando_no="Con una mano media que no le gana a lo que te va a pagar ni hace "
        "retirar a lo que te gana: esa mano prefiere hacer check.",
 ejemplo="Ligás trío (tres cartas iguales) en el flop. Apostás para que el rival, "
        "que tiene pareja alta, pague. Cada ficha que te pague es tuya.",
 error_comun="Apostar 'porque sí', sin saber qué querés lograr. Antes de apostar, "
        "tené claro si buscás que te paguen o que se retiren.",
 idea_clave="Bet = ser el primero en apostar. Apostás para que te paguen (mano "
        "fuerte) o para que se retiren (mano floja).",
),

"T037": dict(  # Raise
 que_es="Hacer raise (o 'subir') es aumentar una apuesta que ya está sobre la mesa. "
        "Ponés más que la apuesta anterior.",
 por_que_importa="Subir es la jugada más fuerte: pone presión, hace crecer el bote "
        "rápido y te pone al mando de la acción. También es cara si te equivocás.",
 como_funciona="Tenés que subir al menos otro tanto de lo que había que pagar (subir "
        "'un poquito' no está permitido; la regla exacta la ves en la mesa). Los "
        "rivales vuelven a decidir: pagar tu subida, volver a subir o retirarse.",
 cuando_lo_uso="Con manos muy fuertes que quieren un bote grande. O para hacer "
        "retirar al rival cuando la subida cuenta una historia creíble y él tiene una "
        "mano con la que le duele pagar.",
 cuando_no="No subas con manos medias 'para definir': si te vuelven a subir, quedás "
        "jugando un bote grande con una mano que no aguanta.",
 ejemplo="El rival abre a 3. Tenés A♠ A♦ (la mejor mano antes del flop). Subís a 9 "
        "para agrandar el bote desde el principio.",
 error_comun="Subir con una mano que solo hace pagar a lo que te gana y retirarse a "
        "lo que le ganás. Antes de subir, pensá: '¿quién me paga y quién se va?'",
 idea_clave="Raise = subir una apuesta existente. Es la jugada más fuerte: mano "
        "grande, o presión con una historia creíble.",
),

"T038": dict(  # Re-raise
 que_es="Un re-raise es subir por encima de una subida. Es decir: alguien apostó, "
        "otro subió, y vos volvés a subir.",
 por_que_importa="Cada nueva subida achica muchísimo el abanico de manos con las que "
        "tiene sentido seguir: el bote y la presión escalan. Cuando alguien vuelve a "
        "subir, casi siempre tiene algo muy fuerte.",
 como_funciona="Antes del flop, la primera subida se llama 'open raise', la "
        "re-subida '3-bet' y la siguiente '4-bet'. Cada escalón representa una mano "
        "más fuerte. Cómo y cuándo usarlas es todo el Nivel 7.",
 cuando_lo_uso="Con tus mejores manos. Como jugada de presión, solo si tenés un plan "
        "claro. Por ahora alcanza con reconocerla cuando la ves.",
 cuando_no="No vuelvas a subir 'porque me molesta que suban'. Sin una mano fuerte o "
        "un plan, solo agrandás tu pérdida.",
 ejemplo="UTG abre a 3. El botón sube a 9 (una 3-bet). Vos, en la ciega grande, "
        "tenés A♠ A♦ y volvés a subir a 27 (una 4-bet).",
 error_comun="Tratar toda re-subida del rival como un engaño. La mayoría de las "
        "veces es una mano enorme: respetala hasta tener razones para no hacerlo.",
 idea_clave="Re-raise = subir sobre una subida. Cada escalón = manos más fuertes.",
),

"T039": dict(  # All-in
 que_es="Ir all-in es apostar todas las fichas que tenés en la mesa en una sola "
        "jugada.",
 por_que_importa="Es la apuesta máxima y sin vuelta atrás. Define la mano: si te "
        "pagan, se muestran las cartas y no hay más decisiones. Usarla bien o mal "
        "cambia sesiones enteras.",
 como_funciona="Ponés tu stack entero (todas tus fichas en la mesa). Si un rival "
        "tiene menos y paga, solo se juega lo que él pueda cubrir; el resto vuelve a "
        "vos. Nunca podés perder más de lo que tenés en la mesa.",
 cuando_lo_uso="Cuando te quedan pocas fichas y tenés una mano fuerte. O con una "
        "mano a medio hacer con mucho potencial, que prefiere jugarse todo ahora "
        "antes que pagar apuestas incómodas después.",
 cuando_no="Con un stack profundo y una pareja media: ir all-in te hace ganar un "
        "bote chico o perder uno enorme. El all-in liviano es de los errores más "
        "caros.",
 ejemplo="Te quedan 12 ciegas grandes y tenés A♠ K♦. En vez de abrir chico, vas "
        "all-in: presionás fuerte y te evitás decisiones difíciles después del flop.",
 error_comun="Ir all-in 'para no pensar'. El all-in resuelve la mano, pero si lo "
        "hacés con la mano equivocada, la resuelve en contra tuya.",
 idea_clave="All-in = todas tus fichas. Máxima presión, cero vuelta atrás. Nunca "
        "perdés más de lo que tenés en la mesa.",
),

"T040": dict(  # Acción cerrada
 que_es="La acción está 'cerrada' cuando todos los jugadores que siguen en la mano "
        "igualaron la última apuesta (o hicieron check). Ahí termina la ronda.",
 por_que_importa="Saber cuándo se cierra una ronda te dice cuándo sale la carta "
        "siguiente y cuándo te toca volver a decidir. Es el ritmo de la mano.",
 como_funciona="La ronda sigue hasta que la acción vuelve al último que apostó o "
        "subió sin que nadie más suba. Si todos pasan, también se cierra. Recién "
        "entonces sale la próxima carta comunitaria (o se llega al showdown).",
 cuando_lo_uso="Cuando estás por actuar, fijate si tu decisión cierra la acción o si "
        "todavía quedan jugadores por hablar detrás tuyo: eso cambia el riesgo.",
 cuando_no=None,
 ejemplo="En el flop: vos apostás 5, el rival paga 5. Nadie más queda. La acción "
        "está cerrada: sale el turn.",
 error_comun="Creer que después de tu call ya salió la carta, cuando todavía hay "
        "jugadores detrás que pueden subir. La ronda no se cierra hasta que todos "
        "hablaron.",
 idea_clave="La ronda se cierra cuando todos igualaron o pasaron. Recién ahí sale "
        "la carta siguiente.",
),

"T041": dict(  # Acción legal
 que_es="En cada turno, solo algunas acciones están permitidas. Qué podés hacer "
        "depende de si hay una apuesta delante tuyo o no.",
 por_que_importa="Antes de decidir, tenés que saber qué opciones tenés. Las reglas "
        "son simples, pero hay que tenerlas claras para no perder el hilo de la mano.",
 como_funciona="Si NO hay apuesta delante: podés hacer check o bet. Si SÍ hay una "
        "apuesta delante: podés foldear, hacer call o hacer raise. Nunca podés hacer "
        "check con una apuesta enfrente, ni call si nadie apostó.",
 cuando_lo_uso="Cada vez que te toca actuar: primero mirá si hay apuesta delante, y "
        "eso te dice tus 2 o 3 opciones.",
 cuando_no=None,
 ejemplo="Nadie apostó en el flop y te toca: tus opciones son check o bet. El rival "
        "apuesta 4 y te toca de nuevo: ahora son fold, call de 4 o raise.",
 error_comun="Pedir 'check' cuando ya hay una apuesta sobre la mesa. Con apuesta "
        "delante, tus únicas salidas son pagar, subir o irte.",
 idea_clave="Sin apuesta delante: check o bet. Con apuesta delante: fold, call o "
        "raise.",
),

"T042": dict(  # El orden de acción
 que_es="En cada ronda, los jugadores actúan de a uno, en un orden fijo alrededor "
        "de la mesa. No se habla 'cuando uno quiere'.",
 por_que_importa="El que actúa último ve lo que hicieron todos los demás antes de "
        "decidir. Esa diferencia de información —la posición— es una de las ventajas "
        "más grandes del póker. La estudiás en el Nivel 3.",
 como_funciona="Antes del flop, la acción arranca a la izquierda de las ciegas y da "
        "la vuelta. Después del flop, arranca en la primera ciega que siga en la "
        "mano. Siempre el mismo sentido, siempre de a uno.",
 cuando_lo_uso="Antes de actuar, fijate cuántos jugadores hablan después tuyo: "
        "cuantos más, más cuidado (cualquiera puede tener una mano fuerte).",
 cuando_no=None,
 ejemplo="Sos el primero en hablar en el flop, con varios jugadores detrás. Aunque "
        "tengas una mano decente, tenés que decidir a ciegas: cualquiera de ellos "
        "puede todavía subir.",
 error_comun="Actuar sin registrar quién ya habló y quién falta. La misma mano se "
        "juega distinto según si sos el primero o el último en decidir.",
 idea_clave="Se actúa de a uno, en orden fijo. Actuar último = decidir con más "
        "información.",
),

# ============================================================
# 1.4 — Las cuatro calles
# ============================================================

"T043": dict(  # El preflop
 que_es="El preflop es la primera ronda de apuestas, antes de que salga ninguna "
        "carta comunitaria. Solo tenés tus 2 cartas privadas.",
 por_que_importa="Es la decisión más frecuente del póker: la tomás en cada mano. "
        "Elegir bien qué manos jugar y cuáles tirar preflop es lo que más separa a un "
        "ganador de un perdedor.",
 como_funciona="Ya hay fichas en el bote (las ciegas). La acción empieza a la "
        "izquierda de la ciega grande. Cada jugador foldea, iguala la ciega o sube. "
        "Cuando se cierra la ronda, sale el flop.",
 cuando_lo_uso="En cada mano. La mayoría de las veces, tu decisión preflop es "
        "foldear — y está bien.",
 cuando_no=None,
 ejemplo="Recibís K♠ Q♠ en el botón. Nadie subió antes que vos. Abrís subiendo a "
        "2,5 ciegas: es una buena mano y estás en buena posición.",
 error_comun="Jugar demasiadas manos preflop. Entrar con manos flojas te mete en "
        "problemas en todas las calles siguientes.",
 idea_clave="Preflop = primera ronda, solo tus 2 cartas. Elegí bien qué jugar: casi "
        "siempre, foldear.",
),

"T044": dict(  # El flop
 que_es="El flop son las primeras 3 cartas comunitarias, que se abren juntas después "
        "de que se cierra la ronda preflop.",
 por_que_importa="El flop define la mano: pasás de 2 cartas a 5 disponibles. Acá se "
        "decide si conectaste con el board, si tenés algo armándose, o si te toca "
        "soltar.",
 como_funciona="Se abren las 3 cartas de golpe. Empieza una nueva ronda de apuestas, "
        "esta vez desde la primera ciega que siga en la mano (después del flop, la SB "
        "habla primero).",
 cuando_lo_uso="Apenas ves el flop, leelo: ¿te ayudó?, ¿tenés algo hecho o algo "
        "armándose?, ¿esas 3 cartas le pegan más a tu mano o a la del rival?",
 cuando_no=None,
 ejemplo="Tenés A♥ K♥. Flop: K♠ 9♥ 4♥. Emparejaste tu rey y, además, hay tres "
        "corazones entre tu mano y la mesa: te falta uno para tener cinco del mismo "
        "palo. Un flop que te encanta.",
 error_comun="Seguir en la mano solo porque 'todavía puede venir mi carta'. Si el "
        "flop no te dio nada y no hay nada real armándose, casi siempre es momento de "
        "soltar.",
 idea_clave="Flop = 3 cartas comunitarias juntas. Acá se define casi todo: leé el "
        "board antes de decidir.",
),

"T045": dict(  # El turn
 que_es="El turn es la cuarta carta comunitaria. Sale sola, después de la ronda de "
        "apuestas del flop.",
 por_que_importa="Es la calle donde el bote suele hacerse grande y las decisiones "
        "más caras. Una sola carta puede terminar de armar una mano o cambiar quién "
        "va ganando.",
 como_funciona="Se abre 1 carta y empieza una nueva ronda de apuestas. Ya quedan "
        "menos cartas por venir: una mano que todavía no está hecha tiene una sola "
        "carta más para completarse.",
 cuando_lo_uso="En el turn, volvé a mirar todo: ¿la carta ayudó a alguno?, ¿sigo "
        "con la mejor mano?, ¿lo que estoy esperando todavía justifica pagar?",
 cuando_no=None,
 ejemplo="Flop: 8♠ 7♦ 2♣. Turn: 6♥. Con 5-4 en la mano, la mesa te da cinco cartas "
        "seguidas (8-7-6-5-4). Si en cambio tenías pareja de ochos, ahora esas cinco "
        "seguidas son posibles para otro y tu mano vale menos. Una sola carta cambió "
        "todo.",
 error_comun="Jugar el turn con el mismo plan que el flop sin actualizar. La carta "
        "nueva cambió la mano: pensala de nuevo.",
 idea_clave="Turn = la 4ª carta comunitaria. Bote grande, decisiones caras, una "
        "chance menos para las manos sin terminar.",
),

"T046": dict(  # El river
 que_es="El river es la quinta y última carta comunitaria. Después del river no hay "
        "más cartas: tu mano ya es lo que es.",
 por_que_importa="Es la última decisión y suele ser la del bote más grande. Como no "
        "viene ninguna carta más, lo que estabas esperando y no salió ya no vale "
        "nada: la mano está cerrada.",
 como_funciona="Se abre la última carta y hay una ronda final de apuestas. Después, "
        "o alguien hace foldear al resto, o se llega al showdown.",
 cuando_lo_uso="En el river pensás distinto: no viene ninguna carta más. Mirás la "
        "mano que tenés, la comparás con lo que puede tener el rival, y decidís con "
        "eso: apostar si creés que tenés la mejor, o irte.",
 cuando_no="No sigas 'esperando tu carta' en el river: ya no viene ninguna.",
 ejemplo="Estabas esperando una pica para completar cinco del mismo palo y en el "
        "river salió un trébol. Tu mano quedó en nada. El rival apuesta: como no le "
        "ganás a casi nada, foldeás.",
 error_comun="Pagar el river con una mano que no ligó nada, 'porque ya puse mucho'. "
        "Lo que pusiste ya no es tuyo: si tu mano no gana en el showdown, foldeá.",
 idea_clave="River = última carta. No viene nada más: o tu mano ya gana, o no.",
),

"T047": dict(  # La ronda de apuestas
 que_es="Una ronda de apuestas es el tramo, dentro de cada calle, en que los "
        "jugadores apuestan por turno hasta que la acción se cierra.",
 por_que_importa="Hay exactamente 4 rondas por mano (una por calle). Cada una es una "
        "oportunidad de ganar el bote o de perder fichas. Entender el ritmo "
        "carta-ronda-carta-ronda es entender la estructura del póker.",
 como_funciona="En cada calle: se reparte la carta (o las cartas), empieza la ronda, "
        "cada jugador actúa en orden, y cuando todos igualaron o pasaron, la ronda se "
        "cierra y sale la carta siguiente.",
 cuando_lo_uso="Siempre sabés en qué ronda estás: preflop, flop, turn o river. Eso "
        "define cuánta información tenés y cuántas cartas faltan.",
 cuando_no=None,
 ejemplo="Preflop: ronda 1. Flop: ronda 2. Turn: ronda 3. River: ronda 4. Después "
        "de la ronda 4, showdown (o la mano ya terminó porque todos foldearon).",
 error_comun="Perder la cuenta de en qué calle estás y jugar el turn como si fuera "
        "el flop. Cada ronda tiene su lógica.",
 idea_clave="4 calles, 4 rondas de apuestas. Carta → ronda → carta → ronda.",
),

"T048": dict(  # El cambio de información entre calles
 que_es="Cada carta comunitaria nueva y cada acción del rival te dan información. "
        "Con cada calle sabés más sobre la mano de lo que sabías antes.",
 por_que_importa="El póker se juega hacia adelante: tus decisiones del turn se "
        "apoyan en lo que aprendiste en el flop. Un jugador que no actualiza su "
        "lectura calle a calle está jugando a ciegas.",
 como_funciona="Preflop sabés poco (solo tus cartas). En el flop ves 3 comunitarias "
        "y cómo apostó el rival. En el turn y el river, más cartas y más acciones. El "
        "abanico de manos que el rival puede tener se va achicando con cada dato.",
 cuando_lo_uso="Al empezar cada calle, preguntate: '¿qué aprendí desde la calle "
        "anterior?' La respuesta cambia tu plan.",
 cuando_no=None,
 ejemplo="Preflop el rival solo pagó tu subida: puede tener muchas manos. En el flop "
        "apostó fuerte en un board A-K-2: ahora la lista de manos que puede tener es "
        "más corta y más fuerte (ases, reyes, algún intento de robo).",
 error_comun="Decidir el river con la misma imagen del rival que tenías preflop. Su "
        "historia de apuestas cambió lo que puede tener.",
 idea_clave="Cada carta y cada acción suman información. Actualizá tu lectura calle "
        "a calle.",
),

"T049": dict(  # El fin de la mano
 que_es="Una mano termina de dos maneras: por fold (queda un solo jugador) o por "
        "showdown (los que quedan muestran y gana la mejor mano de 5).",
 por_que_importa="Saber cómo puede terminar la mano te dice cuál es tu plan: ¿estoy "
        "jugando para que el rival se retire, o para llegar a mostrar la mejor mano? "
        "Las dos cosas se juegan distinto.",
 como_funciona="Si en cualquier calle todos menos uno se retiran, la mano termina "
        "ahí y ese jugador se lleva el bote sin mostrar. Si al menos dos llegan al "
        "final del river, hay showdown y se compara.",
 cuando_lo_uso="Desde el preflop tenés un plan de cómo querés terminar la mano. Con "
        "mano fuerte: llegar al showdown cobrando. Con mano floja: ganar antes porque "
        "el rival se va, o rendirte barato.",
 cuando_no=None,
 ejemplo="Mano A: apostás el flop y todos se van → ganás por fold, mano terminada. "
        "Mano B: los dos llegan al river y mostrás cinco del mismo palo contra dos "
        "pares → ganás por showdown.",
 error_comun="Jugar sin plan de salida: apostar y apostar sin saber si buscás que "
        "el rival se retire o que te pague, y llegar al river sin idea de qué hacer.",
 idea_clave="La mano termina por fold o por showdown. Tené claro para cuál de las "
        "dos estás jugando.",
),

}
