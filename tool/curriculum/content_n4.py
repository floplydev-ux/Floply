# -*- coding: utf-8 -*-
"""
PASO 7 — Contenido redactado del NIVEL 4: "Leé tu mano y el board".
37 teorías, 6 subniveles. Banda BÁSICO, estadio RECONOCER (4.6 es checkpoint).
Voz: un buen profesor a alguien que empieza a leer situaciones. Completo, no
largo. Español rioplatense (vos / tenés).

Fuente de verdad: curriculum_spec.json (IDs, títulos, objetivos, orden y
prerrequisitos no se tocan acá).

Meta de N4: pasar de "reconocer qué cartas tengo" a "leer qué tengo AHORA con
el board y qué puede cambiar". El alumno sale de N4 sabiendo: clasificar su
mano inicial, leer la textura de un flop, distinguir mano hecha de proyecto,
graduar la fuerza de una pareja o una mano hecha, y reconocer los nuts.

Vocabulario: se usa terminología real de póker (board, flop, turn, river,
proyecto/draw, outs, gutshot, nuts) explicada la primera vez que aparece. NO
se enseña todavía: rangos, RFI, equity formal, pot odds, EV, fold equity,
3-bet, c-bet, MDF, blockers, realización de equity, explotación del rival.
Única excepción señalada: T100 nombra "valor" (apostar por valor) porque su
objetivo lo requiere; se glosa en el momento, no se desarrolla como teoría.
"""

