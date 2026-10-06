/// Texto de feedback real por `StrategyOption.rationaleKey` — Fase 1,
/// paso 8 del rediseño del motor preflop del Laboratorio (ver la
/// memoria del proyecto `laboratorio-motor-preflop`), más las 4
/// familias postflop de `PostflopStrategy` (`cbet.*`/`facing_cbet.*`/
/// `barrel.*`) agregadas junto con la devolución estructurada
/// post-respuesta de Laboratorio.
///
/// **Cobertura deliberadamente parcial**: las 3 clases de estrategia
/// preflop de esa fase ([DefenseVsOpenStrategy], [FacingThreeBetStrategy],
/// [ShortStackStrategy]), `PostflopStrategy` completa, y
/// `StrategyEngine.openRaiseStrategy`/`openSizingStrategy` (Open Raise —
/// sumadas junto con la corrección del sizing: antes esta familia caía
/// siempre al texto genérico, ver la memoria del proyecto
/// `laboratorio-motor-preflop`; el contenido real de estas claves ya
/// existía en `evaluation/feedback_engine.dart` para el sistema viejo de
/// Academia — se adapta acá al tono mentor, no se inventa de cero). Las
/// claves más viejas (`open_over_limpers.*`, `facing_raise.*`) siguen sin
/// texto propio — [LabFeedbackBuilder] (y, antes,
/// [ExerciseScenarioAdapter.feedbackFor]) caen al texto genérico por
/// veredicto para cualquier clave que no esté acá. Ampliar esta tabla a
/// esas claves queda como trabajo futuro, no silenciado.
///
/// Algunas entradas usan los placeholders `{board}`/`{heroHand}`, que
/// [LabFeedbackBuilder] resuelve con los datos reales de la mano jugada
/// (nunca con un patrón genérico) — ver su doc-comment.
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

    // PostflopStrategy — c-bet (agresor en el flop)
    'cbet.bet': 'Con {board} en la mesa, tu rango de apertura le pega '
        'mucho más seguido que el del rival — seguir apostando es la '
        'línea estándar, no hace falta esperar a ver más.',
    'cbet.check': 'Pasar acá regala la iniciativa: con {board} en la '
        'mesa tu rango de apertura le sigue pegando más que el del '
        'rival, así que convenía seguir apostando.',

    // PostflopStrategy — encarar presión real en el turn
    'facing_cbet.call.value': 'Tu equity contra el rango de apertura del '
        'rival te alcanza de sobra para pagar esta apuesta al precio '
        'que te están cobrando — pagar es la línea rentable.',
    'facing_cbet.fold.mistake': 'Acá el problema está en que te estás '
        'retirando con equity de sobra: tu mano le sigue ganando a '
        'buena parte del rango de apertura del rival, y pagar era la '
        'línea rentable.',
    'facing_cbet.call.mistake': 'Acá el problema está en que estás '
        'pagando demasiado caro: tu equity contra el rango de apertura '
        'del rival no llega a lo que pide el precio de esta apuesta.',
    'facing_cbet.fold.value': 'Tu equity no alcanza para pagar esta '
        'apuesta al precio que te están cobrando — retirarte es lo '
        'correcto.',
    'facing_cbet.call.close': 'Esto está al filo: tu equity queda cerca '
        'de lo que pide el precio de la apuesta — pagar es defendible, '
        'pero no la única línea razonable.',
    'facing_cbet.fold.close': 'Esto está al filo: tu equity queda '
        'apenas por debajo de lo que pide el precio de la apuesta — '
        'retirarte es defendible, aunque pagar también lo es.',
    'facing_cbet.raise.value': 'Con esta equity, re-subir por valor es '
        'una línea razonable: tu mano le sigue ganando a la mayoría de '
        'lo que el rival puede tener.',
    'facing_cbet.raise.bluff': 'Re-subir acá depende de cuánto se '
        'retire el rival — un dato que este ejercicio no te muestra, '
        'así que no hay una única respuesta correcta.',

    // PostflopStrategy — segundo/tercer barril (agresor en turn/river)
    'barrel.bet.value': 'Tu mano le sigue ganando, en promedio, al '
        'rango con el que el rival sigue en esta mano — seguir '
        'apostando es la línea de valor.',
    'barrel.bet.mistake': 'Seguir apostando acá no tiene sustento: tu '
        'equity contra lo que el rival puede tener no alcanza para que '
        'valga la pena.',
    'barrel.check.mistake': 'Pasar acá regala valor: tu mano le sigue '
        'ganando, en promedio, al rango del rival — convenía seguir '
        'apostando.',
    'barrel.check.control': 'Tu equity no alcanza para que otra '
        'apuesta sea rentable — controlar el bote con un check es la '
        'línea más sólida.',

    // StrategyEngine.openRaiseStrategy / openSizingStrategy — Open Raise
    // (contenido real adaptado de `evaluation/feedback_engine.dart`,
    // nunca inventado de cero — ver el doc-comment de la clase).
    'open.raise.in_range': 'Tu mano entra cómoda en el rango de '
        'apertura de esta posición — abrir es la línea estándar.',
    'open.fold.too_strong': 'Retirarte acá regala valor: esta mano '
        'entra de sobra en tu rango de apertura.',
    'open.raise.frontier': 'Es una mano de borde del rango: abrir es '
        'defendible, aunque no la única línea razonable.',
    'open.fold.frontier': 'Es una mano de borde del rango: retirarte '
        'también es defendible desde esta posición.',
    'open.fold.out_of_range': 'Esta mano queda fuera del rango de '
        'apertura de la posición — retirarte es lo correcto.',
    'open.raise.borderline_out': 'Esta mano queda justo por fuera del '
        'rango — abrir acá es forzar un poco la situación, defendible '
        'según la mesa pero no la línea estándar.',
    'open.raise.out_of_range': 'Esta mano es demasiado débil para '
        'abrir desde esta posición: vas a jugar botes sin iniciativa '
        'clara y fuera de rango.',
    'sizing.ideal': 'Es el tamaño estándar de apertura para esta '
        'posición.',
    'sizing.too_small': 'Un tamaño tan chico le da un precio '
        'demasiado bueno a las ciegas para entrar al bote.',
    'sizing.too_big': 'Un tamaño tan grande infla el bote sin '
        'necesidad y hace tu apertura muy fácil de leer.',
    'sizing.slightly_big': 'Está un poco por encima del tamaño '
        'estándar de la posición, pero sigue siendo defendible.',
    'sizing.slightly_small': 'Está un poco por debajo del tamaño '
        'estándar de la posición, pero sigue siendo defendible.',
  };

  /// El texto real para [rationaleKey], o `null` si esta clave todavía
  /// no tiene uno — el caller decide el fallback (nunca esta clase).
  static String? textFor(String? rationaleKey) =>
      rationaleKey == null ? null : _text[rationaleKey];
}
