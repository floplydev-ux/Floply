import '../poker/evaluator/hand_strength_tier.dart';
import '../poker/game/opponent_policy.dart';
import '../poker/poker_action.dart';
import '../poker/street.dart';
import '../strategy/decision_math.dart';
import '../strategy/hand_strength.dart';
import '../strategy/opening_ranges.dart';
import 'hero_decision_record.dart';

/// Qué tan sólida fue una decisión, según la información que el héroe
/// tenía disponible en ese momento — nunca una nota fría. Se usa solo
/// para que el Coach elija QUÉ decisión vale la pena mostrar y con qué
/// énfasis; nunca se muestra como un número o una letra al usuario.
enum DecisionQuality {
  /// La jugada de siempre para esa situación — nada que corregir.
  solid,

  /// Bien, pero había un matiz para sacarle más.
  improvable,

  /// Ni buena ni mala en el vacío — depende de información que el propio
  /// héroe también tenía (frecuencia límite, margen de equity chico).
  contextDependent,

  /// Hay motivo real para dudar de esta línea, sin ser un desastre.
  questionable,

  /// El punto más flojo de la mano — la alternativa era claramente
  /// mejor con los números que había sobre la mesa en ese momento.
  costly,
}

/// El análisis del Coach para UNA decisión seleccionada, con el
/// comentario ya listo para mostrar — breve, en tono de mentor pero
/// formal (ver el doc-comment de [CoachAnalyzer]).
class HandDecisionReview {
  const HandDecisionReview({
    required this.street,
    required this.quality,
    required this.comment,
    this.math,
  });

  final Street street;
  final DecisionQuality quality;
  final String comment;

  /// Los números reales que ya se usaron para calificar esta decisión
  /// (equity aproximada, pot odds, bote, lo que faltaba pagar) — `null`
  /// cuando ninguno aplica (p. ej. un check sin apuesta de por medio).
  /// Nunca un número inventado: siempre el mismo que ya calculó
  /// [CoachAnalyzer] internamente para decidir [quality], expuesto en vez
  /// de descartado.
  final DecisionMath? math;
}

/// El análisis de la mano que acaba de terminar — solo los momentos
/// realmente relevantes (nunca cada acción, ver [CoachAnalyzer]), más una
/// idea de cierre.
class HandReview {
  const HandReview({required this.decisions, required this.closingThought});

  final List<HandDecisionReview> decisions;
  final String closingThought;
}

/// Interno: una decisión ya evaluada pero sin filtrar todavía — [trivial]
/// y [potBb] existen solo para que [CoachAnalyzer.analyzeHand] decida qué
/// mostrar, nunca llegan a la UI.
class _RawReview {
  const _RawReview({
    required this.street,
    required this.quality,
    required this.comment,
    required this.trivial,
    required this.potBb,
    required this.index,
    this.math,
  });

  final Street street;
  final DecisionQuality quality;
  final String comment;
  final DecisionMath? math;

  /// El único caso sin alternativa real: la BB mirando el flop gratis
  /// sin que nadie haya subido — se computa igual (para el cierre) pero
  /// nunca ocupa un lugar en el análisis mostrado.
  final bool trivial;
  final double potBb;
  final int index;
}

const Map<DecisionQuality, int> _kQualityRank = {
  DecisionQuality.costly: 4,
  DecisionQuality.questionable: 3,
  DecisionQuality.contextDependent: 2,
  DecisionQuality.improvable: 1,
  DecisionQuality.solid: 0,
};

/// Genera el análisis del Coach/Mentor **al final de la mano** — nunca
/// interrumpe durante ella (ver `HandTableController`) y nunca obliga a
/// leerlo (la pantalla lo muestra solo si el usuario elige "Ver
/// análisis", ver `CoachHandOverBanner`).
///
/// **Breve y por momentos importantes**: no comenta cada acción — filtra
/// la única decisión sin alternativa real (la BB mirando gratis) y,
/// cuando hay más de 3 decisiones relevantes, se queda con las 3 más
/// importantes (peor calidad primero, bote más grande como desempate),
/// mostradas igual en el orden en que ocurrieron. Marca además cuál fue
/// LA decisión clave de la mano ("Esta es la decisión más importante de
/// la mano...") cuando hay una que realmente lo amerita.
///
/// **Tono**: mentor, pero profesional — un veredicto claro y el motivo,
/// sin convertir la revisión en una clase (ver los ejemplos del pedido:
/// "El open es correcto para esta posición.", "El fold es preferible
/// porque la apuesta representa un rango fuerte y no hay equity
/// suficiente para continuar.").
///
/// Sigue sin ser un segundo evaluador tipo Laboratorio (Grupo 6/7): no
/// produce un veredicto contra opciones pre-calificadas con EV exacto,
/// analiza en retrospectiva una mano que ya se jugó libremente, con las
/// mismas piezas de siempre ([HandStrength]/[OpeningRanges] preflop,
/// [HandStrengthClassifier] + [OpponentPolicy.approxEquity] postflop —
/// el mismo número que ya usa el propio bot para decidir, nunca un
/// segundo criterio de equity aproximada inventado aparte para esto).
class CoachAnalyzer {
  const CoachAnalyzer._();

