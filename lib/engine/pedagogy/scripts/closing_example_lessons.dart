import '../table_lesson.dart';

/// Guiones de los **ejemplos de cierre** (Bloque B) del piloto de 3 bloques
/// (teoría escrita → ejemplo en mesa → ejercicios) de los subniveles 1.1 y
/// 1.2.
///
/// Cada uno se muestra DESPUÉS de las fichas de teoría escrita del subnivel
/// y ANTES de sus ejercicios (ver `AcademyClosingExamples` /
/// `AcademyController`). Reutilizan el mismo modelo `TableLessonScript`/
/// `TableStep` que ya usa el guion legado — la diferencia es dónde se
/// muestran, no cómo se dibujan: el texto de cada paso siempre vive en el
/// panel debajo de la mesa (`TableExplanationView`), nunca en una burbuja
/// flotante.
///
/// [objetivoYCartas] (1.1) usa deliberadamente la misma mano que el guion
/// legado de 1.1 (K♦K♣, flop K♠7♥2♦, turn Q♠, río 3♣, showdown vs A♦J♣) —
/// no hace falta inventar una mano nueva. [ganarLaMano] (1.2) declara
/// siempre el resultado de la comparación como un hecho narrado ("tu mano
/// vale más", "las dos manos valen exactamente igual") en vez de nombrar
/// categorías de mano (pareja, trío, etc.): el ranking de manos todavía no
/// se enseñó (eso es Nivel 2) y no hace falta para entender el showdown, el
/// empate o el fold.
class ClosingExampleLessons {
  ClosingExampleLessons._();

  static const _heroCards = ['Kd', 'Kc'];
  static const _flop = ['Ks', '7h', '2d'];
  static const _turnCard = 'Qs';
  static const _board = ['Ks', '7h', '2d', 'Qs', '3c'];
  static const _villainSlot = 3;
  static const _villainCards = ['Ad', 'Jc'];

  static TableSnapshot _stage({
    List<String> hero = const [],
    List<String> board = const [],
    int? villainSlot,
    List<String> villain = const [],
    bool villainFolded = false,
    Map<int, double> bets = const {},
    Map<int, String> actions = const {},
    int? toAct,
    double pot = 0,
  }) {
    return TableSnapshot(
      seats: [
        SeatState(
          slot: 0,
          label: '',
          isHero: true,
          cards: hero,
          betBb: bets[0] ?? 0,
          action: actions[0],
          toAct: toAct == 0,
        ),
        for (var i = 1; i < 6; i++)
          if (i == villainSlot)
            SeatState(
              slot: i,
              label: '',
              cards: villain,
              folded: villainFolded,
              action: villainFolded ? 'FOLD' : actions[i],
              betBb: bets[i] ?? 0,
              toAct: toAct == i,
            )
          else
            SeatState.empty(i),
      ],
      board: board,
      potBb: pot,
      buttonSlot: 0,
    );
  }

