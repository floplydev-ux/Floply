/// Contenido de las teorías piloto de la Fase 3 (transformación pedagógica
/// "libro → mentor"): T051, T020, T073, T139, T108, T109, T175, T190, T224,
/// T308. (T001 migró de acá al piloto de 3 bloques de la Fase 3.1 — ver
/// `academy_closing_examples.dart` — y ya no tiene clase de mentor.)
///
/// Reutiliza exactamente los mismos datos técnicos (cartas, boards,
/// porcentajes, definiciones) que la teoría escrita oficial de cada una —
/// nunca inventa un hecho nuevo, nunca usa un concepto de un nivel
/// posterior. Donde una teoría necesita rozar una idea futura, se explica
/// la intuición sin nombrarla (mismo criterio que ya usa el resto del
/// currículo, ej. T037 con "3-bet" antes de N7).
library;

import 'mentor_lesson.dart';
import 'scripts/table_builder.dart';
import 'table_exercise.dart' show ExerciseChoice, ExerciseRating;
import 'table_lesson.dart';

/// Mesa mínima: solo el héroe (y opcionalmente board), sin posiciones —
/// para teorías donde lo único que importa es leer cartas, no la mesa
/// completa (T051, T073, T108, T109, T190). Mismo criterio que usaba
/// `visual_pilot_lessons.dart`: un rival con nombre/stack de utilería no
/// aporta nada cuando la lección es sobre cartas, no sobre posición.
TableSnapshot _cardStage({
  List<String> hero = const [],
  List<String> board = const [],
}) {
  return TableSnapshot(
    seats: [
      SeatState(slot: 0, label: '', isHero: true, cards: hero),
      const SeatState.empty(1),
      const SeatState.empty(2),
      const SeatState.empty(3),
      const SeatState.empty(4),
      const SeatState.empty(5),
    ],
    board: board,
    buttonSlot: 0,
  );
}

class MentorPilotLessons {
  MentorPilotLessons._();

  // ==================================================================
  // T051 — Pareja (N2.1)
  // Clase con error típico: no todas las parejas valen lo mismo.
  // ==================================================================
  static MentorLesson pareja() {
    final beats = <MentorBeat>[];
    const hero = ['Qh', 'Jc'];
    const flop = ['Qs', '8d', '3h'];

    beats.say(
      'Tenés Q♥J♣. Dos cartas sueltas — nada especial todavía.',
      role: MentorSayRole.intro,
      table: _cardStage(hero: hero),
      anchor: TableAnchor.heroCards,
    );

    beats.say(
      'Sale el flop: Q♠8♦3♥.',
      role: MentorSayRole.observe,
      table: _cardStage(hero: hero, board: flop),
      anchor: TableAnchor.board,
      cardGlow: const {CardRef.board(0)},
    );

    beats.say(
      'Una de tus cartas repite el valor de una carta de la mesa: tenés '
      'pareja de damas, con J, 8 y 3 de acompañamiento.',
      role: MentorSayRole.explain,
      table: _cardStage(hero: hero, board: flop),
      anchor: TableAnchor.heroCards,
      highlight: const [TableAnchor.heroCards, TableAnchor.board],
      cardGlow: const {CardRef.hero(0), CardRef.board(0)},
    );

    beats.say(
      'Ahora, la trampa: no todas las parejas valen lo mismo. Una pareja '
      'de ases y una de treses son las dos "una pareja" — pero una gana '
      'casi siempre, y la otra casi nunca.',
      role: MentorSayRole.error,
    );

    beats.ask(
      'Entre estas dos parejas, ¿cuál le gana a la otra en un showdown?',
      options: const [
        ExerciseChoice(
          label: 'Pareja de reyes',
          rating: ExerciseRating.best,
          feedback: 'Correcto: entre dos parejas gana la de valor más '
              'alto — reyes le gana a cuatros, sin importar nada más.',
        ),
        ExerciseChoice(
          label: 'Pareja de cuatros',
          rating: ExerciseRating.poor,
          feedback: 'No: entre dos parejas manda el valor. Los reyes son '
              'más altos que los cuatros, así que ganan.',
        ),
      ],
      wrapUp: 'Pareja = dos cartas iguales. Entre dos parejas, gana la '
          'más alta — así de simple.',
    );

    return MentorLesson('T051', beats);
  }

