import 'package:flutter/foundation.dart';

import '../../../engine/poker/card.dart';
import '../../../engine/poker/position.dart';
import '../../../engine/strategy/hand_range.dart';
import '../../../engine/strategy/opening_ranges.dart';
import '../../../engine/strategy/range_comparison.dart';
import '../../../engine/strategy/range_context.dart';
import '../../../engine/strategy/saved_range.dart';
import '../../../persistence/saved_range_store.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../widgets/card_situation.dart';
import 'range_filters.dart';

enum RangeToolMode { explore, build, practice }

/// Estado central de la pantalla de Rangos — un solo controller para toda
/// la herramienta (Explorar/Construir/Practicar comparten el mismo rango
/// activo, el mismo board y los mismos filtros), mismo criterio que
/// `AcademyController`/`LabSessionController`: un controller grande por
/// feature, no uno por widget.
class RangeExplorerController extends ChangeNotifier {
  RangeExplorerController({SavedRangeStore? store})
      : _store = store ?? defaultSavedRangeStore {
    _loadSavedRanges();
  }

  final SavedRangeStore _store;

  // ---------------------------------------------------------------------
  // Navegación / contexto
  // ---------------------------------------------------------------------

  RangeToolMode mode = RangeToolMode.explore;
  RangeContext context = const RangeContext(position: Position.btn);
  String? selectedNotation;
  RangeFilters filters = const RangeFilters();

  void setMode(RangeToolMode value) {
    mode = value;
    notifyListeners();
  }

  void setPosition(Position position) {
    context = context.copyWith(position: position);
    selectedNotation = null;
    _openSavedRangeId = null;
    notifyListeners();
  }

  void selectCell(String? notation) {
    selectedNotation = notation;
    notifyListeners();
  }