  static TableLessonScript objetivoYCartas() {
    return TableLessonScript([
      // Paso 1 — comienza la mano.
      TableStep(
        table: _stage(),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'Arranca una mano nueva. Por ahora, nadie tiene cartas '
            'todavía.',
      ),
      // Paso 2 — Hero recibe sus 2 cartas privadas.
      TableStep(
        table: _stage(hero: _heroCards),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'Te tocan tus 2 cartas privadas: K♦ K♣. Solo vos las ves.',
      ),
      // Paso 3 — la mano continúa (puente: los demás también tienen las suyas).
      TableStep(
        table: _stage(hero: _heroCards),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'La mano continúa: cada uno de los demás jugadores también '
            'recibió sus propias 2 cartas privadas — vos no las ves, y '
            'ellos no ven las tuyas.',
      ),
      // Paso 4 — flop.
      TableStep(
        table: _stage(hero: _heroCards, board: _flop),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'Llega el flop: 3 cartas comunitarias juntas, K♠ 7♥ 2♦. '
            'Ahora hay 5 cartas disponibles entre tus privadas y el board.',
      ),
      // Paso 5 — turn.
      TableStep(
        table: _stage(hero: _heroCards, board: const ['Ks', '7h', '2d', _turnCard]),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        cardGlow: const {CardRef.board(3)},
        bubble: 'Llega el turn: la 4ª carta comunitaria, Q♠.',
      ),
      // Paso 6 — river.
      TableStep(
        table: _stage(hero: _heroCards, board: _board),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        cardGlow: const {CardRef.board(4)},
        bubble: 'Llega el river: la 5ª y última carta comunitaria, 3♣. Ya '
            'están las 5.',
      ),
      // Paso 7 — las 7 cartas disponibles.
      TableStep(
        table: _stage(hero: _heroCards, board: _board),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'Contá: tus 2 cartas privadas más las 5 comunitarias son 7 '
            'cartas disponibles.',
      ),
      // Paso 8 — la mejor mano de 5.
      TableStep(
        table: _stage(hero: _heroCards, board: _board),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        cardGlow: const {
          CardRef.hero(0),
          CardRef.hero(1),
          CardRef.board(0),
          CardRef.board(1),
          CardRef.board(3),
        },
        bubble: 'Tu mejor mano de 5 es K♦ K♣ K♠ Q♠ 7♥: trío de reyes. El '
            '2♦ y el 3♣ sobran — no forman parte de nada mejor.',
      ),
      // Paso 9 — showdown.
      TableStep(
        table: _stage(
          hero: _heroCards,
          board: _board,
          villainSlot: _villainSlot,
          villain: _villainCards,
        ),
        anchor: TableAnchor.pot,
        dimOthers: false,
        bubble: 'Se muestran las cartas: tu trío de reyes le gana a la '
            'carta alta del rival (A♦ J♣, sin pareja). Te llevás el bote.',
      ),
    ]);
  }

  // ==================================================================
  // 1.2 — Ganar la mano
  // ==================================================================

  static const _h2Hero = ['Ah', 'As'];
  static const _h2Board = ['Ad', 'Kd', '9c', '7s', '2s'];
  static const _h2Villain = ['Qc', 'Qd'];
  static const _tieHero = ['Ah', 'Kd'];
  static const _tieVillain = ['As', 'Kh'];
  static const _tieBoard = ['Qh', 'Jd', '9h', '4c', '2d'];
  static const _foldBoard = ['Jc', '8h', '3d'];

