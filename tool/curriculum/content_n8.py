# -*- coding: utf-8 -*-
"""
PASO 4 — Contenido redactado del NIVEL 8: "El flop: c-bet".
18 teorías, 6 subniveles. Banda INTERMEDIO, estadios ELEGIR (8.1) y
DECIDIR/EXPLICAR el resto. Voz: profesor de póker rioplatense.

Fuente de verdad: curriculum_spec.json.

Meta de N8: pasar de la guerra preflop (N7) a la primera decisión
postflop importante: ¿apuesto el flop siendo el agresor (c-bet) o no?
Y del otro lado: ¿qué hago cuando el agresor me apuesta a mí?

Vocabulario nuevo de N8: iniciativa (formal, T227 — ya evitado
deliberadamente en N1-N3), c-bet (continuation bet), multiway,
check-raise, semi-farol, float, probe bet, donk bet.

NO se enseña todavía: turn/river avanzado como tema propio (N9, salvo lo
mínimo que ya aparece acá al hablar del turn dentro de TN09), lectura de
rango por línea completa (N10), ventaja de rango/nuts formales,
bloqueadores, MDF (N11). El intento de 'jugar bien porque tu rango en
promedio es mejor' se describe en lenguaje llano en T176, sin nombrarlo
todavía 'ventaja de rango' (eso es T224, N11).
"""

