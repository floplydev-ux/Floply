/// Contenido del **piloto visual** (fase de prueba, ver
/// `academy_visual_theories.dart`): las lecciones visuales de T093, T082,
/// T098 y T099.
///
/// Reutiliza exactamente los mismos ejemplos numéricos que la teoría escrita
/// de cada teoría (mismas cartas, mismo board) para que la experiencia
/// visual y la ficha escrita que viene después cuenten la misma historia, no
/// una segunda versión distinta.
library;

import 'table_lesson.dart';
import 'visual_theory.dart';

/// Mesa mínima para el piloto: solo el héroe, el resto de los asientos
/// vacíos. Acá lo único relevante es leer las cartas del héroe contra el
/// board — un rival con nombre y stack de utilería no aporta nada a la
/// lección y solo compite visualmente con lo que sí importa.
TableSnapshot _stage({List<String> hero = const [], List<String> board = const []}) {
  return TableSnapshot(
    seats: [
      SeatState(slot: 0, label: '', isHero: true, cards: hero),
      const SeatState.empty(1),
      const SeatState.empty(2),
      const SeatState.empty(3),
      const SeatState.empty(4),
      const SeatState.empty(5),
    ],
    board: board,
    buttonSlot: 0,
  );
}

const _verLaTeoria = 'VER LA TEORÍA';

class VisualPilotLessons {
  VisualPilotLessons._();

  // ------------------------------------------------------------------
  // T093 — Set
  // ------------------------------------------------------------------
  static VisualTheoryLesson set() {
    const hero = ['8s', '8d'];
    const flop = ['Kc', '8h', '3d'];

    return VisualTheoryLesson('T093', [
      VisualTheoryStep(
        table: _stage(hero: hero),
        anchor: TableAnchor.heroCards,
        bubble: 'Tenés 8♠8♦: ya arrancás con una pareja.',
        caption: 'Es una pareja servida — la tenés desde antes del flop.',
      ),
      VisualTheoryStep(
        table: _stage(hero: hero, board: flop),
        anchor: TableAnchor.board,
        cardGlow: const {CardRef.board(1)},
        bubble: 'El flop trae otro 8.',
        caption: 'Una de las tres cartas del flop repite el valor de tu pareja.',
      ),
      VisualTheoryStep(
        table: _stage(hero: hero, board: flop),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        cardGlow: const {
          CardRef.hero(0),
          CardRef.hero(1),
          CardRef.board(1),
        },
        bubble: '8♠ + 8♦ + 8♥: tenés trío de ochos.',
        caption: 'Como dos de los tres ochos son tuyos, a esto se lo llama SET.',
      ),
      VisualTheoryStep(
        table: _stage(hero: hero, board: flop),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        cardGlow: const {
          CardRef.hero(0),
          CardRef.hero(1),
          CardRef.board(1),
        },
        bubble: 'Nadie ve venir un trío cuando solo hay un 8 a la vista.',
        caption: 'El set es una de las manos más fuertes y disimuladas del póker.',
        buttonLabel: _verLaTeoria,
      ),
    ]);
  }

  // ------------------------------------------------------------------
  // T082 — Proyectos (draws)
  // ------------------------------------------------------------------
  static VisualTheoryLesson draws() {
    const hero = ['9c', '8d'];
    const flop = ['7s', '6h', '2c'];

    return VisualTheoryLesson('T082', [
      VisualTheoryStep(
        table: _stage(hero: hero),
        anchor: TableAnchor.heroCards,
        bubble: 'Tenés 9♣8♦: dos cartas seguidas.',
        caption: 'Son conectores: si el board ayuda, apuntan a una escalera.',
      ),
      VisualTheoryStep(
        table: _stage(hero: hero, board: flop),
        anchor: TableAnchor.board,
        cardGlow: const {CardRef.board(0), CardRef.board(1)},
        bubble: 'El flop trae 7-6-2.',
        caption: 'El 7 y el 6 se suman a tu 9 y tu 8.',
      ),
      VisualTheoryStep(
        table: _stage(hero: hero, board: flop),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        cardGlow: const {
          CardRef.hero(0),
          CardRef.hero(1),
          CardRef.board(0),
          CardRef.board(1),
        },
        bubble: '9-8-7-6: cuatro seguidas, pero todavía no es escalera.',
        caption:
            'Te falta una carta: un 5 o un 10 la completan — eso es un proyecto abierto.',
      ),
      VisualTheoryStep(
        table: _stage(hero: hero, board: flop),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'Todavía no la tenés — pero podés completarla.',
        caption: 'Por eso se llama "proyecto": todavía no es una mano hecha.',
        buttonLabel: _verLaTeoria,
      ),
    ]);
  }

