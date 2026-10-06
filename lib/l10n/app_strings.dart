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

  static const String laboratoryTitle = 'ENTRENAMIENTO';
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
  static const String navLab = 'Entrenamiento';
  static const String navStats = 'Estadísticas';
  static const String navProfile = 'Perfil';

  /// Label de accesibilidad del botón de perfil del header de Home (Fase 1,
  /// Bloque 1, P1-D) — antes no tenía ninguno.
  static const String homeProfileButtonLabel = 'Abrir tu perfil';
  static const String homeNotificationsLabel = 'Notificaciones';

  static String academyLevelOf(int level, int max) => 'Nivel $level de $max';
  static String topPercent(int pct) => 'Top $pct%';

  // Laboratorio / motor de ejercicios
  static const String labHeaderTitle = 'ENTRENAMIENTO';
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
  static const String labBackToLab = 'VOLVER AL ENTRENAMIENTO';
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
  static const String statsLabSection = 'ENTRENAMIENTO';
  static const String statsLabEmptyTitle = 'Todavía sin historial guardado';
  static const String statsLabEmptyBody =
      'Las sesiones de Entrenamiento no se guardan entre sesiones '
      'todavía — esta sección va a mostrar precisión y evolución en cuanto '
      'ese historial exista.';

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
  static const String academyReviewSubtitle = 'Repaso acumulativo';
  static const String academyReviewDone = '¡Repaso completo!';
  static const String academyStartReview = 'HACER EL REPASO';
  static const String academyReviewLater = 'MÁS TARDE';
  static const String academyReviewBannerBody =
      'Antes de seguir, repasemos conceptos de todo lo que viste hasta '
      'acá — no solo lo último.';

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
  static const String toolsBannerDescription = 'Analizá y comprendé tus decisiones.';
  static const String toolsDescription =
      'Rangos, calculadoras y otras herramientas para analizar tu juego.';

  // Home v2 — hero expandido con banner + bloque de nivel (reutiliza
  // academyTitle/academyDescription/yourProgressLabel/laboratoryTitle/
  // laboratoryDescription/continueLabel/practiceNowLabel/academyLevelOf,
  // strings ya existentes de una iteración anterior del Home, nunca
  // tocadas por la migración a Sala Verde — deliberadamente NO reutiliza
  // xpSuffix/streakCurrentLabel/streakBestLabel/rankingLabel/
  // weeklyChallengeTitle/rewardLabel: esas dependían de racha/XP/ranking,
  // mecánicas que no existen de verdad hoy).
  static const String homeHeroEyebrow = 'NIVEL ACTUAL';
  static const String homeSeeProgressDetails = 'Ver estadísticas';
  static const String homeLabProgressBody =
      'Practicá para empezar a ver tu evolución acá.';

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

  // Selector visual de cartas (Grupo 2, sección 1) — compartido por
  // cualquier Tool que necesite elegir cartas concretas.
  static const String toolsCardPickerTitle = 'Elegí una carta';
  static const String toolsHandPickBoth = 'Seleccioná tus 2 cartas para continuar.';
  static const String toolsHandPickOne = 'Te falta seleccionar 1 carta.';
  static const String toolsHandComplete = 'Mano completa.';
  static const String toolsCardGroupClear = 'Limpiar';
  static String toolsBoardMissing(int missing) => missing == 1
      ? 'Te falta 1 carta para completar el board.'
      : 'Te faltan $missing cartas para completar el board.';
  static String toolsGroupComplete(int max) => 'Completo ($max cartas).';
  static String toolsBoardOptional(int remaining) =>
      remaining == 1 ? 'Podés agregar 1 carta más.' : 'Podés agregar hasta $remaining más.';

  // Jerarquía de resultados compartida (sección 5): resultado principal
  // vs. datos utilizados vs. información complementaria.
  static const String toolsResultPrincipal = 'Resultado';
  static const String toolsResultDatos = 'Datos utilizados';
  static const String toolsResultInfo = 'Información complementaria';

  // Sistema de explicación contextual (Grupo 3) — compartido por las 6
  // herramientas; cada una aporta solo su contenido (ver
  // `tool_explainer.dart` y las constantes `kXxxExplainer` al final de
  // este archivo).
  static const String toolsExplainerHowToUse = 'Qué tenés que ingresar';
  static const String toolsExplainerResult = 'Qué resultado obtenés';
  static const String toolsExplainerExtra = 'Tené en cuenta';
  static const String toolsExplainerDontShowAgain = 'No volver a mostrar';
  static const String toolsExplainerCta = 'Entendido';

  // Guía consolidada del hub de Tools ("¿Cómo usar las herramientas?") —
  // reutiliza el contenido real de cada `kXxxExplainer` (ver arriba) y
  // solo aporta, por herramienta, cuándo conviene usarla y un ejemplo
  // breve — ver `tools_guide_sheet.dart`.
  static const String toolsGuideButtonLabel = '¿Cómo usar las herramientas?';
  static const String toolsGuideTitle = 'Cómo usar las herramientas';
  static const String toolsGuideSubtitle =
      'Qué hace cada una, cuándo conviene usarla y un ejemplo rápido.';
  static const String toolsGuideWhenToUse = 'Cuándo conviene usarla';
  static const String toolsGuideExample = 'Ejemplo';
  static const String toolsGuideClose = 'Cerrar';

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
  static const String potOddsYourEquityLabel = 'Tu equity real (opcional)';
  static const String potOddsCalculateEv = 'Calcular EV';

  /// Comparación puramente informativa entre la equity real que ingresó
  /// el usuario y `requiredEquity` — nunca un veredicto CALL/FOLD
  /// (sección 9 del pedido de evolución de Tools: "la herramienta debe
  /// informar, no tomar decisiones").
  static String potOddsEquityComparison({
    required double yourEquityPct,
    required double requiredEquityPct,
  }) {
    final diff = (yourEquityPct - requiredEquityPct).abs().toStringAsFixed(1);
    if (yourEquityPct > requiredEquityPct) {
      return 'Tu equity (${yourEquityPct.toStringAsFixed(1)}%) supera la '
          'necesaria (${requiredEquityPct.toStringAsFixed(1)}%) por $diff '
          'puntos.';
    }
    if (yourEquityPct < requiredEquityPct) {
      return 'Tu equity (${yourEquityPct.toStringAsFixed(1)}%) es menor a la '
          'necesaria (${requiredEquityPct.toStringAsFixed(1)}%) por $diff '
          'puntos.';
    }
    return 'Tu equity (${yourEquityPct.toStringAsFixed(1)}%) coincide '
        'exactamente con la necesaria.';
  }

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
  static const String equityWinLabel = 'Ganás';
  static const String equityTieLabel = 'Empatás';
  static const String equityLoseLabel = 'Perdés';
  static const String equityEmptyStateHands =
      'Seleccioná las 2 cartas de tu mano y las 2 del rival para ver la '
      'equity.';
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

  // Range Explorer (V2 — Explorar/Construir/Practicar)
  static const String rangesModeExplore = 'Explorar';
  static const String rangesBrowseLabel = 'Ver rango';
  static const String rangesModeBuild = 'Construir';
  static const String rangesModePractice = 'Practicar';
  static const String rangesOfficialBadge = 'FLOPly';
  static const String rangesMyRangesTitle = 'Mis Rangos';
  static const String rangesMyRangesEmpty =
      'Todavía no guardaste ningún rango propio. Armá uno en '
      '"Construir" y guardalo para verlo acá.';
  static const String rangesOpenOfficial = 'Ver el oficial';
  static const String rangesViewingSaved = 'Rango propio';
  static const String rangesBasedOn = 'Editado a partir de';
  static const String rangesSizeToggleCombos = 'Combos';
  static const String rangesSizeTogglePercent = '%';
  static const String rangesRangeLabel = 'Rango';
  static const String rangesCombosLabel = 'Combos';
  static const String rangesFiltersTitle = 'Filtros';
  static const String rangesFiltersType = 'Tipo';
  static const String rangesFiltersAction = 'Acción';
  static const String rangesFiltersFrequency = 'Frecuencia';
  static const String rangesFiltersClear = 'Limpiar filtros';
  static const String rangesBoardLabel = 'Board (opcional)';
  static const String rangesCellCombosAvailableLabel = 'Disponibles';
  static const String rangesCellCombosBlockedLabel = 'Bloqueados por el board';
  static const String rangesAnalyzeBlockers = 'Analizar blockers';
  static const String rangesBuilderStartOfficial = 'Partir del oficial';
  static const String rangesBuilderStartScratch = 'Empezar de cero';
  static const String rangesBuilderNameLabel = 'Nombre del rango';
  static const String rangesBuilderNameHint = 'Ej: BTN Open — NL2';
  static const String rangesBuilderSave = 'Guardar';
  static const String rangesBuilderClear = 'Limpiar selección';
  static const String rangesBuilderFrequencyLabel = 'Frecuencia de la mano seleccionada';
  static const String rangesBuilderEmptyHint =
      'Tocá una mano de la grilla para asignarle una frecuencia.';
  static const String rangesBuilderSavedConfirmation = 'Rango guardado en Mis Rangos.';
  static const String rangesDuplicate = 'Duplicar';
  static const String rangesRename = 'Renombrar';
  static const String rangesDelete = 'Eliminar';
  static const String rangesCompareTitle = 'Comparar rangos';
  static const String rangesCompareWith = 'Comparar con';
  static const String rangesCompareAdded = 'Agregadas';
  static const String rangesCompareRemoved = 'Quitadas';
  static const String rangesCompareChanged = 'Frecuencia distinta';
  static const String rangesCompareEmpty = 'Elegí un segundo rango para comparar.';
  static const String rangesCompareLegendAdded = 'Solo en este rango';
  static const String rangesCompareLegendRemoved = 'Solo en el otro rango';
  static const String rangesCompareLegendChanged = 'Frecuencia distinta';
  static const String rangesPracticeTitle = 'Practicar este rango';
  static const String rangesPracticeQuestion = '¿Qué hacés con esta mano?';
  static const String rangesPracticeRaise = 'RAISE';
  static const String rangesPracticeFold = 'FOLD';
  static const String rangesPracticeCorrect = 'Correcto';
  static const String rangesPracticeIncorrect = 'Incorrecto';
  static const String rangesPracticeNext = 'Siguiente mano';
  static const String rangesPracticeScore = 'Aciertos';
  static const String rangesPracticeEmptyRange =
      'Este rango está vacío — no hay ninguna mano para practicar.';
  static String rangesPracticeExplanation(String notation, double frequencyPercent) {
    if (frequencyPercent <= 0) {
      return '$notation no está en este rango: se foldea siempre.';
    }
    if (frequencyPercent >= 100) {
      return '$notation está en este rango al 100%: se abre siempre.';
    }
    return '$notation está en este rango con una frecuencia mixta: se abre '
        '${frequencyPercent.toStringAsFixed(0)}% de las veces.';
  }

  static const String rangesImportExportTitle = 'Importar / Exportar';
  static const String rangesExportJson = 'Copiar como JSON';
  static const String rangesExportCsv = 'Copiar como CSV';
  static const String rangesImportLabel = 'Pegar JSON o CSV';
  static const String rangesImportHint = 'Pegá acá el contenido exportado';
  static const String rangesImportAction = 'Importar';
  static const String rangesImportError = 'No se pudo interpretar ese contenido.';
  static const String rangesCopiedConfirmation = 'Copiado al portapapeles.';
  static const String rangesCancel = 'Cancelar';

  // Blocker Explorer (V2)
  static const String toolsBlockerCalculatorSubtitle =
      'Combos del rango rival que bloquea tu mano.';
  static const String blockerHeroLabel = 'Tu mano';
  static const String blockerVillainRangeLabel = 'Rango del rival';
  static const String blockerVillainRangeHint = 'ej. QQ+,AKs,AKo';
  static const String blockerBoardLabel = 'Board (opcional)';
  static const String blockerInvalidRange = equityRangeInvalidInput;
  static const String blockerTotalLabel = 'Combos totales';
  static const String blockerAvailableLabel = 'Disponibles';
  static const String blockerBlockedLabel = 'Bloqueados';
  static const String blockerClassesHeader = 'Por clase de mano';
  static const String blockerViewEquity = 'Ver equity';
  static const String blockerViewRangeInBuilder = 'Ver este rango en Construir';
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
      'Jugá una mano completa de 6-max contra bots. Cuando termina, un '
      'mentor se sienta con vos a repasar qué pasó.';

  static const String navTools = 'Tools';
  static const String navCoach = 'Coach';

  // Auth — pantalla de acceso
  static const String authTagline = 'Aprendé póker jugando.';
  static const String authContinueGoogle = 'Continuar con Google';
  static const String authSignInWithEmail = 'Iniciar sesión con email';
  static const String authContinueApple = 'Continuar con Apple';
  static const String authContinueEmail = 'Continuar con email';
  static const String authContinueWithoutAccount = 'Continuar sin cuenta';
  static const String authOr = 'o';

  // Auth — campos email + contraseña
  static const String authEmailLabel = 'Email';
  static const String authPasswordLabel = 'Contraseña';
  static const String authPasswordHint = 'Tu contraseña';
  static const String authPasswordRequired = 'Ingresá tu contraseña.';
  static const String authSignInButton = 'INICIAR SESIÓN';
  static const String authNoAccount = '¿No tenés cuenta?';
  static const String authCreateAccountLink = 'Crear cuenta';

  // Auth — crear cuenta
  static const String authCreateAccountTitle = 'Crear cuenta';
  static const String authCreateAccountSubtitle =
      'Completá los datos para empezar.';
  static const String authNameLabel = 'Nombre';
  static const String authNameHint = 'Tu nombre';
  static const String authNameRequired = 'Ingresá tu nombre.';
  static const String authConfirmPasswordLabel = 'Repetir contraseña';
  static const String authPasswordTooShort =
      'La contraseña debe tener al menos 6 caracteres.';
  static const String authPasswordsDoNotMatch = 'Las contraseñas no coinciden.';
  static const String authPhoneLabel = 'Número de teléfono';
  static const String authPhoneHint = '+54 9 11 1234-5678';
  static const String authPhoneRequired =
      'Ingresá tu número de teléfono.';
  static const String authNextButton = 'SIGUIENTE';
  static const String authSmsSendFailed =
      'No pudimos enviar el SMS. Verificá el número e intentá de nuevo.';

  // Auth — verificación SMS
  static const String authSmsTitle = 'Verificar número';
  static String authSmsBody(String phone) =>
      'Ingresá el código de 6 dígitos que mandamos a $phone.';
  static const String authSmsCodeHint = '000000';
  static const String authSmsCodeInvalid = 'Ingresá los 6 dígitos del código.';
  static const String authSmsVerifyButton = 'VERIFICAR';
  static const String authSmsResend = 'Reenviar código';
  static String authSmsResendIn(int seconds) => 'Reenviar en ${seconds}s';
  static const String authSmsWrongNumber = 'Número incorrecto, volver';
  static const String authSmsVerifyFailed =
      'No pudimos crear la cuenta. Intentá nuevamente.';

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

  // Perfil (Grupo 1 — navegación/perfil/configuración)
  static const String profileTitle = 'PERFIL';
  static const String profileSettingsCta = 'Configuración';
  static const String profileChangePhoto = 'Cambiar foto';
  static const String profilePickFromGallery = 'Elegir de la galería';
  static const String profileTakePhoto = 'Sacar una foto';
  static const String profileConfirmPhoto = '¿Usar esta foto?';
  static const String profileUsePhoto = 'Usar esta foto';
  static const String profileCancel = 'Cancelar';
  static const String profileEditNameTitle = 'Tu nombre';
  static const String profileEditNameHint = 'Cómo te vamos a llamar';
  static const String profileEditNameSave = 'Guardar';
  static const String profileAvatarUpdateError =
      'No pudimos actualizar tu foto. Probá de nuevo.';
  static const String profileMemberSince = 'En FLOPly desde';
  static const String profileAccountType = 'TIPO DE CUENTA';
  static const String profileAccountFree = 'FREE';
  static const String profileAccountPremium = 'PREMIUM';
  static const String profileUpgradeCta = 'Pasate a Premium';
  static const String profileLanguageLabel = 'Idioma';

  // Premium / Paywall
  static const String premiumTitle = 'FLOPLY PREMIUM';
  static const String premiumSubtitle = 'El juego completo, sin límites.';
  static const String premiumBenefitCoach = 'Mesa con Coach ilimitada';
  static const String premiumBenefitTools = 'Herramientas sin restricciones';
  static const String premiumBenefitNoAds = 'Sin anuncios de recompensa';
  static const String premiumBenefitSupport = 'Apoyás el desarrollo del proyecto';
  static const String premiumNoOfferings =
      'No se pudieron cargar los planes de suscripción.';
  static const String premiumRetry = 'Reintentar';
  static const String premiumSubscribeCta = 'SUSCRIBIRME';
  static const String premiumPurchasing = 'Procesando…';
  static const String premiumRestorePurchases = 'Restaurar compra anterior';
  static const String premiumPurchaseError =
      'No se pudo completar la compra. Intentá de nuevo.';
  static const String premiumRestoreNotFound =
      'No encontramos ninguna suscripción activa para restaurar.';
  static const String premiumLockedTitle = 'Función Premium';
  static const String premiumLockedBody =
      'La Mesa con Coach es exclusiva para suscriptores Premium.';
  static const String premiumLockedCta = 'VER PLANES PREMIUM';

  // Configuración (Grupo 1)
  static const String settingsTitle = 'CONFIGURACIÓN';
  static const String settingsSectionAccount = 'Cuenta';
  static const String settingsSectionPrivacy = 'Privacidad';
  static const String settingsSectionInfo = 'Información';
  static const String settingsEditName = 'Nombre visible';
  static const String settingsChangePhoto = 'Foto de perfil';
  static const String settingsAccountManage = 'Métodos de acceso y cuenta';
  static const String settingsAccountManageBody =
      'Vincular Google/Apple/email, cerrar sesión, eliminar cuenta.';
  static const String settingsGuestBody =
      'Creá una cuenta para editar tu nombre, tu foto y guardar tu '
      'progreso en la nube.';
  static const String settingsPrivacyDataTitle = 'Tus datos';
  static const String settingsPrivacyDataBody =
      'Tu progreso y tu perfil se guardan en tu cuenta de FLOPly '
      '(Firebase). Tu foto de perfil se guarda solo en este dispositivo.';
  static const String settingsPrivacyDelete = 'Eliminar mi cuenta y mis datos';
  static const String settingsInfoVersion = 'Versión';
  static const String settingsInfoAbout = 'FLOPly';
  static const String settingsInfoAboutBody =
      'Academia de póker: 326 teorías, ejercicios interactivos y un '
      'Entrenamiento de práctica.';

  // Modo offline al arrancar (Grupo 8, sección 1)
  static const String offlineEntryTitle = 'No tenés conexión a Internet';
  static const String offlineEntryBody =
      'Podés seguir usando las Herramientas que ya funcionan sin conexión. '
      'Academia y el Entrenamiento necesitan Internet.';
  static const String offlineEntryCta = 'ENTRAR EN MODO OFFLINE';
  static const String offlineToolsBannerTitle = 'Modo offline';
  static const String offlineToolsBannerBody =
      'Solo Herramientas está disponible sin conexión.';

  // Mesa con Coach/Mentor (Grupo 8)
  static const String coachTableTitle = 'MESA CON COACH';
  static const String coachNewHand = 'NUEVA MANO';
  static const String coachExit = 'SALIR';
  static const String coachThinking = 'Los rivales están jugando…';

  // Mesa con Coach — análisis de fin de mano + herramientas de ayuda
  // (evolución: la mano se juega completa, sin correcciones a mitad de
  // camino — ver el doc-comment de HandTableController/CoachAnalyzer).
  static const String coachHandOverWon = '¡Ganaste la mano!';
  static const String coachHandOverLost = 'Mano terminada';
  static const String coachAnalysisAvailable = 'Análisis de mano disponible';
  static const String coachViewAnalysis = 'VER ANÁLISIS';
  static const String coachContinuePlaying = 'SEGUIR JUGANDO';
  static const String coachReviewTitle = 'Repasemos la mano';
  static const String coachClosingLabel = 'PARA QUEDARTE CON ESTO';
  static const String coachToolsButton = 'Herramientas de ayuda';
  static const String coachToolsTitle = 'HERRAMIENTAS DE AYUDA';
  static const String coachToolsSubtitle =
      'Elegí qué querés consultar sobre esta mano.';
  static const String coachToolRange = 'Mi mano y mi rango';
  static const String coachToolPotOdds = 'Pot Odds';
  static const String coachToolEquity = 'Equity';
  static const String coachToolEv = 'EV';
  static const String coachToolSpot = 'Información del spot';
  static const String coachToolCombos = 'Combos y bloqueadores';
  static const String coachToolsBack = 'Volver';

  // ------------------------------------------------------------------
  // Economía (FLOPly Coins / Training Quota / Rewarded Ads) — integración
  // con el producto real. Tono mentor, nunca técnico: el usuario nunca
  // debería sentir que está leyendo un mensaje de sistema.
  // ------------------------------------------------------------------

  static const String economyLoading = 'Cargando tu economía…';

  /// Chip compacto del Home — "6 Coins" / "90 min".
  static const String economyCoinsSuffix = 'Coins';
  static const String economyHomeCoinsLabel = 'FLOPlyCoins';
  static const String economyMinutesSuffix = 'min';
  static String economyHomeTrainingsLeft(int remaining) =>
      remaining == 1
          ? 'Te queda 1 entrenamiento gratis hoy'
          : 'Te quedan $remaining entrenamientos gratis hoy';
  static const String economyHomeTrainingsExhausted =
      'Usaste tus entrenamientos gratis de hoy';

  static const String economyProfileSectionTitle = 'Tu economía';
  static const String economyProfileCoinsLabel = 'Coins disponibles';
  static const String economyProfileMinutesLabel = 'Tiempo disponible';
  static String economyProfileNextRegeneration(String when) =>
      'Tu próximo Coin llega $when';
  static const String economyProfileFullCoins = 'Ya estás al máximo de Coins';
  static const String economyProfileTrainingLabel = 'Entrenamientos gratis hoy';
  static String economyProfileTrainingReset(String when) => 'Se renuevan $when';
  static const String economyProfilePremiumLabel = 'Premium';
  static const String economyProfilePremiumActive =
      'Sos Premium — Coins ilimitadas';
  static const String economyProfilePremiumInactive = 'Todavía no sos Premium';
  static String economyAdsRemainingInWindow(int remaining, int max) =>
      '$remaining de $max anuncios disponibles ahora';

  static const String economyWatchAdCta = 'VER ANUNCIO +1 COIN';
  static const String economyWaitRegenerationCta = 'ESPERAR REGENERACIÓN';
  static const String economyGoBack = 'VOLVER';

  static const String economyNoCoinsTitle = 'Te quedaste sin tiempo disponible';
  static const String economyNoCoinsBody =
      'No tenés Coins disponibles ahora mismo.';
  static String economyNextRegenerationInline(String when) =>
      'Tu próximo minuto disponible se recupera $when.';
  static const String economyNoNextRegenerationInline =
      'Ya estás al máximo de Coins.';

  static const String economyAdUnavailableFull =
      'Ya estás al máximo de Coins — no hace falta ver un anuncio.';
  static const String economyAdUnavailableLimit =
      'Ya viste el máximo de anuncios por ahora. Probá de nuevo más tarde.';
  static const String economyAdUnavailableNotReady =
      'No hay ningún anuncio listo todavía. Probá en un momento.';

  static const String economyWatchingAd = 'Cargando anuncio…';
  static const String economyAdRewardGranted = '¡Listo! Sumaste 1 Coin.';
  static const String economyAdRewardRejected =
      'El anuncio se vio pero la Coin no se pudo acreditar ahora mismo.';
  static const String economyAdDismissed =
      'Cerraste el anuncio antes de terminar — no se acredita ninguna Coin.';
  static const String economyAdNotAvailable =
      'No se pudo cargar el anuncio. Probá de nuevo en un rato.';

  static const String economyRanOutMidSessionTitle =
      'Se te acabó el tiempo disponible';
  static const String economyRanOutMidSessionBody =
      'Podés seguir viendo lo que ya tenías en pantalla, pero vas a necesitar '
      'Coins para seguir usando esto.';

  static const String economyTrainingQuotaExhaustedTitle =
      'Ya usaste tus entrenamientos gratis de hoy';
  static const String economyTrainingQuotaExhaustedBody =
      'Podés seguir practicando usando el tiempo de tus Coins.';
  static String economyTrainingResetHint(String when) =>
      'Tu cupo gratis se renueva $when.';
  static const String economyExtraTrainingCta = 'PRACTICAR CON COINS';
  static const String economyExtraTrainingConfirmTitle = '¿Practicar con Coins?';
  static const String economyExtraTrainingConfirmBody =
      'Esta práctica extra va a consumir tiempo de tus Coins mientras la '
      'estés usando — solo lo que realmente uses.';
  static const String economyExtraTrainingConfirmCta = 'EMPEZAR';

  // Códigos promocionales
  static const String promoSectionTitle = '¿Tenés un código promocional?';
  static const String promoFieldHint = 'Ingresá tu código';
  static const String promoRedeemButton = 'CANJEAR CÓDIGO';
  static const String promoRedeeming = 'Verificando…';
  static const String promoSuccessTitle = '¡Código aplicado!';
  static String promoSuccessBenefit(String label) => label;
  static const String promoErrorNotFound =
      'El código no es válido. Revisalo e intentá nuevamente.';
  static const String promoErrorInactive =
      'Este código no está disponible en este momento.';
  static const String promoErrorNotStarted =
      'Este código todavía no está disponible.';
  static const String promoErrorExpired =
      'Este código promocional venció.';
  static const String promoErrorExhausted =
      'Este código alcanzó su límite de usos.';
  static const String promoErrorAlreadyRedeemed =
      'Este código ya fue utilizado.';
  static const String promoErrorUnauthenticated =
      'Iniciá sesión para canjear un código promocional.';
  static const String promoErrorServer =
      'Ocurrió un error. Intentá nuevamente en un momento.';

  // Popups informativos de coins en el top bar
  static const String economyCoinInfoTitle = 'FLOPly Coins';
  static const String economyCoinInfoBody =
      'Cada FlopyCoin te da 15 minutos de uso de Tools. '
      'El tiempo solo corre mientras estás activo en la sesión — '
      'al salir, se pausa hasta que volvés.\n\n'
      'Tenés hasta 6 Coins (90 min) a la vez. '
      'Si conseguís una Coin nueva mientras otra ya está activa, '
      'el temporizador de esa Coin NO se reinicia: la nueva se suma al saldo. '
      'Al llegar a 0, la siguiente Coin disponible empieza sola.\n\n'
      'Las Coins se regeneran solas (1 por hora hasta el máximo) y podés '
      'sumar una extra viendo un anuncio (máximo 3 por ventana de 12 horas).\n\n'
      'Los usuarios Premium usan Tools y Coach sin límite de Coins.';

  /// Descripción en la hoja de recuperación de Coin (Tools y Home).
  static const String economyCoinRecoveryDescription =
      'Ver un anuncio suma 1 FlopyCoin a tu saldo. '
      'Si ya tenés una Coin activa, su temporizador NO se reinicia — '
      'la nueva Coin simplemente se acumula.';
  static const String economyTrainingInfoTitle = 'Entrenamientos del día';
  static const String economyTrainingInfoBody =
      'Cada día tenés 5 sesiones de Entrenamiento completamente '
      'gratuitas. Se renuevan a medianoche sin importar cuántas '
      'hayas usado.\n\n'
      'Si agotás las 5 del día, podés seguir practicando usando '
      'tus FLOPly Coins: cada Coin cubre 15 minutos de sesión '
      'extra — solo se descuenta el tiempo que realmente usás.';
  static const String economyCoinInfoClose = 'Entendido';

  // Hoja de "coin que se usa" antes de entrar a Entrenamiento o Tools
  static const String preEntryTrainingTitle = 'Antes de entrenar';
  static const String preEntryTrainingCoinsBody =
      'Esta sesión usará uno de tus 5 entrenamientos gratuitos del día. '
      'Si los agotás, podés seguir con tus Coins (1 Coin = 15 min).';
  static const String preEntryToolsTitle = 'Antes de entrar a Tools';
  static const String preEntryToolsCoinsBody =
      'Mientras usás Tools se consume tiempo de tus Coins activas. '
      'Cada Coin cubre 15 minutos — solo lo que realmente usás. '
      'Los usuarios Premium entran sin límite.';
  static const String preEntryDontShowAgain = 'No volver a mostrar';
  static const String preEntryCta = 'Entrar';

  // Diálogo de sesión de Coach
  static const String coachSessionTitle = 'Sesión en curso';
  static const String coachSessionBody =
      'Tenés una sesión de Coach activa. ¿Querés continuar donde '
      'quedaste o empezar desde cero?';
  static const String coachSessionContinue = 'Continuar sesión';
  static const String coachSessionNew = 'Nueva sesión';
}
