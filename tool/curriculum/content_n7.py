# -*- coding: utf-8 -*-
"""
PASO 4 — Contenido redactado del NIVEL 7: "Guerra preflop: defensa y 3-bet".
23 teorías, 4 subniveles. Banda INTERMEDIO, estadio DECIDIR en todo el
nivel. Voz: mentor de póker rioplatense hablándole directo al alumno —
"vos"/"tenés", explica antes de nombrar, nunca definición de manual.
Completo, no largo.

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
 que_es="Hasta acá veníamos pensando en abrir vos primero. Ahora te toca "
        "la otra mitad de la historia: alguien más abrió antes que vos, y "
        "tenés que decidir qué hacer con eso. La pregunta de fondo es "
        "siempre la misma: ¿tu mano alcanza para seguir en la mano, o te "
        "conviene retirarte acá mismo?",
 por_que_importa="Fijate que esto es un tipo de decisión distinto al que "
        "veníamos viendo en N5. Ahí pensabas 'abro o no abro'. Acá pensás "
        "'alguien ya movió una ficha antes que yo, ¿qué hago con eso?' — "
        "y esa decisión tiene su propio rango, no la misma regla de "
        "siempre.",
 como_funciona="Para responder bien, juntás dos cosas que ya tenés: tu "
        "rango de defensa contra la posición que abrió (eso lo viste en "
        "N5, con T137 y T138), y las pot odds que te está dejando ese "
        "open puntual (N6). Ninguna de las dos alcanza sola — las usás "
        "juntas.",
 cuando_lo_uso="Cada vez que alguien abre antes de que llegue tu turno de "
        "actuar.",
 cuando_no=None,
 ejemplo="Pensemos en un caso concreto: el CO abre. A vos te llega el "
        "turno en el botón con K♠J♠. Esa mano entra cómoda en tu rango de "
        "defensa contra un open del CO — alcanza para seguir.",
 error_comun="El error típico acá es mirar la mano sola, como si valiera "
        "lo mismo siempre. No es así: la misma mano puede alcanzar "
        "perfecto contra un open del botón, y no alcanzar ni cerca contra "
        "un open de UTG. Lo que cambia es contra quién estás "
        "respondiendo.",
 idea_clave="Antes de responder a un open, comparás tu mano contra SU "
        "rango de apertura — nunca la evaluás en el aire.",
),

"T155": dict(  # El call preflop
 que_es="Pagar el open del rival, sin subir ni retirarte: eso es lo que "
        "hacés cuando tu mano prefiere ver más cartas antes de "
        "comprometer más fichas.",
 por_que_importa="No toda mano que 'alcanza' para seguir conviene "
        "subirla. Fijate en esto: algunas manos ganan más jugando el flop "
        "tranquilas, con el bote todavía chico, que agrandando el bote ya "
        "desde preflop.",
 como_funciona="El call preflop le queda mejor a manos que mejoran mucho "
        "cuando ves más cartas —pensá en una pareja chica buscando trío, "
        "o dos cartas conectadas del mismo palo— y que preferís jugar con "
        "el bote chico. No es la herramienta para tus manos que ya son "
        "fuertes de por sí: esas prefieren agrandar el bote, y eso lo "
        "vemos en la próxima teoría.",
 cuando_lo_uso="Con una mano jugable que preferís desarrollar en el flop "
        "antes que agrandar el bote ahí mismo.",
 cuando_no=None,
 ejemplo="El botón abre y estás en la BB con 6♠6♦. No es mano para "
        "subir, pero paga bien: buscás ligar un trío en el flop.",
 error_comun="Ojo con pagar cualquier mano jugable en piloto automático, "
        "sin preguntarte si en realidad no te convendría más subir con "
        "esa mano en particular.",
 idea_clave="El call preflop es para manos que prefieren ver el flop con "
        "el bote chico, no para todo lo que 'alcanza'.",
),

"T156": dict(  # Foldear contra un open
 que_es="Retirarte frente al open del rival porque tu mano, lisa y "
        "llanamente, no entra en tu rango de defensa para esa situación.",
 por_que_importa="Acordate de N5: ahí la mayoría de tus manos se "
        "foldeaban al abrir. Bueno, acá pasa exactamente lo mismo del "
        "otro lado — respondiendo, la mayoría de las manos, la mayoría de "
        "las veces, tampoco alcanzan para seguir.",
 como_funciona="Es simple: si tu mano no entra ni en tu rango de call ni "
        "en tu rango de 3-bet (un término que vas a conocer en la próxima "
        "sección) para esa situación puntual, foldeás. Sin drama.",
 cuando_lo_uso="Cada vez que tu mano no entra en tu rango de defensa "
        "contra ese open concreto.",
 cuando_no=None,
 ejemplo="UTG abre y estás en la BB con 9♠4♦. Esa mano no entra en tu "
        "rango de defensa contra un open tan fuerte y tan temprano en la "
        "mesa — foldeás.",
 error_comun="Un clásico: 'defender' la ciega grande con cualquier cosa "
        "solo porque 'ya pusiste esa ficha'. Pero esa ficha ya está en el "
        "bote pase lo que pase — no es un motivo para pagar de más.",
 idea_clave="Foldear contra un open sigue siendo, con diferencia, la "
        "decisión más frecuente.",
),

"T162": dict(  # La posición del que paga
 que_es="Tu posición RELATIVA a quien abrió —si vas a actuar delante o "
        "detrás de él en el resto de la mano— cambia qué tan ancho podés "
        "defender.",
 por_que_importa="No es lo mismo pagar un open estando en posición sobre "
        "el que abrió, donde vas a actuar último en cada calle que sigue, "
        "que pagar estando fuera de posición, actuando siempre primero y "
        "a ciegas de lo que haga él.",
 como_funciona="Si vas a jugar el resto de la mano EN posición sobre el "
        "abridor, podés defender más ancho: vas a tener más información "
        "en cada calle antes de decidir. Si vas a jugar fuera de "
        "posición, te conviene ser más selectivo — vas a estar decidiendo "
        "con menos datos.",
 cuando_lo_uso="Al armar tu rango de defensa: no alcanza con mirar quién "
        "abrió, también importa desde dónde le vas a responder vos.",
 cuando_no=None,
 ejemplo="El CO abre. Si le respondés desde el botón, vas a estar en "
        "posición todo el resto de la mano y podés defender más ancho. Si "
        "le respondés desde la BB, fuera de posición, te conviene ser más "
        "selectivo con la misma mano del rival.",
 error_comun="Usar el mismo rango de defensa sin fijarte si vas a "
        "terminar en posición o no en las calles que siguen.",
 idea_clave="Defender en posición permite un rango más ancho que "
        "defender fuera de posición, con la misma mano del rival "
        "enfrente.",
),

"T163": dict(  # El tamaño del open del rival
 que_es="Ajustar tu rango de defensa según cuánto subió el rival: un open "
        "a 2x no se responde igual que uno a 3x.",
 por_que_importa="El tamaño del open, que ya viste en N5, cambia el "
        "precio que te están cobrando por seguir. Un open más grande te "
        "deja peores pot odds, así que necesitás una mano mejor para "
        "justificar seguir.",
 como_funciona="Contra un open más chico, tu rango de defensa puede ser "
        "un poco más ancho, porque el precio es mejor. Contra un open más "
        "grande, conviene achicar el rango y ser más selectivo.",
 cuando_lo_uso="Al leer el tamaño del open, antes de decidir con qué "
        "manos vas a responder.",
 cuando_no=None,
 ejemplo="Un open a 2x te deja mejores pot odds que uno a 3x. Con la "
        "misma mano en la mano, seguir puede ser correcto contra el "
        "primero e incorrecto contra el segundo.",
 error_comun="Ignorar el tamaño del open y responder siempre con el "
        "mismo rango, sin fijarte cuánto te está costando realmente "
        "seguir.",
 idea_clave="Open más grande = peor precio para vos = rango de defensa "
        "más angosto.",
),

"TN16": dict(  # Ciega contra ciega (blind vs blind)
 que_es="Cuando todos los demás se retiraron y quedan solo la ciega chica "
        "(SB) y la ciega grande (BB) enfrentadas, entrás en un terreno "
        "distinto: los dos juegan con rangos mucho más anchos que en "
        "cualquier otra situación de la mesa.",
 por_que_importa="Es un caso especial y vale la pena que lo tengas "
        "marcado aparte: la SB, ahí, abre contra un solo rival —nadie más "
        "queda por detrás—, así que su rango de apertura se ensancha "
        "bastante. Y la BB, sabiendo eso, también puede defender más "
        "ancho, porque el precio que recibe es mejor.",
 como_funciona="La SB, al tener solo a la BB detrás, puede abrir mucho "
        "más ancho que en cualquier otra posición de la mesa. La BB, "
        "sabiendo que el rango de apertura de la SB ahí es más amplio y "
        "más flojo que de costumbre, defiende también más ancho de lo "
        "habitual.",
 cuando_lo_uso="Cada vez que la acción llega limpia hasta la SB, sin que "
        "nadie más haya entrado antes: es una situación con lógica "
        "propia, distinta a cualquier otra apertura.",
 cuando_no=None,
 ejemplo="Una mano que foldearías sin dudar si UTG hubiera abierto, la SB "
        "puede abrirla sin problema contra la BB — y la BB, del otro "
        "lado, también puede defenderla.",
 error_comun="Jugar blind vs blind con el mismo rango angosto que usarías "
        "en cualquier otra posición, desperdiciando que ahí enfrente solo "
        "hay un rival.",
 idea_clave="Blind vs blind = rangos más anchos de los dos lados, porque "
        "solo hay un jugador enfrentado.",
),

# ============================================================
# 7.2 — 3-bet: valor y farol
# ============================================================

"T157": dict(  # 3-betear contra un open
 que_es="Hay una tercera opción, además de pagar o retirarte: subir por "
        "encima del open del rival. Eso es un 3-bet. Se llama así porque "
        "es la tercera subida de fichas de la mano — contás la ciega "
        "grande como la primera, el open del rival como la segunda, y tu "
        "subida como la tercera.",
 por_que_importa="Quedate con esto: ya no elegís solamente entre seguir o "
        "irte. Ahora también podés agrandar el bote ahí mismo, en tu "
        "propio turno.",
 como_funciona="3-beteás por dos motivos bien distintos, que vas a ver en "
        "detalle en las próximas dos teorías: con manos que quieren un "
        "bote más grande porque son fuertes (valor), o con manos que se "
        "benefician de que el rival se retire (farol).",
 cuando_lo_uso="Frente al open de un rival, cuando tu mano se beneficia "
        "más de agrandar el bote que de solo pagarlo.",
 cuando_no=None,
 ejemplo="El CO abre. Con A♠A♦ en la mano, 3-betear en vez de solo pagar "
        "empieza a construir un bote grande con la mejor mano posible en "
        "la mesa.",
 error_comun="Pensar el 3-bet como 'siempre agresivo' o 'siempre "
        "arriesgado', sin distinguir por qué lo estás haciendo en cada "
        "caso puntual.",
 idea_clave="3-bet = subir sobre el open del rival. Se hace por valor o "
        "como farol — eso es lo que viene ahora.",
),

"T158": dict(  # 3-bet por valor
 que_es="3-betear con una mano fuerte, buscando construir un bote más "
        "grande porque creés que tu mano está mejor parada que todo el "
        "rango de apertura del rival.",
 por_que_importa="Pensalo así: con tus mejores manos, un bote más grande "
        "te conviene a vos. Cuanta más plata entre en el medio mientras "
        "tenés la mejor mano, mejor para tu bolsillo.",
 como_funciona="Elegís tus manos más fuertes —las que le ganan cómodo al "
        "rango de apertura del rival— y en vez de solo pagar, subís, para "
        "meter más fichas mientras estás adelante.",
 cuando_lo_uso="Con manos que le ganan claramente al rango de apertura "
        "del rival y que quieren jugar un bote grande.",
 cuando_no=None,
 ejemplo="El CO abre. Con K♠K♦ en la mano, 3-betear por valor tiene "
        "sentido: es una mano que le gana a casi todo el rango de "
        "apertura del CO, así que conviene meter más fichas ahí mismo.",
 error_comun="Solo pagar con tus mejores manos 'para no espantar' al "
        "rival. Ahí estás dejando pasar la chance de meter más fichas "
        "justo cuando estás claramente adelante.",
 idea_clave="3-bet por valor = con tu mejor mano, agrandás el bote porque "
        "estás mejor parado.",
),

"T159": dict(  # 3-bet como farol
 que_es="3-betear con una mano que no es fuerte, buscando que el rival se "
        "retire. Acá ganás el bote gracias a la fold equity que ya viste "
        "en N6 — no porque tu mano sea mejor.",
 por_que_importa="Esto suele sorprender: no son solo tus mejores manos "
        "las que pueden 3-betear. Algunas manos flojas también se "
        "benefician de subir, siempre que el rival se retire lo "
        "suficientemente seguido.",
 como_funciona="Elegís manos que no ganan mucho solo pagando —no juegan "
        "bien el flop con el bote chico— pero que sí ganan cuando el "
        "rival se retira frente a tu 3-bet.",
 cuando_lo_uso="Con manos que se benefician más de que el rival foldee "
        "que de ver un flop con el bote chico.",
 cuando_no="Contra un rival que casi nunca foldea frente a una 3-bet. Ahí "
        "te falta la fold equity que hace funcionar el farol — y sin "
        "eso, el farol no tiene sentido.",
 ejemplo="El CO abre. Con A♠5♠ —una mano floja para solo pagar, pero con "
        "algo de potencial— 3-betear como farol busca que el CO se retire "
        "ahí mismo.",
 error_comun="3-betear como farol con cualquier mano floja, sin pararte a "
        "pensar si el rival realmente foldea lo suficiente frente a una "
        "3-bet.",
 idea_clave="3-bet como farol = gana por fold equity, no por tener la "
        "mejor mano.",
),

"T160": dict(  # El rango de call
 que_es="El rango de call es el conjunto completo de manos con las que "
        "elegís pagar un open, en vez de subirlo o retirarte.",
 por_que_importa="Ya viste con qué tipo de mano conviene pagar. Ahora el "
        "trabajo es otro: armar ese rango entero, de antemano — no "
        "decidir mano por mano en el momento, sino saber ya qué entra en "
        "'pago, no subo'.",
 como_funciona="Tu rango de call suele quedar formado por manos que "
        "juegan bien con el bote chico —conectores, parejas medias o "
        "chicas—, dejando tus manos más fuertes y algunos faroles para el "
        "rango de 3-bet.",
 cuando_lo_uso="Al planificar, antes de sentarte a jugar, qué manos vas a "
        "pagar contra un open de determinada posición.",
 cuando_no=None,
 ejemplo="Contra un open del botón, tu rango de call puede incluir manos "
        "como conectores medios y parejas chicas: manos que prefieren "
        "desarrollarse en el flop antes que agrandar el bote.",
 error_comun="No tener un rango de call definido de antemano, y terminar "
        "decidiendo mano por mano sin ningún criterio consistente.",
 idea_clave="Rango de call = las manos con las que elegís pagar, no subir "
        "ni foldear, contra un open concreto.",
),

"T161": dict(  # El rango de 3-bet
 que_es="El rango de 3-bet es el conjunto de manos con las que elegís "
        "subir un open — combinando tus manos de valor con tus manos de "
        "farol.",
 por_que_importa="Fijate por qué importa mezclarlos: si solo 3-beteás con "
        "manos fuertes, un rival atento se va a dar cuenta de que cada "
        "vez que subís tenés lo mejor, y va a dejar de pagarte nunca.",
 como_funciona="Juntás tus mejores manos (valor) con algunas manos flojas "
        "que tienen potencial (farol), y dejás afuera el resto — eso va a "
        "tu rango de call o directo al fold.",
 cuando_lo_uso="Al planificar, de antemano, qué manos vas a 3-betear "
        "contra un open de determinada posición.",
 cuando_no=None,
 ejemplo="Tu rango de 3-bet contra un open del CO puede combinar manos "
        "como AA-QQ y AK (valor) con alguna mano como A5s (farol), "
        "dejando afuera el resto de tus manos jugables.",
 error_comun="3-betear solo con manos de valor, sin ningún farol "
        "mezclado. Un rango así se vuelve predecible enseguida.",
 idea_clave="Rango de 3-bet = valor + farol combinados, nunca solo uno de "
        "los dos.",
),

"TN17": dict(  # El squeeze
 que_es="Un squeeze es 3-betear cuando ya hay un open Y alguien más pagó "
        "ese open antes de que te toque a vos — apretás a los dos "
        "jugadores a la vez.",
 por_que_importa="Con dos rivales ya comprometidos con fichas en el bote, "
        "tu 3-bet tiene que ser más grande que una normal: hay más gente "
        "que podría tener algo bueno, pero también más gente que puede "
        "estar sentada con algo flojo.",
 como_funciona="Pensalo así: el que abrió puede tener un rango amplio y "
        "flojo, y el que solo pagó, en general, tiene una mano que no era "
        "lo bastante fuerte como para subir él mismo. Un squeeze bien "
        "armado aprovecha que ninguno de los dos mostró demasiada fuerza "
        "todavía.",
 cuando_lo_uso="Cuando hay un open y al menos un caller antes de que te "
        "toque a vos, y tu mano se presta para presionar a los dos.",
 cuando_no=None,
 ejemplo="El HJ abre, el CO paga, y en el botón subís con una mano fuerte "
        "o un buen farol: eso es un squeeze, apuntando a que uno de los "
        "dos —o los dos— se retire.",
 error_comun="Usar el mismo tamaño de una 3-bet normal para un squeeze. "
        "Con más jugadores metidos en la mano, te conviene subir más "
        "grande.",
 idea_clave="Squeeze = 3-bet sobre un open Y un caller, con un tamaño más "
        "grande de lo habitual.",
),

# ============================================================
# 7.3 — Anatomía del bote 3-bet
# ============================================================

"T164": dict(  # Qué es un bote 3-bet
 que_es="Un bote 3-bet es un bote que llega al flop después de que "
        "alguien 3-beteó preflop y el otro pagó. Se juega distinto a un "
        "bote 'normal' — lo que vas a empezar a llamar single-raised.",
 por_que_importa="La cantidad de fichas que ya entraron preflop cambia "
        "todo lo que viene después: el bote arranca más grande, y los "
        "stacks que quedan, en relación a ese bote, son más chicos.",
 como_funciona="En vez de una sola subida preflop, hubo dos —el open y "
        "la 3-bet—. Eso deja, al llegar al flop, un bote de partida "
        "bastante más grande que de costumbre.",
 cuando_lo_uso="Al reconocer que la mano llegó al flop con una 3-bet de "
        "por medio: eso te avisa que hay que pensar distinto que en un "
        "bote normal.",
 cuando_no=None,
 ejemplo="Un open a 2.5 BB y una 3-bet a 9 BB dejan un bote de partida de "
        "18-20 BB al llegar al flop — comparado con los 5-6 BB típicos de "
        "un bote sin 3-bet.",
 error_comun="Jugar un bote 3-bet con la misma cabeza que un bote normal, "
        "sin ajustar tamaños ni decisiones a que el bote ya arrancó más "
        "grande.",
 idea_clave="Bote 3-bet = llegó al flop con una 3-bet de por medio. Más "
        "grande de entrada, se juega distinto.",
),

"T165": dict(  # El tamaño del bote 3-bet
 que_es="Se trata de leer, específicamente, cuánto quedó en el bote "
        "después de toda la secuencia de apuestas preflop: el open, la "
        "3-bet, y el call.",
 por_que_importa="Antes de decidir cualquier cosa en el flop, necesitás "
        "saber con cuánto estás jugando de verdad. Un bote 3-bet chico se "
        "juega distinto a uno grande.",
 como_funciona="Sumás lo que puso cada jugador durante el preflop: la "
        "3-bet, más lo que pagó el otro para igualarla, más lo que ya "
        "había de las ciegas antes de que arrancara todo esto.",
 cuando_lo_uso="Al llegar al flop de un bote 3-bet, como primer dato "
        "antes de cualquier otra decisión.",
 cuando_no=None,
 ejemplo="Open a 2.5 BB, 3-bet a 9 BB, call de 9 BB: el bote que llega al "
        "flop es de aproximadamente 19,5 BB — 9 BB del que hizo la "
        "3-bet, más 9 BB de quien la pagó, más 1,5 BB de las dos ciegas "
        "que ya estaban puestas en el medio.",
 error_comun="Llegar al flop de un bote 3-bet sin haber sumado, ni "
        "siquiera de forma aproximada, cuánto hay realmente en el medio.",
 idea_clave="El tamaño del bote 3-bet es el primer dato concreto para "
        "jugar bien el resto de la mano.",
),

"T166": dict(  # El SPR
 que_es="El SPR —stack-to-pot ratio, o 'relación stack-bote'— te dice "
        "cuántas veces entra el bote en el stack efectivo. Y el stack "
        "efectivo es el más chico entre el tuyo y el del rival, porque "
        "eso es lo máximo que realmente puede terminar en el medio.",
 por_que_importa="Un SPR bajo —poco stack en relación al bote— te acerca "
        "rápido a jugarte todo el stack en la mano. Un SPR alto te deja "
        "mucho más margen para decisiones finas en varias calles.",
 como_funciona="Dividís el stack efectivo por el tamaño del bote. Si los "
        "dos tienen el mismo stack, ese número te alcanza tal cual; si "
        "son distintos, siempre usás el más chico de los dos. Y ojo con "
        "esto: los botes 3-bet, al ser más grandes de entrada con los "
        "mismos stacks, dejan un SPR más bajo que un bote normal.",
 cuando_lo_uso="Al llegar al flop, para entender qué tan 'comprometido' "
        "vas a estar con el resto de tu stack en esa mano puntual.",
 cuando_no=None,
 ejemplo="Los dos jugadores tienen 100 BB de stack efectivo, y el bote es "
        "de aproximadamente 19,5 BB. El SPR es aproximadamente 5 "
        "(100÷19,5 ≈ 5,1) — bastante más bajo que en un bote normal de 6 "
        "BB con el mismo stack, donde el SPR sería como 16,6.",
 error_comun="Ignorar el SPR y jugar un bote 3-bet, de SPR bajo, con la "
        "misma cautela que un bote de SPR alto, donde hay mucho más "
        "margen para maniobrar.",
 idea_clave="SPR = stack ÷ bote. Más bajo en los botes 3-bet: te acerca "
        "más rápido a jugarte todo el stack.",
),

"T167": dict(  # El rango del 3-bettor
 que_es="Se trata de estimar el conjunto de manos con las que el rival, "
        "probablemente, te 3-beteó.",
 por_que_importa="Saber leer ese rango te permite jugar mucho mejor el "
        "resto de la mano. Ya viste que un rango de 3-bet combina valor y "
        "farol — y eso te da información concreta para trabajar, no una "
        "adivinanza.",
 como_funciona="Pensá en lo que ya sabés de rangos de 3-bet: manos "
        "fuertes de valor combinadas con algunos faroles, según la "
        "posición desde la que 3-beteó y el estilo del rival.",
 cuando_lo_uso="Al enfrentar una 3-bet, antes de decidir tu respuesta.",
 cuando_no=None,
 ejemplo="Un rival 3-betea desde el botón contra tu open del CO: su rango "
        "probablemente combina manos fuertes con algunos faroles — más "
        "amplio que si el mismo 3-bet viniera de la ciega grande, fuera "
        "de posición.",
 error_comun="Asumir que cualquier 3-bet significa automáticamente una "
        "mano premium. Te olvidás de que los rangos de 3-bet, bien "
        "armados, incluyen faroles.",
 idea_clave="El rango del 3-bettor combina valor y farol — no des por "
        "sentado que siempre es lo mejor posible.",
),

"T168": dict(  # El rango del que paga la 3-bet
 que_es="Acá estimás el conjunto de manos con las que el rival, "
        "probablemente, pagó tu 3-bet en vez de subir o retirarse.",
 por_que_importa="Pagar una 3-bet, en vez de subir a una 4-bet o "
        "foldear, suele filtrar bastante el rango del rival: la mayoría "
        "de las manos flojas se van, y muchas de las más fuertes "
        "prefieren resubir en vez de solo pagar.",
 como_funciona="El rango de quien paga una 3-bet suele quedar compuesto "
        "por manos buenas, pero no tan fuertes como para 4-betear: "
        "parejas medias, broadways decentes, y alguna mano especulativa "
        "con buen potencial para el postflop.",
 cuando_lo_uso="Al jugar un flop de un bote 3-bet donde vos fuiste quien "
        "3-beteó, para leer qué tipo de mano trae el rival que pagó.",
 cuando_no=None,
 ejemplo="3-beteás y el rival paga. Ese rango, en general, ya viene con "
        "sus manos más débiles filtradas afuera — está compuesto por "
        "manos que juegan bien un bote de SPR bajo.",
 error_comun="Tratar el rango de quien paga una 3-bet como si fuera tan "
        "amplio y flojo como un rango de defensa normal. No lo es: ya "
        "pasó un filtro más.",
 idea_clave="Pagar una 3-bet filtra el rango: suele quedar compuesto por "
        "manos razonablemente buenas, no cualquier cosa.",
),

"T169": dict(  # La posición en el bote 3-bet
 que_es="En un bote 3-bet, con SPR más bajo y menos margen para maniobrar "
        "en las calles que faltan, la posición pesa todavía más que en un "
        "bote normal.",
 por_que_importa="Pensalo así: con menos margen de maniobra, cada "
        "decisión vale más. Tener información extra por estar en "
        "posición se vuelve más valioso, no menos.",
 como_funciona="Repasá lo que ya sabés de la posición, de N3 y N5: actuar "
        "último te da información antes de decidir. En un bote 3-bet, con "
        "el bote ya grande desde el arranque, esa ventaja se nota mucho "
        "más rápido.",
 cuando_lo_uso="Al planear cómo vas a jugar un bote 3-bet, según si vas a "
        "estar en posición o fuera de ella.",
 cuando_no=None,
 ejemplo="Con la misma mano, jugar un bote 3-bet en posición te permite "
        "tomar decisiones más finas —controlar el tamaño del bote, ver "
        "una calle más barata— que jugarlo fuera de posición con ese "
        "mismo SPR bajo.",
 error_comun="Subestimar cuánto pesa la posición en un bote 3-bet, "
        "pensando 'total el SPR ya es bajo, da lo mismo'. No da lo "
        "mismo.",
 idea_clave="Con SPR bajo, la posición pesa más, no menos: hay menos "
        "margen para equivocarse.",
),

# ============================================================
# 7.4 — Responder a una 3-bet / 4-bet
# ============================================================

"T170": dict(  # La 4-bet
 que_es="Una 4-bet es subir por encima de una 3-bet — la cuarta subida de "
        "fichas de la secuencia: ciega grande, open, 3-bet, y ahora tu "
        "4-bet.",
 por_que_importa="Es el siguiente escalón de esta guerra preflop que "
        "venimos viendo: abriste, te 3-betearon, y tu mano es lo "
        "bastante fuerte —o estratégica— como para seguir subiendo en vez "
        "de solo pagar o foldear.",
 como_funciona="Aparece cuando vos abriste, el rival te 3-beteó, y "
        "decidís responder con una subida en vez de un call o un fold.",
 cuando_lo_uso="Al enfrentar una 3-bet con una mano que quiere seguir "
        "subiendo en vez de solo pagar.",
 cuando_no=None,
 ejemplo="Abrís desde el CO, el botón te 3-betea, y con A♠A♦ en la mano "
        "subís de nuevo: eso es una 4-bet.",
 error_comun="Confundir cualquier subida preflop con una 4-bet. Es, "
        "específicamente, la subida que responde a una 3-bet — ni antes, "
        "ni en otro contexto.",
 idea_clave="4-bet = subir sobre una 3-bet. El siguiente escalón después "
        "del open y la 3-bet.",
),

"T171": dict(  # Foldear contra una 3-bet
 que_es="Retirarte cuando abriste, te 3-betearon, y tu mano no alcanza ni "
        "para pagar ni para 4-betear.",
 por_que_importa="Ya viste que la mayoría de las manos se foldean al "
        "abrir y al defender. Bueno, acá pasa lo mismo frente a una "
        "3-bet: es una subida grande, contra un rango del rival que ya "
        "viene bastante fuerte de por sí.",
 como_funciona="Si tu mano no entra en tu rango de call ni en tu rango de "
        "4-bet contra esa 3-bet puntual, foldeás — y sin arrepentimiento: "
        "abriste con una mano razonable, esto es parte normal del juego.",
 cuando_lo_uso="Cada vez que abrís, te 3-betean, y tu mano no alcanza "
        "para seguir.",
 cuando_no=None,
 ejemplo="Abrís con K♠9♦ desde el CO y el botón te 3-betea. Esa mano no "
        "entra ni en tu rango de call ni en tu rango de 4-bet contra esa "
        "3-bet — foldeás.",
 error_comun="Sentir que 'ya invertiste' con el open, y por eso tenés que "
        "pagar la 3-bet. Ese open ya está hecho y ya es pasado: la "
        "decisión de acá en más se toma con la información nueva que "
        "tenés ahora.",
 idea_clave="Foldear contra una 3-bet sigue siendo, con diferencia, la "
        "respuesta más frecuente.",
),

"T172": dict(  # Pagar una 3-bet
 que_es="Pagar la 3-bet del rival, en vez de foldear o 4-betear, con una "
        "mano que juega bien un bote 3-bet.",
 por_que_importa="Pasa lo mismo que con el call preflop que ya viste: no "
        "toda mano que 'alcanza' conviene 4-betearla. Algunas prefieren "
        "ver el flop con el bote ya grande, en vez de agrandarlo todavía "
        "más.",
 como_funciona="Pagás con manos buenas que no ganan lo suficiente "
        "4-beteando —ahí perderías el valor de las manos más flojas del "
        "rival, que se retirarían frente a una 4-bet— y que juegan bien "
        "un flop de SPR bajo.",
 cuando_lo_uso="Con una mano sólida, con posición favorable, que "
        "prefiere jugar el flop antes que seguir agrandando el bote "
        "preflop.",
 cuando_no=None,
 ejemplo="Abrís con A♠Q♠ desde el botón y el rival te 3-betea. Pagar, en "
        "vez de 4-betear, mantiene en el bote a las manos más flojas de "
        "su rango de 3-bet — las que foldearían frente a una 4-bet.",
 error_comun="4-betear con cualquier mano que 'alcanza' contra una "
        "3-bet, sin pararte a pensar si en realidad conviene más pagar.",
 idea_clave="Pagar una 3-bet es para manos buenas que prefieren jugar el "
        "flop, no agrandar más el bote todavía.",
),

"T173": dict(  # 4-bet por valor
 que_es="4-betear con tus manos más fuertes, buscando meter más fichas "
        "mientras estás mejor parado que el rango de 3-bet del rival.",
 por_que_importa="Con tus manos más fuertes de todas, conviene seguir "
        "agrandando el bote — es la misma lógica que ya viste con la "
        "3-bet por valor, un escalón más arriba.",
 como_funciona="Elegís las manos que le ganan cómodo incluso al rango de "
        "3-bet del rival —que ya es, en promedio, más fuerte que un "
        "rango de apertura común— y subís de nuevo.",
 cuando_lo_uso="Con tus manos más fuertes, frente a una 3-bet.",
 cuando_no=None,
 ejemplo="Abrís y te 3-betean. Con K♠K♦ en la mano, 4-betear por valor "
        "tiene sentido: le ganás cómodo a la inmensa mayoría del rango de "
        "3-bet del rival — solo un As-As te supera de entrada.",
 error_comun="Solo pagar con tus manos más fuertes por miedo a que el "
        "rival se retire. Ahí dejás de construir el bote más grande "
        "posible justo cuando estás claramente adelante.",
 idea_clave="4-bet por valor = con tu mano más fuerte, seguís agrandando "
        "el bote.",
),

"T174": dict(  # 4-bet como farol
 que_es="4-betear con una mano que no es de valor, usando una carta que "
        "el rival necesitaría para tener sus propias manos más fuertes de "
        "3-bet.",
 por_que_importa="Pasa lo mismo que con la 3-bet: no son solo tus "
        "mejores manos las que pueden 4-betear. Algunas manos flojas, "
        "pero con la carta correcta en la mano, también funcionan como "
        "farol.",
 como_funciona="Elegís una mano que, además de tener algo de potencial, "
        "hace un poco menos probable que el rival tenga las manos MÁS "
        "fuertes de su rango de 3-bet — porque una de esas cartas ya está "
        "en tu mano, no dando vueltas en el mazo.",
 cuando_lo_uso="Con una mano floja que, sin embargo, hace un poco menos "
        "probable que el rival tenga sus combos más fuertes.",
 cuando_no="Contra un rival que casi nunca foldea frente a una 4-bet. "
        "Ahí te falta la fold equity que hace funcionar el farol.",
 ejemplo="Abrís, te 3-betean, y tenés A♠5♦ en la mano. Ese As hace un "
        "poco menos probable que el rival tenga AA o AK en su rango de "
        "3-bet. 4-betear ahí busca que el resto de su rango se retire.",
 error_comun="4-betear como farol con cualquier mano floja, sin elegir "
        "una que además le reste combos fuertes al rango del rival.",
 idea_clave="4-bet como farol = elegís una mano cuya carta hace un poco "
        "menos probable que el rival tenga sus manos más fuertes.",
),

}