  /// El análisis de la mano — `decisions` vacío en el resultado significa
  /// que ninguna decisión del héroe ameritaba un comentario propio (mano
  /// jugada de forma impecable y sin momentos límite) o que el héroe no
  /// llegó a decidir nada.
  static HandReview analyzeHand({
    required List<HeroDecisionRecord> decisions,
    required int heroSlot,
    required bool heroWon,
  }) {
    if (decisions.isEmpty) {
      return HandReview(
        decisions: const [],
        closingThought: heroWon
            ? 'Esta la ganaste sin tener que decidir nada — a veces la '
                'mano se resuelve sola.'
            : 'Acá no llegaste a decidir nada — no hay mucho para '
                'analizar de esta mano en particular.',
      );
    }

    final all = [
      for (var i = 0; i < decisions.length; i++)
        _reviewOne(decisions[i], index: i, heroSlot: heroSlot),
    ];
    final nonTrivial = all.where((r) => !r.trivial).toList();
    final pool = nonTrivial.isEmpty ? all : nonTrivial;

    _RawReview? key;
    for (final r in pool) {
      if (key == null ||
          _kQualityRank[r.quality]! > _kQualityRank[key.quality]! ||
          (_kQualityRank[r.quality]! == _kQualityRank[key.quality]! &&
              r.potBb > key.potBb)) {
        key = r;
      }
    }
    final resolvedKey = key;
    final keyIndex = (pool.length > 1 &&
            resolvedKey != null &&
            _kQualityRank[resolvedKey.quality]! >= 2)
        ? resolvedKey.index
        : null;

    final selected = pool.length <= 3
        ? (List<_RawReview>.from(pool)..sort((a, b) => a.index.compareTo(b.index)))
        : _topThreeChronological(pool);

    final publicReviews = [
      for (final r in selected)
        HandDecisionReview(
          street: r.street,
          quality: r.quality,
          comment: (keyIndex != null && r.index == keyIndex)
              ? 'Esta es la decisión más importante de la mano. ${r.comment}'
              : r.comment,
          math: r.math,
        ),
    ];

    return HandReview(
      decisions: publicReviews,
      closingThought: _closingThought(key: key, heroWon: heroWon),
    );
  }

  static List<_RawReview> _topThreeChronological(List<_RawReview> pool) {
    final ranked = List<_RawReview>.from(pool)
      ..sort((a, b) {
        final byRank = _kQualityRank[b.quality]!.compareTo(_kQualityRank[a.quality]!);
        if (byRank != 0) return byRank;
        return b.potBb.compareTo(a.potBb);
      });
    final top = ranked.take(3).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return top;
  }

  static _RawReview _reviewOne(
    HeroDecisionRecord record, {
    required int index,
    required int heroSlot,
  }) {
    final before = record.before;
    final hero = before.seatAt(heroSlot);
    final hand = hero.holeCards;
    if (hand == null) {
      throw ArgumentError(
          'CoachAnalyzer: el héroe (slot $heroSlot) no tiene mano conocida.');
    }
    final position = before.positionOf(heroSlot);
    final potBb = before.pot.totalBb;
    final toCallBb = before.round.currentBetBb - hero.investedThisStreetBb;
    final facingBet = toCallBb > 0;
    final trivial = before.street == Street.preflop &&
        record.action.type == ActionType.check &&
        !facingBet;

    final (quality, comment, math) = before.street == Street.preflop
        ? _preflopReview(
            action: record.action,
            percentile: HandStrength.percentile(hand.notation),
            openRangeFrequency:
                OpeningRanges.forPosition(position).frequencyOf(hand.notation),
            facingBet: facingBet,
            toCallBb: toCallBb,
            potBb: potBb,
          )
        : _postflopReview(
            action: record.action,
            reading: HandStrengthClassifier.classify(hand, before.board),
            facingBet: facingBet,
            toCallBb: toCallBb,
            potBb: potBb,
          );

    return _RawReview(
      street: record.street,
      quality: quality,
      comment: comment,
      trivial: trivial,
      potBb: potBb,
      index: index,
      math: math,
    );
  }

