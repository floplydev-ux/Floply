# -*- coding: utf-8 -*-
"""
Genera la estructura DEFINITIVA de la Academia Floply.
13 niveles · subniveles · 308 teorías originales + 18 nuevas = 326.
Salida: curriculum_spec.json  +  validación por stdout.
"""
import json, sys, collections, os, importlib.util

# ------------------------------------------------------------------ #
# 0. CONTENIDO REDACTADO (PASO 4) — un módulo scratchpad/content_nX.py
#    por nivel; cada uno expone un dict  NX = {theory_id: {campos...}}.
#    El JSON sigue siendo la fuente de verdad: esto solo lo alimenta.
# ------------------------------------------------------------------ #
def _load_written_content():
    here = os.path.dirname(os.path.abspath(__file__))
    merged = {}
    for lvl in range(1, 14):
        mod = "content_n%d" % lvl
        path = os.path.join(here, mod + ".py")
        if not os.path.exists(path):
            continue
        spec = importlib.util.spec_from_file_location(mod, path)
        m = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(m)
        merged.update(getattr(m, "N%d" % lvl, {}))
    return merged

CONTENT = _load_written_content()
CONTENT_KEYS = [
    "que_es", "por_que_importa", "como_funciona", "cuando_lo_uso",
    "cuando_no", "ejemplo", "error_comun", "idea_clave",
]

# ------------------------------------------------------------------ #
# 1. TÍTULOS de los 308 temas del documento maestro
# ------------------------------------------------------------------ #
T = {
 1:"Objetivo del juego",2:"La baraja",3:"Cartas privadas",4:"Cartas comunitarias",5:"La mano de 5 cartas",
 6:"El ranking de manos",7:"Desempates",8:"El showdown",9:"Ganar por cartas",10:"Ganar por fold",
 11:"La mesa 6-max",12:"El botón (BTN)",13:"La ciega chica (SB)",14:"La ciega grande (BB)",15:"UTG",
 16:"El hijack (HJ)",17:"El cutoff (CO)",18:"El orden de acción preflop",19:"El orden de acción postflop",
 20:"Estar en posición",21:"Estar fuera de posición",22:"Posición relativa",
 23:"El stack",24:"La ciega grande como unidad",25:"El stack de 100 BB",26:"La ciega chica (aporte)",
 27:"La ciega grande (aporte)",28:"El bote (pot)",29:"El tamaño del bote",30:"La apuesta",
 31:"El coste de una decisión",32:"El stack efectivo",
 33:"Fold",34:"Check",35:"Call",36:"Bet",37:"Raise",38:"Re-raise",39:"All-in",40:"Acción cerrada",
 41:"Acción legal",42:"El orden de acción",
 43:"El preflop",44:"El flop",45:"El turn",46:"El river",47:"La ronda de apuestas",
 48:"El cambio de información entre calles",49:"El fin de la mano",
 50:"Carta alta",51:"Pareja",52:"Doble pareja",53:"Trío",54:"Escalera",55:"Color",56:"Full",
 57:"Póker",58:"Escalera de color",59:"Escalera real",60:"Comparar por categoría",61:"Comparar por kicker",
 62:"Cuando el board juega",63:"Elegir la mejor combinación de 5",
 64:"Parejas servidas (pocket pairs)",65:"Manos del mismo palo (suited)",66:"Manos de distinto palo (offsuit)",
 67:"Manos conectadas",68:"Broadways",69:"Manos con As",70:"Manos premium",71:"Pares medios",
 72:"Pares pequeños",73:"Mano dominada",74:"Mano especulativa",
 75:"Board seco",76:"Board coordinado",77:"Board monótono",78:"Board rainbow",79:"Board pareado",
 80:"Posibilidades de escalera",81:"Posibilidades de color",82:"Proyectos (draws)",83:"Proyecto backdoor",
 84:"Cartas peligrosas",85:"Cartas que favorecen tu mano",86:"Cartas que favorecen al rival",
 87:"La fuerza de una pareja",88:"Top pair",89:"Middle pair",90:"Bottom pair",91:"Overpair",
 92:"Doble pareja (hecha)",93:"Set",94:"Trips",95:"Escalera (hecha)",96:"Color (hecho)",97:"Full (hecho)",
 98:"Los nuts",99:"Cerca de los nuts (near-nuts)",100:"Bluff catcher",
 101:"Outs",102:"Outs limpios",103:"Outs sucios",104:"Equity",105:"Equity contra una mano",
 106:"Equity contra un rango",107:"Equity de un proyecto",108:"La regla del 2",109:"La regla del 4",
 110:"Probabilidad",
 111:"El precio del call",112:"El bote actual",113:"La apuesta del rival",114:"El bote final",
 115:"Pot odds",116:"La equity necesaria",117:"Comparar equity contra precio",118:"Calls rentables",
 119:"Calls perdedores",
 120:"El valor esperado (EV)",121:"Una decisión +EV",122:"Una decisión -EV",123:"El EV del call",
 124:"El EV del fold",125:"El EV de apostar",126:"El EV de un farol",127:"El EV a largo plazo",
 128:"Qué es un rango",129:"Un rango fuerte",130:"Un rango débil",131:"Un rango amplio",132:"Un rango estrecho",
 133:"Combos",134:"Rango contra mano",135:"Rango contra rango",136:"El rango percibido",
 137:"El rango de apertura",138:"El rango de defensa",
 139:"Qué es el RFI (raise first in)",140:"Abrir una mano",141:"Foldear preflop",142:"El tamaño de apertura",
 143:"Abrir a 2x",144:"Abrir a 2.5x",145:"Abrir a 3x",146:"Rango de apertura de UTG",147:"Rango de apertura del HJ",
 148:"Rango de apertura del CO",149:"Rango de apertura del BTN",150:"Rango de apertura de la SB",
 151:"La BB no abre",152:"La posición define el rango",153:"El rango cambia según la acción previa",
 154:"¿Podemos pagar un open?",155:"El call preflop",156:"Foldear contra un open",157:"3-betear contra un open",
 158:"3-bet por valor",159:"3-bet como farol",160:"El rango de call",161:"El rango de 3-bet",
 162:"La posición del que paga",163:"El tamaño del open del rival",
 164:"Qué es un bote 3-bet",165:"El tamaño del bote 3-bet",166:"El SPR",167:"El rango del 3-bettor",
 168:"El rango del que paga la 3-bet",169:"La posición en el bote 3-bet",170:"La 4-bet",171:"Foldear contra una 3-bet",
 172:"Pagar una 3-bet",173:"4-bet por valor",174:"4-bet como farol",
 175:"Qué es la continuation bet (c-bet)",176:"Por qué hacemos c-bet",177:"C-bet por valor",178:"C-bet como farol",
 179:"C-bet con proyecto",180:"C-bet en board seco",181:"C-bet en board coordinado",182:"C-bet en posición",
 183:"C-bet fuera de posición",184:"La frecuencia de c-bet",185:"El tamaño de la c-bet",
 186:"La segunda decisión postflop",187:"Una carta buena para nosotros",188:"Una carta buena para el rival",
 189:"Una carta blank",190:"Una scare card",191:"El barrel",192:"El double barrel",193:"Check en el turn",
 194:"Bet en el turn",195:"Pot control",196:"Proyectos que siguen en el turn",197:"Los cambios de equity",
 198:"El river: no quedan cartas",199:"La value bet",200:"El value fino (thin value)",201:"El farol (bluff)",
 202:"El bluff catcher (uso)",203:"Check back",204:"Check/fold",205:"Bet/fold",206:"Polarización",
 207:"El rango de valor",208:"El rango de farol",209:"¿Qué manos peores te pagan?",210:"¿Qué manos mejores foldean?",
 211:"Las acciones son información",212:"El rango después de un open",213:"El rango después de un call",
 214:"El rango después de una 3-bet",215:"El rango después de una c-bet",216:"El rango después de un raise",
 217:"El rango después de un check",218:"Estrechar el rango (narrowing)",219:"Contar los combos posibles",
 220:"La línea de juego",221:"La coherencia de la línea",222:"Identificar valor",223:"Identificar faroles",
 224:"Ventaja de rango",225:"Ventaja de nuts",226:"Ventaja posicional (estratégica)",227:"La iniciativa",
 228:"La profundidad de stack",229:"El SPR (uso estratégico)",230:"Polarización (uso estratégico)",
 231:"Condensación de rango",232:"Bloqueadores (blockers)",233:"El efecto de remover combos (removal)",
 234:"La frecuencia mínima de defensa (MDF)",235:"La relación farol/valor",236:"Pensar en frecuencias",
 237:"Explotar vs jugar equilibrado (GTO)",238:"Adaptarse al rival",
 239:"Qué es NL2",240:"100 BB en NL2 (impacto estratégico)",241:"El rake",242:"El valor de las manos fuertes",
 243:"Evitar los hero calls",244:"Evitar los calls marginales",245:"Evitar jugar demasiadas manos",
 246:"Aprovechar los errores del rival",247:"Apostar más fuerte por valor",248:"Farolear de forma selectiva",
 249:"La posición como fuente de ganancia",250:"La disciplina preflop",251:"La selección de manos",
 252:"Reconocer spots rentables",
 253:"¿Cuál es mi posición?",254:"¿Cuál es mi mano?",255:"¿Cuál es la acción previa?",256:"¿Cuál es el rango del rival?",
 257:"¿Cuál es el board?",258:"¿Qué mano tengo hecha?",259:"¿Qué proyectos tengo?",260:"¿Qué equity tengo?",
 261:"¿Cuál es el tamaño del bote?",262:"¿Cuánto cuesta mi decisión?",263:"¿Qué opciones tengo?",
 264:"¿Cuál tiene mejor EV?",265:"¿Qué aporta la acción del rival?",266:"¿Qué cambia si aparece cierta carta?",
 267:"Elegir la acción",268:"Revisar el resultado",269:"Separar el resultado de la calidad de la decisión",
 270:"Error: jugar demasiadas manos",271:"Error: jugar fuera de posición sin razón",
 272:"Error: pagar porque 'ya puse dinero'",273:"Error: pagar de más con manos marginales",
 274:"Error: sobrevalorar el top pair",275:"Error: no reconocer que estás dominado",
 276:"Error: perseguir proyectos sin el precio correcto",277:"Error: confundir outs con equity",
 278:"Error: ignorar el rango del rival",279:"Error: mirar solo tus cartas",280:"Error: ignorar el board",
 281:"Error: apostar en automático",282:"Error: hacer c-bet en automático",
 283:"Error: farolear sin pensar en el rango rival",284:"Error: no hacer value bet",
 285:"Error: hacer hero call por curiosidad",286:"Error: decidir en tilt",
 287:"Error: confundir ganar la mano con tomar una buena decisión",
 288:"Integrar: el RFI preflop",289:"Integrar: jugar contra un open",290:"Integrar: la defensa de BB",
 291:"Integrar: la 3-bet",292:"Integrar: un bote 3-bet",293:"Integrar: un bote single-raised",
 294:"Integrar: la c-bet",295:"Integrar: el check-back",296:"Integrar: jugar un proyecto en el flop",
 297:"Integrar: jugar una mano hecha en el flop",298:"Integrar: el segundo barrel en el turn",
 299:"Integrar: el check en el turn",300:"Integrar: el valor en el river",301:"Integrar: el farol en el river",
 302:"Integrar: el bluff catch en el river",303:"Integrar: la decisión de all-in",
 304:"La decisión por pot odds",305:"La decisión por equity",306:"La decisión por rango",
 307:"La decisión por posición",308:"La decisión integrada",
}

