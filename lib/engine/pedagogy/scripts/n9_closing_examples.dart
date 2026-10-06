import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de **ejemplo de cierre** — Nivel 9 (Turn y river).
class N9ClosingExamples {
  N9ClosingExamples._();

  static final Map<String, TableLessonScript> byId = {
    '9.1': _reevaluarTurn(),
    '9.2': _barrelOPotControl(),
    '9.3': _riverValor(),
    '9.4': _riverFarol(),
    '9.5': _lineasRiver(),
  };

  static const _labels = TableBuilder.btnHero;

  static TableSnapshot _street({
    required List<String> board,
    required List<String> hero,
    Map<int, double> bets = const {},
    Map<int, String> actions = const {},
    double pot = 20,
  }) =>
      TableSnapshot(
        seats: TableBuilder.seats(
          labels: _labels,
          cards: {0: hero, 1: const ['?', '?']},
          folded: const {5, 4, 3, 2},
          bets: bets,
          actions: actions,
        ),
        board: board,
        potBb: pot,
        buttonSlot: 0,
      );

  // 9.1 — Reevaluar en el turn
  static TableLessonScript _reevaluarTurn() {
    return TableLessonScript([
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Kd'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'Flop K-7-2: tenés top pair (AK). El bote fue chequeado. '
            'Viene el turn — cada carta nueva cambia la situación.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As'],
          hero: const ['Ah', 'Kd'],
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'Turn A♠: CARTA BUENA para vos — mejoraste a doble pareja '
            '(AK). Tu equity subió. Podés apostar para construir el bote.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'Jh'],
          hero: const ['Ah', 'Kd'],
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'Turn J♥: SCARE CARD — el rival con QT ahora tiene escalera '
            '(K-Q-J-T-9 necesita T o A). No mejoró tu mano y le agregó '
            'posibilidades al rival. Revisá si seguir apostando.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', '5s'],
          hero: const ['Ah', 'Kd'],
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'Turn 5♠: BLANK — no cambia nada relevante. '
            'Tu top pair sigue siendo igual de fuerte. '
            'Apostá de nuevo para extraer valor.',
      ),
    ]);
  }

  // 9.2 — Barrel o pot control
  static TableLessonScript _barrelOPotControl() {
    return TableLessonScript([
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c'],
          hero: const ['Ah', 'Kd'],
          bets: const {0: 6.0},
          actions: const {0: 'C-BET'},
          pot: 26,
        ),
        anchor: TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0)],
        bubble: 'Hiciste c-bet en el flop K-7-2 con AK y el rival llamó. '
            'En el turn tenés dos opciones: BARREL (apostar de nuevo) '
            'o chequearlo (pot control).',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As'],
          hero: const ['Ah', 'Kd'],
          bets: const {0: 14.0},
          actions: const {0: 'BARREL'},
          pot: 40,
        ),
        anchor: TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0)],
        bubble: 'DOUBLE BARREL: el turn A♠ te mejora y construís el bote. '
            'Apostás otra vez porque tu mano ganó fuerza. '
            'Con doble pareja AK, querés que llame alguien con K o A peor.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'Jh'],
          hero: const ['Ah', 'Kd'],
        ),
        anchor: TableAnchor.board,
        dimOthers: false,
        bubble: 'POT CONTROL: turn J♥ (scare card). Chequeas para evitar '
            'construir un bote grande con una mano que puede estar '
            'superada. Si el rival chequea atrás, vas al river '
            'con información y un bote manejable.',
      ),
    ]);
  }

  // 9.3 — El river: valor
  static TableLessonScript _riverValor() {
    return TableLessonScript([
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9s'],
          hero: const ['Ah', 'Kd'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'River 9♠. Tenés doble pareja A-K en un board K-7-2-A-9. '
            'Llegaste al final. VALUE BET: apostá para que te pague '
            'alguien con K solo, A solo, o un 9.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9s'],
          hero: const ['Ah', 'Kd'],
          bets: const {0: 12.0},
          actions: const {0: 'VALUE BET'},
          pot: 32,
        ),
        anchor: TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0)],
        bubble: 'VALUE BET: apostás esperando ser llamado por manos peores. '
            'No apostás enorme — querés que llame. '
            'Si apostás muy grande, solo te llama quien te gana.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9s'],
          hero: const ['Ah', 'Qd'],
          bets: const {0: 7.0},
          actions: const {0: 'VALUE FINO'},
          pot: 27,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'VALUE FINO: con AQ (top pair, kicker dama) apostás pequeño. '
            'El rival puede tener A con kicker peor (AT, A9). '
            'Apostás buscando valor de manos que casi empatan.',
      ),
    ]);
  }

  // 9.4 — El river: farol y bluff-catch
  static TableLessonScript _riverFarol() {
    return TableLessonScript([
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Qh', 'Jh'],
          bets: const {0: 18.0},
          actions: const {0: 'FAROL'},
          pot: 38,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.bet(0)],
        bubble: 'FAROL en el river: perdiste el draw (QJ buscaba escalera '
            'o color). Apostás representando una mano fuerte (AK, AA). '
            'El rival tiene que foldear una mano mediana para que funcione.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Kd', '8c'],
          bets: const {1: 18.0},
          actions: const {1: 'FAROL'},
          pot: 38,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'BLUFF CATCH: el rival apostó grande. Tenés K-8 (pareja '
            'de reyes, kicker 8). Decidís si llamar. '
            '¿Puede tener el rival manos que foldearon mejor y ahora farolean?',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Kd', '8c'],
          bets: const {1: 18.0, 0: 18.0},
          actions: const {1: 'FAROL', 0: 'CALL'},
          pot: 56,
        ),
        anchor: TableAnchor.heroCards,
        dimOthers: false,
        bubble: 'Llamás: con K-8 en K-A-9-7-2 el rival necesita AK, A2, A7 '
            'para ganar. Si su rango tiene muchos draws que fallaron, '
            'el call como bluff catcher es rentable.',
      ),
    ]);
  }

  // 9.5 — Líneas de river y polarización
  static TableLessonScript _lineasRiver() {
    return TableLessonScript([
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Ah', 'Kd'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'En el river tenés cuatro líneas posibles: '
            'BET/FOLD, BET, CHECK/CALL, CHECK/FOLD. '
            'Cada una le dice algo al rival sobre tu mano.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Ah', 'Kd'],
          bets: const {0: 25.0},
          actions: const {0: 'BET'},
          pot: 45,
        ),
        anchor: TableAnchor.bet(0),
        highlight: const [TableAnchor.bet(0)],
        bubble: 'RANGO POLARIZADO al apostar en el river: tenés manos '
            'muy fuertes (que quieren valor: doble pareja) O manos '
            'débiles que farolean. Las manos medianas no suelen apostar.',
      ),
      TableStep(
        table: _street(
          board: const ['Kh', '7d', '2c', 'As', '9h'],
          hero: const ['Kd', '8h'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'RANGO CONDENSADO al chequear: manos medias que quieren '
            'llegar al showdown sin pagar más (K8 = pareja media). '
            'Check/call si el rival apuesta con farol. Check/fold si '
            'apostó demasiado para que sea rentable.',
      ),
    ]);
  }
}
