import 'concept.dart';
import 'concept_ids.dart';

/// Catálogo de conceptos + grafo de prerrequisitos (knowledge graph).
///
/// Es de solo lectura una vez construido. La instancia por defecto
/// ([ConceptRegistry.standard]) trae los conceptos del vertical slice
/// (posición + apertura preflop) más varios conceptos posteriores ya
/// declarados para que el grafo sea real desde el principio.
class ConceptRegistry {
  ConceptRegistry(List<Concept> concepts)
      : _byId = {for (final c in concepts) c.id: c} {
    _validateGraph();
  }

  final Map<String, Concept> _byId;

  Iterable<Concept> get all => _byId.values;

  bool has(String id) => _byId.containsKey(id);

  Concept byId(String id) {
    final concept = _byId[id];
    if (concept == null) {
      throw ArgumentError('Concepto desconocido: "$id"');
    }
    return concept;
  }

  Concept? tryById(String id) => _byId[id];

  List<Concept> inCategory(ConceptCategory category) =>
      all.where((c) => c.category == category).toList(growable: false);

  /// Prerrequisitos directos de [id].
  List<String> directPrerequisites(String id) => byId(id).prerequisites;

  /// Todos los prerrequisitos (transitivos) de [id].
  Set<String> allPrerequisites(String id) {
    final result = <String>{};
    final stack = [...byId(id).prerequisites];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (result.add(current)) {
        stack.addAll(byId(current).prerequisites);
      }
    }
    return result;
  }

  /// `true` si, dado el conjunto [mastered] de conceptos dominados, se
  /// cumplen todos los prerrequisitos de [id] (es decir, se puede
  /// introducir).
  bool isUnlockable(String id, Set<String> mastered) =>
      byId(id).prerequisites.every(mastered.contains);

  /// Orden topológico de todos los conceptos (prerrequisitos primero).
  List<Concept> topologicalOrder() {
    final visited = <String>{};
    final result = <Concept>[];

    void visit(String id) {
      if (!visited.add(id)) return;
      for (final pre in byId(id).prerequisites) {
        visit(pre);
      }
      result.add(byId(id));
    }

    for (final id in _byId.keys) {
      visit(id);
    }
    return result;
  }

  void _validateGraph() {
    // Referencias colgantes.
    for (final concept in _byId.values) {
      for (final pre in concept.prerequisites) {
        if (!_byId.containsKey(pre)) {
          throw StateError(
              'El concepto "${concept.id}" depende de "$pre", que no existe');
        }
      }
    }
    // Ciclos.
    final white = _byId.keys.toSet();
    final gray = <String>{};
    final black = <String>{};

    bool hasCycle(String id) {
      white.remove(id);
      gray.add(id);
      for (final pre in _byId[id]!.prerequisites) {
        if (black.contains(pre)) continue;
        if (gray.contains(pre)) return true;
        if (hasCycle(pre)) return true;
      }
      gray.remove(id);
      black.add(id);
      return false;
    }

    while (white.isNotEmpty) {
      if (hasCycle(white.first)) {
        throw StateError('El grafo de conceptos tiene un ciclo');
      }
    }
  }

  /// Registro estándar de la app.
  factory ConceptRegistry.standard() => ConceptRegistry(_standardConcepts);

  static final List<Concept> _standardConcepts = [
    // ---- Fundamentos ----
    const Concept(
      id: ConceptIds.rules,
      name: 'Reglas del juego',
      description:
          'Cómo se juega una mano de No-Limit Hold\'em: ciegas, calles y '
          'acciones posibles.',
      category: ConceptCategory.rules,
      introducedAtLevel: '1.1',
    ),
    const Concept(
      id: ConceptIds.handRanking,
      name: 'Ranking de manos',
      description: 'Jerarquía de las manos de póker, de carta alta a escalera '
          'de color.',
      category: ConceptCategory.handRanking,
      introducedAtLevel: '1.2',
      prerequisites: [ConceptIds.rules],
    ),

    // ---- Posición ----
    const Concept(
      id: ConceptIds.positionNames,
      name: 'Nombres de las posiciones',
      description: 'UTG, HJ, CO, BTN, SB y BB en una mesa 6-max y su orden de '
          'acción.',
      category: ConceptCategory.position,
      introducedAtLevel: '1.3',
      prerequisites: [ConceptIds.rules],
    ),
    const Concept(
      id: ConceptIds.blinds,
      name: 'Las ciegas (SB / BB)',
      description: 'Qué son la ciega chica y la ciega grande y por qué juegan '
          'en desventaja posicional postflop.',
      category: ConceptCategory.position,
      introducedAtLevel: '1.3',
      prerequisites: [ConceptIds.positionNames],
    ),
    const Concept(
      id: ConceptIds.utg,
      name: 'UTG / posición temprana',
      description: 'La primera posición en actuar: la más apretada porque '
          'quedan muchos jugadores por hablar.',
      category: ConceptCategory.position,
      introducedAtLevel: '1.3',
      prerequisites: [ConceptIds.positionNames],
    ),
    const Concept(
      id: ConceptIds.hj,
      name: 'HJ / posición media',
      description: 'Hijack: posición intermedia, puede abrir algo más ancho '
          'que UTG.',
      category: ConceptCategory.position,
      introducedAtLevel: '1.3',
      prerequisites: [ConceptIds.positionNames],
    ),
    const Concept(
      id: ConceptIds.co,
      name: 'CO / posición tardía',
      description: 'Cutoff: penúltima en actuar preflop, rango de apertura '
          'amplio.',
      category: ConceptCategory.position,
      introducedAtLevel: '1.3',
      prerequisites: [ConceptIds.positionNames],
    ),
    const Concept(
      id: ConceptIds.btn,
      name: 'BTN / el botón',
      description: 'La mejor posición: actúa último en todas las calles '
          'postflop.',
      category: ConceptCategory.position,
      introducedAtLevel: '1.3',
      prerequisites: [ConceptIds.positionNames],
    ),
    const Concept(
      id: ConceptIds.positionAdvantage,
      name: 'Ventaja posicional',
      description: 'Actuar último da información y control del bote: por eso '
          'las posiciones tardías abren más manos.',
      category: ConceptCategory.position,
      introducedAtLevel: '1.4',
      difficulty: 2,
      prerequisites: [ConceptIds.btn, ConceptIds.blinds],
    ),

    // ---- Apertura preflop ----
    const Concept(
      id: ConceptIds.openingRange,
      name: 'Rango de apertura',
      description: 'El conjunto de manos con las que subimos si somos los '
          'primeros en entrar al bote desde una posición.',
      category: ConceptCategory.preflop,
      introducedAtLevel: '2.1',
      difficulty: 2,
      prerequisites: [ConceptIds.positionAdvantage, ConceptIds.handRanking],
    ),
    const Concept(
      id: ConceptIds.openRaise,
      name: 'Open raise',
      description: 'Subir de entrada (en lugar de igualar o pasar) cuando '
          'nadie entró todavía al bote.',
      category: ConceptCategory.preflop,
      introducedAtLevel: '2.1',
      difficulty: 2,
      prerequisites: [ConceptIds.openingRange],
    ),
    const Concept(
      id: ConceptIds.rangeWidth,
      name: 'Amplitud de rango',
      description: 'Comparar qué tan ancho es un rango de apertura entre una '
          'posición y otra.',
      category: ConceptCategory.ranges,
      introducedAtLevel: '2.2',
      difficulty: 2,
      prerequisites: [ConceptIds.openingRange],
    ),
    const Concept(
      id: ConceptIds.openSizing,
      name: 'Tamaño de apertura',
      description: 'Con cuántas ciegas grandes subir al abrir (típicamente '
          '2–3bb en 6-max).',
      category: ConceptCategory.betting,
      introducedAtLevel: '2.3',
      difficulty: 2,
      prerequisites: [ConceptIds.openRaise],
    ),

    // ---- Defensa / 3-bet (bloqueados en el slice inicial) ----
    const Concept(
      id: ConceptIds.call,
      name: 'Call',
      description: 'Igualar una apuesta para continuar en la mano.',
      category: ConceptCategory.preflop,
      introducedAtLevel: '3.1',
      difficulty: 2,
      prerequisites: [ConceptIds.openRaise],
    ),
    const Concept(
      id: ConceptIds.bbDefense,
      name: 'Defensa de BB',
      description: 'Qué manos defender desde la ciega grande frente a un open '
          'raise.',
      category: ConceptCategory.preflop,
      introducedAtLevel: '3.1',
      difficulty: 3,
      prerequisites: [ConceptIds.call, ConceptIds.blinds],
    ),
    const Concept(
      id: ConceptIds.threeBet,
      name: '3-bet',
      description: 'Re-subir sobre un open raise.',
      category: ConceptCategory.preflop,
      introducedAtLevel: '3.2',
      difficulty: 3,
      prerequisites: [ConceptIds.bbDefense],
    ),
    const Concept(
      id: ConceptIds.threeBetValue,
      name: '3-bet por valor',
      description: 'Re-subir con manos fuertes que quieren jugar un bote '
          'grande.',
      category: ConceptCategory.preflop,
      introducedAtLevel: '3.2',
      difficulty: 3,
      prerequisites: [ConceptIds.threeBet],
    ),
    const Concept(
      id: ConceptIds.threeBetBluff,
      name: '3-bet bluff',
      description: 'Re-subir como farol, idealmente con manos que tienen '
          'buenos bloqueadores.',
      category: ConceptCategory.preflop,
      introducedAtLevel: '3.3',
      difficulty: 4,
      prerequisites: [ConceptIds.threeBetValue, ConceptIds.blockers],
    ),

    // ---- Matemáticas ----
    const Concept(
      id: ConceptIds.equity,
      name: 'Equity',
      description: 'La probabilidad de ganar la mano en el showdown dado el '
          'estado actual.',
      category: ConceptCategory.math,
      introducedAtLevel: '3.1',
      difficulty: 3,
      prerequisites: [ConceptIds.handRanking],
    ),
    const Concept(
      id: ConceptIds.outs,
      name: 'Outs',
      description: 'Cartas que todavía no salieron y que mejoran nuestra mano '
          'a la mejor.',
      category: ConceptCategory.math,
      introducedAtLevel: '3.1',
      difficulty: 2,
      prerequisites: [ConceptIds.equity],
    ),
    const Concept(
      id: ConceptIds.potOdds,
      name: 'Pot odds',
      description: 'La relación entre lo que hay que pagar y lo que se puede '
          'ganar; se compara con la equity.',
      category: ConceptCategory.math,
      introducedAtLevel: '3.2',
      difficulty: 3,
      prerequisites: [ConceptIds.equity, ConceptIds.call],
    ),
    const Concept(
      id: ConceptIds.combos,
      name: 'Combos',
      description: 'Contar cuántas combinaciones concretas de cartas forman '
          'una clase de mano.',
      category: ConceptCategory.math,
      introducedAtLevel: '3.3',
      difficulty: 3,
      prerequisites: [ConceptIds.handRanking],
    ),
    const Concept(
      id: ConceptIds.ev,
      name: 'Valor esperado (EV)',
      description: 'El resultado promedio de una decisión si se repitiera '
          'infinitas veces. Una decisión es buena por su EV, no por el '
          'resultado puntual.',
      category: ConceptCategory.math,
      introducedAtLevel: '3.4',
      difficulty: 3,
      prerequisites: [ConceptIds.potOdds],
    ),
    const Concept(
      id: ConceptIds.equityRealization,
      name: 'Realización de equity',
      description: 'Qué parte de nuestra equity teórica logramos capturar '
          'realmente; la posición la mejora.',
      category: ConceptCategory.math,
      introducedAtLevel: '4.2',
      difficulty: 4,
      prerequisites: [ConceptIds.ev, ConceptIds.positionAdvantage],
    ),

    // ---- Postflop (declarados para el grafo) ----
    const Concept(
      id: ConceptIds.boardTexture,
      name: 'Textura de board',
      description: 'Cómo la estructura del flop (seco, húmedo, conectado) '
          'condiciona la estrategia.',
      category: ConceptCategory.boardTexture,
      introducedAtLevel: '4.1',
      difficulty: 3,
      prerequisites: [ConceptIds.handRanking],
    ),
    const Concept(
      id: ConceptIds.rangeAdvantage,
      name: 'Ventaja de rango',
      description: 'Cuando nuestro rango completo es más fuerte que el del '
          'rival en un board dado.',
      category: ConceptCategory.postflop,
      introducedAtLevel: '4.2',
      difficulty: 4,
      prerequisites: [ConceptIds.boardTexture, ConceptIds.openingRange],
    ),
    const Concept(
      id: ConceptIds.nutAdvantage,
      name: 'Ventaja de nuts',
      description: 'Tener más manos muy fuertes (o el potencial de tenerlas) '
          'que el rival.',
      category: ConceptCategory.postflop,
      introducedAtLevel: '4.2',
      difficulty: 4,
      prerequisites: [ConceptIds.rangeAdvantage],
    ),
    const Concept(
      id: ConceptIds.cbet,
      name: 'Continuation bet',
      description: 'Apostar en el flop tras haber sido el agresor preflop.',
      category: ConceptCategory.betting,
      introducedAtLevel: '4.1',
      difficulty: 3,
      prerequisites: [ConceptIds.openRaise, ConceptIds.boardTexture],
    ),
    const Concept(
      id: ConceptIds.valueBet,
      name: 'Apuesta por valor',
      description: 'Apostar buscando pago de manos peores.',
      category: ConceptCategory.betting,
      introducedAtLevel: '4.3',
      difficulty: 3,
      prerequisites: [ConceptIds.cbet, ConceptIds.equity],
    ),
    const Concept(
      id: ConceptIds.bluff,
      name: 'Farol',
      description: 'Apostar buscando que manos mejores se retiren.',
      category: ConceptCategory.betting,
      introducedAtLevel: '4.3',
      difficulty: 3,
      prerequisites: [ConceptIds.cbet],
    ),
    const Concept(
      id: ConceptIds.bluffCatcher,
      name: 'Bluff catcher',
      description: 'Una mano que solo gana si el rival está faroleando.',
      category: ConceptCategory.postflop,
      introducedAtLevel: '5.1',
      difficulty: 4,
      prerequisites: [ConceptIds.bluff, ConceptIds.potOdds],
    ),
    const Concept(
      id: ConceptIds.blockers,
      name: 'Bloqueadores',
      description: 'Cartas en nuestra mano que reducen las combinaciones de '
          'ciertas manos en el rango rival.',
      category: ConceptCategory.advanced,
      introducedAtLevel: '5.2',
      difficulty: 4,
      prerequisites: [ConceptIds.combos],
    ),
    const Concept(
      id: ConceptIds.overbet,
      name: 'Overbet',
      description: 'Apostar más que el tamaño del bote, típico con rangos muy '
          'polarizados.',
      category: ConceptCategory.betting,
      introducedAtLevel: '5.3',
      difficulty: 5,
      prerequisites: [ConceptIds.polarization, ConceptIds.nutAdvantage],
    ),
    const Concept(
      id: ConceptIds.polarization,
      name: 'Polarización',
      description: 'Un rango de apuesta compuesto por manos muy fuertes y '
          'faroles, con pocas manos intermedias.',
      category: ConceptCategory.advanced,
      introducedAtLevel: '5.2',
      difficulty: 4,
      prerequisites: [ConceptIds.valueBet, ConceptIds.bluff],
    ),

    // ---- Avanzado ----
    const Concept(
      id: ConceptIds.gto,
      name: 'GTO',
      description: 'Estrategia de equilibrio: imposible de explotar aunque el '
          'rival sepa qué hacemos.',
      category: ConceptCategory.gto,
      introducedAtLevel: '6.1',
      difficulty: 5,
      prerequisites: [ConceptIds.ev, ConceptIds.polarization],
    ),
    const Concept(
      id: ConceptIds.mixedStrategies,
      name: 'Estrategias mixtas',
      description: 'Tomar una misma mano y jugarla de dos maneras con cierta '
          'frecuencia (p. ej. 70% call / 30% 3-bet).',
      category: ConceptCategory.gto,
      introducedAtLevel: '6.1',
      difficulty: 5,
      prerequisites: [ConceptIds.gto],
    ),
    const Concept(
      id: ConceptIds.exploit,
      name: 'Explotación',
      description: 'Desviarse del equilibrio para castigar un error concreto '
          'del rival.',
      category: ConceptCategory.gto,
      introducedAtLevel: '6.2',
      difficulty: 5,
      prerequisites: [ConceptIds.gto],
    ),
  ];
}