  // ==================================================================
  // T020 — Estar en posición (N3.3)
  // Clase con descubrimiento: la mesa demuestra el concepto antes de
  // nombrarlo. Corresponde casi textual al ejemplo del prompt maestro.
  // ==================================================================
  static MentorLesson estarEnPosicion() {
    final beats = <MentorBeat>[];

    final foldedTable = TableBuilder.seats(
      labels: TableBuilder.btnHero,
      folded: const {1, 2, 3}, // CO, HJ, UTG ya se retiraron
      toAct: 0,
    );
    beats.say(
      'Antes de hablar de rangos, quiero que mires algo simple de la '
      'mesa. Estamos en el botón (BTN). UTG, HJ y CO ya actuaron — los '
      'tres se retiraron.',
      role: MentorSayRole.intro,
      table: TableSnapshot(seats: foldedTable, potBb: 1.5, buttonSlot: 0),
      anchor: TableAnchor.heroCards,
      highlight: const [
        TableAnchor.seat(3),
        TableAnchor.seat(2),
        TableAnchor.seat(1),
      ],
    );

    beats.ask(
      '¿Qué sabemos nosotros, ahora, que UTG no sabía cuando le tocó '
      'decidir?',
      options: const [
        ExerciseChoice(
          label: 'Vimos actuar a HJ y a CO antes que a nosotros',
          rating: ExerciseRating.best,
          feedback: 'Exacto. Vimos actuar a los dos — y a UTG también. '
              'Esa diferencia de información no es un detalle menor.',
        ),
        ExerciseChoice(
          label: 'Nada, es la misma información para todos',
          rating: ExerciseRating.poor,
          feedback: 'No es así: ya vimos tres decisiones completas antes '
              'de que nos toque. UTG, en cambio, decidió sin ver a '
              'nadie.',
        ),
      ],
      wrapUp: 'Esa diferencia de información es, ni más ni menos, la '
          'posición.',
    );

    beats.say(
      "Eso es estar 'en posición': actuar después que un rival, viendo "
      'lo que hizo antes de decidir vos. En 6-max, el botón está en '
      'posición sobre todos los demás.',
      role: MentorSayRole.explain,
    );

    final flopTable = TableBuilder.seats(
      labels: TableBuilder.btnHero,
      folded: const {1, 2, 3, 5},
      actions: const {4: 'CHECK'},
      toAct: 0,
    );
    beats.say(
      'Un ejemplo concreto: sos el botón. En el flop, la BB pasa. Ya '
      'sabés que probablemente no tiene una mano fuerte: podés apostar '
      'para llevártelo, o pasar y ver el turn gratis. Ella nunca tiene '
      'esa información sobre vos.',
      role: MentorSayRole.example,
      table: TableSnapshot(
        seats: flopTable,
        board: const ['Js', '7d', '2c'],
        potBb: 6.0,
        buttonSlot: 0,
      ),
      anchor: const TableAnchor.seat(4),
    );

    beats.say(
      'Esto que acabamos de ver — jugar con más información cuando '
      'actuás después — es la razón por la que, en unas clases más, vas '
      'a empezar a abrir más manos desde el botón que desde UTG.',
      role: MentorSayRole.bridge,
    );

    beats.say(
      'En posición = actuás último = ves antes de decidir. Es una '
      'ventaja enorme.',
      role: MentorSayRole.keyIdea,
    );

    return MentorLesson('T020', beats);
  }