# 18 teorías nuevas aprobadas
NEW = {
 "TN01":"Qué es un limp","TN02":"El isolation raise","TN03":"Overlimpear o foldear",
 "TN04":"Jugar un bote limpeado","TN05":"Enfrentar una c-bet","TN06":"Check-raise por valor",
 "TN07":"Check-raise como semi-farol","TN08":"El float","TN09":"El probe bet y el donk bet",
 "TN10":"Implied odds","TN11":"Reverse implied odds","TN12":"La varianza","TN13":"La fold equity",
 "TN14":"Cómo se ve un rango (la grilla 13×13)","TN15":"La realización de equity",
 "TN16":"Ciega contra ciega (blind vs blind)","TN17":"El squeeze","TN18":"C-bet en botes multiway",
}

# ------------------------------------------------------------------ #
# 2. OBJETIVOS (una frase por teoría)
# ------------------------------------------------------------------ #
OBJ = {
 1:"Entender que el objetivo de cada mano es llevarse el bote.",
 2:"Conocer las 52 cartas, los 4 palos y el orden de los valores.",
 3:"Saber que cada jugador recibe 2 cartas que solo ve él.",
 4:"Saber que el flop, el turn y el river son cartas de todos.",
 5:"Entender que tu mano son las mejores 5 de las 7 disponibles.",
 6:"Tener una idea general de que hay manos mejores y peores.",
 7:"Saber que cuando dos manos empatan en categoría se mira la carta más alta.",
 8:"Entender qué es mostrar las cartas al final para ver quién gana.",
 9:"Saber que se puede ganar mostrando la mejor mano en el showdown.",
 10:"Saber que también se gana si todos los rivales se retiran.",
 11:"Entender cómo se sienta y funciona una mesa de 6 jugadores.",
 12:"Reconocer el botón y saber que marca desde dónde se reparte.",
 13:"Saber qué es la ciega chica y dónde se sienta.",
 14:"Saber qué es la ciega grande y dónde se sienta.",
 15:"Reconocer UTG como la primera silla en hablar preflop.",
 16:"Reconocer el hijack como posición media.",
 17:"Reconocer el cutoff como la silla anterior al botón.",
 18:"Saber el orden en que se habla antes del flop: UTG→HJ→CO→BTN→SB→BB.",
 19:"Saber que después del flop el orden se invierte: la SB abre.",
 20:"Entender que estar en posición es actuar después que el rival.",
 21:"Entender que estar fuera de posición es tener que decidir primero.",
 22:"Saber que la posición se mide entre los jugadores que siguen en la mano.",
 23:"Saber que el stack son las fichas con las que jugás esa mano.",
 24:"Aprender a pensar todo en ciegas grandes, no en dinero.",
 25:"Reconocer 100 BB como el stack estándar de referencia.",
 26:"Saber cuánto pone la ciega chica y por qué es obligatoria.",
 27:"Saber cuánto pone la ciega grande y por qué es obligatoria.",
 28:"Entender que el bote son todas las fichas apostadas en juego.",
 29:"Saber leer cuánto hay en el bote en cualquier momento.",
 30:"Entender qué es poner fichas voluntariamente en el bote.",
 31:"Empezar a ver cada decisión como algo que tiene un precio.",
 32:"Entender que lo que se puede jugar es el stack más chico de la mano.",
 33:"Saber qué es abandonar la mano y cuándo tiene sentido.",
 34:"Saber qué es pasar sin apostar cuando no hay apuesta delante.",
 35:"Saber qué es igualar la apuesta que tenés enfrente.",
 36:"Saber qué es ser el primero en apostar en una calle.",
 37:"Saber qué es subir por encima de una apuesta.",
 38:"Saber qué es volver a subir sobre una subida.",
 39:"Saber qué es apostar todo el stack.",
 40:"Entender cuándo termina una ronda de apuestas.",
 41:"Saber qué acciones están disponibles en cada situación.",
 42:"Saber en qué orden le toca actuar a cada jugador.",
 43:"Entender el preflop: solo tenés tus 2 cartas y hay una ronda de apuestas.",
 44:"Entender el flop: se abren 3 cartas comunitarias.",
 45:"Entender el turn: la 4ª carta comunitaria.",
 46:"Entender el river: la 5ª y última carta comunitaria.",
 47:"Entender que en cada calle hay una ronda de apuestas.",
 48:"Ver que cada carta nueva cambia lo que puede tener cada uno.",
 49:"Saber que la mano termina en fold o en showdown.",
 50:"Reconocer la carta alta como la mano más débil.",
 51:"Reconocer una pareja.",52:"Reconocer una doble pareja.",53:"Reconocer un trío.",
 54:"Reconocer una escalera (5 cartas seguidas).",55:"Reconocer un color (5 del mismo palo).",
 56:"Reconocer un full (trío + pareja).",57:"Reconocer un póker (4 iguales).",
 58:"Reconocer una escalera de color.",59:"Reconocer la escalera real como la mejor mano posible.",
 60:"Saber que primero decide la categoría de la mano, no las cartas sueltas.",
 61:"Saber desempatar dos manos de la misma categoría por el kicker.",
 62:"Reconocer cuándo tu mejor mano son las 5 cartas del board.",
 63:"Aprender a elegir las mejores 5 entre las 7 disponibles.",
 64:"Reconocer una pareja servida y su potencial de ligar trío.",
 65:"Reconocer manos del mismo palo y su potencial de color.",
 66:"Reconocer manos de distinto palo y qué pierden.",
 67:"Reconocer manos conectadas y su potencial de escalera.",
 68:"Reconocer las broadways (dos cartas T o mayores).",
 69:"Reconocer las manos con As y por qué el kicker importa tanto.",
 70:"Reconocer las manos premium (AA, KK, QQ, AK).",
 71:"Reconocer los pares medios (TT–77) y su juego incómodo.",
 72:"Reconocer los pares pequeños (66–22) y que juegan a ligar set.",
 73:"Reconocer cuándo tu mano está dominada por una mejor con la misma carta alta.",
 74:"Reconocer una mano especulativa: floja ahora, con potencial si liga.",
 75:"Reconocer un board seco: pocas conexiones y proyectos.",
 76:"Reconocer un board coordinado: muchos proyectos y manos hechas posibles.",
 77:"Reconocer un board monótono: 3 cartas del mismo palo.",
 78:"Reconocer un board rainbow: 3 palos distintos, sin proyecto de color.",
 79:"Reconocer un board pareado y qué combos habilita.",
 80:"Identificar qué escaleras son posibles en un board.",
 81:"Identificar cuándo hay proyecto de color en un board.",
 82:"Distinguir un proyecto abierto (8 outs) de un gutshot (4 outs).",
 83:"Reconocer un proyecto backdoor: necesita las dos cartas por venir.",
 84:"Identificar las cartas del turn/river que empeoran tu situación.",
 85:"Identificar las cartas que mejoran tu mano.",
 86:"Identificar las cartas que probablemente ayudan al rival.",
 87:"Entender que no todas las parejas valen lo mismo.",
 88:"Reconocer el top pair: pareja con la carta más alta del board.",
 89:"Reconocer el middle pair y su fuerza intermedia.",
 90:"Reconocer el bottom pair y su debilidad.",
 91:"Reconocer un overpair: pareja servida más alta que el board.",
 92:"Reconocer una doble pareja hecha y su fuerza real.",
 93:"Reconocer un set (trío con pareja servida) y por qué es oro.",
 94:"Reconocer trips (trío con una carta del board) y su diferencia con el set.",
 95:"Reconocer una escalera hecha y su vulnerabilidad al color.",
 96:"Reconocer un color hecho y cuándo no es el nut.",
 97:"Reconocer un full hecho.",
 98:"Entender qué son los nuts: la mejor mano posible en ese board.",
 99:"Reconocer una mano casi imbatible pero no la mejor.",
 100:"Reconocer un bluff catcher: gana a faroles, pierde contra valor.",
 101:"Contar las cartas que todavía pueden mejorar tu mano.",
 102:"Distinguir los outs que de verdad te dan la mejor mano.",
 103:"Reconocer outs que pueden darte la segunda mejor mano.",
 104:"Entender la equity como el porcentaje de veces que ganás la mano.",
 105:"Estimar tu equity contra una mano concreta.",
 106:"Estimar tu equity contra todo el rango posible del rival.",
 107:"Estimar la equity de un proyecto que todavía no ligó.",
 108:"Usar la regla del 2 para estimar equity con una carta por venir.",
 109:"Usar la regla del 4 para estimar equity con dos cartas por venir.",
 110:"Entender la probabilidad como frecuencia a largo plazo.",
 111:"Calcular cuánto tenés que pagar para seguir en la mano.",
 112:"Leer cuánto hay en el bote antes de tu decisión.",
 113:"Leer el tamaño de la apuesta del rival en relación al bote.",
 114:"Calcular cuánto habrá en el bote si pagás.",
 115:"Entender las pot odds como 'lo que pagás vs lo que podés ganar'.",
 116:"Calcular la equity mínima que necesitás para que un call sea rentable.",
 117:"Comparar tu equity con la equity necesaria para decidir.",
 118:"Reconocer un call que gana fichas a largo plazo.",
 119:"Reconocer un call que pierde fichas a largo plazo.",
 120:"Entender el EV como el resultado promedio de repetir la decisión mil veces.",
 121:"Reconocer una decisión que gana fichas en promedio.",
 122:"Reconocer una decisión que pierde fichas en promedio.",
 123:"Estimar si pagar tiene EV positivo o negativo.",
 124:"Entender que foldear tiene EV 0 y a veces es lo mejor.",
 125:"Estimar el EV de apostar por valor.",
 126:"Entender que un farol gana por las veces que el rival foldea.",
 127:"Entender que una buena decisión puede perder una mano y aun así ser correcta.",
 128:"Entender un rango como el conjunto de todas las manos posibles en una situación.",
 129:"Reconocer un rango fuerte: muchas manos hechas de valor.",
 130:"Reconocer un rango débil: muchas manos marginales y faroles.",
 131:"Reconocer un rango amplio: muchas combinaciones.",
 132:"Reconocer un rango estrecho: pocas manos, casi todas fuertes.",
 133:"Contar cuántas combinaciones concretas forman una clase de mano.",
 134:"Comparar tu mano concreta contra todo el rango del rival.",
 135:"Comparar dos rangos completos entre sí.",
 136:"Entender qué rango cree el rival que tenés vos.",
 137:"Entender el rango de apertura como las manos con las que subís de entrada.",
 138:"Entender el rango de defensa como las manos con las que seguís frente a un open.",
 139:"Entender el RFI: subir siendo el primero en entrar al bote.",
 140:"Decidir abrir una mano que entra en tu rango.",
 141:"Decidir foldear una mano que no entra en tu rango.",
 142:"Entender que el tamaño de apertura estándar en 6-max es 2–3 BB.",
 143:"Saber cuándo un open a 2x tiene sentido.",
 144:"Reconocer 2.5x como el tamaño de apertura de referencia.",
 145:"Saber cuándo conviene abrir un poco más grande (3x).",
 146:"Conocer el rango de apertura de UTG: cerrado, solo manos fuertes.",
 147:"Conocer el rango de apertura del HJ: algo más ancho que UTG.",
 148:"Conocer el rango de apertura del CO: ancho.",
 149:"Conocer el rango de apertura del BTN: el más ancho de la mesa.",
 150:"Conocer el rango de apertura de la SB y por qué se juega distinto.",
 151:"Entender que la BB no hace RFI: completa o sube frente a limpers, o defiende.",
 152:"Entender que la posición define qué tan ancho es tu rango.",
 153:"Entender que tu rango cambia según lo que hicieron los rivales antes.",
 154:"Evaluar si una mano alcanza para seguir frente a un open.",
 155:"Decidir pagar un open con posición y una mano jugable.",
 156:"Decidir foldear frente a un open cuando la mano no alcanza.",
 157:"Decidir 3-betear en vez de pagar o foldear.",
 158:"3-betear con manos fuertes que quieren jugar un bote grande.",
 159:"3-betear como farol con manos que se benefician de que el rival foldee.",
 160:"Construir el rango con el que pagás un open.",
 161:"Construir el rango con el que 3-beteás un open.",
 162:"Entender cómo cambia tu defensa según tu posición respecto al que abrió.",
 163:"Ajustar tu respuesta según el tamaño del open del rival.",
 164:"Entender qué es un bote 3-bet y por qué se juega distinto.",
 165:"Leer el tamaño del bote que deja una 3-bet.",
 166:"Entender el SPR: la relación entre el stack que queda y el bote.",
 167:"Estimar el rango del que 3-beteó.",
 168:"Estimar el rango del que pagó la 3-bet.",
 169:"Entender el peso de la posición en un bote 3-bet.",
 170:"Entender qué es una 4-bet y cuándo aparece.",
 171:"Decidir foldear frente a una 3-bet.",
 172:"Decidir pagar una 3-bet con posición y una mano que juega bien.",
 173:"4-betear por valor con las manos más fuertes.",
 174:"4-betear como farol con manos que le quitan combos de valor al rival.",
 175:"Entender la c-bet: apostar el flop siendo el agresor preflop.",
 176:"Entender por qué la c-bet funciona: iniciativa y rango.",
 177:"C-betear por valor con manos que quieren pago.",
 178:"C-betear como farol con manos que quieren que el rival foldee.",
 179:"C-betear con un proyecto: farol con equity para mejorar.",
 180:"Ajustar la c-bet en un board seco: se apuesta más seguido.",
 181:"Ajustar la c-bet en un board coordinado: más selectivo.",
 182:"Aprovechar la c-bet cuando jugás en posición.",
 183:"Ajustar la c-bet cuando jugás fuera de posición.",
 184:"Entender que no se c-betea siempre: hay una frecuencia.",
 185:"Elegir el tamaño de la c-bet según el board y el objetivo.",
 186:"Reevaluar la mano en el turn con la carta nueva.",
 187:"Reconocer cuando el turn mejora tu situación.",
 188:"Reconocer cuando el turn mejora la situación del rival.",
 189:"Reconocer un blank: una carta que casi no cambia nada.",
 190:"Reconocer una scare card: una carta que asusta a alguno de los dos.",
 191:"Entender el barrel: seguir apostando en el turn.",
 192:"Entender el double barrel y cuándo tiene sentido.",
 193:"Decidir pasar en el turn para controlar el bote.",
 194:"Decidir apostar el turn por valor o como segundo farol.",
 195:"Usar el pot control para no inflar el bote con manos medias.",
 196:"Distinguir los proyectos que siguen vivos en el turn.",
 197:"Ver cómo la equity de cada mano cambia con la carta del turn.",
 198:"Entender que en el river ya no hay más cartas: la mano está definida.",
 199:"Apostar por valor buscando el pago de manos peores.",
 200:"Reconocer un value fino: apostar una mano que gana justo.",
 201:"Farolear el river buscando que manos mejores foldeen.",
 202:"Decidir cuándo pagar el river como bluff catcher.",
 203:"Decidir pasar detrás en el river con una mano media.",
 204:"Ejecutar la línea check/fold: pasar y abandonar frente a una apuesta.",
 205:"Ejecutar la línea bet/fold: apostar y abandonar frente a una subida.",
 206:"Entender un rango polarizado: manos muy fuertes y faroles, poco en el medio.",
 207:"Definir tu rango de valor en el river.",
 208:"Definir tu rango de farol en el river.",
 209:"Antes de apostar, preguntarte qué manos peores te van a pagar.",
 210:"Antes de farolear, preguntarte qué manos mejores van a foldear.",
 211:"Usar cada acción del rival como información sobre su mano.",
 212:"Estimar cómo queda el rango del rival después de que abre.",
 213:"Estimar cómo queda el rango del rival después de que solo paga.",
 214:"Estimar cómo queda el rango del rival después de una 3-bet.",
 215:"Estimar cómo queda el rango del rival después de una c-bet.",
 216:"Estimar cómo queda el rango del rival después de un raise postflop.",
 217:"Estimar cómo queda el rango del rival después de un check.",
 218:"Ir descartando manos del rango del rival calle a calle.",
 219:"Contar cuántos combos de cada mano le quedan al rival.",
 220:"Leer la secuencia completa de acciones como una historia.",
 221:"Evaluar si esa historia es coherente con valor o con un farol.",
 222:"Reconocer cuándo la línea del rival representa valor.",
 223:"Reconocer cuándo la línea del rival representa un farol.",
 224:"Reconocer cuándo tu rango entero es más fuerte que el del rival.",
 225:"Reconocer cuándo tenés más manos muy fuertes (o su potencial) que el rival.",
 226:"Entender cómo la posición mejora cuánta de tu equity realizás.",
 227:"Entender la iniciativa: ser el que apostó último y lleva la agresión.",
 228:"Entender cómo la profundidad de stack cambia qué manos son jugables.",
 229:"Usar el SPR para saber si tu mano quiere jugar por todo el stack.",
 230:"Decidir cuándo polarizar tu propio rango de apuesta.",
 231:"Reconocer un rango condensado: muchas manos medias, pocas extremas.",
 232:"Usar tus propias cartas para descartar manos del rival (bloqueadores).",
 233:"Entender cómo remover combos cambia la probabilidad de cada mano rival.",
 234:"Entender la MDF de forma intuitiva: si foldeás de más, te farolean gratis.",
 235:"Entender la relación farol/valor que hace tu apuesta difícil de explotar.",
 236:"Empezar a pensar decisiones como frecuencias, no como blanco o negro.",
 237:"Distinguir jugar equilibrado de desviarse para castigar un error del rival.",
 238:"Ajustar tu estrategia a las tendencias concretas del rival.",
 239:"Entender qué es NL2: el nivel más bajo, lleno de jugadores que se equivocan.",
 240:"Entender por qué jugar 100 BB cambia qué manos son rentables.",
 241:"Entender el rake y por qué obliga a jugar más ajustado.",
 242:"Entender que en NL2 el dinero viene sobre todo de las manos fuertes bien jugadas.",
 243:"Evitar pagar apuestas grandes con manos que solo ganan a un farol.",
 244:"Evitar pagar de más con manos marginales fuera de posición.",
 245:"Evitar entrar en demasiadas manos: la disciplina preflop rinde.",
 246:"Aprender a detectar y castigar los errores típicos de NL2.",
 247:"Apostar más grande por valor porque en NL2 te pagan de más.",
 248:"Elegir bien los faroles: pocos, con lógica y con bloqueadores.",
 249:"Priorizar jugar manos en posición: es la ventaja más confiable.",
 250:"Sostener la disciplina preflop mano tras mano.",
 251:"Elegir bien qué manos jugar según posición y acción.",
 252:"Reconocer los spots donde el rival casi siempre se equivoca.",
 253:"Empezar toda decisión identificando tu posición.",
 254:"Identificar exactamente qué mano tenés.",
 255:"Reconstruir toda la acción que hubo antes de tu turno.",
 256:"Construir el rango probable del rival.",
 257:"Leer la textura del board.",
 258:"Clasificar qué mano hecha tenés ahora.",
 259:"Identificar qué proyectos tenés.",
 260:"Estimar tu equity contra el rango del rival.",
 261:"Calcular cuánto hay en el bote.",
 262:"Calcular cuánto te cuesta la decisión.",
 263:"Enumerar todas tus opciones (fold, call, raise…).",
 264:"Comparar el EV de cada opción.",
 265:"Sumar la información que aporta la última acción del rival.",
 266:"Anticipar cómo cambiaría todo si aparece cierta carta en la próxima calle.",
 267:"Elegir la acción con mejor EV.",
 268:"Revisar la mano después de jugarla.",
 269:"Juzgar la decisión por su calidad, no por si esa mano salió bien o mal.",
 270:"Corregir el error de jugar demasiadas manos.",
 271:"Corregir el error de entrar en manos fuera de posición sin razón.",
 272:"Corregir el error de pagar solo porque ya pusiste fichas (costo hundido).",
 273:"Corregir el error de pagar demasiado con manos marginales.",
 274:"Corregir el error de sobrevalorar el top pair en botes grandes.",
 275:"Corregir el error de no ver que estás dominado.",
 276:"Corregir el error de perseguir proyectos sin el precio correcto.",
 277:"Corregir el error de confundir la cantidad de outs con la equity real.",
 278:"Corregir el error de decidir sin pensar en el rango del rival.",
 279:"Corregir el error de mirar solo tus cartas y no el contexto.",
 280:"Corregir el error de ignorar lo que el board hace posible.",
 281:"Corregir el error de apostar sin un objetivo claro.",
 282:"Corregir el error de hacer c-bet en todos los flops sin pensar.",
 283:"Corregir el error de farolear sin mirar el rango del rival.",
 284:"Corregir el error de no apostar por valor cuando corresponde.",
 285:"Corregir el error de pagar el river solo por curiosidad.",
 286:"Reconocer el tilt y parar de decidir con la emoción.",
 287:"Dejar de medir tu juego por si ganaste la mano en vez de por la decisión.",
 288:"Integrar todo lo aprendido en una decisión de RFI completa.",
 289:"Integrar todo en la decisión de call/fold/3-bet frente a un open.",
 290:"Integrar todo en la defensa de la ciega grande.",
 291:"Integrar todo en la decisión de 3-betear.",
 292:"Integrar todo para jugar un bote 3-bet postflop.",
 293:"Integrar todo para jugar un bote single-raised postflop.",
 294:"Integrar todo en la decisión de c-betear el flop.",
 295:"Integrar todo en la decisión de pasar detrás en el flop.",
 296:"Integrar todo para jugar un proyecto en el flop.",
 297:"Integrar todo para jugar una mano hecha en el flop.",
 298:"Integrar todo en la decisión de segundo barrel en el turn.",
 299:"Integrar todo en la decisión de pasar en el turn.",
 300:"Integrar todo en la decisión de valor en el river.",
 301:"Integrar todo en la decisión de farol en el river.",
 302:"Integrar todo en la decisión de bluff catch en el river.",
 303:"Integrar todo en la decisión de ir o pagar un all-in.",
 304:"Tomar una decisión completa apoyándote en las pot odds.",
 305:"Tomar una decisión completa apoyándote en la equity.",
 306:"Tomar una decisión completa apoyándote en la lectura de rango.",
 307:"Tomar una decisión completa apoyándote en la posición.",
 308:"Tomar una decisión completa integrando todas las variables a la vez.",
 "TN01":"Reconocer un limp y entender por qué suele ser una jugada débil.",
 "TN02":"Decidir subir para aislar a un limper y jugar la mano en posición.",
 "TN03":"Elegir entre acompañar el limp o foldear según mano y posición.",
 "TN04":"Jugar el flop en un bote limpeado, donde nadie mostró fuerza.",
 "TN05":"Decidir entre foldear, pagar o subir cuando el rival te c-betea.",
 "TN06":"Pasar y subir con una mano fuerte para construir el bote.",
 "TN07":"Pasar y subir con un proyecto para ganar de dos formas.",
 "TN08":"Pagar una c-bet sin mano hecha, planeando llevarte el bote en el turn.",
 "TN09":"Apostar el turn cuando el agresor pasó, o el flop siendo el defensor.",
 "TN10":"Estimar lo que podés ganar en calles futuras si ligás tu proyecto.",
 "TN11":"Reconocer cuándo ligar tu mano igual te hace perder un bote grande.",
 "TN12":"Aceptar que con la mejor decisión igual vas a perder muchas manos.",
 "TN13":"Entender que parte del valor de una apuesta es que el rival foldee.",
 "TN14":"Leer un rango en la grilla 13×13 de todas las manos posibles.",
 "TN15":"Entender que no siempre cobrás toda tu equity: la posición ayuda a realizarla.",
 "TN16":"Jugar el enfrentamiento SB vs BB, con rangos anchos y fuera de posición.",
 "TN17":"3-betear sobre un open y un caller para llevarte el bote ahí mismo.",
 "TN18":"Ajustar la c-bet cuando hay 3 o más jugadores en el flop.",
}

