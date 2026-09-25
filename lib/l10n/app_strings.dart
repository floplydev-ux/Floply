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

  /// Label de accesibilidad del botón de perfil del header de Home (Fase 1,
  /// Bloque 1, P1-D) — antes no tenía ninguno.
  static const String homeProfileButtonLabel = 'Abrir tu perfil';

  static String academyLevelOf(int level, int max) => 'Nivel $level de $max';
  static String topPercent(int pct) => 'Top $pct%';

  // Laboratorio / motor de ejercicios
  static const String labHeaderTitle = 'LABORATORIO';
  static const String labHeaderSubtitle =
      'Practicá decisiones concretas y entendé el porqué.';
  static const String labYourReasoning = '¿POR QUÉ? (opcional)';
  static const String labShowAdvanced = 'Ver explicación avanzada';
  static const String labDecision = 'Decisión';
  static const String labReasoning = 'Razonamiento';
  static const String labSessionSummary = 'RESUMEN DE LA SESIÓN';
  static const String labRecoveryPrefix = 'Recuperación sugerida: ';
  static const String labConceptFocus = 'Concepto en foco';
  static const String labDifficulty = 'Dificultad';
  static const String labExitTooltip = 'Salir del entrenamiento';

  // Selector de dificultad (Fácil/Medio/Experto/Custom) — Fase 9:
  // eliminado el Modo Clásico, estas son las únicas cuatro modalidades.
  static const String labChooseTitle = '¿QUÉ QUERÉS PRACTICAR?';
  static const String labChooseSubtitle =
      'Elegí un nivel — vas a poder cambiarlo cuando quieras.';

  // Custom (Fase 8): sesión configurada por el usuario, no un preset.
  static const String labCustomLabel = 'CUSTOM';
  static const String labCustomSubtitle = 'A tu medida';
  static const String labCustomDescription =
      'Elegí exactamente qué áreas practicar, en vez de un nivel fijo.';
  static const String labCustomHeaderTitle = 'CUSTOM';
  static const String labCustomHeaderSubtitle = 'Elegí qué querés practicar';
  static const String labCustomAreasHeader = '¿QUÉ ÁREAS QUERÉS PRACTICAR?';
  static const String labCustomAreasSubtitle =
      'Elegí una o más — podés combinarlas.';
  static const String labCustomLengthHeader = '¿CUÁNTOS EJERCICIOS?';
  static const String labCustomEmptyHint =
      'Elegí al menos un área para poder empezar.';
  static const String labCustomStart = 'COMENZAR';
  static const String labBack = 'ATRÁS';

  static String labCustomSummary(int areas, int exercises) =>
      '$areas ${areas == 1 ? 'área' : 'áreas'} · $exercises ejercicios';

  // Resumen de sesión del motor nuevo (Fase 9)
  static const String labKeepPracticing = 'SEGUIR PRACTICANDO';
  static const String labBackToLab = 'VOLVER AL LABORATORIO';
  static const String labQualityHeader = 'CALIDAD DE DECISIONES';
  static const String labPracticedHeader = 'LO QUE PRACTICASTE';
  static const String labToImproveHeader = 'PARA SEGUIR TRABAJANDO';
  static const String labRecentDecisionsHeader = 'DECISIONES RECIENTES';

  static String labProgress(int current, int total) => '$current / $total';

  // Estadísticas
  static const String statsHeaderTitle = 'ESTADÍSTICAS';
  static const String statsHeaderSubtitle =
      'Tu progreso real en la Academia, en un solo lugar.';
  static const String statsAcademySection = 'ACADEMIA';
  static const String statsLevelsSection = 'NIVELES';
  static const String statsConceptMasterySection = 'DOMINIO POR CONCEPTO';
  static const String statsConceptMasteryEmpty =
      'Todavía no hay conceptos practicados para mostrar acá.';
  static const String statsLabSection = 'LABORATORIO';
  static const String statsLabEmptyTitle = 'Todavía sin historial guardado';
  static const String statsLabEmptyBody =
      'Las sesiones del Laboratorio no se guardan entre sesiones todavía — '
      'esta sección va a mostrar precisión y evolución en cuanto ese '
      'historial exista.';

  // Academia
  static const String academyHeaderSubtitle =
      'Aprendé paso a paso: teoría, práctica y evaluación.';
  static const String academyMasteredLabel = 'Conceptos dominados';

  /// Fase 1, Bloque 2, P1-1: `LevelState.available` y `.inProgress` se
  /// veían idénticos en el mapa — el engine ya distinguía "nunca empezado"
  /// de "algo completado, no todo" (`academy_engine.dart`), la UI no.
  static String academyLevelInProgress(int done, int total) =>
      'EN CURSO · $done/$total';

  /// Labels de estado para accesibilidad (Fase 1, Bloque 2, P1-3) — el
  /// único lugar donde hoy se expresa bloqueado/disponible/en curso/
  /// completado en palabras, no solo con un ícono.
  static const String academyStateLocked = 'Bloqueado';
  static const String academyStateAvailable = 'Disponible';
  static const String academyStateInProgress = 'En curso';
  static const String academyStateCompleted = 'Completado';
  static const String academyLockedLessonHint =
      'Completá la lección anterior para desbloquearla.';
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

  // Ejercicio jugable (mesa + acción real)
  static const String playableWhyTitle = '¿POR QUÉ ELEGISTE ESTA ACCIÓN?';
  static const String playableActionResultLabel = 'Elegiste';
  static const String playableReasoningLabel = 'Tu razonamiento';
  static const String playableConceptLabel = 'Concepto';

  static String playableChooseSizeBody(String actionLabel) =>
      'Elegiste $actionLabel. Elegí el tamaño.';

  static String playableWhyBody(String actionLabel) =>
      '¿Por qué elegiste $actionLabel?';

  static String academyLevelLabel(int number, String title) =>
      'Nivel $number · $title';
  static String academyLessonsDone(int done, int total) =>
      '$done de $total lecciones completadas';
  static String academyScore(int pct) => 'Puntaje: $pct%';

  static const String bankrollTitle = 'BANKROLL';
  static const String bankrollDescription =
      'Antes de jugar NL2 con dinero real: cómo cuidar tu capital.';
  static const String bankrollCardCta = 'VER MÓDULO';
  static const String bankrollScreenSubtitle = 'Módulo complementario';
  static const String bankrollDone = '¡Módulo completo!';
  static const String bankrollDoneBody =
      'Ya viste los conceptos clave para cuidar tu bankroll antes de '
      'jugar NL2 con dinero real.';

  // Home
  static String homeGreeting(String name) => 'Hola, $name';
  static const String homeGreetingSubtitle = 'Sigamos mejorando tu juego.';

  static const String continueLearningEyebrow = 'SEGUIMOS DONDE QUEDASTE';
  static const String continueLearningNewTitle = 'Empezá a aprender póker';
  static const String continueLearningNewBody =
      'Un camino paso a paso, desde las bases hasta jugar con confianza.';
  static const String continueLearningStartCta = 'COMENZAR ACADEMIA';
  static const String continueLearningCompletedTitle = 'Academia completada';
  static const String continueLearningCompletedBody =
      'Terminaste todo el camino de la Academia. Practicá lo aprendido para '
      'afianzarlo.';
  static const String continueLearningLoadingBody = 'Cargando tu progreso…';

  // Fase 1, Bloque 1, P1-C: separa visualmente "lo que hay que hacer
  // ahora" (el hero de arriba) de "el resto de la app" (Laboratorio,
  // Bankroll, Tools, Coach) — sin eliminar ningún destino ni cambiar
  // navegación, solo un eyebrow de sección.
  static const String homeMoreLabel = 'SEGUÍ EXPLORANDO';

  static const String practiceRoomTitle = 'PRACTICE ROOM';
  static const String practiceRoomBody =
      'Ya aprendiste la teoría. Ahora practicá para hacerla automática.';

  static const String toolsTitle = 'TOOLS';
  static const String toolsDescription =
      'Rangos, calculadoras y otras herramientas para analizar tu juego.';

  // Tools — hub y Pot Odds Calculator (V1)
  static const String toolsHeaderTitle = 'TOOLS';
  static const String toolsHeaderSubtitle =
      'Calculadoras rápidas para analizar una situación concreta.';
  static const String toolsPotOddsTitle = 'POT ODDS';
  static const String toolsPotOddsSubtitle = 'Calculadora';
  static const String toolsPotOddsCardDescription =
      '¿Cuánta equity necesitás para que pagar sea rentable?';
  static const String toolsComingSoonLabel = 'Próximamente';
  static const String toolsEquityTitle = 'EQUITY';
  static const String toolsEquityCardDescription =
      'Mano vs mano, mano vs rango, rango vs rango.';
  static const String toolsEvTitle = 'EV';
  static const String toolsEvCardDescription =
      'Valor esperado de pagar una apuesta.';
  static const String toolsRangesTitle = 'RANGOS';
  static const String toolsRangesCardDescription =
      'Rangos de apertura por posición.';
  static const String toolsComboTitle = 'COMBOS';
  static const String toolsComboCardDescription =
      'Combinaciones físicas de una mano, con cartas muertas.';
  static const String toolsBlockerTitle = 'BLOCKERS';
  static const String toolsBlockerCardDescription =
      'Cuánto bloquea tu mano al rango del rival.';

  static const String potOddsPotLabel = 'Bote antes de pagar';
  static const String potOddsCallLabel = 'Lo que tenés que pagar';
  static const String potOddsBbSuffix = 'BB';
  static const String potOddsFinalPotLabel = 'Bote final';
  static const String potOddsRequiredEquityLabel = 'Equity necesaria';
  static const String potOddsRatioLabel = 'Pot odds';
  static const String potOddsInvalidInput = 'Ingresá números válidos (0 o más).';

  static String potOddsExplanation(double requiredEquityPct) =>
      'Necesitás ganar al menos ${requiredEquityPct.toStringAsFixed(1)}% de '
      'las veces para que pagar sea rentable a largo plazo. Si tu equity '
      'real en esta mano es mayor, pagar es +EV.';

  // EV Calculator (V1)
  static const String toolsEvCalculatorSubtitle =
      'Valor esperado de pagar una apuesta.';
  static const String evPotLabel = 'Bote antes de pagar';
  static const String evCallLabel = 'Lo que tenés que pagar';
  static const String evEquityLabel = 'Tu equity estimada';
  static const String evPercentSuffix = '%';
  static const String evRequiredEquityLabel = 'Equity necesaria (break-even)';
  static const String evResultLabel = 'Valor esperado (EV)';
  static const String evInvalidInput =
      'Ingresá números válidos: bote/call ≥ 0, equity entre 0 y 100.';
  static const String evProfitableLabel = '+EV: pagar gana en el largo plazo';
  static const String evBreakEvenLabel = 'Break-even: ni gana ni pierde';
  static const String evLosingLabel = '-EV: pagar pierde en el largo plazo';

  static String evExplanation({
    required double evBb,
    required double equityPct,
    required double requiredEquityPct,
  }) {
    final diff = (equityPct - requiredEquityPct).abs().toStringAsFixed(1);
    if (evBb > 0) {
      return 'Tu equity estimada (${equityPct.toStringAsFixed(1)}%) supera '
          'la necesaria (${requiredEquityPct.toStringAsFixed(1)}%) por '
          '$diff puntos — pagar tiene EV positivo.';
    }
    if (evBb < 0) {
      return 'Tu equity estimada (${equityPct.toStringAsFixed(1)}%) está '
          '$diff puntos por debajo de la necesaria '
          '(${requiredEquityPct.toStringAsFixed(1)}%) — pagar tiene EV '
          'negativo.';
    }
    return 'Tu equity estimada coincide exactamente con la necesaria: '
        'pagar es break-even.';
  }

  // EV Calculator V2 — EV de apostar/subir (EV Avanzado, alcance
  // "Modelo A" de EV_AVANZADO_AUDITORIA_DISENO.md)
  static const String evModeCallLabel = 'Pagar un call';
  static const String evModeBetLabel = 'Apostar / subir';
  static const String evBetPotLabel = 'Bote antes de tu apuesta';
  static const String evBetSizeLabel = 'Tu apuesta';
  static const String evBetFoldLabel = '% que el rival foldea';
  static const String evBetCallLabel = '% que el rival paga';
  static const String evBetEquityLabel = 'Tu equity si paga';
  static const String evBetInvalidInput =
      'Ingresá números válidos: bote ≥ 0, apuesta > 0, % fold + % call ≤ '
      '100, equity si paga entre 0 y 100.';
  static const String evBetFoldContributionLabel = 'Aporte si foldea';
  static const String evBetCallContributionLabel = 'Aporte si paga';

  static String evBetUnmodeledWarning(double unmodeledPct) =>
      'El ${unmodeledPct.toStringAsFixed(1)}% restante corresponde a que '
      'el rival suba — esa rama no está incluida en este cálculo (ver '
      'EV_AVANZADO_AUDITORIA_DISENO.md). El EV mostrado es una cota '
      'parcial, no el EV completo de la apuesta.';

  static String evBetExplanation(double evBb) {
    if (evBb > 0) {
      return 'Sumando lo que ganás cuando el rival foldea y lo que '
          'esperás cuando paga, esta apuesta tiene EV positivo con las '
          'probabilidades que ingresaste.';
    }
    if (evBb < 0) {
      return 'Sumando lo que ganás cuando el rival foldea y lo que '
          'esperás cuando paga, esta apuesta tiene EV negativo con las '
          'probabilidades que ingresaste.';
    }
    return 'Con las probabilidades que ingresaste, esta apuesta es '
        'exactamente break-even.';
  }

  // Equity Calculator (V1: mano vs mano; V2: + mano vs rango, rango vs rango)
  static const String toolsEquityCalculatorSubtitle =
      'Elegí el modo: mano vs mano, mano vs rango o rango vs rango.';
  static const String equityHeroLabel = 'Tu mano';
  static const String equityVillainLabel = 'Mano del rival';
  static const String equityBoardLabel = 'Board (3, 4 o 5 cartas)';
  static const String equityHeroHint = 'ej. AhKd';
  static const String equityVillainHint = 'ej. QsQc';
  static const String equityBoardHint = 'ej. 2c7d9h';
  static const String equityWinLabel = 'Ganás';
  static const String equityTieLabel = 'Empatás';
  static const String equityLoseLabel = 'Perdés';
  static const String equityInvalidInput =
      'Revisá la notación: 2 caracteres por carta (ej. As, Td), board de '
      '3, 4 o 5 cartas, y ninguna carta repetida entre tu mano, la del '
      'rival y el board.';

  static String equityExplanation(double equityPct) =>
      'Tu equity es la parte del bote que te corresponde en promedio si '
      'la mano se jugara muchas veces desde acá: ${equityPct.toStringAsFixed(1)}% '
      'de las veces terminás llevándote el bote (contando los empates a '
      'mitad de valor).';

  // Equity Calculator V2 — mano vs rango y rango vs rango
  static const String equityModeHandVsHandLabel = 'Mano vs mano';
  static const String equityModeHandVsRangeLabel = 'Mano vs rango';
  static const String equityModeRangeVsRangeLabel = 'Rango vs rango';
  static const String equityHeroRangeLabel = 'Tu rango';
  static const String equityVillainRangeLabel = 'Rango del rival';
  static const String equityHeroRangeHint = 'ej. AA-TT,AKs,AKo';
  static const String equityVillainRangeHint = 'ej. QQ+,AKs,AKo';
  static const String equityRangeInvalidInput =
      'Revisá la notación del rango: tokens separados por coma (ej. '
      '77+, ATs+, AKo, A5s-A2s), con frecuencia opcional entre paréntesis '
      '(ej. KQo(0.5)).';
  static const String equityRangeBlockedError =
      'No queda ningún escenario válido: el board o las manos indicadas '
      'bloquean por completo el rango rival. Probá con un rango más ancho '
      'o un board distinto.';
  static const String equityCalculateButtonLabel = 'Calcular equity';
  static const String equityCalculatingLabel = 'Calculando…';
  static const String equityRangeModeHint =
      'Completá los campos y tocá "Calcular equity". En rangos anchos el '
      'cálculo puede tardar unos segundos: enumera cada combinación física '
      'posible, no es una aproximación.';
  static const String equityScenariosLabel = 'Escenarios evaluados';

  // Combo Calculator (V1)
  static const String toolsComboCalculatorSubtitle =
      'Combinaciones físicas de una clase de mano.';
  static const String comboHandClassLabel = 'Clase de mano';
  static const String comboHandClassHint = 'ej. AKs, 77, AKo';
  static const String comboDeadCardsLabel = 'Cartas muertas (opcional)';
  static const String comboDeadCardsHint = 'ej. 2c7d9h';
  static const String comboTotalLabel = 'Combos totales';
  static const String comboAvailableLabel = 'Disponibles';
  static const String comboBlockedLabel = 'Bloqueados';
  static const String comboListLabel = 'Combos disponibles';
  static const String comboInvalidInput =
      'Revisá la notación: la clase de mano se escribe como AKs, AKo o 77, '
      'y las cartas muertas de a 2 caracteres cada una (ej. As, Td), sin '
      'repetir ninguna.';
  static const String comboNoneAvailable =
      'No queda ningún combo disponible: las cartas muertas bloquean todas '
      'las combinaciones de esta clase de mano.';

  static String comboExplanation({
    required String notation,
    required int total,
    required int available,
  }) {
    final blocked = total - available;
    if (blocked == 0) {
      return '$notation tiene $total combos posibles y ninguno está '
          'bloqueado por las cartas muertas.';
    }
    return '$notation tiene $total combos posibles. Con las cartas muertas '
        'indicadas, $blocked ${blocked == 1 ? 'está bloqueado' : 'están '
            'bloqueados'} y quedan $available disponibles.';
  }

  // Range Explorer (V1)
  static const String toolsRangesCalculatorSubtitle =
      'Rango de apertura (RFI) por posición.';
  static const String rangesPositionLabel = 'Posición';
  static const String rangesSizingLabel = 'Apertura estándar';
  static const String rangesPercentLabel = '% de manos';
  static const String rangesBbTitle = 'La BB no abre';
  static const String rangesBbBody =
      'La Big Blind ya puso su apuesta: si todos foldean antes de que le '
      'toque actuar, se lleva el bote sin necesidad de abrir. No tiene un '
      'rango de apertura propio — su primera decisión real es responder a '
      'una apertura ajena.';
  static const String rangesCellHandLabel = 'Mano';
  static const String rangesCellFrequencyLabel = 'Frecuencia';
  static const String rangesCellCombosLabel = 'Combos';
  static const String rangesTapHint = 'Tocá una mano de la grilla para ver el detalle.';
  static const String rangesLegendFull = 'Se abre siempre';
  static const String rangesLegendMixed = 'Estrategia mixta';
  static const String rangesLegendNone = 'No se abre';

  // Blocker Explorer (V2)
  static const String toolsBlockerCalculatorSubtitle =
      'Combos del rango rival que bloquea tu mano.';
  static const String blockerHeroLabel = 'Tu mano';
  static const String blockerHeroHint = 'ej. AhKd';
  static const String blockerVillainRangeLabel = 'Rango del rival';
  static const String blockerVillainRangeHint = 'ej. QQ+,AKs,AKo';
  static const String blockerBoardLabel = 'Board (opcional)';
  static const String blockerBoardHint = 'ej. 2c7d9h';
  static const String blockerInvalidHand =
      'Revisá la notación de tu mano: 2 caracteres por carta (ej. As, Td), '
      'sin repetir ninguna con el board.';
  static const String blockerInvalidRange = equityRangeInvalidInput;
  static const String blockerInvalidBoard =
      'El board tiene que estar vacío o tener 3, 4 o 5 cartas (ej. 2c7d9h), '
      'sin repetir ninguna con tu mano.';
  static const String blockerTotalLabel = 'Combos totales';
  static const String blockerAvailableLabel = 'Disponibles';
  static const String blockerBlockedLabel = 'Bloqueados';
  static const String blockerClassesHeader = 'Por clase de mano';
  static const String blockerEmptyRangeError =
      'El rango del rival no tiene ningún combo válido una vez descontadas '
      'tu mano y el board — probá con un rango más ancho.';

  static String blockerExplanation({
    required int total,
    required int available,
  }) {
    final blocked = total - available;
    if (blocked == 0) {
      return 'Tu mano no bloquea ningún combo del rango del rival: de '
          '$total combos posibles, los $available siguen disponibles.';
    }
    final pct = (blocked / total * 100).toStringAsFixed(0);
    return 'Tu mano bloquea $blocked de $total combos del rango rival '
        '($pct%) — quedan $available disponibles.';
  }

  static const String coachTitle = 'COACH';
  static const String coachDescription =
      'Tu entrenamiento personalizado. Próximamente.';

  static const String navTools = 'Tools';
  static const String navCoach = 'Coach';

  // Auth — pantalla de acceso (Fase 22)
  static const String authTagline = 'Aprendé póker jugando.';
  static const String authContinueGoogle = 'Continuar con Google';
  static const String authContinueApple = 'Continuar con Apple';
  static const String authContinueEmail = 'Continuar con email';
  static const String authContinueWithoutAccount = 'Continuar sin cuenta';
  static const String authOr = 'o';

  // Auth — email (Fase 5)
  static const String authEmailTitle = 'Ingresá tu email';
  static const String authEmailBody =
      'Te mandamos un link para entrar, sin contraseña.';
  static const String authEmailHint = 'tu@email.com';
  static const String authEmailSend = 'ENVIAR LINK';
  static const String authEmailSentTitle = 'Revisá tu correo';
  static String authEmailSentBody(String email) =>
      'Te mandamos un link a $email. Tocalo desde este dispositivo para '
      'continuar.';
  static const String authEmailResend = 'Reenviar link';
  static const String authEmailInvalid = 'Ingresá un email válido.';

  // Auth — cuenta (Fase 8/16/17/18)
  static const String accountTitle = 'CUENTA';
  static const String accountMethodsTitle = 'Métodos de acceso';
  static const String accountMethodsBody =
      'Todos representan la misma cuenta FLOPly.';
  static const String accountLinked = 'Vinculado';
  static const String accountLink = 'Vincular';
  static const String accountUnlink = 'Quitar';
  static const String accountSignOut = 'Cerrar sesión';
  static const String accountSignOutConfirm =
      '¿Cerrar sesión? Tu progreso queda guardado en la nube.';
  static const String accountDelete = 'Eliminar cuenta';
  static const String accountDeleteWarning =
      'Esta acción eliminará tu cuenta y los datos asociados. No se puede '
      'deshacer.';
  static const String accountDeleteConfirm = 'Sí, eliminar mi cuenta';
  static const String accountCancel = 'Cancelar';
  static const String accountGuestTitle = 'Estás usando FLOPly sin cuenta';
  static const String accountGuestBody =
      'Creá una cuenta para guardar tu progreso y usarlo en otro '
      'dispositivo.';
  static const String accountCreateCta = 'Crear cuenta';

  // Auth — conflicto de cuentas (Fase 9)
  static const String accountConflictTitle =
      'Este método de acceso ya está en otra cuenta FLOPly.';
  static String accountConflictBody(String? email) => email == null
      ? 'Ya existe una cuenta asociada a este método.'
      : 'Ya existe una cuenta asociada a $email.';
  static const String accountConflictSignIn = 'Iniciar sesión en esa cuenta';
  static const String accountConflictCancel = 'Cancelar';
}
