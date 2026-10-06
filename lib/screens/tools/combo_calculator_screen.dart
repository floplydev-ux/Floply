import 'package:flutter/material.dart' hide Card;

import '../../engine/poker/card.dart';
import '../../engine/poker/combos/combo_engine.dart';
import '../../engine/poker/hole_cards.dart';
import '../../l10n/app_strings.dart';
import '../../theme/sala_verde/sala_verde_tokens.dart';
import 'widgets/card_situation.dart';
import 'widgets/tool_explainer.dart';
import 'widgets/tool_guide_screen.dart';
import 'widgets/tool_widgets.dart';

/// Público (antes privado): reutilizado por la guía consolidada del hub
/// (`tools_guide_sheet.dart`) — ver el doc-comment equivalente en
/// `pot_odds_calculator_screen.dart`.
const kComboToolId = 'combo_calculator';
const kComboExplainer = ToolExplainerContent(
  title: 'Combos',
  description:
      'Mostrá cuántas combinaciones físicas quedan de una clase de mano '
      '(ej. AKs) según qué cartas ya están fuera del mazo.',
  howToUse: 'Escribí la clase de mano (AKs, 77, AKo) y agregá cartas '
      'muertas si corresponde.',
  result: 'Cuántos combos quedan disponibles sobre el total de esa '
      'clase, y la lista de combos concretos.',
);

const kComboGuide = ToolGuideContent(
  title: 'Combos',
  tagline: 'Combinaciones físicas de una clase de mano',
  icon: Icons.style_rounded,
  sections: [
    ToolGuideSection(
      label: '¿Para qué sirve?',
      body: 'Cuenta cuántas combinaciones físicas distintas quedan de una '
          'clase de mano descontando las cartas muertas. Fundamental para '
          'pesar rangos y entender la frecuencia real de cada mano.',
    ),
    ToolGuideSection(
      label: '¿Cuándo usarla?',
      items: [
        'Para saber cuántos combos le quedan al rival de una mano específica.',
        'Antes de decidir si una mano rival es posible dada tu hand y el board.',
        'Para calcular la frecuencia relativa de manos dentro de un rango.',
      ],
    ),
    ToolGuideSection(
      label: 'Las reglas del conteo',
      isFormula: true,
      body: 'Pares  (AA):   C(4,2) = 6 combos\n'
          'Suited (AKs):  4 combos (uno por palo)\n'
          'Offsuit(AKo): 4×4 − 4 = 12 combos\n\n'
          'Card removal: se descarta cualquier combo\n'
          'que use una carta muerta.',
    ),
    ToolGuideSection(
      label: 'Ejemplo',
      body: 'AA con board Ah 7d 2c\n'
          '→ 6 combos totales − 3 bloqueados por Ah = 3 disponibles\n'
          '   (AsAd · AsAc · AdAc)',
    ),
    ToolGuideSection(
      label: 'Errores comunes',
      items: [
        'Ingresar un rango en vez de una clase. Esta herramienta acepta '
            'una clase a la vez (AKs, no AK ni QQ+). Para rangos usá '
            'Blocker Explorer.',
        'Olvidar las cartas de tu propia mano como muertas. Si tenés As '
            'en la mano, AKs tiene solo 3 combos vivos.',
      ],
    ),
  ],
);

/// Combo Calculator — cuarta herramienta real de Tools V1.
///
/// La entrada principal sigue en notación de texto (`AKs`, `77`, `AKo`):
/// una CLASE de mano no son 2 cartas concretas del jugador (son hasta 16
/// combinaciones físicas distintas a la vez), así que no encaja en el
/// selector universal de cartas — es, literalmente, otro tipo de dato.
/// Las cartas muertas (0..N cartas puntuales) sí son cartas concretas, y
/// se eligen con [CardGroupField] sobre un único grupo `deadCards`
/// (mismo mecanismo que Equity/Blocker, no un picker aparte).
///
/// Todo el cálculo vive en [ComboEngine] (enumeración física + card
/// removal, ya probado) — esta pantalla solo arma la entrada y muestra
/// la lista resultante de [HoleCards].
class ComboCalculatorScreen extends StatefulWidget {
  const ComboCalculatorScreen({
    super.key,
    this.initialNotation,
    this.initialDeadCards = const [],
  });

  /// Precarga desde otra herramienta (hoy: Blocker Explorer, al tocar un
  /// chip de clase). `null` conserva el default de siempre (`'AKs'`,
  /// sin cartas muertas).
  final String? initialNotation;
  final List<Card> initialDeadCards;

  @override
  State<ComboCalculatorScreen> createState() => _ComboCalculatorScreenState();
}

class _ComboCalculatorScreenState extends State<ComboCalculatorScreen> {
  late final _handClassController =
      TextEditingController(text: widget.initialNotation ?? 'AKs');

