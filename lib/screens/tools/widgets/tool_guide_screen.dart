import 'package:flutter/material.dart';

import '../../../theme/sala_verde/sala_verde_tokens.dart';
import '../../../widgets/sala_verde/sala_verde_widgets.dart';
import 'tool_widgets.dart';

/// Una sección de la guía previa de un tool.
///
/// Puede ser texto plano ([body]), lista de ítems ([items]), o ambos.
/// Con [isNote] renderiza como callout de advertencia (útil para
/// limitaciones importantes). Con [isFormula] renderiza en bloque
/// monospace con borde izquierdo.
class ToolGuideSection {
  const ToolGuideSection({
    required this.label,
    this.body,
    this.items,
    this.isNote = false,
    this.isFormula = false,
  });

  final String label;
  final String? body;
  final List<String>? items;
  final bool isNote;
  final bool isFormula;
}

/// Contenido completo de la guía previa de un tool.
class ToolGuideContent {
  const ToolGuideContent({
    required this.title,
    required this.tagline,
    required this.icon,
    required this.sections,
  });

  final String title;
  final String tagline;
  final IconData icon;
  final List<ToolGuideSection> sections;
}

/// Pantalla completa de guía que se muestra antes de cada calculadora.
///
/// Flujo: `ToolsScreen` → `EconomyGate(ToolGuideScreen)` → `Calculator`.
/// El botón sticky "Usar <título>" empuja el calculator como ruta nueva
/// sin salir del EconomyGate activo.
class ToolGuideScreen extends StatelessWidget {
  const ToolGuideScreen({
    super.key,
    required this.content,
    required this.calculatorBuilder,
  });

  final ToolGuideContent content;
  final WidgetBuilder calculatorBuilder;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.sizeOf(context).width >= 480 ? 24.0 : 18.0;
    return Scaffold(
      backgroundColor: SalaVerdeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(pad, 12, pad, SalaVerdeSpace.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ToolHeader(
                      icon: content.icon,
                      title: content.title,
                      subtitle: content.tagline,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: SalaVerdeSpace.xl),
                    for (int i = 0; i < content.sections.length; i++) ...[
                      if (i > 0) const SizedBox(height: SalaVerdeSpace.lg),
                      _SectionBlock(section: content.sections[i]),
                    ],
                  ],
                ),
              ),
            ),
            _StickyButton(
              label: 'Usar ${content.title}',
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: calculatorBuilder)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sección individual ────────────────────────────────────────────────────────

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section});

  final ToolGuideSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.label.toUpperCase(),
          style: SalaVerdeType.label(color: kToolAccent),
        ),
        const SizedBox(height: SalaVerdeSpace.sm),
        if (section.isNote)
          SvCalloutAccent(
            eyebrow: '',
            body: section.body ?? section.items?.join('\n') ?? '',
            color: SalaVerdeColors.warning,
            icon: Icons.info_outline_rounded,
          )
        else if (section.isFormula)
          _FormulaBlock(text: section.body ?? '')
        else ...[
          if (section.body != null)
            Text(
              section.body!,
              style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
            ),
          if (section.items != null) ...[
            if (section.body != null) const SizedBox(height: SalaVerdeSpace.sm),
            for (final item in section.items!)
              _BulletItem(text: item),
          ],
        ],
      ],
    );
  }
}

class _FormulaBlock extends StatelessWidget {
  const _FormulaBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SalaVerdeSpace.md),
      decoration: BoxDecoration(
        color: SalaVerdeColors.surfaceElevated,
        borderRadius: BorderRadius.circular(SalaVerdeRadius.control),
        border: const Border(
          left: BorderSide(color: kToolAccent, width: 3),
          top: BorderSide(color: SalaVerdeColors.borderSubtle),
          right: BorderSide(color: SalaVerdeColors.borderSubtle),
          bottom: BorderSide(color: SalaVerdeColors.borderSubtle),
        ),
      ),
      child: Text(
        text,
        style: SalaVerdeType.numeric(
          size: 13,
          color: SalaVerdeColors.textPrimary,
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: SalaVerdeColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: SalaVerdeType.body(color: SalaVerdeColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón sticky inferior ─────────────────────────────────────────────────────

class _StickyButton extends StatelessWidget {
  const _StickyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.sizeOf(context).width >= 480 ? 24.0 : 18.0;
    return Container(
      padding: EdgeInsets.fromLTRB(
        pad, SalaVerdeSpace.md, pad, SalaVerdeSpace.lg,
      ),
      decoration: const BoxDecoration(
        color: SalaVerdeColors.surface,
        border: Border(top: BorderSide(color: SalaVerdeColors.borderSubtle)),
      ),
      child: SvButtonPrimary(
        label: label,
        accent: kToolAccent,
        onTap: onTap,
      ),
    );
  }
}