  static (DecisionQuality, String, DecisionMath?) _preflopReview({
    required PokerAction action,
    required double percentile,
    required double openRangeFrequency,
    required bool facingBet,
    required double toCallBb,
    required double potBb,
  }) {
    if (!facingBet) {
      if (action.type == ActionType.check) {
        return (DecisionQuality.solid, 'Check automático: no hay nada que pagar.', null);
      }
      if (action.type == ActionType.fold) {
        final costly = percentile <= 0.20;
        return (
          costly ? DecisionQuality.costly : DecisionQuality.solid,
          costly
              ? 'El fold cede la iniciativa con una mano que normalmente '
                  'juega desde esta posición.'
              : 'El fold es razonable: la mano no pide más sin presión rival.',
          null,
        );
      }
      // open / raise / allIn / limp
      final quality = openRangeFrequency >= 0.9
          ? DecisionQuality.solid
          : openRangeFrequency > 0
              ? DecisionQuality.contextDependent
              : (percentile > 0.55
                  ? DecisionQuality.costly
                  : DecisionQuality.questionable);
      final comment = switch (quality) {
        DecisionQuality.solid => 'El open es correcto para esta posición.',
        DecisionQuality.contextDependent => 'El open es límite para esta '
            'posición: defendible, aunque no la primera opción.',
        _ => 'Esta apertura no calza con el rango habitual de esta posición.',
      };
      return (quality, comment, null);
    }

    final requiredEquity = potBb <= 0 ? 0.0 : toCallBb / (potBb + toCallBb);
    final math = DecisionMath(
      requiredEquityPct: requiredEquity * 100,
      potBb: potBb,
      toCallBb: toCallBb,
    );
    if (action.type == ActionType.fold) {
      final quality = percentile <= 0.08
          ? DecisionQuality.costly
          : percentile <= 0.20
              ? DecisionQuality.questionable
              : DecisionQuality.solid;
      final comment = switch (quality) {
        DecisionQuality.solid => 'El fold es la salida más barata con esta mano.',
        DecisionQuality.questionable => 'El fold es discutible: la mano '
            'todavía compite contra esta subida.',
        _ => 'Este fold cede una mano que puede pelear la subida.',
      };
      return (quality, comment, math);
    }
    final quality = percentile <= 0.15
        ? DecisionQuality.solid
        : percentile <= 0.35
            ? DecisionQuality.contextDependent
            : (requiredEquity > 0.35
                ? DecisionQuality.costly
                : DecisionQuality.questionable);
    final comment = switch (quality) {
      DecisionQuality.solid => 'Seguir tiene sentido: la mano aguanta bien '
          'contra este rango.',
      DecisionQuality.contextDependent => 'Es un call límite, defendible '
          'según el rango representado.',
      _ => 'La mano no alcanza para justificar este call frente al rango '
          'representado.',
    };
    return (quality, comment, math);
  }