  // ==================================================================
  // T073 — Mano dominada (N4.2)
  // Clase con comparación: misma carta alta, distinto kicker.
  // ==================================================================
  static MentorLesson manoDominada() {
    final beats = <MentorBeat>[];
    const hero = ['As', '5d'];
    const flop = ['Ac', '9d', '6s'];

    beats.say(
      'Quiero mostrarte una de las formas más caras de perder fichas en '
      'el póker — y no tiene nada que ver con mala suerte.',
      role: MentorSayRole.intro,
    );

    beats.say(
      'Tenés A♠5♦. El board trae un As: A♣9♦6♠. Emparejaste — pareja de '
      'ases.',
      role: MentorSayRole.observe,
      table: _cardStage(hero: hero, board: flop),
      anchor: TableAnchor.board,
      cardGlow: const {CardRef.board(0)},
    );

    beats.say(
      'Ahora supongamos que el rival tiene A♥K♣. Los dos tienen pareja '
      'de ases... con una diferencia enorme: tu segunda carta es un 5, '
      'la suya es un Rey. Cuando dos manos emparejan la misma carta, '
      'decide la otra — el kicker.',
      role: MentorSayRole.explain,
    );

    beats.say(
      "Esto se llama estar 'dominado': compartís la carta más alta con "
      'el rival, pero la suya acompaña mejor. Vas a emparejar la misma '
      'carta seguido... y vas a perder casi siempre.',
      role: MentorSayRole.error,
    );

    beats.ask(
      'Con A♠5♦ contra A♥K♣, después de que sale el As en el board, '
      '¿quién gana normalmente?',
      options: const [
        ExerciseChoice(
          label: 'El rival, casi siempre — mejor kicker',
          rating: ExerciseRating.best,
          feedback: 'Correcto: los dos tienen par de ases, pero su Rey '
              'le gana a tu 5. Estás dominado: casi no hay forma de '
              'ganarle salvo que tu kicker mejore de casualidad.',
        ),
        ExerciseChoice(
          label: 'Nosotros, porque emparejamos primero',
          rating: ExerciseRating.poor,
          feedback: "Emparejar no alcanza: cuando las dos manos son 'par "
              "de ases', decide el kicker — y el Rey del rival es mucho "
              'mejor que tu 5.',
        ),
      ],
      wrapUp: 'Mano dominada = misma carta alta, peor kicker. Por eso '
          "jugar cualquier As 'porque es un As' es un error caro.",
    );

    beats.say(
      'Por eso, antes de jugar un As acompañado por una carta baja, '
      'conviene preguntarse: ¿y si el rival tiene la misma carta alta, '
      'pero mejor acompañada?',
      role: MentorSayRole.bridge,
    );

    return MentorLesson('T073', beats);
  }

  // ==================================================================
  // T139 — Qué es el RFI (N5.3)
  // Clase con decisión: le pone nombre preciso a algo ya usado.
  // ==================================================================
  static MentorLesson rfi() {
    final beats = <MentorBeat>[];

    beats.say(
      "Hasta acá veníamos hablando de 'tu rango de apertura' en general. "
      'Ahora le vamos a poner nombre preciso a la situación exacta en '
      'la que lo usás.',
      role: MentorSayRole.intro,
    );

    final table = TableBuilder.seats(
      labels: TableBuilder.btnHero,
      folded: const {1, 2, 3},
      toAct: 0,
    );
    beats.say(
      'Mirá esta mesa: UTG, HJ y CO se retiraron. Te toca a vos en el '
      'botón, y nadie más entró todavía.',
      role: MentorSayRole.observe,
      table: TableSnapshot(seats: table, potBb: 1.5, buttonSlot: 0),
      anchor: TableAnchor.heroCards,
    );

    beats.say(
      "Cuando la acción te llega así —'limpia', nadie subió ni entró "
      'antes— y vos decidís subir, eso tiene un nombre: RFI, raise first '
      'in. Subir siendo el primero en poner dinero de más en el bote.',
      role: MentorSayRole.explain,
    );

    beats.ask(
      'Y si en cambio alguien ya hubiera subido antes de que te toque, '
      '¿tu subida seguiría siendo un RFI?',
      options: const [
        ExerciseChoice(
          label: 'No — RFI es específicamente ser el primero en subir',
          rating: ExerciseRating.best,
          feedback: 'Exacto. Si alguien ya subió, tu jugada es otra cosa '
              '(la vas a ver más adelante) — no un RFI.',
        ),
        ExerciseChoice(
          label: 'Sí, cualquier subida es un RFI',
          rating: ExerciseRating.poor,
          feedback: "No: la palabra importa. RFI es puntualmente 'ser el "
              "primero en subir'. Si ya había alguien antes, es una "
              'situación distinta.',
        ),
      ],
      wrapUp: 'RFI = subir siendo el primero en entrar a la mano con una '
          'subida.',
    );

    beats.say(
      "Tu rango de apertura, entonces, es tu 'rango de RFI': con qué "
      'manos hacés esto, según la posición.',
      role: MentorSayRole.bridge,
    );

    return MentorLesson('T139', beats);
  }