N4 = {

# ============================================================
# 4.1 — Tipos de mano inicial
# ============================================================

"T064": dict(  # Parejas servidas (pocket pairs)
 que_es="Dos cartas privadas del mismo valor (por ejemplo 8♠8♦). Se llaman "
        "'pareja servida' o 'pocket pair' porque ya nacés con la pareja hecha, "
        "antes de que salga ninguna carta comunitaria.",
 por_que_importa="Empezás la mano con una combinación ya armada. Y tiene un "
        "potencial extra: si sale una tercera carta de ese valor en el board, "
        "formás un trío escondido — una de las manos más fuertes y disimuladas "
        "del póker.",
 como_funciona="Hay 13 parejas servidas posibles, de 2♠2♦ a A♠A♦. Cuanto más alta, "
        "mejor de entrada; las bajas valen sobre todo por la chance de ligar ese "
        "trío.",
 cuando_lo_uso="Al mirar tus 2 cartas privadas: '¿son del mismo valor?' es la "
        "primera pregunta.",
 cuando_no=None,
 ejemplo="8♠8♦ es una pareja servida. Si el flop trae un 8, tenés trío escondido: "
        "nadie en la mesa espera que tengas eso.",
 error_comun="Jugar cualquier pareja servida igual. Una pareja de ases entra "
        "siempre; una de doses vale sobre todo por si liga trío, y si no liga, "
        "suele ser floja.",
 idea_clave="Pareja servida = tus 2 cartas ya forman pareja. Potencial extra: "
        "ligar trío escondido.",
),

"T065": dict(  # Manos del mismo palo (suited)
 que_es="Dos cartas privadas del mismo palo (por ejemplo K♠7♠). Se anota con una "
        "'s' chiquita: 'K7s'.",
 por_que_importa="Te da una chance extra de terminar armando un color, que no "
        "tenés si tus cartas son de palos distintos.",
 como_funciona="Con dos cartas del mismo palo, necesitás 3 más del board para "
        "completar cinco del mismo palo. Es un extra, no el motivo principal para "
        "jugar la mano: el valor real sigue viniendo de los valores de las "
        "cartas.",
 cuando_lo_uso="Al anotar o pensar una mano: 'K7 suited' = K7s.",
 cuando_no=None,
 ejemplo="A♠5♠ vale más que A♦5♣ aunque las cartas sean las mismas: la versión "
        "suited tiene, además, chance de color.",
 error_comun="Sobrevalorar el 'suited' y jugar cualquier cosa solo porque "
        "combina. 7♠2♠ sigue siendo una mano floja, aunque sea del mismo palo.",
 idea_clave="Suited (s) = mismo palo = chance extra de color. Es un plus, no la "
        "mano en sí.",
),

"T066": dict(  # Manos de distinto palo (offsuit)
 que_es="Dos cartas privadas de palos distintos (por ejemplo K♠7♥). Se anota con "
        "una 'o': 'K7o'.",
 por_que_importa="Sin el plus del color, esa mano vale exactamente lo que valen "
        "sus dos cartas y nada más. Es la versión 'de base' de cualquier "
        "combinación de valores.",
 como_funciona="La misma pareja de valores vale menos offsuit que suited, porque "
        "perdés la chance de color. La diferencia es real pero no enorme: sigue "
        "mandando el valor de las cartas.",
 cuando_lo_uso="Para comparar dos versiones de la misma mano: '¿esta A-Q es "
        "suited o offsuit?'.",
 cuando_no=None,
 ejemplo="A♦Q♣ (AQo) y A♠Q♠ (AQs) son parecidas, pero la segunda tiene además "
        "chance de color. AQo sigue siendo una mano fuerte igual: no es floja por "
        "ser offsuit.",
 error_comun="Pensar que 'offsuit' convierte automáticamente una mano fuerte en "
        "floja. K-Q offsuit sigue siendo buena; lo que pierde es solo la chance "
        "extra de color.",
 idea_clave="Offsuit (o) = distinto palo = sin chance de color. Vale por sus "
        "cartas, no menos por eso.",
),

"T067": dict(  # Manos conectadas
 que_es="Dos cartas privadas de valores seguidos o casi seguidos (por ejemplo "
        "9♣8♦). Se llaman 'conectores'.",
 por_que_importa="Te dan chance de completar una escalera si el board colabora, "
        "además de poder emparejar cualquiera de las dos cartas.",
 como_funciona="Cuanto menos 'hueco' hay entre las dos cartas, más formas hay de "
        "completar una escalera. 9-8 (seguidas) tiene más chances que 9-6 (con "
        "dos huecos).",
 cuando_lo_uso="Al mirar tus cartas: '¿están cerca en valor?', además de '¿son "
        "del mismo palo?'.",
 cuando_no=None,
 ejemplo="J♠T♦ son conectores: si el board ayuda, podés armar una escalera por "
        "varios lados distintos.",
 error_comun="Jugar conectores muy bajos (4-3, 5-3) esperando lo mismo que con "
        "conectores altos. Con los altos, además de la escalera, tenés más "
        "chances de ganar aunque no la completes.",
 idea_clave="Conectores = valores seguidos o casi. Suman chance de escalera.",
),

"T068": dict(  # Broadways
 que_es="Las cartas broadway son las cinco más altas: 10, J, Q, K, A. Una mano "
        "'broadway' tiene sus dos cartas privadas dentro de ese grupo (por "
        "ejemplo K♠J♦).",
 por_que_importa="Cualquier pareja que armes con una carta broadway va a ser una "
        "pareja alta, fuerte contra la mayoría de los boards. Y si dos broadways "
        "conectan, apuntan a la escalera más alta posible.",
 como_funciona="Combinando dos cartas broadway (KQ, QJ, AJ, etc.) tenés una mano "
        "que empareja fuerte y, muchas veces, conecta para escalera.",
 cuando_lo_uso="Para reconocer de un vistazo una mano de valores altos: '¿mis dos "
        "cartas son 10 o más?'.",
 cuando_no=None,
 ejemplo="K♠Q♦ es broadway: si empareja el rey o la dama, es una pareja fuerte. "
        "Si el board trae un J y un T, tenés K-Q-J-T: cuatro seguidas, un "
        "proyecto de escalera abierto por las dos puntas. Un As o un 9 lo "
        "completa.",
 error_comun="Meter en la misma bolsa cualquier carta alta con cualquier otra. "
        "Q♠4♦ tiene una carta broadway, pero la otra no acompaña: no es lo mismo "
        "que Q-J.",
 idea_clave="Broadway = 10, J, Q, K, A. Dos broadways juntas: pareja alta + "
        "chance de escalera alta.",
),

"T069": dict(  # Manos con As
 que_es="Cualquier mano que incluye un As (por ejemplo A♠9♥). El As es la carta "
        "más alta de la baraja, así que estas manos merecen una mirada aparte.",
 por_que_importa="Si emparejás el As, tenés la pareja más alta posible del "
        "board. Pero acá el kicker pesa muchísimo: no es lo mismo A-K que A-4.",
 como_funciona="Con As, mirá siempre la segunda carta: cuanto más alta, mejor "
        "acompaña al As y menos te expone a perder por kicker cuando emparejás.",
 cuando_lo_uso="Cada vez que mirás tus 2 cartas y una es un As: '¿con qué está "
        "acompañado?'.",
 cuando_no=None,
 ejemplo="A♠K♦ (as bien acompañado) y A♦4♣ (as mal acompañado) no se juegan "
        "igual: si los dos emparejan el As en el flop, el primero tiene un "
        "kicker enorme y el segundo, uno muy pobre.",
 error_comun="Jugar cualquier As igual, solo por ser la carta más alta. Un As "
        "con kicker chico te puede meter en problemas grandes si emparejás y el "
        "rival tiene un As mejor acompañado.",
 idea_clave="Mano con As = mirá el kicker. A-K no es lo mismo que A-4.",
),

# ============================================================
# 4.2 — Fuerza de la mano inicial
# ============================================================

"T070": dict(  # Manos premium
 que_es="El puñado de manos iniciales más fuertes que existen: AA, KK, QQ y AK. "
        "Se llaman 'premium'.",
 por_que_importa="Son las únicas manos que casi siempre conviene jugar sin "
        "dudar, sea cual sea tu posición. Todo lo demás es, en distinto grado, "
        "una decisión más matizada.",
 como_funciona="AA, KK y QQ son parejas servidas altísimas: rarísima vez están "
        "detrás antes del flop. AK no es pareja, pero son las dos cartas más "
        "altas: mucho potencial de emparejar fuerte o armar la mejor escalera.",
 cuando_lo_uso="Cuando recibís una de estas 4 manos, sabés que estás arriba de "
        "casi todo lo que puede tener el rival.",
 cuando_no=None,
 ejemplo="Recibís Q♠Q♥. Aunque un As o un Rey en el flop te preocupe un poco, "
        "seguís teniendo una mano premium: se juega con confianza.",
 error_comun="Creer que 'premium' significa invencible. Hasta AA puede perder "
        "una mano puntual; lo que las hace premium es que ganan mucho más "
        "seguido que cualquier otra cosa, no que ganen siempre.",
 idea_clave="Premium = AA, KK, QQ, AK. Las manos más fuertes para empezar una "
        "mano.",
),

"T071": dict(  # Pares medios
 que_es="Parejas servidas de valor medio: de TT a 77.",
 por_que_importa="Son manos incómodas: le ganan a casi cualquier mano sin "
        "pareja, pero les preocupa que en el flop aparezca una carta más alta "
        "que ellas.",
 como_funciona="Empiezan como una pareja decente. Si el flop no trae ninguna "
        "carta más alta, siguen siendo la mejor pareja posible. Si trae una "
        "carta más alta, pasan a ser solo una pareja de valor medio y hay que "
        "tener más cuidado.",
 cuando_lo_uso="Al recibir TT-77: sabelas jugar, pero estate atento a lo que "
        "trae el flop antes de comprometer muchas fichas.",
 cuando_no=None,
 ejemplo="Tenés 9♠9♦. Si el flop es 6♣4♦2♥, tu pareja sigue siendo la más alta "
        "del board: buena mano. Si el flop es K♣8♦3♥, hay una carta más alta que "
        "tu pareja: ya no es tan cómoda.",
 error_comun="Jugar un par medio como si fuera premium en cualquier board. Su "
        "fuerza depende mucho de qué salga en el flop.",
 idea_clave="Pares medios = TT a 77. Buenos, pero dependen de qué carta "
        "aparezca en el flop.",
),

"T072": dict(  # Pares pequeños
 que_es="Parejas servidas bajas: de 66 a 22.",
 por_que_importa="Casi nunca van a ser la mejor pareja una vez que sale el "
        "flop: es muy probable que aparezca alguna carta más alta. Su valor "
        "principal es la chance de ligar un trío.",
 como_funciona="Jugás estas manos sobre todo esperando ligar trío en el flop. Si "
        "no lo ligás, generalmente no valen mucho y conviene soltarlas fácil.",
 cuando_lo_uso="Al recibir 66-22: entrá pensando 'busco trío', no 'tengo una "
        "pareja fuerte'.",
 cuando_no=None,
 ejemplo="Tenés 4♠4♦. Flop: K♣9♦2♥. No ligaste el trío: tu pareja de cuatros es "
        "la más floja posible en ese board. Si en cambio el flop es 8♣4♥2♦, "
        "ligaste trío: mano excelente.",
 error_comun="Pagar de más con un par pequeño 'porque es una pareja'. Sin el "
        "trío, casi siempre es una mano débil.",
 idea_clave="Pares pequeños = 66 a 22. Juegan a ligar trío; sin eso, valen poco.",
),

"T073": dict(  # Mano dominada
 que_es="Tu mano está 'dominada' cuando comparte la carta más alta con la del "
        "rival, pero la de él tiene mejor kicker (por ejemplo, vos A-4 y él "
        "A-K).",
 por_que_importa="Es una de las formas más caras de perder fichas: las dos "
        "manos van a emparejar la misma carta seguido, pero una siempre le gana "
        "a la otra por el kicker.",
 como_funciona="Cuando las dos cartas altas coinciden, el resultado depende casi "
        "siempre de la segunda carta. Si la tuya es baja y la del rival alta, "
        "estás dominado: casi no tenés forma de ganarle salvo que tu kicker "
        "mejore de casualidad.",
 cuando_lo_uso="Antes de jugar una mano tipo A-x chico o K-x chico, preguntate: "
        "'¿y si el rival tiene la misma carta alta con mejor kicker?'.",
 cuando_no=None,
 ejemplo="Tenés A♠5♦, el rival tiene A♥K♣. El board trae un As (A♣): los dos "
        "emparejan, pero el rival gana casi siempre por el kicker (K contra 5).",
 error_comun="Jugar cualquier As solo porque 'es un As'. Un As mal acompañado se "
        "choca seguido con Ases mejor acompañados, y ahí está dominado.",
 idea_clave="Mano dominada = misma carta alta, peor kicker. Perdés casi siempre "
        "que las dos emparejan.",
),

"T074": dict(  # Mano especulativa
 que_es="Una mano floja de entrada, que casi nunca gana por sí sola, pero que "
        "tiene potencial de convertirse en algo muy fuerte si el board la ayuda "
        "(conectores suited chicos, como 6♠5♠).",
 por_que_importa="Estas manos no se juegan por su fuerza actual, sino por lo que "
        "pueden llegar a ser: color, escalera o incluso una combinación muy "
        "disimulada.",
 como_funciona="Casi siempre entrás con una mano especulativa esperando ligar "
        "algo grande en el flop. Si no ligás nada, la soltás fácil, sin pelear.",
 cuando_lo_uso="Con manos como 76 suited, 65 suited: cuando decidís jugarlas, es "
        "apostando a un flop que las transforme, no a lo que valen ahora.",
 cuando_no=None,
 ejemplo="Tenés 7♠6♠. Solas, esas cartas no valen casi nada. Pero si el flop es "
        "8♠5♠2♦, de repente tenés escalera abierta y proyecto de color a la "
        "vez.",
 error_comun="Seguir jugando una mano especulativa que no ligó nada, solo porque "
        "'tenía potencial'. Si el flop no la ayudó, ya no vale ese potencial.",
 idea_clave="Mano especulativa = floja ahora, con potencial si liga. Sin ligar, "
        "se suelta fácil.",
),

# ============================================================
# 4.3 — Texturas de board
# ============================================================

"T075": dict(  # Board seco
 que_es="La textura del board es cómo se relacionan entre sí sus cartas: sus "
        "palos, sus valores y qué tan conectadas están. Un board seco es una "
        "textura con pocas conexiones: cartas de valores separados y de palos "
        "distintos (por ejemplo K♠7♦2♣).",
 por_que_importa="Es el tipo de board más simple de leer: casi nadie tiene un "
        "proyecto porque no hay dos cartas seguidas ni dos del mismo palo. Lo "
        "que ves es, en general, lo que hay.",
 como_funciona="Mirá las 3 cartas del flop: si están lejos en valor y no hay dos "
        "del mismo palo, es seco. En un board así, las manos hechas valen más "
        "tranquilas, porque hay pocas cartas por venir que cambien mucho la "
        "situación.",
 cuando_lo_uso="Apenas se abre el flop: '¿hay cartas seguidas o del mismo palo? "
        "Si no, es un board seco.'",
 cuando_no=None,
 ejemplo="Flop K♠7♦2♣: valores separados, tres palos distintos. Muy poco puede "
        "completar algo grande ahí.",
 error_comun="Jugar todos los boards igual de 'tranquilo'. Un board seco de hoy "
        "puede volverse coordinado con una sola carta del turn.",
 idea_clave="Board seco = cartas separadas, palos distintos. Pocos proyectos "
        "posibles.",
),

"T076": dict(  # Board coordinado
 que_es="Un board coordinado es lo contrario del seco: cartas de valores "
        "cercanos, con muchas combinaciones posibles de escalera (por ejemplo "
        "9♠8♦7♣).",
 por_que_importa="En un board así hay muchas más manos posibles: escaleras "
        "hechas, proyectos abiertos, incluso trío. Hay que jugar con más "
        "cuidado: lo que parecía una buena mano puede estar perdiendo.",
 como_funciona="Mirá si las 3 cartas del flop están cerca en valor, aunque no "
        "sean seguidas exactas. Cuanto más cerca, más 'coordinado' y más "
        "proyectos hay dando vueltas.",
 cuando_lo_uso="Apenas ves el flop: '¿estas cartas están cerca en valor? Si sí, "
        "mucha gente puede tener algo.'",
 cuando_no=None,
 ejemplo="Flop 9♠8♦7♣: cualquier mano con 10-6, 6-5, o un 9, un 8 o un 7 ya "
        "tiene algo hecho o un proyecto fuerte.",
 error_comun="Apostar fuerte en un board coordinado con una mano media, sin "
        "pensar en cuánta gente puede tener ya una escalera o algo mejor.",
 idea_clave="Board coordinado = cartas cercanas. Muchos proyectos y manos "
        "hechas dando vueltas.",
),

"T077": dict(  # Board monótono
 que_es="Un board monótono tiene las 3 cartas del flop del mismo palo (por "
        "ejemplo Q♠9♠4♠).",
 por_que_importa="Cualquiera con dos cartas de ese palo ya tiene color hecho. Es "
        "el board donde más hay que respetar la posibilidad de color.",
 como_funciona="Mirá los palos del flop: si los 3 son iguales, es monótono. A "
        "partir de ahí, cualquier apuesta fuerte puede significar color; y si "
        "vos no tenés cartas de ese palo, tu mano hecha vale menos de lo "
        "normal.",
 cuando_lo_uso="Apenas ves el flop: '¿las 3 cartas son del mismo palo?'",
 cuando_no=None,
 ejemplo="Flop Q♠9♠4♠. Cualquiera con dos picas ya tiene color. Un trío de "
        "nueves ahí es fuerte, pero puede estar perdiendo contra un color.",
 error_comun="Ignorar el color posible porque 'yo tengo una mano hecha buena'. "
        "En un board monótono, hasta un full puede perder si el rival tiene "
        "escalera de color, y una mano hecha modesta pierde seguido contra el "
        "color.",
 idea_clave="Board monótono = 3 cartas del mismo palo. El color siempre está en "
        "juego.",
),

"T078": dict(  # Board rainbow
 que_es="Un board rainbow tiene las 3 cartas del flop de 3 palos distintos (por "
        "ejemplo K♠9♥4♣): ningún proyecto de color es posible todavía.",
 por_que_importa="Es una preocupación menos: nadie puede tener color hecho ni "
        "proyecto de color con solo 3 cartas de palos distintos en la mesa.",
 como_funciona="Mirá los palos: si los 3 son diferentes, es rainbow. Ojo: el "
        "turn o el river pueden repetir un palo y abrir una posibilidad de "
        "color que antes no existía.",
 cuando_lo_uso="Apenas ves el flop: '¿los 3 palos son distintos? Entonces, por "
        "ahora, no hay color en juego.'",
 cuando_no=None,
 ejemplo="Flop K♠9♥4♣: rainbow. Si el turn trae otra pica (por ejemplo 7♠), el "
        "board deja de ser rainbow y ahí sí puede haber proyecto de color.",
 error_comun="Suponer que como el flop es rainbow, el color nunca va a ser un "
        "problema en esa mano. Alcanza con que salga una carta más del mismo "
        "palo para que la situación cambie.",
 idea_clave="Board rainbow = 3 palos distintos en el flop. Sin color en juego, "
        "por ahora.",
),

"T079": dict(  # Board pareado
 que_es="Un board pareado tiene dos cartas del mismo valor entre las que "
        "salieron (por ejemplo J♠J♦4♣).",
 por_que_importa="Habilita el full house y el póker para cualquiera que tenga "
        "la tercera de ese valor. También hace que una doble pareja 'de las "
        "tuyas' sea menos segura.",
 como_funciona="Mirá si dos de las cartas del board repiten valor. A partir de "
        "ahí, cualquier carta de ese mismo valor en la mano de un rival le da "
        "trío usando la pareja del board, y si tenés vos la tercera, tenés "
        "póker.",
 cuando_lo_uso="Apenas ves el flop, turn o river: '¿hay dos cartas iguales en la "
        "mesa?'",
 cuando_no=None,
 ejemplo="Board J♠J♦4♣. Cualquiera con un J en la mano tiene trío de jotas. Si "
        "vos tenés Q♣Q♥, tu pareja de damas ya no es tan tranquila: un J solo en "
        "la mano del rival te pasa por arriba.",
 error_comun="Mirar un board pareado y solo pensar en tu propia mano, sin "
        "preguntarte quién más podría tener esa carta repetida.",
 idea_clave="Board pareado = dos cartas iguales en la mesa. Habilita tríos y "
        "fulls para cualquiera con esa carta.",
),

# ============================================================
# 4.4 — Proyectos y cartas clave
# ============================================================

"T080": dict(  # Posibilidades de escalera
 que_es="Mirar el board y preguntarte qué escaleras son posibles con las cartas "
        "que salieron.",
 por_que_importa="Te dice qué tan peligroso es el board para vos y qué tenés "
        "que vigilar en las próximas cartas.",
 como_funciona="Fijate qué tan cerca están los valores del board. Con 3 cartas "
        "seguidas o casi seguidas, hay varias escaleras posibles; con cartas "
        "muy separadas, casi ninguna.",
 cuando_lo_uso="En cada flop, turn y river nuevo: '¿qué escalera se podría estar "
        "armando acá?'",
 cuando_no=None,
 ejemplo="Board 9♠7♦6♣. Con 8-5 en la mano ya tenés escalera hecha: 5-6-7-8-9. "
        "Con T-8 también: 6-7-8-9-T. En cambio con 8-4 todavía NO tenés "
        "escalera: te falta un 5 o un T para completarla — es solo una "
        "posibilidad, no una mano hecha.",
 error_comun="Mirar solo si VOS tenés escalera, sin pensar qué escaleras podría "
        "tener el rival con ese board.",
 idea_clave="Mirá el board y preguntate qué escaleras son posibles, las tuyas y "
        "las del rival.",
),

"T081": dict(  # Posibilidades de color
 que_es="Mirar el board y preguntarte si hay o puede haber color en juego.",
 por_que_importa="Es la otra pregunta obligatoria junto con la de la escalera: "
        "te dice si tenés que cuidarte de un color hecho o de un proyecto.",
 como_funciona="Contá cuántas cartas de cada palo hay en el board. Con 3 del "
        "mismo palo (board monótono), el color ya es posible hecho. Con 2 del "
        "mismo palo, todavía no hay color, pero cualquiera con 2 cartas de ese "
        "palo está en proyecto.",
 cuando_lo_uso="En cada calle nueva: '¿cuántas cartas de un mismo palo hay en la "
        "mesa?'",
 cuando_no=None,
 ejemplo="Board K♠9♠4♦. Dos picas en la mesa: nadie tiene color todavía, pero "
        "cualquiera con dos picas en la mano está en proyecto de color.",
 error_comun="Confundir 'hay 2 cartas de un palo' con 'ya hay color'. Con 2 en "
        "el board hace falta 3 en tu mano, o esperar una carta más para "
        "completarlo.",
 idea_clave="Mirá cuántas cartas de un mismo palo hay en el board: 3 es color "
        "hecho posible, 2 es proyecto posible.",
),

"T082": dict(  # Proyectos (draws)
 que_es="Un proyecto (o 'draw') es una mano que todavía no está hecha, pero que "
        "se completa si sale la carta correcta. Cada una de esas cartas que te "
        "completan se llama un out (outs, en plural). Se dice 'proyecto "
        "abierto' cuando tenés 8 outs para la escalera, y 'gutshot' cuando "
        "tenés solo 4.",
 por_que_importa="Jugar bien un proyecto empieza por saber cuántas cartas "
        "realmente lo completan. Un proyecto abierto tiene el doble de chances "
        "que un gutshot. Esa cantidad de outs es, ni más ni menos, lo que más "
        "adelante vas a aprender a convertir en un número concreto de "
        "probabilidad: por ahora, alcanza con contarlos bien.",
 como_funciona="Proyecto abierto: tenés 4 cartas seguidas y te sirve una en "
        "cualquiera de las dos puntas. Gutshot: te falta una carta específica "
        "en el medio de la seguida.",
 cuando_lo_uso="Cada vez que tenés escalera a medio armar: '¿me sirve una carta "
        "de cualquiera de las dos puntas, o necesito una específica en el "
        "medio?'",
 cuando_no=None,
 ejemplo="Tenés 9♣8♦. Board: 7♠6♥2♣. Un 5 o un 10 te completa la escalera: "
        "proyecto abierto. Si en cambio tuvieras 9♣5♦ con ese mismo board, tenés "
        "9-7-6-5: te falta solo el 8 del medio. Gutshot.",
 error_comun="Tratar un gutshot como si tuviera las mismas chances que un "
        "proyecto abierto. Tiene la mitad de outs: hay que pagar mucho menos "
        "por él.",
 idea_clave="Proyecto = mano sin terminar que una carta puede completar. "
        "Abierto (8 outs) sirve por las dos puntas; gutshot (4 outs), solo por "
        "el medio. Contá los outs bien: más adelante se convierten en un "
        "número de probabilidad.",
),

"T083": dict(  # Proyecto backdoor
 que_es="Un proyecto backdoor es el que necesita las DOS cartas que faltan "
        "(turn y river) para completarse, no una sola.",
 por_que_importa="Es mucho menos probable que un proyecto normal, así que no "
        "debería ser el motivo principal para seguir jugando una mano — pero "
        "suma un poquito de valor extra a una mano que ya tenías ganas de jugar "
        "por otra razón.",
 como_funciona="En el flop, contás cuántas cartas de tu palo hay en la mesa. Con "
        "solo 1, necesitás que el turn Y el river traigan del mismo palo para "
        "completar color: eso es backdoor.",
 cuando_lo_uso="Como un plus menor al evaluar una mano en el flop, nunca como "
        "razón principal para pagar.",
 cuando_no=None,
 ejemplo="Tenés A♠5♠. Board: K♠9♥2♣. Solo hay una pica en la mesa: si el turn Y "
        "el river traen picas, completás color backdoor. Es un extra, no algo "
        "para contar como si ya tuvieras proyecto.",
 error_comun="Pagar una apuesta grande pensando 'tengo backdoor de color' como "
        "si fuera un proyecto real. Necesita dos cartas exactas seguidas: es "
        "mucho menos probable.",
 idea_clave="Backdoor = necesita las dos cartas que faltan. Es un plus chico, no "
        "una razón para pagar.",
),

"T084": dict(  # Cartas peligrosas
 que_es="Una carta peligrosa (o 'scare card') es una carta del turn o del river "
        "que puede haber completado algo fuerte para el rival y empeorar tu "
        "situación.",
 por_que_importa="Reconocerla te avisa cuándo tenés que frenar o desconfiar, "
        "aunque tu propia mano no haya cambiado en nada.",
 como_funciona="Preguntate, ante cada carta nueva: '¿esta carta completa una "
        "escalera posible?, ¿trae el tercer palo de un color?, ¿empareja el "
        "board?'. Si la respuesta es sí a alguna, es peligrosa.",
 cuando_lo_uso="Cada vez que sale el turn o el river, antes de decidir.",
 cuando_no=None,
 ejemplo="Tenés trío de nueves (9♦9♥ + 9♠ del board). Board: 9♠7♣4♦, turn 6♠. "
        "Con 9-7-6-4 en la mesa, un 8 en el river deja 9-8-7-6 en el board: "
        "cualquiera con un simple 5 en la mano ya tiene escalera. Carta "
        "peligrosa para tu trío.",
 error_comun="Mirar solo si la carta te ayudó a vos, sin preguntarte qué le "
        "pudo dar al rival.",
 idea_clave="Carta peligrosa = puede haber completado algo fuerte para el "
        "rival. Frená a pensar cuando aparece.",
),

"T085": dict(  # Cartas que favorecen tu mano
 que_es="Identificar, calle a calle, qué cartas del turn o del river te ayudan "
        "específicamente a vos.",
 por_que_importa="Es la otra cara de la carta peligrosa: saber qué te conviene "
        "te ayuda a decidir si seguís pagando por ver la próxima carta.",
 como_funciona="Mirá tu proyecto o tu mano y preguntate: '¿qué carta la "
        "mejora?'. Puede ser una que completa tu color o escalera, o una que te "
        "da una pareja más fuerte.",
 cuando_lo_uso="Antes de pagar para ver una carta más: '¿qué necesito que "
        "salga?'",
 cuando_no=None,
 ejemplo="Tenés K♠Q♠. Board: J♠6♠2♦. Cualquier pica te completa color; un K o "
        "una Q te da una pareja alta. Ya sabés exactamente qué estás "
        "esperando.",
 error_comun="Seguir jugando 'a ver qué sale' sin tener claro qué carta "
        "específica te mejora.",
 idea_clave="Antes de pagar por ver una carta más, sabé exactamente qué carta "
        "te ayuda.",
),

"T086": dict(  # Cartas que favorecen al rival
 que_es="Pensar, calle a calle, qué cartas podrían estar ayudando al rival "
        "según cómo jugó la mano hasta ahí.",
 por_que_importa="Completa el cuadro: no alcanza con mirar tu propia mano y tus "
        "propias cartas buenas; el rival también tiene cartas que lo mejoran, y "
        "a veces coinciden con las tuyas.",
 como_funciona="Mirá el board y preguntate qué proyectos son posibles ahí y qué "
        "manos hechas caben. Esas son las cartas que, si aparecen, probablemente "
        "lo ayudan a él.",
 cuando_lo_uso="Junto con leer tus propias cartas buenas, cada vez que sale una "
        "carta nueva: pensás las dos caras, la tuya y la de él.",
 cuando_no=None,
 ejemplo="Tenés trío de seises (6♦6♥ + 6♣ del board). Board: J♠9♠6♣. Un 10 o "
        "una pica más ayudan a cualquiera que tenga un proyecto de escalera o de "
        "color: son cartas que probablemente lo favorecen a él, aunque tu trío "
        "siga siendo trío.",
 error_comun="Suponer que si tu mano no cambió, la situación tampoco cambió. El "
        "board le puede haber dado algo mejor al rival sin tocar tu mano en "
        "nada.",
 idea_clave="Cada carta nueva puede ayudarte a vos, a él, o a los dos. Pensá "
        "siempre las dos caras.",
),

# ============================================================
# 4.5 — Tu mano hecha en el flop
# ============================================================

"T087": dict(  # La fuerza de una pareja
 que_es="La idea de que no todas las parejas valen lo mismo: depende de qué tan "
        "alta es respecto de las otras cartas del board.",
 por_que_importa="'Tengo pareja' no te dice casi nada por sí solo. Una pareja "
        "puede ser la mejor mano posible en ese board, o casi la peor.",
 como_funciona="Comparás el valor de tu pareja con las otras cartas del board: "
        "cuanto más arriba esté tu pareja respecto de ellas, más fuerte es. Las "
        "próximas teorías (top pair, middle pair, bottom pair) le ponen nombre "
        "a cada caso.",
 cuando_lo_uso="Cada vez que armás una pareja: no te quedes en 'tengo pareja', "
        "seguí preguntando '¿qué tan buena es en este board?'",
 cuando_no=None,
 ejemplo="Board J♠7♦2♣. Una pareja de jotas y una pareja de doses son las dos "
        "'una pareja', pero están en mundos distintos.",
 error_comun="Tratar toda pareja como si fuera igual de fuerte. El board dice "
        "mucho más que la palabra 'pareja'.",
 idea_clave="Una pareja vale según su posición respecto del board, no solo por "
        "existir.",
),

"T088": dict(  # Top pair
 que_es="Top pair es cuando tu pareja se forma con la carta más alta del "
        "board.",
 por_que_importa="Es, en general, la mejor pareja posible en ese flop — aunque "
        "no es automáticamente una mano invencible: hay que seguir mirando el "
        "kicker y el resto del board.",
 como_funciona="Mirá la carta más alta del board y fijate si una de tus cartas "
        "privadas coincide con ella.",
 cuando_lo_uso="Al leer tu mano en el flop: '¿emparejé la carta más alta de la "
        "mesa?'",
 cuando_no=None,
 ejemplo="Board K♠7♦2♣. Tenés K♥9♠: emparejaste el rey, la carta más alta del "
        "board. Eso es top pair, con kicker 9.",
 error_comun="Confiar ciegamente en cualquier top pair. Con un kicker bajo, un "
        "top pair puede perder contra otro top pair mejor acompañado.",
 idea_clave="Top pair = pareja con la carta más alta del board. Buena, pero no "
        "invencible.",
),

"T089": dict(  # Middle pair
 que_es="Middle pair es cuando tu pareja se forma con la carta del medio del "
        "board (ni la más alta, ni la más baja).",
 por_que_importa="Es una mano incómoda: le gana a manos peores, pero un top "
        "pair del rival —muy posible— la deja atrás.",
 como_funciona="Ordená las 3 cartas del flop de mayor a menor y fijate cuál "
        "emparejaste. Si es la del medio, tenés middle pair.",
 cuando_lo_uso="Al leer tu mano en el flop: '¿emparejé la carta del medio?'",
 cuando_no=None,
 ejemplo="Board K♠7♦2♣. Tenés 7♥9♠: emparejaste el 7, la carta del medio. "
        "Middle pair.",
 error_comun="Jugar un middle pair con la misma confianza que un top pair. "
        "Contra apuestas grandes, un middle pair necesita mucho más cuidado.",
 idea_clave="Middle pair = pareja con la carta del medio del board. Ojo con lo "
        "que apuesta el rival.",
),

"T090": dict(  # Bottom pair
 que_es="Bottom pair es cuando tu pareja se forma con la carta más baja del "
        "board.",
 por_que_importa="Es la pareja más floja posible en ese flop: casi cualquier "
        "otra pareja del rival ya le gana.",
 como_funciona="Mirá la carta más baja del board y fijate si la emparejaste.",
 cuando_lo_uso="Al leer tu mano: '¿emparejé la carta más baja de la mesa?'",
 cuando_no=None,
 ejemplo="Board K♠7♦2♣. Tenés 2♥9♠: emparejaste el 2, la carta más baja. "
        "Bottom pair.",
 error_comun="Pagar apuestas grandes con un bottom pair 'porque es una pareja'. "
        "Suele ser una mano para soltar fácil frente a presión.",
 idea_clave="Bottom pair = pareja con la carta más baja del board. La más floja "
        "de las tres.",
),

"T091": dict(  # Overpair
 que_es="Un overpair es cuando tu pareja servida es más alta que las tres "
        "cartas del flop.",
 por_que_importa="Es distinto de top/middle/bottom pair: no emparejaste una "
        "carta del board, ya traías la pareja de tus cartas privadas y le gana a "
        "todo el board.",
 como_funciona="Comparás el valor de tu pareja servida con la carta más alta "
        "del board. Si tu pareja es más alta que esa carta, tenés overpair.",
 cuando_lo_uso="Al recibir una pareja servida y ver el flop: '¿mi pareja es más "
        "alta que todo lo que salió?'",
 cuando_no=None,
 ejemplo="Tenés Q♠Q♦. Board: J♠7♦2♣. Tu pareja de damas es más alta que el J, "
        "el 7 y el 2: overpair. Fuerte, aunque un J en manos del rival te "
        "complica.",
 error_comun="Confundir overpair con top pair. Son parecidos en fuerza, pero "
        "conceptualmente distintos: uno ya lo traías, el otro lo armaste con el "
        "board.",
 idea_clave="Overpair = tu pareja servida es más alta que todo el board.",
),

"T092": dict(  # Doble pareja (hecha)
 que_es="Formar una doble pareja usando tus 2 cartas privadas contra el board, "
        "típicamente emparejando dos de tus cartas con dos del board.",
 por_que_importa="Es un salto fuerte de categoría respecto de una sola pareja. "
        "Pero conviene distinguir una doble pareja 'de las tuyas' de una que ya "
        "viene armada en el board — esa última la comparte cualquiera.",
 como_funciona="Mirá si cada una de tus cartas privadas coincide con una carta "
        "distinta del board.",
 cuando_lo_uso="Al leer tu mano en el flop, turn o river.",
 cuando_no=None,
 ejemplo="Tenés K♠7♦. Board: K♥7♠2♣. Emparejaste el rey Y el 7 del board: doble "
        "pareja de reyes y sietes, hecha con tus dos cartas privadas.",
 error_comun="No notar cuándo la doble pareja ya está en el board (por ejemplo "
        "K♥7♠7♦) y que, en ese caso, cualquier rival la tiene también — no es "
        "tuya en particular.",
 idea_clave="Doble pareja hecha = tus dos cartas privadas emparejaron dos del "
        "board. Fijate si es realmente tuya o ya está en la mesa.",
),

"T093": dict(  # Set
 que_es="Un set es un trío formado con una pareja servida más una carta igual "
        "en el board.",
 por_que_importa="Es una de las manos más fuertes y mejor disimuladas del "
        "póker: nadie espera que tengas trío cuando solo hay una carta de ese "
        "valor a la vista en la mesa.",
 como_funciona="Necesitás haber empezado con una pareja servida, y que el board "
        "traiga una tercera carta de ese mismo valor.",
 cuando_lo_uso="Cuando jugás parejas servidas, especialmente las bajas: el "
        "objetivo es ligar el set.",
 cuando_no=None,
 ejemplo="Tenés 8♠8♦. Board: K♣8♥3♦. El 8 del board te da trío de ochos: un "
        "set. Nadie ve venir eso con solo un 8 a la vista.",
 error_comun="Confundir set con trips: en el set, la pareja es tuya y solo una "
        "carta viene del board. Es importante para saber si el rival puede "
        "tener el mismo trío que vos (con trips, sí puede; con set, casi "
        "nunca).",
 idea_clave="Set = pareja servida + una igual en el board. Fuerte y "
        "disimulado.",
),

"T094": dict(  # Trips
 que_es="Trips es un trío formado con UNA carta privada más DOS iguales en el "
        "board (al revés que el set).",
 por_que_importa="Es igual de fuerte que un set en cuanto a categoría, pero "
        "mucho menos disimulado: cualquiera con esa misma carta en la mano "
        "tiene el mismo trío que vos, y el kicker puede desempatar.",
 como_funciona="El board trae una pareja; si una de tus cartas privadas es del "
        "mismo valor, formás trips con esa pareja del board.",
 cuando_lo_uso="En boards pareados, al ver si tenés esa carta.",
 cuando_no=None,
 ejemplo="Tenés K♠4♦. Board: 4♣4♥9♠. Tu 4 más los dos 4 del board: trips de "
        "cuatros, con K de kicker.",
 error_comun="No pensar en el kicker con trips. Si otro jugador también tiene "
        "un 4, gana el que tenga mejor kicker — algo que casi no pasa con un "
        "set.",
 idea_clave="Trips = una carta tuya + pareja del board. Igual de fuerte que el "
        "set, pero menos disimulado: el kicker importa.",
),

# ============================================================
# 4.6 — Manos grandes y nuts (checkpoint del nivel)
# ============================================================

"T095": dict(  # Escalera (hecha)
 que_es="Completar una escalera usando alguna combinación de tus cartas "
        "privadas y el board.",
 por_que_importa="Es una categoría muy por encima de cualquier pareja o trío. "
        "Muchos principiantes no la ven venir en boards conectados.",
 como_funciona="Sumá tus 2 cartas privadas a las del board y fijate si hay 5 "
        "valores seguidos entre las 7.",
 cuando_lo_uso="En cualquier board donde haya cartas cercanas en valor: revisá "
        "siempre si armaste escalera.",
 cuando_no=None,
 ejemplo="Tenés J♠T♦. Board: 9♣8♥2♦, turn 7♠. J-T-9-8-7: escalera hecha.",
 error_comun="Festejar la escalera sin mirar si el board también trae 3 o más "
        "cartas del mismo palo. Una escalera puede estar perdiendo contra un "
        "color.",
 idea_clave="Escalera hecha = 5 seguidas entre tus 7 cartas. Fuerte, pero "
        "vulnerable al color.",
),

"T096": dict(  # Color (hecho)
 que_es="Completar un color usando alguna combinación de tus cartas privadas y "
        "el board.",
 por_que_importa="Categoría muy fuerte, pero no todos los colores son iguales: "
        "hay que fijarse si el tuyo es el más alto posible con ese palo.",
 como_funciona="Sumá tus 2 privadas a las del board; si hay 5 del mismo palo "
        "entre las 7, tenés color. La carta más alta de esas 5 decide qué tan "
        "bueno es tu color.",
 cuando_lo_uso="En cualquier board con 3 o más cartas de un mismo palo.",
 cuando_no=None,
 ejemplo="Tenés Q♠4♠. Board: J♠9♠2♦, turn 6♠. Cinco picas entre tus cartas y el "
        "board: color con la Q como carta más alta.",
 error_comun="Suponer que 'tengo color' ya es sinónimo de ganar. Si tu carta "
        "más alta de ese palo no es la más alta posible, alguien puede tener un "
        "color mejor.",
 idea_clave="Color hecho = 5 del mismo palo entre tus 7 cartas. Fijate si es el "
        "más alto posible, no des por sentado que ganás.",
),

"T097": dict(  # Full (hecho)
 que_es="Completar un full usando alguna combinación de tus cartas privadas y "
        "el board.",
 por_que_importa="Categoría altísima. En un board pareado, siempre hay que "
        "tener en cuenta que alguien —quizás vos— tenga full.",
 como_funciona="Necesitás un trío y una pareja entre tus 7 cartas. Puede salir "
        "de tu pareja servida + trío del board, de tu trío + pareja del board, "
        "o de combinaciones más raras con dos pares del board.",
 cuando_lo_uso="En cualquier board pareado: revisá si tenés trío y pareja al "
        "mismo tiempo.",
 cuando_no=None,
 ejemplo="Tenés K♠K♦. Board: K♣9♠9♦. Trío de reyes (tus dos + el del board) más "
        "pareja de nueves del board: full de reyes.",
 error_comun="No revisar el full cuando el board ya trae una pareja propia "
        "(como el 9-9 del ejemplo): ahí un full puede estar armado con muy "
        "poco.",
 idea_clave="Full hecho = trío + pareja entre tus 7 cartas. Revisalo siempre "
        "que el board esté pareado.",
),

"T098": dict(  # Los nuts
 que_es="'Los nuts' es la mejor mano posible que se puede armar en ese board "
        "específico, en ese momento de la mano.",
 por_que_importa="Tener los nuts significa que nadie te puede ganar en el "
        "showdown. Es el techo de fuerza para ese board.",
 como_funciona="Mirá las cartas del board y preguntate: '¿cuál sería la mejor "
        "mano de 5 cartas que alguien podría armar con estas cartas "
        "comunitarias?'. Esa es 'los nuts' en ese momento; puede cambiar con "
        "cada carta nueva.",
 cuando_lo_uso="En botes grandes, antes de comprometer muchas fichas: '¿tengo "
        "los nuts, o solo una mano fuerte?'",
 cuando_no=None,
 ejemplo="Board: K♠Q♠J♠T♦2♥. Los nuts ahí son la escalera de color con A♠T♠ — "
        "la mejor mano posible en ese board exacto.",
 error_comun="Creer que 'una mano muy fuerte' es lo mismo que 'los nuts'. Podés "
        "tener full y no ser los nuts si el board permite color o escalera de "
        "color.",
 idea_clave="Los nuts = la mejor mano posible en ese board. Nadie te gana si "
        "los tenés.",
),

"T099": dict(  # Cerca de los nuts (near-nuts)
 que_es="Una mano casi imbatible en ese board, pero que no es técnicamente la "
        "mejor posible: existe una mano —poco probable— que le gana.",
 por_que_importa="Es la zona más incómoda para manejar botes grandes: tu mano "
        "es fortísima, pero no podés estar 100% tranquilo.",
 como_funciona="Compará tu mano con lo que serían los nuts en ese board. Si hay "
        "una combinación concreta y posible que te gane, aunque sea poco "
        "probable, estás cerca de los nuts, no en los nuts.",
 cuando_lo_uso="Antes de jugarte todo el stack: '¿esto es lo mejor posible, o "
        "solo casi lo mejor?'",
 cuando_no=None,
 ejemplo="Board: K♠Q♠J♠T♦2♥ (el mismo de antes). Si tenés A♦K♣, tenés escalera "
        "con carta alta — muy fuerte, pero le pierde a cualquiera con A♠T♠ (la "
        "escalera de color). Estás cerca de los nuts, no en los nuts.",
 error_comun="Jugar una mano cerca de los nuts exactamente igual que si fueran "
        "los nuts. La diferencia, aunque rara, existe.",
 idea_clave="Cerca de los nuts = casi imbatible, pero no la mejor mano posible. "
        "Jugala fuerte, con un poquito de respeto.",
),

"T100": dict(  # Bluff catcher
 que_es="Un bluff catcher es una mano que solo le gana a un farol: si el rival "
        "tiene una mano de verdad fuerte —lo que se llama apostar 'por "
        "valor'—, pierde contra ella.",
 por_que_importa="Pagar con un bluff catcher es una apuesta sobre el rival, no "
        "sobre tus cartas: estás decidiendo si creés que está faroleando o no. "
        "Es de las decisiones más difíciles del póker.",
 como_funciona="Preguntate: 'si pago y el rival muestra las cartas, ¿le gano a "
        "algo que apostaría por valor, o solo le gano a un farol?'. Si la "
        "respuesta es 'solo a un farol', tenés un bluff catcher.",
 cuando_lo_uso="Cuando dudás si pagar una apuesta grande con una mano media, en "
        "el river sobre todo.",
 cuando_no=None,
 ejemplo="Tenés una pareja de reyes en un board donde ya no hay proyectos "
        "posibles. El rival apuesta fuerte: si tiene un full, perdés seguro; si "
        "está faroleando, ganás. Tu pareja de reyes es un bluff catcher.",
 error_comun="Pagar como bluff catcher solo por curiosidad, sin pensar si la "
        "historia de apuestas del rival realmente parece un farol.",
 idea_clave="Bluff catcher = le gana a un farol, pierde contra una mano de "
        "verdad. Pagar con él es apostar a que el rival está mintiendo.",
),

}