# ------------------------------------------------------------------ #
# 3. ESTRUCTURA: niveles → subniveles → temas (en orden)
#    band: 1 FUNDAMENTAL · 2 BÁSICO · 3 INTERMEDIO · 4 AVANZADO
#    estadio: 1 RECONOCER · 2 ELEGIR · 3 DECIDIR · 4 EXPLICAR
# ------------------------------------------------------------------ #
LEVELS = [
 dict(n=1, name="Cómo funciona una mano",
   capability="Seguir una mano de Texas Hold'em de principio a fin: repartir, apostar, las 4 calles y cómo termina.",
   band=1, subs=[
     dict(code="1.1", name="El objetivo y las cartas", est=1, prq=[],
          obj="Entender qué se juega y con qué cartas.", items=[1,2,3,4,5]),
     dict(code="1.2", name="Ganar la mano", est=1, prq=["1.1"],
          obj="Saber que se gana por showdown o por fold.", items=[8,9,10]),
     dict(code="1.3", name="Las acciones", est=1, prq=["1.2"],
          obj="Conocer fold, check, call, bet, raise, all-in y cuándo se usa cada una.", items=[33,34,35,36,37,38,39,40,41,42]),
     dict(code="1.4", name="Las cuatro calles", est=1, prq=["1.3"],
          obj="Ordenar preflop → flop → turn → river → showdown.", items=[43,44,45,46,47,48,49]),
   ]),
 dict(n=2, name="Ranking de manos",
   capability="Nombrar cualquier mano y decir quién gana un showdown, incluidos los desempates.",
   band=1, subs=[
     dict(code="2.1", name="Las 10 categorías", est=1, prq=["1.2"],
          obj="Reconocer y ordenar las 10 categorías de manos.", items=[6,50,51,52,53,54,55,56,57,58,59]),
     dict(code="2.2", name="Comparar y desempatar", est=2, prq=["2.1"],
          obj="Comparar dos manos por categoría y, si empatan, por kicker.", items=[60,61,7,62,63]),
   ]),
 dict(n=3, name="La mesa: posiciones y dinero",
   capability="Decir en qué posición está, en qué orden se actúa y cuánto dinero hay en juego.",
   band=1, subs=[
     dict(code="3.1", name="La mesa 6-max y las 6 sillas", est=1, prq=["1.4"],
          obj="Reconocer las 6 posiciones de una mesa 6-max.", items=[11,12,13,14,15,16,17]),
     dict(code="3.2", name="El orden de acción", est=1, prq=["3.1"],
          obj="Saber quién habla antes y quién después, pre y postflop.", items=[18,19]),
     dict(code="3.3", name="Posición", est=1, prq=["3.2"],
          obj="Entender qué es estar en posición y fuera de posición.", items=[20,21,22]),
     dict(code="3.4", name="Fichas y stacks", est=1, prq=["1.3","3.1"],
          obj="Pensar en BB y entender el stack efectivo.", items=[23,24,25,32]),
     dict(code="3.5", name="El bote y las apuestas", est=1, prq=["3.4"],
          obj="Leer el bote y entender que cada decisión tiene un precio.", items=[26,27,28,29,30,31]),
   ]),
 dict(n=4, name="Leé tu mano y el board",
   capability="Clasificar su mano inicial, leer la textura del flop y ver qué proyectos y cartas peligrosas hay.",
   band=2, subs=[
     dict(code="4.1", name="Tipos de mano inicial", est=1, prq=["2.2","3.3"],
          obj="Clasificar tu mano inicial y aprender la notación (AKs, AKo, 77).", items=[64,65,66,67,68,69]),
     dict(code="4.2", name="Fuerza de la mano inicial", est=1, prq=["4.1"],
          obj="Ordenar tus manos iniciales de premium a especulativa.", items=[70,71,72,73,74]),
     dict(code="4.3", name="Texturas de board", est=1, prq=["4.1"],
          obj="Clasificar un flop como seco, coordinado, monótono, rainbow o pareado.", items=[75,76,77,78,79]),
     dict(code="4.4", name="Proyectos y cartas clave", est=1, prq=["4.3"],
          obj="Identificar proyectos y qué cartas del turn/river cambian la mano.", items=[80,81,82,83,84,85,86]),
     dict(code="4.5", name="Tu mano hecha en el flop", est=1, prq=["4.3","2.2"],
          obj="Leer la fuerza real de tu pareja, doble pareja, set o trips.", items=[87,88,89,90,91,92,93,94]),
     dict(code="4.6", name="Manos grandes y nuts", est=1, prq=["4.5"],
          obj="Reconocer escaleras, colores, fulls, los nuts y un bluff catcher.", items=[95,96,97,98,99,100]),
   ]),
 dict(n=5, name="Rangos y apertura",
   capability="Pensar en rangos y decidir qué abrir desde cada posición, con qué tamaño y por qué.",
   band=2, subs=[
     dict(code="5.1", name="Qué es un rango", est=1, prq=["4.2","4.6","3.3"],
          obj="Entender el rango como el conjunto de manos posibles y verlo en la grilla.", items=[128,129,130,131,132,133,"TN14"]),
     dict(code="5.2", name="Rangos en acción", est=2, prq=["5.1"],
          obj="Comparar rango vs mano y rango vs rango; entender rango percibido.", items=[134,135,136,137,138]),
     dict(code="5.3", name="La decisión de abrir (RFI)", est=2, prq=["5.2","3.3"],
          obj="Decidir abrir o foldear según si la mano entra en el rango de tu posición.", items=[139,140,141,152,153]),
     dict(code="5.4", name="El tamaño de apertura", est=2, prq=["5.3","3.5"],
          obj="Elegir un tamaño de apertura razonable (2–3 BB) y practicarlo.", items=[142,143,144,145]),
     dict(code="5.5", name="Rango de apertura por posición", est=2, prq=["5.3"],
          obj="Conocer el rango de apertura de cada silla, de UTG al BTN.", items=[146,147,148,149,150,151]),
     dict(code="5.6", name="Contra limpers / iso raise", est=2, prq=["5.5"],
          obj="Decidir qué hacer cuando alguien limpea antes que vos.", items=["TN01","TN02","TN03","TN04"]),
   ]),
 dict(n=6, name="La matemática de continuar",
   capability="Calcular si pagar sale a cuenta: outs, equity, pot odds, EV, implied odds.",
   band=3, subs=[
     dict(code="6.1", name="Outs", est=3, prq=["4.4","2.1"],
          obj="Contar los outs que de verdad te dan la mejor mano.", items=[101,102,103]),
     dict(code="6.2", name="Equity", est=3, prq=["6.1"],
          obj="Estimar tu equity contra una mano y contra un rango.", items=[104,105,106,107,110]),
     dict(code="6.3", name="Estimar rápido", est=3, prq=["6.2"],
          obj="Usar las reglas del 2 y del 4 para estimar equity en la mesa.", items=[108,109]),
     dict(code="6.4", name="El precio de continuar", est=3, prq=["3.5"],
          obj="Calcular cuánto te cuesta seguir y cuánto podés ganar.", items=[111,112,113,114]),
     dict(code="6.5", name="Pot odds", est=3, prq=["6.4","6.2"],
          obj="Comparar el precio con tu equity y sumar implied / reverse implied odds.", items=[115,116,117,118,119,"TN10","TN11"]),
     dict(code="6.6", name="EV", est=3, prq=["6.5"],
          obj="Entender el EV y aceptar la varianza a largo plazo.", items=[120,121,122,127,"TN12"]),
     dict(code="6.7", name="El EV de cada acción", est=3, prq=["6.6"],
          obj="Estimar el EV de pagar, foldear, apostar y farolear (fold equity).", items=[123,124,125,"TN13",126]),
   ]),
 dict(n=7, name="Guerra preflop: defensa y 3-bet",
   capability="Responder a un open (call/fold/3-bet), jugar un bote 3-bet y una 4-bet.",
   band=3, subs=[
     dict(code="7.1", name="¿Call o fold contra un open?", est=3, prq=["5.5","6.5"],
          obj="Decidir pagar o foldear un open según mano, posición y tamaño.", items=[154,155,156,162,163,"TN16"]),
     dict(code="7.2", name="3-bet: valor y farol", est=3, prq=["7.1","5.2"],
          obj="Decidir 3-betear por valor o como farol, y hacer squeeze.", items=[157,158,159,160,161,"TN17"]),
     dict(code="7.3", name="Anatomía del bote 3-bet", est=3, prq=["7.2"],
          obj="Leer un bote 3-bet: SPR, rangos y posición.", items=[164,165,166,167,168,169]),
     dict(code="7.4", name="Responder a una 3-bet / 4-bet", est=3, prq=["7.3"],
          obj="Decidir fold, call o 4-bet frente a una 3-bet.", items=[170,171,172,173,174]),
   ]),
 dict(n=8, name="El flop: c-bet",
   capability="Decidir si apostar el flop siendo el agresor — y qué hacer cuando no lo fue.",
   band=3, subs=[
     dict(code="8.1", name="La iniciativa y la c-bet", est=2, prq=["5.3","4.3","6.7"],
          obj="Entender qué es tener la iniciativa, qué es la c-bet y por qué funciona.", items=[227,175,176]),
     dict(code="8.2", name="C-bet por valor, farol y con proyecto", est=3, prq=["8.1"],
          obj="Elegir el tipo de c-bet según tu mano.", items=[177,178,179]),
     dict(code="8.3", name="C-bet según el board", est=3, prq=["8.2","4.3"],
          obj="Ajustar la c-bet al board y a los botes multiway.", items=[180,181,"TN18"]),
     dict(code="8.4", name="C-bet según la posición", est=3, prq=["8.2","3.3"],
          obj="Ajustar la c-bet a jugar en o fuera de posición.", items=[182,183]),
     dict(code="8.5", name="Frecuencia y tamaño", est=4, prq=["8.4"],
          obj="Elegir cuántas veces c-betear y con qué tamaño.", items=[184,185]),
     dict(code="8.6", name="Enfrentar una apuesta postflop", est=3, prq=["8.5","6.5"],
          obj="Decidir qué hacer cuando el rival apuesta: fold, call, raise, check-raise, float.", items=["TN05","TN06","TN07","TN08","TN09"]),
   ]),
 dict(n=9, name="Turn y river",
   capability="Seguir o frenar la agresión en el turn; jugar el river por valor, farol o bluff-catch.",
   band=4, subs=[
     dict(code="9.1", name="Reevaluar en el turn", est=3, prq=["8.6","6.2"],
          obj="Leer la carta del turn y qué cambia para cada uno.", items=[186,187,188,189,190,197]),
     dict(code="9.2", name="Barrel o pot control", est=3, prq=["9.1"],
          obj="Decidir entre seguir apostando el turn o controlar el bote.", items=[191,192,193,194,195,196]),
     dict(code="9.3", name="El river: valor", est=3, prq=["9.2"],
          obj="Apostar por valor y reconocer un value fino.", items=[198,199,200,209]),
     dict(code="9.4", name="El river: farol y bluff-catch", est=3, prq=["9.3","4.6"],
          obj="Farolear el river con lógica y decidir cuándo pagar como bluff catcher.", items=[201,202,210]),
     dict(code="9.5", name="Líneas de river y polarización", est=4, prq=["9.4"],
          obj="Elegir líneas de river y entender un rango polarizado.", items=[203,204,205,206,207,208]),
   ]),
 dict(n=10, name="Leer al rival",
   capability="Reconstruir el rango del rival por su línea y decir si representa valor o farol.",
   band=4, subs=[
     dict(code="10.1", name="Cada acción es información", est=3, prq=["5.2","7.4","9.5"],
          obj="Ver cómo cada acción del rival recorta su rango.", items=[211,212,213,216,217]),
     dict(code="10.2", name="Rango tras agresión", est=3, prq=["10.1"],
          obj="Leer el rango después de una 3-bet y una c-bet.", items=[214,215]),
     dict(code="10.3", name="Estrechar el rango", est=3, prq=["10.2"],
          obj="Ir descartando manos calle a calle y contar combos.", items=[218,219,220,221]),
     dict(code="10.4", name="¿Valor o farol?", est=4, prq=["10.3"],
          obj="Concluir si la línea del rival representa valor o farol.", items=[222,223]),
   ]),
 dict(n=11, name="Conceptos estratégicos",
   capability="Entender ventaja de rango/nuts/posición, iniciativa, SPR, bloqueadores y frecuencias.",
   band=4, subs=[
     dict(code="11.1", name="Ventajas", est=4, prq=["10.4","4.6"],
          obj="Reconocer ventaja de rango, de nuts y de posición, y entender la realización de equity.", items=[224,225,"TN15",226]),
     dict(code="11.2", name="Stacks y SPR", est=4, prq=["11.1","7.3"],
          obj="Usar la profundidad de stack y el SPR para decidir compromiso.", items=[228,229]),
     dict(code="11.3", name="Polarización y estructura de rango", est=4, prq=["11.2","9.5"],
          obj="Decidir cuándo polarizar y reconocer un rango condensado.", items=[230,231]),
     dict(code="11.4", name="Bloqueadores", est=4, prq=["11.3"],
          obj="Usar tus cartas para descartar manos del rival, con ejemplos concretos.", items=[232,233]),
     dict(code="11.5", name="Frecuencias y equilibrio", est=4, prq=["11.4"],
          obj="Entender la MDF de forma intuitiva y pensar en frecuencias.", items=[235,234,236]),
     dict(code="11.6", name="Explotar vs equilibrio", est=4, prq=["11.5"],
          obj="Distinguir jugar equilibrado de explotar un error del rival.", items=[237,238]),
   ]),
 dict(n=12, name="Integración y toma de decisiones",
   capability="Combinar todo lo aprendido en una sola decisión, siguiendo un checklist propio.",
   band=4, subs=[
     dict(code="12.1", name="El checklist — leer el spot", est=4, prq=["11.6"],
          obj="Leer un spot completo: posición, mano, acción, rango, board.", items=[253,254,255,256,257,258,259]),
     dict(code="12.2", name="El checklist — tomar la decisión", est=4, prq=["12.1"],
          obj="De la lectura a la acción: equity, precio, opciones, EV y revisión.", items=[260,261,262,263,264,265,266,267,268,269]),
     dict(code="12.3", name="Integrar el preflop", est=3, prq=["12.2","7.4"],
          obj="Resolver de punta a punta un RFI, una defensa, una 3-bet.", items=[288,289,290,291]),
     dict(code="12.4", name="Integrar el postflop", est=3, prq=["12.3","9.5"],
          obj="Resolver de punta a punta un bote 3-bet, un single-raised, una c-bet, un proyecto.", items=[292,293,294,295,296,297,298,299]),
   ]),
 dict(n=13, name="Dominio de NL2",
   capability="Sentarse en NL2 y tomar decisiones sólidas y consistentes en manos completas — el capstone.",
   band=4, subs=[
     dict(code="13.1", name="El entorno NL2", est=3, prq=["12.4"],
          obj="Entender NL2: 100 BB, rake y jugadores que se equivocan mucho.", items=[239,240,241]),
     dict(code="13.2", name="Cómo se gana en NL2", est=3, prq=["13.1"],
          obj="La receta de NL2: valor fuerte, disciplina, posición, faroles selectivos.", items=[242,243,244,245,246,247,248,249,250,251,252]),
     dict(code="13.3", name="Los 18 errores que cuestan fichas", est=4, prq=["13.2"],
          obj="Reconocer y corregir los 18 errores que separan a un ganador de un perdedor en NL2.", items=[270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287]),
     dict(code="13.4", name="Spots completos de river y all-in", est=3, prq=["13.3"],
          obj="Resolver manos completas de river y decisiones de all-in.", items=[300,301,302,303]),
     dict(code="13.5", name="La decisión integrada", est=4, prq=["13.4"],
          obj="Cerrar la Academia tomando decisiones completas que integran todo.", items=[304,305,306,307,308]),
   ]),
]

