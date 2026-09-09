/// Copy de la interfaz, centralizado.
///
/// Ningún widget hardcodea texto visible directamente: todo pasa por acá.
/// El día que se agregue internacionalización real (paquete `intl` +
/// archivos `.arb`), esta clase se reemplaza por las claves generadas sin
/// tener que tocar los widgets que hoy la consumen.
class AppStrings {
  AppStrings._();

  static const String comingSoonTitle = 'Próximamente';
  static const String comingSoonBody =
      'Esta sección todavía se está construyendo.';

  static const String xpSuffix = 'XP';
  static const String levelLabel = 'NIVEL';

  static const String streakCurrentLabel = 'RACHA ACTUAL';
  static const String streakBestLabel = 'MEJOR RACHA';
  static const String daysSuffix = 'días';

  static const String academyTitle = 'ACADEMIA';
  static const String academyDescription =
      'Aprendé paso a paso y desbloqueá tu mejor juego.';
  static const String yourProgressLabel = 'TU PROGRESO';
  static const String continueLabel = 'CONTINUAR';

  static const String laboratoryTitle = 'LABORATORIO';
  static const String laboratoryDescription =
      'Practicá situaciones específicas y mejorá tus habilidades.';
  static const String lastSessionLabel = 'ÚLTIMA SESIÓN';
  static const String practiceNowLabel = 'PRACTICAR AHORA';

  static const String accuracyLabel = 'PRECISIÓN';
  static const String thisWeekLabel = 'esta semana';
  static const String rankingLabel = 'RANKING';
  static const String exercisesLabel = 'EJERCICIOS';
  static const String completedLabel = 'Completados';
  static const String activityLabel = 'ACTIVIDAD';

  static const String weeklyChallengeTitle = 'DESAFÍO SEMANAL';
  static const String rewardLabel = 'RECOMPENSA';

  static const String navHome = 'Inicio';
  static const String navAcademy = 'Academia';
  static const String navLab = 'Laboratorio';
  static const String navStats = 'Estadísticas';
  static const String navProfile = 'Perfil';

  static String academyLevelOf(int level, int max) => 'Nivel $level de $max';
  static String topPercent(int pct) => 'Top $pct%';

  // Laboratorio / motor de ejercicios
  static const String labHeaderTitle = 'LABORATORIO';
  static const String labHeaderSubtitle =
      'Practicá decisiones concretas y entendé el porqué.';
  static const String labStartSession = 'EMPEZAR A PRACTICAR';
  static const String labYourReasoning = '¿POR QUÉ? (opcional)';
  static const String labConfirm = 'CONFIRMAR';
  static const String labNext = 'SIGUIENTE';
  static const String labShowAdvanced = 'Ver explicación avanzada';
  static const String labDecision = 'Decisión';
  static const String labReasoning = 'Razonamiento';
  static const String labSessionSummary = 'RESUMEN DE LA SESIÓN';
  static const String labAgain = 'OTRA SESIÓN';
  static const String labRecoveryPrefix = 'Recuperación sugerida: ';
  static const String labConceptFocus = 'Concepto en foco';
  static const String labDifficulty = 'Dificultad';

  static String labProgress(int current, int total) => '$current / $total';

  // Academia
  static const String academyHeaderSubtitle =
      'Aprendé paso a paso: teoría, práctica y evaluación.';
  static const String academyMasteredLabel = 'Conceptos dominados';
  static const String academyContinue = 'CONTINUAR';
  static const String academyBack = 'ATRÁS';
  static const String academyStartPractice = 'PRACTICAR';
  static const String academyConfirm = 'CONFIRMAR';
  static const String academyNext = 'SIGUIENTE';
  static const String academySeeResult = 'VER RESULTADO';
  static const String academyPassed = '¡Evaluación aprobada!';
  static const String academyNotPassed = 'Todavía no alcanza';
  static const String academyLessonDone = '¡Lección completada!';
  static const String academyPracticeMore = 'PRACTICÁ MÁS ESTO';
  static const String academyStartRecovery = 'PRACTICAR RECUPERACIÓN';
  static const String academyRetry = 'REINTENTAR EVALUACIÓN';
  static const String academyBackToMap = 'VOLVER AL MAPA';
  static const String academyRecoveryTitle = 'Práctica de recuperación';

  static String academyLevelLabel(int number, String title) =>
      'Nivel $number · $title';
  static String academyLessonsDone(int done, int total) =>
      '$done de $total lecciones completadas';
  static String academyScore(int pct) => 'Puntaje: $pct%';
}
