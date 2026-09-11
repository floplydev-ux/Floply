# -*- coding: utf-8 -*-
"""
PASO 4 — Contenido redactado del NIVEL 10: "Leer al rival".
13 teorías, 4 subniveles. Banda AVANZADO, estadio DECIDIR (10.1-10.3) y
EXPLICAR (10.4). Voz: profesor de póker rioplatense.

Fuente de verdad: curriculum_spec.json.

Meta de N10: juntar todo lo que ya sabés sobre rangos por acción (N5-N9,
cada uno enseñado por separado) en un solo proceso continuo: leer la
LÍNEA completa de una mano, calle por calle, para terminar decidiendo si
lo que el rival hizo representa valor o farol.

Vocabulario nuevo de N10: (formaliza, no inventa) línea de juego,
estrechar el rango (narrowing), coherencia de la línea.

NO se enseña todavía: ventaja de rango/nuts/posicional formales,
bloqueadores, remoción de combos, MDF, GTO/explotación (N11) — acá se
cuenta combos (ya sabido desde N5) para estrechar el rango, pero no se
habla todavía de "remover" combos por tus propias cartas (eso es T233,
N11).
"""

N10 = {

# ============================================================
# 10.1 — Cada acción es información
# ============================================================

"T211": dict(  # Las acciones son información
 que_es="Cada acción del rival — abrir, pagar, subir, pasar — es una "
        "pista sobre su mano. Juntando todas las pistas de la mano, "
        "podés reconstruir un rango cada vez más ajustado.",
 por_que_importa="Ya veníamos usando esta idea por separado en cada "
        "nivel (rango de apertura en N5, rango después de una c-bet en "
        "N8...). Acá se formaliza como un proceso único que se repite "
        "en cada acción de toda la mano.",
 como_funciona="Después de cada acción del rival, actualizás mentalmente "
        "su rango: sacás las manos que no encajan con lo que acaba de "
        "hacer, y te quedás con las que sí.",
 cuando_lo_uso="Después de CADA acción del rival, en cualquier punto de "
        "la mano — no solo al final.",
 cuando_no=None,
 ejemplo="El rival abre (te da una primera pista: su rango de "
        "apertura), después c-betea el flop (otra pista: iniciativa + "
        "rango de esa posición), después apuesta el turn de nuevo (otra "
        "pista más). Cada una recorta un poco más su rango real.",
 error_comun="Solo mirar la ÚLTIMA acción del rival para decidir, "
        "ignorando toda la información que ya juntaste en las calles "
        "anteriores.",
 idea_clave="Cada acción es una pista. El rango del rival se construye "
        "sumando pistas, no mirando solo la última.",
),

"T212": dict(  # El rango después de un open
 que_es="El primer paso de esa reconstrucción: el rango del rival "
        "después de abrir es, simplemente, su rango de apertura (N5) "
        "para esa posición.",
 por_que_importa="Es el punto de partida de toda lectura: antes de "
        "cualquier otra acción, ya tenés una primera estimación basada "
        "en dónde estaba sentado cuando abrió.",
 como_funciona="Usás lo que ya sabés (N5, 5.5): UTG angosto y fuerte, "
        "botón ancho, y así con cada posición.",
 cuando_lo_uso="Como primer paso de la lectura, apenas el rival hace su "
        "primera acción de la mano.",
 cuando_no=None,
 ejemplo="El rival abre desde UTG: tu primera estimación de su rango ya "
        "es que es angosto y fuerte, antes de que pase nada más en la "
        "mano.",
 error_comun="Ignorar la posición del open como primer dato, esperando "
        "a tener 'más información' cuando en realidad ya tenías la "
        "primera pista desde el arranque.",
 idea_clave="El rango después de un open = el rango de apertura de esa "
        "posición. El punto de partida de toda lectura.",
),

"T213": dict(  # El rango después de un call
 que_es="El rango del rival después de pagar (en vez de subir) tiende a "
        "quedar compuesto por manos que juegan bien con el bote chico "
        "— ni tan fuertes como para subir, ni tan flojas como para "
        "foldear.",
 por_que_importa="Un call es una pista distinta a un raise: te dice que "
        "el rival, con esa mano, prefirió no agrandar el bote — algo "
        "que ya viste con el rango de call (N7, T160).",
 como_funciona="Sacás del rango de apertura las manos que, con esa "
        "acción, más probablemente hubieran subido en vez de pagar "
        "(las más fuertes de valor y los faroles) y te quedás con lo "
        "que suele pagar: manos medias con buen potencial.",
 cuando_lo_uso="Cada vez que el rival responde con un call en vez de "
        "una subida.",
 cuando_no=None,
 ejemplo="El rival paga tu open en vez de 3-betear: su rango ahí "
        "probablemente ya no incluye sus manos más fuertes (esas suelen "
        "preferir 3-betear) ni sus faroles más flojos (esos suelen "
        "foldear).",
 error_comun="Tratar un call como si dejara el rango exactamente igual "
        "de amplio que antes de esa acción.",
 idea_clave="Un call filtra el rango: quedan las manos medias que "
        "juegan bien con el bote chico, no las más fuertes ni las más "
        "flojas.",
),

"T216": dict(  # El rango después de un raise
 que_es="El rango del rival después de subir postflop (un check-raise, "
        "por ejemplo) tiende a estar más polarizado: manos fuertes de "
        "valor o proyectos con buenos outs jugados como semi-farol, y "
        "poco en el medio.",
 por_que_importa="Subir cuesta más fichas que pagar: los jugadores "
        "suelen reservar esa jugada para sus mejores manos o sus "
        "mejores semi-faroles, no para cualquier mano media.",
 como_funciona="Pensá en lo que ya sabés del check-raise (N8, TN06-"
        "TN07): valor o semi-farol. Ese mismo patrón aplica a cualquier "
        "raise postflop.",
 cuando_lo_uso="Cada vez que el rival sube una apuesta en el flop, "
        "turn o river.",
 cuando_no=None,
 ejemplo="El rival te sube tu c-bet: su rango ahí probablemente combina "
        "manos ya hechas fuertes con algunos proyectos de buenos outs "
        "— no manos medias que preferirían solo pagar.",
 error_comun="Asumir que cualquier raise significa automáticamente 'la "
        "mejor mano posible', ignorando que también puede ser un "
        "semi-farol con buenos outs.",
 idea_clave="Un raise postflop suele venir de un rango polarizado: "
        "valor fuerte o semi-farol, poco en el medio.",
),

"T217": dict(  # El rango después de un check
 que_es="El rango del rival después de pasar no es 'nada': puede "
        "incluir manos medias, proyectos, e incluso alguna mano fuerte "
        "jugando pot control (N9). Pero SÍ suele quedar sin sus manos "
        "MÁS fuertes, porque esas suelen preferir apostar.",
 por_que_importa="Leer bien un check evita dos errores opuestos: "
        "pensar que 'pasó, seguro no tiene nada' (falso: puede tener "
        "pot control) o 'pasó, puede tener cualquier cosa' (tampoco: "
        "sus manos más fuertes suelen apostar).",
 como_funciona="Un check saca del rango, sobre todo, las manos que casi "
        "siempre apostarían solas (los value bets más claros). Deja "
        "manos medias, proyectos, y a veces manos fuertes jugando con "
        "cautela.",
 cuando_lo_uso="Cada vez que el rival pasa en vez de apostar, en "
        "cualquier calle.",
 cuando_no=None,
 ejemplo="El rival pasa el turn en un board donde una mano muy fuerte "
        "casi siempre apostaría: eso hace bastante menos probable (sin "
        "descartarlas del todo) que tenga esas manos más fuertes.",
 error_comun="Interpretar cualquier check como 'debilidad total', "
        "olvidando que el pot control (N9) también usa el check con "
        "manos buenas.",
 idea_clave="Un check suele sacar del rango las manos MÁS fuertes (que "
        "casi siempre apuestan solas), no todas las manos buenas.",
),

# ============================================================
# 10.2 — Rango tras agresión
# ============================================================

"T214": dict(  # El rango después de una 3-bet
 que_es="El rango del rival después de 3-betear (N7): combina sus "
        "manos de valor más fuertes con algunos faroles elegidos "
        "(T161).",
 por_que_importa="Ya lo estudiaste como concepto en N7 (T167); acá lo "
        "sumás al proceso general de leer TODA la línea de la mano, "
        "junto con las acciones que vengan después.",
 como_funciona="Repasás lo que ya sabés: un rango de 3-bet mezcla valor "
        "y farol, ajustado por posición y por si fue una 3-bet simple o "
        "un squeeze (N7, TN17).",
 cuando_lo_uso="Como uno de los pasos de la línea completa: cada vez "
        "que el rival 3-beteó en algún momento de la mano.",
 cuando_no=None,
 ejemplo="El rival 3-beteó preflop: al llegar al flop, ya sabés que su "
        "rango combina valor fuerte y algunos faroles — el resto de la "
        "línea (c-bet, turn, river) va a seguir recortando ese rango.",
 error_comun="Volver a explicar desde cero qué es un rango de 3-bet en "
        "vez de usarlo como un dato ya conocido dentro de la línea "
        "completa.",
 idea_clave="El rango después de una 3-bet ya lo conocés (N7): valor + "
        "farol combinados. Acá es un paso más de la línea completa.",
),

"T215": dict(  # El rango después de una c-bet
 que_es="El rango del rival después de c-betear (N8): puede ser por "
        "valor, farol o proyecto, según el board, la posición y si el "
        "bote es multiway.",
 por_que_importa="Igual que con la 3-bet, ya estudiaste esto en N8; "
        "acá se convierte en otro paso más dentro de la línea completa "
        "que vas armando mano tras mano.",
 como_funciona="Repasás lo que ya sabés: c-bet por valor, farol o "
        "proyecto (N8, 8.2), ajustado por el tipo de board (8.3) y la "
        "posición (8.4).",
 cuando_lo_uso="Como uno de los pasos de la línea completa: cada vez "
        "que el rival c-beteó en algún momento de la mano.",
 cuando_no=None,
 ejemplo="El rival c-beteó un board coordinado: ya sabés (N8, T181) que "
        "eso suele ser más selectivo que en un board seco — un dato "
        "más para sumar a la línea completa.",
 error_comun="Tratar la c-bet como si fuera información aislada, sin "
        "conectarla con el resto de las acciones de la mano.",
 idea_clave="El rango después de una c-bet ya lo conocés (N8). Acá se "
        "suma como un paso más de la línea completa.",
),

# ============================================================
# 10.3 — Estrechar el rango
# ============================================================

"T218": dict(  # Estrechar el rango (narrowing)
 que_es="Estrechar el rango es el proceso de ir sacando manos del "
        "rango posible del rival, calle a calle, a medida que actúa.",
 por_que_importa="Es la idea central de todo el nivel: no leés el "
        "rango del rival una sola vez al final, lo vas recortando en "
        "cada acción, desde el open hasta el río.",
 como_funciona="Empezás con el rango más amplio posible (su rango de "
        "apertura) y, con cada acción nueva (T212-T217), sacás las "
        "manos que ya no son compatibles con lo que hizo.",
 cuando_lo_uso="A lo largo de toda la mano, actualizando tu estimación "
        "después de cada acción del rival.",
 cuando_no=None,
 ejemplo="El rival abre (rango amplio) → paga tu 3-bet (se recorta: "
        "salen sus manos más flojas y sus manos más fuertes que "
        "hubieran 4-beteado) → c-betea el flop (se recorta más, según "
        "el board) → apuesta el turn de nuevo (se recorta todavía más).",
 error_comun="Reiniciar la lectura en cada calle, en vez de seguir "
        "recortando el mismo rango que ya venías construyendo.",
 idea_clave="Estrechar el rango = recortarlo acción por acción, no "
        "adivinarlo de una sola vez al final.",
),

"T219": dict(  # Contar los combos posibles
 que_es="Usar el conteo de combos (N5, T133) para saber cuántas "
        "combinaciones concretas de cada mano le quedan al rival, "
        "después de estrechar su rango.",
 por_que_importa="No alcanza con decir 'todavía puede tener X': "
        "contar cuántos combos reales le quedan te dice qué tan "
        "probable es cada posibilidad, en vez de tratarlas todas por "
        "igual.",
 como_funciona="Para cada clase de mano que sigue en su rango después "
        "de estrechar (T218), contás cuántos combos reales representa "
        "(6 para una pareja, 4 suited + 12 offsuit para una no "
        "pareada) y comparás.",
 cuando_lo_uso="Al querer precisar qué tan probable es que el rival "
        "tenga una mano puntual, dentro de todo lo que su rango "
        "estrechado todavía permite.",
 cuando_no=None,
 ejemplo="Si su rango estrechado todavía incluye AA (6 combos) y AK "
        "(16 combos entre suited y offsuit), hay bastante más chance de "
        "que tenga AK que AA, simplemente por cantidad de combos.",
 error_comun="Tratar cada clase de mano que sigue en el rango como "
        "igual de probable, sin contar cuántos combos reales tiene "
        "cada una.",
 idea_clave="Contar combos te dice qué tan probable es cada mano "
        "dentro del rango ya estrechado, no solo si 'todavía es "
        "posible'.",
),

"T220": dict(  # La línea de juego
 que_es="La línea de juego es la secuencia COMPLETA de acciones del "
        "rival en toda la mano, leída como una sola historia — no "
        "acción por acción por separado.",
 por_que_importa="Una acción sola puede significar varias cosas. La "
        "secuencia completa, en cambio, suele contar una historia "
        "mucho más clara.",
 como_funciona="En vez de preguntarte '¿qué significa esta apuesta?', "
        "preguntate '¿qué mano jugaría exactamente así, desde el "
        "principio hasta acá?'.",
 cuando_lo_uso="Al llegar a una decisión importante (normalmente el "
        "river), mirando toda la mano de punta a punta.",
 cuando_no=None,
 ejemplo="Abrió, c-beteó el flop, apostó el turn, y ahora apuesta "
        "grande el río: esa secuencia completa (abrir + tres apuestas "
        "seguidas) es la línea de juego, y cuenta una historia distinta "
        "a cualquiera de esas acciones sueltas.",
 error_comun="Analizar solo la última apuesta sin mirar cómo se llegó "
        "hasta ahí — la historia completa suele decir mucho más.",
 idea_clave="La línea de juego es la mano entera contada como una "
        "historia, no una acción aislada.",
),

"T221": dict(  # La coherencia de la línea
 que_es="Evaluar si esa historia completa (T220) tiene sentido para una "
        "mano de valor, para un farol, o si hay algo que no encaja.",
 por_que_importa="Es el paso que te permite finalmente decidir: una "
        "línea coherente con valor te dice 'cuidado, probablemente "
        "tiene lo que representa'; una línea que no encaja bien puede "
        "ser un farol.",
 como_funciona="Preguntate: ¿qué mano jugaría CADA UNA de estas "
        "acciones, en este orden, en estos boards? Si hay una mano de "
        "valor real que encaja perfecto con toda la secuencia, la línea "
        "es coherente con valor. Si es difícil encontrar una mano de "
        "valor que jugaría exactamente así, puede ser un farol.",
 cuando_lo_uso="Después de reconstruir la línea completa (T220), como "
        "paso final antes de decidir.",
 cuando_no=None,
 ejemplo="Alguien que apostó fuerte en un board que mejoró mucho para "
        "un color, con una línea que encaja perfecto con tener ese "
        "color: coherente con valor. Alguien que apuesta fuerte en un "
        "board que no cambió para nada desde el flop, sin motivo claro "
        "para esa apuesta grande: menos coherente, más sospechoso de "
        "farol.",
 error_comun="Juzgar la línea solo por el tamaño de las apuestas, sin "
        "preguntarte qué mano de verdad jugaría toda esa secuencia.",
 idea_clave="Una línea coherente con valor encaja con una mano real en "
        "cada paso. Una línea rara, difícil de explicar con valor, "
        "huele a farol.",
),

# ============================================================
# 10.4 — ¿Valor o farol?
# ============================================================

"T222": dict(  # Identificar valor
 que_es="Reconocer cuándo la línea completa del rival representa "
        "valor: encaja con una mano real que quiere pago, en cada paso "
        "de la secuencia.",
 por_que_importa="Es la conclusión práctica de todo el nivel: juntar "
        "el rango estrechado (T218), los combos (T219) y la coherencia "
        "de la línea (T221) para decidir 'esto probablemente es "
        "valor'.",
 como_funciona="Si la secuencia de acciones coincide con lo que una "
        "mano fuerte haría en cada calle, y el rango estrechado todavía "
        "deja bastantes combos de esas manos fuertes, la conclusión es "
        "valor.",
 cuando_lo_uso="Al llegar a la decisión final del río, para decidir si "
        "foldear o pagar contra una apuesta que parece de valor.",
 cuando_no=None,
 ejemplo="Apostó cada calle en un board que mejoró mucho para un "
        "color, y su rango estrechado todavía incluye varios combos de "
        "ese color: la línea completa apunta a valor.",
 error_comun="Foldear contra cualquier apuesta grande 'por las dudas', "
        "sin haber hecho el trabajo de leer si la línea realmente "
        "apunta a valor.",
 idea_clave="Identificar valor = la línea completa encaja con una mano "
        "real que quiere pago.",
),

"T223": dict(  # Identificar faroles
 que_es="Reconocer cuándo la línea completa del rival representa un "
        "farol: no encaja bien con ninguna mano de valor real en "
        "alguno de los pasos de la secuencia.",
 por_que_importa="Es la otra cara de T222: te da la confianza para "
        "pagar como bluff catcher (N9, T202) cuando la línea, bien "
        "leída, no cuenta una historia creíble de valor.",
 como_funciona="Buscá el paso de la secuencia que 'no cierra': una "
        "apuesta en un board que no cambió nada, un tamaño raro para "
        "una mano de valor, una línea que no coincide con ninguna mano "
        "fuerte razonable.",
 cuando_lo_uso="Al llegar a la decisión final del río, para decidir si "
        "pagar contra una apuesta que parece un farol.",
 cuando_no=None,
 ejemplo="Apostó grande en un board que no cambió nada desde el flop, "
        "sin ninguna scare card (N9) de por medio, en una situación "
        "donde sus manos fuertes normalmente hubieran apostado antes: "
        "la línea completa no cierra con valor.",
 error_comun="Pagar cualquier apuesta grande 'porque puede ser farol', "
        "sin haber hecho el trabajo de leer si la línea realmente "
        "apunta a eso.",
 idea_clave="Identificar un farol = la línea completa no encaja con "
        "ninguna mano de valor real en algún punto de la secuencia.",
),

}
