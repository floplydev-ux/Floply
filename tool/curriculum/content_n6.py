# -*- coding: utf-8 -*-
"""
PASO 4 — Contenido redactado del NIVEL 6: "La matemática de continuar".
31 teorías, 7 subniveles. Banda INTERMEDIO, estadio DECIDIR en todo el
nivel. Voz: un buen profesor a alguien que empieza a leer situaciones.
Completo, no largo. Español rioplatense (vos / tenés).

Fuente de verdad: curriculum_spec.json (IDs, títulos, objetivos, orden y
prerrequisitos no se tocan acá).

Meta de N6: pasar de "leer la situación" (N4-N5) a "calcular si pagar sale
a cuenta". El alumno sale de N6 sabiendo: contar outs, estimar equity con
la regla del 2 y del 4, calcular pot odds y equity necesaria, entender
implied/reverse implied odds, y razonar en EV en vez de en "me siento
bien/mal con esta mano".

Vocabulario nuevo de N6: outs (limpios/sucios), equity, probabilidad,
regla del 2, regla del 4, precio del call, bote actual/final, pot odds,
equity necesaria, call rentable/perdedor, implied odds, reverse implied
odds, EV (valor esperado), decisión +EV/-EV, varianza, fold equity, farol.

EJEMPLO NUMÉRICO ÚNICO reutilizado en 6.4-6.7 (igual criterio que N4: un
solo hilo numérico en vez de inventar números nuevos en cada teoría):
  Bote antes de que el rival apueste: 4 BB. El rival apuesta 4 BB (apuesta
  del tamaño del bote). Precio del call: 4 BB. Bote actual (con la apuesta
  del rival adentro): 8 BB. Bote final si pagás: 12 BB. Pot odds: 8 a 4,
  o sea 2 a 1. Equity necesaria: 4/12 ≈ 33%. Con un proyecto de color con
  dos cartas por venir (9 outs, regla del 4 ≈ 36% de equity), el call es
  rentable: EV(call) = 0.36×8 − 0.64×4 = +0.32 BB.

NO se enseña todavía (llega en niveles posteriores): 3-bet, c-bet,
blockers, MDF, GTO/explotación, ICM. "Valor" (apostar por valor) ya se
había glosado en T100 (N4); acá se retoma sin volver a definirlo desde
cero.
"""