  static TableLessonScript ganarLaMano() {
    return TableLessonScript([
      // Paso 1 — llegan al showdown.
      TableStep(
        table: _stage(
          hero: _h2Hero,
          board: _h2Board,
          villainSlot: _villainSlot,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'Los dos siguen en la mano hasta el final, sin retirarse. '
            'Toca mostrar las cartas: a este momento se lo llama showdown.',
      ),
      // Paso 2 — se revelan las cartas y se compara.
      TableStep(
        table: _stage(
          hero: _h2Hero,
          board: _h2Board,
          villainSlot: _villainSlot,
          villain: _h2Villain,
        ),
        anchor: TableAnchor.pot,
        highlight: const [TableAnchor.heroCards, TableAnchor.seat(_villainSlot)],
        dimOthers: false,
        bubble: 'Se muestran las cartas: tu mano de 5 vale más que la del '
            'rival. Ganás el bote entero.',
      ),
      // Paso 3 — empate exacto.
      TableStep(
        table: _stage(
          hero: _tieHero,
          board: _tieBoard,
          villainSlot: _villainSlot,
          villain: _tieVillain,
        ),
        anchor: TableAnchor.pot,
        dimOthers: false,
        bubble: 'Otra mano: esta vez, al mostrar las cartas, las dos manos '
            'de 5 valen exactamente lo mismo. Nadie gana más que el otro: '
            'el bote se reparte entre los dos, mitad y mitad.',
      ),
      // Paso 4 — apostar más no decide.
      TableStep(
        table: _stage(
          hero: _h2Hero,
          board: _h2Board,
          villainSlot: _villainSlot,
          villain: _h2Villain,
        ),
        anchor: const TableAnchor.seat(_villainSlot),
        highlight: const [TableAnchor.heroCards, TableAnchor.seat(_villainSlot)],
        dimOthers: false,
        bubble: 'Fijate: en esta mano el rival apostó más que vos en el '
            'río. Aun así, en el showdown gana la mejor mano de 5 — no '
            'quien apostó más.',
      ),
      // Paso 5 — ahora, ganar por fold: el rival no paga.
      TableStep(
        table: _stage(
          hero: const [],
          board: _foldBoard,
          villainSlot: _villainSlot,
          villainFolded: true,
        ),
        anchor: const TableAnchor.seat(_villainSlot),
        highlight: const [TableAnchor.seat(_villainSlot)],
        bubble: 'Ahora una mano distinta. Apostás, y esta vez el rival '
            'decide no pagar: se retira.',
      ),
      // Paso 6 — se lleva el bote sin mostrar.
      TableStep(
        table: _stage(
          hero: const [],
          board: _foldBoard,
          villainSlot: _villainSlot,
          villainFolded: true,
        ),
        anchor: TableAnchor.pot,
        dimOthers: false,
        bubble: 'La mano termina ahí mismo: te llevás el bote sin mostrar '
            'tus cartas — ni siquiera importa qué tenías.',
      ),
    ]);
  }

  // ==================================================================
  // 1.3 — Las acciones
  // ==================================================================
  //
  // Cada acción se demuestra en una mesa propia (no una sola mano
  // continua): así cada paso queda enfocado en UNA acción a la vez, tal
  // como pide el pedido. Los montos de fichas son ilustrativos.

  static const _h3Board = ['Jc', '8h', '3d'];

  static TableLessonScript lasAcciones() {
    return TableLessonScript([
      // Fold.
      TableStep(
        table: _stage(hero: const ['9d', '4c'], toAct: 0),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'Tenés 9♦4♣, una mano floja. Foldeás: soltás tus cartas y '
            'no ponés ni una ficha más. Lo único que perdés es lo que ya '
            'habías puesto antes, si algo pusiste.',
      ),
      // Check.
      TableStep(
        table: _stage(
          hero: const ['Ah', 'Qd'],
          board: _h3Board,
          toAct: 0,
        ),
        anchor: const TableAnchor.seat(0),
        highlight: const [TableAnchor.seat(0)],
        bubble: 'Nadie apostó todavía en esta ronda. Pasás sin poner '
            'fichas: eso es check. Seguís en la mano gratis.',
      ),
      // Call.
      TableStep(
        table: _stage(
          hero: const ['Ah', 'Qd'],
          board: _h3Board,
          villainSlot: _villainSlot,
          bets: const {_villainSlot: 4},
          actions: const {_villainSlot: 'APUESTA'},
          pot: 6,
          toAct: 0,
        ),
        anchor: const TableAnchor.bet(_villainSlot),
        highlight: const [TableAnchor.bet(_villainSlot), TableAnchor.heroCards],
        bubble: 'El rival ya apostó 4 BB. Vos igualás esa misma cantidad '
            'para seguir en la mano sin subir: eso es call.',
      ),
      // Bet.
      TableStep(
        table: _stage(
          hero: const ['Kc', 'Kd'],
          board: _h3Board,
          bets: const {0: 5},
          actions: const {0: 'APUESTA'},
          pot: 5,
        ),
        anchor: const TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0)],
        bubble: 'Nadie había apostado todavía en esta ronda. Vos ponés '
            'fichas primero: eso es bet. Ahora el rival tiene que '
            'responder.',
      ),
      // Raise.
      TableStep(
        table: _stage(
          hero: const ['Kc', 'Kd'],
          board: _h3Board,
          villainSlot: _villainSlot,
          bets: const {_villainSlot: 3, 0: 9},
          actions: const {_villainSlot: 'APUESTA', 0: 'SUBE'},
          pot: 12,
        ),
        anchor: const TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(_villainSlot), TableAnchor.bet(0)],
        bubble: 'El rival apostó 3 BB. Vos ponés 9 BB, más que esa '
            'apuesta: eso es raise, subir. El rival tiene que decidir de '
            'nuevo.',
      ),
      // Re-raise.
      TableStep(
        table: _stage(
          hero: const ['As', 'Ad'],
          board: const [],
          villainSlot: _villainSlot,
          bets: const {_villainSlot: 9, 0: 27},
          actions: const {_villainSlot: 'SUBE', 0: 'SUBE'},
          pot: 39,
        ),
        anchor: const TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(_villainSlot), TableAnchor.bet(0)],
        bubble: 'El rival ya había subido una apuesta. Vos volvés a subir '
            'por encima de esa subida: eso es un re-raise.',
      ),
      // All-in.
      TableStep(
        table: _stage(
          hero: const ['As', 'Kd'],
          board: const [],
          bets: const {0: 100},
          actions: const {0: 'ALL-IN'},
          pot: 100,
        ),
        anchor: const TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0)],
        bubble: 'Ponés todas las fichas que tenés en la mesa, de una sola '
            'vez: eso es ir all-in. Es la apuesta más grande posible.',
      ),
      // Acción cerrada.
      TableStep(
        table: _stage(
          hero: const ['Kc', 'Kd'],
          board: _h3Board,
          villainSlot: _villainSlot,
          bets: const {_villainSlot: 5, 0: 5},
          actions: const {_villainSlot: 'PAGA', 0: 'APUESTA'},
          pot: 15,
        ),
        anchor: TableAnchor.pot,
        dimOthers: false,
        bubble: 'Vos apostaste 5 BB y el rival pagó esos mismos 5 BB. No '
            'queda nadie más por hablar: la acción está cerrada. Recién '
            'ahora sale la próxima carta.',
      ),
      // Acción legal — sin apuesta delante.
      TableStep(
        table: _stage(hero: const ['Th', '9h'], board: _h3Board, toAct: 0),
        anchor: const TableAnchor.seat(0),
        highlight: const [TableAnchor.seat(0)],
        bubble: 'Mirá: acá no hay ninguna apuesta delante tuyo. Tus únicas '
            'opciones son check o bet.',
      ),
      // Acción legal — con apuesta delante.
      TableStep(
        table: _stage(
          hero: const ['Th', '9h'],
          board: _h3Board,
          villainSlot: _villainSlot,
          bets: const {_villainSlot: 4},
          actions: const {_villainSlot: 'APUESTA'},
          pot: 6,
          toAct: 0,
        ),
        anchor: const TableAnchor.bet(_villainSlot),
        highlight: const [TableAnchor.bet(_villainSlot), TableAnchor.seat(0)],
        bubble: 'Ahora sí hay una apuesta delante tuyo. Tus opciones '
            'cambian: fold, call o raise — check ya no es una opción.',
      ),
      // Orden de acción, paso 1.
      TableStep(
        table: _stage(
          hero: const ['Th', '9h'],
          board: _h3Board,
          toAct: 0,
        ),
        anchor: const TableAnchor.seat(0),
        highlight: const [TableAnchor.seat(0)],
        dimOthers: false,
        bubble: 'Se actúa de a uno, en un orden fijo. Ahora te toca a vos.',
      ),
      // Orden de acción, paso 2.
      TableStep(
        table: _stage(
          hero: const ['Th', '9h'],
          board: _h3Board,
          villainSlot: _villainSlot,
          actions: const {_villainSlot: 'PASA'},
          toAct: _villainSlot,
        ),
        anchor: const TableAnchor.seat(_villainSlot),
        highlight: const [TableAnchor.seat(_villainSlot)],
        dimOthers: false,
        bubble: 'Ahora le toca al rival. Cuando te vuelva a tocar a vos, '
            'ya vas a haber visto lo que hizo — esa ventaja de información '
            'la vas a estudiar más adelante.',
      ),
    ]);
  }
}
