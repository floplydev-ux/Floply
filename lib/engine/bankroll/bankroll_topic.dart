import '../pedagogy/theory.dart';

/// Un tema del módulo de Bankroll: mismo formato de contenido que una
/// teoría de la Academia ([TheoryContent]) — así reutiliza el mismo
/// lenguaje visual (QUÉ ES / POR QUÉ IMPORTA / CÓMO FUNCIONA / ...) sin
/// ser una teoría del currículo. No tiene ID, prerrequisitos ni
/// `orden_global`: vive fuera de las 326 teorías, a propósito.
class BankrollTopic {
  const BankrollTopic({
    required this.titulo,
    required this.objetivo,
    required this.contenido,
  });

  final String titulo;
  final String objetivo;
  final TheoryContent contenido;
}

/// Contenido del módulo complementario de Bankroll — 7 fichas que cubren,
/// en lenguaje de principiante, los 12 puntos mínimos pedidos: qué es el
/// bankroll, separarlo de la plata personal, buy-in, cuántos buy-ins
/// llevar, riesgo de rachas, una mala sesión no es jugar mal, shot-taking,
/// bajar de límite, regla de stop, no jugar con plata prestada ni
/// destinada a otra cosa, y el bankroll como herramienta contra la
/// varianza (cierra conectando con TN12, ya visto en la Academia).
///
/// Deliberadamente corto y práctico: sin matemática de riesgo de ruina.
class BankrollTopics {
  BankrollTopics._();

  static const List<BankrollTopic> all = [_t1, _t2, _t3, _t4, _t5, _t6, _t7];

  static const _t1 = BankrollTopic(
    titulo: 'Qué es el bankroll',
    objetivo: 'Entender el bankroll como la plata separada, exclusiva '
        'para jugar al póker.',
    contenido: TheoryContent(
      queEs: 'Tu bankroll es la plata que separás específicamente para '
          'jugar al póker — y para nada más. No es "la plata que tenés", '
          'es una caja aparte.',
      porQueImporta: 'Mientras jugás con dinero que también necesitás '
          'para otra cosa, cada mano se juega con miedo: no podés decidir '
          'bien si una pérdida te complica pagar algo real. Separar el '
          'bankroll es lo que te permite jugar tus manos por sus méritos, '
          'no por necesidad.',
      comoFunciona: 'Definís un monto, lo apartás (una cuenta separada '
          'ayuda) y jugás solo con eso. Lo que ganás se suma al bankroll; '
          'lo que perdés, sale de ahí — nunca de otro lado.',
      cuandoLoUso: 'Antes de sentarte a jugar por primera vez con dinero '
          'real: definir el bankroll es el primer paso, no un detalle '
          'para después.',
      ejemplo: 'Tenés ahorros para el alquiler, gastos del mes y algo '
          'aparte para entretenimiento. Solo esa última parte — la que ya '
          'estaba pensada para gastar en algo — puede convertirse en '
          'bankroll.',
      errorComun: 'Jugar "con lo que hay en la cuenta" sin haber separado '
          'nunca cuánto es plata de póker y cuánto es plata de vivir.',
      ideaClave: 'Bankroll = plata separada, exclusiva para jugar. Nunca '
          'se mezcla con lo demás.',
    ),
  );

  static const _t2 = BankrollTopic(
    titulo: 'El buy-in y cuántos llevar',
    objetivo: 'Entender qué es un buy-in y cuántos conviene tener antes '
        'de jugar NL2.',
    contenido: TheoryContent(
      queEs: 'Un buy-in es la cantidad de fichas con la que te sentás a '
          'una mesa — en NL2, lo estándar son 100 BB (Nivel 3). "Tener '
          'varios buy-ins" significa poder pagar esa entrada varias veces '
          'seguidas sin quedarte sin bankroll.',
      porQueImporta: 'Un solo buy-in no alcanza: si perdés esa mesa, ya '
          'no tenés con qué seguir jugando ni aprendiendo. Los buy-ins de '
          'sobra son lo que te permite seguir en pie después de una mala '
          'sesión.',
      comoFunciona: 'Muchos jugadores de NL2 empiezan con un bankroll de '
          'entre 20 y 30 buy-ins completos antes de sentarse con dinero '
          'real — no es una ley matemática exacta, es un margen prudente '
          'para alguien que recién empieza.',
      cuandoLoUso: 'Antes de decidir con cuánto vas a jugar NL2: contá '
          'cuántos buy-ins completos representa tu bankroll total.',
      ejemplo: 'Si un buy-in de NL2 son 2 dólares (100 BB a 2 centavos la '
          'ciega grande), un bankroll de 20 a 30 buy-ins ronda los 40-60 '
          'dólares — no la plata que tengas "de más", sino la que ya '
          'decidiste separar (T1).',
      errorComun: 'Sentarse a jugar NL2 con un único buy-in "para probar" '
          'y sin margen si esa mesa sale mal.',
      ideaClave: 'Buy-in = tu entrada a una mesa. Bankroll sano = muchos '
          'buy-ins de sobra, no uno solo.',
    ),
  );