N6 = {

# ============================================================
# 6.1 — Outs
# ============================================================

"T101": dict(  # Outs
 que_es="Los outs son las cartas que todavía no salieron y que, si "
        "aparecen, mejoran tu mano — normalmente, a la mejor mano de la "
        "mesa en ese momento.",
 por_que_importa="Contar outs es el primer paso para cualquier cálculo "
        "sobre si vale la pena seguir en una mano donde todavía no tenés "
        "la mejor combinación, pero podrías tenerla.",
 como_funciona="Contás cuántas cartas, de las que quedan sin ver, "
        "completan lo que necesitás. Un proyecto de escalera abierta "
        "(cuatro cartas seguidas, por ejemplo 9-8-7-6, que se completa por "
        "los dos extremos) tiene 8 outs. Un proyecto de color (cuatro "
        "cartas del mismo palo) tiene 9 outs.",
 cuando_lo_uso="Cada vez que tenés una mano todavía no hecha del todo "
        "(un proyecto) y necesitás saber cuántas chances reales tenés de "
        "completarla.",
 cuando_no=None,
 ejemplo="Tenés 8♠7♠ y el flop trae 9♠6♦2♣. Cualquier 5 o cualquier 10 te "
        "completa una escalera: hay 4 cincos y 4 dieces en el mazo, "
        "8 outs en total.",
 error_comun="Contar outs 'a ojo' sin fijarse qué carta exacta hace "
        "falta. Cada out tiene que ser una carta real que de verdad "
        "complete tu mano.",
 idea_clave="Out = una carta que todavía no salió y que mejora tu mano. "
        "Contarlos es el primer paso antes de cualquier cálculo.",
),

"T102": dict(  # Outs limpios
 que_es="Los outs limpios son los outs que, si aparecen, te dan la mejor "
        "mano de la mesa sin ninguna duda razonable.",
 por_que_importa="No todos los outs valen lo mismo: contar solo outs "
        "limpios te da una estimación más confiable de tus chances reales "
        "de ganar la mano.",
 como_funciona="Preguntate, para cada out: 'si sale esta carta, ¿mi mano "
        "queda mejor que cualquier cosa razonable que pueda tener el "
        "rival?'. Si la respuesta es sí, es un out limpio.",
 cuando_lo_uso="Al revisar tu lista de outs, para separar los que te dan "
        "una mano segura de los que son más dudosos.",
 cuando_no=None,
 ejemplo="Con tu proyecto de escalera 8♠7♠ en un board 9♠6♦2♣ sin cartas "
        "parejadas ni proyecto de color visible, tus 8 outs a la "
        "escalera son, en principio, todos limpios: si completan, tenés "
        "la mejor mano casi seguro.",
 error_comun="Dar por limpio un out sin chequear si el board tiene otras "
        "posibilidades (color, otra escalera más alta) que puedan "
        "superarte igual.",
 idea_clave="Out limpio = te da la mejor mano sin dudas. Es el tipo de "
        "out en el que más confiás.",
),

"T103": dict(  # Outs sucios
 que_es="Los outs sucios son cartas que mejoran tu mano, pero no te "
        "garantizan ganar: pueden mejorarte a la SEGUNDA mejor mano, "
        "porque esa misma carta también puede mejorar al rival.",
 por_que_importa="Confiar en un out sucio como si fuera limpio te hace "
        "sobreestimar tus chances reales. Distinguirlos evita pagar de "
        "más pensando que estás más protegido de lo que estás.",
 como_funciona="Un out es sucio cuando, al completar tu proyecto, "
        "también completa (o puede completar) algo mejor para el rival "
        "— por ejemplo, la misma carta que te da color también le "
        "empareja el board a él para un full.",
 cuando_lo_uso="Al revisar tus outs en boards peligrosos (con posibilidad "
        "de color, escalera más alta, o cartas pareadas), donde alguno de "
        "tus outs también puede favorecer al rival.",
 cuando_no=None,
 ejemplo="Tenés un proyecto de color con A♠K♠ en un board 9♠8♦4♠ (9 "
        "outs a color). Uno de esos outs es justo el 8♠: si sale, "
        "completás tu color — pero esa misma carta también le da trío de "
        "ochos al rival, y si el rival ya tenía pareja de cuatros, ese "
        "trío se convierte en full. Ganás tu color y perdés la mano "
        "igual: ese out era sucio.",
 error_comun="Tratar cada out como si fuera garantía de ganar. Contra "
        "boards peligrosos, parte de tus outs pueden ser sucios sin que "
        "te des cuenta.",
 idea_clave="Out sucio = mejora tu mano, pero puede mejorar más todavía "
        "al rival. Cuenta menos que un out limpio.",
),

# ============================================================
# 6.2 — Equity
# ============================================================

"T104": dict(  # Equity
 que_es="La equity es el porcentaje de veces que tu mano termina "
        "ganando el bote, si la mano se jugara muchísimas veces desde "
        "ese mismo punto.",
 por_que_importa="Es la forma de poner un número a 'qué tan bien parado "
        "estás', más allá de si tenés la mejor mano ahora mismo. Una "
        "mano todavía no hecha puede tener mucha equity si tiene buenas "
        "chances de mejorar.",
 como_funciona="No es una certeza sobre esta mano puntual: es un "
        "promedio sobre todas las formas posibles en que puede terminar "
        "de desarrollarse el board. Más outs (T101), más equity, en "
        "general.",
 cuando_lo_uso="Para comparar qué tan bien parada está tu mano contra la "
        "del rival (o contra su rango), más allá del resultado de esta "
        "mano en particular.",
 cuando_no=None,
 ejemplo="Con un proyecto de color de 9 outs contra una pareja hecha, tu "
        "mano gana una buena porción de las veces que se juega esa "
        "situación — no todas, no ninguna: un porcentaje real, en el "
        "medio.",
 error_comun="Confundir equity con certeza. Tener equity alta no "
        "significa que vas a ganar esta mano puntual: significa que "
        "ganás más seguido que tu rival, jugando esa situación muchas "
        "veces.",
 idea_clave="Equity = tu porcentaje de victoria si la situación se "
        "repitiera muchas veces.",
),

"T105": dict(  # Equity contra una mano
 que_es="Estimar tu equity contra una mano concreta del rival: cuánto "
        "ganás, en porcentaje, si supieras exactamente qué dos cartas "
        "tiene.",
 por_que_importa="Es el caso más simple para practicar el concepto de "
        "equity: comparar una mano contra otra mano, antes de complicarlo "
        "con un rango entero de posibilidades.",
 como_funciona="Comparás tu mano y la del rival contra las cartas que "
        "todavía pueden salir. Cuantos más outs tengas para superarlo (o "
        "cuanto mejor sea tu mano ya hecha comparada con la de él), más "
        "alta tu equity.",
 cuando_lo_uso="Como ejercicio mental o cuando tenés muy buena "
        "información y podés acotar al rival a una mano casi exacta.",
 cuando_no=None,
 ejemplo="Tu proyecto de color con 9 outs contra una pareja hecha del "
        "rival: tu equity contra ESA mano puntual es la que corresponde a "
        "tus 9 outs con las cartas que faltan por salir.",
 error_comun="Usar este tipo de cálculo (contra una mano exacta) cuando "
        "en realidad no tenés forma de saber la mano puntual del rival "
        "— ahí corresponde pensar en rango, no en una mano (T106).",
 idea_clave="Equity contra una mano = el caso más simple: comparar tu "
        "mano contra una mano rival conocida o supuesta.",
),

"T106": dict(  # Equity contra un rango
 que_es="Estimar tu equity contra TODO el rango posible del rival, no "
        "contra una sola mano — promediando tu chance de ganar contra "
        "cada combinación que él podría tener.",
 por_que_importa="En la mesa real nunca sabés la mano exacta del rival: "
        "lo que tenés es su rango (T134, N5). Calcular tu equity contra "
        "ese conjunto completo es lo que de verdad corresponde a la "
        "situación real.",
 como_funciona="En vez de una sola comparación, es como calcular tu "
        "equity contra cada mano posible del rango y promediarlas todas, "
        "pesando más las combinaciones (combos) más probables.",
 cuando_lo_uso="En la práctica real de juego, siempre — porque casi "
        "nunca sabés la mano exacta del rival.",
 cuando_no=None,
 ejemplo="Tu proyecto de color contra el rango completo de apertura del "
        "rival desde el botón (que incluye manos fuertes, medias y "
        "flojas) te da una equity distinta que contra una sola mano "
        "puntual — generalmente, un poco más alta, porque el rango "
        "incluye combinaciones más flojas que una mano fuerte aislada.",
 error_comun="Seguir pensando 'contra qué mano exacta juego' en la mesa "
        "real, en vez de acostumbrarte a pensar contra el rango completo.",
 idea_clave="Equity contra un rango = tu chance de ganar promediada "
        "contra TODO lo que el rival podría tener, no una mano puntual.",
),

"T107": dict(  # Equity de un proyecto
 que_es="La equity de un proyecto es la equity que tiene específicamente "
        "una mano todavía no hecha (un draw) gracias a sus outs — la "
        "parte de tu equity que depende de completar algo en calles "
        "futuras.",
 por_que_importa="Los proyectos son el caso donde más se usa el cálculo "
        "de equity en la práctica: no tenés nada hecho todavía, pero "
        "tampoco nada — tenés una chance concreta que se puede medir.",
 como_funciona="Se relaciona directo con la cantidad de outs (T101): "
        "más outs, más equity de proyecto. En 6.3 vas a ver una forma "
        "rápida de pasar de 'cantidad de outs' a 'porcentaje aproximado'.",
 cuando_lo_uso="Cada vez que tenés un proyecto (color, escalera) y "
        "necesitás saber, aunque sea aproximadamente, qué tan seguido lo "
        "vas a completar.",
 cuando_no=None,
 ejemplo="Tu proyecto de color de 9 outs, con dos cartas por venir "
        "(turn y river), tiene una equity bastante considerable — lo "
        "suficiente como para justificar seguir en muchas situaciones, "
        "como vas a calcular con precisión en 6.3.",
 error_comun="Tratar 'tengo un proyecto' como si fuera automáticamente "
        "'tengo poca equity'. Un buen proyecto (muchos outs, dos cartas "
        "por venir) puede tener más equity que una mano hecha floja.",
 idea_clave="Equity de un proyecto = la chance real de completarlo, "
        "atada directamente a la cantidad de outs que tiene.",
),

"T110": dict(  # Probabilidad
 que_es="La probabilidad es la frecuencia con la que pasa algo, medida a "
        "largo plazo: si repetís la misma situación muchísimas veces, "
        "¿en qué porcentaje de esas veces ocurre lo que estás midiendo?",
 por_que_importa="Es la idea de fondo detrás de todo lo que veníamos "
        "usando en este subnivel: outs, equity, 'las veces que ganás'. "
        "Ponerle nombre te permite aplicar la misma lógica a cualquier "
        "situación nueva, no solo a estas.",
 como_funciona="Nada en una mano puntual es 'seguro' salvo lo que ya "
        "pasó. Todo lo demás son probabilidades: chances medidas en "
        "porcentaje, basadas en cuántas cartas favorables quedan sobre "
        "el total de cartas que pueden salir.",
 cuando_lo_uso="Como marco general para entender que la equity, los "
        "outs y (más adelante) el EV son todas aplicaciones de esta "
        "misma idea: frecuencia a largo plazo, no certeza en una mano.",
 cuando_no=None,
 ejemplo="Cuando dijiste 'tu proyecto de 9 outs tiene bastante equity', "
        "en el fondo estabas hablando de una probabilidad: la frecuencia "
        "con la que, repitiendo esa misma situación muchas veces, "
        "completás tu proyecto.",
 error_comun="Pensar la probabilidad como una predicción de ESTA mano "
        "puntual. Es una medida de frecuencia a largo plazo, no una bola "
        "de cristal sobre lo que va a pasar ahora.",
 idea_clave="Probabilidad = frecuencia a largo plazo. Es la idea de "
        "fondo detrás de outs, equity y (más adelante) EV.",
),

# ============================================================
# 6.3 — Estimar rápido
# ============================================================

"T108": dict(  # La regla del 2
 que_es="La regla del 2 es una forma rápida de estimar tu equity cuando "
        "queda UNA sola carta por salir (estás en el turn, esperando el "
        "river): multiplicá tu cantidad de outs por 2.",
 por_que_importa="Te ahorra un cálculo exacto en medio de la mesa: con "
        "una multiplicación simple, tenés una estimación bastante buena "
        "de tu equity real.",
 como_funciona="Contás tus outs (T101) y los multiplicás por 2. Eso te "
        "da un porcentaje aproximado de equity con una sola carta por "
        "venir.",
 cuando_lo_uso="En el turn, cuando te queda una sola carta por ver y "
        "querés estimar rápido tu equity.",
 cuando_no=None,
 ejemplo="Con 9 outs a color en el turn, la regla del 2 da 9×2 = 18%: "
        "aproximadamente 18% de chances de completar el color en el "
        "river.",
 error_comun="Usar la regla del 2 con dos cartas todavía por venir (por "
        "ejemplo, en el flop). Para eso está la regla del 4 (T109), que "
        "da una estimación distinta.",
 idea_clave="Regla del 2: outs × 2 ≈ % de equity con una carta por "
        "venir.",
),

"T109": dict(  # La regla del 4
 que_es="La regla del 4 es la misma idea que la regla del 2, pero para "
        "cuando quedan DOS cartas por salir (estás en el flop, esperando "
        "turn y river): multiplicá tu cantidad de outs por 4.",
 por_que_importa="Con dos cartas por venir tenés el doble de chances de "
        "conectar que con una sola, así que la estimación rápida también "
        "se ajusta.",
 como_funciona="Contás tus outs y los multiplicás por 4. Es una "
        "aproximación bastante buena para hasta unos 8 outs; con "
        "cantidades de outs más grandes, la estimación real es un poco "
        "menor a lo que da la multiplicación exacta.",
 cuando_lo_uso="En el flop, cuando te quedan dos cartas por ver y "
        "querés estimar rápido tu equity total para llegar al river.",
 cuando_no="Con muchísimos outs (14 o más, proyectos combinados), la "
        "regla del 4 empieza a sobreestimar bastante: ahí conviene "
        "desconfiar un poco del número exacto y saber que la equity real "
        "es algo menor.",
 ejemplo="Con 9 outs a color en el flop, la regla del 4 da 9×4 = 36%: "
        "aproximadamente 36% de chances de completar el color para el "
        "river (contando turn y river juntos).",
 error_comun="Aplicar la regla del 4 y después, si no completás en el "
        "turn, seguir usando ese mismo 36% para el river — ahí ya "
        "quedó una sola carta, corresponde la regla del 2 con los outs "
        "que sigan en pie.",
 idea_clave="Regla del 4: outs × 4 ≈ % de equity con dos cartas por "
        "venir (flop hasta river).",
),

# ============================================================
# 6.4 — El precio de continuar
# ============================================================

"T111": dict(  # El precio del call
 que_es="El precio del call es la cantidad de fichas que tenés que poner "
        "para igualar la apuesta del rival y seguir en la mano.",
 por_que_importa="Es el primer dato concreto que necesitás antes de "
        "cualquier cálculo sobre si conviene pagar: cuánto te cuesta "
        "seguir.",
 como_funciona="Simplemente es el tamaño de la apuesta que enfrentás: si "
        "el rival apostó 4 BB, tu precio del call es 4 BB.",
 cuando_lo_uso="Cada vez que enfrentás una apuesta y estás por decidir "
        "si pagar.",
 cuando_no=None,
 ejemplo="El rival apuesta 4 BB. Tu precio del call es, exactamente, "
        "4 BB — ese es el número de partida para todo lo que sigue en "
        "este subnivel.",
 error_comun="Confundir el precio del call con el bote total. El precio "
        "del call es solo lo que VOS tenés que poner, no todo lo que hay "
        "en el medio.",
 idea_clave="Precio del call = lo que tenés que poner vos para seguir en "
        "la mano.",
),

"T112": dict(  # El bote actual
 que_es="El bote actual es todo lo que hay en el medio de la mesa en el "
        "momento en que te toca decidir — ya incluye la apuesta del "
        "rival que estás por responder.",
 por_que_importa="Es el segundo dato que necesitás para cualquier "
        "cálculo de pot odds: cuánto podrías ganar si pagás y ganás la "
        "mano.",
 como_funciona="Sumá lo que ya había en el bote antes de esta ronda de "
        "apuestas más lo que el rival acaba de apostar. Eso es el bote "
        "actual, tal como lo ves en el momento de decidir.",
 cuando_lo_uso="Cada vez que enfrentás una apuesta: leés el bote actual "
        "antes de pensar en pagar.",
 cuando_no=None,
 ejemplo="Había 4 BB en el bote antes de que el rival apostara. El "
        "rival apuesta 4 BB más. El bote actual, en el momento de tu "
        "decisión, es 4 + 4 = 8 BB.",
 error_comun="Olvidarse de sumar la apuesta del rival al bote que había "
        "antes, y trabajar con un número más chico del real.",
 idea_clave="Bote actual = todo lo que hay en el medio ahora mismo, "
        "incluida la apuesta del rival.",
),

"T113": dict(  # La apuesta del rival
 que_es="Leer la apuesta del rival en relación al bote significa "
        "comparar cuánto apostó contra cuánto había en el bote antes de "
        "esa apuesta — por ejemplo, si apostó la mitad del bote o el bote "
        "entero.",
 por_que_importa="El tamaño relativo de una apuesta (no solo el número "
        "absoluto) te da información: apuestas más grandes suelen "
        "representar más fuerza o más presión, y además cambian cuánta "
        "equity necesitás para pagar rentable.",
 como_funciona="Dividí la apuesta del rival por el bote que había antes "
        "de esa apuesta. Si apostó lo mismo que había, apostó el 100% "
        "del bote (pot-size bet); si apostó la mitad, el 50%; y así.",
 cuando_lo_uso="Al leer una apuesta del rival, además de para calcular "
        "pot odds: el tamaño relativo también es información sobre la "
        "mano.",
 cuando_no=None,
 ejemplo="Había 4 BB en el bote. El rival apuesta 4 BB: apostó el 100% "
        "del bote — una apuesta grande.",
 error_comun="Fijarse solo en el número absoluto de la apuesta (\"apostó "
        "4 BB\") sin relacionarlo con el tamaño del bote, que es lo que "
        "de verdad dice si la apuesta es chica o grande.",
 idea_clave="El tamaño de una apuesta se lee en relación al bote, no en "
        "número absoluto: 4 BB puede ser una apuesta chica o gigante "
        "según cuánto había en el medio.",
),

"T114": dict(  # El bote final
 que_es="El bote final es cuánto va a haber en el medio si pagás la "
        "apuesta del rival: el bote actual más tu propio call.",
 por_que_importa="Es el número que en verdad importa para calcular pot "
        "odds: no lo que hay ahora, sino lo que habría DESPUÉS de que "
        "pongas tu call.",
 como_funciona="Sumá el bote actual (T112) más el precio del call "
        "(T111). Ese total es el bote final.",
 cuando_lo_uso="Como último dato antes de calcular pot odds (T115): "
        "siempre el paso previo a esa cuenta.",
 cuando_no=None,
 ejemplo="Bote actual: 8 BB. Precio del call: 4 BB. Bote final si pagás: "
        "8 + 4 = 12 BB.",
 error_comun="Calcular pot odds usando el bote actual en vez del bote "
        "final — hay que sumar tu propio call antes de comparar.",
 idea_clave="Bote final = bote actual + tu call. Es el número que se usa "
        "para calcular pot odds.",
),

# ============================================================
# 6.5 — Pot odds
# ============================================================

"T115": dict(  # Pot odds
 que_es="Las pot odds son la relación entre lo que arriesgás (tu call) y "
        "lo que podés ganar (el bote actual) si pagás y ganás la mano.",
 por_que_importa="Es la comparación central para decidir si un call "
        "tiene sentido matemático: te dice qué tan buen 'precio' te "
        "están dando para seguir jugando.",
 como_funciona="Comparás el bote actual (lo que podés ganar) contra tu "
        "precio del call (lo que arriesgás), expresado como una razón: "
        "'tantos a uno'.",
 cuando_lo_uso="Cada vez que enfrentás una apuesta y ya tenés el bote "
        "actual y el precio del call.",
 cuando_no=None,
 ejemplo="Bote actual: 8 BB. Precio del call: 4 BB. Las pot odds son "
        "8 a 4, o sea 2 a 1: arriesgás 4 BB para ganar 8 BB si acertás.",
 error_comun="Expresar las pot odds al revés (4 a 8 en vez de 8 a 4), lo "
        "que invierte completamente la lectura de si el precio es bueno "
        "o malo.",
 idea_clave="Pot odds = lo que podés ganar : lo que arriesgás. En el "
        "ejemplo, 2 a 1.",
),

"T116": dict(  # La equity necesaria
 que_es="La equity necesaria es el porcentaje mínimo de veces que tenés "
        "que ganar la mano para que un call, a largo plazo, no pierda "
        "fichas.",
 por_que_importa="Convierte las pot odds (una razón) en un porcentaje "
        "directamente comparable con tu equity real (T104-107) — así "
        "podés comparar manzanas con manzanas.",
 como_funciona="Se calcula como: precio del call ÷ bote final. Ese "
        "resultado, en porcentaje, es la equity mínima que necesitás.",
 cuando_lo_uso="Justo después de calcular pot odds, como paso siguiente "
        "antes de comparar contra tu equity real.",
 cuando_no=None,
 ejemplo="Precio del call: 4 BB. Bote final: 12 BB. Equity necesaria: "
        "4 ÷ 12 ≈ 33%. Necesitás ganar más del 33% de las veces para que "
        "el call no pierda fichas a la larga.",
 error_comun="Calcular la equity necesaria usando el bote actual en vez "
        "del bote final (que ya incluye tu propio call) — el denominador "
        "correcto es siempre el bote final.",
 idea_clave="Equity necesaria = precio del call ÷ bote final. En el "
        "ejemplo, ≈33%.",
),

"T117": dict(  # Comparar equity contra precio
 que_es="Comparar tu equity real (T104-107) contra la equity necesaria "
        "(T116) es el paso que finalmente responde si conviene pagar o "
        "no.",
 por_que_importa="Es donde se juntan las dos mitades del cálculo: cuánto "
        "ganás vos en realidad (tu equity) contra cuánto necesitás ganar "
        "como mínimo (la equity necesaria) para que valga la pena.",
 como_funciona="Si tu equity real es MAYOR que la equity necesaria, "
        "pagar gana fichas a la larga. Si es MENOR, pagar pierde fichas a "
        "la larga.",
 cuando_lo_uso="Como el paso final de la cadena outs → equity → pot "
        "odds → equity necesaria → esta comparación.",
 cuando_no=None,
 ejemplo="Tu proyecto de color (9 outs, regla del 4) tiene ≈36% de "
        "equity. La equity necesaria en esta mano es ≈33%. Como 36% > "
        "33%, pagar es rentable.",
 error_comun="Calcular ambos números por separado y no llegar a "
        "compararlos — el cálculo solo sirve si terminás con esta "
        "comparación.",
 idea_clave="Equity real > equity necesaria → pagar gana fichas a la "
        "larga. Equity real < equity necesaria → pagar pierde fichas.",
),

"T118": dict(  # Calls rentables
 que_es="Un call rentable es un call donde tu equity real supera la "
        "equity necesaria: a la larga, repitiendo esa misma decisión, "
        "ganás fichas.",
 por_que_importa="Es el resultado positivo de la comparación de T117: "
        "reconocerlo te da confianza para pagar aunque, en esa mano "
        "puntual, pierdas la mayoría de las veces.",
 como_funciona="Si ya calculaste que tu equity (36% en el ejemplo) "
        "supera la equity necesaria (33%), estás frente a un call "
        "rentable — aunque sigas perdiendo esa mano puntual el 64% de "
        "las veces.",
 cuando_lo_uso="Al reconocer, después de comparar equity contra precio, "
        "que el call es matemáticamente correcto.",
 cuando_no=None,
 ejemplo="36% de equity contra 33% necesario: call rentable. Vas a "
        "perder esa mano casi dos de cada tres veces, y aun así es la "
        "decisión correcta.",
 error_comun="Juzgar si un call fue 'bueno' por el resultado de esa mano "
        "puntual, en vez de por si era rentable a la larga cuando lo "
        "tomaste.",
 idea_clave="Call rentable = tu equity supera la equity necesaria. Gana "
        "fichas a la larga, aunque pierdas seguido en el corto plazo.",
),

"T119": dict(  # Calls perdedores
 que_es="Un call perdedor es un call donde tu equity real es MENOR que "
        "la equity necesaria: a la larga, repitiendo esa misma decisión, "
        "perdés fichas.",
 por_que_importa="Reconocerlo te da el permiso (y la razón matemática) "
        "para foldear, incluso con una mano que 'se siente' con ganas de "
        "seguir.",
 como_funciona="Si tu equity real es menor que la equity necesaria, "
        "pagar pierde fichas en promedio, aunque a veces ganes esa mano "
        "puntual.",
 cuando_lo_uso="Al reconocer, después de comparar equity contra precio, "
        "que el call es matemáticamente incorrecto.",
 cuando_no=None,
 ejemplo="Si en el mismo ejemplo tu equity real fuera 20% en vez de "
        "36%, con una equity necesaria de 33%, sería un call perdedor: "
        "20% < 33%.",
 error_comun="Pagar 'para ver' con una equity claramente por debajo de "
        "la necesaria, solo por curiosidad o porque la mano parece "
        "interesante.",
 idea_clave="Call perdedor = tu equity es menor que la equity necesaria. "
        "Pierde fichas a la larga, aunque a veces ganes esa mano "
        "puntual.",
),

"TN10": dict(  # Implied odds
 que_es="Las implied odds son una corrección a las pot odds: tienen en "
        "cuenta que, si completás tu proyecto, probablemente vas a poder "
        "ganar fichas EXTRA en las calles siguientes, más allá del bote "
        "final actual.",
 por_que_importa="A veces tu equity real es un poco menor que la "
        "necesaria por pot odds puras, pero el call igual conviene, "
        "porque completar tu proyecto te va a dejar ganar más fichas "
        "después.",
 como_funciona="Preguntate: si completo mi proyecto, ¿el rival me va a "
        "pagar más apuestas después? Cuanto más probable eso, más podés "
        "relajar la equity necesaria estricta de T116.",
 cuando_lo_uso="Con proyectos que, al completarse, quedan bien "
        "disimulados y es probable que el rival siga pagando después "
        "(por ejemplo, un proyecto de escalera contra una mano fuerte "
        "del rival).",
 cuando_no="Cuando es poco probable que el rival pague más fichas "
        "después de que completes tu proyecto (por ejemplo, si el board "
        "queda muy obvio y el rival se va a frenar).",
 ejemplo="Con tu proyecto de escalera, si el rival tiene una pareja de "
        "ases y vos completás en el river, es bastante probable que "
        "pague una apuesta más — esas fichas extra 'implican' que podés "
        "pagar el call actual con un poquito menos de equity de la que "
        "pedían las pot odds puras.",
 error_comun="Usar 'implied odds' como excusa para pagar con cualquier "
        "equity insuficiente, sin evaluar en serio si de verdad vas a "
        "ganar más fichas después.",
 idea_clave="Implied odds = fichas extra que esperás ganar en calles "
        "futuras si completás tu proyecto. Te permite pagar con un poco "
        "menos de equity que la estrictamente necesaria.",
),

"TN11": dict(  # Reverse implied odds
 que_es="Las reverse implied odds son el caso contrario a las implied "
        "odds (TN10): situaciones donde, incluso completando tu proyecto, "
        "podés terminar perdiendo un bote MÁS GRANDE, porque tu mano "
        "completada sigue siendo vulnerable a algo mejor.",
 por_que_importa="Te avisan que, en ciertos proyectos, la equity "
        "necesaria real debería ser MÁS ALTA que la que dan las pot odds "
        "puras — lo opuesto a las implied odds de TN10.",
 como_funciona="Preguntate: si completo mi proyecto, ¿existe una mano "
        "razonable que le gane igual? Si la respuesta es sí (por ejemplo, "
        "tu color no es el más alto posible), tenés reverse implied "
        "odds en contra.",
 cuando_lo_uso="Con proyectos donde tu mano completada puede seguir "
        "siendo vulnerable a algo mejor — por ejemplo, un color con "
        "cartas bajas en un board donde un color más alto también es "
        "posible.",
 cuando_no=None,
 ejemplo="Completás un color con 6♠4♠ en un board con tres picas: si el "
        "rival también tiene color, pero con cartas más altas, vas a "
        "pagar una apuesta más pensando que ganaste, y vas a perder un "
        "bote más grande todavía. Eso es reverse implied odds.",
 error_comun="Evaluar un proyecto solo por su cantidad de outs, sin "
        "pensar si, incluso completándolo, sigue siendo vulnerable a "
        "algo mejor.",
 idea_clave="Reverse implied odds = riesgo de perder MÁS fichas incluso "
        "después de completar tu proyecto, porque tu mano completada "
        "sigue sin ser la mejor posible.",
),

# ============================================================
# 6.6 — EV
# ============================================================

"T120": dict(  # El valor esperado (EV)
 que_es="El valor esperado (EV) es el resultado promedio que te deja una "
        "decisión si la repetís miles de veces: cuánto ganás o perdés, "
        "en promedio, por cada vez que la tomás.",
 por_que_importa="Es la forma más completa de evaluar una decisión: "
        "junta en un solo número tu equity y lo que hay en juego, y te "
        "dice si esa decisión suma o resta fichas a la larga.",
 como_funciona="EV = (probabilidad de ganar × lo que ganás si ganás) − "
        "(probabilidad de perder × lo que perdés si perdés).",
 cuando_lo_uso="Para evaluar cualquier decisión de forma completa, "
        "juntando todo lo que veníamos calculando en este nivel.",
 cuando_no=None,
 ejemplo="Con 36% de equity, ganás 8 BB (el bote actual) si acertás y "
        "perdés tu call de 4 BB si no: EV = (0.36 × 8) − (0.64 × 4) = "
        "2.88 − 2.56 = +0.32 BB. En promedio, esa decisión suma fichas.",
 error_comun="Juzgar una decisión por si ganaste o perdiste ESA mano, en "
        "vez de calcular el EV, que mide el promedio a largo plazo.",
 idea_clave="EV = resultado promedio de repetir la decisión muchas "
        "veces. Fórmula: (%gano × lo que gano) − (%pierdo × lo que "
        "pierdo).",
),

"T121": dict(  # Una decisión +EV
 que_es="Una decisión +EV es una decisión cuyo valor esperado es "
        "positivo: en promedio, gana fichas a la larga.",
 por_que_importa="Es el objetivo de cada decisión en la mesa: no ganar "
        "esta mano puntual (eso no lo controlás del todo), sino tomar "
        "decisiones que sumen fichas en promedio.",
 como_funciona="Si el resultado del cálculo de EV (T120) da un número "
        "positivo, la decisión es +EV.",
 cuando_lo_uso="Al calificar una decisión ya calculada como correcta a "
        "largo plazo.",
 cuando_no=None,
 ejemplo="El call del ejemplo (EV = +0.32 BB) es una decisión +EV: en "
        "promedio, repetirla suma fichas, aunque en esta mano puntual "
        "pierdas la mayoría de las veces.",
 error_comun="Pensar que 'perdí esa mano' significa que la decisión no "
        "era +EV. Una decisión +EV puede perder muchas manos puntuales y "
        "seguir siendo correcta.",
 idea_clave="+EV = suma fichas en promedio a la larga. Es el objetivo de "
        "cada decisión.",
),

"T122": dict(  # Una decisión -EV
 que_es="Una decisión -EV es una decisión cuyo valor esperado es "
        "negativo: en promedio, pierde fichas a la larga.",
 por_que_importa="Reconocerla es lo que te permite evitarla, incluso "
        "cuando 'tenés ganas' de tomarla o cuando en el pasado te salió "
        "bien de casualidad.",
 como_funciona="Si el resultado del cálculo de EV (T120) da un número "
        "negativo, la decisión es -EV.",
 cuando_lo_uso="Al calificar una decisión ya calculada como incorrecta a "
        "largo plazo, para evitar repetirla.",
 cuando_no=None,
 ejemplo="Con solo 20% de equity contra un 33% necesario: EV = "
        "(0.20 × 8) − (0.80 × 4) = 1.6 − 3.2 = −1.6 BB. Pagar ahí es una "
        "decisión -EV.",
 error_comun="Repetir una decisión -EV porque 'una vez salió bien'. Una "
        "sola mano no valida ni invalida una decisión: el promedio a "
        "largo plazo, sí.",
 idea_clave="-EV = pierde fichas en promedio a la larga. Se evita, "
        "aunque alguna vez haya salido bien.",
),

"T127": dict(  # El EV a largo plazo
 que_es="El EV a largo plazo es la idea de que una decisión correcta "
        "(+EV) puede perder esa mano puntual y, aun así, seguir siendo "
        "la decisión correcta.",
 por_que_importa="Es probablemente la idea más importante de todo el "
        "nivel: te libera de juzgar tus decisiones por el resultado "
        "inmediato, que tiene mucho de azar en el corto plazo.",
 como_funciona="Separá dos preguntas distintas: '¿gané esta mano?' y "
        "'¿tomé la decisión correcta?'. La segunda se responde con EV, no "
        "con el resultado de una mano puntual.",
 cuando_lo_uso="Cada vez que evalúes una decisión pasada — la tuya o la "
        "de un rival — para no confundir 'resultado' con 'calidad de la "
        "decisión'.",
 cuando_no=None,
 ejemplo="Pagaste con 36% de equity (call +EV) y perdiste esa mano "
        "puntual, como iba a pasar el 64% de las veces. La decisión "
        "siguió siendo correcta: el resultado de esa mano no la cambia.",
 error_comun="Arrepentirte de una decisión +EV solo porque esa vez "
        "perdiste, y empezar a evitarla en el futuro por esa sola mano.",
 idea_clave="Una decisión +EV puede perder la mano puntual y seguir "
        "siendo correcta. El resultado de una mano no define si la "
        "decisión fue buena.",
),

"TN12": dict(  # La varianza
 que_es="La varianza es cuánto pueden variar tus resultados de una mano "
        "a otra, incluso tomando siempre las decisiones correctas — es "
        "parte normal del juego, no una señal de que algo está mal.",
 por_que_importa="Sin entender varianza, es fácil confundir una mala "
        "racha (esperable, aunque juegues bien) con estar jugando mal, y "
        "empezar a cambiar decisiones correctas por otras peores.",
 como_funciona="Aceptá que, incluso jugando +EV todo el tiempo, vas a "
        "tener rachas de perder muchas manos seguidas. Eso es varianza, "
        "no una señal de error.",
 cuando_lo_uso="Al evaluar una racha de resultados (buena o mala) antes "
        "de sacar conclusiones sobre si estás jugando bien o mal.",
 cuando_no=None,
 ejemplo="Podés tomar la decisión +EV del ejemplo (36% de equity) diez "
        "veces seguidas y perder la mayoría, solo por varianza — el 64% "
        "de perder, repetido varias veces seguidas, no es raro ni "
        "imposible.",
 error_comun="Cambiar una estrategia correcta después de una mala racha "
        "corta, atribuyéndole a la estrategia lo que en realidad es "
        "varianza normal.",
 idea_clave="Varianza = resultados que suben y bajan incluso jugando "
        "bien. Es parte del juego, no un diagnóstico.",
),

# ============================================================
# 6.7 — El EV de cada acción
# ============================================================

"T123": dict(  # El EV del call
 que_es="Estimar el EV del call es aplicar específicamente el cálculo de "
        "EV (T120) a la decisión de pagar una apuesta.",
 por_que_importa="Es la aplicación más directa de todo lo que "
        "aprendiste en este nivel: outs, equity, pot odds y EV, todo "
        "junto en una sola decisión concreta.",
 como_funciona="Usás la fórmula de EV con tu equity real y los números "
        "del bote (actual y del call) para saber si pagar suma o resta "
        "fichas en promedio.",
 cuando_lo_uso="Cada vez que enfrentás una apuesta y querés la "
        "evaluación más completa posible antes de decidir.",
 cuando_no=None,
 ejemplo="El cálculo completo del ejemplo de este nivel — EV = "
        "+0.32 BB — es, específicamente, el EV del call en esa "
        "situación.",
 error_comun="Calcular pot odds o equity por separado y quedarte ahí, "
        "sin terminar de juntar todo en el EV del call.",
 idea_clave="El EV del call junta equity, bote y precio en un solo "
        "número que responde: ¿pagar suma o resta fichas en promedio?",
),

"T124": dict(  # El EV del fold
 que_es="Foldear siempre tiene EV exactamente 0: no ganás nada más, pero "
        "tampoco arriesgás nada más a partir de ese momento.",
 por_que_importa="Convierte al fold en un punto de referencia fijo: "
        "cualquier otra acción (pagar, subir) solo tiene sentido si su "
        "EV calculado es mejor que ese 0 seguro.",
 como_funciona="Las fichas que ya pusiste antes en la mano son un costo "
        "hundido: ya se fueron, ganes o pierdas la mano. Foldear no "
        "arriesga NADA más a partir de ahora, así que su EV, mirando "
        "hacia adelante, es 0.",
 cuando_lo_uso="Como punto de comparación: si el EV de pagar da "
        "negativo, foldear (EV 0) es mejor.",
 cuando_no=None,
 ejemplo="Con el call -EV del ejemplo (−1.6 BB), foldear (EV 0) es "
        "mejor que pagar: 0 es mayor que −1.6.",
 error_comun="Sentir que foldear 'pierde' las fichas que ya pusiste "
        "antes en la mano. Esas fichas ya no son parte de la decisión: "
        "lo único que cuenta es lo que hacés de acá en adelante.",
 idea_clave="El EV del fold es siempre 0. A veces, foldear (EV 0) le "
        "gana a pagar con EV negativo.",
),

"T125": dict(  # El EV de apostar
 que_es="Estimar el EV de apostar por valor es calcular cuánto suma, en "
        "promedio, apostar cuando creés tener la mejor mano y esperás "
        "que el rival pague con algo peor.",
 por_que_importa="No solo pagar o foldear tienen un EV calculable: "
        "apostar también, y entenderlo te ayuda a decidir cuándo y "
        "cuánto apostar con tus manos buenas.",
 como_funciona="Pensá en las veces que el rival paga con algo peor "
        "(ganás tu apuesta) contra las veces que paga con algo mejor o "
        "te resube (perdés). El balance entre esos dos escenarios da el "
        "EV de la apuesta.",
 cuando_lo_uso="Al decidir si apostar (y con qué tamaño) cuando creés "
        "tener la mejor mano.",
 cuando_no=None,
 ejemplo="Con una mano fuerte hecha, si el rival paga con manos peores "
        "más seguido de lo que te supera, apostar tiene EV positivo: "
        "estás cobrando valor de tu mano.",
 error_comun="Apostar tu mejor mano al tamaño máximo siempre, sin "
        "pensar si un tamaño más chico consigue que el rival pague más "
        "seguido con manos peores.",
 idea_clave="El EV de apostar por valor depende de cuánto pagan manos "
        "peores comparado con cuánto te superan manos mejores.",
),

"TN13": dict(  # La fold equity
 que_es="La fold equity es la parte del valor de una apuesta que viene, "
        "específicamente, de que el rival se retire — ganás el bote "
        "actual sin necesidad de mostrar ni tener la mejor mano.",
 por_que_importa="Es una fuente de valor separada de 'tener la mejor "
        "mano': una apuesta puede sumar EV solo por la chance de que el "
        "rival foldee, incluso con una mano floja.",
 como_funciona="Cuanto más seguido creas que el rival va a foldear "
        "frente a tu apuesta, más fold equity tiene esa apuesta — y más "
        "EV suma, sin importar tu mano real.",
 cuando_lo_uso="Al evaluar el valor de una apuesta más allá de si tenés "
        "la mejor mano: parte de ese valor viene de que el rival pueda "
        "retirarse.",
 cuando_no=None,
 ejemplo="Apostás con una mano floja en un board que asusta: si el "
        "rival se retira la mitad de las veces, ganás el bote esa mitad "
        "de las veces sin necesidad de tener la mejor mano — eso es fold "
        "equity funcionando.",
 error_comun="Pensar el valor de una apuesta únicamente en términos de "
        "'tengo la mejor mano o no', ignorando que el rival foldeando "
        "también genera valor.",
 idea_clave="Fold equity = el valor que te da que el rival se retire "
        "frente a tu apuesta, más allá de tu mano real.",
),

"T126": dict(  # El EV de un farol
 que_es="Un farol es apostar con una mano floja, que probablemente "
        "pierde si te pagan. Su EV depende casi por completo de la fold "
        "equity (TN13): gana por las veces que el rival se retira.",
 por_que_importa="Entender esto te dice cuándo un farol tiene sentido "
        "matemático (rival que foldea seguido) y cuándo no (rival que "
        "paga cualquier cosa, sin importar la presión).",
 como_funciona="Comparás las fichas que ganás cada vez que el rival "
        "foldea contra las fichas que perdés las veces que paga (y "
        "generalmente te gana, porque tu mano es floja). Si el rival "
        "foldea lo suficientemente seguido, el balance es positivo.",
 cuando_lo_uso="Al decidir si vale la pena farolear en una situación "
        "concreta, pensando en qué tan seguido creés que el rival se "
        "retira.",
 cuando_no="Contra un rival que paga casi cualquier apuesta (poca fold "
        "equity), un farol pierde EV casi seguro: no tiene con qué "
        "ganar.",
 ejemplo="Apostás 4 BB para ganar un bote de 8 BB con una mano floja. Si "
        "el rival foldea la mitad de las veces, ganás 8 BB esa mitad y "
        "perdés 4 BB la otra mitad: EV = (0.5 × 8) − (0.5 × 4) = "
        "4 − 2 = +2 BB. El farol suma, gracias a la fold equity.",
 error_comun="Farolear sin pensar en qué tan seguido el rival "
        "realmente se retira frente a ese tipo de apuesta — el farol "
        "solo funciona si hay fold equity real detrás.",
 idea_clave="El EV de un farol depende de la fold equity: gana por las "
        "veces que el rival se retira, no por tener la mejor mano.",
),

}
