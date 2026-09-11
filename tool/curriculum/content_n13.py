# -*- coding: utf-8 -*-
"""
PASO 4 — Contenido redactado del NIVEL 13: "Dominio de NL2" (capstone).
41 teorías, 5 subniveles. Banda AVANZADO, estadio DECIDIR (13.1-13.2,
13.4) y EXPLICAR (13.3, 13.5). Voz: profesor de póker rioplatense.

Fuente de verdad: curriculum_spec.json.

Meta de N13: el cierre de la Academia. Primero ubica al alumno en el
entorno real (NL2, 13.1), después explica de dónde sale la ganancia real
en ese entorno (13.2), repasa los 18 errores más caros y frecuentes como
checklist de autocontrol (13.3), aplica todo a spots completos de río y
all-in (13.4), y termina con la sÍntesis final: una sola decisión
integrando pot odds, equity, rango y posición a la vez (13.5, capstone de
las 326 teorías).

Vocabulario nuevo de N13: NL2, rake, hero call. El resto es aplicación e
integración de todo lo aprendido en N1-N12 — 13.3 en particular es
deliberadamente corto por entrada: son 18 recordatorios, no 18 conceptos
nuevos.

NO hay niveles posteriores. Esta es la última tanda de contenido de la
Academia (T308 cierra las 326 teorías).
"""