  // Máximo generoso, no artificialmente bajo: en la práctica nadie
  // retira más de un puñado de cartas del mazo para este análisis, pero
  // nada en la mecánica lo impide — 20 cubre cualquier caso real sin
  // acercarse al límite físico de 52.
  late final _situation = CardSituationController([
    const CardGroupSpec(
      id: 'deadCards',
      label: AppStrings.comboDeadCardsLabel,
      minCount: 0,
      maxCount: 20,
      accent: SalaVerdeColors.graphiteSteelBright,
    ),
  ]);

  HandClass? _handClass;
  List<HoleCards>? _combos;
  bool _invalid = false;

  @override
  void initState() {
    super.initState();
    for (final card in widget.initialDeadCards) {
      _situation.setCard('deadCards', _situation.cardsOf('deadCards').length, card);
    }
    _situation.addListener(_recalculate);
    _recalculate();
  }

  @override
  void dispose() {
    _situation.removeListener(_recalculate);
    _situation.dispose();
    _handClassController.dispose();
    super.dispose();
  }

  HandClass? _tryParseHandClass(String text) {
    final clean = text.trim();
    if (!HandClass.isValid(clean)) return null;
    return HandClass.parse(clean);
  }

  void _recalculate() {
    final handClass = _tryParseHandClass(_handClassController.text);
    if (handClass == null) {
      setState(() {
        _handClass = null;
        _combos = null;
        _invalid = true;
      });
      return;
    }
    setState(() {
      _handClass = handClass;
      _combos = ComboEngine.combosForHandClass(
        handClass,
        deadCards: _situation.cardsOf('deadCards'),
      );
      _invalid = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SalaVerdeColors.background,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final pad = constraints.maxWidth >= 480 ? 24.0 : 18.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ToolHeader(
                  icon: Icons.style_rounded,
                  title: AppStrings.toolsComboTitle,
                  subtitle: AppStrings.toolsComboCalculatorSubtitle,
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing: ToolInfoButton(
                    onTap: () => showToolExplainerSheet(
                      context,
                      toolId: kComboToolId,
                      content: kComboExplainer,
                    ),
                  ),
                ),
                const SizedBox(height: SalaVerdeSpace.xl),
                ToolCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ToolTextField(
                        label: AppStrings.comboHandClassLabel,
                        controller: _handClassController,
                        onChanged: _recalculate,
                        hintText: AppStrings.comboHandClassHint,
                      ),
                      const SizedBox(height: SalaVerdeSpace.lg),
                      CardGroupField(controller: _situation, groupId: 'deadCards'),
                    ],
                  ),
                ),
                const SizedBox(height: SalaVerdeSpace.lg),
                if (_invalid)
                  const ToolErrorCard(message: AppStrings.comboInvalidInput)
                else if (_handClass != null && _combos != null)
                  _ResultCard(handClass: _handClass!, combos: _combos!),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.handClass, required this.combos});

  final HandClass handClass;
  final List<HoleCards> combos;

  @override
  Widget build(BuildContext context) {
    final total = handClass.combos;
    final available = combos.length;
    return ToolCard(
      borderColor: kToolAccent.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ToolSectionLabel(AppStrings.toolsResultPrincipal, color: kToolAccent),
          const SizedBox(height: SalaVerdeSpace.sm),
          Row(
            children: [
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.comboAvailableLabel,
                  value: '$available',
                  big: true,
                  color: SalaVerdeColors.success,
                ),
              ),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.comboBlockedLabel,
                  value: '${total - available}',
                  big: true,
                  color: SalaVerdeColors.errorBright,
                ),
              ),
              Expanded(
                child: ToolResultStat(
                  label: AppStrings.comboTotalLabel,
                  value: '$total',
                ),
              ),
            ],
          ),
          const SizedBox(height: SalaVerdeSpace.md),
          Text(
            AppStrings.comboExplanation(
              notation: handClass.notation,
              total: total,
              available: available,
            ),
            style: SalaVerdeType.caption(color: SalaVerdeColors.textSecondary),
          ),
          if (available == 0) ...[
            const SizedBox(height: SalaVerdeSpace.md),
            const ToolErrorCard(message: AppStrings.comboNoneAvailable),
          ] else ...[
            const SizedBox(height: SalaVerdeSpace.lg),
            const Divider(height: 1, color: SalaVerdeColors.borderSubtle),
            const SizedBox(height: SalaVerdeSpace.md),
            const ToolSectionLabel(AppStrings.comboListLabel),
            const SizedBox(height: SalaVerdeSpace.sm),
            Wrap(
              spacing: SalaVerdeSpace.sm,
              runSpacing: SalaVerdeSpace.sm,
              children: [
                for (final combo in combos)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
                      color: SalaVerdeColors.surfaceElevated,
                      border: Border.all(color: SalaVerdeColors.borderSubtle),
                    ),
                    child: Text(
                      combo.pretty,
                      style: SalaVerdeType.numeric(size: 13),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
