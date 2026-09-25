# -*- coding: utf-8 -*-
"""
PASO 4 — Contenido redactado del NIVEL 7: "Guerra preflop: defensa y 3-bet".
23 teorías, 4 subniveles. Banda INTERMEDIO, estadio DECIDIR en todo el
nivel. Voz: profesor de póker rioplatense. Completo, no largo.

Fuente de verdad: curriculum_spec.json (IDs, títulos, objetivos, orden y
prerrequisitos no se tocan acá).

Meta de N7: pasar de "abrir y esperar" (N5) a jugar la guerra preflop
completa: qué hacer cuando alguien más ya abrió (call, fold o 3-bet), cómo
se juega un bote 3-bet, y qué pasa cuando la pelea sigue con una 4-bet.

Vocabulario nuevo de N7: rango de call, 3-bet (valor/farol), rango de
3-bet, squeeze, bote 3-bet, SPR (stack-to-pot ratio), 4-bet (valor/farol),
blind vs blind.

NO se enseña todavía: c-bet/iniciativa formal (N8), turn/river avanzado
(N9), lectura de rango por línea completa (N10), ventaja de rango/nuts,
bloqueadores formales, MDF (N11). T174 (4-bet como farol) necesita la
IDEA de "mi mano usa una carta que el rival necesitaría para sus manos
más fuertes" sin nombrarla todavía "bloqueador" — ese término formal es
T232 (N11); acá se describe el mecanismo, no se lo bautiza.
"""