BAND_NAME = {1:"FUNDAMENTAL",2:"BÁSICO",3:"INTERMEDIO",4:"AVANZADO"}
EST_NAME  = {1:"RECONOCER",2:"ELEGIR",3:"DECIDIR",4:"EXPLICAR"}

# Prerrequisitos cruzados teoría→teoría (los que el usuario menciona explícitamente
# y otros que cruzan subniveles de forma no obvia)
EXTRA_PREREQ = {
 "T115":["T028","T030","T111"],          # pot odds necesita bote + apuesta + precio del call
 "T120":["T104","T111"],                 # EV necesita equity + precio
 "T126":["TN13"],                         # EV de un farol se apoya en fold equity  (ambos en 6.7)
 "T159":["T158","TN13"],                  # 3-bet bluff necesita 3-bet valor + fold equity
 "T175":["T137","T125"],                 # c-bet necesita rango de apertura + EV de apostar (iniciativa ya viene antes)
 "T202":["T100","T115"],                 # bluff catcher (uso) necesita su intro + pot odds
 "T234":["T235","T126"],                  # MDF intuitiva junto a farol/valor + EV de farol
 "T308":["T264","T304","T305","T306","T307"],
 "TN17":["T157","T155"],                  # squeeze necesita 3-bet + call preflop
 "TN10":["T115"],
 "TN11":["T073","T115"],                  # reverse implied odds ancla en mano dominada
 "TN15":["T106"],                          # realización de equity ancla en equity vs rango
 "TN18":["T180","T181"],
}