  // ==================================================================
  // T108 — La regla del 2 (N6.3)
  // Clase por capas: situación → atajo numérico → practicar el atajo.
  // ==================================================================
  static MentorLesson reglaDel2() {
    final beats = <MentorBeat>[];
    const hero = ['As', '5s'];
    const board = ['Ks', '9s', '2c', '7d'];

    beats.say(
      'Estás en el turn. Tenés un proyecto de color: contando tus dos '
      'cartas y las dos picas del board, te quedan 9 outs para '
      'completarlo en el río.',
      role: MentorSayRole.intro,
      table: _cardStage(hero: hero, board: board),
      anchor: TableAnchor.heroCards,
      highlight: const [TableAnchor.heroCards, TableAnchor.board],
    );

    beats.say(
      'Para no calcular la probabilidad exacta cada vez, hay un atajo: '
      'cuando te queda UNA sola carta por salir —como ahora, esperando '
      'el río— multiplicás tus outs por 2.',
      role: MentorSayRole.explain,
    );

    beats.say(
      '9 outs × 2 = 18%. Esa es, aproximadamente, tu chance de completar '
      'el color en el río.',
      role: MentorSayRole.example,
      table: _cardStage(hero: hero, board: board),
      anchor: TableAnchor.board,
    );

    beats.ask(
      'Con 4 outs (un gutshot) en el turn, ¿qué porcentaje aproximado de '
      'equity te da la regla del 2?',
      options: const [
        ExerciseChoice(
          label: '8%',
          rating: ExerciseRating.best,
          feedback: 'Correcto: 4 outs × 2 = 8%. Poca equity — un '
              'gutshot en el turn casi no alcanza para pagar apuestas '
              'grandes.',
        ),
        ExerciseChoice(
          label: '16%',
          rating: ExerciseRating.poor,
          feedback: 'Ese número es la regla del 4, para cuando quedan '
              'DOS cartas por venir. Acá, en el turn, ya solo queda una '
              '— corresponde la regla del 2: 4 × 2 = 8%.',
        ),
      ],
      wrapUp: 'Regla del 2: outs × 2 ≈ % de equity con una sola carta '
          'por venir.',
    );

    beats.say(
      'Esto sirve en el turn, con una sola carta por venir. ¿Y en el '
      'flop, con dos cartas todavía por salir? Ahí la cuenta cambia un '
      'poco — lo vemos ahora.',
      role: MentorSayRole.bridge,
    );

    return MentorLesson('T108', beats);
  }

  // ==================================================================
  // T109 — La regla del 4 (N6.3)
  // Puente directo desde T108: misma mano, un paso antes.
  // ==================================================================
  static MentorLesson reglaDel4() {
    final beats = <MentorBeat>[];
    const hero = ['As', '5s'];
    const flop = ['Ks', '9s', '2c'];

    beats.say(
      'Recién vimos la regla del 2, para cuando te queda una sola carta '
      'por venir. Ahora retrocedé una calle: estás en el flop, con DOS '
      'cartas por salir todavía — turn y río.',
      role: MentorSayRole.intro,
    );

    beats.say(
      'Misma mano, un paso antes: flop K♠9♠2♣, con tu proyecto de color '
      'de 9 outs.',
      role: MentorSayRole.observe,
      table: _cardStage(hero: hero, board: flop),
      anchor: TableAnchor.board,
    );

    beats.say(
      'Con dos cartas por venir en vez de una, tenés el doble de '
      'chances de conectar. Por eso, en el flop, multiplicás tus outs '
      'por 4 en vez de por 2.',
      role: MentorSayRole.explain,
    );

    beats.say(
      '9 outs × 4 = 36%. Esa es tu equity aproximada para llegar con el '
      'color hecho al río, contando turn y río juntos.',
      role: MentorSayRole.example,
    );

    beats.say(
      'Ojo con un error típico: si no completás en el turn, ya NO te '
      'quedan dos cartas — te queda una sola. Ahí hay que volver a la '
      'regla del 2 con los outs que te sigan quedando, no seguir '
      'usando el 36% viejo.',
      role: MentorSayRole.error,
    );

    beats.ask(
      'Tenés un proyecto de escalera abierta (8 outs) en el flop. Según '
      'la regla del 4, ¿cuál es tu equity aproximada?',
      options: const [
        ExerciseChoice(
          label: '32%',
          rating: ExerciseRating.best,
          feedback: 'Correcto: 8 outs × 4 = 32%. Un proyecto abierto en '
              'el flop tiene bastante equity.',
        ),
        ExerciseChoice(
          label: '16%',
          rating: ExerciseRating.poor,
          feedback: 'Eso sería la regla del 2 (una sola carta por '
              'venir). En el flop, con dos cartas por venir, se '
              'multiplica por 4: 8 × 4 = 32%.',
        ),
      ],
      wrapUp: 'Regla del 4: outs × 4 ≈ % de equity con dos cartas por '
          'venir (flop hasta el río).',
    );

    return MentorLesson('T109', beats);
  }