N7 = {

# ============================================================
# 7.1 — ¿Call o fold contra un open?
# ============================================================

"T154": dict(  # ¿Podemos pagar un open?
 que_es="Es la primera pregunta que te hacés cuando alguien abrió antes "
        "que vos: ¿tu mano alcanza para seguir en la mano, o te conviene "
        "retirarte?",
 por_que_importa="Hasta ahora veníamos pensando 'abrir o no abrir' (N5). "
        "Ahora aparece la otra mitad del juego preflop: responder cuando "
        "OTRO ya abrió. Es una decisión distinta, con su propio rango.",
 como_funciona="Juntás dos cosas que ya sabés: tu rango de defensa "
        "(N5, T138) contra el rango de apertura de esa posición (N5,\n"
        "T137), y las pot odds (N6) que te da ese open concreto.",
 cuando_lo_uso="Cada vez que alguien abre antes de que te toque actuar a "
        "vos.",
 cuando_no=None,
 ejemplo="El CO abre. Te llega a vos en el botón con K♠J♠: tu mano entra "
        "cómoda en tu rango de defensa contra un open del CO — alcanza "
        "para seguir.",
 error_comun="Evaluar la mano sola, sin comparar contra el rango de "
        "apertura de quien abrió. La misma mano puede alcanzar contra un "
        "open del botón y no alcanzar contra un open de UTG.",
 idea_clave="Antes de responder a un open, comparás tu mano contra SU "
        "rango de apertura — no la evaluás en el aire.",
),

"T155": dict(  # El call preflop
 que_es="Pagar (call) el open del rival, en vez de subir o retirarte, "
        "con una mano que juega bien después del flop.",
 por_que_importa="No toda mano que 'alcanza' conviene subirla: algunas "
        "manos ganan más jugando el flop en vez de agrandando el bote de "
        "entrada.",
 como_funciona="El call preflop funciona mejor con manos que mejoran "
        "mucho al ver más cartas (parejas chicas buscando trío, "
        "conectores suited) y que preferís jugar con el bote más chico, "
        "no manos que ya son fuertes de por sí.",
 cuando_lo_uso="Con una mano jugable que preferís desarrollar en el "
        "flop antes que agrandar el bote ahí mismo.",
 cuando_no=None,
 ejemplo="El botón abre y estás en la BB con 6♠6♦: no es mano para "
        "3-betear, pero paga bien buscando ligar un trío en el flop.",
 error_comun="Pagar con cualquier mano jugable sin pensar si en realidad "
        "convendría más subir (T157) con esa mano en particular.",
 idea_clave="El call preflop es para manos que prefieren ver el flop con "
        "el bote chico, no para todo lo que 'alcanza'.",
),

"T156": dict(  # Foldear contra un open
 que_es="Retirarte frente al open del rival porque tu mano no entra en "
        "tu rango de defensa para esa situación.",
 por_que_importa="Así como en N5 la mayoría de tus manos se foldeaban al "
        "abrir, acá pasa lo mismo respondiendo: la mayoría de las manos, "
        "la mayoría de las veces, no alcanzan para seguir.",
 como_funciona="Si tu mano no entra ni en tu rango de call ni en tu "
        "rango de 3-bet (T161) para esa situación puntual, foldeás.",
 cuando_lo_uso="Cada vez que tu mano no entra en tu rango de defensa "
        "contra ese open concreto.",
 cuando_no=None,
 ejemplo="UTG abre y estás en la BB con 9♠4♦: no entra en tu rango de "
        "defensa contra un open tan fuerte y tan temprano — foldeás.",
 error_comun="'Defender' la ciega grande con cualquier cosa solo porque "
        "'ya pusiste esa ficha'. Esa ficha ya está en el bote pase lo "
        "que pase: no es un motivo para pagar.",
 idea_clave="Foldear contra un open sigue siendo, con diferencia, la "
        "decisión más frecuente.",
),

"T162": dict(  # La posición del que paga
 que_es="Tu posición RELATIVA a quien abrió (delante o detrás de él en "
        "el resto de la mano) cambia qué tan ancho podés defender.",
 por_que_importa="No es lo mismo pagar un open estando en posición sobre "
        "el que abrió (vas a actuar último en las calles siguientes) que "
        "pagar estando fuera de posición.",
 como_funciona="Si vas a jugar el resto de la mano EN posición sobre el "
        "abridor, podés defender más ancho: vas a tener más información "
        "en cada calle. Si vas a jugar fuera de posición, conviene ser "
        "más selectivo.",
 cuando_lo_uso="Al construir tu rango de defensa: no solo importa quién "
        "abrió, importa desde dónde respondés vos.",
 cuando_no=None,
 ejemplo="El CO abre. Si respondés desde el botón, vas a estar en "
        "posición todo el resto de la mano: podés defender más ancho que "
        "si respondieras desde la BB, fuera de posición.",
 error_comun="Usar el mismo rango de defensa sin importar si vas a "
        "quedar en posición o no en las calles siguientes.",
 idea_clave="Defender en posición permite un rango más ancho que "
        "defender fuera de posición, con la misma mano del rival.",
),

"T163": dict(  # El tamaño del open del rival
 que_es="Ajustar tu rango de defensa según cuánto subió el rival: un "
        "open a 2x no se responde igual que uno a 3x.",
 por_que_importa="El tamaño del open (N5, T142-145) cambia el precio que "
        "te están cobrando por seguir: un open más grande te da peores "
        "pot odds, así que necesitás una mano mejor para justificar "
        "seguir.",
 como_funciona="Contra un open más chico, tu rango de defensa puede ser "
        "un poco más ancho (mejor precio). Contra un open más grande, "
        "conviene ser más selectivo.",
 cuando_lo_uso="Al leer el tamaño del open antes de decidir con qué "
        "manos vas a responder.",
 cuando_no=None,
 ejemplo="Un open a 2x te deja mejores pot odds que uno a 3x: con la "
        "misma mano, seguir puede ser correcto contra el primero y "
        "incorrecto contra el segundo.",
 error_comun="Ignorar el tamaño del open y responder siempre con el "
        "mismo rango, sin importar cuánto te está costando seguir.",
 idea_clave="Open más grande = peor precio para vos = rango de defensa "
        "más angosto.",
),

"TN16": dict(  # Ciega contra ciega (blind vs blind)
 que_es="El enfrentamiento entre la ciega chica (SB) y la ciega grande "
        "(BB) cuando todos los demás se retiraron: ambos con rangos más "
        "anchos que en cualquier otra situación.",
 por_que_importa="Es un caso especial: la SB abre contra un solo rival "
        "(nadie más queda por detrás), así que su rango de apertura ahí "
        "es más ancho de lo normal; y la BB, al defender, también puede "
        "ser más ancha, porque recibe un precio mejor.",
 como_funciona="La SB, al tener solo a la BB detrás, puede abrir mucho "
        "más ancho que en cualquier otra posición. La BB, sabiendo que "
        "el rango de apertura de la SB ahí es más amplio y flojo, "
        "defiende también más ancho de lo habitual.",
 cuando_lo_uso="Cada vez que la acción llega limpia hasta la SB: es una "
        "situación con su propia lógica, distinta a las demás aperturas.",
 cuando_no=None,
 ejemplo="Con una mano que foldearías si UTG hubiera abierto, la SB "
        "puede abrirla sin problema contra la BB — y la BB, del otro "
        "lado, puede defenderla también.",
 error_comun="Jugar blind vs blind con el mismo rango angosto que "
        "usarías en cualquier otra posición, desaprovechando que ahí "
        "solo hay un rival.",
 idea_clave="Blind vs blind = rangos más anchos de los dos lados, "
        "porque solo hay un jugador enfrentado.",
),

# ============================================================
# 7.2 — 3-bet: valor y farol
# ============================================================

"T157": dict(  # 3-betear contra un open
 que_es="Subir por encima del open del rival (3-bet), en vez de pagar o "
        "retirarte. Se llama '3-bet' porque es la tercera subida de "
        "fichas en la mano (la ciega grande cuenta como la primera, el "
        "open del rival como la segunda).",
 por_que_importa="Es la tercera opción, además de call y fold: agrandar "
        "el bote ahí mismo, en vez de solo seguir o irte.",
 como_funciona="3-beteás con manos que quieren un bote más grande "
        "(porque son fuertes) o con manos que se benefician de que el "
        "rival se retire (farol). Las próximas dos teorías desarrollan "
        "cada caso.",
 cuando_lo_uso="Frente al open de un rival, cuando tu mano se beneficia "
        "más de agrandar el bote que de solo pagar.",
 cuando_no=None,
 ejemplo="El CO abre. Con A♠A♦, 3-betear (en vez de solo pagar) empieza "
        "a construir un bote grande con la mejor mano posible.",
 error_comun="Pensar que 3-betear es 'siempre agresivo' o 'siempre "
        "arriesgado' sin distinguir por qué se está haciendo en cada "
        "caso.",
 idea_clave="3-bet = subir sobre el open del rival. Se hace por valor o "
        "como farol — las próximas dos teorías.",
),

"T158": dict(  # 3-bet por valor
 que_es="3-betear con una mano fuerte, buscando construir un bote más "
        "grande porque creés que tu mano está mejor parada que el "
        "rango del rival.",
 por_que_importa="Con tus mejores manos, un bote más grande es bueno "
        "para vos: cuanta más plata entre con la mejor mano, mejor.",
 como_funciona="Elegís tus manos más fuertes (las que le ganan cómodo al "
        "rango de apertura del rival) y subís, en vez de solo pagar, "
        "para meter más fichas mientras estás adelante.",
 cuando_lo_uso="Con manos que le ganan claramente al rango de apertura "
        "del rival y que quieren jugar un bote grande.",
 cuando_no=None,
 ejemplo="El CO abre. Con K♠K♦, 3-betear por valor: es una mano que le "
        "gana a casi todo el rango de apertura del CO, así que conviene "
        "meter más fichas ahí mismo.",
 error_comun="Solo pagar con tus mejores manos 'para no espantar' al "
        "rival, dejando pasar la chance de meter más fichas mientras "
        "estás claramente adelante.",
 idea_clave="3-bet por valor = con tu mejor mano, agrandás el bote "
        "porque estás mejor parado.",
),

"T159": dict(  # 3-bet como farol
 que_es="3-betear con una mano que no es fuerte, buscando que el rival "
        "se retire — ganando el bote gracias a la fold equity (N6, "
        "TN13), no porque tu mano sea mejor.",
 por_que_importa="No solo tus mejores manos pueden 3-betear: algunas "
        "manos flojas también se benefician de subir, si el rival se "
        "retira lo suficientemente seguido.",
 como_funciona="Elegís manos que no ganan mucho solo pagando (no juegan "
        "bien el flop en un bote chico), pero que sí ganan cuando el "
        "rival se retira frente a tu 3-bet.",
 cuando_lo_uso="Con manos que se benefician más de que el rival foldee "
        "que de ver un flop con el bote chico.",
 cuando_no="Contra un rival que casi nunca foldea frente a una 3-bet: "
        "ahí falta la fold equity que hace funcionar el farol.",
 ejemplo="El CO abre. Con A♠5♠, una mano floja para solo pagar pero con "
        "algo de potencial, 3-betear como farol busca que el CO se "
        "retire ahí mismo.",
 error_comun="3-betear como farol con cualquier mano floja, sin pensar "
        "si el rival realmente foldea lo suficiente frente a una 3-bet.",
 idea_clave="3-bet como farol = gana por fold equity, no por tener la "
        "mejor mano.",
),

"T160": dict(  # El rango de call
 que_es="El conjunto de manos con las que elegís PAGAR un open, en vez "
        "de subirlo o retirarte.",
 por_que_importa="Ya viste con qué tipo de mano conviene pagar (T155). "
        "Ahora se trata de construir ese rango completo: no una mano "
        "puntual, sino todas las que van a entrar en 'pago, no subo'.",
 como_funciona="Tu rango de call suele quedar formado por manos que "
        "juegan bien con el bote chico (conectores, parejas medias-"
        "chicas), dejando las manos más fuertes y algunos faroles para "
        "tu rango de 3-bet.",
 cuando_lo_uso="Al planificar, de antemano, qué manos vas a pagar contra "
        "un open de determinada posición.",
 cuando_no=None,
 ejemplo="Contra un open del botón, tu rango de call puede incluir "
        "manos como conectores medios y parejas chicas — manos que "
        "prefieren desarrollarse en el flop antes que agrandar el bote.",
 error_comun="No tener un rango de call definido y decidir mano por "
        "mano sin ningún criterio consistente.",
 idea_clave="Rango de call = las manos con las que elegís pagar, no "
        "subir ni foldear, contra un open concreto.",
),

"T161": dict(  # El rango de 3-bet
 que_es="El conjunto de manos con las que elegís 3-betear un open — "
        "combinando tus manos de valor (T158) y tus manos de farol "
        "(T159).",
 por_que_importa="Un rango de 3-bet bien armado mezcla ambos tipos: si "
        "solo 3-beteás con manos fuertes, un rival atento va a notar que "
        "cada vez que subís tenés lo mejor, y va a dejar de pagarte.",
 como_funciona="Juntás tus mejores manos (valor) con algunas manos "
        "flojas con potencial (farol), dejando afuera el resto — que va "
        "a tu rango de call (T160) o directo al fold.",
 cuando_lo_uso="Al planificar, de antemano, qué manos vas a 3-betear "
        "contra un open de determinada posición.",
 cuando_no=None,
 ejemplo="Tu rango de 3-bet contra un open del CO puede combinar manos "
        "como AA-QQ y AK (valor) con algunas manos como A5s (farol), "
        "dejando afuera el resto de tus manos jugables.",
 error_comun="3-betear solo con manos de valor, sin ningún farol mezclado "
        "— un rango así se vuelve predecible.",
 idea_clave="Rango de 3-bet = valor + farol combinados, no solo uno de "
        "los dos.",
),

"TN17": dict(  # El squeeze
 que_es="Un squeeze es 3-betear cuando ya hay un open Y alguien más que "
        "pagó ese open antes que vos — apretando a los dos a la vez.",
 por_que_importa="Con dos jugadores ya comprometidos con fichas en el "
        "bote, tu 3-bet tiene que ser más grande que una 3-bet normal: "
        "hay más gente que podría tener algo, pero también más gente "
        "que puede estar foldeando algo flojo.",
 como_funciona="El que abrió puede tener un rango amplio y flojo; el que "
        "solo pagó, generalmente, tiene una mano que no era lo bastante "
        "fuerte como para subir. Un squeeze bien armado aprovecha que "
        "ninguno de los dos mostró demasiada fuerza.",
 cuando_lo_uso="Cuando hay un open y al menos un caller antes de que te "
        "toque a vos, y tu mano se presta para presionar a los dos.",
 cuando_no=None,
 ejemplo="El HJ abre, el CO paga, y en el botón subís con una mano "
        "fuerte o un buen farol: un squeeze, apuntando a que uno de los "
        "dos (o los dos) se retire.",
 error_comun="Usar el mismo tamaño de una 3-bet normal para un squeeze. "
        "Con más jugadores en la mano, conviene subir más grande.",
 idea_clave="Squeeze = 3-bet sobre un open Y un caller, con un tamaño "
        "más grande de lo habitual.",
),

# ============================================================
# 7.3 — Anatomía del bote 3-bet
# ============================================================

"T164": dict(  # Qué es un bote 3-bet
 que_es="Un bote 3-bet es un bote que llegó al flop después de que "
        "alguien 3-beteó preflop y el otro pagó — se juega distinto a un "
        "bote 'normal' (single-raised).",
 por_que_importa="La cantidad de fichas que ya entraron preflop cambia "
        "todo lo que viene después: el bote es más grande desde el "
        "arranque, y los stacks que quedan, relativamente, son más "
        "chicos.",
 como_funciona="En vez de una sola subida preflop, hubo dos (el open y "
        "la 3-bet). Eso deja un bote de partida mucho más grande al "
        "llegar al flop.",
 cuando_lo_uso="Al reconocer que la mano llegó al flop con una 3-bet de "
        "por medio: te avisa que hay que pensar distinto que en un bote "
        "normal.",
 cuando_no=None,
 ejemplo="Un open a 2.5 BB y una 3-bet a 9 BB dejan un bote de partida "
        "de 18-20 BB al llegar al flop, comparado con los 5-6 BB "
        "típicos de un bote sin 3-bet.",
 error_comun="Jugar un bote 3-bet con la misma cabeza que un bote "
        "normal, sin ajustar tamaños ni decisiones al bote ya más "
        "grande.",
 idea_clave="Bote 3-bet = llegó al flop con una 3-bet de por medio. Más "
        "grande de entrada, se juega distinto.",
),

"T165": dict(  # El tamaño del bote 3-bet
 que_es="Leer específicamente cuánto quedó en el bote después de la "
        "secuencia de apuestas preflop (open + 3-bet + call).",
 por_que_importa="Antes de decidir cualquier cosa en el flop, necesitás "
        "saber con cuánto estás jugando: un bote 3-bet chico se juega "
        "distinto a uno grande.",
 como_funciona="Sumás lo que puso cada jugador durante el preflop: la "
        "3-bet, más lo que pagó el otro para igualarla, más lo que ya "
        "había de las ciegas.",
 cuando_lo_uso="Al llegar al flop de un bote 3-bet, como primer dato "
        "antes de cualquier decisión.",
 cuando_no=None,
 ejemplo="Open a 2.5 BB, 3-bet a 9 BB, call de 9 BB: el bote que llega "
        "al flop es de aproximadamente 19,5 BB (9 BB del 3-bettor + 9 BB "
        "de quien pagó + 1,5 BB de las dos ciegas que ya estaban "
        "perdidas en el medio).",
 error_comun="Llegar al flop de un bote 3-bet sin haber sumado cuánto "
        "hay realmente en el medio.",
 idea_clave="El tamaño del bote 3-bet es el primer dato concreto para "
        "jugar bien el resto de la mano.",
),

"T166": dict(  # El SPR
 que_es="El SPR (stack-to-pot ratio, 'relación stack-bote') es cuántas "
        "veces entra el bote en el stack EFECTIVO — el más chico entre "
        "tu stack y el del rival, porque eso es lo máximo que realmente "
        "puede terminar en el medio —: stack efectivo ÷ bote.",
 por_que_importa="Un SPR bajo (poco stack en relación al bote) te acerca "
        "rápido a jugarte todo el stack; un SPR alto te deja más margen "
        "para decisiones más finas en varias calles.",
 como_funciona="Dividís el stack efectivo (el más chico entre el tuyo y "
        "el del rival) por el tamaño del bote. Si ambos tienen el mismo "
        "stack, listo, ese número alcanza; si son distintos, siempre se "
        "usa el más chico. Los botes 3-bet, al ser más grandes de entrada "
        "con los mismos stacks, dejan un SPR más bajo que un bote normal.",
 cuando_lo_uso="Al llegar al flop, para entender qué tan 'comprometido' "
        "vas a estar con el resto de tu stack en esa mano.",
 cuando_no=None,
 ejemplo="Los dos jugadores tienen 100 BB de stack efectivo y el bote es "
        "de aproximadamente 19,5 BB (T165): el SPR es aproximadamente 5 "
        "(100÷19,5 ≈ 5,1) — bastante más bajo que en un bote normal de "
        "6 BB con el mismo stack (SPR ≈ 16,6).",
 error_comun="Ignorar el SPR y jugar un bote 3-bet (SPR bajo) con la "
        "misma cautela que un bote de SPR alto, donde hay mucho más "
        "margen para maniobrar.",
 idea_clave="SPR = stack ÷ bote. Más bajo en botes 3-bet: te acerca más "
        "rápido a jugarte todo el stack.",
),

"T167": dict(  # El rango del 3-bettor
 que_es="Estimar el conjunto de manos con las que el rival, probablemente, "
        "3-beteó.",
 por_que_importa="Saber leer ese rango te permite jugar mejor el resto "
        "de la mano: un rango de 3-bet (T161) combina valor y farol, y "
        "eso te da información concreta para trabajar.",
 como_funciona="Pensá en lo que ya sabés de rangos de 3-bet (T161): "
        "manos fuertes de valor combinadas con algunos faroles, según la "
        "posición y el estilo del rival.",
 cuando_lo_uso="Al enfrentar una 3-bet, antes de decidir tu respuesta.",
 cuando_no=None,
 ejemplo="Un rival 3-betea desde el botón contra tu open del CO: su "
        "rango probablemente combina manos fuertes con algunos faroles "
        "— más amplio que si el mismo 3-bet viniera de la ciega grande, "
        "fuera de posición.",
 error_comun="Asumir que cualquier 3-bet significa automáticamente una "
        "mano premium, ignorando que los rangos de 3-bet incluyen "
        "faroles.",
 idea_clave="El rango del 3-bettor combina valor y farol — no asumas "
        "que siempre es lo mejor posible.",
),

"T168": dict(  # El rango del que paga la 3-bet
 que_es="Estimar el conjunto de manos con las que el rival, "
        "probablemente, pagó tu 3-bet (en vez de subir o retirarse).",
 por_que_importa="Pagar una 3-bet (en vez de subir a una 4-bet o "
        "foldear) suele filtrar bastante el rango: la mayoría de las "
        "manos flojas se van, y muchas de las más fuertes prefieren "
        "resubir.",
 como_funciona="El rango de quien paga una 3-bet suele quedar compuesto "
        "por manos buenas pero no tan fuertes como para 4-betear: "
        "parejas medias, broadways decentes, algunas manos "
        "especulativas con buen potencial postflop.",
 cuando_lo_uso="Al jugar un flop de un bote 3-bet donde vos fuiste "
        "quien 3-beteó, para leer qué tipo de mano trae el rival que "
        "pagó.",
 cuando_no=None,
 ejemplo="3-beteás y el rival paga: ese rango, en general, no tiene tus "
        "manos más débiles posibles ya filtradas — está compuesto por "
        "manos que juegan bien un bote de SPR bajo.",
 error_comun="Tratar el rango de un caller de 3-bet como si fuera tan "
        "amplio y flojo como un rango de defensa normal (T138).",
 idea_clave="Pagar una 3-bet filtra el rango: suele quedar compuesto por "
        "manos razonablemente buenas, no cualquier cosa.",
),

"T169": dict(  # La posición en el bote 3-bet
 que_es="En un bote 3-bet, con SPR más bajo (T166) y menos margen para "
        "maniobrar en las calles que faltan, la posición pesa todavía "
        "más que en un bote normal.",
 por_que_importa="Con menos margen de maniobra (SPR bajo), cada decisión "
        "vale más: tener información extra por estar en posición se "
        "vuelve más valioso, no menos.",
 como_funciona="Repasá lo que ya sabés de la posición (N3, N5): actuar "
        "último te da información antes de decidir. En un bote 3-bet, "
        "con el bote ya grande desde el arranque, esa ventaja se nota "
        "más rápido.",
 cuando_lo_uso="Al planear cómo vas a jugar un bote 3-bet, según si vas "
        "a estar en posición o fuera de ella.",
 cuando_no=None,
 ejemplo="Con la misma mano, jugar un bote 3-bet en posición te permite "
        "tomar decisiones más finas (pot control, ver una calle más "
        "barata) que jugarlo fuera de posición con el mismo SPR bajo.",
 error_comun="Subestimar cuánto pesa la posición en un bote 3-bet, "
        "pensando que 'total el SPR es bajo, da lo mismo'.",
 idea_clave="Con SPR bajo, la posición pesa más, no menos: hay menos "
        "margen para equivocarse.",
),

# ============================================================
# 7.4 — Responder a una 3-bet / 4-bet
# ============================================================

"T170": dict(  # La 4-bet
 que_es="Una 4-bet es subir por encima de una 3-bet — la cuarta subida "
        "de fichas de la secuencia (ciega grande, open, 3-bet, 4-bet).",
 por_que_importa="Es el siguiente escalón de la guerra preflop: cuando "
        "abriste, te 3-betearon, y tu mano es lo bastante fuerte (o "
        "estratégica) como para seguir subiendo en vez de solo pagar o "
        "foldear.",
 como_funciona="Aparece cuando vos abriste, el rival te 3-beteó, y "
        "decidís responder con una subida en vez de call o fold.",
 cuando_lo_uso="Al enfrentar una 3-bet con una mano que quiere seguir "
        "subiendo en vez de solo pagar.",
 cuando_no=None,
 ejemplo="Abrís desde el CO, el botón te 3-betea, y con A♠A♦ subís de "
        "nuevo: eso es una 4-bet.",
 error_comun="Confundir cualquier subida preflop con una 4-bet. Es "
        "específicamente la subida que responde a una 3-bet.",
 idea_clave="4-bet = subir sobre una 3-bet. El siguiente escalón después "
        "del open y la 3-bet.",
),

"T171": dict(  # Foldear contra una 3-bet
 que_es="Retirarte cuando abriste, te 3-betearon, y tu mano no alcanza "
        "para pagar ni para 4-betear.",
 por_que_importa="Así como la mayoría de las manos se foldean al abrir "
        "y al defender, también la mayoría se foldean frente a una "
        "3-bet: es una subida grande, con un rango del rival ya "
        "bastante fuerte de por sí.",
 como_funciona="Si tu mano no entra en tu rango de call ni en tu rango "
        "de 4-bet contra esa 3-bet, foldeás — sin arrepentimiento: "
        "abriste con una mano razonable, esto es parte normal del juego.",
 cuando_lo_uso="Cada vez que abrís, te 3-betean, y tu mano no alcanza "
        "para seguir.",
 cuando_no=None,
 ejemplo="Abrís con K♠9♦ desde el CO y el botón te 3-betea: esa mano no "
        "entra ni en tu rango de call ni de 4-bet contra una 3-bet — "
        "foldeás.",
 error_comun="Sentir que 'ya invertiste' con el open y por eso tenés "
        "que pagar la 3-bet. El open ya está hecho; la decisión de acá "
        "en más se toma con la información nueva.",
 idea_clave="Foldear contra una 3-bet sigue siendo, con diferencia, la "
        "respuesta más frecuente.",
),

"T172": dict(  # Pagar una 3-bet
 que_es="Pagar la 3-bet del rival, en vez de foldear o 4-betear, con una "
        "mano que juega bien un bote 3-bet.",
 por_que_importa="Al igual que con el call preflop (T155), no toda mano "
        "que 'alcanza' conviene 4-betearla: algunas prefieren ver el "
        "flop con el bote ya grande, en vez de agrandarlo todavía más.",
 como_funciona="Pagás con manos buenas que no ganan lo suficiente "
        "4-beteando (perderías valor si el rival foldea sus manos más "
        "flojas de 3-bet) y que juegan bien un flop de SPR bajo.",
 cuando_lo_uso="Con una mano sólida, con posición favorable, que "
        "prefiere jugar el flop antes que seguir agrandando el bote "
        "preflop.",
 cuando_no=None,
 ejemplo="Abrís con A♠Q♠ desde el botón, el rival te 3-betea: pagar (en "
        "vez de 4-betear) mantiene en el bote a manos más flojas de su "
        "rango de 3-bet que foldearían frente a una 4-bet.",
 error_comun="4-betear con cualquier mano que 'alcanza' contra una "
        "3-bet, sin pensar si en realidad conviene más pagar.",
 idea_clave="Pagar una 3-bet es para manos buenas que prefieren jugar "
        "el flop, no agrandar más el bote todavía.",
),

"T173": dict(  # 4-bet por valor
 que_es="4-betear con tus manos más fuertes, buscando meter más fichas "
        "mientras estás mejor parado que el rango de 3-bet del rival.",
 por_que_importa="Con tus manos más fuertes de todas, conviene seguir "
        "agrandando el bote: es la misma lógica de la 3-bet por valor "
        "(T158), un escalón más arriba.",
 como_funciona="Elegís las manos que le ganan cómodo incluso al rango "
        "de 3-bet del rival (que ya es, en promedio, más fuerte que un "
        "rango de apertura) y subís de nuevo.",
 cuando_lo_uso="Con tus manos más fuertes, frente a una 3-bet.",
 cuando_no=None,
 ejemplo="Abrís y te 3-betean. Con K♠K♦, 4-betear por valor: le ganás "
        "cómodo a la inmensa mayoría del rango de 3-bet del rival — solo "
        "un As-As lo supera de entrada.",
 error_comun="Solo pagar con tus manos más fuertes por miedo a que el "
        "rival se retire, dejando de construir el bote más grande "
        "posible cuando estás claramente adelante.",
 idea_clave="4-bet por valor = con tu mano más fuerte, seguís agrandando "
        "el bote.",
),

"T174": dict(  # 4-bet como farol
 que_es="4-betear con una mano que no es de valor, usando una carta que "
        "el rival necesitaría para tener sus propias manos más fuertes "
        "de 3-bet.",
 por_que_importa="Igual que con la 3-bet (T159), no solo tus mejores "
        "manos pueden 4-betear: algunas manos flojas, pero con la carta "
        "correcta en la mano, también funcionan como farol.",
 como_funciona="Elegís una mano que, además de tener algo de potencial, "
        "reduce las combinaciones de las manos MÁS fuertes que el rival "
        "podría tener en su rango de 3-bet — porque una de esas cartas "
        "ya está en tu mano, no en el mazo.",
 cuando_lo_uso="Con una mano floja que, sin embargo, hace un poco menos "
        "probable que el rival tenga sus combos más fuertes.",
 cuando_no="Contra un rival que casi nunca foldea frente a una 4-bet: "
        "ahí falta la fold equity que hace funcionar el farol.",
 ejemplo="Abrís, te 3-betean, y tenés A♠5♦. Ese As en tu mano hace un "
        "poco menos probable que el rival tenga AA o AK en su rango de "
        "3-bet — 4-betear ahí busca que el resto de su rango se "
        "retire.",
 error_comun="4-betear como farol con cualquier mano floja, sin elegir "
        "una que además reste combos fuertes al rango del rival.",
 idea_clave="4-bet como farol = elegís una mano cuya carta hace un poco "
        "menos probable que el rival tenga sus manos más fuertes.",
),

}
