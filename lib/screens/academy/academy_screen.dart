import 'package:flutter/material.dart';

import '../../services/premium/premium_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sala_verde/floply_loading_indicator.dart';
import 'academy_controller.dart';
import 'widgets/lesson_flow.dart';
import 'widgets/level_map.dart';

/// Pantalla de la Academia: el recorrido pedagógico estructurado (niveles
/// 1–5). Reemplaza al placeholder "Próximamente" de esa pestaña.
///
/// La práctica libre sigue viviendo en el Laboratorio: la Academia es
/// *aprender y progresar*. Esta clase es solo el *shell*: es dueña del
/// controlador y ramifica entre el mapa (`LevelMap`) y el recorrido de una
/// lección (`LessonFlow`).
class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key, this.controller, this.premium});

  final AcademyController? controller;

  /// Si se omite, el banner de publicidad nunca se muestra (ej. tests).
  final PremiumService? premium;

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  late final AcademyController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AcademyController();
    _ownsController = widget.controller == null;
    if (_controller.loading) _controller.load();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.backgroundGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        // `bottom: true` (antes `false`): con la navbar transparente de
        // `AppShell` (`extendBody: true`), este `SafeArea` es quien
        // reserva el espacio real de la barra para que la mesa/el scroll
        // no terminen por detrás — antes era innecesario porque la barra
        // opaca ya reservaba su propio lugar en el layout. La altura de
        // la mesa (`TableExplanationView.tableHeightFor`) ya se calcula
        // proporcional al alto real de pantalla con piso/techo, así que
        // los ~70dp menos de espacio no la rompen.
        child: AnimatedBuilder(
          animation: widget.premium != null
              ? Listenable.merge([_controller, widget.premium!])
              : _controller,
          builder: (context, _) {
            if (_controller.loading) {
              return const Center(child: FloplyLoadingIndicator(size: 64));
            }
            return _controller.phase == AcademyPhase.map
                ? LevelMap(controller: _controller)
                : LessonFlow(
                    controller: _controller,
                    isPremium: widget.premium?.isPremium ?? false,
                  );
          },
        ),
      ),
    );
  }
}
