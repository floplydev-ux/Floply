import '../../concepts/concept_ids.dart';
import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos sobre la mesa — Nivel 3 (Posición).
///
/// El alumno mira una mesa 6-max con las posiciones etiquetadas y decide
/// sobre **quién actúa, en qué orden y quién tiene la ventaja**. Misma
/// infraestructura que Nivel 1 y 2 (`InteractiveTableExercise`): situación
/// → pregunta → opciones → feedback → explicación sobre la mesa.
///
/// Conceptos: `position_names` (enseñado en 3.1) y `position_advantage`
/// (enseñado en 3.3).
class Level3Exercises {
  Level3Exercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '3.1': InteractiveExerciseSet([
      _yourPosition(),
      _whoActsFirst(),
      _whoAreTheBlinds(),
    ]),
    '3.2': InteractiveExerciseSet([
      _firstToDecide(),
      _howManyAfterCo(),
      _whoIsLeftOnBtn(),
      _whoActsLastPreflop(),
    ]),
    '3.3': InteractiveExerciseSet([
      _classifyHj(),
      _classifyBtn(),
      _onlyEarlyPosition(),
    ]),
    '3.4': InteractiveExerciseSet([
      _postflopSbVsBtn(),
      _bbIsOutOfPosition(),
      _utgVsCoPostflop(),
      _whyLatePlaysMore(),
    ]),
    '3.5': InteractiveExerciseSet([
      _bestPosition(),
      _whoFollowsUtg(),
      _blindsPostflop(),
      _coInPositionWhenBtnFolds(),
      _hjVsCoOrder(),
      _whyBtnHasEdge(),
    ]),
  };

  static const _names = ConceptIds.positionNames;
  static const _advantage = ConceptIds.positionAdvantage;

  // ================================================================
  // Helpers de mesa
  // ================================================================

  /// Las 6 posiciones 6-max en orden horario de acción preflop.
  static const _clockwise = ['UTG', 'HJ', 'CO', 'BTN', 'SB', 'BB'];

  /// Orden de las sillas en la mesa, empezando por el héroe (slot 0) y
  /// girando en el sentido de la acción: 0 → 5 → 4 → 3 → 2 → 1.
  static const _slotOrder = [0, 5, 4, 3, 2, 1];

  /// Mapa slot→etiqueta con el héroe (slot 0) en la posición [heroPos].
  static Map<int, String> _labelsHeroAt(String heroPos) {
    final start = _clockwise.indexOf(heroPos);
    return {
      for (var i = 0; i < 6; i++)
        _slotOrder[i]: _clockwise[(start + i) % _clockwise.length],
    };
  }

  /// Slot que tiene el botón cuando el héroe está en [heroPos].
  static int _buttonSlotHeroAt(String heroPos) => _labelsHeroAt(heroPos)
      .entries
      .firstWhere((e) => e.value == 'BTN')
      .key;

  /// Mesa 6-max con las posiciones etiquetadas y el héroe en [heroPos].
  static TableSnapshot _table({
    required String heroPos,
    Map<int, double> bets = const {},
    Map<int, String> actions = const {},
    Set<int> folded = const {},
    Map<int, List<String>> cards = const {},
    List<String> board = const [],
    double pot = 1.5,
    int? toAct = 0,
  }) {
    return TableSnapshot(
      seats: TableBuilder.seats(
        labels: _labelsHeroAt(heroPos),
        bets: bets,
        actions: actions,
        folded: folded,
        cards: cards,
        toAct: toAct,
      ),
      board: board,
      potBb: pot,
      buttonSlot: _buttonSlotHeroAt(heroPos),
    );
  }

  /// Ciegas puestas (SB 0,5 · BB 1) para el héroe en [heroPos].
  static Map<int, double> _blindBets(String heroPos) {
    final labels = _labelsHeroAt(heroPos);
    final sb = labels.entries.firstWhere((e) => e.value == 'SB').key;
    final bb = labels.entries.firstWhere((e) => e.value == 'BB').key;
    return {sb: 0.5, bb: 1.0};
  }

  static Map<int, String> _blindActions(String heroPos) {
    final labels = _labelsHeroAt(heroPos);
    final sb = labels.entries.firstWhere((e) => e.value == 'SB').key;
    final bb = labels.entries.firstWhere((e) => e.value == 'BB').key;
    return {sb: 'CIEGA', bb: 'CIEGA'};
  }

  static int _slotOf(String heroPos, String pos) =>
      _labelsHeroAt(heroPos).entries.firstWhere((e) => e.value == pos).key;

  // ================================================================
  // 3.1 — Las posiciones en 6-max
  // ================================================================

  // El héroe está pegado al botón: ¿qué posición es?
  static InteractiveTableExercise _yourPosition() {
    const heroPos = 'CO';
    final btn = _slotOf(heroPos, 'BTN');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: _blindActions(heroPos),
        cards: const {0: ['Ad', 'Kc']},
        pot: 1.5,
      ),
      concept: _names,
      questionAnchor: const TableAnchor.seat(0),
      situationHighlight: [const TableAnchor.seat(0), TableAnchor.seat(btn)],
      question: 'Sos la última silla que habla antes del botón, que tiene '
          '{BTN}. ¿Qué posición ocupás?',
      choices: const [
        ExerciseChoice(
          label: 'CO (cutoff)',
          rating: ExerciseRating.best,
          feedback: 'Exacto: el CO es la posición justo anterior al botón '
              'en el orden de acción.',
        ),
        ExerciseChoice(
          label: 'HJ (hijack)',
          rating: ExerciseRating.poor,
          feedback: 'No: el HJ habla una silla antes que el CO. Vos estás '
              'pegado al botón: sos el CO.',
        ),
        ExerciseChoice(
          label: 'BTN (botón)',
          rating: ExerciseRating.poor,
          feedback: 'No: el botón lo tiene {BTN}. Vos actuás justo antes '
              'que él.',
        ),
      ],
      explanation: [
        const ExerciseExplainStep(
          text: 'Estás en el CO: la última posición antes del botón.',
          anchor: TableAnchor.seat(0),
          highlight: [TableAnchor.seat(0)],
        ),
        ExerciseExplainStep(
          text: 'Después tuyo solo hablan {BTN}, {SB} y {BB}.',
          anchor: TableAnchor.seat(btn),
          highlight: [
            TableAnchor.seat(btn),
            TableAnchor.seat(_slotOf(heroPos, 'SB')),
            TableAnchor.seat(_slotOf(heroPos, 'BB')),
          ],
        ),
      ],
    );
  }

  // ¿Quién abre la acción preflop?
  static InteractiveTableExercise _whoActsFirst() {
    const heroPos = 'BB';
    final utg = _slotOf(heroPos, 'UTG');
    final hj = _slotOf(heroPos, 'HJ');
    final co = _slotOf(heroPos, 'CO');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: _blindActions(heroPos),
        cards: const {0: ['9h', '9s']},
        pot: 1.5,
      ),
      concept: _names,
      questionAnchor: TableAnchor.seat(utg),
      situationHighlight: [
        TableAnchor.seat(utg),
        TableAnchor.seat(hj),
        TableAnchor.seat(co),
      ],
      question: 'Se repartieron las cartas y nadie actuó todavía. ¿Quién '
          'tiene que decidir primero?',
      choices: const [
        ExerciseChoice(
          label: 'UTG',
          rating: ExerciseRating.best,
          feedback: 'Sí: UTG ("under the gun") abre siempre la acción '
              'preflop, sin ver qué hacen los demás.',
        ),
        ExerciseChoice(
          label: 'SB',
          rating: ExerciseRating.poor,
          feedback: 'No: la SB ya puso media ciega, pero preflop habla '
              'anteúltima, casi al final.',
        ),
        ExerciseChoice(
          label: 'La BB (vos)',
          rating: ExerciseRating.poor,
          feedback: 'No: la BB cierra la acción preflop. Sos el último en '
              'decidir, no el primero.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: '{UTG} está a la izquierda de la BB: primero en hablar y '
              'con la menor información de la mesa.',
          anchor: TableAnchor.seat(utg),
          highlight: [TableAnchor.seat(utg)],
        ),
        const ExerciseExplainStep(
          text: 'Orden preflop: UTG → HJ → CO → BTN → SB → BB.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // ¿Quiénes son "las ciegas"?
  static InteractiveTableExercise _whoAreTheBlinds() {
    const heroPos = 'BTN';
    final sb = _slotOf(heroPos, 'SB');
    final bb = _slotOf(heroPos, 'BB');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: _blindActions(heroPos),
        cards: const {0: ['As', 'Qs']},
        pot: 1.5,
      ),
      concept: _names,
      questionAnchor: TableAnchor.pot,
      situationHighlight: [TableAnchor.bet(sb), TableAnchor.bet(bb)],
      question: 'Dos jugadores ya pusieron fichas antes de recibir cartas. '
          '¿Quiénes son "las ciegas"?',
      choices: const [
        ExerciseChoice(
          label: 'SB y BB',
          rating: ExerciseRating.best,
          feedback: 'Sí: la ciega chica (SB) y la ciega grande (BB) ponen '
              'apuestas obligatorias que arrancan el bote.',
        ),
        ExerciseChoice(
          label: 'El BTN (vos) y la SB',
          rating: ExerciseRating.poor,
          feedback: 'No: en el botón no pusiste ninguna ciega. Las ciegas '
              'son {SB} y {BB}.',
        ),
        ExerciseChoice(
          label: 'La BB y UTG',
          rating: ExerciseRating.poor,
          feedback: 'No: {UTG} no puso ciega. Son las dos primeras sillas a '
              'la izquierda del botón: {SB} y {BB}.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: 'La SB pone 0,5 BB y la BB pone 1 BB, siempre, antes de '
              'ver cartas.',
          anchor: TableAnchor.bet(bb),
          highlight: [TableAnchor.bet(sb), TableAnchor.bet(bb)],
        ),
        ExerciseExplainStep(
          text: 'Postflop, {SB} y {BB} actúan primeras: por eso son las '
              'peores posiciones.',
          anchor: TableAnchor.seat(sb),
          highlight: [TableAnchor.seat(sb), TableAnchor.seat(bb)],
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 3.2 — El orden de acción
  // ================================================================

  // ¿Quién decide primero (héroe en HJ)?
  static InteractiveTableExercise _firstToDecide() {
    const heroPos = 'HJ';
    final utg = _slotOf(heroPos, 'UTG');
    final btn = _slotOf(heroPos, 'BTN');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: _blindActions(heroPos),
        cards: const {0: ['Kd', 'Qd']},
        pot: 1.5,
      ),
      concept: _names,
      questionAnchor: TableAnchor.seat(utg),
      situationHighlight: [TableAnchor.seat(utg)],
      question: 'Todavía no actuó nadie. ¿Quién tiene que hablar primero?',
      choices: const [
        ExerciseChoice(
          label: 'UTG',
          rating: ExerciseRating.best,
          feedback: 'Sí: UTG habla primero en el preflop, siempre.',
        ),
        ExerciseChoice(
          label: 'SB',
          rating: ExerciseRating.poor,
          feedback: 'No: la SB habla anteúltima preflop, aunque ya haya '
              'puesto media ciega.',
        ),
        ExerciseChoice(
          label: 'BTN',
          rating: ExerciseRating.poor,
          feedback: 'No: el BTN habla cuarto preflop, después de UTG, HJ '
              'y CO.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: 'La acción preflop empieza a la izquierda de la BB '
              '({UTG}) y termina en la BB.',
          anchor: TableAnchor.seat(utg),
          highlight: [TableAnchor.seat(utg), TableAnchor.seat(btn)],
        ),
        const ExerciseExplainStep(
          text: 'Vos, en el HJ, sos el segundo en hablar: solo {UTG} '
              'decide antes.',
          anchor: TableAnchor.seat(0),
          highlight: [TableAnchor.seat(0)],
          dimOthers: false,
        ),
      ],
    );
  }

  // ¿Cuántos hablan después del CO?
  static InteractiveTableExercise _howManyAfterCo() {
    const heroPos = 'CO';
    final utg = _slotOf(heroPos, 'UTG');
    final hj = _slotOf(heroPos, 'HJ');
    final btn = _slotOf(heroPos, 'BTN');
    final sb = _slotOf(heroPos, 'SB');
    final bb = _slotOf(heroPos, 'BB');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: {
          ..._blindActions(heroPos),
          utg: 'FOLD',
          hj: 'FOLD',
        },
        folded: {utg, hj},
        cards: const {0: ['Ac', 'Jc']},
        pot: 1.5,
      ),
      concept: _names,
      questionAnchor: const TableAnchor.seat(0),
      situationHighlight: [
        TableAnchor.seat(btn),
        TableAnchor.seat(sb),
        TableAnchor.seat(bb),
      ],
      question: '{UTG} y {HJ} foldearon. Si entrás en la mano, ¿cuántos '
          'jugadores pueden actuar todavía después de vos?',
      choices: const [
        ExerciseChoice(
          label: '3: BTN, SB y BB',
          rating: ExerciseRating.best,
          feedback: 'Sí: quedan el BTN y las dos ciegas por decidir '
              'después de vos.',
        ),
        ExerciseChoice(
          label: '1: solo el BTN',
          rating: ExerciseRating.poor,
          feedback: 'Te olvidás de las ciegas: {SB} y {BB} todavía no '
              'decidieron qué hacen con su mano.',
        ),
        ExerciseChoice(
          label: 'Ninguno',
          rating: ExerciseRating.poor,
          feedback: 'No: solo actuaron {UTG} y {HJ}. Faltan el BTN y las '
              'dos ciegas.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: 'Después del CO hablan {BTN}, {SB} y {BB}.',
          anchor: TableAnchor.seat(btn),
          highlight: [
            TableAnchor.seat(btn),
            TableAnchor.seat(sb),
            TableAnchor.seat(bb),
          ],
        ),
        const ExerciseExplainStep(
          text: 'Cuantos más jugadores hablan después tuyo, más cuidado: '
              'cualquiera puede subir.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // Héroe en el BTN, todos foldearon: ¿quién queda?
  static InteractiveTableExercise _whoIsLeftOnBtn() {
    const heroPos = 'BTN';
    final utg = _slotOf(heroPos, 'UTG');
    final hj = _slotOf(heroPos, 'HJ');
    final co = _slotOf(heroPos, 'CO');
    final sb = _slotOf(heroPos, 'SB');
    final bb = _slotOf(heroPos, 'BB');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: {
          ..._blindActions(heroPos),
          utg: 'FOLD',
          hj: 'FOLD',
          co: 'FOLD',
        },
        folded: {utg, hj, co},
        cards: const {0: ['Ts', '9s']},
        pot: 1.5,
      ),
      concept: _names,
      questionAnchor: const TableAnchor.seat(0),
      situationHighlight: [TableAnchor.seat(sb), TableAnchor.seat(bb)],
      question: 'Todos foldearon hasta vos, en el botón. Si igualás o '
          'subís, ¿quién queda por decidir?',
      choices: const [
        ExerciseChoice(
          label: 'SB y BB',
          rating: ExerciseRating.best,
          feedback: 'Sí: las dos ciegas todavía no hablaron. Pueden pagar, '
              'foldear o resubir.',
        ),
        ExerciseChoice(
          label: 'Nadie, la mano es tuya',
          rating: ExerciseRating.poor,
          feedback: 'Todavía no: {SB} y {BB} tienen que responder a tu '
              'acción antes de ir al flop.',
        ),
        ExerciseChoice(
          label: 'Solo la BB',
          rating: ExerciseRating.poor,
          feedback: 'También {SB}: puso media ciega pero todavía no '
              'decidió qué hace con su mano.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: 'Las ciegas siempre cierran la acción preflop.',
          anchor: TableAnchor.seat(sb),
          highlight: [TableAnchor.seat(sb), TableAnchor.seat(bb)],
        ),
        const ExerciseExplainStep(
          text: 'En el botón con todos foldeados tenés la mejor posición '
              'para intentar llevarte las ciegas.',
          anchor: TableAnchor.seat(0),
          dimOthers: false,
        ),
      ],
    );
  }

  // ¿Quién habla último preflop?
  static InteractiveTableExercise _whoActsLastPreflop() {
    const heroPos = 'UTG';
    final sb = _slotOf(heroPos, 'SB');
    final bb = _slotOf(heroPos, 'BB');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: _blindActions(heroPos),
        cards: const {0: ['Qh', 'Qd']},
        pot: 1.5,
      ),
      concept: _names,
      questionAnchor: TableAnchor.seat(bb),
      situationHighlight: [TableAnchor.seat(bb)],
      question: 'Abrís desde UTG. Si todos los demás solo pagan tu subida, '
          '¿quién es el último en hablar antes del flop?',
      choices: const [
        ExerciseChoice(
          label: 'BB',
          rating: ExerciseRating.best,
          feedback: 'Sí: la BB cierra siempre la acción preflop. Ya puso '
              'una ciega entera.',
        ),
        ExerciseChoice(
          label: 'SB',
          rating: ExerciseRating.poor,
          feedback: 'Casi: la SB habla anteúltima, justo antes de la BB.',
        ),
        ExerciseChoice(
          label: 'UTG (vos)',
          rating: ExerciseRating.poor,
          feedback: 'No: UTG abre la acción, no la cierra. Después de vos '
              'hablan otras cinco sillas.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: '{BB} es la única que puede terminar la ronda preflop sin '
              'poner más fichas, si nadie subió.',
          anchor: TableAnchor.seat(bb),
          highlight: [TableAnchor.seat(bb), TableAnchor.seat(sb)],
        ),
        const ExerciseExplainStep(
          text: 'Preflop: UTG primero, BB último. Postflop se invierte: '
              'la SB abre.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 3.3 — Temprana, media y tardía
  // ================================================================

  // ¿A qué grupo pertenece el HJ?
  static InteractiveTableExercise _classifyHj() {
    const heroPos = 'UTG';
    final hj = _slotOf(heroPos, 'HJ');
    final co = _slotOf(heroPos, 'CO');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: _blindActions(heroPos),
        cards: const {0: ['Ah', 'Qh']},
        pot: 1.5,
        toAct: null,
      ),
      concept: _advantage,
      questionAnchor: TableAnchor.seat(hj),
      situationHighlight: [TableAnchor.seat(hj), TableAnchor.seat(co)],
      question: 'Las posiciones se agrupan en temprana, media y tardía. '
          '¿A qué grupo pertenece el HJ?',
      choices: const [
        ExerciseChoice(
          label: 'Media',
          rating: ExerciseRating.best,
          feedback: 'Sí: el HJ y el CO son las posiciones medias en 6-max.',
        ),
        ExerciseChoice(
          label: 'Temprana',
          rating: ExerciseRating.poor,
          feedback: 'No: la única posición temprana en 6-max es UTG. El HJ '
              'ya decide viendo actuar a UTG.',
        ),
        ExerciseChoice(
          label: 'Tardía',
          rating: ExerciseRating.poor,
          feedback: 'No: la tardía es el BTN. El HJ todavía tiene a CO, '
              'BTN, SB y BB por detrás.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: 'Medias: {HJ} y {CO}. Quedan jugadores por hablar, pero '
              'menos que en temprana.',
          anchor: TableAnchor.seat(hj),
          highlight: [TableAnchor.seat(hj), TableAnchor.seat(co)],
        ),
        const ExerciseExplainStep(
          text: 'Temprana: UTG. Media: HJ y CO. Tardía: BTN. Las ciegas '
              'son aparte (lo peor postflop).',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // Héroe en el BTN: ¿temprana, media o tardía?
  static InteractiveTableExercise _classifyBtn() {
    const heroPos = 'BTN';
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: _blindActions(heroPos),
        cards: const {0: ['Kd', 'Kc']},
        pot: 1.5,
        toAct: null,
      ),
      concept: _advantage,
      questionAnchor: const TableAnchor.seat(0),
      situationHighlight: const [TableAnchor.seat(0)],
      question: 'Estás en el botón. ¿Tu posición es temprana, media o '
          'tardía?',
      choices: const [
        ExerciseChoice(
          label: 'Tardía',
          rating: ExerciseRating.best,
          feedback: 'Sí: el BTN es la posición más tardía y la mejor de la '
              'mesa.',
        ),
        ExerciseChoice(
          label: 'Media',
          rating: ExerciseRating.poor,
          feedback: 'No: medias son HJ y CO. El botón habla último '
              'postflop: es tardía.',
        ),
        ExerciseChoice(
          label: 'Temprana',
          rating: ExerciseRating.poor,
          feedback: 'No: temprana es UTG, el primero en actuar. El botón es '
              'lo opuesto.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'El BTN actúa último en el flop, el turn y el river: '
              'máxima información.',
          anchor: TableAnchor.seat(0),
          highlight: [TableAnchor.seat(0)],
        ),
        ExerciseExplainStep(
          text: 'Por eso desde el botón se pueden jugar muchas más manos '
              'que desde UTG.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // ¿Cuál es la única posición temprana en 6-max?
  static InteractiveTableExercise _onlyEarlyPosition() {
    const heroPos = 'CO';
    final utg = _slotOf(heroPos, 'UTG');
    final hj = _slotOf(heroPos, 'HJ');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: _blindActions(heroPos),
        cards: const {0: ['As', 'Ks']},
        pot: 1.5,
        toAct: null,
      ),
      concept: _advantage,
      questionAnchor: TableAnchor.seat(utg),
      situationHighlight: [TableAnchor.seat(utg)],
      question: 'En una mesa de 6, ¿cuál es la única posición realmente '
          'temprana?',
      choices: const [
        ExerciseChoice(
          label: 'UTG',
          rating: ExerciseRating.best,
          feedback: 'Sí: UTG decide sin ninguna información. Es la posición '
              'más difícil y necesita las manos más fuertes.',
        ),
        ExerciseChoice(
          label: 'El HJ',
          rating: ExerciseRating.poor,
          feedback: 'No: el HJ ya es posición media. Ve actuar a {UTG} '
              'antes de decidir.',
        ),
        ExerciseChoice(
          label: 'La SB',
          rating: ExerciseRating.poor,
          feedback: 'La SB es mala postflop, pero preflop habla casi al '
              'final: no abre la acción.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: '{UTG} abre la acción a ciegas; {HJ} y {CO} ya lo vieron '
              'actuar antes de decidir.',
          anchor: TableAnchor.seat(utg),
          highlight: [TableAnchor.seat(utg), TableAnchor.seat(hj)],
        ),
        const ExerciseExplainStep(
          text: 'Menos información = rango más cerrado. UTG es el más '
              'cerrado de todos.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 3.4 — Actuar primero vs actuar último
  // ================================================================

  // Postflop, BTN vs SB: ¿quién actúa primero?
  static InteractiveTableExercise _postflopSbVsBtn() {
    const heroPos = 'BTN';
    final sb = _slotOf(heroPos, 'SB');
    final bb = _slotOf(heroPos, 'BB');
    final utg = _slotOf(heroPos, 'UTG');
    final hj = _slotOf(heroPos, 'HJ');
    final co = _slotOf(heroPos, 'CO');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        folded: {bb, utg, hj, co},
        actions: {bb: 'FOLD', utg: 'FOLD', hj: 'FOLD', co: 'FOLD'},
        cards: const {0: ['Ad', 'Qc']},
        board: const ['Kh', '8c', '3s'],
        pot: 5.5,
        toAct: null,
      ),
      concept: _advantage,
      questionAnchor: TableAnchor.board,
      situationHighlight: [
        const TableAnchor.seat(0),
        TableAnchor.seat(sb),
        TableAnchor.board,
      ],
      question: 'Abriste desde el botón y te pagó {SB}. Llega el flop. '
          '¿Quién actúa primero?',
      choices: const [
        ExerciseChoice(
          label: 'La SB',
          rating: ExerciseRating.best,
          feedback: 'Sí: postflop, la SB abre la acción en todas las '
              'calles. El botón siempre habla último.',
        ),
        ExerciseChoice(
          label: 'El botón (vos)',
          rating: ExerciseRating.poor,
          feedback: 'Eso es preflop. Postflop se invierte: las ciegas '
              'actúan primero, el botón último.',
        ),
        ExerciseChoice(
          label: 'Los dos a la vez',
          rating: ExerciseRating.poor,
          feedback: 'Siempre hay un orden. Postflop empieza el jugador más '
              'a la izquierda del botón que siga en la mano: acá, {SB}.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: '{SB} decide sin saber qué vas a hacer vos.',
          anchor: TableAnchor.seat(sb),
          highlight: [TableAnchor.seat(sb)],
        ),
        const ExerciseExplainStep(
          text: 'Vos ves su acción y recién después decidís: esa es la '
              'ventaja del botón.',
          anchor: TableAnchor.seat(0),
          highlight: [TableAnchor.seat(0)],
          dimOthers: false,
        ),
      ],
    );
  }

  // Héroe en la BB contra el BTN: ¿ventaja posicional?
  static InteractiveTableExercise _bbIsOutOfPosition() {
    const heroPos = 'BB';
    final btn = _slotOf(heroPos, 'BTN');
    final sb = _slotOf(heroPos, 'SB');
    final utg = _slotOf(heroPos, 'UTG');
    final hj = _slotOf(heroPos, 'HJ');
    final co = _slotOf(heroPos, 'CO');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        folded: {sb, utg, hj, co},
        actions: {sb: 'FOLD', utg: 'FOLD', hj: 'FOLD', co: 'FOLD'},
        cards: const {0: ['Ac', 'Jd']},
        board: const ['Qd', '7h', '2c'],
        pot: 5.0,
        toAct: 0,
      ),
      concept: _advantage,
      questionAnchor: const TableAnchor.seat(0),
      situationHighlight: [const TableAnchor.seat(0), TableAnchor.seat(btn)],
      question: 'Defendiste tu BB contra la subida de {BTN}. En el flop, el '
          'turn y el river, ¿tenés ventaja de posición?',
      choices: const [
        ExerciseChoice(
          label: 'No: actúo primero en cada calle',
          rating: ExerciseRating.best,
          feedback: 'Exacto: desde la BB actuás antes que el botón en todas '
              'las calles postflop. Es la peor posición.',
        ),
        ExerciseChoice(
          label: 'Sí: ya puse la ciega grande',
          rating: ExerciseRating.poor,
          feedback: 'Poner la ciega no da ventaja: te obliga a jugar y '
              'encima actuás primero.',
        ),
        ExerciseChoice(
          label: 'Depende de las cartas',
          rating: ExerciseRating.poor,
          feedback: 'La posición no depende de las cartas: la BB actúa '
              'primero postflop pase lo que pase.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: 'Vos hablás primero; {BTN} decide viéndote.',
          anchor: const TableAnchor.seat(0),
          highlight: [const TableAnchor.seat(0), TableAnchor.seat(btn)],
        ),
        const ExerciseExplainStep(
          text: 'Por eso defender la BB es difícil: jugás fuera de '
              'posición toda la mano.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // UTG abre, CO paga: ¿quién decide primero postflop?
  static InteractiveTableExercise _utgVsCoPostflop() {
    const heroPos = 'UTG';
    final co = _slotOf(heroPos, 'CO');
    final hj = _slotOf(heroPos, 'HJ');
    final btn = _slotOf(heroPos, 'BTN');
    final sb = _slotOf(heroPos, 'SB');
    final bb = _slotOf(heroPos, 'BB');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        folded: {hj, btn, sb, bb},
        actions: {hj: 'FOLD', btn: 'FOLD', sb: 'FOLD', bb: 'FOLD'},
        cards: const {0: ['As', 'Ks']},
        board: const ['Js', 'Th', '4d'],
        pot: 6.0,
        toAct: 0,
      ),
      concept: _advantage,
      questionAnchor: TableAnchor.board,
      situationHighlight: [const TableAnchor.seat(0), TableAnchor.seat(co)],
      question: 'Abriste desde UTG y te pagó {CO}. En el flop, ¿quién habla '
          'primero?',
      choices: const [
        ExerciseChoice(
          label: 'Vos (UTG)',
          rating: ExerciseRating.best,
          feedback: 'Sí: de los dos que siguen en la mano, vos estás más a '
              'la izquierda del botón, así que actuás primero cada calle.',
        ),
        ExerciseChoice(
          label: 'El CO',
          rating: ExerciseRating.poor,
          feedback: 'No: el CO está más cerca del botón que vos. Actúa '
              'después: tiene la posición.',
        ),
        ExerciseChoice(
          label: 'Vos, pero solo en el flop',
          rating: ExerciseRating.poor,
          feedback: 'El orden se mantiene todas las calles: hablás primero '
              'en flop, turn y river.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: 'Entre {CO} y vos, el CO está más cerca del botón: juega '
              'en posición.',
          anchor: TableAnchor.seat(co),
          highlight: [const TableAnchor.seat(0), TableAnchor.seat(co)],
        ),
        const ExerciseExplainStep(
          text: 'Abrir de UTG y que pague una posición más tardía = jugás '
              'la mano fuera de posición.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // ¿Por qué las posiciones tardías juegan más manos?
  static InteractiveTableExercise _whyLatePlaysMore() {
    const heroPos = 'BTN';
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: _blindActions(heroPos),
        cards: const {0: ['Ts', '9s']},
        pot: 1.5,
        toAct: null,
      ),
      concept: _advantage,
      questionAnchor: const TableAnchor.seat(0),
      situationHighlight: const [TableAnchor.seat(0)],
      question: '¿Por qué desde el botón se pueden jugar muchas más manos '
          'que desde UTG?',
      choices: const [
        ExerciseChoice(
          label: 'Porque actúa con más información',
          rating: ExerciseRating.best,
          feedback: 'Sí: ver actuar a todos antes reduce el riesgo, así que '
              'manos más flojas se vuelven rentables.',
        ),
        ExerciseChoice(
          label: 'Porque el botón recibe mejores cartas',
          rating: ExerciseRating.poor,
          feedback: 'No: las cartas se reparten al azar. Lo que cambia es '
              'la información al decidir.',
        ),
        ExerciseChoice(
          label: 'Porque el botón paga menos ciega',
          rating: ExerciseRating.poor,
          feedback: 'El botón no paga ciega, pero eso no es lo importante: '
              'la ventaja es actuar último.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Desde el botón, si todos foldean, muchas veces te llevás '
              'las ciegas sin pelear.',
          anchor: TableAnchor.seat(0),
          highlight: [TableAnchor.seat(0)],
        ),
        ExerciseExplainStep(
          text: 'Y si hay flop, siempre decidís último. Más información = '
              'más manos jugables.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  // ================================================================
  // 3.5 — Evaluación: Posición
  // ================================================================

  static InteractiveTableExercise _bestPosition() {
    const heroPos = 'UTG';
    final btn = _slotOf(heroPos, 'BTN');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: _blindActions(heroPos),
        cards: const {0: ['9h', '9d']},
        pot: 1.5,
        toAct: null,
      ),
      concept: _advantage,
      questionAnchor: TableAnchor.seat(btn),
      situationHighlight: [TableAnchor.seat(btn)],
      question: '¿Cuál es la mejor posición en una mesa de 6?',
      choices: const [
        ExerciseChoice(
          label: 'BTN',
          rating: ExerciseRating.best,
          feedback: 'Sí: el BTN actúa último postflop siempre. Máxima '
              'información y control del bote.',
        ),
        ExerciseChoice(
          label: 'UTG',
          rating: ExerciseRating.poor,
          feedback: 'No: UTG es la más difícil. Abre la acción sin ver a '
              'nadie.',
        ),
        ExerciseChoice(
          label: 'BB',
          rating: ExerciseRating.poor,
          feedback: 'No: la BB actúa primera postflop. Es de las peores '
              'posiciones.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: '{BTN} habla último en flop, turn y river.',
          anchor: TableAnchor.seat(btn),
          highlight: [TableAnchor.seat(btn)],
        ),
        const ExerciseExplainStep(
          text: 'De peor a mejor postflop: SB, BB, UTG, HJ, CO, BTN.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _whoFollowsUtg() {
    const heroPos = 'BB';
    final utg = _slotOf(heroPos, 'UTG');
    final hj = _slotOf(heroPos, 'HJ');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: _blindActions(heroPos),
        cards: const {0: ['Kc', 'Qc']},
        pot: 1.5,
        toAct: null,
      ),
      concept: _names,
      questionAnchor: TableAnchor.seat(hj),
      situationHighlight: [TableAnchor.seat(utg), TableAnchor.seat(hj)],
      question: 'Preflop, justo después de UTG, ¿quién habla?',
      choices: const [
        ExerciseChoice(
          label: 'El HJ',
          rating: ExerciseRating.best,
          feedback: 'Sí: el orden es UTG → HJ → CO → BTN → SB → BB.',
        ),
        ExerciseChoice(
          label: 'El CO',
          rating: ExerciseRating.poor,
          feedback: 'No: el CO habla tercero, después del HJ.',
        ),
        ExerciseChoice(
          label: 'El BTN',
          rating: ExerciseRating.poor,
          feedback: 'No: el BTN habla cuarto preflop.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: '{HJ} es la segunda silla en actuar preflop.',
          anchor: TableAnchor.seat(hj),
          highlight: [TableAnchor.seat(hj)],
        ),
        const ExerciseExplainStep(
          text: 'Orden preflop completo: UTG → HJ → CO → BTN → SB → BB.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _blindsPostflop() {
    const heroPos = 'CO';
    final sb = _slotOf(heroPos, 'SB');
    final bb = _slotOf(heroPos, 'BB');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: _blindActions(heroPos),
        cards: const {0: ['Ad', 'Td']},
        pot: 1.5,
        toAct: null,
      ),
      concept: _advantage,
      questionAnchor: TableAnchor.pot,
      situationHighlight: [TableAnchor.seat(sb), TableAnchor.seat(bb)],
      question: 'Postflop, las ciegas (SB y BB)…',
      choices: const [
        ExerciseChoice(
          label: 'actúan primeras: desventaja',
          rating: ExerciseRating.best,
          feedback: 'Sí: SB y BB abren la acción en flop, turn y river. '
              'Deciden sin información.',
        ),
        ExerciseChoice(
          label: 'actúan últimas: ventaja',
          rating: ExerciseRating.poor,
          feedback: 'No: eso es el BTN. Las ciegas son lo contrario.',
        ),
        ExerciseChoice(
          label: 'depende de las cartas',
          rating: ExerciseRating.poor,
          feedback: 'El orden de acción no depende de las cartas.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: '{SB} habla primero postflop; {BB}, segunda.',
          anchor: TableAnchor.seat(sb),
          highlight: [TableAnchor.seat(sb), TableAnchor.seat(bb)],
        ),
        const ExerciseExplainStep(
          text: 'Ya pusieron fichas y encima juegan fuera de posición: por '
              'eso son las peores.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _coInPositionWhenBtnFolds() {
    const heroPos = 'CO';
    final btn = _slotOf(heroPos, 'BTN');
    final sb = _slotOf(heroPos, 'SB');
    final bb = _slotOf(heroPos, 'BB');
    final utg = _slotOf(heroPos, 'UTG');
    final hj = _slotOf(heroPos, 'HJ');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        folded: {btn, utg, hj},
        actions: {btn: 'FOLD', utg: 'FOLD', hj: 'FOLD'},
        cards: const {0: ['Ah', 'Qs']},
        board: const ['9c', '6h', '2s'],
        pot: 7.0,
        toAct: null,
      ),
      concept: _advantage,
      questionAnchor: const TableAnchor.seat(0),
      situationHighlight: [
        TableAnchor.seat(sb),
        TableAnchor.seat(bb),
        const TableAnchor.seat(0),
      ],
      question: 'Abriste desde el CO. {BTN} foldeó y te pagaron {SB} y '
          '{BB}. Postflop, ¿jugás en posición o fuera de posición?',
      choices: const [
        ExerciseChoice(
          label: 'En posición: soy el último de los tres',
          rating: ExerciseRating.best,
          feedback: 'Sí: con el botón fuera de la mano, el que está más '
              'cerca de él —vos, el CO— actúa último.',
        ),
        ExerciseChoice(
          label: 'Fuera de posición: las ciegas hablan después',
          rating: ExerciseRating.poor,
          feedback: 'No: las ciegas siempre abren la acción postflop. Vos '
              'hablás después de las dos.',
        ),
        ExerciseChoice(
          label: 'Da igual con dos rivales',
          rating: ExerciseRating.poor,
          feedback: 'La posición importa igual: seguís decidiendo con la '
              'info de lo que hicieron {SB} y {BB}.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: 'Orden postflop: {SB}, {BB}, y recién vos.',
          anchor: TableAnchor.seat(sb),
          highlight: [
            TableAnchor.seat(sb),
            TableAnchor.seat(bb),
            const TableAnchor.seat(0),
          ],
        ),
        const ExerciseExplainStep(
          text: 'La posición se define por la cercanía al botón entre los '
              'jugadores que siguen en la mano.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _hjVsCoOrder() {
    const heroPos = 'BTN';
    final hj = _slotOf(heroPos, 'HJ');
    final co = _slotOf(heroPos, 'CO');
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: _blindActions(heroPos),
        cards: const {0: ['Js', 'Jc']},
        pot: 1.5,
        toAct: null,
      ),
      concept: _names,
      questionAnchor: TableAnchor.seat(hj),
      situationHighlight: [TableAnchor.seat(hj), TableAnchor.seat(co)],
      question: 'Entre el HJ y el CO, ¿quién actúa antes?',
      choices: const [
        ExerciseChoice(
          label: 'El HJ',
          rating: ExerciseRating.best,
          feedback: 'Sí: el HJ habla antes que el CO, tanto preflop como '
              'postflop.',
        ),
        ExerciseChoice(
          label: 'El CO',
          rating: ExerciseRating.poor,
          feedback: 'No: el CO está más cerca del botón, así que actúa '
              'después del HJ.',
        ),
        ExerciseChoice(
          label: 'Actúan a la vez',
          rating: ExerciseRating.poor,
          feedback: 'Nunca dos jugadores actúan a la vez: siempre hay un '
              'orden fijo.',
        ),
      ],
      explanation: [
        ExerciseExplainStep(
          text: '{HJ} → {CO} → {BTN}: cada uno habla después del anterior.',
          anchor: TableAnchor.seat(co),
          highlight: [TableAnchor.seat(hj), TableAnchor.seat(co)],
        ),
        const ExerciseExplainStep(
          text: 'Más cerca del botón = actúa más tarde = mejor posición.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }

  static InteractiveTableExercise _whyBtnHasEdge() {
    const heroPos = 'BTN';
    return InteractiveTableExercise(
      situation: _table(
        heroPos: heroPos,
        bets: _blindBets(heroPos),
        actions: _blindActions(heroPos),
        cards: const {0: ['Ac', 'Kd']},
        pot: 1.5,
        toAct: null,
      ),
      concept: _advantage,
      questionAnchor: const TableAnchor.seat(0),
      situationHighlight: const [TableAnchor.seat(0)],
      question: 'El BTN juega con ventaja porque…',
      choices: const [
        ExerciseChoice(
          label: 'actúa último postflop y decide con más información',
          rating: ExerciseRating.best,
          feedback: 'Exacto: ver a todos antes de decidir es la ventaja '
              'posicional.',
        ),
        ExerciseChoice(
          label: 'recibe cartas más fuertes',
          rating: ExerciseRating.poor,
          feedback: 'No: las cartas son al azar. La ventaja es la '
              'información, no las cartas.',
        ),
        ExerciseChoice(
          label: 'puede subir más grande',
          rating: ExerciseRating.poor,
          feedback: 'El tamaño de la subida no cambia por la posición. Lo '
              'que cambia es cuándo te toca decidir.',
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'En cada calle postflop, el BTN espera a que hablen todos '
              'y recién ahí decide.',
          anchor: TableAnchor.seat(0),
          highlight: [TableAnchor.seat(0)],
        ),
        ExerciseExplainStep(
          text: 'Con más información, controlás el tamaño del bote y te '
              'equivocás menos.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }
}