  static (DecisionQuality, String, DecisionMath?) _postflopReview({
    required PokerAction action,
    required HandStrengthReading reading,
    required bool facingBet,
    required double toCallBb,
    required double potBb,
  }) {
    final approxEquity = OpponentPolicy.approxEquity(reading);
    final requiredEquity = potBb <= 0 ? 0.0 : toCallBb / (potBb + toCallBb);
    // La misma equity aproximada que ya usa el propio bot para decidir
    // ([OpponentPolicy.approxEquity], nunca un segundo cálculo) — acá
    // simplemente se deja de descartar antes de llegar a la UI.
    final facingBetMath = DecisionMath(
      equityPct: approxEquity * 100,
      requiredEquityPct: requiredEquity * 100,
      edgePct: (approxEquity - requiredEquity) * 100,
      potBb: potBb,
      toCallBb: toCallBb,
    );

    if (action.type == ActionType.fold) {
      final margin = approxEquity - requiredEquity;
      final quality = margin > 0.12
          ? DecisionQuality.costly
          : margin > 0.03
              ? DecisionQuality.questionable
              : DecisionQuality.solid;
      final comment = switch (quality) {
        DecisionQuality.solid => 'El fold es preferible: la apuesta '
            'representa un rango fuerte y no hay equity suficiente para '
            'continuar.',
        DecisionQuality.questionable => 'El fold es discutible: la mano y '
            'las pot odds casi alcanzaban para seguir.',
        _ => 'Este fold cede una mano que las pot odds justificaban pagar.',
      };
      return (quality, comment, facingBetMath);
    }

    if (action.type == ActionType.check) {
      final missedValue = reading.tier == HandStrengthTier.strong;
      return (
        missedValue ? DecisionQuality.contextDependent : DecisionQuality.solid,
        missedValue
            ? 'El check es viable, aunque también había valor para '
                'apostar acá.'
            : 'El check es viable; no hace falta inflar el pot con esta mano.',
        DecisionMath(equityPct: approxEquity * 100, potBb: potBb),
      );
    }

    if (action.type == ActionType.call) {
      final margin = approxEquity - requiredEquity;
      if (reading.tier.isAtLeastDecent && margin >= 0.05) {
        return (
          DecisionQuality.contextDependent,
          'El call es viable, pero el raise también tenía sentido para '
              'proteger la mano y extraer valor.',
          facingBetMath,
        );
      }
      final quality = margin >= 0.05
          ? DecisionQuality.solid
          : margin >= -0.05
              ? DecisionQuality.contextDependent
              : DecisionQuality.costly;
      final comment = switch (quality) {
        DecisionQuality.solid => 'El call es sólido: la mano y la cuenta cierran.',
        DecisionQuality.contextDependent => 'Es un call límite: la cuenta '
            'casi cierra.',
        _ => 'El call es cuestionable: la ecuación no cierra con esta mano.',
      };
      return (quality, comment, facingBetMath);
    }

    // bet / raise / allIn
    final quality = reading.tier.isAtLeastDecent
        ? DecisionQuality.solid
        : reading.hasAnyDraw
            ? DecisionQuality.contextDependent
            : DecisionQuality.questionable;
    final comment = switch (quality) {
      DecisionQuality.solid => 'La apuesta tiene sentido para extraer '
          'valor con una mano por delante.',
      DecisionQuality.contextDependent => 'El semi-farol es razonable: '
          'hay proyecto real detrás si no funciona.',
      _ => 'Este farol queda expuesto sin nada detrás — conviene '
          'reservarlo para pocas veces.',
    };
    return (quality, comment, DecisionMath(equityPct: approxEquity * 100, potBb: potBb));
  }

  static String _closingThought({
    required _RawReview? key,
    required bool heroWon,
  }) {
    final rank = key == null ? 0 : _kQualityRank[key.quality]!;
    if (rank >= 3) {
      return 'La clave de esta mano estuvo en ${_streetWord(key!.street)}: '
          'ahí vale la pena revisar la decisión antes que cualquier otra.';
    }
    if (rank == 2) {
      return 'La mano estuvo pareja; el único matiz para afinar aparece '
          'en ${_streetWord(key!.street)}.';
    }
    return heroWon
        ? 'Mano bien jugada de punta a punta, y encima ganada.'
        : 'Mano bien jugada de punta a punta — a veces se pierde igual.';
  }

  static String _streetWord(Street street) => switch (street) {
        Street.flop => 'el flop',
        Street.turn => 'el turn',
        Street.river => 'el río',
        Street.preflop => 'preflop',
      };

  /// Descripción corta de una mano ya clasificada — reutilizada por el
  /// panel de "Herramientas de ayuda" (tarjeta "Mi mano") para no
  /// duplicar el mismo texto en dos lugares.
  static String describeHandForDisplay(HandStrengthReading reading) =>
      _handWord(reading);

  static String _handWord(HandStrengthReading reading) {
    final base = switch (reading.category.strength) {
      >= 6 => reading.category.label.toLowerCase(),
      _ when reading.tier == HandStrengthTier.decent => 'top pair',
      _ when reading.category.index >= 1 => 'una pareja floja',
      _ => 'carta alta',
    };
    if (!reading.hasAnyDraw) return base;
    final draws = [
      if (reading.flushDraw) 'proyecto de color',
      if (reading.straightDraw) 'proyecto de escalera',
    ].join(' y ');
    return reading.category.index == 0 ? draws : '$base con $draws';
  }
}
