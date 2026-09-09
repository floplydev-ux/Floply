import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
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
  const AcademyScreen({super.key, this.controller});

  final AcademyController? controller;

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
        bottom: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return _controller.phase == AcademyPhase.map
                ? LevelMap(controller: _controller)
                : LessonFlow(controller: _controller);
          },
        ),
      ),
    );
  }
}
