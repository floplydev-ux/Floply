import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de **ejemplo de cierre** — Nivel 8 (C-bet).
class N8ClosingExamples {
  N8ClosingExamples._();

  static final Map<String, TableLessonScript> byId = {
    '8.1': _iniciativaYCbet(),
    '8.2': _tiposDeCbet(),
    '8.3': _cbetSegunBoard(),
    '8.4': _cbetSegunPosicion(),
    '8.5': _frecuenciaYTamanio(),
    '8.6': _enfrentarApuesta(),
  };

  static const _labels = TableBuilder.btnHero;

  static TableSnapshot _flop({
    required List<String> board,
    required List<String> hero,
    Map<int, double> bets = const {},
    Map<int, String> actions = const {},
    Set<int> folded = const {5, 4, 3, 2},
    double? pot,
  }) =>
      TableSnapshot(
        seats: TableBuilder.seats(
          labels: _labels,
          cards: {0: hero, 1: const ['?', '?']},
          bets: bets,
          actions: actions,
          folded: folded,
        ),
        board: board,
        potBb: pot ?? 10,
        buttonSlot: 0,
      );

  // 8.1 — La iniciativa y la c-bet
  static TableLessonScript _iniciativaYCbet() {
    return TableLessonScript([
      TableStep(
        table: _flop(board: const ['Ks', '7h', '2d'], hero: const ['Ah', 'Qd']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'Abriste preflop y CO llamó. Llegaste al flop con la '
            'INICIATIVA — el último en apostar o subir. '
            'El rival no sabe qué tenés y teme que mejoraste el board.',
      ),
      TableStep(
        table: _flop(
          board: const ['Ks', '7h', '2d'],
          hero: const ['Ah', 'Qd'],
          bets: const {0: 5.0},
          actions: const {0: 'C-BET'},
          pot: 15,
        ),
        anchor: TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0)],
        bubble: 'CONTINUATION BET (c-bet): apostás al flop porque tenés '
            'la iniciativa. No necesitás haber mejorado — el rival '
            'no sabe si pegaste o no el board.',
      ),
      TableStep(
        table: _flop(board: const ['Ks', '7h', '2d'], hero: const ['Ah', 'Qd']),
        anchor: TableAnchor.board,
        dimOthers: false,
        bubble: 'La c-bet funciona porque el rival foldea muchas veces. '
            'En un board seco como K-7-2, la mayoria de las manos '
            'del rival no conectaron — foldea y vos te quedás con el bote.',
      ),
    ]);
  }

  // 8.2 — C-bet por valor, farol y con proyecto
  static TableLessonScript _tiposDeCbet() {
    return TableLessonScript([
      TableStep(
        table: _flop(
          board: const ['Ks', '7h', '2d'],
          hero: const ['Kh', 'Qd'],
          bets: const {0: 5.0},
          actions: const {0: 'C-BET'},
          pot: 15,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'C-BET POR VALOR: hiciste top pair con K♥Q♦ en el flop K-7-2. '
            'Apostás para extraer valor de manos peores (K con peor kicker, '
            'pares medianos). Querés que el rival llame.',
      ),
      TableStep(
        table: _flop(
          board: const ['Ks', '7h', '2d'],
          hero: const ['Ah', 'Jd'],
          bets: const {0: 5.0},
          actions: const {0: 'C-BET'},
          pot: 15,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'C-BET COMO FAROL: no pegaste (AJ vs K-7-2). '
            'Apostás porque el rival tampoco pegó muchas veces '
            'y puede foldear. Si llama, podés mejorar o parar.',
      ),
      TableStep(
        table: _flop(
          board: const ['Jh', '9c', '3h'],
          hero: const ['Kh', 'Qh'],
          bets: const {0: 5.0},
          actions: const {0: 'C-BET'},
          pot: 15,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'C-BET CON PROYECTO: KQ♥ tiene flush draw + OESD en J-9-3♥. '
            'Apostás con mucha equity (~50%). Si te llaman, '
            'podés ganar igualmente completando el draw.',
      ),
    ]);
  }

  // 8.3 — C-bet según el board
  static TableLessonScript _cbetSegunBoard() {
    return TableLessonScript([
      TableStep(
        table: _flop(board: const ['Ks', '7h', '2d'], hero: const ['Ac', 'Jd']),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'BOARD SECO (K-7-2 rainbow): el rival tiene pocos draws. '
            'C-bet casi siempre con cualquier mano — el board "le pertenece" '
            'al que abrió y la mayoría de las manos del rival no conectaron.',
      ),
      TableStep(
        table: _flop(board: const ['Jh', '9h', '8d'], hero: const ['Ac', 'Kd']),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'BOARD COORDINADO (J-9-8, flush draw): el rival tiene muchos '
            'draws. C-bet más selectivo — apostá con manos fuertes o '
            'buenas manos hechas, no en automático con carta alta.',
      ),
      TableStep(
        table: _flop(
          board: const ['Jh', '9h', '8d'],
          hero: const ['Ac', 'Kd'],
          folded: const {5, 3, 2},
        ),
        anchor: TableAnchor.board,
        dimOthers: false,
        bubble: 'BOTE MULTIWAY (3+ jugadores): c-bet con manos muy fuertes '
            'solamente. Alguien en el grupo conectó el board con más frecuencia '
            '— la c-bet como farol funciona mal en multiway.',
      ),
    ]);
  }

  // 8.4 — C-bet según la posición
  static TableLessonScript _cbetSegunPosicion() {
    return TableLessonScript([
      TableStep(
        table: _flop(board: const ['Ks', '7h', '2d'], hero: const ['Ah', 'Jd']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'C-BET EN POSICIÓN (BTN vs CO): apostás viendo antes '
            'qué hace el rival en calles futuras. Si chequea el turn, '
            'podés chequear atrás para control — o apostar de nuevo.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: const {
              0: 'CO',
              5: 'SB',
              4: 'BB',
              3: 'UTG',
              2: 'HJ',
              1: 'BTN',
            },
            cards: const {0: ['Ah', 'Jd'], 1: const ['?', '?']},
            folded: const {5, 4, 3, 2},
            bets: const {0: 5.0},
            actions: const {0: 'C-BET'},
          ),
          board: const ['Ks', '7h', '2d'],
          potBb: 15,
          buttonSlot: 1,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'C-BET FUERA DE POSICIÓN (CO vs BTN): sos el primero en '
            'hablar postflop. Hacés c-bet con manos fuertes; con manos '
            'medianas o draws, chequeás para no regalar información.',
      ),
    ]);
  }

  // 8.5 — Frecuencia y tamaño
  static TableLessonScript _frecuenciaYTamanio() {
    return TableLessonScript([
      TableStep(
        table: _flop(
          board: const ['Ks', '7h', '2d'],
          hero: const ['Ah', 'Kd'],
          bets: const {0: 3.3},
          actions: const {0: 'C-BET 33%'},
          pot: 13.3,
        ),
        anchor: TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0)],
        bubble: 'TAMAÑO PEQUEÑO (33% del bote): da odds baratos al rival, '
            'pero es rentable en boards secos donde tenés ventaja de rango. '
            'Apostás frecuente, con muchas manos.',
      ),
      TableStep(
        table: _flop(
          board: const ['Jh', '9h', '8d'],
          hero: const ['Ah', 'Kh'],
          bets: const {0: 6.6},
          actions: const {0: 'C-BET 66%'},
          pot: 16.6,
        ),
        anchor: TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0)],
        bubble: 'TAMAÑO GRANDE (66% del bote): en boards coordinados '
            'apostás menos seguido, pero con manos fuertes. '
            'La apuesta más grande protege tu mano hecha mejor.',
      ),
      TableStep(
        table: _flop(board: const ['Ks', '7h', '2d'], hero: const ['Ah', 'Kd']),
        anchor: TableAnchor.board,
        dimOthers: false,
        bubble: 'Regla: boards secos → tamaño chico y frecuencia alta. '
            'Boards coordinados → tamaño grande y frecuencia baja. '
            'El equilibrio protege tu rango contra rivales atentos.',
      ),
    ]);
  }

  // 8.6 — Enfrentar una apuesta postflop
  static TableLessonScript _enfrentarApuesta() {
    return TableLessonScript([
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: const {0: 'BB', 5: 'SB', 4: 'CO', 3: 'BTN', 2: 'HJ', 1: 'UTG'},
            cards: const {0: ['Ks', 'Jh'], 4: const ['?', '?']},
            folded: const {5, 3, 2, 1},
            bets: const {4: 5.0},
            actions: const {4: 'C-BET'},
          ),
          board: const ['Kd', '8h', '3c'],
          potBb: 15,
          buttonSlot: 3,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'CO hace c-bet en K-8-3. Vos estás en BB con K♠J♥. '
            'Pegaste top pair — acá la respuesta es CALL o CHECK-RAISE.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: const {0: 'BB', 5: 'SB', 4: 'CO', 3: 'BTN', 2: 'HJ', 1: 'UTG'},
            cards: const {0: ['7h', '8d'], 4: const ['?', '?']},
            folded: const {5, 3, 2, 1},
            bets: const {4: 5.0, 0: 15.0},
            actions: const {4: 'C-BET', 0: 'CHECK-RAISE'},
          ),
          board: const ['Kd', '8h', '3c'],
          potBb: 25,
          buttonSlot: 3,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.bet(0)],
        bubble: 'CHECK-RAISE: chequeas, CO apuesta, vos subís. '
            'Con 7♥8♦ tenés middle pair y gutshot en K-8-3. '
            'El check-raise como semi-farol pone presión y da equity.',
      ),
      TableStep(
        table: TableSnapshot(
          seats: TableBuilder.seats(
            labels: const {0: 'BB', 5: 'SB', 4: 'CO', 3: 'BTN', 2: 'HJ', 1: 'UTG'},
            cards: const {0: ['Jh', 'Tc'], 4: const ['?', '?']},
            folded: const {5, 3, 2, 1},
            bets: const {4: 5.0, 0: 5.0},
            actions: const {4: 'C-BET', 0: 'CALL (FLOAT)'},
          ),
          board: const ['Kd', '8h', '3c'],
          potBb: 20,
          buttonSlot: 3,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'FLOAT: llamás la c-bet sin mano real, esperando chequearlo '
            'en el turn para apostar vos. Con JT en K-8-3 tenés gutshot '
            'y el rival puede chequear el turn mostrando debilidad.',
      ),
    ]);
  }
}