  // ------------------------------------------------------------------
  // T098 — Los nuts
  // ------------------------------------------------------------------
  static VisualTheoryLesson nuts() {
    const hero = ['As', 'Ts'];
    const board = ['Ks', 'Qs', 'Js', 'Td', '2h'];

    return VisualTheoryLesson('T098', [
      VisualTheoryStep(
        table: _stage(hero: hero),
        anchor: TableAnchor.heroCards,
        bubble: 'Tenés A♠T♠.',
        caption: 'Dos cartas altas del mismo palo.',
      ),
      VisualTheoryStep(
        table: _stage(hero: hero, board: board),
        anchor: TableAnchor.board,
        bubble: 'El board ya está completo: K♠Q♠J♠T♦2♥.',
        caption: 'Con estas 5 cartas en la mesa, ¿cuál sería la mejor mano posible?',
      ),
      VisualTheoryStep(
        table: _stage(hero: hero, board: board),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        cardGlow: const {
          CardRef.hero(0),
          CardRef.hero(1),
          CardRef.board(0),
          CardRef.board(1),
          CardRef.board(2),
        },
        bubble: 'A♠ + T♠ + K♠Q♠J♠: escalera real de picas.',
        caption: 'Es la mejor mano que se puede armar con este board exacto.',
      ),
      VisualTheoryStep(
        table: _stage(hero: hero, board: board),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'Nadie te puede ganar: estos son los nuts.',
        caption: 'Los nuts son el techo de fuerza de ESE board en particular.',
        buttonLabel: _verLaTeoria,
      ),
    ]);
  }

  // ------------------------------------------------------------------
  // T099 — Cerca de los nuts
  // ------------------------------------------------------------------
  static VisualTheoryLesson nearNuts() {
    const hero = ['Ad', 'Kc'];
    const board = ['Ks', 'Qs', 'Js', 'Td', '2h'];

    return VisualTheoryLesson('T099', [
      VisualTheoryStep(
        table: _stage(hero: hero),
        anchor: TableAnchor.heroCards,
        bubble: 'Ahora tenés A♦K♣, sobre el mismo board de antes.',
        caption: 'Otra combinación posible sobre esa misma mesa.',
      ),
      VisualTheoryStep(
        table: _stage(hero: hero, board: board),
        anchor: TableAnchor.board,
        bubble: 'El board: K♠Q♠J♠T♦2♥.',
        caption: 'El mismo board del ejemplo de los nuts.',
      ),
      VisualTheoryStep(
        table: _stage(hero: hero, board: board),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        cardGlow: const {
          CardRef.hero(0),
          CardRef.board(0),
          CardRef.board(1),
          CardRef.board(2),
          CardRef.board(3),
        },
        bubble: 'A♦ + K-Q-J-T: escalera, pero sin color.',
        caption: 'Usás el As y cuatro cartas del board — sin ser todas del mismo palo.',
      ),
      VisualTheoryStep(
        table: _stage(hero: hero, board: board),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'Muy fuerte… pero le pierde a A♠T♠ (la escalera de color).',
        caption: 'Por eso esta mano está cerca de los nuts, no en los nuts.',
        buttonLabel: _verLaTeoria,
      ),
    ]);
  }
}
