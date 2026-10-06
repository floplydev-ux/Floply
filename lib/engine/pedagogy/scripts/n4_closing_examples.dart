import '../table_lesson.dart';
import 'table_builder.dart';

/// Guiones de **ejemplo de cierre** — Nivel 4.
class N4ClosingExamples {
  N4ClosingExamples._();

  static final Map<String, TableLessonScript> byId = {
    '4.1': _tiposDeManoPrincipal(),
    '4.2': _fuerzaDeManoPrincipal(),
    '4.3': _texturasDeBoardPrincipal(),
    '4.4': _proyectosPrincipal(),
    '4.5': _manoHechaFlop(),
    '4.6': _manosGrandesYNuts(),
  };

  static const _labels = TableBuilder.btnHero;

  /// Mesa 6-max básica con solo el héroe activo (resto foldeados).
  static TableSnapshot _preflop({
    List<String> hero = const ['?', '?'],
  }) =>
      TableSnapshot(
        seats: TableBuilder.seats(
          labels: _labels,
          cards: {0: hero},
          folded: const {5, 4, 3, 2, 1},
        ),
        buttonSlot: 0,
      );

  /// Mesa en el flop con héroe y un rival visible (resto foldeados).
  static TableSnapshot _flop({
    required List<String> board,
    List<String> hero = const ['?', '?'],
    List<String> rival = const ['?', '?'],
    bool rivalFolded = true,
    double pot = 10,
  }) =>
      TableSnapshot(
        seats: TableBuilder.seats(
          labels: _labels,
          cards: {0: hero, if (!rivalFolded) 1: rival},
          folded: {5, 4, 3, 2, if (rivalFolded) 1},
        ),
        board: board,
        potBb: pot,
        buttonSlot: 0,
      );

