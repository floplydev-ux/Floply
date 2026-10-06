import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de los **ejemplos de cierre** (Bloque B) del piloto de 3 bloques
/// (teoría escrita → ejemplo en mesa → ejercicios) de los subniveles 1.1,
/// 1.2, 1.3 y 1.4.
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

  /// Mesa de 6 jugadores para 1.1/1.2/1.3 (reutiliza [TableBuilder], igual
  /// que los ejercicios y el resto de los guiones — no un sistema nuevo).
  /// Héroe en el BOTÓN, SB/BB/UTG/HJ/CO siempre presentes y con su
  /// etiqueta de posición visible, aunque no participen del ejemplo
  /// puntual: la mesa tiene que verse como una mano real de 6, no un
  /// mano a mano con 4 sillas vacías.
  ///
  /// [othersDealt] controla si los 4 asientos de fondo (todos menos héroe
  /// y [villainSlot]) ya tienen cartas boca abajo — antes del reparto
  /// (1.1, pasos 1-2) todavía no. [othersFolded] los marca como fuera de
  /// la mano (gris + ✕, sin texto: es un estado puramente visual que
  /// `PlayerSeat` ya sabe dibujar, no introduce ningún término nuevo) —
  /// una mesa real rara vez llega al río con los 6 adentro.
  ///
  /// [heroStack]/[villainStack]/[pot] son `null` por defecto: si no se
  /// pasan, se calculan solos a partir de [bets] (100 BB menos lo que ese
  /// asiento puso; el bote, la suma de lo que hay sobre la mesa) — así una
  /// escena que muestra fichas apostadas nunca puede quedar con un stack
  /// de 100 BB fijo "de regalo". Pasarlos explícitos (como en las manos
  /// encadenadas de 1.1/1.2, donde el bote ya sweepeado no coincide con
  /// ninguna apuesta visible en pantalla) los pisa sin problema.
  static TableSnapshot _stage6({
    List<String> hero = const [],
    List<String> board = const [],
    int villainSlot = _villainSlot,
    List<String> villain = const [],
    bool villainFolded = false,
    bool othersDealt = true,
    bool othersFolded = true,
    Map<int, double> bets = const {},
    Map<int, String> actions = const {},
    int? toAct,
    double? heroStack,
    double? villainStack,
    double? pot,
  }) {
    final background = {
      for (var i = 1; i < 6; i++)
        if (i != villainSlot) i,
    };
    return TableSnapshot(
      seats: TableBuilder.seats(
        labels: TableBuilder.btnHero,
        bets: bets,
        actions: actions,
        cards: {
          0: hero,
          villainSlot: villain,
          for (final i in background) i: othersDealt ? const ['?', '?'] : const [],
        },
        stacks: {
          0: heroStack ?? (100 - (bets[0] ?? 0)),
          villainSlot: villainStack ?? (100 - (bets[villainSlot] ?? 0)),
        },
        folded: {
          if (villainFolded) villainSlot,
          if (othersFolded) ...background,
        },
        toAct: toAct,
      ),
      board: board,
      potBb: pot ?? bets.values.fold(0.0, (a, b) => a + b),
      buttonSlot: 0,
    );
  }

  static TableLessonScript objetivoYCartas() {
    return TableLessonScript([
      // Paso 1 — comienza la mano: los 6 sentados, nadie tiene cartas
      // todavía (ni héroe ni el resto).
      TableStep(
        table: _stage6(othersDealt: false, othersFolded: false),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'Arranca una mano nueva. Los 6 están sentados, pero por '
            'ahora nadie tiene cartas todavía.',
      ),
      // Paso 2 — Hero recibe sus 2 cartas privadas.
      TableStep(
        table: _stage6(hero: _heroCards, othersDealt: false, othersFolded: false),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'Te tocan tus 2 cartas privadas: K♦ K♣. Solo vos las ves.',
      ),
      // Paso 3 — la mano continúa (puente: los demás también tienen las suyas).
      TableStep(
        table: _stage6(
          hero: _heroCards,
          villain: const ['?', '?'],
          othersDealt: true,
          othersFolded: false,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'La mano continúa: cada uno de los demás jugadores también '
            'recibió sus propias 2 cartas privadas — vos no las ves, y '
            'ellos no ven las tuyas.',
      ),
      // Paso 4 — flop. De acá en más algunos ya se bajaron de la mano
      // (mirá los asientos grises): como en cualquier mano real, no todos
      // llegan hasta el final.
      TableStep(
        table: _stage6(hero: _heroCards, board: _flop, villain: const ['?', '?']),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'Llega el flop: 3 cartas comunitarias juntas, K♠ 7♥ 2♦. '
            'Ahora hay 5 cartas disponibles entre tus privadas y el board.',
      ),
      // Paso 5 — turn.
      TableStep(
        table: _stage6(
          hero: _heroCards,
          board: const ['Ks', '7h', '2d', _turnCard],
          villain: const ['?', '?'],
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        cardGlow: const {CardRef.board(3)},
        bubble: 'Llega el turn: la 4ª carta comunitaria, Q♠.',
      ),
      // Paso 6 — river.
      TableStep(
        table: _stage6(hero: _heroCards, board: _board, villain: const ['?', '?']),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        cardGlow: const {CardRef.board(4)},
        bubble: 'Llega el river: la 5ª y última carta comunitaria, 3♣. Ya '
            'están las 5.',
      ),
      // Paso 7 — las 7 cartas disponibles.
      TableStep(
        table: _stage6(hero: _heroCards, board: _board, villain: const ['?', '?']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'Contá: tus 2 cartas privadas más las 5 comunitarias son 7 '
            'cartas disponibles.',
      ),
      // Paso 8 — la mejor mano de 5.
      TableStep(
        table: _stage6(hero: _heroCards, board: _board, villain: const ['?', '?']),
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
      // Paso 9 — showdown: de los 6 que arrancaron, llegan hasta acá vos
      // y un solo rival — el resto ya se había bajado en el camino.
      TableStep(
        table: _stage6(
          hero: _heroCards,
          board: _board,
          villain: _villainCards,
          pot: 24,
          heroStack: 88,
          villainStack: 88,
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
      // Paso 1 — llegan al showdown. De los 6 que arrancaron la mano, ya
      // solo quedan vos y un rival — el resto se retiró en el camino
      // (asientos grises): por eso importa saber las dos formas de ganar.
      TableStep(
        table: _stage6(
          hero: _h2Hero,
          board: _h2Board,
          villain: const ['?', '?'],
          pot: 18,
          heroStack: 91,
          villainStack: 91,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'Los dos siguen en la mano hasta el final, sin retirarse. '
            'Toca mostrar las cartas: a este momento se lo llama showdown.',
      ),
      // Paso 2 — se revelan las cartas y se compara.
      TableStep(
        table: _stage6(
          hero: _h2Hero,
          board: _h2Board,
          villain: _h2Villain,
          pot: 18,
          heroStack: 91,
          villainStack: 91,
        ),
        anchor: TableAnchor.pot,
        highlight: const [TableAnchor.heroCards, TableAnchor.seat(_villainSlot)],
        dimOthers: false,
        bubble: 'Se muestran las cartas: tu mano de 5 vale más que la del '
            'rival. Ganás el bote entero.',
      ),
      // Paso 3 — empate exacto.
      TableStep(
        table: _stage6(
          hero: _tieHero,
          board: _tieBoard,
          villain: _tieVillain,
          pot: 14,
          heroStack: 93,
          villainStack: 93,
        ),
        anchor: TableAnchor.pot,
        dimOthers: false,
        bubble: 'Otra mano: esta vez, al mostrar las cartas, las dos manos '
            'de 5 valen exactamente lo mismo. Nadie gana más que el otro: '
            'el bote se reparte entre los dos, mitad y mitad.',
      ),
      // Paso 4 — apostar fuerte no decide. Para llegar los dos hasta acá,
      // cada apuesta del rival ya la pagaste vos (por eso los stacks bajan
      // lo mismo): apostar fuerte no es lo mismo que ganar.
      TableStep(
        table: _stage6(
          hero: _h2Hero,
          board: _h2Board,
          villain: _h2Villain,
          pot: 18,
          heroStack: 91,
          villainStack: 91,
        ),
        anchor: const TableAnchor.seat(_villainSlot),
        highlight: const [TableAnchor.heroCards, TableAnchor.seat(_villainSlot)],
        dimOthers: false,
        bubble: 'Fijate: en esta mano el rival apostó fuerte en varias '
            'calles y vos pagaste esas apuestas para seguir viéndolo. Aun '
            'así, en el showdown gana la mejor mano de 5 — apostar fuerte '
            'no te hace ganar por sí solo.',
      ),
      // Paso 5 — ahora, ganar por fold: el rival no paga. Mano distinta,
      // más corta: se terminó en el flop, por eso el bote es más chico.
      TableStep(
        table: _stage6(
          hero: const ['?', '?'],
          board: _foldBoard,
          villainFolded: true,
          pot: 10,
          heroStack: 95,
          villainStack: 95,
        ),
        anchor: const TableAnchor.seat(_villainSlot),
        highlight: const [TableAnchor.seat(_villainSlot)],
        bubble: 'Ahora una mano distinta. Apostás, y esta vez el rival '
            'decide no pagar: se retira.',
      ),
      // Paso 6 — se lleva el bote sin mostrar.
      TableStep(
        table: _stage6(
          hero: const ['?', '?'],
          board: _foldBoard,
          villainFolded: true,
          pot: 10,
          heroStack: 95,
          villainStack: 95,
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
        table: _stage6(hero: const ['9d', '4c'], toAct: 0),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'Tenés 9♦4♣, una mano floja. Foldeás: soltás tus cartas y '
            'no ponés ni una ficha más. Lo único que perdés es lo que ya '
            'habías puesto antes, si algo pusiste.',
      ),
      // Check.
      TableStep(
        table: _stage6(
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
        table: _stage6(
          hero: const ['Ah', 'Qd'],
          board: _h3Board,
          bets: const {_villainSlot: 4},
          actions: const {_villainSlot: 'APUESTA'},
          toAct: 0,
        ),
        anchor: const TableAnchor.bet(_villainSlot),
        highlight: const [TableAnchor.bet(_villainSlot), TableAnchor.heroCards],
        bubble: 'El rival ya apostó 4 BB. Vos igualás esa misma cantidad '
            'para seguir en la mano sin subir: eso es call.',
      ),
      // Bet.
      TableStep(
        table: _stage6(
          hero: const ['Kc', 'Kd'],
          board: _h3Board,
          bets: const {0: 5},
          actions: const {0: 'APUESTA'},
        ),
        anchor: const TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0)],
        bubble: 'Nadie había apostado todavía en esta ronda. Vos ponés '
            'fichas primero: eso es bet. Ahora el rival tiene que '
            'responder.',
      ),
      // Raise.
      TableStep(
        table: _stage6(
          hero: const ['Kc', 'Kd'],
          board: _h3Board,
          bets: const {_villainSlot: 3, 0: 9},
          actions: const {_villainSlot: 'APUESTA', 0: 'SUBE'},
        ),
        anchor: const TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(_villainSlot), TableAnchor.bet(0)],
        bubble: 'El rival apostó 3 BB. Vos ponés 9 BB, más que esa '
            'apuesta: eso es raise, subir. El rival tiene que decidir de '
            'nuevo.',
      ),
      // Re-raise.
      TableStep(
        table: _stage6(
          hero: const ['As', 'Ad'],
          board: const [],
          bets: const {_villainSlot: 9, 0: 27},
          actions: const {_villainSlot: 'SUBE', 0: 'SUBE'},
        ),
        anchor: const TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(_villainSlot), TableAnchor.bet(0)],
        bubble: 'El rival ya había subido una apuesta. Vos volvés a subir '
            'por encima de esa subida: eso es un re-raise.',
      ),
      // All-in.
      TableStep(
        table: _stage6(
          hero: const ['As', 'Kd'],
          board: const [],
          bets: const {0: 100},
          actions: const {0: 'ALL-IN'},
        ),
        anchor: const TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0)],
        bubble: 'Ponés todas las fichas que tenés en la mesa, de una sola '
            'vez: eso es ir all-in. Es la apuesta más grande posible — '
            'fijate que no te queda nada de stack detrás.',
      ),
      // Acción cerrada.
      TableStep(
        table: _stage6(
          hero: const ['Kc', 'Kd'],
          board: _h3Board,
          bets: const {_villainSlot: 5, 0: 5},
          actions: const {_villainSlot: 'PAGA', 0: 'APUESTA'},
        ),
        anchor: TableAnchor.pot,
        dimOthers: false,
        bubble: 'Vos apostaste 5 BB y el rival pagó esos mismos 5 BB. No '
            'queda nadie más por hablar: la acción está cerrada. Recién '
            'ahora sale la próxima carta.',
      ),
      // Acción legal — sin apuesta delante.
      TableStep(
        table: _stage6(hero: const ['Th', '9h'], board: _h3Board, toAct: 0),
        anchor: const TableAnchor.seat(0),
        highlight: const [TableAnchor.seat(0)],
        bubble: 'Mirá: acá no hay ninguna apuesta delante tuyo. Tus únicas '
            'opciones son check o bet.',
      ),
      // Acción legal — con apuesta delante.
      TableStep(
        table: _stage6(
          hero: const ['Th', '9h'],
          board: _h3Board,
          bets: const {_villainSlot: 4},
          actions: const {_villainSlot: 'APUESTA'},
          toAct: 0,
        ),
        anchor: const TableAnchor.bet(_villainSlot),
        highlight: const [TableAnchor.bet(_villainSlot), TableAnchor.seat(0)],
        bubble: 'Ahora sí hay una apuesta delante tuyo. Tus opciones '
            'cambian: fold, call o raise — check ya no es una opción.',
      ),
      // Orden de acción, paso 1.
      TableStep(
        table: _stage6(
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
        table: _stage6(
          hero: const ['Th', '9h'],
          board: _h3Board,
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

  // ==================================================================
  // 1.4 — Las cuatro calles (consolidación de 1.1-1.3)
  // ==================================================================
  //
  // Una sola mano continua, de punta a punta (preflop → flop → turn →
  // river → showdown), con el rival en la ciega grande (villainSlot: 4,
  // BB): a diferencia de 1.1/1.2/1.3, acá SÍ importa que las fichas se
  // seigan calle a calle en el mismo bote, porque el objetivo de 1.4 es
  // justamente ver avanzar una mano completa. Por eso los pasos con
  // apuestas pasan `heroStack`/`villainStack`/`pot` explícitos (arrastrando
  // lo ya puesto en calles anteriores) en vez de dejar que `_stage6` los
  // calcule solo a partir de `bets` (que solo sabe de la calle actual).
  // Cierra con una segunda mano, más corta, que termina por fold — para
  // que quede claro que una mano no siempre llega hasta el río.

  static const _c4VillainSlot = 4; // BB
  static const _c4Hero = ['As', 'Ks'];
  static const _c4Flop = ['Kd', '7h', '2c'];
  static const _c4TurnCard = '9s';
  static const _c4Board = ['Kd', '7h', '2c', '9s', '4d'];
  static const _c4Villain = ['Qc', 'Qd'];
  static const _c4FoldBoard = ['Jc', '8h', '3d'];

  static TableLessonScript lasCuatroCalles() {
    return TableLessonScript([
      // Paso 1 — preflop: las ciegas ya están en el bote antes de repartir.
      TableStep(
        table: _stage6(
          villainSlot: _c4VillainSlot,
          othersDealt: false,
          othersFolded: false,
          pot: 1.5,
          villainStack: 99,
        ),
        anchor: const TableAnchor.seat(_c4VillainSlot),
        highlight: const [TableAnchor.pot, TableAnchor.seat(_c4VillainSlot)],
        dimOthers: false,
        bubble: 'Mirá: antes de que te toquen tus cartas, ya hay fichas en '
            'el bote — son las ciegas obligatorias. Así arranca siempre el '
            'preflop.',
      ),
      // Paso 2 — hero recibe sus privadas.
      TableStep(
        table: _stage6(
          hero: _c4Hero,
          villainSlot: _c4VillainSlot,
          othersDealt: false,
          othersFolded: false,
          pot: 1.5,
          villainStack: 99,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'Te llegan tus 2 privadas: A♠K♠. Con nada más sobre la '
            'mesa todavía, esta es la primera ronda de apuestas: el '
            'preflop.',
      ),
      // Paso 3 — hero abre. Los demás (menos BB) se bajan de la mano.
      TableStep(
        table: _stage6(
          hero: _c4Hero,
          villainSlot: _c4VillainSlot,
          othersDealt: false,
          bets: const {0: 3},
          actions: const {0: 'SUBE'},
          heroStack: 97,
          villainStack: 99,
          pot: 4.5,
        ),
        anchor: const TableAnchor.bet(0),
        highlight: const [TableAnchor.seat(0), TableAnchor.bet(0)],
        bubble: 'Subís a 3. Fijate tu stack: bajó exactamente esas 3 '
            'fichas — nada es gratis.',
      ),
      // Paso 4 — BB paga: se cierra la ronda de preflop.
      TableStep(
        table: _stage6(
          hero: _c4Hero,
          villainSlot: _c4VillainSlot,
          bets: const {0: 3, _c4VillainSlot: 3},
          actions: const {0: 'SUBE', _c4VillainSlot: 'PAGA'},
          heroStack: 97,
          villainStack: 97,
          pot: 6.5,
        ),
        anchor: const TableAnchor.seat(_c4VillainSlot),
        highlight: const [TableAnchor.seat(0), TableAnchor.seat(_c4VillainSlot)],
        dimOthers: false,
        bubble: 'El rival iguala tus 3. Los dos pusimos lo mismo: la ronda '
            'se cierra. Recién ahora sale el flop.',
      ),
      // Paso 5 — llega el flop: nueva calle, nueva ronda de apuestas.
      TableStep(
        table: _stage6(
          hero: _c4Hero,
          board: _c4Flop,
          villainSlot: _c4VillainSlot,
          heroStack: 97,
          villainStack: 97,
          pot: 6.5,
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'Llega el flop: 3 cartas juntas, K♦7♥2♣. Arranca una '
            'ronda de apuestas nueva — la segunda de la mano.',
      ),
      // Paso 6 — bet + call en el flop.
      TableStep(
        table: _stage6(
          hero: _c4Hero,
          board: _c4Flop,
          villainSlot: _c4VillainSlot,
          bets: const {0: 4, _c4VillainSlot: 4},
          actions: const {0: 'APUESTA', _c4VillainSlot: 'PAGA'},
          heroStack: 93,
          villainStack: 93,
          pot: 14.5,
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board, TableAnchor.bet(0), TableAnchor.bet(_c4VillainSlot)],
        bubble: 'Apostás en el flop y te pagan. Mirá cómo el bote crece y '
            'los dos stacks bajan, calle tras calle.',
      ),
      // Paso 7 — llega el turn. Ojo con esto: cada calle suma información.
      TableStep(
        table: _stage6(
          hero: _c4Hero,
          board: const ['Kd', '7h', '2c', _c4TurnCard],
          villainSlot: _c4VillainSlot,
          heroStack: 93,
          villainStack: 93,
          pot: 14.5,
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        cardGlow: const {CardRef.board(3)},
        bubble: 'Llega el turn: la 4ª carta, 9♠. Ya sabés más que en el '
            'flop — viste cómo pagó ahí, y ahora hay una carta más para '
            'leer. Cada calle suma información: nunca es menos que antes.',
      ),
      // Paso 8 — check-check: la ronda se cierra sin que nadie apueste.
      TableStep(
        table: _stage6(
          hero: _c4Hero,
          board: const ['Kd', '7h', '2c', _c4TurnCard],
          villainSlot: _c4VillainSlot,
          actions: const {0: 'PASA', _c4VillainSlot: 'PASA'},
          heroStack: 93,
          villainStack: 93,
          pot: 14.5,
        ),
        anchor: TableAnchor.pot,
        dimOthers: false,
        bubble: 'Los dos pasamos: nadie apuesta esta vez. No hace falta '
            'apostar para que la ronda se cierre — alcanza con que nadie '
            'quiera poner más. Sale la próxima carta gratis.',
      ),
      // Paso 9 — llega el river: la última carta.
      TableStep(
        table: _stage6(
          hero: _c4Hero,
          board: _c4Board,
          villainSlot: _c4VillainSlot,
          heroStack: 93,
          villainStack: 93,
          pot: 14.5,
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        cardGlow: const {CardRef.board(4)},
        bubble: 'Llega el river: la 5ª y última carta, 4♦. No viene nada '
            'más — tu mano ya es lo que es. Empieza la última ronda.',
      ),
      // Paso 10 — bet + call en el río: se cierra la última ronda.
      TableStep(
        table: _stage6(
          hero: _c4Hero,
          board: _c4Board,
          villainSlot: _c4VillainSlot,
          bets: const {0: 8, _c4VillainSlot: 8},
          actions: const {0: 'APUESTA', _c4VillainSlot: 'PAGA'},
          heroStack: 85,
          villainStack: 85,
          pot: 30.5,
        ),
        anchor: const TableAnchor.seat(0),
        highlight: const [TableAnchor.seat(0), TableAnchor.seat(_c4VillainSlot)],
        dimOthers: false,
        bubble: 'En el río volvés a apostar, y te vuelven a pagar. Con '
            'esto se cierra la última ronda: ya no queda nada más por '
            'hacer que mostrar las cartas.',
      ),
      // Paso 11 — showdown: la mano termina mostrando.
      TableStep(
        table: _stage6(
          hero: _c4Hero,
          board: _c4Board,
          villainSlot: _c4VillainSlot,
          villain: _c4Villain,
          heroStack: 85,
          villainStack: 85,
          pot: 30.5,
        ),
        anchor: TableAnchor.pot,
        dimOthers: false,
        bubble: 'Se muestran las cartas: tu mano vale más. Así termina '
            'esta mano — por showdown, una de las dos formas de terminar '
            'que ya conocés.',
      ),
      // Paso 12 — otra mano, más corta: alguien tiene que decidir frente
      // a una apuesta.
      TableStep(
        table: _stage6(
          hero: const ['?', '?'],
          board: _c4FoldBoard,
          villainSlot: _c4VillainSlot,
          bets: const {0: 6},
          actions: const {0: 'APUESTA'},
          heroStack: 94,
          pot: 6,
        ),
        anchor: const TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0), TableAnchor.seat(_c4VillainSlot)],
        bubble: 'Ahora una mano bien distinta, más corta: apostás en el '
            'flop, y el rival tiene que decidir si paga o se retira.',
      ),
      // Paso 13 — el rival se retira: la mano termina por fold.
      TableStep(
        table: _stage6(
          hero: const ['?', '?'],
          board: _c4FoldBoard,
          villainSlot: _c4VillainSlot,
          villainFolded: true,
          heroStack: 94,
          pot: 6,
        ),
        anchor: const TableAnchor.seat(_c4VillainSlot),
        highlight: const [TableAnchor.seat(_c4VillainSlot)],
        bubble: 'El rival se retira: la mano termina ahí mismo, sin '
            'mostrar nada. Ganás por fold — la otra forma de terminar una '
            'mano, sin necesidad de llegar al río.',
      ),
    ]);
  }
}