  // ==================================================================
  // T175 — Qué es la c-bet (N8.1)
  // Clase puente: conecta con iniciativa (ya enseñada) antes del nombre.
  // ==================================================================
  static MentorLesson cbet() {
    final beats = <MentorBeat>[];

    final table = TableBuilder.seats(
      labels: TableBuilder.btnHero,
      heroSlot: 1, // CO
      folded: const {0, 2, 3, 5}, // BTN, HJ, UTG, SB — solo queda la BB
      toAct: 1,
    );
    final snapshot = TableSnapshot(
      seats: table,
      board: const ['Kd', '7c', '2h'],
      potBb: 6.0,
      buttonSlot: 0,
    );

    beats.say(
      'Repasemos algo que ya sabés: hace un par de clases vimos la '
      'iniciativa. Abriste desde el CO, la BB pagó, y llega el flop.',
      role: MentorSayRole.intro,
      table: snapshot,
      anchor: TableAnchor.heroCards,
    );

    beats.ask(
      '¿Quién tiene la iniciativa en esta mano?',
      options: const [
        ExerciseChoice(
          label: 'Nosotros — fuimos los últimos en subir',
          rating: ExerciseRating.best,
          feedback: 'Exacto, como ya vimos: tener la iniciativa es haber '
              'sido el último en apostar o subir. Abriste vos, nadie '
              'volvió a subir — la iniciativa es tuya.',
        ),
        ExerciseChoice(
          label: 'La BB, porque paga primero en el flop',
          rating: ExerciseRating.poor,
          feedback: 'Pagar no es lo mismo que tener la iniciativa. La '
              'iniciativa la tiene quien hizo la última subida — eso '
              'fuiste vos, al abrir.',
        ),
      ],
    );

    beats.say(
      'Apostar el flop teniendo la iniciativa tiene nombre propio: '
      "continuation bet, o c-bet. 'Continuás' la agresión que ya venías "
      'mostrando.',
      role: MentorSayRole.explain,
      table: snapshot,
      anchor: TableAnchor.heroCards,
    );

    beats.say(
      'Es la decisión postflop más frecuente de todas: cada vez que '
      'abrís y te pagan, te vas a enfrentar a esto. En las próximas '
      'clases vamos a ver cuándo conviene, y con qué tipo de mano.',
      role: MentorSayRole.bridge,
    );

    beats.say(
      'C-bet = apostar el flop siendo el jugador con la iniciativa.',
      role: MentorSayRole.keyIdea,
    );

    return MentorLesson('T175', beats);
  }