# Prerrequisitos que REEMPLAZAN por completo el cálculo automático para una
# teoría puntual (cuando "última teoría del subnivel previo" no es el ancla
# conceptual correcta). El camino visible sigue siendo lineal; esto solo
# afina el grafo interno.
PREREQ_OVERRIDE = {
 # 1.2 quedó ordenado T008→T009→T010, así que su "última teoría" es T010
 # ("ganar por fold"). Pero el ranking de manos se apoya en el SHOWDOWN
 # (comparar manos), no en ganar porque el rival se retira.
 "T006": ["T008"],
}
FORWARD_SOFT = set()

NON_MESA = {110,120,127,236,269,287,"TN12",241,"TN10","TN11"}  # conceptos abstractos / diagrama

# ------------------------------------------------------------------ #
# 3b. Conceptos clave por subnivel (solo ids que YA existen en concept_registry.dart;
#     el resto se crearán al redactar el contenido — PASO 4)
# ------------------------------------------------------------------ #
SUBCONCEPTS = {
 "1.1":[], "1.2":["rules"], "1.3":["rules"], "1.4":["rules"],
 "2.1":["hand_ranking"], "2.2":["hand_ranking"],
 "3.1":["position_names","position_blinds","position_utg","position_hj","position_co","position_btn"],
 "3.2":["position_names"], "3.3":["position_advantage"], "3.4":["rules"], "3.5":["rules"],
 "4.1":[], "4.2":[], "4.3":["board_texture"], "4.4":["board_texture"], "4.5":[], "4.6":[],
 "5.1":[], "5.2":[], "5.3":["opening_range","open_raise"], "5.4":["open_sizing"],
 "5.5":["opening_range","range_width"], "5.6":[],
 "6.1":["outs"], "6.2":["equity"], "6.3":["equity","outs"], "6.4":["pot_odds"],
 "6.5":["pot_odds"], "6.6":["ev"], "6.7":["ev"],
 "7.1":["bb_defense","call"], "7.2":["three_bet","three_bet_value","three_bet_bluff"],
 "7.3":[], "7.4":[],
 "8.1":["cbet"], "8.2":["cbet","value_bet","bluff"], "8.3":["cbet","board_texture"],
 "8.4":["cbet"], "8.5":["cbet"], "8.6":[],
 "9.1":[], "9.2":[], "9.3":["value_bet"], "9.4":["bluff","bluff_catcher"], "9.5":["polarization"],
 "10.1":[], "10.2":[], "10.3":["combos"], "10.4":[],
 "11.1":["range_advantage","nut_advantage","position_advantage","equity_realization"],
 "11.2":[], "11.3":["polarization"], "11.4":["blockers"], "11.5":[],
 "11.6":["gto","exploit","mixed_strategies"],
 "12.1":[], "12.2":["ev"], "12.3":[], "12.4":[],
 "13.1":[], "13.2":[], "13.3":[], "13.4":[], "13.5":[],
}

