import 'package:flutter/material.dart' hide Card;

import '../../../engine/poker/card.dart';
import '../../../l10n/app_strings.dart';
import '../../../screens/academy/widgets/table/playing_card.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/pressable_scale.dart';
import 'card_picker.dart';

/// Selector universal de cartas — una sola arquitectura para CUALQUIER
/// lugar de Tools que necesite elegir cartas (mano del jugador, mano del
/// rival, board/flop/turn/river, cartas muertas de Combos…), en vez de un
/// picker distinto por herramienta. Construido sobre lo que ya existía en
/// `card_picker.dart` (`DottedCardOutline`, `pickCard` — la grilla de 52
/// no se duplica, se reutiliza tal cual).
///
/// Dos piezas:
///  - [CardSituationController]: el estado global de "qué cartas están en
///    uso" de UNA pantalla (una "situación") — varios [CardGroupSpec]
///    (Hero, Rival, Board…), cada uno con su propia lista de cartas. Una
///    carta usada en un grupo queda excluida automáticamente de TODOS los
///    demás — así ninguna herramienta tiene que armar a mano su propio
///    `Set<Card>` de "ya usadas" (lo que hacían Equity/Blocker antes,
///    cada una por su cuenta).
///  - [CardGroupField]: la UI de un grupo — funciona para una mano fija
///    de 2 (Hero/Rival, cuenta fija) o un board de largo variable (0..5,
///    turn/river son literalmente "agregar 1 carta más" al mismo grupo).

/// Describe UN grupo de cartas dentro de una situación: cuántas hacen
/// falta como mínimo, cuántas como máximo, y cómo se llama.
class CardGroupSpec {
  const CardGroupSpec({
    required this.id,
    required this.label,
    required this.minCount,
    required this.maxCount,
    this.accent = SalaVerdeColors.textSecondary,
  });

  /// Clave estable del grupo (`'hero'`, `'villain'`, `'board'`…) — la usa
  /// el controller para guardar sus cartas y para excluir "las propias"
  /// al recalcular qué está disponible.
  final String id;

  /// Lo que ve el usuario ("Tu mano", "Mano del rival", "Board").
  final String label;

  /// Cuántas cartas hacen falta como mínimo para considerar el grupo
  /// completo (2 para una mano; 0 para un board opcional).
  final int minCount;

  /// Cuántas cartas admite como máximo (2 para una mano; 5 para un board
  /// completo — 3 ya es un flop válido, no hace falta llegar a 5).
  final int maxCount;

  /// Acento de color para distinguir visualmente a qué grupo pertenece
  /// cada carta (Hero vs Rival vs Board) cuando conviven en la misma
  /// pantalla — sección "la interfaz debe dejar claro visualmente...".
  final Color accent;

  bool get isFixedCount => minCount == maxCount;
}

/// Estado global de cartas en uso de una pantalla — una instancia por
/// pantalla (`State.initState`), nunca compartida entre herramientas
/// distintas (cada Tool analiza su propia situación).
class CardSituationController extends ChangeNotifier {
  CardSituationController(List<CardGroupSpec> groups)
      : specs = {for (final g in groups) g.id: g},
        _cards = {for (final g in groups) g.id: <Card>[]};

  final Map<String, CardGroupSpec> specs;
  final Map<String, List<Card>> _cards;

  /// Cartas ya puestas en [groupId], en el orden en que se eligieron.
  List<Card> cardsOf(String groupId) => List.unmodifiable(_cards[groupId] ?? const []);

  /// Todas las cartas en uso en la situación completa (todos los
  /// grupos) — lo que le pasa el motor (`ComboEngine`/`EquityEngine`)
  /// como cartas ya retiradas del mazo.
  Set<Card> get allUsedCards => {
        for (final list in _cards.values) ...list,
      };

  /// Cartas disponibles para elegir en [groupId] en la posición [index]
  /// (o al final, si se está agregando) — todo lo usado en CUALQUIER
  /// grupo, salvo la carta que ya ocupa esa misma posición (para poder
  /// reemplazarla sin que se bloquee a sí misma).
  Set<Card> excludedFor(String groupId, {int? index}) {
    final own = index != null && index < (_cards[groupId]?.length ?? 0)
        ? _cards[groupId]![index]
        : null;
    final used = allUsedCards;
    if (own != null) used.remove(own);
    return used;
  }

  bool isComplete(String groupId) {
    final spec = specs[groupId]!;
    return cardsOf(groupId).length >= spec.minCount;
  }

  /// Pone/reemplaza la carta en [index] (agrega al final si `index ==
  /// length`).
  void setCard(String groupId, int index, Card card) {
    final list = _cards[groupId]!;
    if (index < list.length) {
      list[index] = card;
    } else {
      list.add(card);
    }
    notifyListeners();
  }