  void setFilters(RangeFilters value) {
    filters = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Board (para combos/blockers) — el mismo mecanismo que Blocker
  // Explorer, no un segundo picker.
  // ---------------------------------------------------------------------

  late final CardSituationController board = CardSituationController([
    const CardGroupSpec(
      id: 'board',
      label: 'Board',
      minCount: 0,
      maxCount: 5,
      accent: SalaVerdeColors.steelBlueBright,
    ),
  ])
    ..addListener(notifyListeners);

  List<Card> get boardCards => board.cardsOf('board');

  /// Etiqueta de calle según cuántas cartas tiene el board — nunca una
  /// acción postflop inventada, solo el nombre de la calle.
  String get streetLabel => switch (boardCards.length) {
        0 => 'Preflop',
        3 => 'Flop',
        4 => 'Turn',
        _ => boardCards.length >= 5 ? 'River' : 'Preflop',
      };

  // ---------------------------------------------------------------------
  // Rango activo: oficial (FLOPly) o uno propio abierto desde Mis Rangos.
  // ---------------------------------------------------------------------

  String? _openSavedRangeId;

  SavedRange? get openSavedRange {
    if (_openSavedRangeId == null) return null;
    for (final r in savedRanges) {
      if (r.id == _openSavedRangeId) return r;
    }
    return null;
  }

  bool get isViewingOfficial => openSavedRange == null;

  String get officialRangeLabel => '${context.position.abbreviation} Open';

  /// El rango que se dibuja en la matriz en modo Explorar/Practicar.
  HandRange get activeRange =>
      openSavedRange?.toHandRange() ?? OpeningRanges.forPosition(context.position);

  void openSaved(String id) {
    _openSavedRangeId = id;
    selectedNotation = null;
    notifyListeners();
  }

  void viewOfficial() {
    _openSavedRangeId = null;
    selectedNotation = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Mis Rangos (persistencia)
  // ---------------------------------------------------------------------

  bool savedRangesLoading = true;
  List<SavedRange> savedRanges = [];

  Future<void> _loadSavedRanges() async {
    savedRanges = await _store.loadAll();
    savedRangesLoading = false;
    notifyListeners();
  }

  Future<void> _persist() => _store.saveAll(savedRanges);

  Future<SavedRange> saveRange({
    required String name,
    required Map<String, double> frequencies,
    String? basedOnOfficialId,
  }) async {
    final now = DateTime.now();
    final saved = SavedRange(
      id: '${now.microsecondsSinceEpoch}',
      name: name,
      frequencies: frequencies,
      position: context.position,
      situation: context.situation,
      basedOnOfficialId: basedOnOfficialId,
      createdAt: now,
      updatedAt: now,
    );
    savedRanges = [...savedRanges, saved];
    await _persist();
    notifyListeners();
    return saved;
  }

  Future<void> updateRange(String id, {String? name, Map<String, double>? frequencies}) async {
    savedRanges = [
      for (final r in savedRanges)
        if (r.id == id)
          r.copyWith(name: name, frequencies: frequencies, updatedAt: DateTime.now())
        else
          r,
    ];
    await _persist();
    notifyListeners();
  }

  Future<SavedRange> duplicateRange(SavedRange source, {String? newName}) async {
    final now = DateTime.now();
    final copy = SavedRange(
      id: '${now.microsecondsSinceEpoch}',
      name: newName ?? '${source.name} (copia)',
      frequencies: Map.of(source.frequencies),
      position: source.position,
      situation: source.situation,
      basedOnOfficialId: source.basedOnOfficialId,
      createdAt: now,
      updatedAt: now,
    );
    savedRanges = [...savedRanges, copy];
    await _persist();
    notifyListeners();
    return copy;
  }

  Future<void> deleteRange(String id) async {
    if (_openSavedRangeId == id) _openSavedRangeId = null;
    savedRanges = savedRanges.where((r) => r.id != id).toList();
    await _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Range Builder — borrador en memoria, independiente del rango activo
  // de Explorar hasta que se guarda.
  // ---------------------------------------------------------------------

  Map<String, double> draftFrequencies = {};
  String draftName = '';
  String? draftBasedOnOfficialId;

  void startDraftFromScratch() {
    draftFrequencies = {};
    draftName = '';
    draftBasedOnOfficialId = null;
    notifyListeners();
  }

  void startDraftFromOfficial() {
    draftFrequencies = Map.of(activeRange.frequencies);
    draftName = '$officialRangeLabel (editado)';
    draftBasedOnOfficialId = 'open_raise_${context.position.name}';
    notifyListeners();
  }

  void startDraftFromSaved(SavedRange saved) {
    draftFrequencies = Map.of(saved.frequencies);
    draftName = saved.name;
    draftBasedOnOfficialId = saved.basedOnOfficialId;
    notifyListeners();
  }

  void setDraftName(String name) {
    draftName = name;
    notifyListeners();
  }

  void setDraftFrequency(String notation, double frequency) {
    if (frequency <= 0) {
      draftFrequencies.remove(notation);
    } else {
      draftFrequencies[notation] = frequency.clamp(0.0, 1.0);
    }
    notifyListeners();
  }

  void clearDraft() {
    draftFrequencies = {};
    notifyListeners();
  }

  HandRange get draftRange => HandRange(Map.of(draftFrequencies));

  // ---------------------------------------------------------------------
  // Range Compare (sección 19)
  // ---------------------------------------------------------------------

  Position? compareTargetPosition;
  String? compareTargetSavedId;

  HandRange? get compareTargetRange {
    if (compareTargetSavedId != null) {
      for (final r in savedRanges) {
        if (r.id == compareTargetSavedId) return r.toHandRange();
      }
      return null;
    }
    if (compareTargetPosition != null) {
      return OpeningRanges.forPosition(compareTargetPosition!);
    }
    return null;
  }

  String? get compareTargetLabel {
    if (compareTargetSavedId != null) {
      for (final r in savedRanges) {
        if (r.id == compareTargetSavedId) return r.name;
      }
      return null;
    }
    if (compareTargetPosition != null) {
      return '${compareTargetPosition!.abbreviation} Open';
    }
    return null;
  }

  RangeComparison? get comparison {
    final target = compareTargetRange;
    if (target == null) return null;
    return RangeComparison.compute(activeRange, target);
  }

  void setCompareTargetPosition(Position? position) {
    compareTargetPosition = position;
    compareTargetSavedId = null;
    notifyListeners();
  }

  void setCompareTargetSaved(String? id) {
    compareTargetSavedId = id;
    compareTargetPosition = null;
    notifyListeners();
  }

  void clearCompare() {
    compareTargetPosition = null;
    compareTargetSavedId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    board.removeListener(notifyListeners);
    board.dispose();
    super.dispose();
  }
}