# ------------------------------------------------------------------ #
# 3c. Contenido heredado: qué asset de las 25 lecciones actuales cubre
#     (de forma interina) cada subnivel nuevo. Nada se borra; se re-ancla.
#     Claves: guiones de mesa / sets de ejercicios interactivos /
#     teoría en texto (academy_content) / practice specs / checks.
# ------------------------------------------------------------------ #
LEGACY = {
 # "1.1", "1.2", "1.3" y "1.4" (piloto Fase 3 del nuevo patrón de 3
 # bloques) ya NO heredan sus guiones/ejercicios legados. El guion "1.2" lo
 # siguen usando "3.4"/"3.5". Los guiones "1.1"/"1.3" y los sets "1.4"/"1.5"
 # quedaron sin re-anclar (ver el test de cobertura actualizado en
 # `curriculum_spec_test.dart`, que ya no los exige): con las 4 migradas al
 # piloto no queda ningún subnivel nuevo que necesite mostrar ese contenido
 # legado. Los ejemplos de mesa y ejercicios nuevos de 1.1/1.2/1.3/1.4 viven
 # aparte, en `AcademyClosingExamples`/`N1PilotExercises` (Dart puro, no
 # currículo).
 "2.1":{"table_scripts":["2.1"],"exercise_sets":["2.1","2.2"]},
 "2.2":{"exercise_sets":["2.3","2.4","2.5"]},
 "3.1":{"table_scripts":["3.1"],"exercise_sets":["3.1","3.2"]},
 "3.2":{"exercise_sets":["3.2"]},
 "3.3":{"table_scripts":["3.3"],"exercise_sets":["3.3","3.4"]},
 "3.4":{"table_scripts":["1.2"]},
 "3.5":{"table_scripts":["1.2"],"exercise_sets":["1.2","3.5"]},
 "5.1":{"table_scripts":["4.1"]},
 "5.2":{"table_scripts":["4.1"]},
 "5.3":{"table_scripts":["5.1"],"practice":["4.2","5.2"],"checks":["4.1","5.1"]},
 "5.4":{"text_theory":["5.3"]},
 "5.5":{"table_scripts":["5.1"],"practice":["4.4","4.5","5.5"],"text_theory":["4.3"]},
 "7.2":{"exercise_sets":["5.4"]},
}

EST_KIND = {"RECONOCER":"theory","ELEGIR":"basic","DECIDIR":"intermediate","EXPLICAR":"challenge"}

# ------------------------------------------------------------------ #
# 4. Construcción
# ------------------------------------------------------------------ #
def tid(ref):
    return ref if isinstance(ref, str) else "T%03d" % ref
def title(ref):
    return NEW[ref] if isinstance(ref, str) else T[ref]
def objective(ref):
    return OBJ[ref]

theories = []
order = 0
sub_last = {}   # subcode -> id de la última teoría del subnivel
sub_meta = {}
all_refs = []

