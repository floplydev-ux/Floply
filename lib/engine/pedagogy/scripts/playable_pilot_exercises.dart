import '../../concepts/concept_ids.dart';
import '../playable_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Piloto de ejercicios **jugables** (Fase de evolución de `InteractiveTable
/// Exercise` a decisión de acción real): 4 subniveles reales de N5/N8,
/// reescritos sobre la misma situación de mesa que ya tenían en
/// [N5Exercises]/[N8Exercises] (no se inventa contenido nuevo, se
/// reformula la interacción).
///
/// Elegidos porque ya eran, en el fondo, decisiones de acción (fold/abrir,
/// tamaño, fold/call/raise) — el candidato ideal para "sentir que estás
/// jugando la mano" en vez de responder una pregunta. Ejercicios de
/// comprensión pura (combos, "¿contra qué comparás tu mano?") quedan sin
/// tocar: ese formato les sigue quedando mejor.
///
///  - 5.3 — RFI: FOLD vs ABRIR, con razones de posición/fuerza de mano.
///  - 5.4 — Tamaño de apertura: ABRIR abre un paso de sizing.
///  - 5.5 — Rango por posición (mitad UTG): la misma decisión que 5.3, pero
///    la razón correcta cambia porque la posición es distinta.
///  - 8.6 — Enfrentar una c-bet: FOLD / CALL / SUBIR (el ejemplo exacto del
///    pedido: "si enfrenta una apuesta, FOLD | CALL | RAISE").
class PlayablePilotExercises {
  PlayablePilotExercises._();

  static final Map<String, PlayableExerciseSet> byId = {
    '5.3': PlayableExerciseSet([_rfi()]),
    '5.4': PlayableExerciseSet([_openSizing()]),
    '5.5': PlayableExerciseSet([_utgTight()]),
    '8.6': PlayableExerciseSet([_facingCbet()]),
  };