  static const _t3 = BankrollTopic(
    titulo: 'Rachas: perder no es jugar mal',
    objetivo: 'Aceptar el riesgo de perder varias cajas seguidas sin '
        'confundirlo con jugar mal.',
    contenido: TheoryContent(
      queEs: 'Una racha perdedora es perder varias sesiones (o varias '
          'cajas/buy-ins) seguidas. Puede pasar incluso jugando bien: ya '
          'lo viste en la Academia como varianza (Nivel 6).',
      porQueImporta: 'Si no lo esperás, una racha te hace dudar de todo '
          'lo que aprendiste justo cuando más necesitás sostenerlo. El '
          'bankroll separado (T1) existe, en gran parte, para poder '
          'atravesar una racha así sin quedarte sin plata para seguir.',
      comoFunciona: 'Con suficientes buy-ins de margen (T2), una racha '
          'perdedora achica el bankroll pero no lo termina. Sin ese '
          'margen, una racha normal puede dejarte sin nada para seguir '
          'jugando — no porque jugaste mal, sino porque no tenías colchón.',
      cuandoLoUso: 'Después de una mala racha: antes de asumir que estás '
          'jugando mal, revisá si tus decisiones fueron +EV (Nivel 6) — '
          'perder no es lo mismo que decidir mal.',
      cuandoNo: 'Esto no significa ignorar una racha para siempre: si '
          'revisás tus manos y sí encontrás errores de decisión '
          'repetidos, eso sí hay que corregirlo — la varianza no tapa un '
          'problema real de juego.',
      ejemplo: 'Perdés 5 sesiones seguidas jugando decisiones +EV en '
          'cada una: es una racha esperable, no una señal de que algo '
          'está mal.',
      errorComun: 'Cambiar toda tu estrategia después de una mala racha '
          'corta, en vez de revisar primero si las decisiones fueron '
          'buenas.',
      ideaClave: 'Perder una racha no significa jugar mal. El bankroll '
          'con margen existe para poder atravesarla.',
    ),
  );

  static const _t4 = BankrollTopic(
    titulo: 'Subir y bajar de límite',
    objetivo: 'Saber cuándo probar un límite más alto (shot) y cuándo '
        'conviene bajar.',
    contenido: TheoryContent(
      queEs: 'Un "shot" es probar un límite más alto que el tuyo '
          'habitual, con parte del bankroll. Bajar de límite es lo '
          'contrario: volver a uno más chico cuando el bankroll ya no '
          'aguanta el actual.',
      porQueImporta: 'Subir sin margen te expone a perder una porción '
          'grande del bankroll de una sola vez. Bajar a tiempo, en '
          'cambio, es lo que te permite seguir jugando y aprendiendo en '
          'vez de quedarte sin nada.',
      comoFunciona: 'Hacé un shot solo cuando tu bankroll ya tiene margen '
          'de sobra en el límite actual (T2) — nunca con todo el '
          'bankroll de una vez. Si el shot no sale bien, volvés sin '
          'drama al límite anterior. Bajá de límite cuando tu bankroll ya '
          'no cubre los buy-ins de margen que decidiste tener.',
      cuandoLoUso: 'Al evaluar, de vez en cuando, si tu bankroll actual '
          'te permite un shot, o si en cambio te está pidiendo bajar.',
      ejemplo: 'Con bankroll de sobra en NL2, probás algunas sesiones en '
          'NL5. Si te va mal y el bankroll baja, volvés a NL2 sin '
          'problema: seguís jugando y aprendiendo igual.',
      errorComun: 'Quedarte en un límite que ya no podés sostener "por '
          'orgullo", en vez de bajar y seguir jugando con margen.',
      ideaClave: 'Shot = probar más arriba con margen de sobra. Bajar de '
          'límite no es un fracaso: es cuidar tu capacidad de seguir '
          'jugando.',
    ),
  );

  static const _t5 = BankrollTopic(
    titulo: 'La regla de stop',
    objetivo: 'Definir de antemano cuándo parar una sesión.',
    contenido: TheoryContent(
      queEs: 'Una regla de stop es un límite que definís ANTES de jugar '
          '—de tiempo, de pérdida, o de cantidad de buy-ins— para cortar '
          'la sesión ahí, sin importar cómo te sentís en el momento.',
      porQueImporta: 'En el momento de estar jugando (sobre todo en una '
          'mala racha, T3) es muy difícil decidir con la cabeza fría. '
          'Definir el límite de antemano saca esa decisión del momento '
          'más comprometido.',
      comoFunciona: 'Antes de sentarte, elegís un límite concreto (por '
          'ejemplo: "si pierdo 3 buy-ins, corto la sesión"). Si lo tocás, '
          'parás — sin negociar con vos mismo en el momento.',
      cuandoLoUso: 'Siempre, antes de empezar cualquier sesión — no solo '
          'cuando "presentís" que puede ir mal.',
      ejemplo: 'Definiste: "si pierdo 3 buy-ins, corto por hoy". Llegás a '
          'esa pérdida a mitad de sesión: cerrás la mesa ahí, aunque '
          '"sientas que se puede dar vuelta".',
      errorComun: 'Definir una regla de stop y no respetarla justo "esta '
          'vez", que es exactamente cuando más hace falta.',
      ideaClave: 'La regla de stop se decide ANTES de jugar, con la '
          'cabeza fría — y se respeta después, sin excepciones.',
    ),
  );

