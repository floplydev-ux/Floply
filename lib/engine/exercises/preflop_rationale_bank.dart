/// Texto de feedback real por `StrategyOption.rationaleKey` — Fase 1,
/// paso 8 del rediseño del motor preflop del Laboratorio (ver la
/// memoria del proyecto `laboratorio-motor-preflop`).
///
/// **Cobertura deliberadamente parcial**: solo las 3 clases de
/// estrategia nuevas de esta fase ([DefenseVsOpenStrategy],
/// [FacingThreeBetStrategy], [ShortStackStrategy] — ver sus
/// respectivos `rationaleKey`). Las claves más viejas
/// (`open_over_limpers.*`, `facing_raise.*`, las de
/// `StrategyEngine.openRaiseStrategy`) siguen sin texto propio —
/// [ExerciseScenarioAdapter.feedbackFor] cae al texto genérico por
/// veredicto para cualquier clave que no esté acá, exactamente como
/// hacía para TODAS las claves antes de este paso. Ampliar esta tabla
/// a las claves viejas queda como trabajo futuro, no silenciado.
class PreflopRationaleBank {
  const PreflopRationaleBank._();

  static const Map<String, String> _text = {
    // DefenseVsOpenStrategy
    'defense_vs_open.raise.value': 'Tu mano ya le gana a lo que sigue '
        'pagando en el rango de apertura del rival — re-subir es la '
        'línea de valor.',
    'defense_vs_open.call.value_flat': 'Pagar también sirve con esta '
        'mano, pero re-subir saca más valor: hay manos peores en el '
        'rango del rival que van a seguir pagando.',
    'defense_vs_open.fold.value': 'Retirarte acá regala valor: tu mano '
        'ya le gana a buena parte de lo que el rival puede tener.',
    'defense_vs_open.call.bluff_candidate': 'Pagar es la línea simple '
        'con esta mano: tiene bloqueadores y jugabilidad, pero no el '
        'peso para re-subir sin depender del rival.',
    'defense_vs_open.raise.bluff': 'Re-subir acá es defendible por los '
        'bloqueadores que tenés, pero funciona o no según qué tan '
        'seguido se retira el rival — no es la única respuesta '
        'correcta.',
    'defense_vs_open.fold.bluff_candidate': 'Retirarte desperdicia una '
        'mano con bloqueadores y jugabilidad real — al menos pagar es '
        'mejor.',
    'defense_vs_open.call.standard': 'Pagar es la defensa estándar '
        'acá: tu mano no tiene el peso para re-subir, pero sí para '
        'seguir en la mano.',
    'defense_vs_open.raise.no_merit': 'Re-subir con esta mano no tiene '
        'respaldo de valor ni de farol — no hay motivo real para '
        'hacerlo.',
    'defense_vs_open.fold.standard': 'Esta mano no alcanza para pagar '
        'la apertura del rival — retirarte es lo correcto.',

    // FacingThreeBetStrategy
    'facing_three_bet.raise.value': 'Tu mano le gana a lo que sigue en '
        'el rango de 3-bet del rival — re-subir (4-bet) es la línea '
        'de valor.',
    'facing_three_bet.call.value_flat': 'Pagar el 3-bet también sirve '
        'con esta mano, pero re-subir sigue sacando más valor.',
    'facing_three_bet.fold.value': 'Retirarte acá regala valor: tu '
        'mano ya le gana a buena parte del rango de 3-bet del rival.',
    'facing_three_bet.call.standard': 'Pagar el 3-bet es la línea '
        'estándar con esta mano: no alcanza para un 4-bet, pero sí '
        'para seguir.',
    'facing_three_bet.raise.no_merit': 'Re-subir (4-bet) acá no tiene '
        'ningún respaldo de valor contra el rango de 3-bet del rival.',
    'facing_three_bet.fold.standard': 'Esta mano no alcanza para pagar '
        'el 3-bet — retirarte es lo correcto.',
    'facing_three_bet.fold.out_of_range': 'Tu mano queda claramente '
        'afuera del rango de 3-bet del rival — retirarte es lo '
        'correcto.',
    'facing_three_bet.call.out_of_range': 'Pagar acá no tiene '
        'sustento: tu mano queda afuera de lo que puede seguir del '
        'rango de 3-bet del rival.',
    'facing_three_bet.raise.out_of_range': 'Re-subir (4-bet) con esta '
        'mano no tiene ningún respaldo — ni de valor, ni de farol.',

    // ShortStackStrategy
    'short_stack.shove.value': 'A este stack, empujar todo es la línea '
        'estándar con esta mano: la fold equity más la equity si te '
        'pagan hacen que valga la pena.',
    'short_stack.call.surrenders_fold_equity': 'Pagar sin ir all-in a '
        'este stack renuncia a la fold equity sin ganar nada a cambio '
        '— defendible en algunos contextos, pero no la línea simple.',
    'short_stack.fold.value': 'Retirarte acá desperdicia una mano que '
        'ya está en el rango de empuje a este stack.',
    'short_stack.fold.out_of_range': 'Tu mano queda afuera del rango '
        'de empuje a este stack — retirarte es lo correcto.',
    'short_stack.call.out_of_range': 'Pagar sin ir all-in con esta '
        'mano no tiene sustento a este stack.',
    'short_stack.shove.out_of_range': 'Empujar todo con esta mano no '
        'tiene respaldo — queda afuera del rango de empuje a este '
        'stack.',
  };

  /// El texto real para [rationaleKey], o `null` si esta clave todavía
  /// no tiene uno — el caller decide el fallback (nunca esta clase).
  static String? textFor(String? rationaleKey) =>
      rationaleKey == null ? null : _text[rationaleKey];
}
