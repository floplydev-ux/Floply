# -*- coding: utf-8 -*-
"""
PASO 4 — Contenido redactado del NIVEL 12: "Integración y toma de
decisiones". 29 teorías, 4 subniveles. Banda AVANZADO, estadio EXPLICAR
(12.1-12.2) y DECIDIR (12.3-12.4). Voz: profesor de póker rioplatense.

Fuente de verdad: curriculum_spec.json.

Meta de N12: este nivel NO enseña conceptos nuevos de póker — organiza
todo lo ya aprendido (N1-N11) en un checklist práctico de diecisiete
preguntas (siete para leer el spot, en 12.1; diez para tomar la decisión,
en 12.2), y después lo aplica a doce situaciones concretas recurrentes
(12.3-12.4). Por eso el contenido es deliberadamente más corto que en
niveles anteriores: cada teoría es un paso de un proceso, no un concepto
nuevo — "completo no significa largo" se aplica más que nunca acá.

Vocabulario nuevo de N12: ninguno. Es integración pura.
"""

N12 = {

# ============================================================
# 12.1 — El checklist: leer el spot
# ============================================================

"T253": dict(  # ¿Cuál es mi posición?
 que_es="El primer paso de cualquier decisión: identificar dónde estás "
        "sentado en la mesa en este momento de la mano.",
 por_que_importa="Toda la Academia, desde N3, viene mostrando que la "
        "posición cambia todo lo demás. Por eso es la primera pregunta "
        "del checklist, no una más.",
 como_funciona="Antes de pensar en tu mano o en cualquier otra cosa, "
        "identificá tu posición (UTG, HJ, CO, BTN, SB, BB) y si vas a "
        "quedar en posición o no en las calles que siguen.",
 cuando_lo_uso="Al arrancar cualquier decisión, como primer paso "
        "automático.",
 cuando_no=None,
 ejemplo="Antes de mirar tus cartas, ya sabés: 'estoy en el botón' — "
        "eso ya te dice que tu rango puede ser más ancho y que vas a "
        "jugar el resto de la mano en posición.",
 error_comun="Saltarte este paso y mirar directo la mano, olvidando que "
        "la misma mano vale distinto según dónde estés sentado.",
 idea_clave="Primer paso del checklist: ¿dónde estoy sentado?",
),

"T254": dict(  # ¿Cuál es mi mano?
 que_es="El segundo paso: identificar exactamente qué dos cartas "
        "tenés, sin apurarte a la siguiente pregunta.",
 por_que_importa="Suena obvio, pero apurarse a decidir sin registrar "
        "bien la mano (tipo, palo, conexión) lleva a errores de "
        "clasificación que arrastran toda la decisión siguiente.",
 como_funciona="Nombrá tu mano con precisión: ¿es pareja? ¿suited u "
        "offsuit? ¿conectada? — todo lo que ya sabés clasificar desde "
        "N4.",
 cuando_lo_uso="Como segundo paso del checklist, después de la "
        "posición.",
 cuando_no=None,
 ejemplo="No es 'tengo una reina y un diez', es 'tengo QTs, conectada, "
        "del mismo palo' — la clasificación completa, no la versión "
        "apurada.",
 error_comun="Clasificar la mano a medias ('es una mano media') sin la "
        "precisión que las siguientes preguntas van a necesitar.",
 idea_clave="Segundo paso del checklist: ¿qué mano tengo, con "
        "precisión?",
),

"T255": dict(  # ¿Cuál es la acción previa?
 que_es="El tercer paso: reconstruir todo lo que ya pasó en la mano "
        "antes de que te toque a vos.",
 por_que_importa="Tu decisión no se toma en el vacío: depende "
        "completamente de qué pasó antes (¿llegó limpio? ¿alguien "
        "abrió? ¿alguien 3-beteó?).",
 como_funciona="Repasá, en orden, cada acción de cada jugador hasta "
        "llegar a vos: folds, calls, raises, y desde qué posición.",
 cuando_lo_uso="Como tercer paso del checklist, antes de pensar en el "
        "rango del rival.",
 cuando_no=None,
 ejemplo="UTG foldeó, HJ abrió, CO foldeó: esa es la acción previa "
        "completa que te llega a vos en el botón.",
 error_comun="Solo registrar la última acción ('alguien abrió') sin "
        "reconstruir toda la secuencia completa.",
 idea_clave="Tercer paso del checklist: ¿qué pasó exactamente antes de "
        "que me toque?",
),

"T256": dict(  # ¿Cuál es el rango del rival?
 que_es="El cuarto paso: construir el rango probable del rival, "
        "usando la acción previa que ya reconstruiste.",
 por_que_importa="Es donde aplicás todo lo de N5-N10: rango de "
        "apertura, de defensa, estrechado por cada acción de la línea.",
 como_funciona="Con la posición del rival y su acción (T255), "
        "construís su rango: de apertura si abrió, estrechado si ya "
        "hubo más acciones.",
 cuando_lo_uso="Como cuarto paso del checklist, antes de mirar el "
        "board.",
 cuando_no=None,
 ejemplo="El HJ abrió: su rango es el rango de apertura del HJ (N5), "
        "sin más ajustes todavía porque es la única acción que hizo.",
 error_comun="Saltarte este paso y decidir mirando solo tu propia mano, "
        "sin construir el rango del rival.",
 idea_clave="Cuarto paso del checklist: ¿qué rango tiene el rival, "
        "según lo que hizo?",
),

"T257": dict(  # ¿Cuál es el board?
 que_es="El quinto paso: leer la textura del board (N4) — seco, "
        "coordinado, con proyectos posibles.",
 por_que_importa="El board cambia cómo se comparan tu mano y el rango "
        "del rival: la misma mano vale distinto en boards distintos.",
 como_funciona="Mirá las cartas comunitarias y clasificá el board como "
        "ya sabés hacerlo desde N4: seco/coordinado, con o sin "
        "proyectos de color o escalera visibles.",
 cuando_lo_uso="Como quinto paso del checklist, en cualquier decisión "
        "postflop.",
 cuando_no=None,
 ejemplo="Un board K♠7♦2♣ es seco, sin proyectos visibles — un dato "
        "concreto para las preguntas que siguen.",
 error_comun="Mirar el board solo para ver si tu mano mejoró, sin "
        "clasificar su textura general para el resto del análisis.",
 idea_clave="Quinto paso del checklist: ¿qué tipo de board es?",
),

"T258": dict(  # ¿Qué mano tengo hecha?
 que_es="El sexto paso: clasificar con precisión qué mano hecha tenés "
        "ahora, combinando tus cartas con el board.",
 por_que_importa="Es la aplicación directa de la clasificación de N4 "
        "(top pair, set, color, etc.) al momento concreto de la "
        "decisión.",
 como_funciona="Combiná tus dos cartas con el board y nombrá tu mano "
        "con precisión: ¿es top pair? ¿un set? ¿nada?",
 cuando_lo_uso="Como sexto paso del checklist, después de leer el "
        "board.",
 cuando_no=None,
 ejemplo="Con A♠K♦ en un board K♠7♦2♣, tenés top pair con el mejor "
        "kicker posible — nombralo así, con precisión.",
 error_comun="Quedarte con una clasificación vaga ('tengo algo "
        "bueno') en vez de nombrar exactamente qué mano hecha tenés.",
 idea_clave="Sexto paso del checklist: ¿qué mano hecha tengo, con "
        "precisión?",
),

"T259": dict(  # ¿Qué proyectos tengo?
 que_es="El séptimo y último paso de 'leer el spot': identificar qué "
        "proyectos tenés, además de (o en vez de) una mano hecha.",
 por_que_importa="Una mano puede tener valor hecho, un proyecto, o "
        "ambos combinados (un proyecto con pareja incluida, por "
        "ejemplo) — cada combinación cambia la decisión.",
 como_funciona="Contá tus outs (N6) si tenés algún proyecto de color o "
        "escalera, sumado a lo que ya tenés hecho (T258).",
 cuando_lo_uso="Como último paso de 'leer el spot', antes de pasar a "
        "tomar la decisión (12.2).",
 cuando_no=None,
 ejemplo="Con un proyecto de color además de una pareja media: tenés "
        "mano hecha Y proyecto — dos fuentes de equity distintas para "
        "sumar.",
 error_comun="Olvidarse de contar los proyectos cuando ya identificaste "
        "una mano hecha, perdiendo equity adicional real del cálculo.",
 idea_clave="Séptimo paso del checklist: ¿tengo, además, algún "
        "proyecto?",
),

# ============================================================
# 12.2 — El checklist: tomar la decisión
# ============================================================

"T260": dict(  # ¿Qué equity tengo?
 que_es="El primer paso de 'tomar la decisión': estimar tu equity (N6) "
        "contra el rango del rival (T256), usando lo que tenés hecho "
        "(T258) y tus proyectos (T259).",
 por_que_importa="Es donde el 'leer el spot' (12.1) se convierte en un "
        "número concreto con el que trabajar.",
 como_funciona="Combiná tu mano hecha y tus outs contra el rango del "
        "rival: usá la regla del 2 o del 4 (N6) si tenés proyecto, o "
        "una estimación más directa si tu mano ya está hecha.",
 cuando_lo_uso="Como primer paso de tomar la decisión, con todo lo que "
        "ya juntaste en 12.1.",
 cuando_no=None,
 ejemplo="Con un proyecto de color y dos cartas por venir, tu equity "
        "ronda el 36% (regla del 4, N6) contra un rango que no tiene "
        "ese color hecho todavía.",
 error_comun="Pasar directo a decidir sin poner un número aproximado a "
        "tu equity real.",
 idea_clave="Primer paso de decidir: ¿cuál es, aproximadamente, mi "
        "equity?",
),

"T261": dict(  # ¿Cuál es el tamaño del bote?
 que_es="El segundo paso: leer cuánto hay en el bote en este momento "
        "(N6, T112).",
 por_que_importa="Es el dato base para calcular pot odds y equity "
        "necesaria más adelante.",
 como_funciona="Sumá todo lo que ya está en el medio, incluida "
        "cualquier apuesta que estés enfrentando.",
 cuando_lo_uso="Como segundo paso de tomar la decisión.",
 cuando_no=None,
 ejemplo="El bote actual, con la apuesta del rival ya adentro, es de "
        "8 BB.",
 error_comun="Olvidarse de sumar la apuesta que estás enfrentando "
        "dentro del bote actual.",
 idea_clave="Segundo paso de decidir: ¿cuánto hay en el bote ahora "
        "mismo?",
),

"T262": dict(  # ¿Cuánto cuesta mi decisión?
 que_es="El tercer paso: calcular el precio del call (N6, T111) o "
        "cuánto costaría cada otra opción que estés considerando.",
 por_que_importa="Es el otro dato base, junto al tamaño del bote, para "
        "las próximas preguntas del checklist.",
 como_funciona="Si estás pensando en pagar, es el tamaño de la "
        "apuesta del rival. Si estás pensando en subir, es cuánto vas "
        "a poner de más.",
 cuando_lo_uso="Como tercer paso de tomar la decisión.",
 cuando_no=None,
 ejemplo="El rival apostó 4 BB: eso es lo que cuesta la opción de "
        "pagar.",
 error_comun="Confundir el costo de tu decisión con el tamaño total "
        "del bote.",
 idea_clave="Tercer paso de decidir: ¿cuánto me cuesta cada opción?",
),

"T263": dict(  # ¿Qué opciones tengo?
 que_es="El cuarto paso: enumerar TODAS las acciones legales "
        "disponibles en este momento (fold, call, raise, y con qué "
        "tamaños razonables).",
 por_que_importa="Antes de comparar cuál es mejor (T264), necesitás "
        "tener claro el menú completo de opciones reales.",
 como_funciona="Listá, sin todavía elegir, cada acción posible: "
        "foldear, pagar, o subir (y con qué tamaño tendría sentido "
        "subir, si es una opción).",
 cuando_lo_uso="Como cuarto paso de tomar la decisión, antes de "
        "comparar el EV de cada una.",
 cuando_no=None,
 ejemplo="Frente a una c-bet: tus opciones son foldear, pagar, o "
        "subir (check-raise si ya habías pasado, o raise directo).",
 error_comun="Saltarte alguna opción razonable (como subir) por ir "
        "directo a 'pago o foldeo'.",
 idea_clave="Cuarto paso de decidir: ¿cuáles son, en concreto, todas "
        "mis opciones?",
),

"T264": dict(  # ¿Cuál tiene mejor EV?
 que_es="El quinto paso: comparar el EV (N6) aproximado de cada opción "
        "que enumeraste (T263) y quedarte con la de mejor EV.",
 por_que_importa="Es el corazón del checklist: todo lo anterior (mano, "
        "board, rango, equity, bote, precio, opciones) existe para "
        "llegar a esta comparación.",
 como_funciona="Para cada opción, estimá su EV usando tu equity "
        "(T260) y los números del bote (T261-T262), como ya sabés "
        "hacer desde N6.",
 cuando_lo_uso="Como quinto paso de tomar la decisión, el paso central "
        "del checklist.",
 cuando_no=None,
 ejemplo="Pagar tiene EV +0.32 BB (N6); foldear tiene EV 0. Entre esas "
        "dos, pagar tiene mejor EV en este ejemplo.",
 error_comun="Elegir la opción que 'se siente mejor' en vez de la que "
        "tiene mejor EV calculado.",
 idea_clave="Quinto paso de decidir: ¿cuál opción, en números, suma "
        "más fichas en promedio?",
),

"T265": dict(  # ¿Qué aporta la acción del rival?
 que_es="El sexto paso: sumar lo que la línea completa del rival (N10) "
        "te dice sobre su rango, antes de la decisión final.",
 por_que_importa="El EV calculado en T264 depende de qué tan bien "
        "estimaste el rango del rival — esta pregunta te hace revisar "
        "si tenés en cuenta TODA la información de su línea.",
 como_funciona="Repasá la línea completa (N10, T220-T221): ¿la acción "
        "del rival cuenta una historia coherente de valor o de farol? "
        "Ajustá tu estimación de rango si hace falta.",
 cuando_lo_uso="Como sexto paso, revisando el cálculo anterior con la "
        "lectura de línea completa.",
 cuando_no=None,
 ejemplo="Si la línea del rival no encaja con valor (T223), tu "
        "estimación de equity contra su rango probablemente debería "
        "ser más alta de lo que calculaste con un rango genérico.",
 error_comun="Calcular el EV con un rango genérico de esa posición, "
        "sin ajustar por la línea completa y específica que jugó el "
        "rival en esta mano.",
 idea_clave="Sexto paso de decidir: ¿la línea completa del rival "
        "cambia mi estimación de su rango?",
),

"T266": dict(  # ¿Qué cambia si aparece cierta carta?
 que_es="El séptimo paso: pensar hacia adelante — si hay más calles "
        "por venir, ¿qué cartas cambiarían la decisión en la próxima "
        "ronda?",
 por_que_importa="Una buena decisión no piensa solo en la calle "
        "actual: anticipa cómo vas a reaccionar según lo que traiga la "
        "próxima carta (N9, T187-T190).",
 como_funciona="Identificá qué cartas serían buenas para vos, cuáles "
        "para el rival, y cuáles blanks — como ya sabés hacer desde N9 "
        "— para tener un plan armado de antemano.",
 cuando_lo_uso="En cualquier decisión donde todavía queden calles por "
        "jugar (flop o turn, no en el río).",
 cuando_no="En el río, donde ya no quedan más cartas (N9, T198).",
 ejemplo="Si pagás con un proyecto de color, ya sabés de antemano: "
        "'si sale una carta de mi palo en el turn, sigo fuerte; si no, "
        "reevalúo con la regla del 2'.",
 error_comun="Llegar a la próxima calle sin haber pensado de antemano "
        "cómo ibas a reaccionar según la carta que saliera.",
 idea_clave="Séptimo paso de decidir: ¿tengo un plan para lo que "
        "pueda venir?",
),

"T267": dict(  # Elegir la acción
 que_es="El octavo paso: con todo lo anterior ya trabajado, ejecutar "
        "finalmente la acción elegida.",
 por_que_importa="Es el momento en que todo el checklist se convierte "
        "en una acción concreta sobre la mesa.",
 como_funciona="Tomás la opción que identificaste con mejor EV (T264), "
        "ya ajustada por la lectura de línea (T265) y con un plan para "
        "las calles siguientes (T266).",
 cuando_lo_uso="Como paso final de cada decisión, después de haber "
        "recorrido todo el checklist.",
 cuando_no=None,
 ejemplo="Después de todo el análisis, la acción elegida es pagar — "
        "ejecutás esa decisión con la confianza de haberla pensado "
        "completa.",
 error_comun="Dudar en el último momento y cambiar de decisión sin "
        "ningún dato nuevo que justifique el cambio.",
 idea_clave="Octavo paso de decidir: ejecutá la acción que el análisis "
        "completo indicó.",
),

"T268": dict(  # Revisar el resultado
 que_es="El noveno paso, después de que la mano terminó: revisar qué "
        "pasó, con la cabeza fría.",
 por_que_importa="Revisar tus manos es cómo mejorás con el tiempo — "
        "pero solo si lo hacés de la forma correcta, que es el tema de "
        "la última pregunta (T269).",
 como_funciona="Repasá la mano completa: qué viste, qué decidiste, y "
        "qué terminó pasando, sin todavía juzgar si estuvo bien o mal.",
 cuando_lo_uso="Después de que termina cada mano importante, como "
        "hábito de revisión.",
 cuando_no=None,
 ejemplo="Perdiste la mano del ejemplo (pagaste con 36% de equity y no "
        "completaste): revisarla es mirar de nuevo cada paso del "
        "checklist, no solo el resultado final.",
 error_comun="Revisar una mano solo cuando salió mal, ignorando las "
        "que salieron bien pero quizás se decidieron peor.",
 idea_clave="Noveno paso: revisar la mano completa después de que "
        "terminó, con calma.",
),

"T269": dict(  # Separar el resultado de la calidad de la decisión
 que_es="El décimo y último paso del checklist: juzgar tu decisión por "
        "su calidad (¿tenía buen EV con la información de ese momento?), "
        "no por si esa mano puntual salió bien o mal.",
 por_que_importa="Es la idea más importante de todo el checklist (ya "
        "vista en N6, T127): una decisión correcta puede perder la "
        "mano, y una decisión incorrecta puede ganarla. Confundir "
        "ambas cosas es el error que más frena el progreso.",
 como_funciona="Preguntate: '¿con la información que tenía en ese "
        "momento, era la decisión de mejor EV?' — esa pregunta se "
        "responde igual, gane o pierda esa mano en particular.",
 cuando_lo_uso="Como cierre de cada revisión de mano (T268), siempre.",
 cuando_no=None,
 ejemplo="Pagaste con 36% de equity (call +EV, N6) y perdiste esa mano "
        "puntual: la decisión siguió siendo correcta. El resultado de "
        "esa mano no la cambia.",
 error_comun="Concluir 'jugué mal' solo porque perdiste la mano, sin "
        "revisar si la decisión, en el momento, tenía buen EV.",
 idea_clave="Último paso del checklist: juzgá la decisión por su EV en "
        "el momento, no por el resultado de esa mano puntual.",
),

# ============================================================
# 12.3 — Integrar el preflop
# ============================================================

"T288": dict(  # Integrar: el RFI preflop
 que_es="Aplicar el checklist completo (12.1-12.2) a la decisión de "
        "abrir (RFI, N5): posición, mano, rango de apertura, y la "
        "acción que corresponde.",
 por_que_importa="Es la primera aplicación práctica de todo lo que "
        "veníamos armando por separado: acá se ve cómo el checklist "
        "resuelve una decisión real de punta a punta.",
 como_funciona="Posición (T253) → mano (T254) → ¿llegó limpio? (T255) "
        "→ tu rango de apertura para esa posición (N5) → abrís o "
        "foldeás.",
 cuando_lo_uso="Cada vez que te toca decidir si abrís, aplicando el "
        "checklist en vez de decidir 'a ojo'.",
 cuando_no=None,
 ejemplo="Botón, con K♠J♠, nadie entró antes: el checklist confirma "
        "que esa mano entra en tu rango de apertura del botón — abrís.",
 error_comun="Saltarte pasos del checklist en decisiones que ya te "
        "parecen 'obvias' — justo ahí es donde se filtran los errores "
        "por costumbre.",
 idea_clave="El checklist aplicado al RFI: posición + mano + rango de "
        "apertura = la decisión.",
),

"T289": dict(  # Integrar: jugar contra un open
 que_es="Aplicar el checklist completo a la decisión de responder a un "
        "open (N7): call, fold o 3-bet.",
 por_que_importa="Es la misma estructura que T288, pero desde el lado "
        "de quien responde, sumando el rango del rival (T256) a la "
        "ecuación.",
 como_funciona="Posición tuya y del que abrió → tu mano → rango de "
        "apertura del rival según su posición → tu rango de call/3-bet "
        "contra ese rango → la decisión.",
 cuando_lo_uso="Cada vez que alguien abre antes que vos.",
 cuando_no=None,
 ejemplo="El CO abre, estás en el botón con A♠K♠: el checklist "
        "confirma que esa mano entra en tu rango de 3-bet contra el "
        "rango de apertura del CO.",
 error_comun="Responder a un open mirando solo tu mano, sin construir "
        "el rango del rival según su posición.",
 idea_clave="El checklist aplicado a responder un open: tu mano contra "
        "SU rango, no en el aire.",
),

"T290": dict(  # Integrar: la defensa de BB
 que_es="Aplicar el checklist completo a la defensa de la ciega grande "
        "(N7), un caso particular de T289 con su propia lógica de "
        "posición.",
 por_que_importa="La BB tiene su propia lógica (siempre fuera de "
        "posición postflop, pero con mejor precio preflop): merece su "
        "propia aplicación del checklist.",
 como_funciona="Igual que T289, pero con la posición fija de la BB: "
        "peor precio en información futura, pero mejor precio en pot "
        "odds por la ciega ya puesta.",
 cuando_lo_uso="Cada vez que te toca decidir desde la BB frente a un "
        "open o un limp.",
 cuando_no=None,
 ejemplo="El botón abre y estás en la BB: el checklist pesa tanto el "
        "buen precio (pot odds) como el hecho de que vas a jugar el "
        "resto de la mano fuera de posición.",
 error_comun="Defender la BB solo por el buen precio, sin pesar el "
        "costo de jugar fuera de posición el resto de la mano.",
 idea_clave="El checklist aplicado a la BB: buen precio ahora, pero "
        "fuera de posición después — los dos pesan.",
),

"T291": dict(  # Integrar: la 3-bet
 que_es="Aplicar el checklist completo a la decisión de 3-betear (N7): "
        "por valor, como farol, o ninguna de las dos.",
 por_que_importa="Cierra el checklist preflop: junta rango de "
        "apertura del rival, tu rango de 3-bet (valor + farol, N7) y "
        "la posición de ambos.",
 como_funciona="Rango de apertura del rival → tu mano comparada contra "
        "ese rango → ¿entra en tu rango de 3-bet por valor, por farol, "
        "o en ninguno? → la decisión.",
 cuando_lo_uso="Cada vez que estás considerando 3-betear un open.",
 cuando_no=None,
 ejemplo="El HJ abre y tenés K♠K♦ en el botón: el checklist confirma "
        "que es una 3-bet por valor clara.",
 error_comun="3-betear 'porque la mano se ve fuerte', sin pasar por el "
        "checklist completo de rango del rival y tu propio rango de "
        "3-bet.",
 idea_clave="El checklist aplicado a la 3-bet: rango del rival + tu "
        "rango de 3-bet = la decisión.",
),

# ============================================================
# 12.4 — Integrar el postflop
# ============================================================

"T292": dict(  # Integrar: un bote 3-bet
 que_es="Aplicar el checklist completo a jugar el flop de un bote "
        "3-bet (N7): con SPR bajo y el rango de ambos ya más acotado.",
 por_que_importa="Un bote 3-bet se juega distinto (N7, T164-T169): el "
        "checklist tiene que reflejar ese SPR bajo y esos rangos más "
        "concentrados.",
 como_funciona="Aplicás el checklist completo (12.1-12.2), teniendo en "
        "cuenta que el SPR bajo acerca las decisiones a 'ir por todo el "
        "stack o no' (N11, T229) más rápido que en un bote normal.",
 cuando_lo_uso="Cada vez que llegás al flop de una mano donde hubo una "
        "3-bet preflop.",
 cuando_no=None,
 ejemplo="Con SPR 3 en un bote 3-bet, una mano 'buena pero no la "
        "mejor posible' como top pair ya puede querer ir por todo el "
        "stack — el checklist lo confirma con el SPR bajo.",
 error_comun="Jugar un bote 3-bet con la misma cabeza que un bote "
        "normal, ignorando el SPR distinto.",
 idea_clave="El checklist en un bote 3-bet: SPR bajo, decisiones de "
        "stack más cercanas de lo habitual.",
),

"T293": dict(  # Integrar: un bote single-raised
 que_es="Aplicar el checklist completo a jugar el flop de un bote "
        "single-raised (una sola subida preflop, sin 3-bet) — el caso "
        "más común de todos.",
 por_que_importa="Es el bote más frecuente del juego: con SPR más "
        "alto que un bote 3-bet, hay más margen para decisiones finas "
        "en varias calles.",
 como_funciona="Aplicás el checklist completo, con un SPR más alto que "
        "en T292: hay más lugar para pot control (N9), floats (N8) y "
        "decisiones más graduales.",
 cuando_lo_uso="Cada vez que llegás al flop de una mano donde hubo una "
        "sola subida preflop.",
 cuando_no=None,
 ejemplo="Con SPR 15 en un bote single-raised, una mano media puede "
        "preferir pot control (N9) en vez de comprometerse de una — "
        "hay mucho más margen que en un bote 3-bet.",
 error_comun="Jugar un bote single-raised con la urgencia de un bote "
        "3-bet, sin aprovechar el margen extra que da el SPR más alto.",
 idea_clave="El checklist en un bote single-raised: SPR más alto, más "
        "margen para decisiones graduales.",
),

"T294": dict(  # Integrar: la c-bet
 que_es="Aplicar el checklist completo a la decisión de c-betear "
        "(N8): iniciativa, board, posición y multiway, todo junto.",
 por_que_importa="Junta las cuatro variables de N8 (por qué c-betear, "
        "según el board, según la posición, con qué frecuencia) en una "
        "sola decisión concreta.",
 como_funciona="¿Tenés la iniciativa? → tipo de board (seco/"
        "coordinado) → posición (en posición/fuera) → ¿multiway? → "
        "frecuencia y tamaño resultantes (N8, 8.5).",
 cuando_lo_uso="Cada vez que llegás al flop con la iniciativa.",
 cuando_no=None,
 ejemplo="Iniciativa + board seco + en posición + heads-up: el "
        "checklist da una c-bet frecuente y de tamaño chico.",
 error_comun="C-betear con una frecuencia fija sin ajustar por las "
        "cuatro variables que ya estudiaste por separado en N8.",
 idea_clave="El checklist de la c-bet: iniciativa + board + posición + "
        "cantidad de rivales, todo junto.",
),

"T295": dict(  # Integrar: el check-back
 que_es="Aplicar el checklist completo a la decisión de pasar detrás "
        "en vez de c-betear.",
 por_que_importa="Es el reverso de T294: reconocer cuándo el checklist "
        "apunta a NO apostar, con la misma solidez que cuando apunta a "
        "apostar.",
 como_funciona="Las mismas variables de T294, pero cuando el resultado "
        "es 'no c-beteo esta vez': board muy coordinado, fuera de "
        "posición, multiway, mano sin valor ni buen proyecto.",
 cuando_lo_uso="Cada vez que el checklist, aplicado a la c-bet, no "
        "justifica apostar.",
 cuando_no=None,
 ejemplo="Board muy coordinado, fuera de posición, multiway, mano sin "
        "nada: el checklist apunta claramente a pasar en vez de "
        "c-betear.",
 error_comun="C-betear 'por costumbre' incluso cuando el checklist "
        "completo apunta a pasar.",
 idea_clave="El check-back también es una conclusión válida del "
        "checklist, no una excepción.",
),

"T296": dict(  # Integrar: jugar un proyecto en el flop
 que_es="Aplicar el checklist completo a una mano con proyecto en el "
        "flop: contar outs, estimar equity, y decidir entre c-bet con "
        "proyecto (N8), pagar, o foldear.",
 por_que_importa="Es una de las decisiones más frecuentes del juego: "
        "el checklist evita jugarla 'a sentimiento'.",
 como_funciona="Contás outs (N6) → estimás equity (regla del 4) → "
        "leés el bote y el precio → comparás contra tus opciones (c-bet "
        "con proyecto, pagar, foldear) → elegís la de mejor EV.",
 cuando_lo_uso="Cada vez que tenés un proyecto en el flop, sin mano "
        "hecha todavía.",
 cuando_no=None,
 ejemplo="Proyecto de color de 9 outs (equity ≈36%, regla del 4) en un "
        "board donde también tenés la iniciativa: el checklist suele "
        "apuntar a c-betear con ese proyecto.",
 error_comun="Jugar un proyecto solo por 'sentirlo fuerte', sin el "
        "cálculo de outs y equity que el checklist pide.",
 idea_clave="Jugar un proyecto en el flop: outs + equity + bote + "
        "precio, no sensación.",
),

"T297": dict(  # Integrar: jugar una mano hecha en el flop
 que_es="Aplicar el checklist completo a una mano ya hecha en el "
        "flop: clasificarla (N4), estimar contra qué rango compite, y "
        "decidir entre c-bet por valor, check para pot control, u otra "
        "opción.",
 por_que_importa="Una mano hecha no siempre 'se apuesta sola': el "
        "checklist te hace revisar si de verdad conviene apostar por "
        "valor o si el pot control (N9) es mejor en esa situación "
        "puntual.",
 como_funciona="Clasificás tu mano hecha (top pair, set, etc.) → "
        "estimás contra qué parte del rango del rival compite → "
        "¿tenés manos peores reales que paguen? (N8, T177) → decidís.",
 cuando_lo_uso="Cada vez que tenés una mano ya hecha en el flop.",
 cuando_no=None,
 ejemplo="Top pair con buen kicker contra un rango con varias manos "
        "peores: el checklist confirma una c-bet por valor. Top pair "
        "débil contra un rango fuerte: puede apuntar a pot control en "
        "vez de apostar grande.",
 error_comun="Apostar automáticamente cualquier 'mano hecha' sin "
        "revisar si el rango del rival realmente tiene manos peores "
        "dispuestas a pagar.",
 idea_clave="Jugar una mano hecha: clasificarla, comparar contra el "
        "rango real del rival, y recién ahí decidir.",
),

"T298": dict(  # Integrar: el segundo barrel en el turn
 que_es="Aplicar el checklist completo a la decisión de seguir "
        "apostando en el turn (double barrel, N9) después de haber "
        "c-beteado el flop.",
 por_que_importa="Cada barrel es una decisión nueva, no una "
        "continuación automática: el checklist revisa si la carta del "
        "turn (N9, T187-T190) sigue apoyando seguir apostando.",
 como_funciona="Revisás la carta del turn (¿buena para vos, para el "
        "rival, blank, scare card?) → actualizás tu equity → "
        "recalculás el EV de seguir apostando contra pasar (T193).",
 cuando_lo_uso="Cada vez que ya c-beteaste el flop y llega el turn.",
 cuando_no=None,
 ejemplo="C-beteaste el flop, el turn es un blank: el checklist "
        "confirma que seguir con el double barrel sigue teniendo "
        "sentido, porque nada cambió en contra tuyo.",
 error_comun="Hacer double barrel en piloto automático sin revisar si "
        "la carta del turn cambió el panorama.",
 idea_clave="El segundo barrel se decide de nuevo en cada turn, no se "
        "hace por inercia.",
),

"T299": dict(  # Integrar: el check en el turn
 que_es="Aplicar el checklist completo a la decisión de pasar en el "
        "turn (N9, T193) en vez de seguir con el barrel.",
 por_que_importa="Es el reverso de T298: reconocer cuándo el checklist "
        "apunta a frenar, ya sea porque la carta favoreció al rival o "
        "porque tu mano quiere pot control.",
 como_funciona="Mismas variables que T298, pero cuando el resultado es "
        "'no sigo apostando': carta que favorece al rival, o mano media "
        "que prefiere mantener el bote chico (N9, T195).",
 cuando_lo_uso="Cada vez que el checklist, aplicado al turn, no "
        "justifica seguir apostando.",
 cuando_no=None,
 ejemplo="C-beteaste el flop con un farol y el turn trae una scare "
        "card (N9) que favorece al rango del rival: el checklist "
        "apunta a pasar en vez de insistir con el double barrel.",
 error_comun="Sentir que 'ya invertiste con la c-bet' y por eso tenés "
        "que seguir apostando el turn sin importar la carta que salió.",
 idea_clave="Pasar en el turn también es una conclusión válida del "
        "checklist, no una rendición.",
),

}