N8 = {

# ============================================================
# 8.1 — La iniciativa y la c-bet
# ============================================================

"T227": dict(  # La iniciativa
 que_es="Tener la iniciativa es haber sido el último en apostar o subir "
        "en la mano: el resto de los jugadores tiene que reaccionar a "
        "lo que hiciste vos, no al revés.",
 por_que_importa="El jugador con la iniciativa arrastra una ventaja que "
        "no depende de sus cartas: los demás llegan a la calle "
        "siguiente teniendo que decidir frente a SU apuesta, no "
        "proponiendo ellos la acción.",
 como_funciona="Si abriste preflop y nadie volvió a subir, tenés la "
        "iniciativa al llegar al flop. Si 3-beteaste y te pagaron, "
        "también. La iniciativa se mantiene mientras seas vos quien "
        "hizo la última subida.",
 cuando_lo_uso="Para identificar, en cualquier punto de la mano, quién "
        "'lleva la voz cantante' y quién tiene que reaccionar.",
 cuando_no=None,
 ejemplo="Abrís desde el CO, el botón paga: llegan al flop con vos "
        "teniendo la iniciativa (fuiste el último en subir) y el botón "
        "teniendo que reaccionar a lo que hagas.",
 error_comun="Confundir iniciativa con 'tener la mejor mano'. Son cosas "
        "distintas: podés tener la iniciativa con una mano floja, y el "
        "rival puede tener la mejor mano sin tener la iniciativa.",
 idea_clave="Iniciativa = fuiste el último en subir. El resto reacciona "
        "a vos.",
),

"T175": dict(  # Qué es la continuation bet (c-bet)
 que_es="La continuation bet (c-bet) es apostar el flop siendo el "
        "jugador que tenía la iniciativa desde preflop — 'continuás' la "
        "agresión que ya venías mostrando.",
 por_que_importa="Es la decisión postflop más frecuente del juego: cada "
        "vez que abrís y te pagan, o 3-beteás y te pagan, te vas a "
        "enfrentar a esta decisión en el flop.",
 como_funciona="Si tenías la iniciativa (T227) al llegar al flop, "
        "c-betear es simplemente apostar vos primero, antes de que el "
        "rival tenga la chance de mostrar qué hizo con esa carta.",
 cuando_lo_uso="Cada vez que llegás al flop con la iniciativa y te toca "
        "decidir si apostás.",
 cuando_no=None,
 ejemplo="Abrís desde el CO, el botón paga, sale el flop: c-betear ahí "
        "es apostar como el jugador que llevaba la iniciativa.",
 error_comun="Pensar que 'c-bet' es cualquier apuesta en el flop. Es "
        "específicamente la apuesta del jugador que tenía la iniciativa "
        "desde antes.",
 idea_clave="C-bet = apostar el flop siendo el jugador con la "
        "iniciativa.",
),

"T176": dict(  # Por qué hacemos c-bet
 que_es="La c-bet funciona por dos motivos que se combinan: tenés la "
        "iniciativa (el rival reacciona a vos) y tu rango de apertura, "
        "en promedio, suele estar mejor parado que lo que el rival "
        "defendió.",
 por_que_importa="Entender POR QUÉ funciona te permite decidir cuándo "
        "sigue funcionando y cuándo no, en vez de c-betear en piloto "
        "automático.",
 como_funciona="Tu rango de apertura (N5) incluye manos fuertes y "
        "también manos que, la mayoría de las veces, terminan sin "
        "conectar el flop. Lo mismo el rango de defensa del rival. Pero "
        "como el rango del que abrió suele "
        "estar, en conjunto, un poco mejor parado en la mayoría de los "
        "boards, apostar ahí de entrada tiene sentido más seguido de lo "
        "que parece.",
 cuando_lo_uso="Como marco general para entender la lógica detrás de la "
        "c-bet, antes de ver los casos concretos (por valor, farol, "
        "proyecto) en 8.2.",
 cuando_no=None,
 ejemplo="Abrís con tu rango de apertura del CO y el botón paga con su "
        "rango de defensa: en la mayoría de los flops, tu rango en "
        "conjunto está un poco mejor parado — eso, sumado a la "
        "iniciativa, es la base de la c-bet.",
 error_comun="Pensar que la c-bet funciona 'porque el rival probablemente "
        "falló el flop, nomás'. También importa que tu propio rango, en "
        "conjunto, suele estar mejor parado en ese board.",
 idea_clave="La c-bet funciona por dos motivos juntos: la iniciativa y "
        "que tu rango, en promedio, suele estar mejor parado.",
),

# ============================================================
# 8.2 — C-bet por valor, farol y con proyecto
# ============================================================

"T177": dict(  # C-bet por valor
 que_es="C-betear con una mano ya hecha y fuerte, buscando que el rival "
        "pague con algo peor.",
 por_que_importa="Es el caso más simple de c-bet: tenés una buena mano, "
        "querés que te paguen. La misma lógica de la value bet (N6, "
        "T125), aplicada específicamente al flop.",
 como_funciona="Con una mano que le gana a buena parte del rango de "
        "defensa del rival en ese board, apostás buscando cobrar valor.",
 cuando_lo_uso="Con una mano hecha y fuerte en el flop, contra un "
        "rango del rival que puede tener manos peores dispuestas a "
        "pagar.",
 cuando_no=None,
 ejemplo="Tenés top pair con buen kicker en un board seco: c-betear por "
        "valor busca que manos peores del rango del rival paguen.",
 error_comun="C-betear por valor con un tamaño tan grande que solo te "
        "paguen manos que te ganan, o tan chico que no cobrás lo "
        "suficiente de las manos peores.",
 idea_clave="C-bet por valor = tenés lo mejor, buscás que te paguen.",
),

"T178": dict(  # C-bet como farol
 que_es="C-betear con una mano floja, sin proyecto ni mano hecha, "
        "buscando que el rival se retire.",
 por_que_importa="Gracias a la fold equity (N6), no necesitás la mejor "
        "mano para que apostar tenga sentido: alcanza con que el rival "
        "se retire lo suficientemente seguido.",
 como_funciona="En boards donde tu rango (el que abrió) suele estar "
        "mejor parado y el rival falló seguido, una c-bet con nada "
        "puede ganar el bote ahí mismo sin necesidad de mejorar.",
 cuando_lo_uso="Con una mano sin ningún valor real ni proyecto, en un "
        "board donde el rival tiene buenos motivos para foldear seguido.",
 cuando_no="Contra un rival que paga cualquier c-bet sin importar el "
        "board: ahí falta la fold equity que hace funcionar el farol.",
 ejemplo="Abriste con K♠Q♦, falló un flop 7♠4♦2♣, y c-beteás como "
        "farol: no tenés nada, pero el rival tiene muchos motivos para "
        "haber fallado también ese board.",
 error_comun="C-betear como farol en cualquier board, sin pensar si el "
        "rival realmente tiene motivos para retirarse seguido ahí.",
 idea_clave="C-bet como farol = sin mano, gana por fold equity si el "
        "rival se retira.",
),

"T179": dict(  # C-bet con proyecto
 que_es="C-betear con un proyecto (un semi-farol): todavía no tenés la "
        "mejor mano, pero podés ganar de dos formas — que el rival se "
        "retire ahora, o que completes tu proyecto si te paga.",
 por_que_importa="Es distinta a un farol puro (T178): incluso si te "
        "pagan, todavía tenés chances reales de terminar ganando la "
        "mano en las calles siguientes.",
 como_funciona="Elegís un proyecto con buenos outs (N6) y apostás: si el "
        "rival se retira, ganás ahí mismo; si paga, seguís con equity "
        "real para completar tu mano.",
 cuando_lo_uso="Con un proyecto de varios outs (color, escalera) en el "
        "flop, contra un rival que puede retirarse o pagar.",
 cuando_no=None,
 ejemplo="Tenés un proyecto de color en el flop: c-betear ahí gana si "
        "el rival se retira, y si paga, seguís con 9 outs reales para "
        "completar el color en las calles siguientes.",
 error_comun="Tratar cualquier c-bet con un proyecto flojo (pocos outs) "
        "igual que una con muchos outs — la calidad del proyecto importa.",
 idea_clave="C-bet con proyecto = gana de dos formas: fold equity ahora, "
        "o equity real si te pagan.",
),

# ============================================================
# 8.3 — C-bet según el board
# ============================================================

"T180": dict(  # C-bet en board seco
 que_es="En un board seco (N4: pocas cartas conectadas, sin proyectos "
        "obvios), la c-bet se puede hacer con más frecuencia.",
 por_que_importa="Un board seco favorece al rango del que tenía la "
        "iniciativa: hay pocas manos que realmente hayan conectado algo "
        "fuerte del lado del defensor.",
 como_funciona="Con menos proyectos y menos chances de que el rival haya "
        "mejorado, apostar seguido en un board seco cuesta poco y gana "
        "seguido — tanto por valor como por fold equity.",
 cuando_lo_uso="Al llegar a un flop claramente seco, como parte de tu "
        "plan de c-bet.",
 cuando_no=None,
 ejemplo="Un flop K♠7♦2♣ (sin proyecto de color ni de escalera visible) "
        "es seco: ahí una c-bet frecuente funciona bien.",
 error_comun="Jugar un board seco con la misma frecuencia baja que un "
        "board peligroso, desaprovechando que ahí la c-bet rinde más.",
 idea_clave="Board seco = c-beteás más seguido: el rival tiene pocos "
        "motivos para haber conectado.",
),

"T181": dict(  # C-bet en board coordinado
 que_es="En un board coordinado (N4: cartas conectadas, proyectos "
        "posibles), conviene ser más selectivo con la c-bet.",
 por_que_importa="Un board coordinado favorece más al rango del "
        "defensor: hay más manos y proyectos posibles que pueden haber "
        "conectado, así que apostar a ciegas cuesta más caro cuando el "
        "rival responde.",
 como_funciona="En vez de c-betear con cualquier cosa, elegís más "
        "puntualmente: manos de valor real, proyectos con buenos outs "
        "(T179), y menos farol puro.",
 cuando_lo_uso="Al llegar a un flop claramente coordinado, como parte de "
        "tu plan de c-bet.",
 cuando_no=None,
 ejemplo="Un flop 9♠8♠7♦ (conectado, con proyecto de color y de "
        "escalera posibles) es coordinado: ahí conviene c-betear con "
        "una selección más cuidada de manos.",
 error_comun="C-betear en un board coordinado con la misma frecuencia "
        "alta que usarías en uno seco.",
 idea_clave="Board coordinado = c-beteás más selectivo: hay más manos "
        "del rival que pudieron conectar.",
),

"TN18": dict(  # C-bet en botes multiway
 que_es="Un bote multiway es un bote con TRES o más jugadores viendo el "
        "flop, no solo vos y un rival. La c-bet ahí se ajusta todavía "
        "más.",
 por_que_importa="Con más jugadores en la mano, hay más chances de que "
        "ALGUNO de ellos haya conectado algo — aunque cada rival "
        "individual siga teniendo la misma chance de siempre.",
 como_funciona="Bajás todavía más la frecuencia de farol puro y "
        "apostás con manos más concretas: valor real o proyectos con "
        "buenos outs, porque necesitás que TODOS los rivales se "
        "retiren, no solo uno.",
 cuando_lo_uso="Cada vez que llegás al flop con dos o más rivales "
        "todavía en la mano.",
 cuando_no=None,
 ejemplo="Abriste y dos rivales pagaron: llegan al flop de a tres. "
        "C-betear ahí con una mano floja sin proyecto es más riesgoso "
        "que en un bote de uno contra uno, porque necesitás que los DOS "
        "se retiren.",
 error_comun="C-betear un bote multiway con la misma frecuencia y las "
        "mismas manos que usarías contra un solo rival.",
 idea_clave="Multiway = más jugadores, más chances de que alguno haya "
        "conectado. C-beteás con manos más concretas.",
),

# ============================================================
# 8.4 — C-bet según la posición
# ============================================================

"T182": dict(  # C-bet en posición
 que_es="Aprovechar que vas a actuar último en el resto de la mano para "
        "c-betear con más margen: vas a ver la reacción del rival antes "
        "de la próxima decisión.",
 por_que_importa="Estar en posición (N3) te deja tomar decisiones con "
        "más información en cada calle que sigue — eso hace que "
        "apostar el flop en posición sea, en general, más cómodo.",
 como_funciona="Al actuar último, si el rival paga, vas a ver qué hace "
        "en el turn antes de decidir vos. Eso te permite planear la "
        "mano con más flexibilidad.",
 cuando_lo_uso="Al c-betear desde una posición donde vas a actuar "
        "después del rival el resto de la mano.",
 cuando_no=None,
 ejemplo="Abriste desde el botón y la BB pagó: c-betear desde ahí te "
        "deja ver la reacción de la BB antes de decidir el turn.",
 error_comun="No aprovechar la información extra de estar en posición, "
        "jugando el resto de la mano igual que si estuvieras fuera de "
        "ella.",
 idea_clave="C-betear en posición te deja ver la reacción del rival "
        "antes de la próxima decisión.",
),

"T183": dict(  # C-bet fuera de posición
 que_es="C-betear teniendo que actuar primero en las calles siguientes: "
        "sin ver antes qué hace el rival.",
 por_que_importa="Fuera de posición tenés menos información para las "
        "decisiones que vienen: hay que ser un poco más selectivo y "
        "pensar con más anticipación qué vas a hacer según lo que "
        "pase.",
 como_funciona="Como no vas a ver la reacción del rival antes de tu "
        "próxima decisión, conviene c-betear con manos que sepas cómo "
        "seguir jugando (valor claro o proyecto con buenos outs) en vez "
        "de faroles sueltos difíciles de continuar.",
 cuando_lo_uso="Al c-betear desde una posición donde vas a actuar antes "
        "que el rival el resto de la mano.",
 cuando_no=None,
 ejemplo="Abriste desde UTG y la BB pagó: c-betear ahí, fuera de "
        "posición, conviene hacerlo con manos donde ya tenés un plan "
        "claro para el turn, sin importar lo que haga la BB.",
 error_comun="C-betear fuera de posición con la misma amplitud de "
        "manos que en posición, sin un plan para cuando venga la "
        "próxima decisión a ciegas.",
 idea_clave="Fuera de posición, c-beteás con manos donde ya tenés un "
        "plan para seguir, porque no vas a ver la reacción del rival "
        "antes.",
),

# ============================================================
# 8.5 — Frecuencia y tamaño
# ============================================================

"T184": dict(  # La frecuencia de c-bet
 que_es="La frecuencia de c-bet es qué tan seguido apostás el flop "
        "cuando tenés la iniciativa — no es 'siempre' ni 'nunca', es "
        "una proporción que depende del board, la posición y si el bote "
        "es multiway.",
 por_que_importa="C-betear el 100% de las veces te vuelve predecible "
        "(el rival sabe que siempre vas a apostar, así que puede jugar "
        "en consecuencia); no c-betear casi nunca desperdicia todo lo "
        "que trabajaste en 8.1-8.4.",
 como_funciona="Juntá todo lo que ya viste: boards secos y en posición "
        "empujan la frecuencia hacia arriba; boards coordinados, "
        "multiway y fuera de posición la empujan hacia abajo.",
 cuando_lo_uso="Como resumen práctico antes de decidir si apostás este "
        "flop puntual: no es una decisión aislada, es parte de un "
        "patrón.",
 cuando_no=None,
 ejemplo="En un board seco, en posición, contra un solo rival, tu "
        "frecuencia de c-bet debería ser alta. En un board coordinado, "
        "fuera de posición, multiway, debería ser bastante más baja.",
 error_comun="Pensar la c-bet mano por mano sin ningún patrón general, "
        "en vez de tener una frecuencia razonable según el tipo de "
        "situación.",
 idea_clave="La frecuencia de c-bet varía según board, posición y "
        "cantidad de rivales — no es un sí o un no fijo.",
),

"T185": dict(  # El tamaño de la c-bet
 que_es="Elegir cuánto apostar en la c-bet, según el board y lo que "
        "buscás con esa apuesta puntual.",
 por_que_importa="Igual que con el tamaño de apertura (N5), el tamaño "
        "de la c-bet no es un número fijo: cumple un objetivo distinto "
        "según la situación.",
 como_funciona="En boards secos, un tamaño más chico ya cumple su "
        "función (el rival tiene pocos motivos para pagar con algo "
        "mejor). En boards coordinados o multiway, un tamaño más grande "
        "cobra mejor valor y cobra más caro a los proyectos del rival.",
 cuando_lo_uso="Cada vez que decidís c-betear: además de con qué mano, "
        "definís cuánto apostar.",
 cuando_no=None,
 ejemplo="En un board seco, una c-bet chica (un tercio del bote) puede "
        "ser suficiente. En un board coordinado con muchos proyectos "
        "posibles, un tamaño más grande (dos tercios o más) cobra mejor "
        "a esos proyectos.",
 error_comun="Usar siempre el mismo tamaño de c-bet sin importar el "
        "board, perdiendo la chance de ajustar según lo que cada "
        "situación pide.",
 idea_clave="El tamaño de la c-bet se ajusta al board y al objetivo, "
        "igual que el tamaño de apertura se ajusta a la posición.",
),

# ============================================================
# 8.6 — Enfrentar una apuesta postflop
# ============================================================

"TN05": dict(  # Enfrentar una c-bet
 que_es="Del otro lado de la mesa: decidir entre foldear, pagar o subir "
        "cuando el rival (con la iniciativa) te c-betea a vos.",
 por_que_importa="Todo lo que viste en 8.1-8.5 fue desde el punto de "
        "vista del agresor. Ahora te toca ser el que responde — la otra "
        "mitad de cada mano postflop.",
 como_funciona="Juntás lo que ya sabés: tu mano y tus proyectos (N4), "
        "el rango probable del rival según el board (8.1-8.4), y pot "
        "odds/equity necesaria (N6) para decidir entre las tres "
        "opciones.",
 cuando_lo_uso="Cada vez que el rival, con la iniciativa, te apuesta el "
        "flop.",
 cuando_no=None,
 ejemplo="El rival c-betea en un board coordinado donde vos fallaste "
        "por completo: sin mano ni proyecto, y sin motivos para pensar "
        "que va a foldear, foldeás.",
 error_comun="Responder a cada c-bet con la misma acción (siempre "
        "pagar, o siempre foldear), sin evaluar mano, board y rango del "
        "rival cada vez.",
 idea_clave="Enfrentar una c-bet junta todo lo aprendido hasta acá: tu "
        "mano, el board, y el rango probable del que apostó.",
),

"TN06": dict(  # Check-raise por valor
 que_es="Un check-raise es pasar primero y después subir la apuesta del "
        "rival en la misma ronda. Por valor: lo hacés con una mano "
        "fuerte, buscando construir un bote más grande.",
 por_que_importa="Es una forma de sacarle más valor a una mano fuerte "
        "cuando sabés que el rival, teniendo la iniciativa, va a "
        "apostar casi siempre — dejás que apueste primero y después "
        "subís.",
 como_funciona="Pasás con tu mano fuerte (en vez de apostar vos), "
        "esperando que el rival c-betee, y entonces subís su apuesta.",
 cuando_lo_uso="Con una mano fuerte, contra un rival que c-betea "
        "seguido, cuando pasar primero te deja meter más fichas en el "
        "bote que apostar vos de entrada.",
 cuando_no=None,
 ejemplo="Tenés un set en un board donde sabés que el rival c-betea casi "
        "siempre: pasar y dejar que apueste, para después subir, mete "
        "más fichas que apostar vos primero.",
 error_comun="Check-raisear por valor contra un rival que casi nunca "
        "c-betea — ahí simplemente estás regalando la chance de apostar "
        "vos mismo.",
 idea_clave="Check-raise por valor = pasás para que el rival apueste "
        "primero, y después subís con tu mano fuerte.",
),

"TN07": dict(  # Check-raise como semi-farol
 que_es="Check-raisear con un proyecto (semi-farol): igual que la c-bet "
        "con proyecto (T179), ganás de dos formas — que el rival se "
        "retire frente a tu subida, o que completes tu proyecto si "
        "paga.",
 por_que_importa="No hace falta tener la mejor mano para check-raisear: "
        "un proyecto con buenos outs te deja jugar agresivo incluso "
        "pasando primero.",
 como_funciona="Pasás con tu proyecto, el rival c-betea, y subís: si "
        "se retira, ganás el bote ahí mismo; si paga, seguís con "
        "chances reales de completar tu mano en las calles que siguen.",
 cuando_lo_uso="Con un proyecto de varios outs, contra un rival que "
        "c-betea seguido y que a veces se retira frente a presión.",
 cuando_no=None,
 ejemplo="Tenés un proyecto de color, pasás, el rival c-betea, y "
        "subís: si se retira ganás ahí; si paga, seguís con 9 outs "
        "reales para el turn o el river.",
 error_comun="Check-raisear como semi-farol con un proyecto muy flojo "
        "(pocos outs), donde perdés casi todo tu valor si el rival "
        "paga.",
 idea_clave="Check-raise como semi-farol = gana de dos formas, igual "
        "que la c-bet con proyecto, pero pasando primero.",
),

"TN08": dict(  # El float
 que_es="El float es pagar la c-bet del rival sin tener mano hecha, con "
        "el plan de apostar vos en el turn si el rival muestra "
        "debilidad (por ejemplo, si pasa).",
 por_que_importa="Es una forma de aprovechar la posición: en vez de "
        "responder a la c-bet foldeando, pagás una vez, planeando "
        "llevarte el bote más adelante si el rival no vuelve a "
        "apostar.",
 como_funciona="Pagás la c-bet del flop sin mano real. En el turn, si "
        "el rival pasa (mostrando que no tiene ganas de seguir "
        "apostando), apostás vos y buscás que se retire ahí.",
 cuando_lo_uso="Estando en posición, contra un rival que suele c-betear "
        "una vez en el flop pero no siempre sigue apostando en el turn "
        "sin una mano real.",
 cuando_no="Fuera de posición: el float depende de ver primero qué hace "
        "el rival en el turn, así que necesita estar en posición para "
        "funcionar.",
 ejemplo="El rival c-betea el flop, pagás sin mano. En el turn, el "
        "rival pasa: apostás vos, buscando que se retire una mano que "
        "ya mostró que no quería seguir apostando.",
 error_comun="Hacer float sin estar en posición, sin poder ver primero "
        "qué hace el rival en la calle siguiente.",
 idea_clave="Float = pagar sin mano en el flop, planeando robar el bote "
        "en el turn si el rival muestra debilidad.",
),

"TN09": dict(  # El probe bet y el donk bet
 que_es="Dos formas de apostar 'fuera del orden esperado': el probe bet "
        "es apostar el turn cuando el agresor (quien tenía la "
        "iniciativa) pasó el flop; el donk bet es apostar el flop "
        "siendo el defensor, antes de que el agresor tenga la chance de "
        "c-betear.",
 por_que_importa="Ambas rompen el patrón habitual (agresor apuesta, "
        "defensor reacciona), así que son señales que vale la pena "
        "reconocer, tanto para usarlas vos como para leerlas del "
        "rival.",
 como_funciona="Probe bet: el agresor pasó el flop (mostrando poco "
        "interés), y vos, como defensor, apostás el turn aprovechando "
        "esa debilidad. Donk bet: apostás el flop siendo el defensor, "
        "sin esperar a ver si el agresor c-betea.",
 cuando_lo_uso="Probe bet: cuando el agresor pasó el flop y el board o "
        "la situación te da motivos para pensar que se retira frente a "
        "presión. Donk bet: en situaciones puntuales donde apostar "
        "primero vos, como defensor, tiene una razón concreta (por "
        "ejemplo, una carta del turn que te favorece mucho más a vos "
        "que al agresor).",
 cuando_no=None,
 ejemplo="El agresor pasa el flop: apostás el turn (probe bet), "
        "aprovechando que mostró poco interés. En otra mano, como "
        "defensor, apostás vos el flop antes de que el agresor c-betee "
        "(donk bet), porque una carta te benefició mucho más a vos.",
 error_comun="Usar el donk bet como costumbre, sin una razón concreta — "
        "en general, romper el patrón esperado sin motivo regala "
        "información sin necesidad.",
 idea_clave="Probe bet y donk bet rompen el orden esperado de apuestas: "
        "valen la pena cuando hay una razón concreta detrás, no por "
        "costumbre.",
),

}