  // ==================================================================
  // T190 — Una scare card (N9.1)
  // Clase visual: descubrimiento apoyado casi enteramente en la mesa.
  // ==================================================================
  static MentorLesson scareCard() {
    final beats = <MentorBeat>[];
    const hero = ['Ac', 'Ad'];
    const flop = ['Ks', '9s', '4s'];
    const withTurn = ['Ks', '9s', '4s', '2s'];

    beats.say(
      'Tenés A♣A♦: par de ases, todavía fuerte. Pero mirá el flop: '
      'K♠9♠4♠ — las tres cartas son picas.',
      role: MentorSayRole.intro,
      table: _cardStage(hero: hero, board: flop),
      anchor: TableAnchor.board,
      highlight: const [TableAnchor.board],
    );

    beats.ask(
      'Con tres picas ya en la mesa, ¿alguien puede tener color hecho '
      'ahora mismo?',
      options: const [
        ExerciseChoice(
          label: 'Sí, con dos picas en la mano',
          rating: ExerciseRating.best,
          feedback: 'Correcto — eso ya lo sabés: con tres cartas del '
              'mismo palo en el board, cualquiera con dos cartas de ese '
              'palo en la mano ya tiene color.',
        ),
        ExerciseChoice(
          label: 'No, hacen falta las cinco cartas en la mesa',
          rating: ExerciseRating.poor,
          feedback: 'No: no hace falta que las cinco estén en el board. '
              'Con tres en la mesa y dos en la mano ya alcanza para '
              'tener color hecho.',
        ),
      ],
    );

    beats.say(
      'Sale el turn: 2♠. Ahora hay CUATRO picas en la mesa.',
      role: MentorSayRole.observe,
      table: _cardStage(hero: hero, board: withTurn),
      anchor: TableAnchor.board,
      cardGlow: const {CardRef.board(3)},
    );

    beats.say(
      'Con cuatro picas a la vista, ya no hace falta tener DOS picas en '
      'la mano — alcanza con tener UNA sola. Eso multiplica muchísimo '
      'cuántas manos del rival ya tienen color. Una carta así, que '
      'completa un proyecto visible en el board, se llama scare card: '
      "'carta que asusta'.",
      role: MentorSayRole.explain,
      table: _cardStage(hero: hero, board: withTurn),
      anchor: TableAnchor.board,
      highlight: const [TableAnchor.board],
    );

    beats.say(
      'Ojo: tu par de ases no cambió en nada. La scare card no te '
      'empeoró a vos — cambia cómo tenés que leer la mano del rival, '
      'exista o no ese color en concreto.',
      role: MentorSayRole.error,
    );

    beats.say(
      'Scare card = completa un proyecto visible en el board. Cambia '
      'cómo se juega la mano, exista o no esa mano en concreto.',
      role: MentorSayRole.keyIdea,
    );

    return MentorLesson('T190', beats);
  }

  // ==================================================================
  // T224 — Ventaja de rango (N11.1)
  // Clase de comprobación (EXPLICAR): sin decisión forzada artificial.
  // ==================================================================
  static MentorLesson ventajaDeRango() {
    final beats = <MentorBeat>[];

    beats.say(
      "Ya sabés por qué funciona la c-bet: dijimos que 'tu rango, en "
      "promedio, suele estar mejor parado' que el del rival. Ahora le "
      'vamos a poner nombre preciso a esa idea.',
      role: MentorSayRole.intro,
    );

    final table = TableBuilder.seats(
      labels: TableBuilder.utgHero,
      folded: const {2, 3, 4, 5}, // SB, BTN, CO, HJ — solo queda la BB
      toAct: 0,
    );
    final snapshot = TableSnapshot(
      seats: table,
      board: const ['Ks', 'Qh', '7c'],
      potBb: 6.0,
      buttonSlot: 3,
    );

    beats.say(
      'Abriste desde UTG —rango angosto y fuerte— y te pagó la BB — '
      'rango amplio y más flojo. Mirá el board: K-Q-7.',
      role: MentorSayRole.observe,
      table: snapshot,
      anchor: TableAnchor.board,
    );

    beats.say(
      'Ventaja de rango es que TODO tu conjunto de manos, en promedio, '
      'le gana más seguido al conjunto del rival en ESE board puntual '
      '— no se trata de tu mano puntual, sino del conjunto completo.',
      role: MentorSayRole.explain,
    );

    beats.ask(
      'En este board con cartas altas (K-Q-7), ¿de qué lado está la '
      'ventaja de rango?',
      options: const [
        ExerciseChoice(
          label: 'La nuestra — nuestro rango de UTG tiene más cartas altas',
          rating: ExerciseRating.best,
          feedback: 'Correcto: tu rango de apertura de UTG incluye '
              'muchas más manos con K, Q y A que el rango de defensa de '
              'la BB. En un board así, tu conjunto completo está mejor '
              'parado.',
        ),
        ExerciseChoice(
          label: 'La de la BB — tiene más manos en total',
          rating: ExerciseRating.poor,
          feedback: "Tener más manos (un rango más amplio) no es lo "
              'mismo que tener ventaja de rango. Lo que importa acá es '
              'qué tan seguido, en promedio, cada conjunto le gana al '
              'otro en ESTE board — y el de UTG, con más cartas altas, '
              'gana más seguido.',
        ),
      ],
      wrapUp: 'Ventaja de rango = tu rango completo, en promedio, gana '
          'más seguido que el del rival en ese board.',
    );

    beats.say(
      "No la confundas con 'tengo la mejor mano': es una propiedad del "
      'conjunto, no de tu mano puntual — y hay un concepto hermano, más '
      'específico, que vas a ver en la próxima clase.',
      role: MentorSayRole.bridge,
    );

    return MentorLesson('T224', beats);
  }

