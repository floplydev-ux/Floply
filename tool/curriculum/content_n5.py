# -*- coding: utf-8 -*-
"""
PASO 4 — Contenido redactado del NIVEL 5: "Rangos y apertura".
31 teorías, 6 subniveles. Banda BÁSICO, estadios RECONOCER (5.1) y ELEGIR
(5.2 a 5.6). Voz: un buen profesor a alguien que empieza a leer situaciones.
Completo, no largo. Español rioplatense (vos / tenés).

Fuente de verdad: curriculum_spec.json (IDs, títulos, objetivos, orden y
prerrequisitos no se tocan acá).

Meta de N5: pasar de "leer una mano puntual" (N4) a "pensar en conjuntos de
manos". El alumno sale de N5 sabiendo qué es un rango, cómo se ve (grilla
13×13), cómo contar combos, y sobre todo: con qué manos abrir desde cada
posición, con qué tamaño, y qué hacer frente a un limper.

Vocabulario nuevo de N5: rango, rango fuerte/débil/amplio/estrecho, combos,
grilla 13×13, rango de apertura, rango de defensa, rango percibido, RFI
(raise first in), tamaño de apertura (2x/2.5x/3x), limp, isolation raise
(iso raise), overlimpear, bote limpeado.

NO se enseña todavía (llega en niveles posteriores): outs, equity, la regla
del 2/4, pot odds, valor esperado (EV), 3-bet, c-bet, blockers, MDF. Cuando
una teoría necesita comparar "qué mano gana más seguido", se dice en
lenguaje llano ("le gana a más manos", "está mejor parado") sin usar el
término técnico equity, que se define recién en el nivel siguiente.
"""