  static const _t6 = BankrollTopic(
    titulo: 'Plata que nunca es bankroll',
    objetivo: 'Reconocer qué plata no debe convertirse nunca en '
        'bankroll.',
    contenido: TheoryContent(
      queEs: 'Hay dos tipos de plata que nunca deberían formar parte de '
          'tu bankroll: la plata prestada, y la plata ya destinada a '
          'gastos, emergencias o necesidades personales.',
      porQueImporta: 'Jugar con plata prestada suma una presión extra '
          'que no tiene nada que ver con el póker: ahora le debés a '
          'alguien, gane o pierda esa sesión. Jugar con plata destinada a '
          'otra cosa (alquiler, comida, una emergencia) convierte cada '
          'mano en un riesgo que no podés permitirte.',
      comoFunciona: 'Antes de definir tu bankroll (T1), primero separá lo '
          'que NUNCA puede tocarse: gastos fijos, ahorro de emergencia, '
          'deudas. El bankroll sale solo de lo que quedó después de eso '
          '— y siempre con plata propia, no prestada.',
      cuandoLoUso: 'Al definir tu bankroll por primera vez, y cada vez '
          'que pienses en recargarlo.',
      cuandoNo: 'Ni siquiera "por poco tiempo" o "para recuperar rápido" '
          '(ver T3): pedir plata prestada para jugar es exactamente lo '
          'que la separación del bankroll busca evitar.',
      ejemplo: 'Perdiste tu bankroll de la semana. La opción correcta es '
          'esperar a la próxima parte que ibas a destinar a entretenimiento '
          '— no pedir plata prestada para "recuperar ya".',
      errorComun: 'Pedir plata prestada o usar la destinada a otra cosa '
          '"solo por esta vez", justo en el peor momento para tomar esa '
          'decisión (después de una mala racha).',
      ideaClave: 'El bankroll sale de plata propia, ya separada para '
          'entretenimiento. Nunca prestada, nunca la de gastos fijos.',
    ),
  );

  static const _t7 = BankrollTopic(
    titulo: 'El bankroll y la varianza',
    objetivo: 'Entender el bankroll como la herramienta que te permite '
        'soportar la varianza del juego.',
    contenido: TheoryContent(
      queEs: 'Ya viste en la Academia (Nivel 6) que incluso jugando bien '
          'vas a perder manos y sesiones seguidas — eso es varianza. El '
          'bankroll es, ni más ni menos, la herramienta que te permite '
          'aguantar esa varianza sin quedarte afuera del juego.',
      porQueImporta: 'Podés saber jugar perfecto y aun así fundirte si tu '
          'bankroll no tiene margen para la varianza normal del juego. '
          'Un bankroll bien administrado no te hace ganar más rápido: te '
          'da tiempo para que tus buenas decisiones (Nivel 6, "el EV a '
          'largo plazo") terminen rindiendo.',
      comoFunciona: 'Juntá todo lo de este módulo: plata separada (T1), '
          'margen de buy-ins (T2), aceptar las rachas sin pánico (T3), '
          'moverte de límite con criterio (T4), una regla de stop (T5) y '
          'nunca tocar plata que no es tuya para jugar (T6). Todo eso, '
          'junto, es tu forma de "comprar tiempo" para que la varianza '
          'se empareje.',
      cuandoLoUso: 'Como marco general antes de sentarte a jugar NL2 con '
          'dinero real por primera vez — y como chequeo periódico '
          'después.',
      ejemplo: 'Dos jugadores toman las mismas buenas decisiones. Uno '
          'tiene bankroll con margen: atraviesa la racha mala y sigue '
          'jugando hasta que empareja. El otro se queda sin plata a '
          'mitad de la racha y nunca llega a emparejar, aunque jugó '
          'exactamente igual de bien.',
      errorComun: 'Pensar el bankroll como un obstáculo burocrático en '
          'vez de como la herramienta que te permite seguir en el juego '
          'el tiempo suficiente para que el buen juego rinda.',
      ideaClave: 'El bankroll no te hace ganar más rápido: protege tu '
          'capacidad de seguir jugando y aprendiendo hasta que la '
          'varianza se empareje.',
    ),
  );
}
