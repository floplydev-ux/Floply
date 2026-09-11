import '../../concepts/concept_ids.dart';
import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos — Nivel 5 "Rangos y apertura" (PASO 4, N5-N13).
///
/// Un ejercicio por subnivel (dos en 5.5, para contrastar dos posiciones
/// con la misma mano) — calidad sobre cantidad: cada uno comprueba la
/// habilidad concreta del subnivel, no una definición repetida.
class N5Exercises {
  N5Exercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '5.1': InteractiveExerciseSet([_combos()]),
    '5.2': InteractiveExerciseSet([_rangoVsRango()]),
    '5.3': InteractiveExerciseSet([_rfi()]),
    '5.4': InteractiveExerciseSet([_sizing()]),
    '5.5': InteractiveExerciseSet([_utgAngosto(), _btnAncho()]),
    '5.6': InteractiveExerciseSet([_isoRaise()]),
  };

  // ================================================================
  // 5.1 — Qué es un rango (combos)
  // ================================================================
  static InteractiveTableExercise _combos() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(labels: TableBuilder.btnHero),
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: TableAnchor.heroCards,
      question: 'Contando suited y offsuit juntas, ¿cuántos combos distintos '
          'de "AK" existen?',
      choices: const [
        ExerciseChoice(
          label: '16',
          rating: ExerciseRating.best,
          feedback: 'Exacto: 4 combos suited (AK del mismo palo) + 12 '
              'offsuit = 16 en total.',
        ),
        ExerciseChoice(
          label: '4',
          rating: ExerciseRating.poor,
          feedback: 'Esos son solo los combos suited. Sumando los offsuit '
              '(12 más), el total es 16.',
        ),
        ExerciseChoice(
          label: '6',
          rating: ExerciseRating.poor,
          feedback: '6 es la cantidad de combos de una PAREJA (como AA), no '
              'de una mano no pareada como AK.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: '4 suited (A♠K♠, A♥K♥, A♦K♦, A♣K♣) + 12 offsuit '
              '(A♠K♥, A♠K♦... cada As con cada K de otro palo) = 16.',
          anchor: TableAnchor.heroCards,
        ),
        ExerciseExplainStep(
          text: 'Comparalo con AA: solo 6 combos, porque es una pareja. '
              'AK pesa casi el triple dentro de un rango.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  // ================================================================
  // 5.2 — Rangos en acción (rango vs rango, no mano puntual)
  // ================================================================
  static InteractiveTableExercise _rangoVsRango() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {2, 1},
        actions: const {3: 'SUBE'},
        bets: const {3: 2.5},
        cards: const {0: ['Kc', 'Qd']},
      ),
      potBb: 4.0,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: const TableAnchor.seat(3),
      situationHighlight: const [TableAnchor.seat(3), TableAnchor.heroCards],
      question: '{UTG} abre. Para decidir con K♣Q♦, ¿contra qué tenés que '
          'comparar tu mano?',
      choices: const [
        ExerciseChoice(
          label: 'CONTRA SU RANGO DE APERTURA COMPLETO',
          rating: ExerciseRating.best,
          feedback: 'Correcto: nunca sabés su mano exacta. Comparás tu mano '
              'contra TODO el conjunto de manos con las que suele abrir '
              'desde esa posición.',
        ),
        ExerciseChoice(
          label: 'CONTRA LA PEOR MANO QUE PODRÍA TENER',
          rating: ExerciseRating.poor,
          feedback: 'Eso te haría sobreestimar tu mano: su rango también '
              'incluye manos mejores que la tuya.',
        ),
        ExerciseChoice(
          label: 'CONTRA LA MEJOR MANO QUE PODRÍA TENER',
          rating: ExerciseRating.poor,
          feedback: 'Eso te haría foldear de más: su rango también incluye '
              'manos peores que la tuya.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Su rango de apertura desde UTG es angosto y fuerte, pero '
              'sigue siendo un CONJUNTO de manos — no una sola.',
          anchor: TableAnchor.seat(3),
        ),
      ],
    );
  }

  // ================================================================
  // 5.3 — La decisión de abrir (RFI)
  // ================================================================
  static InteractiveTableExercise _rfi() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        cards: const {0: ['Ks', '9s']},
        toAct: 0,
      ),
      potBb: 1.5,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.openRaise,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards],
      question: 'Llega limpio a vos en el BOTÓN con K♠9♠. ¿Abrís o '
          'foldeás?',
      choices: const [
        ExerciseChoice(
          label: 'ABRIR',
          rating: ExerciseRating.best,
          feedback: 'Sí: K9 suited entra cómodo en el rango de apertura '
              'del botón — la posición más ancha de la mesa.',
        ),
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.poor,
          feedback: 'Foldear acá regala una apertura rentable. Con solo las '
              'ciegas por detrás, el botón abre bastante más ancho que '
              'esto.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Nadie entró antes: llegó "limpio". Es un RFI (raise '
              'first in), y desde el botón el rango de apertura es el más '
              'ancho de la mesa.',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }

  // ================================================================
  // 5.4 — El tamaño de apertura
  // ================================================================
  static InteractiveTableExercise _sizing() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.utgHero,
        cards: const {0: ['As', 'Qc']},
        toAct: 0,
      ),
      potBb: 1.5,
      buttonSlot: 3,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.openSizing,
      questionAnchor: TableAnchor.pot,
      question: 'Vas a abrir en una mesa 6-max estándar. ¿Qué tamaño de '
          'apertura es el más razonable por defecto?',
      choices: const [
        ExerciseChoice(
          label: '2.5 BB',
          rating: ExerciseRating.best,
          feedback: 'Es el tamaño de referencia en 6-max: ni tan chico que '
              'invite a cualquiera, ni tan grande que arriesgue de más.',
        ),
        ExerciseChoice(
          label: '6 BB',
          rating: ExerciseRating.poor,
          feedback: 'Demasiado grande como apertura estándar: arriesga '
              'fichas de más sin un motivo puntual para ese tamaño.',
        ),
        ExerciseChoice(
          label: '1.2 BB',
          rating: ExerciseRating.acceptable,
          feedback: 'Muy chico: le da a los demás un precio casi regalado '
              'para seguir con cualquier cosa.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: '2 a 3 BB es el rango estándar en 6-max. 2.5 BB es un buen '
              'default si no tenés un motivo concreto para ir más chico o '
              'más grande.',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }

  // ================================================================
  // 5.5 — Rango de apertura por posición (misma mano, dos posiciones)
  // ================================================================
  static InteractiveTableExercise _utgAngosto() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.utgHero,
        cards: const {0: ['Qc', '9c']},
        toAct: 0,
      ),
      potBb: 1.5,
      buttonSlot: 3,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.rangeWidth,
      questionAnchor: TableAnchor.heroCards,
      question: 'Sos UTG con Q♣9♣ y llega limpio. ¿Abrís o foldeás?',
      choices: const [
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.best,
          feedback: 'Correcto: Q9 suited queda afuera del rango angosto de '
              'UTG. Cinco jugadores todavía pueden tener algo mejor.',
        ),
        ExerciseChoice(
          label: 'ABRIR',
          rating: ExerciseRating.poor,
          feedback: 'Desde UTG hay que ser mucho más selectivo: esta mano '
              'entra recién desde posiciones más tardías.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Guardá esta mano: en el próximo paso la jugás desde el '
              'botón, para ver cómo cambia la misma decisión.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  static InteractiveTableExercise _btnAncho() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        cards: const {0: ['Qc', '9c']},
        toAct: 0,
      ),
      potBb: 1.5,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      concept: ConceptIds.rangeWidth,
      questionAnchor: TableAnchor.heroCards,
      question: 'La misma Q♣9♣, pero ahora en el BOTÓN, y llega limpio. '
          '¿Abrís o foldeás?',
      choices: const [
        ExerciseChoice(
          label: 'ABRIR',
          rating: ExerciseRating.best,
          feedback: 'Sí: desde el botón, con solo las ciegas por detrás, '
              'esta misma mano ya entra cómoda en el rango de apertura.',
        ),
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.poor,
          feedback: 'Foldear una mano jugable desde el botón regala una '
              'apertura rentable: acá el riesgo de que alguien tenga algo '
              'mejor es mucho menor que desde UTG.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Misma mano, decisión distinta: la posición define el '
              'rango. Menos jugadores por detrás = menos riesgo = rango '
              'más ancho.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  // ================================================================
  // 5.6 — Contra limpers / iso raise
  // ================================================================
  static InteractiveTableExercise _isoRaise() {
    final table = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3},
        actions: const {2: 'PAGA'},
        bets: const {2: 1.0},
        cards: const {0: ['As', 'Qs']},
        toAct: 0,
      ),
      potBb: 2.5,
      buttonSlot: 0,
    );
    return InteractiveTableExercise(
      situation: table,
      questionAnchor: const TableAnchor.seat(2),
      situationHighlight: const [TableAnchor.seat(2), TableAnchor.heroCards],
      question: '{HJ} limpea (paga la ciega grande sin subir). Tenés '
          'A♠Q♠ en el botón. ¿Qué hacés?',
      choices: const [
        ExerciseChoice(
          label: 'SUBIR (ISO RAISE)',
          rating: ExerciseRating.best,
          feedback: 'Bien: con una mano buena, subir sobre el limp lo '
              'aísla y te deja jugar en ventaja, en vez de compartir un '
              'bote barato.',
        ),
        ExerciseChoice(
          label: 'SOLO PAGAR EL LIMP',
          rating: ExerciseRating.acceptable,
          feedback: 'No es un error grave, pero con una mano tan buena '
              'como AQ suited conviene más subir y aislar que solo '
              'acompañar.',
        ),
        ExerciseChoice(
          label: 'FOLDEAR',
          rating: ExerciseRating.poor,
          feedback: 'AQ suited es una mano fuerte: foldearla contra un '
              'limp (la jugada más débil del rival) regala valor.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Un limp es, en general, una jugada débil. Con una mano '
              'buena, subir para aislar al limper es mejor que dejarlo '
              'jugar barato contra varios rivales.',
          anchor: TableAnchor.seat(2),
        ),
      ],
    );
  }
}