N5 = {

# ============================================================
# 5.1 — Qué es un rango
# ============================================================

"T128": dict(  # Qué es un rango
 que_es="Un rango es el conjunto de TODAS las manos que un jugador podría "
        "tener en una situación concreta — no una mano puntual, sino todas "
        "las combinaciones posibles a la vez.",
 por_que_importa="Nunca sabés qué dos cartas tiene el rival. Pero sí podés "
        "razonar sobre qué manos son compatibles con lo que hizo: su "
        "posición, sus acciones, el momento de la mano. Pensar en rangos es "
        "la forma real de jugar contra la incertidumbre, en vez de "
        "adivinar una mano exacta.",
 como_funciona="En vez de preguntarte '¿qué tiene?', preguntate '¿qué "
        "podría tener acá?'. La respuesta casi nunca es una mano: es un "
        "grupo. Ese grupo es su rango en ese momento.",
 cuando_lo_uso="Cada vez que un rival actúa: pensás en el conjunto de manos "
        "compatible con esa acción, no en una mano específica.",
 cuando_no=None,
 ejemplo="Un rival sube desde el botón. No sabés si tiene A♠A♦ o 7♠6♠: "
        "sabés que su rango de apertura desde esa posición incluye docenas "
        "de manos distintas, desde las más fuertes hasta algunas "
        "especulativas.",
 error_comun="Intentar 'leer' una mano exacta ('seguro tiene ases') en vez "
        "de razonar con un conjunto. Casi nunca vas a acertar la mano "
        "puntual; sí podés acotar bien el rango.",
 idea_clave="Rango = todas las manos posibles en una situación, no una "
        "mano adivinada.",
),

"T129": dict(  # Un rango fuerte
 que_es="Un rango fuerte es un rango compuesto mayormente por manos de "
        "valor: parejas altas, broadways bien acompañadas, combinaciones "
        "que le ganan a la mayoría de las manos posibles.",
 por_que_importa="Si sabés que el rango del rival es fuerte, jugar contra "
        "él es distinto: hay menos lugar para faroles baratos y más manos "
        "que de verdad te pueden ganar.",
 como_funciona="Mirá qué tan seguido, dentro de ese conjunto de manos, hay "
        "combinaciones que pegan fuerte con el board o que ya eran fuertes "
        "de entrada. Cuantas más, más fuerte el rango.",
 cuando_lo_uso="Al evaluar una situación donde el rival mostró mucha "
        "fuerza (por ejemplo, subió desde muy temprano en la mesa).",
 cuando_no=None,
 ejemplo="Alguien sube desde UTG (el primero en hablar). Ahí, casi nadie "
        "sube con cualquier cosa: su rango tiende a ser fuerte, con más "
        "manos premium que en otras posiciones.",
 error_comun="Suponer que un rango fuerte significa 'siempre tiene una "
        "mano ganadora'. Sigue siendo un conjunto: la mayoría son buenas, "
        "pero no todas ganan siempre.",
 idea_clave="Rango fuerte = predominan las manos de valor sobre las "
        "marginales.",
),

"T130": dict(  # Un rango débil
 que_es="Un rango débil es un rango con muchas manos marginales: cartas "
        "que no son gran cosa por sí solas, y donde también entran más "
        "faroles.",
 por_que_importa="Contra un rango débil, tu mano media alcanza más seguido "
        "para estar bien parado. Reconocerlo te ayuda a no regalarle "
        "respeto a una acción que no lo merece.",
 como_funciona="Un rango se vuelve débil cuando el jugador puede entrar con "
        "casi cualquier cosa en esa situación: no hay mucho filtro, así que "
        "el conjunto incluye bastante material flojo.",
 cuando_lo_uso="Al evaluar situaciones donde el rival tiene poco motivo "
        "para ser selectivo (por ejemplo, defendiendo su ciega grande "
        "barata).",
 cuando_no=None,
 ejemplo="Alguien defiende su ciega grande pagando una subida chica: ahí "
        "entra casi cualquier mano jugable, no solo las fuertes. Es un "
        "rango débil comparado con el de quien abrió.",
 error_comun="Confundir 'rango débil' con 'mano débil garantizada'. Sigue "
        "siendo un conjunto: incluye basura, pero también algunas manos "
        "buenas.",
 idea_clave="Rango débil = predominan las manos marginales y los faroles "
        "posibles.",
),

"T131": dict(  # Un rango amplio
 que_es="Un rango amplio (o 'wide') es un rango con MUCHAS combinaciones "
        "distintas de manos — cuenta cantidad, no calidad.",
 por_que_importa="Amplio y fuerte no son lo mismo. Un rango puede ser "
        "amplio y a la vez incluir manos flojas: lo que importa acá es "
        "cuántas combinaciones entran, no qué tan buenas son en promedio.",
 como_funciona="Contá cuántas manos distintas caben en ese conjunto. "
        "Cuantas más entran, más amplio el rango.",
 cuando_lo_uso="Al describir la cantidad de manos con las que alguien "
        "juega en una situación, sin todavía opinar sobre su calidad.",
 cuando_no=None,
 ejemplo="Desde el botón, un jugador agresivo puede abrir con la mitad de "
        "todas las manos posibles: un rango bien amplio, aunque adentro "
        "haya manos bastante flojas.",
 error_comun="Usar 'amplio' como sinónimo de 'fuerte'. Un rango puede ser "
        "amplio y débil a la vez — de hecho, es lo más común.",
 idea_clave="Amplio = muchas combinaciones. Es una medida de cantidad, no "
        "de calidad.",
),

"T132": dict(  # Un rango estrecho
 que_es="Un rango estrecho (o 'tight' o 'narrow') es un rango con POCAS "
        "combinaciones — otra vez, cantidad, no calidad.",
 por_que_importa="Un rango estrecho suele ser (aunque no siempre) también "
        "fuerte: si alguien es muy selectivo, lo poco que juega tiende a "
        "ser bueno.",
 como_funciona="Contá cuántas manos entran. Si son pocas, el rango es "
        "estrecho. Preguntate aparte si además son fuertes.",
 cuando_lo_uso="Al describir situaciones donde el jugador filtra mucho qué "
        "manos juega (por ejemplo, subir desde la posición más temprana de "
        "la mesa).",
 cuando_no=None,
 ejemplo="Desde UTG, un jugador disciplinado sube con muy pocas manos "
        "distintas: un rango estrecho. Como además suelen ser las mejores "
        "manos, ahí sí coincide con ser fuerte.",
 error_comun="Pensar que estrecho siempre implica fuerte. Alguien puede "
        "tener un rango estrecho de manos raras y flojas si juega mal — es "
        "poco común, pero conceptualmente son cosas distintas.",
 idea_clave="Estrecho = pocas combinaciones. Suele venir acompañado de "
        "fuerza, pero son dos ideas separadas.",
),

"T133": dict(  # Combos
 que_es="Un combo es una combinación concreta de dos cartas exactas. "
        "'A♠A♦' es un combo; 'AA' (la clase 'par de ases') agrupa varios "
        "combos: A♠A♦, A♠A♣, A♠A♥, A♦A♣, A♦A♥, A♣A♥ — seis en total.",
 por_que_importa="Contar combos te dice cuánto pesa cada clase de mano "
        "dentro de un rango. No todas las clases tienen la misma cantidad: "
        "eso cambia cuánto lugar ocupa cada una.",
 como_funciona="Una pareja (como AA) tiene 6 combos. Una mano no pareja "
        "suited (como AKs) tiene 4 combos. La misma mano offsuit (AKo) "
        "tiene 12 combos — el triple, porque hay más formas de combinar "
        "palos distintos que iguales.",
 cuando_lo_uso="Al pensar cuánto pesa una clase de mano dentro de un "
        "rango completo (por ejemplo, para saber si 'AA' es una porción "
        "chica o grande del total).",
 cuando_no=None,
 ejemplo="'AK' como clase representa 16 combos en total: 4 suited (AKs) + "
        "12 offsuit (AKo). Comparado con los 6 combos de 'AA', hay casi "
        "tres veces más formas de tener AK que de tener AA.",
 error_comun="Tratar todas las 'clases' de mano como si pesaran lo mismo "
        "dentro de un rango. Las parejas pesan menos (6 combos) que las "
        "manos no pareadas (16 combos entre suited y offsuit).",
 idea_clave="Combo = combinación exacta de cartas. Las parejas tienen 6, "
        "las no pareadas 16 (4 suited + 12 offsuit).",
),

"TN14": dict(  # Cómo se ve un rango (la grilla 13×13)
 que_es="La grilla 13×13 es la forma estándar de dibujar un rango: un "
        "cuadrado de 13 filas y 13 columnas, una por cada valor de carta "
        "(de 2 a As), con 169 casilleros — uno por cada clase de mano "
        "inicial posible.",
 por_que_importa="Te da una forma visual de ver de un vistazo qué tan "
        "amplio o estrecho es un rango, y qué tipo de manos incluye, sin "
        "tener que leer una lista de nombres.",
 como_funciona="La diagonal (de arriba-izquierda a abajo-derecha) son las "
        "parejas. Arriba de la diagonal van las manos suited. Abajo de la "
        "diagonal, las mismas combinaciones pero offsuit. Un rango se "
        "'pinta' marcando qué casilleros entran.",
 cuando_lo_uso="Para visualizar o comunicar un rango completo de forma "
        "rápida, en vez de enumerar manos una por una.",
 cuando_no=None,
 ejemplo="Si pintás toda la fila y columna del As, más la diagonal "
        "completa, estás marcando: todas las manos con As, más todas las "
        "parejas. Un vistazo a la grilla te dice eso al instante.",
 error_comun="Mirar la grilla y pensar que las 169 casillas pesan lo "
        "mismo. La diagonal (parejas) representa menos combos reales por "
        "casillero que el resto — ver T133.",
 idea_clave="La grilla 13×13: diagonal = parejas, arriba = suited, "
        "abajo = offsuit. Forma visual estándar de mostrar un rango.",
),

# ============================================================
# 5.2 — Rangos en acción
# ============================================================

"T134": dict(  # Rango contra mano
 que_es="Comparar tu mano concreta contra todo el rango del rival: no "
        "contra una mano suya imaginada, sino contra el conjunto entero "
        "de manos que podría tener ahí.",
 por_que_importa="Es la comparación real que importa en la mesa. Vos sí "
        "sabés tu mano exacta; del rival solo tenés el rango. Comparar tu "
        "mano puntual contra ese conjunto completo es lo correcto — "
        "comparar contra una sola mano imaginada del rival, no.",
 como_funciona="Preguntate: de todo lo que el rival podría tener en esta "
        "situación, ¿mi mano está mejor parada que la mayoría, o peor?",
 cuando_lo_uso="Cada vez que evalúes tu mano frente a la acción de un "
        "rival: siempre contra su rango completo, no contra una mano "
        "puntual.",
 cuando_no=None,
 ejemplo="Tenés K♠Q♠ y el rival sube desde el botón. No comparás tu K-Q "
        "contra 'lo que él probablemente tiene' (una mano imaginada): la "
        "comparás contra TODO su rango de apertura de esa posición, que "
        "incluye manos mejores y peores que la tuya.",
 error_comun="Jugar como si el rival tuviera una mano específica en la "
        "cabeza ('seguro tiene AK') en vez de pensar en su rango completo.",
 idea_clave="Tu mano se compara contra el rango entero del rival, no "
        "contra una mano imaginada.",
),

"T135": dict(  # Rango contra rango
 que_es="Comparar dos rangos completos entre sí — el tuyo contra el del "
        "rival — en vez de una mano puntual contra un rango.",
 por_que_importa="A veces ni siquiera tenés una mano decidida todavía (por "
        "ejemplo, estás pensando con qué manos jugar en general desde una "
        "posición): ahí comparás conjunto contra conjunto.",
 como_funciona="Pensá los dos rangos lado a lado: ¿el mío tiene, en "
        "promedio, mejores manos que el suyo, o peores? Esto es más "
        "abstracto que comparar una mano puntual, pero es la base para "
        "decidir con qué manos jugar en general.",
 cuando_lo_uso="Al diseñar o pensar con qué manos abrir o defender desde "
        "una posición, antes de tener una mano específica en las manos.",
 cuando_no=None,
 ejemplo="El rango de apertura del botón contra el rango de defensa de la "
        "ciega grande: en promedio el del botón suele estar mejor parado, "
        "porque el de la ciega grande es más amplio y más flojo por "
        "necesidad.",
 error_comun="Confundir esta comparación (conjunto contra conjunto) con "
        "T134 (mano puntual contra rango). Son dos preguntas distintas.",
 idea_clave="Rango contra rango = comparar dos conjuntos completos, no "
        "una mano puntual contra un conjunto.",
),

"T136": dict(  # El rango percibido
 que_es="El rango percibido es lo que el rival CREE que vos tenés, "
        "basado en tu posición y tus acciones — no necesariamente lo que "
        "de verdad tenés.",
 por_que_importa="Tus rivales toman decisiones según lo que creen que "
        "tenés, no según tu mano real. Entender eso te ayuda a leer por "
        "qué actúan como actúan, y también a saber qué imagen estás "
        "proyectando vos.",
 como_funciona="Ponete en el lugar del rival: con la información que él "
        "tiene (tu posición, lo que hiciste), ¿qué rango le parece "
        "razonable que tengas? Eso es tu rango percibido desde su punto "
        "de vista.",
 cuando_lo_uso="Al pensar por qué un rival actuó de determinada manera "
        "frente a vos, o al anticipar cómo va a reaccionar a tu próxima "
        "jugada.",
 cuando_no=None,
 ejemplo="Subís desde UTG. El rival no ve tus cartas, pero sabe que desde "
        "ahí casi nadie sube con manos flojas: tu rango percibido, para "
        "él, es fuerte — aunque tu mano real sea, esa vez, más floja de "
        "lo habitual.",
 error_comun="Olvidar que el rival juega contra tu rango percibido, no "
        "contra tu mano real. Eso explica reacciones que, si solo pensás "
        "en tu mano concreta, no tienen sentido.",
 idea_clave="Rango percibido = lo que el rival cree que tenés, según tu "
        "posición y tus acciones.",
),

"T137": dict(  # El rango de apertura
 que_es="El rango de apertura es el conjunto de manos con las que subís "
        "cuando sos el primero en entrar voluntariamente a la mano — "
        "nadie subió ni entró antes que vos.",
 por_que_importa="Es el rango más importante para empezar a construir "
        "una estrategia sólida: define, para cada posición, con qué "
        "manos arrancás la pelea por el bote.",
 como_funciona="Cada posición tiene su propio rango de apertura, y suelen "
        "ir de más estrecho a más amplio a medida que actuás más tarde en "
        "la mesa (esto se desarrolla en 5.5).",
 cuando_lo_uso="Cada vez que la acción llega a vos y nadie entró todavía: "
        "consultás tu rango de apertura para esa posición.",
 cuando_no=None,
 ejemplo="Estás en el botón y todos los que actuaron antes se retiraron. "
        "Con K♠J♦, una mano que entra en tu rango de apertura del botón, "
        "subís.",
 error_comun="Usar el mismo rango de apertura sin importar la posición. "
        "Una mano que abrís sin problema desde el botón puede no entrar "
        "en tu rango desde UTG.",
 idea_clave="Rango de apertura = con qué manos subís siendo el primero en "
        "entrar, desde una posición dada.",
),

"T138": dict(  # El rango de defensa
 que_es="El rango de defensa es el conjunto de manos con las que seguís "
        "en la mano (pagando o resubiendo) frente a la subida de otro "
        "jugador, en vez de retirarte.",
 por_que_importa="No solo importa con qué manos abrís vos: también con "
        "qué manos respondés cuando el que actúa primero ya subió. Es la "
        "otra mitad de jugar bien preflop.",
 como_funciona="Cuando alguien sube antes que vos, comparás tu mano "
        "contra el rango de apertura de esa persona (T134) para decidir "
        "si tu mano entra en tu rango de defensa contra esa subida "
        "concreta.",
 cuando_lo_uso="Cada vez que alguien sube antes de que te toque actuar: "
        "consultás tu rango de defensa frente a esa subida.",
 cuando_no=None,
 ejemplo="Alguien sube desde UTG (rango estrecho y fuerte). Tu rango de "
        "defensa contra esa subida es más ajustado que si hubiera subido "
        "desde el botón, porque el rango al que te enfrentás es más "
        "fuerte.",
 error_comun="Defender con el mismo rango sin importar quién subió ni "
        "desde dónde. El rango de defensa correcto depende del rango de "
        "apertura al que te enfrentás.",
 idea_clave="Rango de defensa = con qué manos seguís frente a una subida "
        "ajena, en vez de foldear.",
),

# ============================================================
# 5.3 — La decisión de abrir (RFI)
# ============================================================

"T139": dict(  # Qué es el RFI (raise first in)
 que_es="RFI son las siglas de 'raise first in': subir siendo el primero "
        "en poner dinero de más en el bote — nadie limpeó ni subió antes "
        "que vos en esa mano.",
 por_que_importa="Es el nombre técnico de lo que ya veías en T137 (el "
        "rango de apertura): tener un término preciso te permite hablar "
        "de esta situación sin confundirla con defender o resubir.",
 como_funciona="Si la acción llega a vos limpia (todos foldearon o falta "
        "tu turno) y decidís subir, eso es un RFI. Tu rango de apertura es "
        "'tu rango de RFI'.",
 cuando_lo_uso="Para nombrar con precisión la situación de 'ser el "
        "primero en subir', y distinguirla de subir después de que alguien "
        "más ya hizo algo.",
 cuando_no=None,
 ejemplo="UTG, HJ y CO se retiran. Sos el botón y nadie más entró: si "
        "subís acá, es un RFI. Si en cambio alguien ya había subido antes "
        "y vos resubís, eso NO es un RFI — es otra jugada, que se ve más "
        "adelante en la Academia.",
 error_comun="Llamar 'RFI' a cualquier subida, incluso cuando ya había "
        "alguien que actuó antes que vos. RFI es específicamente ser el "
        "primero en subir.",
 idea_clave="RFI = raise first in = subir siendo el primero en entrar a "
        "la mano con una subida.",
),

"T140": dict(  # Abrir una mano
 que_es="Abrir una mano es la acción concreta de hacer RFI con una mano "
        "que entra en tu rango de apertura para esa posición.",
 por_que_importa="Es donde la teoría (tener un rango definido) se "
        "convierte en una decisión real, mano por mano, en la mesa.",
 como_funciona="Mirás tus dos cartas, mirás tu posición, y consultás: "
        "¿esta mano está en mi rango de apertura acá? Si sí, subís.",
 cuando_lo_uso="Cada vez que te toca actuar primero (nadie entró antes) y "
        "tenés una mano jugable para esa posición.",
 cuando_no=None,
 ejemplo="Estás en el CO con A♠J♠. Esa mano entra cómodo en el rango de "
        "apertura del CO: la abrís, subiendo el tamaño estándar de la "
        "mesa.",
 error_comun="Abrir 'porque tocaba jugar algo', sin chequear si la mano "
        "realmente entra en el rango de esa posición.",
 idea_clave="Abrir una mano = hacer RFI con una mano que sí entra en tu "
        "rango para esa posición.",
),

"T141": dict(  # Foldear preflop
 que_es="Foldear preflop es retirarte de la mano antes de ver el flop, "
        "cuando tu mano no entra en tu rango para esa situación.",
 por_que_importa="La mayoría de las manos que recibís, la mayoría de las "
        "veces, no van a entrar en tu rango. Foldear seguido y sin drama "
        "es una parte enorme de jugar bien — no un fracaso.",
 como_funciona="Si tu mano no está en tu rango de apertura (siendo el "
        "primero en actuar) ni en tu rango de defensa (si alguien ya "
        "subió), la decisión correcta es retirarte, sin gastar fichas de "
        "más.",
 cuando_lo_uso="Cada vez que tu mano no entra en el rango correspondiente "
        "a la situación.",
 cuando_no=None,
 ejemplo="Estás en UTG con 7♠2♦, la peor mano inicial posible. No entra "
        "ni remotamente en tu rango de apertura desde ahí: foldeás sin "
        "pensarlo dos veces.",
 error_comun="Sentir que 'foldear mucho' es jugar mal. Es al revés: un "
        "jugador sólido foldea la mayoría de sus manos, porque la mayoría "
        "de las manos, la mayoría de las veces, no entran en ningún "
        "rango razonable.",
 idea_clave="Foldear preflop = retirarte porque tu mano no entra en tu "
        "rango para esa situación. Es lo más frecuente, no un error.",
),

"T152": dict(  # La posición define el rango
 que_es="Cuanto más tarde actuás en la mesa, más ancho puede ser tu "
        "rango de apertura — porque tenés menos jugadores por detrás que "
        "puedan sorprenderte con una mano mejor.",
 por_que_importa="Esta es la razón concreta por la que UTG abre poco y el "
        "botón abre mucho: no es una regla arbitraria, es consecuencia "
        "directa de cuánta gente queda por actuar después de vos.",
 como_funciona="Desde UTG, quedan cinco jugadores por hablar detrás: "
        "cualquiera de ellos puede tener algo mejor, así que conviene ser "
        "selectivo. Desde el botón, solo quedan las ciegas: mucho menos "
        "riesgo de que alguien tenga algo mejor esperándote.",
 cuando_lo_uso="Para entender POR QUÉ los rangos de apertura cambian "
        "según la posición, antes de memorizar los rangos concretos "
        "(eso viene en 5.5).",
 cuando_no=None,
 ejemplo="Con K♣9♣, foldear desde UTG y abrir desde el botón no es "
        "inconsistencia: es la misma lógica aplicada a dos situaciones "
        "distintas, porque la cantidad de gente por detrás cambió.",
 error_comun="Pensar en 'mi rango' como algo fijo, sin importar la "
        "posición. El rango correcto cambia con la posición porque el "
        "riesgo de tener gente mejor por detrás también cambia.",
 idea_clave="Menos jugadores por detrás = menos riesgo = rango más "
        "amplio. Por eso la posición define el rango.",
),

"T153": dict(  # El rango cambia según la acción previa
 que_es="Tu rango correcto no depende solo de tu posición: también "
        "depende de lo que ya hicieron los demás antes de que te toque "
        "actuar.",
 por_que_importa="El rango de apertura (T137) solo aplica cuando nadie "
        "entró antes que vos. En cuanto alguien limpea o sube, la "
        "situación cambió y tu rango correcto también cambia — ya no "
        "estás abriendo, estás respondiendo.",
 como_funciona="Antes de consultar tu rango, primero mirá qué pasó: "
        "¿llegó limpio a vos? Usás tu rango de apertura. ¿Alguien ya "
        "actuó? Usás el rango que corresponde a esa situación específica "
        "(defensa, o las que se ven en 5.6 contra un limper).",
 cuando_lo_uso="Cada vez, antes de decidir: primero identificás qué pasó "
        "antes que vos, después consultás el rango que corresponde a esa "
        "situación exacta.",
 cuando_no=None,
 ejemplo="Con Q♠J♠ en el CO: si llega limpio a vos, abrís sin problema. "
        "Si en cambio alguien ya subió desde UTG antes que vos, la "
        "decisión es otra — tu rango frente a ESA subida, no tu rango de "
        "apertura.",
 error_comun="Aplicar tu rango de apertura como si nada hubiera pasado, "
        "incluso cuando alguien ya actuó antes que vos.",
 idea_clave="Antes de mirar tu rango, mirá qué pasó antes: el rango "
        "correcto depende de la situación, no solo de la posición.",
),

# ============================================================
# 5.4 — El tamaño de apertura
# ============================================================

"T142": dict(  # El tamaño de apertura
 que_es="El tamaño de apertura es cuánto subís cuando hacés RFI, medido "
        "en BB (ciegas grandes). En mesas 6-max con stacks de 100 BB, el "
        "tamaño estándar ronda las 2 a 3 BB.",
 por_que_importa="Subir muy poco le da a los demás un precio barato para "
        "seguir con cualquier cosa; subir demasiado arriesga fichas de "
        "más sin necesidad. El tamaño estándar busca el punto justo.",
 como_funciona="2 a 3 BB es el rango habitual de referencia. Dentro de "
        "eso, el tamaño exacto varía según la posición y el estilo de la "
        "mesa — eso se ve en las próximas tres teorías.",
 cuando_lo_uso="Cada vez que decidís hacer RFI: además de qué mano, "
        "definís cuánto subir.",
 cuando_no=None,
 ejemplo="Con ciegas de 0.5/1 BB, un tamaño de apertura de 2.5 BB "
        "significa subir a 2.5 fichas, dentro del rango estándar para "
        "esa mesa.",
 error_comun="Subir tamaños muy distintos sin un motivo claro (a veces "
        "1.5 BB, a veces 5 BB) según el humor del momento, en vez de un "
        "tamaño consistente.",
 idea_clave="Tamaño de apertura estándar en 6-max: 2 a 3 BB.",
),

"T143": dict(  # Abrir a 2x
 que_es="Abrir a 2x significa subir a exactamente 2 BB al hacer RFI — el "
        "extremo más chico del rango estándar.",
 por_que_importa="Es un tamaño eficiente: arriesgás poco por adelantado y "
        "mantenés el bote más chico si te pagan, lo cual reduce el riesgo "
        "cuando abrís un rango bien amplio.",
 como_funciona="Se usa sobre todo en mesas donde subir un poco ya alcanza "
        "para que los rivales flojos se retiren, o cuando tu propio "
        "rango de apertura es muy amplio y preferís no arriesgar de más "
        "con cada mano.",
 cuando_lo_uso="En mesas donde un tamaño chico ya cumple su función, o "
        "como parte de un estilo consistente de aperturas ajustadas.",
 cuando_no="Si tus rivales pagan (limpean) fácil sin importar el tamaño, "
        "2x les da un precio demasiado barato para seguir con cualquier "
        "cosa — ahí conviene subir el tamaño.",
 ejemplo="Con ciegas 0.5/1, abrir a 2 BB total.",
 error_comun="Usar 2x en una mesa donde varios rivales limpean cualquier "
        "cosa sin importar el tamaño — ahí ese tamaño no cumple su "
        "función de filtrar.",
 idea_clave="2x = el tamaño de apertura más chico del rango estándar. "
        "Eficiente, pero exige que la mesa lo respete.",
),

"T144": dict(  # Abrir a 2.5x
 que_es="Abrir a 2.5x significa subir a 2.5 BB al hacer RFI — el tamaño "
        "más usado como referencia general en 6-max.",
 por_que_importa="Es el punto intermedio que suele funcionar bien contra "
        "la mayoría de las mesas: ni tan chico que invite a cualquiera a "
        "seguir, ni tan grande que arriesgue fichas de más.",
 como_funciona="Si no tenés un motivo puntual para ir más chico o más "
        "grande, 2.5x es el tamaño por defecto razonable para empezar.",
 cuando_lo_uso="Como tamaño estándar general, salvo que algo concreto de "
        "la mesa (rivales que pagan todo, o que se retiran fácil) "
        "sugiera ajustarlo.",
 cuando_no=None,
 ejemplo="Con ciegas 0.5/1, abrir a 2.5 BB total — el tamaño de "
        "referencia por defecto.",
 error_comun="Buscar un tamaño 'perfecto' distinto para cada mano sin "
        "tener un motivo concreto. 2.5x como default resuelve bien la "
        "mayoría de las situaciones sin tener que pensarlo de cero cada "
        "vez.",
 idea_clave="2.5x = el tamaño de apertura de referencia si no tenés un "
        "motivo puntual para ir más chico o más grande.",
),

"T145": dict(  # Abrir a 3x
 que_es="Abrir a 3x significa subir a 3 BB al hacer RFI — el extremo más "
        "grande del rango estándar.",
 por_que_importa="Un tamaño más grande cobra más caro seguir la mano: "
        "sirve para desalentar a rivales que pagan cualquier cosa, o para "
        "construir un bote más grande cuando tu rango en esa posición es "
        "más fuerte y angosto.",
 como_funciona="Se usa sobre todo desde posiciones tempranas (donde tu "
        "rango ya es más fuerte de por sí) o contra rivales que limpean "
        "demasiado seguido sin importar el tamaño.",
 cuando_lo_uso="Cuando querés cobrarle más caro a los rivales que pagan "
        "cualquier cosa, o cuando abrís un rango angosto y fuerte y "
        "buscás un bote más grande.",
 cuando_no="Si tu rango en esa posición ya es amplio (por ejemplo desde "
        "el botón), subir a 3x en cada apertura arriesga fichas de más "
        "en manos que no lo justifican.",
 ejemplo="Con ciegas 0.5/1, abrir a 3 BB total — más caro para quien "
        "quiera seguir.",
 error_comun="Abrir siempre a 3x sin importar la posición, incluso desde "
        "el botón con un rango amplio, donde ese tamaño arriesga de más "
        "en manos marginales.",
 idea_clave="3x = tamaño más grande del rango estándar. Cobra más caro "
        "seguir; conviene con rangos angostos o contra rivales que pagan "
        "todo.",
),

# ============================================================
# 5.5 — Rango de apertura por posición
# ============================================================

"T146": dict(  # Rango de apertura de UTG
 que_es="El rango de apertura de UTG es el más cerrado de toda la mesa: "
        "solo entran las manos más fuertes.",
 por_que_importa="UTG es la primera posición en hablar: quedan cinco "
        "jugadores por detrás que todavía no actuaron. Cualquiera de "
        "ellos puede tener una mano mejor, así que conviene abrir solo "
        "con lo más sólido.",
 como_funciona="Pensá en parejas altas y medias, broadways bien "
        "acompañados (como AK, AQ, KQ) y algunas manos especulativas "
        "fuertes. Fuera de eso, foldeás.",
 cuando_lo_uso="Cada vez que te toca actuar primero desde UTG y nadie "
        "entró antes.",
 cuando_no=None,
 ejemplo="Con J♠T♠ en UTG: es una mano jugable desde posiciones más "
        "tardías, pero queda afuera del rango angosto de UTG — foldeás.",
 error_comun="Abrir desde UTG con el mismo tipo de manos que abrirías "
        "desde el botón. Es la posición donde más selectivo tenés que "
        "ser.",
 idea_clave="UTG = el rango más angosto de la mesa. Solo lo más fuerte.",
),

"T147": dict(  # Rango de apertura del HJ
 que_es="El rango de apertura del hijack (HJ) es un poco más ancho que "
        "el de UTG: sigue habiendo jugadores por detrás, pero menos que "
        "desde UTG.",
 por_que_importa="Cada posición que ganás hacia el botón te permite "
        "ampliar un poco el rango, porque baja el riesgo de que alguien "
        "detrás tenga algo mejor. El HJ es el primer paso de esa "
        "ampliación gradual.",
 como_funciona="Al rango de UTG le sumás algunas manos más: broadways más "
        "flojos, parejas medias-bajas, algunas manos especulativas "
        "adicionales.",
 cuando_lo_uso="Cada vez que te toca actuar primero desde el HJ y nadie "
        "entró antes.",
 cuando_no=None,
 ejemplo="Con K♠T♦, una mano que quedaba afuera del rango de UTG, ya "
        "entra en el rango de apertura del HJ.",
 error_comun="Usar exactamente el mismo rango que en UTG, ignorando que "
        "hay un jugador menos por detrás.",
 idea_clave="HJ = un poco más ancho que UTG. Un jugador menos por detrás, "
        "un poco menos de riesgo.",
),

"T148": dict(  # Rango de apertura del CO
 que_es="El rango de apertura del cutoff (CO) es ancho: entran bastantes "
        "más manos que desde el HJ.",
 por_que_importa="Desde el CO ya casi no quedan jugadores por detrás: "
        "solo el botón y las dos ciegas, tres en total. El riesgo de "
        "encontrarte con algo mejor bajó bastante, y eso se refleja en un "
        "rango más generoso.",
 como_funciona="Al rango del HJ le sumás manos conectadas, suited más "
        "bajas, y algunas broadways adicionales que todavía no entraban.",
 cuando_lo_uso="Cada vez que te toca actuar primero desde el CO y nadie "
        "entró antes.",
 cuando_no=None,
 ejemplo="Con Q♣9♣, floja para UTG o HJ, ya es una apertura razonable "
        "desde el CO.",
 error_comun="Jugar el CO con la misma prudencia que UTG, dejando pasar "
        "aperturas rentables solo por costumbre.",
 idea_clave="CO = rango ancho. Solo tres jugadores por detrás: el botón "
        "y las dos ciegas.",
),

"T149": dict(  # Rango de apertura del BTN
 que_es="El rango de apertura del botón (BTN) es el más ancho de toda la "
        "mesa: entra la mayor cantidad de manos distintas de las seis "
        "posiciones.",
 por_que_importa="El botón es la última posición 'de mesa' en actuar "
        "preflop — después de él solo faltan hablar las dos ciegas — y "
        "además va a estar EN posición durante el resto de la mano: actúa "
        "último en todas las rondas siguientes (flop, turn, river). Eso "
        "vale mucho: podés abrir bastante más ancho y seguir bien parado.",
 como_funciona="Al rango del CO le sumás bastante más: conectores más "
        "bajos, suited variadas, broadways sueltas. Solo quedan las "
        "ciegas por detrás, y jugás con la ventaja de la posición en "
        "todas las calles siguientes.",
 cuando_lo_uso="Cada vez que te toca actuar primero desde el botón y "
        "nadie entró antes.",
 cuando_no=None,
 ejemplo="Con 8♠6♠, floja para casi cualquier otra posición, es una "
        "apertura razonable desde el botón: pocos rivales por detrás y "
        "jugás en posición el resto de la mano.",
 error_comun="Abrir desde el botón con el mismo rango ajustado que "
        "usarías desde UTG, desaprovechando la mejor posición de la "
        "mesa.",
 idea_clave="BTN = el rango más ancho de la mesa. Menos rivales por "
        "detrás, y jugás en posición el resto de la mano.",
),

"T150": dict(  # Rango de apertura de la SB
 que_es="El rango de apertura de la ciega chica (SB) se juega distinto a "
        "las demás posiciones: para cuando le toca abrir, ya se retiraron "
        "todos los de mesa y solo falta hablar la ciega grande — pero en "
        "todas las rondas siguientes (flop, turn, river) la SB va a ser "
        "la primera en actuar, fuera de posición el resto de la mano.",
 por_que_importa="Tener posición o no importa mucho más allá de "
        "preflop: la SB abre con menos manos que el botón, a pesar de "
        "tener casi la misma cantidad de rivales por detrás, porque paga "
        "el costo de estar fuera de posición toda la mano.",
 como_funciona="El rango de la SB suele quedar entre el del CO y el del "
        "botón en amplitud: más ancho que posiciones tempranas, pero sin "
        "llegar a la amplitud del botón, por el costo de jugar fuera de "
        "posición después.",
 cuando_lo_uso="Cada vez que te toca actuar primero desde la SB (todos "
        "se retiraron o falta tu turno) y nadie entró todavía.",
 cuando_no=None,
 ejemplo="Con A♦8♦, una mano que abrirías sin dudar desde el botón, "
        "puede ser una decisión más cercana desde la SB: la mano es la "
        "misma, pero vas a jugar el resto de la mano fuera de posición.",
 error_comun="Copiar el rango del botón en la SB solo porque el número "
        "de rivales por detrás es parecido, ignorando el costo de estar "
        "fuera de posición después.",
 idea_clave="SB = más angosto que el botón, aunque haya pocos rivales "
        "por detrás, porque después juega fuera de posición.",
),

"T151": dict(  # La BB no abre
 que_es="La ciega grande (BB) nunca hace RFI: para cuando le toca actuar, "
        "o ya pusieron dinero antes que ella (alguien limpeó o subió), o "
        "la mano ya terminó (todos se retiraron y se lleva las ciegas "
        "sin jugar).",
 por_que_importa="Entender esto evita un error de vocabulario y de "
        "lectura: la BB tiene otras decisiones (defender, subir frente a "
        "un limper, pagar), pero 'abrir' específicamente no es una de "
        "ellas.",
 como_funciona="'Abrir' significa ser el primero en poner dinero extra "
        "voluntariamente. La BB ya puso una ciega obligatoria; para "
        "cuando le toca decidir algo, la mano dejó de estar 'limpia' (ya "
        "sea porque alguien actuó, o porque terminó).",
 cuando_lo_uso="Para no confundir las opciones reales de la BB (check, "
        "defender, subir frente a un limper) con un RFI, que ahí no "
        "existe.",
 cuando_no=None,
 ejemplo="Todos se retiran hasta la BB: la mano termina ahí, la BB se "
        "lleva el bote sin jugar — no 'abrió', simplemente ganó por "
        "default. Si en cambio alguien limpea antes, la BB puede subir "
        "para aislarlo — eso tampoco es RFI, se ve en 5.6.",
 error_comun="Hablar del 'rango de apertura de la BB' como si existiera "
        "igual que en las demás posiciones. La BB tiene un rango de "
        "defensa y de reacción frente a limpers, pero no un rango de "
        "RFI.",
 idea_clave="La BB no hace RFI: para cuando actúa, la mano ya no está "
        "'limpia'.",
),

# ============================================================
# 5.6 — Contra limpers / iso raise
# ============================================================

"TN01": dict(  # Qué es un limp
 que_es="Un limp es pagar la ciega grande sin subir, siendo el primero en "
        "entrar al bote — en vez de retirarte o abrir con una subida.",
 por_que_importa="Es, en general, una jugada débil: le da a todos los que "
        "vienen atrás un precio barato para ver el flop con cualquier "
        "mano, sin ganar nada a cambio (no presionás a nadie a "
        "retirarse).",
 como_funciona="En vez de subir o foldear siendo el primero en entrar, el "
        "jugador iguala la ciega grande y deja pasar la acción sin "
        "presionar.",
 cuando_lo_uso="Para reconocer esta jugada cuando la ves en la mesa, y "
        "entender por qué en general no es la mejor opción para vos.",
 cuando_no=None,
 ejemplo="Con ciegas 0.5/1, un jugador en el CO simplemente iguala 1 BB "
        "en vez de subir a 2.5 BB: eso es un limp.",
 error_comun="Limpear con manos especulativas pensando que es 'jugar "
        "barato y con cuidado'. En realidad suele regalar la iniciativa "
        "sin necesidad: si la mano es buena para jugar, casi siempre es "
        "mejor subir que limpear.",
 idea_clave="Limp = pagar la ciega grande sin subir, siendo el primero en "
        "entrar. En general, una jugada débil.",
),

"TN02": dict(  # El isolation raise
 que_es="El isolation raise (o 'iso raise') es subir después de que un "
        "rival limpeó, con la intención de aislarlo: sacar del medio a los "
        "demás y jugar la mano en ventaja, mano a mano contra el "
        "limper.",
 por_que_importa="Contra un limper (jugada débil, TN01) subir es "
        "castigarlo: le sacás su bote barato y multijugador, y lo obligás "
        "a jugar una mano más grande contra vos, en posición.",
 como_funciona="En vez de solo igualar el limp o foldear, subís por "
        "encima del limp — un tamaño más grande que tu apertura normal, "
        "para desalentar a los demás jugadores de seguir y quedar mano a "
        "mano contra el limper.",
 cuando_lo_uso="Cuando alguien limpea antes que vos y tu mano es lo "
        "bastante buena como para querer jugarla en ventaja, en vez de "
        "solo acompañar.",
 cuando_no="Con una mano que no aguanta una pelea más grande, o cuando ya "
        "hay varios limpers y aislar a todos se vuelve poco realista.",
 ejemplo="Un jugador limpea desde el HJ. Vos, en el botón, con A♠Q♠, "
        "subís por encima de ese limp para aislarlo: querés jugar tu "
        "buena mano contra una sola mano floja, no contra un bote "
        "multijugador.",
 error_comun="Solo igualar el limp con una mano fuerte, en vez de "
        "aprovechar para aislar y jugar en ventaja.",
 idea_clave="Iso raise = subir sobre un limp para aislar al limper y "
        "jugar en ventaja.",
),

"TN03": dict(  # Overlimpear o foldear
 que_es="Cuando ya hay un limper antes que vos y tu mano no es lo "
        "bastante fuerte como para aislar (TN02), tus opciones reales son "
        "overlimpear (acompañar el limp con tu propia mano) o foldear.",
 por_que_importa="No toda mano que 'entra' frente a un limp amerita "
        "subir. Reconocer cuándo conviene simplemente acompañar (o "
        "directamente retirarte) evita forzar subidas con manos que no "
        "las justifican.",
 como_funciona="Overlimpear tiene más sentido con manos especulativas que "
        "ganan mucho si conectan fuerte pero no aguantan bien una pelea "
        "grande (por ejemplo, conectores bajos suited). Con el resto, "
        "foldear.",
 cuando_lo_uso="Frente a un limp, cuando tu mano no entra en tu rango de "
        "iso raise pero tampoco es una mano para tirar sin más.",
 cuando_no=None,
 ejemplo="Con 6♠5♠ frente a un limp: no es mano para un iso raise grande, "
        "pero sí puede valer la pena overlimpear barato, buscando conectar "
        "algo fuerte en el flop.",
 error_comun="Overlimpear con cualquier mano marginal, incluidas manos "
        "que ni siquiera tienen buen potencial si conectan.",
 idea_clave="Frente a un limp: si no alcanza para aislar, la elección es "
        "overlimpear (con potencial real) o foldear — no forzar una "
        "subida grande.",
),

"TN04": dict(  # Jugar un bote limpeado
 que_es="Un bote limpeado es un bote que llegó al flop sin ninguna "
        "subida: uno o más jugadores solo igualaron la ciega grande, "
        "nadie mostró fuerza todavía.",
 por_que_importa="Se juega distinto a un bote donde alguien subió: el "
        "bote suele ser más chico, hay más jugadores repartiéndose las "
        "posibilidades, y nadie llegó con una mano 'anunciada' como "
        "fuerte.",
 como_funciona="Como nadie mostró fuerza preflop, el flop es más parejo "
        "que en un bote donde alguien subió: cualquiera de los que "
        "limpearon puede haber conectado bien o mal, sin pistas previas.",
 cuando_lo_uso="Al llegar a un flop donde la mano llegó por limps, sin "
        "ninguna subida preflop.",
 cuando_no=None,
 ejemplo="Tres jugadores limpearon y viste el flop gratis desde la BB: "
        "en ese bote, nadie llegó con una historia de fuerza previa — "
        "vas a tener que leer la mano principalmente por lo que pasa a "
        "partir del flop.",
 error_comun="Jugar un bote limpeado como si alguien ya hubiera mostrado "
        "fuerza, cuando en realidad nadie subió y la información previa "
        "es mínima.",
 idea_clave="Bote limpeado = llegó al flop sin subidas. Bote chico, "
        "varios jugadores, sin fuerza anunciada todavía.",
),

}