  // ================================================================
  // 5.3 — RFI: ¿abrís o foldeás? (misma situación que N5Exercises._rfi)
  // ================================================================
  static PlayableTableExercise _rfi() {
    final situation = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        cards: const {
          0: ['Ks', '9s']
        },
        toAct: 0,
      ),
      potBb: 1.5,
      buttonSlot: 0,
    );

    TableSnapshot after({required bool opens}) => TableSnapshot(
          seats: TableBuilder.seats(
            labels: TableBuilder.btnHero,
            folded: const {3, 2, 1},
            bets: opens ? const {0: 2.5} : const {},
            actions: opens ? const {0: 'SUBE'} : const {0: 'FOLD'},
            cards: const {
              0: ['Ks', '9s']
            },
          ),
          potBb: opens ? 4.0 : 1.5,
          buttonSlot: 0,
        );

    return PlayableTableExercise(
      situation: situation,
      concept: ConceptIds.openRaise,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards],
      prompt: 'Llega limpio a vos en el BOTÓN con K♠9♠.',
      actions: [
        ActionChoice(
          action: PokerAction.raise,
          label: 'ABRIR',
          rating: ExerciseRating.best,
          feedback: 'Sí: K9 suited entra cómodo en el rango de apertura '
              'del botón — la posición más ancha de la mesa.',
          afterDecision: after(opens: true),
          reasoning: const [
            ReasoningOption(
              label: 'Estoy en el botón, la posición con el rango más '
                  'ancho.',
              rating: ExerciseRating.best,
              feedback: 'Exacto: con solo las ciegas por detrás, el riesgo '
                  'de que alguien tenga algo mejor es mínimo, así que el '
                  'rango se ensancha.',
            ),
            ReasoningOption(
              label: 'K9 suited es una mano fuerte en cualquier posición.',
              rating: ExerciseRating.acceptable,
              feedback: 'K9 suited es jugable, sí, pero no es fuerte "en '
                  'cualquier posición" — el motivo real de abrir acá es la '
                  'posición, no la mano por sí sola (compará con la misma '
                  'mano en UTG).',
            ),
            ReasoningOption(
              label: 'Nadie entró antes que yo, así que puedo abrir con '
                  'cualquier cosa.',
              rating: ExerciseRating.poor,
              feedback: 'Que nadie haya entrado (RFI) es lo que te da la '
                  'oportunidad de abrir ancho, pero "cualquier cosa" no es '
                  'cierto: sigue habiendo manos que quedan afuera incluso '
                  'del botón.',
            ),
          ],
        ),
        ActionChoice(
          action: PokerAction.fold,
          label: 'FOLDEAR',
          rating: ExerciseRating.poor,
          feedback: 'Foldear acá regala una apertura rentable. Con solo '
              'las ciegas por detrás, el botón abre bastante más ancho '
              'que esto.',
          afterDecision: after(opens: false),
          reasoning: const [
            ReasoningOption(
              label: 'Prefiero jugar solo manos muy seguras.',
              rating: ExerciseRating.poor,
              feedback: 'La posición cambia qué es "seguro": desde el '
                  'botón, K9 suited ya es parte del rango sólido de '
                  'apertura, no una apuesta arriesgada.',
            ),
            ReasoningOption(
              label: 'No tengo pareja ni cartas muy altas.',
              rating: ExerciseRating.poor,
              feedback: 'Un rango de apertura no se arma solo con parejas '
                  'y cartas altas — suited connectors y manos como esta '
                  'entran cómodas desde posiciones tardías.',
            ),
          ],
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Nadie entró antes: llegó "limpio". Es un RFI (raise '
              'first in), y desde el botón el rango de apertura es el '
              'más ancho de la mesa.',
          anchor: TableAnchor.pot,
        ),
        ExerciseExplainStep(
          text: 'La idea para llevarte: cuanto más atrás te sentás, menos '
              'jugadores pueden tener todavía algo mejor detrás — así que '
              'tu rango de apertura se ensancha.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  // ================================================================
  // 5.4 — Tamaño de apertura (misma situación que N5Exercises._sizing)
  // ================================================================
  static PlayableTableExercise _openSizing() {
    final situation = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.utgHero,
        cards: const {
          0: ['As', 'Qc']
        },
        toAct: 0,
      ),
      potBb: 1.5,
      buttonSlot: 3,
    );

    TableSnapshot afterSize(double bb, double pot) => TableSnapshot(
          seats: TableBuilder.seats(
            labels: TableBuilder.utgHero,
            bets: {0: bb},
            actions: const {0: 'SUBE'},
            cards: const {
              0: ['As', 'Qc']
            },
          ),
          potBb: pot,
          buttonSlot: 3,
        );

    return PlayableTableExercise(
      situation: situation,
      concept: ConceptIds.openSizing,
      questionAnchor: TableAnchor.pot,
      prompt: 'UTG con A♠Q♣, mesa 6-max estándar.',
      actions: [
        ActionChoice(
          action: PokerAction.raise,
          label: 'ABRIR',
          rating: ExerciseRating.best,
          feedback: 'AQ es una apertura clara desde UTG en un juego '
              'estándar — la pregunta real acá es a qué tamaño.',
          reasoning: const [
            ReasoningOption(
              label: 'Uso un tamaño estándar salvo que tenga un motivo '
                  'puntual para variarlo.',
              rating: ExerciseRating.best,
              feedback: 'Exacto: un tamaño consistente evita darle '
                  'información gratis a la mesa sobre la fuerza de tu '
                  'mano.',
            ),
            ReasoningOption(
              label: 'Cuanto más grande apueste, más gano si me pagan.',
              rating: ExerciseRating.poor,
              feedback: 'Ignora la otra mitad del problema: un tamaño '
                  'más grande también arriesga más fichas y espanta a '
                  'las manos peores que sí te pagarían un tamaño '
                  'razonable.',
            ),
          ],
          sizeOptions: [
            BetSizeOption(
              label: '2.5 BB',
              rating: ExerciseRating.best,
              feedback: 'Es el tamaño de referencia en 6-max: ni tan '
                  'chico que invite a cualquiera, ni tan grande que '
                  'arriesgue de más.',
              afterDecision: afterSize(2.5, 4.0),
            ),
            BetSizeOption(
              label: '1.2 BB',
              rating: ExerciseRating.acceptable,
              feedback: 'Muy chico: le da a los demás un precio casi '
                  'regalado para seguir con cualquier cosa.',
              afterDecision: afterSize(1.2, 2.7),
            ),
            BetSizeOption(
              label: '6 BB',
              rating: ExerciseRating.poor,
              feedback: 'Demasiado grande como apertura estándar: '
                  'arriesga fichas de más sin un motivo puntual para ese '
                  'tamaño.',
              afterDecision: afterSize(6.0, 7.5),
            ),
          ],
        ),
        const ActionChoice(
          action: PokerAction.fold,
          label: 'FOLDEAR',
          rating: ExerciseRating.poor,
          feedback: 'AQ offsuit es una apertura clara desde UTG en un '
              'juego estándar: foldearla regala valor.',
          reasoning: [
            ReasoningOption(
              label: 'Prefiero no abrir desde la primera posición.',
              rating: ExerciseRating.poor,
              feedback: 'Ser selectivo en UTG es correcto en general, '
                  'pero AQ está claramente dentro de ese rango '
                  'selectivo, no afuera.',
            ),
          ],
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: '2 a 3 BB es el rango estándar en 6-max. 2.5 BB es un '
              'buen default si no tenés un motivo concreto para ir más '
              'chico o más grande.',
          anchor: TableAnchor.pot,
        ),
      ],
    );
  }

  // ================================================================
  // 5.5 — Rango por posición, mitad UTG (misma situación que
  //        N5Exercises._utgAngosto; la mitad BTN sigue en el formato
  //        anterior hasta decidir si conviene migrar el subnivel entero)
  // ================================================================
  static PlayableTableExercise _utgTight() {
    final situation = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.utgHero,
        cards: const {
          0: ['Qc', '9c']
        },
        toAct: 0,
      ),
      potBb: 1.5,
      buttonSlot: 3,
    );

    TableSnapshot after({required bool opens}) => TableSnapshot(
          seats: TableBuilder.seats(
            labels: TableBuilder.utgHero,
            bets: opens ? const {0: 2.5} : const {},
            actions: opens ? const {0: 'SUBE'} : const {0: 'FOLD'},
            cards: const {
              0: ['Qc', '9c']
            },
          ),
          potBb: opens ? 4.0 : 1.5,
          buttonSlot: 3,
        );

    return PlayableTableExercise(
      situation: situation,
      concept: ConceptIds.rangeWidth,
      questionAnchor: TableAnchor.heroCards,
      situationHighlight: const [TableAnchor.heroCards],
      prompt: 'Sos UTG con Q♣9♣ y llega limpio.',
      actions: [
        ActionChoice(
          action: PokerAction.fold,
          label: 'FOLDEAR',
          rating: ExerciseRating.best,
          feedback: 'Correcto: Q9 suited queda afuera del rango angosto '
              'de UTG. Cinco jugadores todavía pueden tener algo mejor.',
          afterDecision: after(opens: false),
          reasoning: const [
            ReasoningOption(
              label: 'Estoy en UTG: todavía pueden actuar muchos '
                  'jugadores detrás.',
              rating: ExerciseRating.best,
              feedback: 'Exacto: cuantos más jugadores puedan actuar '
                  'todavía, más chances de que alguien tenga algo mejor '
                  '— por eso el rango de apertura en UTG es el más '
                  'angosto de la mesa.',
            ),
            ReasoningOption(
              label: 'Prefiero jugar pocas manos en general.',
              rating: ExerciseRating.acceptable,
              feedback: 'El instinto de ser selectivo va en la dirección '
                  'correcta, pero no explica por qué: no es "jugar poco" '
                  'en abstracto, es la posición la que angosta el rango '
                  '(esta misma mano sí se abre desde el botón).',
            ),
            ReasoningOption(
              label: 'Q9 suited nunca es una mano jugable.',
              rating: ExerciseRating.poor,
              feedback: '"Nunca" es demasiado: la misma Q9 suited se '
                  'abre sin problema desde una posición más tardía. El '
                  'problema acá es la posición, no la mano en sí.',
            ),
          ],
        ),
        ActionChoice(
          action: PokerAction.raise,
          label: 'ABRIR',
          rating: ExerciseRating.poor,
          feedback: 'Desde UTG hay que ser mucho más selectivo: esta '
              'mano entra recién desde posiciones más tardías.',
          afterDecision: after(opens: true),
          reasoning: const [
            ReasoningOption(
              label: 'Cualquier mano suited se puede abrir.',
              rating: ExerciseRating.poor,
              feedback: 'Ser suited ayuda, pero no alcanza por sí solo '
                  'para abrir desde la posición más angosta de la mesa.',
            ),
          ],
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Misma mano, decisión distinta según la posición: menos '
              'jugadores por detrás = menos riesgo = rango más ancho. '
              'Desde UTG, con cinco jugadores todavía por actuar, Q9 '
              'suited queda afuera.',
          anchor: TableAnchor.heroCards,
        ),
      ],
    );
  }

  // ================================================================
  // 8.6 — Enfrentar una c-bet (misma situación que N8Exercises._enfrentarCbet)
  // ================================================================
  static PlayableTableExercise _facingCbet() {
    final situation = TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        folded: const {3, 2, 1},
        actions: const {4: 'C-BET'},
        bets: const {4: 4.0},
        cards: const {
          0: ['9d', '8d']
        },
        toAct: 0,
      ),
      board: const ['Kc', 'Qs', '2h'],
      potBb: 6.0,
      buttonSlot: 0,
    );

    TableSnapshot after(
            {required Map<int, double> bets,
            required Map<int, String> actions,
            required double pot,
            Set<int> folded = const {}}) =>
        TableSnapshot(
          seats: TableBuilder.seats(
            labels: TableBuilder.btnHero,
            folded: {3, 2, 1, ...folded},
            actions: {4: 'C-BET', ...actions},
            bets: {4: 4.0, ...bets},
            cards: const {
              0: ['9d', '8d']
            },
          ),
          board: const ['Kc', 'Qs', '2h'],
          potBb: pot,
          buttonSlot: 0,
        );

    return PlayableTableExercise(
      situation: situation,
      questionAnchor: const TableAnchor.seat(4),
      situationHighlight: const [TableAnchor.seat(4), TableAnchor.heroCards],
      prompt: '{BB} c-betea un board K-Q-2. Tenés 9♦8♦: sin nada hecho '
          'ni proyecto real acá.',
      actions: [
        ActionChoice(
          action: PokerAction.fold,
          label: 'FOLDEAR',
          rating: ExerciseRating.best,
          feedback: 'Correcto: sin mano ni proyecto, y sin motivos para '
              'pensar que el rival se retira, no hay nada que justifique '
              'seguir.',
          afterDecision: after(
            bets: const {},
            actions: const {0: 'FOLD'},
            pot: 6.0,
            folded: const {0},
          ),
          reasoning: const [
            ReasoningOption(
              label: 'No tengo mano hecha ni proyecto real en este '
                  'board.',
              rating: ExerciseRating.best,
              feedback: 'Exacto: sin equity real y sin plan para las '
                  'próximas calles, no hay motivo para poner más fichas.',
            ),
            ReasoningOption(
              label: 'El rival apostó, así que seguro tiene algo.',
              rating: ExerciseRating.acceptable,
              feedback: 'Va en la dirección correcta (respeta la apuesta '
                  'del rival), pero la razón central es tu propia mano: '
                  'foldearías igual aunque el rival farolee seguido, '
                  'porque vos no tenés nada con qué continuar.',
            ),
            ReasoningOption(
              label: 'Prefiero no arriesgar fichas nunca.',
              rating: ExerciseRating.poor,
              feedback: 'Eso te haría foldear también en manos donde sí '
                  'conviene seguir. Acá el motivo es esta mano en este '
                  'board, no una regla general de "nunca arriesgar".',
            ),
          ],
        ),
        ActionChoice(
          action: PokerAction.call,
          label: 'PAGAR',
          rating: ExerciseRating.poor,
          feedback: 'Pagar sin mano ni proyecto, "para ver", es tirar '
              'fichas sin ningún plan para las calles siguientes.',
          afterDecision: after(
            bets: const {0: 4.0},
            actions: const {0: 'PAGA'},
            pot: 14.0,
          ),
          reasoning: const [
            ReasoningOption(
              label: 'Quiero ver la próxima carta por si mejoro.',
              rating: ExerciseRating.poor,
              feedback: '9♦8♦ en K-Q-2 no tiene un proyecto real que '
                  'mejore con la próxima carta — "ver qué sale" no es un '
                  'plan sin outs concretos.',
            ),
            ReasoningOption(
              label: 'Pagar es más seguro que subir.',
              rating: ExerciseRating.poor,
              feedback: 'Entre las opciones disponibles, la más segura '
                  'es foldear: pagar sin mano ni proyecto sigue '
                  'arriesgando fichas sin ningún plan.',
            ),
          ],
        ),
        ActionChoice(
          action: PokerAction.raise,
          label: 'SUBIR',
          rating: ExerciseRating.poor,
          feedback: 'Subir sin mano ni proyecto es un farol sin ningún '
              'plan: si te pagan, no tenés forma de mejorar ni de seguir '
              'siendo creíble en las próximas calles.',
          afterDecision: after(
            bets: const {0: 12.0},
            actions: const {0: 'SUBE'},
            pot: 18.0,
          ),
          reasoning: const [
            ReasoningOption(
              label: 'Quiero representar una mano fuerte.',
              rating: ExerciseRating.acceptable,
              feedback: 'Entendés la idea de representar fuerza — el '
                  'problema es el momento: sin ningún proyecto detrás, '
                  'no tenés con qué respaldar el farol si el rival paga.',
            ),
            ReasoningOption(
              label: 'Así el rival se retira siempre.',
              rating: ExerciseRating.poor,
              feedback: 'Un rival que ya apostó su mano no se retira '
                  '"siempre" — asumir eso es la parte más arriesgada de '
                  'este farol.',
            ),
          ],
        ),
      ],
      explanation: const [
        ExerciseExplainStep(
          text: 'Enfrentar una c-bet junta tu mano, el board y el rango '
              'probable del rival — acá ninguno de los tres te da '
              'motivos para seguir.',
          anchor: TableAnchor.seat(4),
        ),
      ],
    );
  }
}