N13 = {

# ============================================================
# 13.1 — El entorno NL2
# ============================================================

"T239": dict(  # Qué es NL2
 que_es="NL2 es el nivel de dinero real más bajo de nomenclatura común "
        "(no-limit con ciega grande de 2 centavos): el punto de partida "
        "típico para jugar con dinero de verdad.",
 por_que_importa="Es un entorno particular: lleno de jugadores que "
        "recién empiezan o juegan por diversión, con errores mucho más "
        "grandes y frecuentes que en niveles más altos.",
 como_funciona="Todo lo que aprendiste en N1-N12 sigue aplicando "
        "igual — la diferencia es contra quién lo aplicás: rivales que "
        "se equivocan más seguido y de forma más obvia que un jugador "
        "avanzado.",
 cuando_lo_uso="Como marco general antes de sentarte a jugar con "
        "dinero real por primera vez.",
 cuando_no=None,
 ejemplo="En NL2 es común ver jugadores pagando con manos muy débiles "
        "o jugando casi cualquier mano preflop — errores que en "
        "niveles más altos son mucho más raros.",
 error_comun="Jugar NL2 como si fuera contra rivales perfectamente "
        "equilibrados (N11, T237), desaprovechando que ahí conviene "
        "explotar errores concretos y frecuentes.",
 idea_clave="NL2 = el punto de entrada al dinero real, con más errores "
        "de los rivales que en cualquier otro nivel.",
),

"T240": dict(  # 100 BB en NL2 (impacto estratégico)
 que_es="Jugar con 100 BB de profundidad (el estándar típico en NL2) "
        "define qué manos son rentables y cuáles no, según todo lo que "
        "ya sabés de profundidad de stack (N11, T228).",
 por_que_importa="100 BB es lo bastante profundo como para que las "
        "manos especulativas (parejas chicas, conectores suited) "
        "tengan buen potencial de implied odds (N6), pero no tan "
        "profundo como para que la teoría cambie radicalmente.",
 como_funciona="Aplicás lo que ya sabés de profundidad de stack: con "
        "100 BB, tanto la fuerza inmediata como el potencial "
        "especulativo tienen su lugar en tu rango jugable.",
 cuando_lo_uso="Como referencia estándar al sentarte en una mesa de "
        "NL2 con el buy-in típico.",
 cuando_no=None,
 ejemplo="Con 100 BB, una pareja chica buscando trío tiene buen "
        "potencial: si liga, hay stack suficiente detrás para ganar "
        "una mano grande.",
 error_comun="Aplicar ajustes de stack corto o extra-profundo sin "
        "haber chequeado primero cuánto stack hay realmente en la "
        "mesa.",
 idea_clave="100 BB es el estándar de NL2: suficiente profundidad para "
        "que el potencial especulativo tenga valor real.",
),

"T241": dict(  # El rake
 que_es="El rake es la comisión que se queda la casa de cada bote — "
        "un costo fijo que reduce, un poco, la ganancia de cada mano "
        "jugada.",
 por_que_importa="El rake hace que decisiones muy cercanas (que serían "
        "apenas rentables sin él) dejen de serlo: obliga a jugar un "
        "poco más ajustado de lo que la teoría 'pura' sugeriría.",
 como_funciona="En cada bote, la casa se queda un pequeño porcentaje "
        "antes de repartirlo al ganador. Es un costo constante que "
        "afecta más a los botes chicos y a las decisiones marginales.",
 cuando_lo_uso="Como ajuste general: con decisiones muy cerradas "
        "(donde el EV calculado da apenas positivo), el rake puede "
        "inclinar la balanza hacia foldear.",
 cuando_no=None,
 ejemplo="Una decisión que en la teoría 'pura' da apenas +EV puede "
        "terminar siendo -EV real una vez descontado el rake del bote.",
 error_comun="Ignorar el rake al evaluar decisiones muy cerradas, "
        "tratando el EV teórico como si fuera el EV real de la mesa.",
 idea_clave="El rake resta valor a cada bote: jugá un poco más "
        "ajustado en las decisiones más cerradas para compensarlo.",
),

# ============================================================
# 13.2 — Cómo se gana en NL2
# ============================================================

"T242": dict(  # El valor de las manos fuertes
 que_es="En NL2, la mayor parte de tu ganancia viene de jugar bien tus "
        "manos fuertes — no de jugadas complicadas ni faroles "
        "elaborados.",
 por_que_importa="Contra rivales que pagan de más (T247), sacarle todo "
        "el valor posible a tus mejores manos rinde más que cualquier "
        "otra estrategia sofisticada.",
 como_funciona="Priorizá apostar por valor con tus manos fuertes, con "
        "buen tamaño, en vez de jugarlas con miedo a 'espantar' al "
        "rival — en NL2, ese miedo suele ser injustificado.",
 cuando_lo_uso="Como principio general al jugar en este entorno: "
        "priorizar el valor por sobre la sofisticación.",
 cuando_no=None,
 ejemplo="Con un set en NL2, apostar grande y seguido rinde más que "
        "jugarlo con cautela pensando en rivales que casi nunca "
        "existen ahí.",
 error_comun="Jugar las manos fuertes con el mismo cuidado que "
        "usarías contra rivales avanzados, subestimando cuánto pagan "
        "los rivales de NL2.",
 idea_clave="En NL2, el dinero viene sobre todo de exprimir bien tus "
        "manos fuertes.",
),

"T243": dict(  # Evitar los hero calls
 que_es="Un hero call es pagar una apuesta grande con una mano que "
        "solo le gana a un farol — y en NL2, donde los rivales farolean "
        "poco, conviene evitarlos.",
 por_que_importa="En niveles altos, farolear seguido es parte del "
        "juego y los hero calls a veces se justifican (N9, T202). En "
        "NL2, la mayoría de las apuestas grandes representan mano de "
        "verdad.",
 como_funciona="Antes de un hero call, preguntate (N9, T210) si el "
        "rival realmente tiene manos mejores dispuestas a foldear — en "
        "NL2, la respuesta suele ser que no.",
 cuando_lo_uso="Al enfrentar una apuesta grande en NL2, con una mano "
        "que solo le gana a un farol.",
 cuando_no=None,
 ejemplo="Un rival de NL2 apuesta fuerte el river después de haber "
        "apostado todas las calles: en este entorno, esa línea suele "
        "significar mano real, no farol.",
 error_comun="Pagar 'para ver' con un bluff catcher en NL2, olvidando "
        "que ahí los rivales farolean mucho menos que en niveles "
        "avanzados.",
 idea_clave="En NL2, los hero calls suelen ser -EV: la mayoría de las "
        "apuestas grandes son de verdad.",
),

"T244": dict(  # Evitar los calls marginales
 que_es="Pagar de menos con manos marginales (sobre todo fuera de "
        "posición) es más rentable en NL2 que intentar 'ver flops "
        "baratos' con cualquier cosa.",
 por_que_importa="Cada call marginal fuera de posición te pone en "
        "decisiones difíciles calle tras calle, contra rivales que, "
        "además, suelen apostar sin mucha estructura.",
 como_funciona="Aplicá tu rango de call (N7, T160) con criterio: si la "
        "mano no juega claramente bien fuera de posición, mejor "
        "foldearla que 'verla barata'.",
 cuando_lo_uso="Al decidir si pagar un open con una mano marginal, "
        "especialmente fuera de posición.",
 cuando_no=None,
 ejemplo="Pagar con una mano floja fuera de posición 'para ver el "
        "flop' suele costarte más fichas a la larga de las que "
        "ganás ocasionalmente ligando algo.",
 error_comun="Pagar cualquier mano jugable solo por curiosidad de ver "
        "el flop, sin pensar en el costo de jugarla fuera de posición.",
 idea_clave="En NL2, menos calls marginales fuera de posición = más "
        "ganancia a la larga.",
),

"T245": dict(  # Evitar jugar demasiadas manos
 que_es="Jugar menos manos preflop, con más disciplina, rinde más que "
        "entrar en cualquier mano jugable solo por estar en la mesa.",
 por_que_importa="Cada mano marginal que jugás de más te expone a "
        "decisiones difíciles postflop sin suficiente ventaja para "
        "compensar el riesgo.",
 como_funciona="Respetá tus rangos de apertura y defensa (N5, N7) con "
        "disciplina, sin ampliarlos 'porque hace rato no juego una "
        "mano'.",
 cuando_lo_uso="Como hábito general de mesa: jugar menos manos, mejor "
        "elegidas.",
 cuando_no=None,
 ejemplo="Foldear varias manos seguidas es normal y correcto — no es "
        "una señal de que 'hay que jugar algo' en la próxima mano "
        "jugable que aparezca.",
 error_comun="Ampliar tu rango 'porque hace mucho que no jugás una "
        "mano', sin ningún motivo real detrás de esa ampliación.",
 idea_clave="Jugar menos manos, mejor elegidas, rinde más que jugar "
        "por aburrimiento.",
),

"T246": dict(  # Aprovechar los errores del rival
 que_es="Aprender a reconocer los errores típicos de NL2 (jugar de "
        "más, pagar de más, no farolear) te permite adaptar tu juego "
        "(N11, T238) para castigarlos directamente.",
 por_que_importa="No alcanza con jugar 'correcto en el vacío': la "
        "ganancia real en NL2 viene de identificar y explotar patrones "
        "concretos de cada rival.",
 como_funciona="Observá cómo juega cada rival (¿paga de más? ¿nunca "
        "farolea? ¿juega demasiadas manos?) y ajustá tu estrategia "
        "específicamente contra él.",
 cuando_lo_uso="A lo largo de la sesión, sumando información real "
        "sobre cada rival.",
 cuando_no=None,
 ejemplo="Si notás que un rival nunca farolea, dejás de hacerle hero "
        "calls (T243) y en cambio apostás por valor sin miedo cuando "
        "tenés lo mejor.",
 error_comun="Jugar en piloto automático sin observar ni aprovechar "
        "los patrones concretos de cada rival en la mesa.",
 idea_clave="La ganancia real en NL2 viene de identificar y castigar "
        "errores concretos, no de jugar en el vacío.",
),

"T247": dict(  # Apostar más fuerte por valor
 que_es="En NL2, conviene apostar tamaños más grandes por valor de lo "
        "que harías contra rivales más avanzados, porque ahí te pagan "
        "de más.",
 por_que_importa="Si los rivales pagan con manos peores incluso con "
        "apuestas grandes, dejar plata en la mesa apostando chico es "
        "un error caro y muy frecuente en principiantes.",
 como_funciona="Con tus manos de valor claro, probá tamaños más "
        "grandes de lo habitual: en NL2, muchas veces te siguen "
        "pagando igual.",
 cuando_lo_uso="Con manos de valor fuerte, contra rivales que ya "
        "mostraron que pagan de más.",
 cuando_no=None,
 ejemplo="Con un color hecho contra un rival que paga cualquier cosa, "
        "apostar el tamaño del bote (en vez de la mitad) suele seguir "
        "cobrando el mismo pago.",
 error_comun="Apostar tamaños chicos 'para asegurar el pago', dejando "
        "de cobrar valor extra que un rival de NL2 hubiera pagado igual.",
 idea_clave="En NL2, apostá más grande por valor: te pagan más de lo "
        "que un jugador avanzado pagaría.",
),

"T248": dict(  # Farolear de forma selectiva
 que_es="En NL2, farolear rinde mucho menos que en niveles más altos: "
        "conviene hacerlo poco, y solo con buenos motivos (bloqueadores, "
        "N11, y una línea que realmente tenga sentido).",
 por_que_importa="Como los rivales de NL2 pagan de más (T247) y "
        "farolean poco (T243), tu fold equity (N6) contra ellos es "
        "menor de lo habitual.",
 como_funciona="Reservá tus faroles para las mejores situaciones: "
        "buenos bloqueadores, una línea coherente (N10), y rivales que "
        "ya demostraron que sí pueden foldear.",
 cuando_lo_uso="Al considerar farolear en NL2: con mucho más criterio "
        "que en niveles avanzados, no menos.",
 cuando_no="Contra un rival que ya mostró que paga cualquier cosa — "
        "ahí ningún farol funciona, por bien elegido que esté.",
 ejemplo="Farolear con una mano que bloquea (N11, T232) las manos de "
        "valor más probables del rival, contra alguien que ya mostró "
        "que a veces foldea, es mucho más selectivo que farolear "
        "porque sí.",
 error_comun="Farolear con la misma frecuencia que usarías contra "
        "rivales avanzados, cuando en NL2 esa frecuencia es demasiado "
        "alta.",
 idea_clave="En NL2, farolear menos y mejor rinde más que farolear "
        "seguido.",
),

"T249": dict(  # La posición como fuente de ganancia
 que_es="Priorizar jugar manos en posición (N3, N11) es una de las "
        "fuentes de ganancia más confiables y consistentes en NL2.",
 por_que_importa="La ventaja posicional (N11, T226) funciona igual en "
        "cualquier nivel: en NL2, sumada a rivales que juegan peor "
        "fuera de posición todavía, rinde todavía más.",
 como_funciona="Priorizá tus manos jugables en posiciones tardías "
        "sobre las tempranas, y aprovechá cada mano donde jugás en "
        "posición para extraer el máximo valor posible.",
 cuando_lo_uso="Como criterio general de selección de manos y de "
        "estilo de juego en NL2.",
 cuando_no=None,
 ejemplo="Ampliar un poco tu rango de apertura del botón (siempre "
        "dentro de lo razonable) suele rendir más en NL2 que ampliar "
        "el de UTG, porque en posición vas a poder explotar mejor los "
        "errores postflop del rival.",
 error_comun="Tratar todas las posiciones igual, sin priorizar "
        "activamente jugar más manos desde las posiciones tardías.",
 idea_clave="La posición es una fuente de ganancia confiable — "
        "priorizarla rinde, mano tras mano.",
),

"T250": dict(  # La disciplina preflop
 que_es="Sostener la disciplina preflop (rangos de apertura y defensa, "
        "N5 y N7) mano tras mano, sesión tras sesión, sin aflojar por "
        "aburrimiento o mala racha.",
 por_que_importa="Es fácil sostener la disciplina en la teoría; "
        "sostenerla en la práctica, mano 200 de una sesión larga, es lo "
        "que realmente separa el resultado a largo plazo.",
 como_funciona="Repetí los mismos rangos (N5, N7) sin importar cuántas "
        "manos llevás foldeadas seguidas ni cómo viene la sesión.",
 cuando_lo_uso="A lo largo de toda una sesión, como hábito constante.",
 cuando_no=None,
 ejemplo="Después de foldear 20 manos seguidas, la mano 21 se evalúa "
        "exactamente con el mismo criterio que la primera — sin "
        "ablandar el rango por cansancio.",
 error_comun="Aflojar la disciplina preflop después de una mala racha "
        "o muchas manos aburridas seguidas.",
 idea_clave="La disciplina preflop se sostiene igual en la mano 1 y en "
        "la mano 200.",
),

"T251": dict(  # La selección de manos
 que_es="Elegir bien qué manos jugar, combinando posición y acción "
        "previa (N5, N7) — el resumen práctico de todo lo aprendido "
        "sobre rangos.",
 por_que_importa="Es la aplicación final de todo el trabajo de N5 y "
        "N7: no una regla nueva, sino la ejecución consistente de lo "
        "que ya sabés.",
 como_funciona="Combinás posición + acción previa + tu rango "
        "correspondiente (apertura, defensa, 3-bet) para cada mano que "
        "te toca decidir.",
 cuando_lo_uso="En cada decisión preflop, como síntesis de todo lo "
        "aprendido en N5-N7.",
 cuando_no=None,
 ejemplo="La misma mano se juega distinto según posición y acción "
        "previa — la selección de manos es aplicar ese criterio "
        "consistentemente, mano tras mano.",
 error_comun="Decidir mano por mano sin un criterio consistente de "
        "selección, olvidando rangos ya definidos.",
 idea_clave="La selección de manos es la aplicación consistente de "
        "tus rangos de apertura, defensa y 3-bet.",
),

"T252": dict(  # Reconocer spots rentables
 que_es="Reconocer los spots (situaciones concretas) donde un rival de "
        "NL2 casi siempre se equivoca — la habilidad final que combina "
        "todo lo anterior de 13.2.",
 por_que_importa="Es el resumen práctico de todo el subnivel: "
        "observar, reconocer patrones y aprovecharlos activamente, en "
        "vez de jugar 'correcto en el vacío'.",
 como_funciona="Juntá lo que ya sabés: valor de manos fuertes (T242), "
        "hero calls a evitar (T243), errores del rival (T246), tamaños "
        "de valor (T247) y faroles selectivos (T248) — y aplicalo a "
        "cada situación concreta que reconozcas.",
 cuando_lo_uso="A lo largo de toda tu sesión en NL2, como el criterio "
        "final que junta todo el subnivel.",
 cuando_no=None,
 ejemplo="Un rival que siempre paga demasiado con manos débiles es un "
        "spot rentable recurrente: apostás por valor más seguido y más "
        "grande contra él específicamente.",
 error_comun="Aplicar una estrategia genérica sin adaptarla a los "
        "spots concretos y recurrentes que vas reconociendo en la "
        "mesa.",
 idea_clave="Reconocer spots rentables = juntar todo lo de 13.2 en "
        "decisiones concretas, mesa tras mesa.",
),

# ============================================================
# 13.3 — Los 18 errores que cuestan fichas
# ============================================================
# Repaso deliberadamente corto: cada teoría recuerda un error ya cubierto
# en niveles anteriores, no introduce nada nuevo. "Repasar ≠ repetir".

"T270": dict(  # Error: jugar demasiadas manos
 que_es="Jugar más manos de las que tu rango (N5, N7) permite para esa "
        "posición y situación.",
 por_que_importa="Es, probablemente, el error más caro y más común de "
        "todo el juego — cada mano de más jugada es fichas que se "
        "pierden a la larga.",
 como_funciona="Se corrige volviendo a T245 y T250: disciplina "
        "sostenida, sin excepciones por aburrimiento.",
 cuando_lo_uso="Como primer chequeo de autocontrol antes de cada mano.",
 cuando_no=None,
 ejemplo="Jugar una mano que claramente no entra en tu rango de "
        "apertura 'porque hace rato no jugás nada'.",
 error_comun=None,
 idea_clave="Error 1: jugar de más. Se corrige con la disciplina de "
        "T245.",
),

"T271": dict(  # Error: jugar fuera de posición sin razón
 que_es="Entrar en manos fuera de posición sin un motivo real que lo "
        "justifique.",
 por_que_importa="Fuera de posición jugás con menos información toda "
        "la mano (N3, N11) — hacerlo sin necesidad regala esa "
        "desventaja gratis.",
 como_funciona="Se corrige aplicando T244 (evitar calls marginales "
        "OOP) y T249 (priorizar la posición).",
 cuando_lo_uso="Al evaluar cualquier mano donde vas a jugar fuera de "
        "posición.",
 cuando_no=None,
 ejemplo="Pagar un open fuera de posición con una mano que solo "
        "jugarías cómodo en posición.",
 error_comun=None,
 idea_clave="Error 2: jugar fuera de posición sin razón. Se corrige "
        "priorizando la posición (T249).",
),

"T272": dict(  # Error: pagar porque "ya puse dinero"
 que_es="Pagar una apuesta solo porque ya pusiste fichas antes en la "
        "mano — el error del costo hundido.",
 por_que_importa="Las fichas que ya pusiste no vuelven, ganes o "
        "pierdas la decisión de ahora: no son parte del cálculo de EV "
        "hacia adelante (N6, T124).",
 como_funciona="Se corrige recordando T124 (el EV del fold): cada "
        "decisión se evalúa desde cero, mirando solo hacia adelante.",
 cuando_lo_uso="Cada vez que sentís la tentación de pagar 'porque ya "
        "invertiste' en la mano.",
 cuando_no=None,
 ejemplo="Pagar una apuesta grande en el river solo porque ya "
        "pagaste el flop y el turn, sin evaluar la decisión de ahora "
        "por separado.",
 error_comun=None,
 idea_clave="Error 3: costo hundido. Se corrige recordando que las "
        "fichas ya puestas no cuentan para la decisión de ahora.",
),

"T273": dict(  # Error: pagar de más con manos marginales
 que_es="Pagar apuestas con manos que no alcanzan la equity necesaria "
        "(N6) para que ese call sea rentable.",
 por_que_importa="Es directamente lo opuesto a un call rentable (N6, "
        "T118): pagar de más con manos marginales es, en números, "
        "perder fichas a la larga.",
 como_funciona="Se corrige volviendo al checklist de N6: comparar tu "
        "equity real contra la equity necesaria antes de pagar.",
 cuando_lo_uso="Cada vez que dudás si pagar una apuesta con una mano "
        "que 'no está tan mal'.",
 cuando_no=None,
 ejemplo="Pagar con una equity real de 20% cuando la equity necesaria "
        "es 33% (N6, T119): un call perdedor.",
 error_comun=None,
 idea_clave="Error 4: pagar de más. Se corrige comparando equity real "
        "contra equity necesaria (N6).",
),

"T274": dict(  # Error: sobrevalorar el top pair
 que_es="Tratar cualquier top pair (N4) como si fuera siempre una mano "
        "fuerte, sin importar el kicker, el board ni el tamaño del "
        "bote.",
 por_que_importa="Un top pair con kicker débil, en un board peligroso, "
        "en un bote grande, no vale lo mismo que un top pair con "
        "kicker fuerte en un board seco.",
 como_funciona="Se corrige aplicando el checklist de N12 (T297): "
        "clasificar la mano con precisión y compararla contra el rango "
        "real del rival, no contra 'top pair es fuerte' como regla "
        "fija.",
 cuando_lo_uso="Cada vez que tenés top pair y estás por comprometer "
        "muchas fichas.",
 cuando_no=None,
 ejemplo="Jugarte todo el stack con top pair y kicker débil contra "
        "una apuesta enorme en un board peligroso, solo porque 'es top "
        "pair'.",
 error_comun=None,
 idea_clave="Error 5: sobrevalorar el top pair. Se corrige clasificando "
        "con precisión, no por regla fija.",
),

"T275": dict(  # Error: no reconocer que estás dominado
 que_es="No darte cuenta de que tu mano está dominada (N4, T073): "
        "misma categoría de mano que el rival, pero peor kicker o peor "
        "versión.",
 por_que_importa="Una mano dominada pierde casi siempre contra la que "
        "la domina — jugarla como si fuera pareja, sin reconocer eso, "
        "cuesta fichas grandes.",
 como_funciona="Se corrige volviendo a T073: comparar tu mano contra "
        "el rango del rival, no solo contra la categoría general.",
 cuando_lo_uso="Cada vez que tenés una pareja o mano hecha y el rival "
        "muestra fuerza también.",
 cuando_no=None,
 ejemplo="Pagar todo el stack con una pareja de reyes con kicker "
        "débil contra un rival que representa la misma pareja pero con "
        "mejor kicker.",
 error_comun=None,
 idea_clave="Error 6: no ver que estás dominado. Se corrige comparando "
        "contra el rango, no solo contra la categoría.",
),

"T276": dict(  # Error: perseguir proyectos sin el precio correcto
 que_es="Pagar para completar un proyecto sin que tu equity supere la "
        "equity necesaria (N6, T116-T119).",
 por_que_importa="Un proyecto que no tiene el precio correcto es un "
        "call perdedor (T119), aunque a veces termine completando.",
 como_funciona="Se corrige aplicando el cálculo completo de N6: outs, "
        "equity (regla del 2 o del 4), y comparación contra la equity "
        "necesaria.",
 cuando_lo_uso="Cada vez que tenés un proyecto y estás por pagar una "
        "apuesta.",
 cuando_no=None,
 ejemplo="Pagar un precio que exige 40% de equity con un proyecto de "
        "gutshot (solo 4 outs, mucho menos del 40% necesario).",
 error_comun=None,
 idea_clave="Error 7: perseguir sin el precio correcto. Se corrige con "
        "el cálculo completo de outs y equity necesaria (N6).",
),

"T277": dict(  # Error: confundir outs con equity
 que_es="Tratar la cantidad de outs (N6, T101) como si fuera "
        "directamente el porcentaje de equity, sin aplicar la regla "
        "del 2 o del 4.",
 por_que_importa="9 outs no son '9% de equity': son aproximadamente "
        "18% (regla del 2, una carta) o 36% (regla del 4, dos cartas). "
        "Confundir ambas cosas lleva a subestimar tu equity real.",
 como_funciona="Se corrige recordando N6, T108-T109: siempre multiplicar "
        "los outs por 2 o por 4 según cuántas cartas quedan por venir.",
 cuando_lo_uso="Cada vez que contás outs, como recordatorio de "
        "convertirlos correctamente en un porcentaje.",
 cuando_no=None,
 ejemplo="Pensar 'tengo 9 outs, o sea 9% de equity' en vez de aplicar "
        "la regla del 4 y llegar a ≈36%.",
 error_comun=None,
 idea_clave="Error 8: confundir outs con equity. Se corrige "
        "multiplicando por 2 o por 4 (N6).",
),

"T278": dict(  # Error: ignorar el rango del rival
 que_es="Decidir mirando solo tu propia mano, sin construir el rango "
        "probable del rival (N5-N10).",
 por_que_importa="Es el error más básico de todos los que se corrigen "
        "con el checklist de N12: toda decisión buena compara tu mano "
        "contra un rango, no contra el aire.",
 como_funciona="Se corrige volviendo al checklist completo (N12, "
        "12.1): posición, acción previa, y rango del rival, antes de "
        "decidir.",
 cuando_lo_uso="Como chequeo constante: '¿ya pensé en lo que él podría "
        "tener?'.",
 cuando_no=None,
 ejemplo="Pagar o foldear pensando solo 'mi mano es buena/mala', sin "
        "preguntarte contra qué rango la estás comparando.",
 error_comun=None,
 idea_clave="Error 9: ignorar el rango del rival. Se corrige con el "
        "checklist completo (N12).",
),

"T279": dict(  # Error: mirar solo tus cartas
 que_es="Concentrarte únicamente en tus dos cartas privadas, sin "
        "prestar atención al resto del contexto de la mano (board, "
        "posición, acción).",
 por_que_importa="Tus cartas son solo una de las siete preguntas del "
        "checklist (N12, T254) — el resto importa igual o más.",
 como_funciona="Se corrige recorriendo el checklist completo (N12, "
        "12.1), no solo su segundo paso.",
 cuando_lo_uso="Como chequeo general: '¿estoy mirando toda la "
        "situación, o solo mis cartas?'.",
 cuando_no=None,
 ejemplo="Jugar la misma mano exactamente igual sin importar posición, "
        "board o acción previa, solo porque 'las cartas son buenas'.",
 error_comun=None,
 idea_clave="Error 10: mirar solo tus cartas. Se corrige con el "
        "checklist completo (N12).",
),

"T280": dict(  # Error: ignorar el board
 que_es="No leer la textura del board (N4, T257) antes de decidir: "
        "seco o coordinado, con o sin proyectos posibles.",
 por_que_importa="La misma mano vale distinto según el board — "
        "ignorarlo te hace tomar la misma decisión en situaciones muy "
        "distintas.",
 como_funciona="Se corrige volviendo al quinto paso del checklist "
        "(N12, T257): siempre clasificar el board antes de decidir.",
 cuando_lo_uso="Cada vez que llegás a una decisión postflop.",
 cuando_no=None,
 ejemplo="C-betear con la misma frecuencia en un board seco y en uno "
        "coordinado, sin ajustar por la diferencia (N8, T180-T181).",
 error_comun=None,
 idea_clave="Error 11: ignorar el board. Se corrige clasificándolo "
        "siempre (N4, N12).",
),

"T281": dict(  # Error: apostar en automático
 que_es="Apostar por costumbre, sin un motivo concreto de valor o "
        "farol detrás de esa apuesta puntual.",
 por_que_importa="Cada apuesta debería tener un motivo claro (N9, "
        "T207-T208): valor, farol, o ninguno de los dos (y entonces "
        "pasar).",
 como_funciona="Se corrige preguntándote, antes de cada apuesta: "
        "'¿esto es valor, farol, o no tengo motivo real?'.",
 cuando_lo_uso="Como chequeo antes de cada apuesta que estés por "
        "hacer.",
 cuando_no=None,
 ejemplo="Apostar 'porque siempre apuesto en esta situación', sin "
        "revisar si esta mano puntual tiene un motivo real.",
 error_comun=None,
 idea_clave="Error 12: apostar en automático. Se corrige exigiéndote "
        "un motivo (valor o farol) por apuesta.",
),

"T282": dict(  # Error: hacer c-bet en automático
 que_es="C-betear siempre que tenés la iniciativa, sin ajustar por "
        "board, posición o cantidad de rivales (N8).",
 por_que_importa="Es la versión específica de T281 aplicada a la "
        "c-bet: una de las jugadas más automatizadas del juego, y por "
        "eso una de las más fáciles de explotar si se hace sin "
        "criterio.",
 como_funciona="Se corrige volviendo a N8 completo: board (8.3), "
        "posición (8.4) y multiway (TN18) ajustan cuándo y cómo "
        "c-betear.",
 cuando_lo_uso="Cada vez que tenés la iniciativa y estás por c-betear.",
 cuando_no=None,
 ejemplo="C-betear el 100% de las veces sin importar el board, "
        "volviéndote predecible para cualquier rival atento.",
 error_comun=None,
 idea_clave="Error 13: c-betear en automático. Se corrige ajustando "
        "por board, posición y multiway (N8).",
),

"T283": dict(  # Error: farolear sin pensar en el rango rival
 que_es="Farolear sin preguntarte si el rival tiene manos mejores que "
        "realmente se retirarían frente a tu apuesta (N9, T210).",
 por_que_importa="Un farol sin fold equity real detrás no gana nada: "
        "es simplemente regalar fichas.",
 como_funciona="Se corrige volviendo a T210: antes de farolear, "
        "chequeá específicamente si existen manos mejores del rival "
        "dispuestas a foldear.",
 cuando_lo_uso="Cada vez que estás por farolear.",
 cuando_no=None,
 ejemplo="Farolear contra un rival que ya mostró que nunca foldea, sin "
        "importar el tamaño de tu apuesta.",
 error_comun=None,
 idea_clave="Error 14: farolear sin pensar en el rango. Se corrige "
        "chequeando fold equity real (N9).",
),

"T284": dict(  # Error: no hacer value bet
 que_es="No apostar una mano que sí tiene valor real, por miedo "
        "excesivo a que el rival tenga algo mejor.",
 por_que_importa="Es el error opuesto a T283: tan caro como farolear "
        "sin motivo es dejar de cobrar valor real por miedo "
        "injustificado, sobre todo en NL2 (T247).",
 como_funciona="Se corrige aplicando T209 (¿qué manos peores me "
        "pagan?): si la respuesta es 'varias', apostá.",
 cuando_lo_uso="Cada vez que dudás si apostar una mano que probablemente "
        "es la mejor.",
 cuando_no=None,
 ejemplo="Pasar con una mano fuerte 'por las dudas' contra un rango "
        "que claramente tiene manos peores dispuestas a pagar.",
 error_comun=None,
 idea_clave="Error 15: no apostar valor real. Se corrige confiando en "
        "el checklist (N9, T209), no en el miedo.",
),

"T285": dict(  # Error: hacer hero call por curiosidad
 que_es="Pagar una apuesta grande solo por curiosidad de ver las "
        "cartas del rival, sin un análisis real detrás.",
 por_que_importa="Es una versión específica y muy cara de T273: en "
        "NL2 en particular (T243), estos calls suelen ser fuertemente "
        "-EV.",
 como_funciona="Se corrige volviendo a T202 (uso del bluff catcher): "
        "pagar solo cuando la línea completa del rival (N10) realmente "
        "sugiere un farol.",
 cuando_lo_uso="Cada vez que sentís ganas de pagar 'solo para ver'.",
 cuando_no=None,
 ejemplo="Pagar una apuesta grande en el río 'para ver qué tenía', "
        "aunque toda la línea de la mano apuntaba claramente a valor.",
 error_comun=None,
 idea_clave="Error 16: hero call por curiosidad. Se corrige leyendo la "
        "línea (N10) antes de pagar, no la curiosidad.",
),

"T286": dict(  # Error: decidir en tilt
 que_es="Tomar decisiones influenciado por la frustración o la "
        "emoción del momento (el tilt), en vez de por el análisis "
        "frío de la situación.",
 por_que_importa="El tilt hace que abandones todo lo aprendido en la "
        "Academia justo cuando más rentable sería aplicarlo con "
        "claridad.",
 como_funciona="Se corrige reconociendo la señal (jugar más rápido de "
        "lo normal, ampliar rangos sin motivo, buscar 'recuperar' lo "
        "perdido) y haciendo una pausa antes de seguir decidiendo.",
 cuando_lo_uso="Cada vez que notás que estás jugando distinto después "
        "de una mano frustrante.",
 cuando_no=None,
 ejemplo="Después de perder una mano grande, ampliar tu rango de "
        "apertura para 'recuperar rápido' — la señal clásica del tilt.",
 error_comun=None,
 idea_clave="Error 17: decidir en tilt. Se corrige reconociendo la "
        "señal y haciendo una pausa.",
),

"T287": dict(  # Error: confundir ganar la mano con tomar una buena decisión
 que_es="Medir tu propio juego por si ganaste o perdiste cada mano "
        "puntual, en vez de por la calidad de tus decisiones (N6, "
        "T127; N12, T269).",
 por_que_importa="Es, probablemente, el error de mentalidad más "
        "importante de toda la Academia — el que hace que todo lo "
        "demás (disciplina, EV, checklist) se sostenga o se abandone.",
 como_funciona="Se corrige volviendo a T269, el cierre del checklist: "
        "juzgá cada decisión por su EV en el momento, no por el "
        "resultado de esa mano puntual.",
 cuando_lo_uso="Después de cada mano, sobre todo las que perdiste con "
        "una decisión que sabías correcta.",
 cuando_no=None,
 ejemplo="Perder una mano con un call +EV (36% de equity contra 33% "
        "necesario, N6) no significa que la decisión estuvo mal — "
        "significa que perdiste el 64% que era esperable.",
 error_comun=None,
 idea_clave="Error 18, el más importante: el resultado de una mano no "
        "define si la decisión fue buena. Eso lo define el EV en el "
        "momento.",
),

# ============================================================
# 13.4 — Spots completos de río y all-in
# ============================================================

"T300": dict(  # Integrar: el valor en el río
 que_es="Aplicar el checklist completo (N12) a la decisión de apostar "
        "por valor en el río (N9, T199), en una mano completa de "
        "principio a fin.",
 por_que_importa="Es la primera de cuatro aplicaciones del checklist a "
        "spots completos del river, el momento más definitorio de "
        "cualquier mano.",
 como_funciona="Recorrés todo el checklist (posición, mano, línea "
        "completa, board, mano hecha) y llegás a T209 (¿qué manos "
        "peores pagan?) para decidir el tamaño de tu apuesta de valor.",
 cuando_lo_uso="En cualquier river donde tenés una mano fuerte y estás "
        "considerando apostar por valor.",
 cuando_no=None,
 ejemplo="Mano completa: abriste, c-beteaste, apostaste el turn, y en "
        "el río con una mano fuerte, el checklist confirma un value "
        "bet de buen tamaño.",
 error_comun="Decidir el river aislado del resto de la mano, sin "
        "conectarlo con toda la línea que veníamos jugando.",
 idea_clave="El valor en el río se decide con el checklist completo, "
        "no aislado del resto de la mano.",
),

"T301": dict(  # Integrar: el farol en el río
 que_es="Aplicar el checklist completo a la decisión de farolear en el "
        "río (N9, T201), incluyendo bloqueadores (N11) y coherencia de "
        "línea (N10).",
 por_que_importa="Es la aplicación más exigente del checklist: junta "
        "casi todo lo aprendido en la Academia en una sola decisión.",
 como_funciona="Recorrés el checklist, verificás T210 (¿qué manos "
        "mejores foldean?), elegís una mano con buenos bloqueadores "
        "(N11, T232), y confirmás que tu línea completa (N10) cuenta "
        "una historia coherente.",
 cuando_lo_uso="En cualquier river donde estés considerando farolear.",
 cuando_no=None,
 ejemplo="Mano completa con una línea agresiva coherente, una mano "
        "que bloquea las manos de valor del rival, contra un rival que "
        "ya mostró que puede foldear: el checklist confirma el farol.",
 error_comun="Farolear sin haber chequeado bloqueadores ni coherencia "
        "de línea, solo por 'sentir' que el rival está débil.",
 idea_clave="El farol en el río se decide con todo el checklist: línea, "
        "bloqueadores y fold equity real, juntos.",
),

"T302": dict(  # Integrar: el bluff catch en el río
 que_es="Aplicar el checklist completo a la decisión de pagar como "
        "bluff catcher (N9, T202), leyendo la línea completa del rival "
        "(N10) para decidir.",
 por_que_importa="Es de las decisiones más difíciles de toda la "
        "Academia: estás apostando sobre el rival, no sobre tus "
        "cartas.",
 como_funciona="Recorrés el checklist, aplicás T221-T223 (coherencia "
        "de línea, identificar valor o farol) y decidís según si la "
        "línea completa parece más creíble como valor o como farol.",
 cuando_lo_uso="En cualquier river donde tu mano solo le gana a un "
        "farol.",
 cuando_no=None,
 ejemplo="Mano completa donde la línea del rival no encaja con "
        "ninguna mano de valor real (T223): el checklist apunta a "
        "pagar como bluff catcher.",
 error_comun="Decidir el bluff catch por sensación, sin haber "
        "reconstruido la línea completa de la mano.",
 idea_clave="El bluff catch se decide leyendo toda la línea, no el "
        "último tamaño de apuesta solo.",
),

"T303": dict(  # Integrar: la decisión de all-in
 que_es="Aplicar el checklist completo a la decisión de ir o pagar un "
        "all-in, usando el SPR (N7, N11) para saber qué tan comprometida "
        "está tu mano.",
 por_que_importa="Es la decisión de mayor riesgo de toda la mano: "
        "merece el checklist completo, no una decisión apurada.",
 como_funciona="Recorrés el checklist completo y sumás el SPR (N11, "
        "T229): con SPR bajo, manos buenas ya alcanzan; con SPR alto, "
        "hace falta mucho más para sentirte cómodo yendo por todo.",
 cuando_lo_uso="En cualquier decisión donde ir o pagar signifique "
        "comprometer todo tu stack.",
 cuando_no=None,
 ejemplo="Con SPR bajo y una mano fuerte pero no la mejor posible, el "
        "checklist confirma que alcanza para ir por todo el stack.",
 error_comun="Decidir un all-in por instinto en el momento, sin haber "
        "calculado el SPR ni recorrido el resto del checklist.",
 idea_clave="La decisión de all-in usa el checklist completo, con el "
        "SPR como dato clave adicional.",
),

# ============================================================
# 13.5 — La decisión integrada
# ============================================================

"T304": dict(  # La decisión por pot odds
 que_es="Apoyar una decisión completa específicamente en las pot odds "
        "(N6): comparar lo que arriesgás contra lo que podés ganar.",
 por_que_importa="Es uno de los cuatro pilares (junto a equity, rango "
        "y posición) que la última teoría de la Academia (T308) va a "
        "juntar en una sola decisión.",
 como_funciona="Repasás pot odds (T115), equity necesaria (T116) y la "
        "comparación final (T117) como el ángulo puramente matemático "
        "de cualquier decisión.",
 cuando_lo_uso="Como uno de los cuatro ángulos de la decisión "
        "integrada final.",
 cuando_no=None,
 ejemplo="Pot odds de 2 a 1 (N6): necesitás más del 33% de equity para "
        "que el call sea rentable — el ángulo puramente numérico de la "
        "decisión.",
 error_comun="Usar las pot odds como el único criterio, ignorando los "
        "otros tres ángulos (T305-T307).",
 idea_clave="Primer pilar de la decisión integrada: pot odds, el "
        "ángulo numérico puro.",
),

"T305": dict(  # La decisión por equity
 que_es="Apoyar una decisión completa en tu equity real (N6): tu "
        "porcentaje de ganar contra el rango del rival.",
 por_que_importa="Es el segundo pilar: las pot odds te dicen cuánto "
        "necesitás; la equity te dice cuánto tenés de verdad.",
 como_funciona="Repasás outs, la regla del 2/4, y la equity contra un "
        "rango completo (N6) como el segundo ángulo de la decisión.",
 cuando_lo_uso="Como segundo ángulo de la decisión integrada final.",
 cuando_no=None,
 ejemplo="Equity real de 36% (regla del 4 con 9 outs) contra pot odds "
        "que piden 33%: la comparación entre estos dos pilares ya "
        "resuelve la decisión matemática.",
 error_comun="Calcular la equity sin conectarla con las pot odds (T304) "
        "para llegar a una conclusión real.",
 idea_clave="Segundo pilar de la decisión integrada: tu equity real, "
        "comparada contra lo que piden las pot odds.",
),

"T306": dict(  # La decisión por rango
 que_es="Apoyar una decisión completa en la lectura del rango del "
        "rival (N5-N10): no solo el número de equity, sino la historia "
        "completa detrás de su línea.",
 por_que_importa="Es el tercer pilar: pot odds y equity son números; "
        "el rango es contexto — te dice si esos números están bien "
        "calculados o si la línea completa sugiere ajustarlos.",
 como_funciona="Repasás la línea completa del rival (N10), su "
        "coherencia (T221), y si representa más probablemente valor o "
        "farol (T222-T223).",
 cuando_lo_uso="Como tercer ángulo de la decisión integrada final.",
 cuando_no=None,
 ejemplo="Una línea que no encaja con valor (T223) puede hacerte "
        "ajustar tu estimación de equity hacia arriba, cambiando toda "
        "la decisión matemática de T304-T305.",
 error_comun="Calcular equity y pot odds con un rango genérico, sin "
        "ajustarlo por la línea específica y real que jugó el rival "
        "esta mano.",
 idea_clave="Tercer pilar de la decisión integrada: el rango real del "
        "rival, no uno genérico.",
),

"T307": dict(  # La decisión por posición
 que_es="Apoyar una decisión completa considerando tu posición (N3, "
        "N11): cuánto de tu equity vas a poder realizar de verdad "
        "(TN15) según si jugás en posición o no.",
 por_que_importa="Es el cuarto pilar: incluso con la misma equity "
        "cruda, la posición cambia cuánto de esa equity terminás "
        "cobrando en la práctica.",
 como_funciona="Repasás la realización de equity (N11, TN15) y la "
        "ventaja posicional estratégica (T226) como el cuarto ángulo, "
        "sobre todo en decisiones cercanas.",
 cuando_lo_uso="Como cuarto ángulo de la decisión integrada final, "
        "especialmente para desempatar decisiones muy cerradas.",
 cuando_no=None,
 ejemplo="Con una decisión matemáticamente muy cerrada (equity apenas "
        "por encima de lo necesario), jugarla en posición inclina la "
        "balanza a favor de seguir; fuera de posición, hacia foldear.",
 error_comun="Ignorar la posición como desempate en decisiones "
        "cerradas, quedándote solo con el número frío de equity.",
 idea_clave="Cuarto pilar de la decisión integrada: la posición, "
        "sobre todo para desempatar decisiones cerradas.",
),

"T308": dict(  # La decisión integrada
 que_es="La decisión integrada es juntar los cuatro pilares — pot "
        "odds, equity, rango y posición — en una sola decisión "
        "completa. Es el cierre de las 326 teorías de la Academia.",
 por_que_importa="Ningún pilar solo alcanza: las pot odds sin equity "
        "no dicen si tenés lo suficiente; la equity sin rango puede "
        "estar mal calculada; ni la equity ni el rango sin posición "
        "consideran cuánto de esa equity vas a cobrar de verdad.",
 como_funciona="Recorrés el checklist completo (N12): leés la "
        "situación, calculás pot odds y equity necesaria (T304), "
        "estimás tu equity real (T305), ajustás por la línea y el "
        "rango del rival (T306), y desempatás con la posición si hace "
        "falta (T307). Elegís la acción de mejor EV, la ejecutás, y "
        "después juzgás la decisión por su calidad — no por el "
        "resultado de esa mano puntual (T269).",
 cuando_lo_uso="En cualquier decisión importante de póker, como el "
        "proceso completo que reemplaza jugar 'a sentimiento'.",
 cuando_no=None,
 ejemplo="Pot odds 2 a 1 (33% necesario) + equity real 36% + línea del "
        "rival que no cierra del todo con valor + jugás en posición: "
        "los cuatro pilares apuntan en la misma dirección, y la "
        "decisión de seguir queda mucho más sólida que si te hubieras "
        "quedado con uno solo.",
 error_comun="Decidir con un solo pilar (solo equity, o solo "
        "'sensación' del rango) en vez de juntar los cuatro.",
 idea_clave="La decisión integrada = pot odds + equity + rango + "
        "posición, juntos. Ese es el juego completo que enseñó la "
        "Academia, de T001 a T308.",
),

}
