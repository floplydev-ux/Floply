import '../table_lesson.dart';
import 'script_builders.dart';

/// Guiones de teoría interactiva sobre la mesa — Nivel 1 (Fundamentos).
///
/// Todo lo básico se ve pasando por una mesa real: fichas, ciegas, bote,
/// cartas, calles, acciones, showdown. Una idea por burbuja.
class Level1Lessons {
  Level1Lessons._();

  static final Map<String, TableLessonScript> byId = {
    '1.1': _howAHandWorks(),
    '1.2': _stackBlindsPot(),
    '1.3': _streetsAndActions(),
  };

  // ---------------------------------------------------------------
  // 1.1 — Cómo se juega una mano  (héroe BTN, mano completa)
  // ---------------------------------------------------------------
  static TableLessonScript _howAHandWorks() {
    const labels = TableScript.btnHero;
    const btn = 0;

    return TableLessonScript([
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            cards: {for (var i = 0; i < 6; i++) i: const <String>[]},
          ),
          potBb: 0,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.seat(0),
        highlight: const [TableAnchor.seat(0)],
        bubble: 'Una mesa 6-max: seis jugadores. Cada uno tiene su stack '
            '(sus fichas). Vos tenés 100 BB.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            cards: {for (var i = 0; i < 6; i++) i: const <String>[]},
            bets: const {5: 0.5, 4: 1.0},
            actions: const {5: 'CIEGA', 4: 'CIEGA'},
          ),
          potBb: 1.5,
          buttonSlot: btn,
        ),
        anchor: TableAnchor.pot,
        highlight: const [
          TableAnchor.bet(5),
          TableAnchor.bet(4),
          TableAnchor.pot,
        ],
        bubble: 'Antes de repartir, la SB y la BB ponen las ciegas '
            'obligatorias: así arranca el bote (1,5 BB).',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            bets: const {5: 0.5, 4: 1.0},
            actions: const {5: 'CIEGA', 4: 'CIEGA'},
            cards: const {0: ['Kd', 'Kc']},
          ),
          potBb: 1.5,
          buttonSlot: btn,
        ),
        anchor: TableAnchor.heroCards,
        bubble: 'Cada jugador recibe 2 cartas privadas. Vos tenés K♦K♣.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            bets: const {0: 2.5, 5: 0.5, 4: 1.0},
            actions: const {
              0: 'SUBE',
              3: 'FOLD',
              2: 'FOLD',
              1: 'FOLD',
              5: 'CIEGA',
              4: 'CIEGA',
            },
            folded: const {3, 2, 1},
            cards: const {0: ['Kd', 'Kc']},
          ),
          potBb: 4.0,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.bet(0),
        bubble: 'En tu turno podés foldear, pagar o subir. Vos subís a '
            '2,5 BB; {UTG}, {HJ} y {CO} foldean.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            bets: const {0: 2.5, 4: 2.5, 5: 0.5},
            actions: const {0: 'SUBE', 4: 'PAGA', 5: 'FOLD'},
            folded: const {3, 2, 1, 5},
            cards: const {0: ['Kd', 'Kc']},
          ),
          potBb: 5.5,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.seat(4),
        bubble: '{BB} paga; {SB} foldea. La mano sigue entre vos y {BB}.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            folded: const {3, 2, 1, 5},
            cards: const {0: ['Kd', 'Kc']},
          ),
          board: const ['Ks', '7h', '2d'],
          potBb: 5.5,
          buttonSlot: btn,
        ),
        anchor: TableAnchor.board,
        bubble: 'El FLOP: 3 cartas comunitarias. Con tu par de reyes, '
            'ahora tenés trío.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            folded: const {3, 2, 1, 5},
            cards: const {0: ['Kd', 'Kc']},
          ),
          board: const ['Ks', '7h', '2d', 'Qs'],
          potBb: 5.5,
          buttonSlot: btn,
        ),
        anchor: TableAnchor.board,
        bubble: 'El TURN: la 4ª carta comunitaria. Otra ronda de apuestas.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            folded: const {3, 2, 1, 5},
            cards: const {0: ['Kd', 'Kc'], 4: ['Ad', 'Jc']},
          ),
          board: const ['Ks', '7h', '2d', 'Qs', '3c'],
          potBb: 5.5,
          buttonSlot: btn,
        ),
        anchor: TableAnchor.pot,
        dimOthers: false,
        highlight: const [TableAnchor.pot],
        bubble: 'El RIVER y el SHOWDOWN: se muestran las cartas y gana la '
            'mejor mano de 5. Tu trío de reyes gana el bote.',
      ),
    ]);
  }

  // ---------------------------------------------------------------
  // 1.2 — Stack, ciegas y bote  (héroe BTN)
  // ---------------------------------------------------------------
  static TableLessonScript _stackBlindsPot() {
    const labels = TableScript.btnHero;

    TableSnapshot base({double pot = 1.5}) => TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            bets: const {5: 0.5, 4: 1.0},
            actions: const {5: 'CIEGA', 4: 'CIEGA'},
          ),
          potBb: pot,
          buttonSlot: 0,
        );

    return TableLessonScript([
      TableStep(
        table: base(),
        anchor: const TableAnchor.seat(0),
        highlight: const [TableAnchor.seat(0)],
        bubble: 'Debajo de cada jugador ves su STACK: las fichas con las '
            'que juega. Vos tenés 100 BB.',
      ),
      TableStep(
        table: base(),
        anchor: const TableAnchor.bet(5),
        highlight: const [TableAnchor.bet(5), TableAnchor.bet(4)],
        bubble: 'La SB y la BB son apuestas OBLIGATORIAS: 0,5 y 1 BB, antes '
            'de ver cartas.',
      ),
      TableStep(
        table: base(),
        anchor: TableAnchor.pot,
        highlight: const [
          TableAnchor.pot,
          TableAnchor.bet(5),
          TableAnchor.bet(4),
        ],
        bubble: 'Esas fichas van al BOTE (pot): 1,5 BB. El bote es el '
            'premio de la mano.',
      ),
      TableStep(
        table: base(),
        anchor: TableAnchor.pot,
        dimOthers: false,
        bubble: 'Ganás una mano llevándote el bote: por showdown o haciendo '
            'foldear a todos.',
      ),
    ]);
  }

  // ---------------------------------------------------------------
  // 1.3 — Las calles y las acciones  (héroe BTN)
  // ---------------------------------------------------------------
  static TableLessonScript _streetsAndActions() {
    const labels = TableScript.btnHero;
    const btn = 0;
    const heroCards = {0: ['Ah', 'Kh']};

    return TableLessonScript([
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            bets: const {5: 0.5, 4: 1.0},
            actions: const {5: 'CIEGA', 4: 'CIEGA'},
            cards: heroCards,
            toAct: 0,
          ),
          potBb: 1.5,
          buttonSlot: btn,
        ),
        anchor: TableAnchor.heroCards,
        bubble: 'PREFLOP: solo tenés tus 2 cartas. Es la primera ronda de '
            'apuestas.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            folded: const {3, 2, 1, 5},
            cards: heroCards,
          ),
          board: const ['Qd', '8s', '3c'],
          potBb: 6.0,
          buttonSlot: btn,
        ),
        anchor: TableAnchor.board,
        bubble: 'El FLOP: se abren 3 cartas comunitarias. Segunda ronda de '
            'apuestas.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            folded: const {3, 2, 1, 5},
            cards: heroCards,
          ),
          board: const ['Qd', '8s', '3c', 'Jh'],
          potBb: 6.0,
          buttonSlot: btn,
        ),
        anchor: TableAnchor.board,
        bubble: 'El TURN: la 4ª carta comunitaria. Tercera ronda.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            folded: const {3, 2, 1, 5},
            cards: heroCards,
          ),
          board: const ['Qd', '8s', '3c', 'Jh', 'Ts'],
          potBb: 6.0,
          buttonSlot: btn,
        ),
        anchor: TableAnchor.board,
        bubble: 'El RIVER: la 5ª y última carta comunitaria. Cuarta y '
            'última ronda.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            folded: const {3, 2, 1, 5},
            cards: heroCards,
            toAct: 0,
          ),
          board: const ['Qd', '8s', '3c', 'Jh', 'Ts'],
          potBb: 6.0,
          buttonSlot: btn,
        ),
        anchor: const TableAnchor.seat(0),
        highlight: const [TableAnchor.seat(0)],
        bubble: 'En tu turno: FOLD (tirar), CHECK (pasar sin apostar), '
            'CALL (igualar), BET o RAISE (poner fichas).',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableScript.seats(
            labels: labels,
            folded: const {3, 2, 1, 5},
            cards: heroCards,
          ),
          board: const ['Qd', '8s', '3c', 'Jh', 'Ts'],
          potBb: 6.0,
          buttonSlot: btn,
        ),
        anchor: TableAnchor.board,
        dimOthers: false,
        bubble: 'Preflop → flop → turn → river → showdown. Una ronda de '
            'apuestas en cada calle.',
      ),
    ]);
  }
}