  // ================================================================
  // 4.1 — Tipos de mano inicial
  // ================================================================
  static TableLessonScript _tiposDeManoPrincipal() {
    return TableLessonScript([
      // Paso 1 — par servido (pocket pair)
      TableStep(
        table: _preflop(hero: const ['8h', '8d']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'PAR SERVIDO (pocket pair): dos cartas del mismo rango. '
            'Se escribe "88" sin letra. No importa el palo — son 6 combos '
            'posibles para cualquier par.',
      ),
      // Paso 2 — suited
      TableStep(
        table: _preflop(hero: const ['As', 'Ks']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'SUITED (mismo palo): las dos cartas son del mismo palo. '
            'Se escribe "AKs" (la "s" indica suited). '
            'Tiene potencial de proyecto de color.',
      ),
      // Paso 3 — offsuit
      TableStep(
        table: _preflop(hero: const ['Ah', 'Kd']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'OFFSUIT (distinto palo): cartas de palos diferentes. '
            'Se escribe "AKo" (la "o" indica offsuit). '
            'Hay 12 combos de AKo contra 4 de AKs.',
      ),
      // Paso 4 — conectadas
      TableStep(
        table: _preflop(hero: const ['9c', '8c']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'CONECTADAS: dos cartas separadas por exactamente un rango '
            '(9-8, 7-6…). Tienen mayor potencial de escalera. '
            'Acá es además suited: conector suited.',
      ),
      // Paso 5 — broadways
      TableStep(
        table: _preflop(hero: const ['Qh', 'Jd']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'BROADWAYS: las cartas altas A, K, Q, J y T. '
            'Una mano broadway conecta con la escalera más alta posible '
            '(A-K-Q-J-T).',
      ),
      // Paso 6 — mano con As
      TableStep(
        table: _preflop(hero: const ['Ah', '4c']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'MANO CON AS: cualquier mano que tenga un as. '
            'El as es la carta más alta y también puede jugar como 1 en '
            'una escalera baja (A-2-3-4-5).',
      ),
    ]);
  }

  // ================================================================
  // 4.2 — Fuerza de la mano inicial
  // ================================================================
  static TableLessonScript _fuerzaDeManoPrincipal() {
    return TableLessonScript([
      // Paso 1 — premium
      TableStep(
        table: _preflop(hero: const ['Ah', 'As']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'MANO PREMIUM: AA, KK, QQ, JJ y AKs. Son las manos más '
            'fuertes preflop — se juegan siempre con valor, incluso '
            'en all-in.',
      ),
      // Paso 2 — par mediano
      TableStep(
        table: _preflop(hero: const ['8h', '8d']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'PAR MEDIANO: pares del 66 al 99. Son fuertes, pero '
            'vulnerables a cartas altas en el board. '
            'Se juegan con cuidado si cae una J, Q o K.',
      ),
      // Paso 3 — par pequeño
      TableStep(
        table: _preflop(hero: const ['3h', '3d']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'PAR PEQUEÑO: del 22 al 55. Su valor principal es mejorar '
            'a un set en el flop. Sin mejora, a menudo quedan por debajo '
            'de las cartas del board.',
      ),
      // Paso 4 — mano dominada
      TableStep(
        table: _preflop(hero: const ['Kh', 'Jd']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'MANO DOMINADA: una mano que comparte el rango alto con '
            'otra mejor (KJ vs AK, o KJ vs KQ). Si hacés pareja, el rival '
            'con mejor kicker gana casi siempre.',
      ),
      // Paso 5 — mano especulativa
      TableStep(
        table: _preflop(hero: const ['7h', '6h']),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'MANO ESPECULATIVA: conectores suited, pares pequeños. '
            'Tienen poco valor de por sí, pero pueden mejorar mucho '
            '(escalera, color, set). Se juegan buscando esa mejora.',
      ),
    ]);
  }

  // ================================================================
  // 4.3 — Texturas de board
  // ================================================================
  static TableLessonScript _texturasDeBoardPrincipal() {
    return TableLessonScript([
      // Paso 1 — board seco
      TableStep(
        table: _flop(
          board: const ['Ks', '9h', '2d'],
          hero: const ['Ah', 'Kd'],
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'BOARD SECO (dry): cartas sin conexión entre sí y de palos '
            'distintos. Pocas posibilidades de escalera o color. '
            'Favorece a quien ya tiene una mano hecha.',
      ),
      // Paso 2 — board coordinado
      TableStep(
        table: _flop(
          board: const ['Td', '9c', '8d'],
          hero: const ['Jh', 'Qs'],
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'BOARD COORDINADO: cartas consecutivas o del mismo palo que '
            'crean muchos proyectos. T-9-8 conecta con cualquier J-7 para '
            'escalera. Hay que tener cuidado con los draws del rival.',
      ),
      // Paso 3 — board monocromo
      TableStep(
        table: _flop(
          board: const ['Jh', '8h', '3h'],
          hero: const ['Ah', 'Kd'],
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'BOARD MONOCROMO: los tres palos del flop son iguales. '
            'Cualquier jugador con dos cartas del mismo palo ya tiene '
            'proyecto de color — el más peligroso.',
      ),
      // Paso 4 — board rainbow
      TableStep(
        table: _flop(
          board: const ['As', '7h', '2c'],
          hero: const ['Ah', 'Kd'],
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'BOARD RAINBOW: tres palos distintos. Ningún proyecto de '
            'color es posible aún. Reduce la cantidad de manos peligrosas '
            'que puede tener el rival.',
      ),
      // Paso 5 — board pareado
      TableStep(
        table: _flop(
          board: const ['Qh', 'Qd', '5c'],
          hero: const ['Ah', 'Ks'],
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'BOARD PAREADO: una carta se repite en el flop. '
            'Si el rival tiene una Q en la mano, tiene trío. '
            'Este board siempre oculta manos muy fuertes.',
      ),
    ]);
  }

  // ================================================================
  // 4.4 — Proyectos y cartas clave
  // ================================================================
  static TableLessonScript _proyectosPrincipal() {
    return TableLessonScript([
      // Paso 1 — proyecto de escalera abierto (OESD)
      TableStep(
        table: _flop(
          board: const ['Jd', '9c', '3s'],
          hero: const ['Th', 'Qh'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'ESCALERA ABIERTA (OESD): Q-J-T-9 son cuatro cartas '
            'consecutivas. Entra un K o un 8 y hacés escalera. '
            'Son 8 outs — el proyecto de escalera más potente.',
      ),
      // Paso 2 — proyecto de color (flush draw)
      TableStep(
        table: _flop(
          board: const ['Kh', '7h', '2d'],
          hero: const ['Ah', 'Jh'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'PROYECTO DE COLOR (flush draw): tenés 4 cartas del mismo '
            'palo (A♥J♥ + K♥7♥). Cualquier corazón en el turn o el river '
            'completa el color. Son 9 outs.',
      ),
      // Paso 3 — gutshot (proyecto de escalera interior)
      TableStep(
        table: _flop(
          board: const ['Qd', '9c', '3s'],
          hero: const ['Jh', '7d'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'GUTSHOT (escalera interior): Q-J-?-9 con un hueco en el '
            'medio. Solo un T completa la escalera. Son 4 outs — la mitad '
            'que la escalera abierta.',
      ),
      // Paso 4 — proyecto backdoor
      TableStep(
        table: _flop(
          board: const ['Kd', '8c', '3s'],
          hero: const ['Ah', 'Qh'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'BACKDOOR: solo tenés 2 cartas del mismo palo (A♥Q♥). '
            'Para el color, necesitás DOS corazones más (turn Y river). '
            'Es un proyecto débil, pero se suma al valor de la mano.',
      ),
      // Paso 5 — carta peligrosa en el turn
      TableStep(
        table: _flop(
          board: const ['Kh', '8h', '2d', 'Jh'],
          hero: const ['As', 'Kd'],
        ),
        anchor: TableAnchor.board,
        highlight: const [TableAnchor.board],
        bubble: 'CARTA PELIGROSA: el turn J♥ completa cualquier color de '
            'corazones. Tenés top pair, pero el board ahora es monocromo '
            '— el rival con un corazón ya tiene proyecto real.',
      ),
    ]);
  }

  // ================================================================
  // 4.5 — Tu mano hecha en el flop
  // ================================================================
  static TableLessonScript _manoHechaFlop() {
    return TableLessonScript([
      // Paso 1 — top pair y middle pair
      TableStep(
        table: _flop(
          board: const ['Ks', '7h', '2d'],
          hero: const ['Kh', 'Qd'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'TOP PAIR: hacés pareja con la carta MÁS ALTA del board. '
            'K♥ + K♠ = pareja de reyes (top pair). Kicker Q — el mejor '
            'kicker posible para esa pareja.',
      ),
      // Paso 2 — bottom pair y middle pair comparación
      TableStep(
        table: _flop(
          board: const ['Ks', '7h', '2d'],
          hero: const ['7d', 'Ac'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'MIDDLE PAIR: pareja con la carta DEL MEDIO del board (7♦ + 7♥). '
            'El kicker As es alto, pero el rival con K en la mano ya te '
            'supera con top pair.',
      ),
      // Paso 3 — overpair
      TableStep(
        table: _flop(
          board: const ['Qs', '7h', '2d'],
          hero: const ['Kh', 'Kd'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'OVERPAIR: par servido en mano que supera a TODAS las cartas '
            'del board. KK > Q (la más alta del board). Es una mano fuerte, '
            'pero vulnerable al set del rival.',
      ),
      // Paso 4 — set
      TableStep(
        table: _flop(
          board: const ['Qs', '7h', '2d'],
          hero: const ['7d', '7c'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'SET: par servido en mano (7♦7♣) + la misma carta en el board '
            '(7♥) = trío. El set es la mano escondida más poderosa: el rival '
            'raramente lo puede adivinar.',
      ),
      // Paso 5 — doble pareja y trips
      TableStep(
        table: _flop(
          board: const ['Ks', '7h', '2d'],
          hero: const ['Kh', '7d'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'DOBLE PAREJA: K♥+K♠ y 7♦+7♥ al mismo tiempo. Es más fuerte '
            'que una sola pareja, pero más débil que un set. '
            'La doble pareja más alta gana si el rival también tiene dos pares.',
      ),
    ]);
  }

  // ================================================================
  // 4.6 — Manos grandes y nuts
  // ================================================================
  static TableLessonScript _manosGrandesYNuts() {
    return TableLessonScript([
      // Paso 1 — escalera hecha
      TableStep(
        table: _flop(
          board: const ['Qh', 'Jd', '9s', 'Th', '3c'],
          hero: const ['Ks', '8d'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'ESCALERA: K-Q-J-T-9 — cinco rangos consecutivos. '
            'Es más fuerte que cualquier color, a menos que el rival '
            'también tenga escalera más alta.',
      ),
      // Paso 2 — color hecho
      TableStep(
        table: _flop(
          board: const ['Kh', '8h', '3h', 'Ah', '2d'],
          hero: const ['Qh', 'Jh'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'COLOR: cinco cartas del mismo palo. Q♥J♥ + K♥8♥3♥A♥ = '
            'color de corazones. El color más alto (por la carta más alta) '
            'gana si dos jugadores tienen color.',
      ),
      // Paso 3 — full house
      TableStep(
        table: _flop(
          board: const ['Kd', 'Ks', 'Qh', 'Kh', '7c'],
          hero: const ['Qd', 'Qc'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'FULL HOUSE: trío + pareja. Q♦Q♣ + Q♥ = trío de damas; '
            'K♦K♠K♥ — espera, en este board vos tenés full de damas con '
            'reyes (QQQ-KK). El full más alto gana.',
      ),
      // Paso 4 — los nuts
      TableStep(
        table: _flop(
          board: const ['Ks', 'Qh', 'Jd', 'Th', '2c'],
          hero: const ['As', '9d'],
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards, TableAnchor.board],
        bubble: 'LOS NUTS: la mejor mano POSIBLE en este board. '
            'A-K-Q-J-T es la Broadway — la escalera más alta. '
            'Nadie te puede ganar. En este river, los nuts son esta escalera.',
      ),
      // Paso 5 — bluff catcher
      TableStep(
        table: _flop(
          board: const ['Kd', '8c', '3s', '2h', '7d'],
          hero: const ['Qh', 'Qd'],
          rival: const ['?', '?'],
          rivalFolded: false,
          pot: 25,
        ),
        anchor: TableAnchor.heroCards,
        highlight: const [TableAnchor.heroCards],
        bubble: 'BLUFF CATCHER: QQ es una pareja modesta en este board seco. '
            'No gana a muchas manos de valor del rival, pero puede ganar '
            'si el rival está bluffeando. Se llama así porque "atrapa" '
            'los bluffs.',
      ),
    ]);
  }
}