for lvl in LEVELS:
    for s in lvl["subs"]:
        prev = None
        for ref in s["items"]:
            order += 1
            all_refs.append(ref)
            _id = tid(ref)
            prq = []
            for pc in s["prq"]:
                if pc in sub_last: prq.append(sub_last[pc])
            if prev: prq.append(prev)
            prq += EXTRA_PREREQ.get(_id, [])
            if _id in PREREQ_OVERRIDE:
                prq = list(PREREQ_OVERRIDE[_id])
            prq = sorted(set(prq))
            raw_cnt = CONTENT.get(_id)
            cnt = None
            if raw_cnt:
                cnt = {k: raw_cnt.get(k) for k in CONTENT_KEYS
                       if raw_cnt.get(k) is not None}
            theories.append(dict(
                id=_id,
                numero_curriculo=(ref if isinstance(ref,int) else None),
                es_nueva=isinstance(ref,str),
                titulo=title(ref),
                nivel=lvl["n"],
                nivel_nombre=lvl["name"],
                subnivel=s["code"],
                subnivel_nombre=s["name"],
                orden_global=order,
                dificultad=BAND_NAME[lvl["band"]],
                estadio=EST_NAME[s["est"]],
                objetivo=objective(ref),
                prerrequisitos=prq,
                teorias_relacionadas=[],
                conceptos_clave=list(SUBCONCEPTS.get(s["code"], [])),
                visualizacion_mesa=(ref not in NON_MESA),
                # --- contenido redactado (PASO 4, nivel por nivel) ---
                contenido=cnt,           # {que_es, por_que_importa, ...} o None
                pasos_mesa=None,         # lista de pasos (situación + burbuja) — opcional
                idea_clave=(cnt or {}).get("idea_clave"),
                estado_redaccion=("listo" if cnt else "pendiente"),
                ejercicios_relacionados=[],
            ))
            sub_last[s["code"]] = _id
            prev = _id
        # El PRIMER subnivel de cada nivel arranca en "teoría"; el ÚLTIMO
        # funciona además como checkpoint del nivel (kind=assessment): si se
        # completa por debajo del umbral, el nivel no queda aprobado y se
        # ofrece recuperación. En el medio, el kind sale del estadio.
        is_first = (s is lvl["subs"][0])
        is_last  = (s is lvl["subs"][-1])
        kind = "assessment" if is_last else ("theory" if is_first else EST_KIND[EST_NAME[s["est"]]])
        sub_meta[s["code"]] = dict(
            code=s["code"], nombre=s["name"], nivel=lvl["n"],
            objetivo=s["obj"], estadio=EST_NAME[s["est"]],
            kind=kind,
            es_checkpoint=is_last,
            dificultad=BAND_NAME[lvl["band"]],
            prerrequisitos=s["prq"], n_teorias=len(s["items"]),
            conceptos_clave=list(SUBCONCEPTS.get(s["code"], [])),
            legacy=LEGACY.get(s["code"]),
        )

# teorias_relacionadas = hermanas del subnivel
bysub = collections.defaultdict(list)
for t in theories: bysub[t["subnivel"]].append(t["id"])
for t in theories:
    t["teorias_relacionadas"] = [x for x in bysub[t["subnivel"]] if x != t["id"]]
# partner del bluff catcher
for t in theories:
    if t["id"]=="T100": t["teorias_relacionadas"].append("T202")
    if t["id"]=="T202": t["teorias_relacionadas"].append("T100")

spec = dict(
    meta=dict(
        proyecto="Floply · Academia",
        version="estructura-definitiva-v2",
        generado_por="tool/curriculum/gen_curriculum.py. Desde aquí, este JSON es la fuente de verdad.",
        total_teorias=len(theories),
        teorias_originales=sum(1 for t in theories if not t["es_nueva"]),
        teorias_nuevas=sum(1 for t in theories if t["es_nueva"]),
        niveles=len(LEVELS),
        subniveles=len(sub_meta),
        unlock_mode="linear",
        unlock_modes_soportados=["linear","prerequisites"],
        estadios_cognitivos=["RECONOCER","ELEGIR","DECIDIR","EXPLICAR"],
        bandas_dificultad=["FUNDAMENTAL","BASICO","INTERMEDIO","AVANZADO"],
    ),
    niveles=[dict(n=l["n"], nombre=l["name"], capacidad=l["capability"],
                  dificultad=BAND_NAME[l["band"]],
                  subniveles=[sub_meta[s["code"]] for s in l["subs"]]) for l in LEVELS],
    teorias=theories,
)

# Rutas de salida: si el script vive en <repo>/tool/curriculum, escribe
# directo a assets/ y lib/; si no (scratchpad), escribe al cwd.
_HERE = os.path.dirname(os.path.abspath(__file__))
_REPO = os.path.abspath(os.path.join(_HERE, "..", ".."))
def _dest(rel_repo, fallback):
    d = os.path.join(_REPO, rel_repo)
    return d if os.path.isdir(os.path.dirname(d)) and \
        os.path.basename(_HERE) == "curriculum" else fallback
JSON_OUT = _dest("assets/curriculum/curriculum_spec.json", "curriculum_spec.json")
GDART_OUT = _dest("lib/engine/pedagogy/curriculum_spec_data.g.dart",
                  "curriculum_spec_data.g.dart")

out = JSON_OUT
with open(out,"w",encoding="utf-8") as f:
    json.dump(spec, f, ensure_ascii=False, indent=1)

# ------------------------------------------------------------------ #
# 5. VALIDACIÓN
# ------------------------------------------------------------------ #
print("="*64)
print("VALIDACIÓN DE LA ESTRUCTURA DEFINITIVA")
print("="*64)
errors=[]; warns=[]

# 5a. cobertura de los 308
orig = sorted(r for r in all_refs if isinstance(r,int))
if orig != list(range(1,309)):
    missing = set(range(1,309))-set(orig); dup=[x for x,c in collections.Counter(orig).items() if c>1]
    errors.append(f"cobertura 308: faltan {sorted(missing)} · duplicados {dup}")
else:
    print(f"[OK] los 308 temas originales aparecen exactamente una vez")

newrefs=[r for r in all_refs if isinstance(r,str)]
if sorted(newrefs)!=sorted(NEW): errors.append(f"teorías nuevas: {set(NEW)^set(newrefs)}")
else: print(f"[OK] las {len(NEW)} teorías nuevas aprobadas están todas ubicadas una vez")

# 5b. ids únicos
ids=[t["id"] for t in theories]
if len(ids)!=len(set(ids)): errors.append("ids duplicados")
else: print(f"[OK] {len(ids)} ids únicos ({spec['meta']['teorias_originales']} orig + {spec['meta']['teorias_nuevas']} nuevas = {len(ids)})")

# 5c. prereqs existen y no apuntan hacia adelante
pos={t["id"]:t["orden_global"] for t in theories}
fwd=0
for t in theories:
    for p in t["prerrequisitos"]:
        if p not in pos: errors.append(f"{t['id']} prereq inexistente {p}")
        elif pos[p] >= t["orden_global"]:
            if (t["id"],p) in FORWARD_SOFT: warns.append(f"forward-soft permitido: {t['id']} ← {p} (adelanto de idea)")
            else: fwd+=1; errors.append(f"{t['id']} ({pos[t['id']]}) tiene prereq POSTERIOR {p} ({pos[p]})")
if fwd==0: print("[OK] ningún prerrequisito apunta hacia adelante (DAG lineal-compatible)")

# 5d. dificultad monótona por nivel
prevband=0
for l in spec["niveles"]:
    b={"FUNDAMENTAL":1,"BÁSICO":2,"INTERMEDIO":3,"AVANZADO":4}[l["dificultad"]]
    if b<prevband: errors.append(f"N{l['n']} baja de dificultad")
    prevband=max(prevband,b)
print(f"[OK] curva de dificultad: {' → '.join(l['dificultad'][:4] for l in spec['niveles'])}")

# 5e. vocabulario antes de uso (chequeo de términos clave)
VOCAB={
 "equity":("T104",[105,106,107,116,117,197,224,226,260,305,"TN15"]),
 "pot odds":("T115",[304]),
 "rango":("T128",list(range(129,163))+[167,168,207,208,212,306]),
 "SPR":("T166",[229]),
 "blocker/bloqueador":("T232",[248,302,"TN07"]),
 "polarización":("T206",[230]),
 "fold equity":("TN13",[126,159,178,201,301]),
 "implied odds":("TN10",[276]),
 "MDF":("T234",[236]),
 "realización de equity":("TN15",[226,244]),
}
for term,(defid,users) in VOCAB.items():
    dp=pos.get(defid)
    bad=[u for u in users if pos.get(tid(u),1e9)<dp]
    if bad: warns.append(f"vocab '{term}': se usa en {[tid(u) for u in bad]} antes de definirse en {defid}")
print("[OK] chequeo de vocabulario clave: definición antes del primer uso")

# 5g. conceptos_clave existen en concept_registry.dart · legacy apunta a lecciones reales
KNOWN_CONCEPTS = {
 "rules","hand_ranking","position_names","position_btn","position_co","position_hj",
 "position_utg","position_blinds","position_advantage","opening_range","open_raise",
 "open_sizing","range_width","bb_defense","call","three_bet","three_bet_value",
 "three_bet_bluff","pot_odds","equity","outs","combos","ev","equity_realization",
 "range_advantage","nut_advantage","cbet","board_texture","value_bet","bluff",
 "bluff_catcher","blockers","overbet","polarization","gto","mixed_strategies","exploit",
}
OLD_LESSONS = {f"{a}.{b}" for a in range(1,6) for b in range(1,6)}
for t in theories:
    for c in t["conceptos_clave"]:
        if c not in KNOWN_CONCEPTS: errors.append(f"{t['id']} concepto_clave desconocido: {c}")
for sc,lg in [(s["code"],s.get("legacy")) for l in LEVELS for s in l["subs"]]:
    if not lg: continue
    for kind,ids in lg.items():
        for i in ids:
            if i not in OLD_LESSONS: errors.append(f"legacy {sc}.{kind}: '{i}' no es una lección actual")
print("[OK] conceptos_clave válidos · legacy apunta a lecciones 1.1–5.5 reales")

