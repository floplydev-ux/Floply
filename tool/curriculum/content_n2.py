# -*- coding: utf-8 -*-
"""
PASO 4 — Contenido redactado del NIVEL 2: "Ranking de manos".
16 teorías, 2 subniveles (2.1 Las 10 categorías · 2.2 Comparar y desempatar).
Banda FUNDAMENTAL. Voz: un buen profesor a alguien que empieza.

Fuente de verdad: curriculum_spec.json (IDs, títulos, objetivos, orden y
prerrequisitos no se tocan acá).

Meta de N2: mirar "mis cartas + la mesa" y responder "¿qué mano tengo y qué
tan fuerte es respecto de otra?".

Vocabulario: NO se asume probabilidad, equity, outs, pot odds, EV, rango,
posición ni estrategia avanzada. "kicker" se introduce en T061; antes se dice
"cartas de acompañamiento".
"""

N2 = {

# ============================================================
# 2.1 — Las 10 categorías (RECONOCER)
# ============================================================

"T006": dict(  # El ranking de manos
 que_es="Todas las manos de póker se ordenan en una escala fija, de la más débil a "
        "la más fuerte. En el showdown, gana la que está más arriba en la escala.",
 por_que_importa="Sin esta escala no podés saber si ganaste. Es la tabla que vas a "
        "tener en la cabeza el resto de tu vida como jugador: cuanto antes la "
        "automatices, mejor.",
 como_funciona="Son 10 categorías. De abajo hacia arriba: carta alta, pareja, doble "
        "pareja, trío, escalera, color, full, póker, escalera de color y —la mejor de "
        "todas— la escalera real. Cada categoría le gana a todas las de abajo, sin "
        "importar las cartas sueltas.",
 cuando_lo_uso=None,
 cuando_no=None,
 ejemplo="Un color (cinco del mismo palo) siempre le gana a una escalera (cinco "
        "seguidas), aunque la escalera use cartas más altas. La categoría manda "
        "primero.",
 error_comun="Comparar carta por carta antes de mirar la categoría. Primero la "
        "categoría; las cartas sueltas solo deciden si las dos manos caen en la misma "
        "categoría.",
 idea_clave="10 categorías, de carta alta a escalera real. La categoría más alta "
        "gana; recién si empatan se miran las cartas.",
),

"T050": dict(  # Carta alta
 que_es="Cuando tus 5 cartas no forman ninguna combinación —ni siquiera una "
        "pareja—, tu mano vale por su carta más alta. Se dice que tenés 'carta "
        "alta'.",
 por_que_importa="Es la mano más débil que existe. Reconocerla te avisa que, para "
        "ganar, casi seguro vas a necesitar mejorar o que el rival se retire.",
 como_funciona="Se mira tu carta más alta. Si empata con la del rival, la segunda "
        "más alta, y así hasta la quinta. Nada de parejas, nada de palos, nada de "
        "secuencias.",
 cuando_lo_uso="Cuando llegás al final y no ligaste nada. Tu mano es 'As alto', "
        "'Rey alto', etc.",
 cuando_no=None,
 ejemplo="Tenés A♠ 9♦. Board: K♣ 7♥ 4♠ 2♦ J♥. Tu mejor mano de 5: A K J 9 7. No hay "
        "ni una pareja: tenés 'As alto'.",
 error_comun="Pensar que 'tengo un As' ya es buena mano. Un As sin pareja sigue "
        "siendo carta alta: pierde contra cualquier pareja, hasta contra un par de "
        "doses.",
 idea_clave="Carta alta = no ligaste nada. Es la mano más débil: pierde contra "
        "cualquier pareja.",
),

"T051": dict(  # Pareja
 que_es="Una pareja son dos cartas del mismo valor (por ejemplo, dos reyes). Las "
        "otras 3 cartas de tu mano de 5 acompañan.",
 por_que_importa="Es la mano ligada más común. La mayoría de los botes chicos y "
        "medianos se ganan con una sola pareja.",
 como_funciona="Podés emparejar una de tus cartas con una del board, o traer la "
        "pareja ya en tus 2 cartas privadas. Entre dos parejas gana la de valor más "
        "alto: par de ases le gana a par de reyes.",
 cuando_lo_uso="Todo el tiempo: 'tengo pareja de reyes', 'emparejé el flop'.",
 cuando_no=None,
 ejemplo="Tenés Q♥ J♣. Flop: Q♠ 8♦ 3♥. Emparejaste tu dama: pareja de damas, con "
        "J, 8 y 3 de acompañamiento.",
 error_comun="Tratar todas las parejas igual. Una pareja de ases y una de treses "
        "son las dos 'una pareja', pero una gana casi siempre y la otra casi nunca.",
 idea_clave="Pareja = dos cartas iguales. Entre dos parejas, gana la más alta.",
),

"T052": dict(  # Doble pareja
 que_es="Dos parejas distintas dentro de la misma mano de 5 (por ejemplo, dos reyes "
        "y dos sietes). La quinta carta acompaña.",
 por_que_importa="Es bastante más fuerte que una pareja sola y gana muchos botes "
        "medianos. Pero es vulnerable: un trío o un full le ganan.",
 como_funciona="Entre dos dobles parejas: primero se compara la pareja más alta de "
        "cada uno; si empatan, la segunda pareja; si también empatan, la quinta "
        "carta.",
 cuando_lo_uso="'Tengo doble pareja', 'el board me dio dos pares'.",
 cuando_no=None,
 ejemplo="Tenés A♦ 9♠. Board: A♣ 9♥ 4♠ 2♦ 7♣. Dos ases y dos nueves: doble pareja "
        "(ases y nueves), con el 7 de acompañamiento.",
 error_comun="Enamorarte de la doble pareja cuando el board tiene una pareja propia "
        "(por ejemplo 9♥ 9♦): ahí alguien puede tener full y tu mano ya no es la "
        "mejor.",
 idea_clave="Doble pareja = dos parejas. Le gana a una pareja; le pierde a un trío "
        "o más.",
),

"T053": dict(  # Trío
 que_es="Tres cartas del mismo valor (por ejemplo, tres reyes). Las otras 2 cartas "
        "acompañan.",
 por_que_importa="Mano fuerte que gana botes grandes. Muchas veces es la mejor mano "
        "hasta el final.",
 como_funciona="Se forma con una pareja en tu mano más una carta igual en el board, "
        "o con una carta tuya más dos iguales en el board. Entre dos tríos, gana el "
        "de valor más alto.",
 cuando_lo_uso="'Ligué trío', 'tengo trío de ochos'.",
 cuando_no=None,
 ejemplo="Tenés 8♥ 8♦. Flop: 8♠ K♣ 4♦. Tres ochos: trío, con K y 4 de "
        "acompañamiento.",
 error_comun="Con el board K♠ K♦ 4♣ y K♥ Q♠ en la mano, cantar 'doble pareja'. No: "
        "tres reyes es trío de reyes (K K K Q 4).",
 idea_clave="Trío = tres cartas iguales. Le gana a la doble pareja.",
),

"T054": dict(  # Escalera
 que_es="Cinco cartas de valor seguido, de cualquier palo (por ejemplo, "
        "6-7-8-9-10). También se la llama 'seguida'.",
 por_que_importa="Mano fuerte que muchos principiantes no ven venir en el board. Le "
        "gana al trío y a la doble pareja.",
 como_funciona="Cuentan solo los valores, no los palos. El As sirve de carta más "
        "alta (10-J-Q-K-A) o de más baja (A-2-3-4-5). No se puede 'dar la vuelta': "
        "Q-K-A-2-3 no es escalera.",
 cuando_lo_uso="'Tengo escalera'; o al leer el board: 'hay cuatro cartas seguidas "
        "en el board, cuidado'.",
 cuando_no=None,
 ejemplo="Tenés 9♣ 8♦. Board: 7♠ 6♥ 5♣ K♦ 2♠. Con 9-8-7-6-5 tenés una escalera "
        "al 9.",
 error_comun="Contar una escalera 'casi hecha' como si estuviera lista. 8-9-J-Q, "
        "con el hueco del 10, todavía no es nada.",
 idea_clave="Escalera = 5 valores seguidos, palos mezclados. El As va arriba o "
        "abajo, nunca en el medio.",
),

"T055": dict(  # Color
 que_es="Cinco cartas del mismo palo (por ejemplo, cinco corazones), estén seguidas "
        "o no. En inglés, 'flush'.",
 por_que_importa="Mano fuerte: le gana a la escalera. Aparece seguido cuando el "
        "board trae tres o más cartas del mismo palo.",
 como_funciona="Cuenta el palo, no el orden. Entre dos colores del mismo palo gana "
        "el que tiene la carta más alta; si empata, la siguiente, y así.",
 cuando_lo_uso="'Tengo color'; o al leer el board: 'hay tres picas, alguien puede "
        "tener color'.",
 cuando_no=None,
 ejemplo="Tenés A♠ 4♠. Board: K♠ 9♠ 2♠ 7♦ 3♣. Cinco picas: color. Y como tenés el "
        "A♠, es el color más alto posible.",
 error_comun="Creer que 'tengo dos corazones' ya es color. Hacen falta cinco del "
        "mismo palo en tu mano de 5; con dos o tres, todavía no tenés nada.",
 idea_clave="Color = 5 del mismo palo. Le gana a la escalera. Entre dos colores, "
        "gana la carta más alta.",
),

"T056": dict(  # Full
 que_es="Un trío y una pareja juntos en la misma mano de 5 (tres reyes y dos "
        "sietes). En inglés, 'full house'. Se dice 'full de reyes'.",
 por_que_importa="Mano muy fuerte: le gana al color y a la escalera. Cuando el board "
        "tiene una pareja, siempre hay que tenerlo en cuenta.",
 como_funciona="Entre dos fulls decide primero el trío: full de reyes le gana a "
        "full de damas. Solo si los tríos empatan, decide la pareja.",
 cuando_lo_uso="'Tengo full'; o al leer el board: 'el board se emparejó, alguien "
        "puede tener full'.",
 cuando_no=None,
 ejemplo="Tenés K♥ K♦. Board: K♠ 9♣ 9♦ 4♠ 2♥. Tres reyes y dos nueves: full de "
        "reyes.",
 error_comun="Cantar 'full' cuando en realidad tenés trío y una carta suelta. Hace "
        "falta trío Y pareja: tres reyes con K-9-4 de acompañamiento es solo trío.",
 idea_clave="Full = trío + pareja. Le gana al color. Entre dos fulls, decide el "
        "trío.",
),

"T057": dict(  # Póker
 que_es="Cuatro cartas del mismo valor (cuatro ases). En inglés, 'four of a kind' o "
        "'quads'. La quinta carta acompaña.",
 por_que_importa="Mano casi imbatible: solo le gana una escalera de color. La vas a "
        "ver poquísimas veces.",
 como_funciona="Se forma con una pareja en tu mano más dos iguales en el board, o "
        "con tres iguales en el board más una tuya. Entre dos póker (rarísimo), gana "
        "el de valor más alto.",
 cuando_lo_uso="Cuando lo tenés, ya está: es casi seguro la mejor mano. El trabajo "
        "pasa a ser cobrar lo máximo.",
 cuando_no=None,
 ejemplo="Tenés 7♣ 7♠. Board: 7♥ 7♦ A♣ K♠ 2♦. Cuatro sietes: póker, con el As de "
        "acompañamiento.",
 error_comun="Confundir 'póker' (el juego) con 'póker' (la mano). Acá 'póker' es la "
        "mano de cuatro cartas del mismo valor.",
 idea_clave="Póker = 4 cartas iguales. Solo le gana una escalera de color.",
),

"T058": dict(  # Escalera de color
 que_es="Cinco cartas seguidas y todas del mismo palo (por ejemplo, 5-6-7-8-9 de "
        "picas). Junta lo mejor de la escalera y del color.",
 por_que_importa="La segunda mano más fuerte que existe. Solo le gana otra escalera "
        "de color más alta.",
 como_funciona="Tiene que cumplir las dos cosas a la vez: seguidas Y mismo palo. "
        "Entre dos, gana la que termina en la carta más alta.",
 cuando_lo_uso="Casi nunca: es rarísima. Cuando la tenés, es prácticamente "
        "imbatible.",
 cuando_no=None,
 ejemplo="Tenés 6♥ 5♥. Board: 7♥ 8♥ 9♥ K♣ 2♠. Con 9-8-7-6-5 de corazones tenés "
        "escalera de color al 9.",
 error_comun="Ver cuatro cartas del mismo palo casi seguidas en el board y asumir "
        "que alguien tiene la escalera de color. Necesita las dos cartas exactas: es "
        "muy poco probable.",
 idea_clave="Escalera de color = seguidas + mismo palo. Solo le gana otra más "
        "alta.",
),

"T059": dict(  # Escalera real
 que_es="La escalera de color más alta posible: 10-J-Q-K-A, todas del mismo palo. "
        "En inglés, 'royal flush'. Es tan especial que se la nombra aparte.",
 por_que_importa="Es la mejor mano del póker. No existe nada que le gane.",
 como_funciona="Es un caso puntual de escalera de color. No hay 'escaleras reales "
        "más chicas': o tenés 10-J-Q-K-A del mismo palo, o no. Solo se reparte el "
        "bote si la escalera real está entera en el board y todos la juegan.",
 cuando_lo_uso="Probablemente la veas unas pocas veces en toda tu vida de jugador.",
 cuando_no=None,
 ejemplo="Tenés A♦ K♦. Board: Q♦ J♦ 10♦ 5♣ 2♠. Tenés 10-J-Q-K-A de diamantes: "
        "escalera real. Imbatible.",
 error_comun=None,
 idea_clave="Escalera real = 10-J-Q-K-A del mismo palo. La mejor mano posible.",
),

# ============================================================
# 2.2 — Comparar y desempatar (ELEGIR · checkpoint del nivel)
# ============================================================

"T060": dict(  # Comparar por categoría
 que_es="Para ver quién gana, lo primero y más importante es la categoría de cada "
        "mano. La categoría más alta gana, sin mirar todavía las cartas sueltas.",
 por_que_importa="Es la regla que resuelve la mayoría de los showdowns de un "
        "vistazo. Solo cuando las dos manos son de la misma categoría hace falta "
        "afinar.",
 como_funciona="Ubicás cada mano en la escala de 10. La que está más arriba gana. "
        "Un trío de doses le gana a una doble pareja de ases y reyes: la categoría va "
        "antes que las cartas.",
 cuando_lo_uso="En cada showdown, como primer paso: '¿de qué categoría es la mía? "
        "¿y la de él?'.",
 cuando_no=None,
 ejemplo="Vos mostrás un color: A♠ K♠ 9♠ 5♠ 2♠. El rival muestra un full: K♥ K♦ K♣ "
        "Q♠ Q♥. El full está más arriba que el color: gana el rival, aunque tu color "
        "tenga un As.",
 error_comun="Empezar a comparar carta por carta antes de fijarte en la categoría. "
        "Perdés tiempo y te confundís.",
 idea_clave="Primero la categoría. Las cartas sueltas solo importan si las dos "
        "manos son de la misma categoría.",
),

"T061": dict(  # Comparar por kicker
 que_es="El kicker es el nombre técnico de lo que veníamos llamando 'carta de "
        "acompañamiento': una carta que no forma parte de tu combinación pero que "
        "sirve para desempatar contra una mano de la misma categoría.",
 por_que_importa="Muchísimos botes se deciden por el kicker, sobre todo cuando los "
        "dos jugadores emparejaron la misma carta del board. Ignorarlo es un error "
        "caro y muy común.",
 como_funciona="Si los dos tienen la misma pareja (por ejemplo, los dos emparejaron "
        "el As del board), se compara la carta más alta que la acompaña. A-K le gana "
        "a A-Q. Si esa también empata, la siguiente, hasta 5 cartas. Si las 5 son "
        "iguales, es empate (bote repartido).",
 cuando_lo_uso="Cuando compartís la mano hecha con el rival: misma pareja, mismo "
        "trío. Ahí decide el kicker.",
 cuando_no=None,
 ejemplo="Board: A♣ 9♦ 6♠ 3♥ 2♣. Vos tenés A♠ K♥ (pareja de ases, kicker K). El "
        "rival tiene A♦ Q♣ (pareja de ases, kicker Q). Los dos tienen par de ases; "
        "tu K le gana a su Q: ganás.",
 error_comun="Jugar fuerte 'A-cualquier cosa' solo porque tenés un As. Si emparejás "
        "el As pero tu otra carta es baja, tu kicker es malo y perdés contra "
        "cualquier As mejor acompañado.",
 idea_clave="Misma pareja o mismo trío → gana el mejor kicker. 'A-K' no es lo mismo "
        "que 'A-4'.",
),

"T007": dict(  # Desempates
 que_es="Las reglas completas para decidir quién gana cuando las dos manos son de "
        "la misma categoría.",
 por_que_importa="Cierra el tema: con la categoría más estas reglas, podés resolver "
        "cualquier showdown sin dudar.",
 como_funciona="Se comparan las 5 cartas de cada mano en orden de importancia. "
        "Pareja: primero el valor de la pareja, después los kickers de mayor a menor. "
        "Doble pareja: la pareja más alta, después la segunda, después el kicker. "
        "Trío y póker: el valor del trío o del póker. Escalera, color y escalera de "
        "color: la carta más alta. Full: primero el trío, después la pareja. Si las 5 "
        "cartas que cuentan son iguales, el bote se reparte.",
 cuando_lo_uso="Cada vez que dos manos caen en la misma categoría.",
 cuando_no=None,
 ejemplo="Board: A♠ 9♠ 4♠ 7♥ 2♣. Vos tenés K♠ J♠; el rival, Q♠ 8♠. Los dos tienen "
        "color de picas. Se compara de mayor a menor: los dos usan el A♠ del board, "
        "pero después tu K le gana a su Q. Ganás.",
 error_comun="Repartir el bote 'porque los dos tienen color'. Solo se reparte si "
        "las 5 cartas que cuentan son idénticas; casi siempre alguna desempata.",
 idea_clave="Misma categoría → se comparan las 5 cartas en orden. Solo hay reparto "
        "si son idénticas.",
),

"T062": dict(  # Cuando el board juega
 que_es="A veces las 5 cartas del board forman una mano mejor que cualquier cosa "
        "que puedas armar con tus cartas privadas. Ahí 'juega el board': todos usan "
        "las 5 comunitarias y el bote se reparte entre los que quedan.",
 por_que_importa="Es una causa muy común de bote repartido. Si no lo reconocés, "
        "cantás 'gané' cuando en realidad empataste con toda la mesa.",
 como_funciona="Tu mano de 5 nunca puede ser peor que el board: siempre podés usar "
        "las 5 comunitarias. Si tus 2 cartas privadas no mejoran esa mano, jugás el "
        "board igual que todos.",
 cuando_lo_uso="Cuando el board ya es una mano fuerte por sí solo: una escalera, un "
        "color, una doble pareja alta.",
 cuando_no=None,
 ejemplo="Board: 10♥ J♥ Q♥ K♥ A♥. El board es una escalera real de corazones: nadie "
        "puede mejorarla. No importa qué tengas en la mano — el bote se reparte entre "
        "todos los que llegaron.",
 error_comun="Ver 'tengo pareja' y cantar victoria sin notar que el board ya trae "
        "una doble pareja más alta que tu pareja. Tu mano no es tu pareja: es la "
        "mejor de 5, y puede ser la del board.",
 idea_clave="Si el board es mejor que lo tuyo, jugás el board — y probablemente "
        "repartís el bote.",
),

"T063": dict(  # Elegir la mejor combinación de 5
 que_es="El paso práctico de mirar tus 7 cartas (2 privadas + 5 del board) y armar "
        "la mejor mano de 5 posible. Es lo que hacés, en la cabeza, en cada "
        "showdown.",
 por_que_importa="Es la habilidad que cierra el Nivel 2. Si la tenés, podés mirar "
        "cualquier mano y decir qué tenés y qué tan fuerte es.",
 como_funciona="Un método simple, siempre en el mismo orden: 1) el palo — ¿hay "
        "cinco del mismo? 2) la secuencia — ¿hay cinco seguidas? 3) los repetidos — "
        "¿pares, tríos, póker? Te quedás con la categoría más alta que encontrás y "
        "completás con las cartas más altas que sobren.",
 cuando_lo_uso="En cada showdown, y cada vez que sale una carta nueva en el board.",
 cuando_no=None,
 ejemplo="Tenés A♠ A♥. Board: A♦ K♣ K♠ 5♥ 5♦. Tus 7 cartas: A A A K K 5 5. La mejor "
        "mano de 5 no es 'tres ases y dos cincos': es tres ases con el par de reyes, "
        "full de ases. Los cincos sobran.",
 error_comun="Agarrar la primera combinación que ves. Con A-A-A-K-K-5-5 hay varios "
        "fulls posibles; la mejor mano usa el par más alto disponible junto al trío.",
 idea_clave="Mirá palo, después secuencia, después repetidos. Quedate con la "
        "categoría más alta y las cartas más altas.",
),

}
