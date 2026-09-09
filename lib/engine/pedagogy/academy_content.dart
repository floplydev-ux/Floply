import '../concepts/concept_ids.dart';
import 'lesson_content.dart';

/// El contenido pedagógico de los niveles 1 a 5 de la Academia.
///
/// Todo el texto que enseña vive acá (no en widgets). Cada entrada está
/// atada al id de un [Lesson] del [Curriculum]. La teoría es corta y
/// progresiva y no adelanta conceptos avanzados (GTO, equity, blockers…):
/// solo lo que el nivel necesita.
class AcademyContent {
  AcademyContent._();

  static LessonContent? forLesson(String lessonId) => _byId[lessonId];

  static bool has(String lessonId) => _byId.containsKey(lessonId);

  static final Map<String, LessonContent> _byId = {
    // ===========================================================
    // NIVEL 1 — FUNDAMENTOS (concepto: reglas)
    // ===========================================================
    '1.1': const LessonContent(
      objective: 'Entender cómo se juega una mano de Texas Hold\'em.',
      theory: [
        TheoryBlock.concept(
          'Texas Hold\'em se juega con dos cartas privadas para cada '
          'jugador y cinco cartas comunitarias en el centro de la mesa.',
        ),
        TheoryBlock.explanation(
          'El objetivo de una mano es llevarse el bote: las fichas que '
          'todos apostaron. Lo ganás de dos maneras: mostrando la mejor '
          'combinación de cinco cartas en el showdown, o haciendo que '
          'todos los demás se retiren (fold) antes.',
        ),
        TheoryBlock.explanation(
          'Cada jugador tiene un stack (sus fichas en la mesa). Antes de '
          'ver cartas, dos jugadores ponen apuestas obligatorias: la '
          'ciega chica (SB) y la ciega grande (BB). Eso arranca el bote y '
          'obliga a jugar.',
        ),
        TheoryBlock.example(
          'Con ciegas de 1/2: la SB pone 1, la BB pone 2. Ya hay 3 en el '
          'bote antes de que nadie decida nada.',
        ),
        TheoryBlock.keyPoint(
          'Ganás el bote con la mejor mano en el showdown o haciendo '
          'foldear a todos. Las ciegas obligan a que siempre haya algo '
          'en juego.',
        ),
      ],
      checks: [
        ComprehensionCheck(
          prompt: '¿De cuántas maneras podés ganar el bote?',
          options: [
            'Solo mostrando la mejor mano en el showdown',
            'Mostrando la mejor mano o haciendo foldear a todos',
            'Solo haciendo foldear a todos',
          ],
          correctIndex: 1,
          explanation:
              'Ganás en el showdown con la mejor mano, o antes si todos '
              'los demás se retiran.',
          concept: ConceptIds.rules,
        ),
      ],
    ),
    '1.2': const LessonContent(
      objective: 'Reconocer stack, ciegas y bote en una mano.',
      intro: 'Repasá lo que acabás de leer con estas situaciones.',
      checks: [
        ComprehensionCheck(
          prompt: 'El "stack" de un jugador es…',
          options: [
            'El total de fichas que tiene disponibles en la mesa',
            'Las cartas comunitarias',
            'La apuesta obligatoria más grande',
          ],
          correctIndex: 0,
          explanation: 'El stack son tus fichas: lo máximo que podés '
              'apostar o perder en esa mano.',
          concept: ConceptIds.rules,
        ),
        ComprehensionCheck(
          prompt: 'Ciegas 2/5. Nadie apostó todavía. ¿Cuánto hay en el bote?',
          options: ['5', '7', '10'],
          correctIndex: 1,
          explanation: 'SB (2) + BB (5) = 7 en el bote antes de la primera '
              'decisión.',
          concept: ConceptIds.rules,
        ),
        ComprehensionCheck(
          prompt: '¿Para qué sirven las ciegas?',
          options: [
            'Para que siempre haya fichas en juego y la mano avance',
            'Para premiar al que va ganando',
            'Para pagar a la casa',
          ],
          correctIndex: 0,
          explanation: 'Sin ciegas nadie estaría obligado a poner fichas y '
              'todos esperarían solo manos enormes.',
          concept: ConceptIds.rules,
        ),
        ComprehensionCheck(
          prompt: 'Si tu stack es 40bb y perdés toda la mano, ¿cuánto perdés '
              'como máximo?',
          options: ['40bb', 'Todo lo que tengas fuera de la mesa también', '2bb'],
          correctIndex: 0,
          explanation: 'Solo arriesgás lo que tenés en la mesa: 40bb.',
          concept: ConceptIds.rules,
        ),
      ],
    ),
    '1.3': const LessonContent(
      objective: 'Ordenar las calles y reconocer las acciones básicas.',
      theory: [
        TheoryBlock.explanation(
          'Una mano tiene cuatro calles: preflop (solo tus dos cartas), '
          'flop (3 cartas comunitarias), turn (la 4ª) y river (la 5ª). '
          'En cada calle hay una ronda de apuestas.',
        ),
        TheoryBlock.explanation(
          'En tu turno podés: foldear (tirar la mano), pasar/check (no '
          'apostar si nadie apostó), igualar/call (pagar la apuesta), '
          'apostar/bet o subir/raise (poner más).',
        ),
        TheoryBlock.keyPoint(
          'Preflop → flop → turn → river → showdown. En cada calle, una '
          'ronda de apuestas.',
        ),
      ],
      checks: [
        ComprehensionCheck(
          prompt: '¿Qué calle viene justo después del flop?',
          options: ['El river', 'El turn', 'El preflop'],
          correctIndex: 1,
          explanation: 'Preflop → flop → turn → river.',
          concept: ConceptIds.rules,
        ),
        ComprehensionCheck(
          prompt: 'Nadie apostó y no querés poner fichas. ¿Qué acción usás?',
          options: ['Fold', 'Check', 'Call'],
          correctIndex: 1,
          explanation: 'Check es pasar sin apostar cuando no hay apuesta '
              'delante. Foldear acá sería tirar la mano gratis.',
          concept: ConceptIds.rules,
        ),
        ComprehensionCheck(
          prompt: 'Hay una apuesta de 5 y querés seguir sin subir. ¿Qué hacés?',
          options: ['Check', 'Call de 5', 'Bet de 5'],
          correctIndex: 1,
          explanation: 'Igualar (call) es pagar exactamente la apuesta que '
              'tenés delante para seguir en la mano.',
          concept: ConceptIds.rules,
        ),
        ComprehensionCheck(
          prompt: '¿Cuántas cartas comunitarias hay en el river?',
          options: ['3', '4', '5'],
          correctIndex: 2,
          explanation: 'Flop 3, turn 4, river 5 cartas comunitarias.',
          concept: ConceptIds.rules,
        ),
      ],
    ),
    '1.4': const LessonContent(
      objective: 'Seguir una mano completa de principio a fin.',
      intro: 'Seguí esta mano paso a paso y respondé.',
      checks: [
        ComprehensionCheck(
          prompt: 'Preflop: la BB sube, todos foldean menos vos, que igualás. '
              '¿Qué viene ahora?',
          options: ['El showdown', 'El flop (3 cartas)', 'El turn'],
          correctIndex: 1,
          explanation: 'Cerrada la apuesta preflop, se reparte el flop.',
          concept: ConceptIds.rules,
        ),
        ComprehensionCheck(
          prompt: 'En el flop tu rival apuesta y vos foldeás. ¿Qué pasa?',
          options: [
            'Se juega igual el turn',
            'Tu rival gana el bote ahí mismo',
            'Van al showdown',
          ],
          correctIndex: 1,
          explanation: 'Si te retirás, tu rival se lleva el bote sin '
              'mostrar cartas.',
          concept: ConceptIds.rules,
        ),
        ComprehensionCheck(
          prompt: 'Otra mano: llegan los dos al river sin foldear. ¿Cómo se '
              'decide el bote?',
          options: [
            'Lo gana quien apostó último',
            'Se reparte siempre a la mitad',
            'Showdown: gana la mejor mano de cinco cartas',
          ],
          correctIndex: 2,
          explanation: 'Si nadie se retiró, se muestran las cartas y gana '
              'la mejor combinación.',
          concept: ConceptIds.rules,
        ),
        ComprehensionCheck(
          prompt: '¿En qué calle se puede ganar el bote sin llegar al '
              'showdown?',
          options: ['En cualquiera, si el rival foldea', 'Solo en el river', 'Nunca'],
          correctIndex: 0,
          explanation: 'En cuanto todos menos uno se retiran, la mano '
              'termina, sea preflop, flop, turn o river.',
          concept: ConceptIds.rules,
        ),
      ],
    ),
    '1.5': const LessonContent(
      objective: 'Demostrar que entendés cómo funciona una mano.',
      intro: 'Evaluación del nivel. Necesitás 70% para aprobar.',
      checks: [
        ComprehensionCheck(
          prompt: '¿Qué es el bote?',
          options: [
            'Las fichas apostadas que se lleva el ganador de la mano',
            'Las cartas comunitarias',
            'El stack del jugador en el botón',
          ],
          correctIndex: 0,
          explanation: 'El bote es todo lo apostado; lo gana quien gana la '
              'mano.',
          concept: ConceptIds.rules,
        ),
        ComprehensionCheck(
          prompt: 'Orden correcto de las calles:',
          options: [
            'Preflop, turn, flop, river',
            'Preflop, flop, turn, river',
            'Flop, preflop, turn, river',
          ],
          correctIndex: 1,
          explanation: 'Preflop → flop → turn → river.',
          concept: ConceptIds.rules,
        ),
        ComprehensionCheck(
          prompt: 'No hay apuesta delante tuyo y no querés apostar. Acción:',
          options: ['Fold', 'Call', 'Check'],
          correctIndex: 2,
          explanation: 'Check: pasás sin poner fichas.',
          concept: ConceptIds.rules,
        ),
        ComprehensionCheck(
          prompt: '¿Cómo NO se puede ganar una mano?',
          options: [
            'Haciendo foldear a todos los rivales',
            'Teniendo la mejor mano en el showdown',
            'Siendo el primero en actuar preflop',
          ],
          correctIndex: 2,
          explanation: 'La posición no gana botes por sí sola: ganás por '
              'showdown o por folds.',
          concept: ConceptIds.rules,
        ),
        ComprehensionCheck(
          prompt: 'Las ciegas (SB y BB) son…',
          options: [
            'Apuestas obligatorias antes de repartir cartas',
            'Premios para el ganador',
            'Cartas comunitarias',
          ],
          correctIndex: 0,
          explanation: 'Son apuestas forzadas que arrancan el bote.',
          concept: ConceptIds.rules,
        ),
      ],
    ),

    // ===========================================================
    // NIVEL 2 — RANKING DE MANOS (concepto: hand_ranking)
    // ===========================================================
    '2.1': const LessonContent(
      objective: 'Reconocer la jerarquía de las manos de póker.',
      theory: [
        TheoryBlock.concept(
          'Todas las manos de póker se ordenan en una jerarquía fija. '
          'Cuando dos jugadores llegan al showdown, gana la que esté más '
          'arriba.',
        ),
        TheoryBlock.explanation(
          'De más débil a más fuerte: carta alta, pareja, doble pareja, '
          'trío, escalera (5 seguidas), color (5 del mismo palo), full '
          '(trío + pareja), póker (4 iguales) y escalera de color.',
        ),
        TheoryBlock.example(
          'Un color siempre le gana a una escalera. Un full siempre le '
          'gana a un color. No importa qué cartas altas tenga la mano '
          'más baja: la categoría manda primero.',
        ),
        TheoryBlock.keyPoint(
          'Primero decide la categoría. Solo si los dos tienen la misma '
          'categoría se mira quién la tiene más alta.',
        ),
      ],
      checks: [
        ComprehensionCheck(
          prompt: '¿Qué gana: un color o una escalera?',
          options: ['La escalera', 'El color', 'Empatan'],
          correctIndex: 1,
          explanation: 'El color está más arriba que la escalera en la '
              'jerarquía.',
          concept: ConceptIds.handRanking,
        ),
      ],
    ),
    '2.2': const LessonContent(
      objective: 'Comparar dos manos de categorías distintas.',
      intro: 'Cada ejercicio te muestra dos manos: elegí la que gana.',
      practice: PracticeSpec(
        targetConcept: ConceptIds.handRanking,
        difficulty: 1,
        exerciseCount: 5,
      ),
    ),
    '2.3': const LessonContent(
      objective: 'Distinguir manos cercanas en la jerarquía.',
      intro: 'Ahora las manos están más cerca entre sí. Fijate bien.',
      practice: PracticeSpec(
        targetConcept: ConceptIds.handRanking,
        difficulty: 2,
        exerciseCount: 5,
      ),
    ),
    '2.4': const LessonContent(
      objective: 'Comparar manos vecinas sin dudar.',
      intro: 'Challenge: categorías consecutivas.',
      practice: PracticeSpec(
        targetConcept: ConceptIds.handRanking,
        difficulty: 3,
        exerciseCount: 5,
      ),
    ),
    '2.5': const LessonContent(
      objective: 'Demostrar que dominás el ranking de manos.',
      intro: 'Evaluación del nivel. Necesitás 70% para aprobar.',
      practice: PracticeSpec(
        targetConcept: ConceptIds.handRanking,
        difficulty: 2,
        exerciseCount: 6,
      ),
    ),

    // ===========================================================
    // NIVEL 3 — POSICIÓN
    // ===========================================================
    '3.1': const LessonContent(
      objective: 'Nombrar las 6 posiciones de una mesa 6-max y su orden.',
      theory: [
        TheoryBlock.concept(
          'En 6-max hay seis posiciones, definidas por dónde está el '
          'botón (BTN), que rota una silla por mano.',
        ),
        TheoryBlock.explanation(
          'En orden de acción preflop: UTG (primero), HJ (hijack), CO '
          '(cutoff), BTN (botón), SB (ciega chica) y BB (ciega grande, '
          'última).',
        ),
        TheoryBlock.explanation(
          'La SB y la BB son "las ciegas": ya pusieron fichas y postflop '
          'actúan primeras, en desventaja.',
        ),
        TheoryBlock.example(
          'Si todos foldean hasta el BTN, quedan BTN, SB y BB. El BTN es '
          'el que mejor la tiene: actúa último en el flop, turn y river.',
        ),
        TheoryBlock.keyPoint(
          'Orden preflop: UTG → HJ → CO → BTN → SB → BB.',
        ),
      ],
      checks: [
        ComprehensionCheck(
          prompt: '¿Quién actúa primero en el preflop?',
          options: ['La BB', 'El BTN', 'UTG'],
          correctIndex: 2,
          explanation: 'UTG ("under the gun") abre la acción preflop.',
          concept: ConceptIds.positionNames,
        ),
      ],
    ),
    '3.2': const LessonContent(
      objective: 'Ubicar cada posición en el orden de acción preflop.',
      intro: 'Ejercicios sobre quién habla antes y quién después.',
      practice: PracticeSpec(
        targetConcept: ConceptIds.positionNames,
        difficulty: 1,
        exerciseCount: 5,
      ),
    ),
    '3.3': const LessonContent(
      objective: 'Entender por qué actuar último es una ventaja.',
      theory: [
        TheoryBlock.concept(
          'Las posiciones se agrupan en temprana (UTG), media (HJ, CO) y '
          'tardía (BTN). Cuanto más tarde actuás, mejor.',
        ),
        TheoryBlock.explanation(
          'La ventaja posicional es esto: si actuás último, ya viste qué '
          'hicieron los demás antes de decidir. Tenés más información y '
          'controlás el tamaño del bote.',
        ),
        TheoryBlock.explanation(
          'Actuar primero es lo contrario: decidís a ciegas y los demás '
          'reaccionan a vos con más datos.',
        ),
        TheoryBlock.keyPoint(
          'Más tarde = más información = mejores decisiones. El BTN es la '
          'mejor posición; las ciegas, las peores postflop.',
        ),
      ],
      checks: [
        ComprehensionCheck(
          prompt: '¿Por qué el BTN tiene ventaja?',
          options: [
            'Porque paga menos ciega',
            'Porque actúa último postflop y decide con más información',
            'Porque recibe mejores cartas',
          ],
          correctIndex: 1,
          explanation: 'Actuar último = ver primero lo que hacen los '
              'demás.',
          concept: ConceptIds.positionAdvantage,
        ),
      ],
    ),
    '3.4': const LessonContent(
      objective: 'Aplicar la idea de ventaja posicional a la mesa.',
      intro: 'Reforzá el orden de acción y quién tiene la ventaja.',
      practice: PracticeSpec(
        targetConcept: ConceptIds.positionNames,
        difficulty: 2,
        exerciseCount: 4,
      ),
      checks: [
        ComprehensionCheck(
          prompt: 'Entre CO y BTN, ¿quién juega con ventaja postflop?',
          options: ['CO', 'BTN', 'Ninguno, es igual'],
          correctIndex: 1,
          explanation: 'El BTN actúa después del CO en todas las calles '
              'postflop.',
          concept: ConceptIds.positionAdvantage,
        ),
        ComprehensionCheck(
          prompt: 'Actuar primero en una calle significa…',
          options: [
            'Decidir sin saber qué harán los demás',
            'Tener más información',
            'Ganar más botes',
          ],
          correctIndex: 0,
          explanation: 'El que actúa primero está en desventaja de '
              'información.',
          concept: ConceptIds.positionAdvantage,
        ),
      ],
    ),
    '3.5': const LessonContent(
      objective: 'Demostrar que entendés posición y orden de acción.',
      intro: 'Evaluación del nivel. Necesitás 70% para aprobar.',
      practice: PracticeSpec(
        targetConcept: ConceptIds.positionNames,
        difficulty: 2,
        exerciseCount: 4,
      ),
      checks: [
        ComprehensionCheck(
          prompt: '¿Cuál es la mejor posición en 6-max?',
          options: ['UTG', 'BTN', 'BB'],
          correctIndex: 1,
          explanation: 'El BTN actúa último postflop siempre.',
          concept: ConceptIds.positionAdvantage,
        ),
        ComprehensionCheck(
          prompt: 'Las ciegas, postflop, actúan…',
          options: ['Últimas', 'Primeras', 'Depende de las cartas'],
          correctIndex: 1,
          explanation: 'SB y BB abren la acción en flop, turn y river: '
              'desventaja posicional.',
          concept: ConceptIds.positionAdvantage,
        ),
      ],
    ),

    // ===========================================================
    // NIVEL 4 — RANGOS
    // ===========================================================
    '4.1': const LessonContent(
      objective: 'Entender qué es un rango y por qué se piensa en rangos.',
      theory: [
        TheoryBlock.concept(
          'Un rango es el conjunto de todas las manos con las que jugarías '
          'de cierta forma en una situación dada.',
        ),
        TheoryBlock.explanation(
          'No decidís solo mirando tus dos cartas. Un jugador que sube de '
          'entrada desde una posición tiene un "rango de apertura": las '
          'manos con las que abre desde ahí.',
        ),
        TheoryBlock.explanation(
          'Pensar en rangos sirve para dos cosas: elegir bien qué manos '
          'jugás vos, y estimar qué puede tener el rival.',
        ),
        TheoryBlock.example(
          'Desde UTG, un rango de apertura típico son manos fuertes: '
          'parejas medias-altas, ases buenos, conectores altos. AA está; '
          '72o no.',
        ),
        TheoryBlock.keyPoint(
          'Un rango = un grupo de manos, no una mano suelta. Jugás y leés '
          'en rangos.',
        ),
      ],
      checks: [
        ComprehensionCheck(
          prompt: 'Un "rango de apertura" es…',
          options: [
            'La única mano con la que se puede abrir',
            'El conjunto de manos con las que abrís desde una posición',
            'El tamaño de la subida',
          ],
          correctIndex: 1,
          explanation: 'Es un grupo de manos, definido por la posición.',
          concept: ConceptIds.openingRange,
        ),
      ],
    ),
    '4.2': const LessonContent(
      objective: 'Decidir si una mano concreta entra en el rango de apertura.',
      intro: 'Para cada mano y posición: ¿la abrís o no?',
      practice: PracticeSpec(
        targetConcept: ConceptIds.openingRange,
        difficulty: 1,
        exerciseCount: 5,
      ),
    ),
    '4.3': const LessonContent(
      objective: 'Comparar la amplitud de los rangos entre posiciones.',
      theory: [
        TheoryBlock.concept(
          'La amplitud de un rango es cuántas manos incluye. Un rango '
          '"ancho" tiene muchas; uno "cerrado", pocas y fuertes.',
        ),
        TheoryBlock.explanation(
          'Cuanto más tardía es la posición, más ancho es el rango de '
          'apertura: quedan menos jugadores por hablar, así que podés '
          'abrir manos más flojas.',
        ),
        TheoryBlock.explanation(
          'Esto también se puede decir con frecuencias: UTG abre quizá el '
          '15% de las manos; el BTN, cerca del 45%.',
        ),
        TheoryBlock.keyPoint(
          'UTG: rango cerrado. BTN: rango ancho. La posición manda.',
        ),
      ],
      checks: [
        ComprehensionCheck(
          prompt: '¿Desde dónde se abren MÁS manos?',
          options: ['UTG', 'CO', 'BTN'],
          correctIndex: 2,
          explanation: 'El BTN es la posición más tardía: rango más ancho.',
          concept: ConceptIds.rangeWidth,
        ),
      ],
    ),
    '4.4': const LessonContent(
      objective: 'Relacionar posición, amplitud de rango y fuerza de la mano.',
      intro: 'Challenge: rangos y posición juntos.',
      practice: PracticeSpec(
        targetConcept: ConceptIds.rangeWidth,
        difficulty: 3,
        exerciseCount: 5,
      ),
    ),
    '4.5': const LessonContent(
      objective: 'Demostrar que entendés los rangos de apertura.',
      intro: 'Evaluación del nivel. Necesitás 70% para aprobar.',
      practice: PracticeSpec(
        targetConcept: ConceptIds.openingRange,
        difficulty: 2,
        exerciseCount: 6,
      ),
    ),

    // ===========================================================
    // NIVEL 5 — OPEN RAISE
    // ===========================================================
    '5.1': const LessonContent(
      objective: 'Decidir entre abrir (open raise) y foldear.',
      theory: [
        TheoryBlock.concept(
          'Si nadie entró todavía al bote, tus opciones reales son dos: '
          'abrir subiendo (open raise) o foldear.',
        ),
        TheoryBlock.explanation(
          'Abrís cuando tu mano está dentro del rango de apertura de tu '
          'posición. Si queda fuera, foldeás: no se limpea (igualar la '
          'ciega) como estrategia por defecto en 6-max.',
        ),
        TheoryBlock.explanation(
          'Juntá todo lo anterior: la posición define qué tan ancho es tu '
          'rango; tu mano está dentro o fuera; y actuás en consecuencia.',
        ),
        TheoryBlock.example(
          'A♠5♠ desde el BTN: dentro del rango ancho del botón → abrís. '
          'El mismo A♠5♠ desde UTG: fuera del rango cerrado → fold.',
        ),
        TheoryBlock.keyPoint(
          'Primero en el bote: abrís si la mano entra en el rango de tu '
          'posición; si no, fold.',
        ),
      ],
      checks: [
        ComprehensionCheck(
          prompt: 'Sos el primero en entrar y tu mano está fuera del rango '
              'de tu posición. ¿Qué hacés?',
          options: ['Foldear', 'Igualar la ciega grande', 'Abrir igual'],
          correctIndex: 0,
          explanation: 'Fuera de rango y primero en el bote: fold.',
          concept: ConceptIds.openRaise,
        ),
      ],
    ),
    '5.2': const LessonContent(
      objective: 'Abrir las manos correctas desde cada posición.',
      intro: 'Todos foldean hasta vos. ¿Subís o foldeás?',
      practice: PracticeSpec(
        targetConcept: ConceptIds.openRaise,
        difficulty: 1,
        exerciseCount: 5,
      ),
    ),
    '5.3': const LessonContent(
      objective: 'Elegir un tamaño de apertura razonable.',
      theory: [
        TheoryBlock.concept(
          'Cuando abrís, el tamaño estándar en 6-max es entre 2 y 3 '
          'ciegas grandes (a veces algo más desde la SB).',
        ),
        TheoryBlock.explanation(
          'Muy chico (o limpear) le da un precio demasiado bueno a las '
          'ciegas para entrar. Muy grande infla el bote sin necesidad y '
          'hace tu apertura fácil de leer.',
        ),
        TheoryBlock.keyPoint(
          'Abrí a 2–3bb. Ni limp ni sobre-subida gigante.',
        ),
      ],
      checks: [
        ComprehensionCheck(
          prompt: 'Tamaño de apertura estándar en 6-max:',
          options: ['1bb (limp)', '2–3bb', '6bb'],
          correctIndex: 1,
          explanation: '2–3bb es el rango habitual de open raise.',
          concept: ConceptIds.openSizing,
        ),
      ],
    ),
    '5.4': const LessonContent(
      objective: 'Integrar posición, rango, acción y sizing en una decisión.',
      intro: 'Challenge: la decisión completa de apertura.',
      practice: PracticeSpec(
        targetConcept: ConceptIds.openRaise,
        difficulty: 4,
        exerciseCount: 6,
      ),
    ),
    '5.5': const LessonContent(
      objective: 'Demostrar que sabés abrir preflop.',
      intro: 'Evaluación del nivel. Necesitás 70% para aprobar.',
      practice: PracticeSpec(
        targetConcept: ConceptIds.openRaise,
        difficulty: 3,
        exerciseCount: 6,
      ),
    ),
  };
}