# 5h. contenido redactado (PASO 4): consistencia estado_redaccion ↔ contenido
written = [t for t in theories if t["contenido"]]
for t in written:
    c = t["contenido"]
    if t["estado_redaccion"] != "listo":
        errors.append(f"{t['id']} tiene contenido pero estado '{t['estado_redaccion']}'")
    faltan = [k for k in ("que_es", "idea_clave") if not c.get(k)]
    if faltan:
        errors.append(f"{t['id']} contenido sin {faltan}")
    huerf = set(c) - set(CONTENT_KEYS)
    if huerf:
        errors.append(f"{t['id']} contenido con claves desconocidas {huerf}")
by_lvl_written = collections.Counter(t["nivel"] for t in written)
print(f"[OK] contenido redactado: {len(written)}/{len(theories)} teorías  "
      + " ".join(f"N{n}={by_lvl_written[n]}" for n in sorted(by_lvl_written)))

# 5f. N12 y N13 con identidad propia
n12=[t for t in theories if t["nivel"]==12]; n13=[t for t in theories if t["nivel"]==13]
print(f"[OK] N12 'Integración' = {len(n12)} teorías (checklist + integrar pre/postflop)")
print(f"[OK] N13 'Dominio de NL2' = {len(n13)} teorías (entorno + receta NL2 + 18 errores + capstone)")

print("-"*64)
print(f"totales: {len(theories)} teorías · {len(LEVELS)} niveles · {len(sub_meta)} subniveles")
sizes=[len([t for t in theories if t['nivel']==l['n']]) for l in LEVELS]
print("por nivel:", " ".join(f"N{i+1}={s}" for i,s in enumerate(sizes)), f"(suma {sum(sizes)})")
print("-"*64)
if warns:
    print(f"\n{len(warns)} AVISOS (esperados / a resolver con nota interna):")
    for w in warns: print("  ·", w)
if errors:
    print(f"\n{len(errors)} ERRORES:")
    for e in errors: print("  ✗", e)
    sys.exit(1)
print("\n>>> ESTRUCTURA VÁLIDA. Escrita en", out)

# ------------------------------------------------------------------ #
# 6. Fragmento HTML del árbol de niveles (para el artefacto)
# ------------------------------------------------------------------ #
import html as _h
DIFF_CLS={"FUNDAMENTAL":"f","BÁSICO":"b","INTERMEDIO":"i","AVANZADO":"a"}
def esc(s): return _h.escape(str(s))
frag=[]
for l in spec["niveles"]:
    lts=[t for t in theories if t["nivel"]==l["n"]]
    nnew=sum(1 for t in lts if t["es_nueva"])
    frag.append(f'''<details class="lvl"{" open" if l["n"]==1 else ""}>
  <summary>
    <span class="lvl-badge">N{l["n"]}</span>
    <span><span class="lvl-title">{esc(l["nombre"])}</span><span class="lvl-q">"{esc(l["capacidad"])}"</span></span>
    <span class="lvl-meta">{esc(l["dificultad"])}<br>{len(lts)} teorías{" · +"+str(nnew)+" nuevas" if nnew else ""} · {len(l["subniveles"])} subniveles</span>
  </summary>
  <div class="lvl-body">''')
    for s in l["subniveles"]:
        sts=[t for t in theories if t["subnivel"]==s["code"]]
        dc=DIFF_CLS[s["dificultad"]]
        chips=[]
        for t in sts:
            cls="t"+(" split" if t["es_nueva"] else "")
            num = t["id"][1:].lstrip("0") if not t["es_nueva"] else "N"
            lbl = ("nueva · " if t["es_nueva"] else "")+esc(t["titulo"])
            chips.append(f'<span class="{cls}"><b>{num if not t["es_nueva"] else "nueva"}</b>{esc(t["titulo"])}</span>')
        frag.append(f'''    <div class="sn"><div class="sn-h"><span class="id">{s["code"]}</span><span class="nm">{esc(s["nombre"])}</span><span class="diff {dc}">{esc(s["dificultad"].capitalize())}</span> <span class="diff">{esc(s["estadio"])}</span></div>
      <div class="sn-note">{esc(s["objetivo"])}  ·  prereq: {esc(", ".join(s["prerrequisitos"]) or "—")}</div>
      <div class="topics">{"".join(chips)}</div>
    </div>''')
    frag.append("  </div>\n</details>")
open("tree_fragment.html","w",encoding="utf-8").write("\n".join(frag))
print(">>> tree_fragment.html escrito (", len("\n".join(frag)), "bytes )")

# resumen por nivel para la tabla de la sección 5
rows=[]
for l in spec["niveles"]:
    lts=[t for t in theories if t["nivel"]==l["n"]]
    rows.append(f'N{l["n"]}\t{l["nombre"]}\t{l["dificultad"]}\t{len(lts)}')
open("niveles_resumen.tsv","w",encoding="utf-8").write("\n".join(rows))

# ------------------------------------------------------------------ #
# 7. Codegen Dart:  curriculum_spec_data.g.dart  (const, sync)
#    El JSON sigue siendo la fuente de verdad; este archivo se regenera
#    con  dart run tool/gen_curriculum_data.dart  (o este script).
# ------------------------------------------------------------------ #
def dq(s):
    if s is None: return "null"
    return "'" + str(s).replace("\\","\\\\").replace("'","\\'").replace("\n","\\n") + "'"
def dlist(xs): return "[" + ", ".join(dq(x) for x in xs) + "]"

# contenido redactado → mapa const Dart con claves camelCase (las del modelo
# TheoryContent). Se omiten los campos ausentes.
_CONTENT_CAMEL = {
 "que_es":"queEs","por_que_importa":"porQueImporta","como_funciona":"comoFunciona",
 "cuando_lo_uso":"cuandoLoUso","cuando_no":"cuandoNo","ejemplo":"ejemplo",
 "error_comun":"errorComun","idea_clave":"ideaClave",
}
def dcontent(d):
    if not d: return "null"
    parts = [f"{dq(_CONTENT_CAMEL[k])}: {dq(v)}"
             for k, v in d.items() if v is not None]
    return "{" + ", ".join(parts) + "}"

lines=[]
lines.append("// GENERADO por tool/curriculum/gen_curriculum.py — NO editar a mano.")
lines.append("// Fuente de verdad: assets/curriculum/curriculum_spec.json")
lines.append("// Regenerar tras cambiar el JSON.")
lines.append("//")
lines.append("// ignore_for_file: lines_longer_than_80_chars, prefer_single_quotes")
lines.append("")
lines.append("const Map<String, Object?> kCurriculumSpecMeta = {")
for k,v in spec["meta"].items():
    if isinstance(v,list): lines.append(f"  {dq(k)}: {dlist(v)},")
    elif isinstance(v,int): lines.append(f"  {dq(k)}: {v},")
    else: lines.append(f"  {dq(k)}: {dq(v)},")
lines.append("};")
lines.append("")
lines.append("const List<Map<String, Object?>> kCurriculumLevels = [")
for l in spec["niveles"]:
    lines.append("  {")
    lines.append(f"    'n': {l['n']}, 'nombre': {dq(l['nombre'])}, 'capacidad': {dq(l['capacidad'])}, 'dificultad': {dq(l['dificultad'])},")
    lines.append("    'subniveles': [")
    for s in l["subniveles"]:
        lg = s.get("legacy")
        lgs = "null"
        if lg:
            parts=[f"{dq(k)}: {dlist(v)}" for k,v in lg.items()]
            lgs = "{" + ", ".join(parts) + "}"
        lines.append("      {")
        lines.append(f"        'code': {dq(s['code'])}, 'nombre': {dq(s['nombre'])}, 'nivel': {s['nivel']},")
        lines.append(f"        'objetivo': {dq(s['objetivo'])}, 'estadio': {dq(s['estadio'])}, 'kind': {dq(s['kind'])}, 'dificultad': {dq(s['dificultad'])},")
        lines.append(f"        'esCheckpoint': {str(s.get('es_checkpoint', False)).lower()},")
        lines.append(f"        'prerrequisitos': {dlist(s['prerrequisitos'])}, 'conceptosClave': {dlist(s['conceptos_clave'])},")
        lines.append(f"        'legacy': {lgs},")
        lines.append("      },")
    lines.append("    ],")
    lines.append("  },")
lines.append("];")
lines.append("")
lines.append("const List<Map<String, Object?>> kCurriculumTheories = [")
for t in theories:
    nc = "null" if t["numero_curriculo"] is None else str(t["numero_curriculo"])
    lines.append("  {")
    lines.append(f"    'id': {dq(t['id'])}, 'numeroCurriculo': {nc}, 'esNueva': {str(t['es_nueva']).lower()},")
    lines.append(f"    'titulo': {dq(t['titulo'])}, 'nivel': {t['nivel']}, 'subnivel': {dq(t['subnivel'])},")
    lines.append(f"    'ordenGlobal': {t['orden_global']}, 'dificultad': {dq(t['dificultad'])}, 'estadio': {dq(t['estadio'])},")
    lines.append(f"    'objetivo': {dq(t['objetivo'])}, 'visualizacionMesa': {str(t['visualizacion_mesa']).lower()},")
    lines.append(f"    'prerrequisitos': {dlist(t['prerrequisitos'])}, 'teoriasRelacionadas': {dlist(t['teorias_relacionadas'])},")
    lines.append(f"    'conceptosClave': {dlist(t['conceptos_clave'])}, 'estadoRedaccion': {dq(t['estado_redaccion'])},")
    lines.append(f"    'contenido': {dcontent(t.get('contenido'))},")
    lines.append("  },")
lines.append("];")
lines.append("")
open(GDART_OUT,"w",encoding="utf-8").write("\n".join(lines))
print(">>> curriculum_spec_data.g.dart escrito (", len("\n".join(lines)), "bytes,", len(theories), "teorías )")
print("    JSON ->", out)
print("    Dart ->", GDART_OUT)