  /// Quita la ÚLTIMA carta del grupo — para un board, es lo único que
  /// tiene sentido (no se puede "destapar" el turn sin antes sacar el
  /// river); para una mano fija de 2, cualquiera de las dos posiciones
  /// se reemplaza directo con [setCard], nunca hace falta vaciarla.
  void removeLast(String groupId) {
    final list = _cards[groupId]!;
    if (list.isEmpty) return;
    list.removeLast();
    notifyListeners();
  }

  /// Vacía un grupo completo — "limpiar la selección" de esa mano/board
  /// puntual, sin tocar los demás grupos de la situación.
  void clearGroup(String groupId) {
    _cards[groupId]!.clear();
    notifyListeners();
  }

  /// Vacía TODA la situación (los N grupos a la vez).
  void clearAll() {
    for (final list in _cards.values) {
      list.clear();
    }
    notifyListeners();
  }
}

/// La UI de UN grupo — se redibuja sola escuchando al [controller]. No
/// necesita saber si es una mano fija o un board variable: lo decide el
/// propio [CardGroupSpec.isFixedCount].
class CardGroupField extends StatelessWidget {
  const CardGroupField({
    super.key,
    required this.controller,
    required this.groupId,
  });

  final CardSituationController controller;
  final String groupId;

  CardGroupSpec get _spec => controller.specs[groupId]!;

  Future<void> _pick(BuildContext context, int index) async {
    final cards = controller.cardsOf(groupId);
    final current = index < cards.length ? cards[index] : null;
    final excluded = controller.excludedFor(groupId, index: index);
    final picked = await pickCard(context, excluded: excluded, current: current);
    if (picked != null) controller.setCard(groupId, index, picked);
  }

  @override
  Widget build(BuildContext context) {
    // `AnimatedBuilder` es lo que hace real el "se redibuja sola escuchando
    // al controller" del doc-comment de la clase: sin esto, tocar una carta
    // llama a `controller.setCard`/`notifyListeners()` pero nada en el
    // árbol de widgets se entera, y el slot se queda mostrando el estado
    // viejo hasta que ALGO más fuerce un `setState` externo.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final spec = _spec;
    final cards = controller.cardsOf(groupId);
    final canAddMore = cards.length < spec.maxCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: SalaVerdeSpace.xs),
              decoration: BoxDecoration(color: spec.accent, shape: BoxShape.circle),
            ),
            Expanded(
              child: Text(
                spec.label,
                style: SalaVerdeType.label(color: SalaVerdeColors.textSecondary),
              ),
            ),
            if (cards.isNotEmpty)
              PressableScale(
                onTap: () => controller.clearGroup(groupId),
                child: Text(
                  AppStrings.toolsCardGroupClear,
                  style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted)
                      .copyWith(decoration: TextDecoration.underline),
                ),
              ),
          ],
        ),
        const SizedBox(height: SalaVerdeSpace.sm),
        Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: SalaVerdeSpace.sm),
              _FilledSlot(
                card: cards[i],
                removable: i == cards.length - 1,
                onTap: () => _pick(context, i),
                onRemove: () => controller.removeLast(groupId),
              ),
            ],
            if (canAddMore) ...[
              if (cards.isNotEmpty) const SizedBox(width: SalaVerdeSpace.sm),
              PressableScale(
                onTap: () => _pick(context, cards.length),
                child: DottedCardOutline(size: cardBaseSize(hero: false, small: false)),
              ),
            ],
          ],
        ),
        const SizedBox(height: SalaVerdeSpace.xs),
        Text(
          _statusMessage(spec, cards.length),
          style: SalaVerdeType.caption(
            color: controller.isComplete(groupId)
                ? SalaVerdeColors.feltGreenBright
                : SalaVerdeColors.textMuted,
          ),
        ),
      ],
    );
  }

  String _statusMessage(CardGroupSpec spec, int count) {
    if (spec.isFixedCount) {
      final missing = spec.maxCount - count;
      if (missing <= 0) return AppStrings.toolsHandComplete;
      return missing == 1 ? AppStrings.toolsHandPickOne : AppStrings.toolsHandPickBoth;
    }
    if (count < spec.minCount) {
      return AppStrings.toolsBoardMissing(spec.minCount - count);
    }
    if (count >= spec.maxCount) return AppStrings.toolsGroupComplete(spec.maxCount);
    return AppStrings.toolsBoardOptional(spec.maxCount - count);
  }
}

class _FilledSlot extends StatelessWidget {
  const _FilledSlot({
    required this.card,
    required this.removable,
    required this.onTap,
    required this.onRemove,
  });

  final Card card;
  final bool removable;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PressableScale(onTap: onTap, child: PlayingCard(code: card.code, small: false)),
        if (removable)
          Positioned(
            right: -6,
            top: -6,
            child: PressableScale(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: SalaVerdeColors.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: SalaVerdeColors.borderSubtle),
                  ),
                ),
                child: const Icon(Icons.close_rounded,
                    size: 12, color: SalaVerdeColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}