  // ==================================================================
  // T308 — La decisión integrada (N13.5, capstone)
  // Clase de consolidación: cierra las 326 teorías.
  // ==================================================================
  static MentorLesson decisionIntegrada() {
    final beats = <MentorBeat>[];

    beats.say(
      'Llegamos a la última teoría de la Academia. No te voy a enseñar '
      'nada nuevo — vamos a juntar, en una sola decisión, cuatro '
      'herramientas que ya tenés.',
      role: MentorSayRole.intro,
    );

    final table = TableBuilder.seats(
      labels: TableBuilder.btnHero,
      folded: const {1, 2, 3, 5},
      actions: const {4: 'APUESTA'},
      bets: const {4: 4.0},
      toAct: 0,
    );
    final snapshot = TableSnapshot(
      seats: table,
      board: const ['Kh', '9d', '4c', '7s', '2h'],
      potBb: 8.0,
      buttonSlot: 0,
    );

    beats.say(
      'Mirá esta mano: pot odds de 2 a 1 (necesitás 33% de equity), tu '
      'equity real es 36%, la línea del rival no termina de cerrar con '
      'una mano de valor, y jugás en posición.',
      role: MentorSayRole.observe,
      table: snapshot,
      anchor: TableAnchor.pot,
    );

    beats.say(
      'Cuatro pilares, cuatro preguntas: ¿qué piden las pot odds? '
      '¿cuánta equity tenés de verdad? ¿qué dice el rango del rival, con '
      'toda su línea? ¿y la posición, para desempatar si hace falta?',
      role: MentorSayRole.explain,
    );

    beats.ask(
      'Con los cuatro pilares apuntando en la misma dirección (equity '
      'por encima de lo necesario, línea que no cierra con valor, jugás '
      'en posición), ¿cuál es la decisión?',
      options: const [
        ExerciseChoice(
          label: 'Pagar — los cuatro pilares apoyan seguir',
          rating: ExerciseRating.best,
          feedback: 'Exacto. Ningún pilar solo alcanza, pero cuando los '
              'cuatro apuntan para el mismo lado, la decisión queda '
              'mucho más sólida que apoyada en uno solo.',
        ),
        ExerciseChoice(
          label: 'Foldear, por las dudas',
          rating: ExerciseRating.poor,
          feedback: "Acá 'por las dudas' no tiene sustento: tu equity ya "
              'supera lo que piden las pot odds, y el resto de la '
              'información acompaña seguir.',
        ),
      ],
      wrapUp: 'La decisión integrada = pot odds + equity + rango + '
          'posición, juntos — no uno solo.',
    );

    beats.say(
      'Ese es el juego completo que enseñó la Academia, de T001 a T308: '
      'no memorizar reglas sueltas, sino juntar todas las herramientas '
      'en cada decisión.',
      role: MentorSayRole.keyIdea,
    );

    beats.say(
      'De acá en más, el Campo de Entrenamiento es donde vas a practicar '
      'aplicando todo esto en situaciones nuevas.',
      role: MentorSayRole.bridge,
    );

    return MentorLesson('T308', beats);
  }
}
