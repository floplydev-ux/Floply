import 'dart:math';

import 'package:flutter/material.dart';

import '../../../engine/poker/hole_cards.dart';
import '../../../engine/strategy/hand_range.dart';
import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import '../widgets/tool_widgets.dart';

/// Regla de corrección de una respuesta — extraída como función pura
/// para poder testearla sin montar el widget. Una frecuencia mixta (ni
/// 0% ni 100%) no tiene una única respuesta correcta declarada por el
/// rango, así que ambas cuentan como acierto en vez de inventar un
/// umbral que el dato no tiene.
bool isPracticeAnswerCorrect({required double frequency, required bool answeredRaise}) {
  final isMixed = frequency > 0 && frequency < 1.0;
  if (isMixed) return true;
  return answeredRaise ? frequency >= 1.0 : frequency <= 0;
}

/// Practicar (sección 21) — convierte el rango activo en un ejercicio
/// corto: una mano al azar (de las 169 clases, no solo las del rango —
/// para que "foldear lo que no entra" también se practique), ¿Raise o
/// Fold?, y una explicación que usa la frecuencia REAL del rango, nunca
/// una regla inventada.
///
/// [onConceptPracticed] queda sin conectar a propósito (sección 22): la
/// integración real con `ConceptRegistry`/`UserKnowledge` requeriría
/// enhebrar `AcademyStore` hasta Tools, fuera del alcance de este
/// upgrade — esta es la interfaz limpia para cuando exista esa vía.
class RangePracticeView extends StatefulWidget {
  const RangePracticeView({super.key, required this.range, this.onConceptPracticed, Random? random})
      : _random = random;

  final HandRange range;
  final void Function(String conceptId, {required bool correct})? onConceptPracticed;

  /// Inyectable para tests deterministas — mismo criterio que
  /// `PokerTrainerEngine(seed: ...)` en el resto del motor.
  final Random? _random;

  @override
  State<RangePracticeView> createState() => _RangePracticeViewState();
}

class _RangePracticeViewState extends State<RangePracticeView> {
  late final _random = widget._random ?? Random();
  late String _notation;
  bool? _lastAnswerWasRaise;
  int _correct = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _notation = _pickNotation();
  }

  String _pickNotation() {
    final classes = HandClass.all();
    return classes[_random.nextInt(classes.length)].notation;
  }

  void _next() {
    setState(() {
      _notation = _pickNotation();
      _lastAnswerWasRaise = null;
    });
  }

  void _answer(bool answeredRaise) {
    final frequency = widget.range.frequencyOf(_notation);
    final correct =
        isPracticeAnswerCorrect(frequency: frequency, answeredRaise: answeredRaise);
    widget.onConceptPracticed?.call('openingRange', correct: correct);
    setState(() {
      _lastAnswerWasRaise = answeredRaise;
      _total++;
      if (correct) _correct++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final frequency = widget.range.frequencyOf(_notation);
    final answered = _lastAnswerWasRaise != null;
    final correct = answered &&
        isPracticeAnswerCorrect(frequency: frequency, answeredRaise: _lastAnswerWasRaise!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolCard(
          child: Column(
            children: [
              Text(
                AppStrings.rangesPracticeQuestion,
                style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
              ),
              const SizedBox(height: SalaVerdeSpace.sm),
              Text(_notation, style: SalaVerdeType.numeric(size: 40, color: kToolAccent)),
              const SizedBox(height: SalaVerdeSpace.lg),
              if (!answered)
                Row(
                  children: [
                    Expanded(
                      child: SvButtonPrimary(
                        label: AppStrings.rangesPracticeRaise,
                        accent: SalaVerdeColors.success,
                        onTap: () => _answer(true),
                      ),
                    ),
                    const SizedBox(width: SalaVerdeSpace.sm),
                    Expanded(
                      child: SvButtonPrimary(
                        label: AppStrings.rangesPracticeFold,
                        accent: SalaVerdeColors.errorBright,
                        onTap: () => _answer(false),
                      ),
                    ),
                  ],
                )
              else ...[
                ToolStatusPill(
                  label: correct
                      ? AppStrings.rangesPracticeCorrect
                      : AppStrings.rangesPracticeIncorrect,
                  color: correct ? SalaVerdeColors.success : SalaVerdeColors.errorBright,
                ),
                const SizedBox(height: SalaVerdeSpace.sm),
                Text(
                  AppStrings.rangesPracticeExplanation(_notation, frequency * 100),
                  textAlign: TextAlign.center,
                  style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
                ),
                const SizedBox(height: SalaVerdeSpace.lg),
                SizedBox(
                  width: double.infinity,
                  child: SvButtonSecondary(
                    label: AppStrings.rangesPracticeNext,
                    onTap: _next,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: SalaVerdeSpace.lg),
        if (_total > 0)
          Center(
            child: Text(
              '${AppStrings.rangesPracticeScore}: $_correct/$_total',
              style: SalaVerdeType.caption(color: SalaVerdeColors.textMuted),
            ),
          ),
      ],
    );
  }
}
