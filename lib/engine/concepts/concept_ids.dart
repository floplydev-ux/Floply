/// Ids de conceptos como constantes, para evitar strings sueltos por todo
/// el código. No es necesario que estén todos implementados: alcanza con
/// que el registro los conozca cuando haga falta.
class ConceptIds {
  ConceptIds._();

  // Reglas y ranking
  static const rules = 'rules';
  static const handRanking = 'hand_ranking';

  // Posición
  static const positionNames = 'position_names';
  static const btn = 'position_btn';
  static const co = 'position_co';
  static const hj = 'position_hj';
  static const utg = 'position_utg';
  static const blinds = 'position_blinds';
  static const positionAdvantage = 'position_advantage';

  // Preflop opening
  static const openingRange = 'opening_range';
  static const openRaise = 'open_raise';
  static const openSizing = 'open_sizing';
  static const rangeWidth = 'range_width';

  // Preflop defensa / 3-bet (bloqueados en el slice inicial)
  static const bbDefense = 'bb_defense';
  static const call = 'call';
  static const threeBet = 'three_bet';
  static const threeBetValue = 'three_bet_value';
  static const threeBetBluff = 'three_bet_bluff';

  // Matemáticas
  static const potOdds = 'pot_odds';
  static const equity = 'equity';
  static const outs = 'outs';
  static const combos = 'combos';
  static const ev = 'ev';
  static const equityRealization = 'equity_realization';

  // Postflop
  static const rangeAdvantage = 'range_advantage';
  static const nutAdvantage = 'nut_advantage';
  static const cbet = 'cbet';
  static const boardTexture = 'board_texture';
  static const valueBet = 'value_bet';
  static const bluff = 'bluff';
  static const bluffCatcher = 'bluff_catcher';
  static const blockers = 'blockers';
  static const overbet = 'overbet';
  static const polarization = 'polarization';

  // Avanzado
  static const gto = 'gto';
  static const mixedStrategies = 'mixed_strategies';
  static const exploit = 'exploit';
}
