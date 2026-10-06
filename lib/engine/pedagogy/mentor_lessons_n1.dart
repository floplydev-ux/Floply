/// Clases de mentor — Nivel 1 "Cómo funciona una mano" (Fase 4).
///
/// Las 25 teorías del nivel (T001-T005 de 1.1, T008-T010 de 1.2, T033-T042
/// de 1.3 y T043-T049 de 1.4, estas últimas antes acá) migraron al piloto
/// de 3 bloques y ya no tienen clase de mentor — ver
/// `academy_mentor_lessons.dart` y `academy_closing_examples.dart`. Esta
/// clase queda sin uso en tiempo de ejecución (no se borra, mismo criterio
/// de "re-anclar, no borrar" que el resto del contenido histórico).
library;

import 'mentor_lesson.dart';
import 'table_exercise.dart' show ExerciseChoice, ExerciseRating;
import 'table_lesson.dart';

TableSnapshot _stage({List<String> hero = const [], List<String> board = const []}) {
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

class MentorLessonsN1 {
  MentorLessonsN1._();

  // ==================================================================
  // 1.4 — Las cuatro calles
  // ==================================================================

  static MentorLesson elPreflop() {
    final beats = <MentorBeat>[];
    beats.say(
      'Ya sabés las acciones. Ahora armemos la mano completa, calle por '
      'calle — empezando por la primera.',
      role: MentorSayRole.intro,
    );
    beats.say(
      'El preflop es la primera ronda: ya hay fichas en el bote (las '
      'ciegas), y cada jugador decide con solo sus 2 cartas privadas — '
      'todavía no salió nada en el centro.',
      role: MentorSayRole.explain,
    );
    beats.say(
      'Es la decisión más frecuente de todo el póker: la tomás en cada '
      'mano, sin excepción. Elegir bien qué manos jugar y cuáles tirar '
      'acá es lo que más separa a un jugador ganador de uno perdedor.',
      role: MentorSayRole.observe,
    );
    beats.say(
      'La mayoría de las manos que recibís, la mayoría de las veces, se '
      'van a foldear — y eso está perfectamente bien. Jugar de más '
      'preflop es uno de los errores más caros y más comunes que existen.',
      role: MentorSayRole.error,
    );
    beats.say(
      'Preflop = primera ronda, solo tus 2 cartas. Elegí bien qué jugar: '
      'casi siempre, foldear.',
      role: MentorSayRole.keyIdea,
    );
    return MentorLesson('T043', beats);
  }

  static MentorLesson elFlop() {
    final beats = <MentorBeat>[];
    const hero = ['Ah', 'Kh'];
    const board = ['Ks', '9h', '4h'];
    beats.say(
      'Se cerró el preflop. Ahora aparecen de golpe las primeras 3 cartas '
      'comunitarias — mirá.',
      role: MentorSayRole.intro,
      table: _stage(hero: hero, board: board),
      anchor: TableAnchor.board,
    );
    beats.say(
      'A eso se lo llama el flop. Pasaste de tener solo 2 cartas a tener '
      '5 disponibles — es acá donde de verdad se empieza a decidir la '
      'mano.',
      role: MentorSayRole.explain,
    );
    beats.say(
      'Con A♥K♥, emparejaste tu rey. Y fijate: hay cuatro corazones entre '
      'tu mano y la mesa — te falta uno solo para tener color. Un flop '
      'así te tiene que encantar.',
      role: MentorSayRole.observe,
      table: _stage(hero: hero, board: board),
      anchor: TableAnchor.heroCards,
      highlight: const [TableAnchor.heroCards, TableAnchor.board],
    );
    beats.say(
      'No sigas en la mano solo porque "todavía puede venir mi carta", '
      'sin nada real armándose. Leer bien el flop —qué tenés hecho, qué '
      'se puede estar armando— es la habilidad que vas a construir en los '
      'próximos niveles.',
      role: MentorSayRole.bridge,
    );
    beats.say(
      'Flop = 3 cartas comunitarias juntas. Acá se define casi todo: leé '
      'el board antes de decidir nada.',
      role: MentorSayRole.keyIdea,
    );
    return MentorLesson('T044', beats);
  }

  static MentorLesson elTurn() {
    final beats = <MentorBeat>[];
    beats.say(
      'Se cerró la ronda del flop. Sale una carta más, sola.',
      role: MentorSayRole.intro,
    );
    beats.say(
      'Esa cuarta carta comunitaria es el turn. El bote suele empezar a '
      'ponerse grande acá, y las decisiones, más caras.',
      role: MentorSayRole.explain,
    );
    beats.say(
      'Flop 8♠7♦2♣, turn 6♥. Con 5-4 en la mano, la mesa te regaló cinco '
      'seguidas: 8-7-6-5-4. Pero si en cambio tenías pareja de ochos, esa '
      'misma carta abrió una escalera posible para cualquier otro — tu '
      'mano, sin cambiar en nada, ahora vale menos.',
      role: MentorSayRole.example,
    );
    beats.say(
      'El error típico es jugar el turn con el mismo plan del flop, sin '
      'actualizar nada. La carta nueva cambió la mano — hay que pensarla '
      'de vuelta, no repetir el plan anterior en piloto automático.',
      role: MentorSayRole.error,
    );
    beats.say(
      'Turn = la 4ª carta comunitaria. Bote más grande, decisiones más '
      'caras, una chance menos para las manos sin terminar.',
      role: MentorSayRole.keyIdea,
    );
    return MentorLesson('T045', beats);
  }

  static MentorLesson elRiver() {
    final beats = <MentorBeat>[];
    beats.say(
      'Última carta de toda la mano. Después de esta, no sale nada más.',
      role: MentorSayRole.intro,
    );
    beats.say(
      'Al river se lo piensa distinto a las calles anteriores: ya no hay '
      '"todavía puede mejorar". Tu mano es, definitivamente, lo que es.',
      role: MentorSayRole.explain,
    );
    beats.say(
      'Estabas esperando una pica para completar color, y en el río salió '
      'un trébol. Tu proyecto murió ahí — no queda ninguna carta más que '
      'lo pueda salvar.',
      role: MentorSayRole.example,
    );
    beats.say(
      'No sigas "esperando tu carta" en el río, porque ya no viene '
      'ninguna. Pagar con una mano que no ligó nada solo "porque ya puse '
      'mucho" es tirar las fichas que te quedan por una ilusión.',
      role: MentorSayRole.error,
    );
    beats.say(
      'River = última carta. No viene nada más: o tu mano ya gana, o no '
      'gana — y ahí termina la historia.',
      role: MentorSayRole.keyIdea,
    );
    return MentorLesson('T046', beats);
  }

  static MentorLesson laRondaDeApuestas() {
    final beats = <MentorBeat>[];
    beats.say(
      'Ya viste las 4 calles por separado. Juntemos el patrón completo.',
      role: MentorSayRole.intro,
    );
    beats.say(
      'En cada calle pasa siempre lo mismo: se reparte la carta (o las '
      'cartas), empieza una ronda de apuestas, cada jugador actúa en su '
      'turno, y cuando todos igualaron o pasaron, la ronda se cierra y '
      'sale la siguiente.',
      role: MentorSayRole.explain,
    );
    beats.say(
      'Preflop: ronda 1. Flop: ronda 2. Turn: ronda 3. River: ronda 4. '
      'Después de esa cuarta ronda, o hay showdown, o la mano ya terminó '
      'porque todos foldearon antes.',
      role: MentorSayRole.observe,
    );
    beats.say(
      'Perder la cuenta de en qué calle estás — y jugar el turn como si '
      'fuera el flop, por ejemplo— te hace tomar decisiones con la '
      'información equivocada. Siempre sabé en qué ronda estás parado.',
      role: MentorSayRole.error,
    );
    beats.say(
      '4 calles, 4 rondas de apuestas. Carta → ronda → carta → ronda, '
      'siempre en ese orden.',
      role: MentorSayRole.keyIdea,
    );
    return MentorLesson('T047', beats);
  }

  static MentorLesson cambioDeInformacion() {
    final beats = <MentorBeat>[];
    beats.say(
      'Una idea que va a atravesar TODA tu forma de jugar, desde acá en '
      'adelante.',
      role: MentorSayRole.intro,
    );
    beats.say(
      'Cada carta nueva y cada acción del rival te dan información. Con '
      'cada calle sabés un poco más de lo que sabías antes — nunca menos.',
      role: MentorSayRole.explain,
    );
    beats.say(
      'Preflop, el rival solo pagó tu subida: puede tener bastantes manos '
      'distintas. En el flop, apuesta fuerte en un board A-K-2: ahora la '
      'lista de manos que puede tener es más corta, y más fuerte en '
      'promedio.',
      role: MentorSayRole.example,
    );
    beats.say(
      'El error más caro acá es decidir el río con la misma imagen del '
      'rival que tenías en el preflop — sin actualizar nada con todo lo '
      'que pasó en el medio.',
      role: MentorSayRole.error,
    );
    beats.say(
      'Cada carta y cada acción suman información. Actualizá tu lectura '
      'calle a calle, nunca te quedes con la primera impresión.',
      role: MentorSayRole.keyIdea,
    );
    return MentorLesson('T048', beats);
  }

  static MentorLesson elFinDeLaMano() {
    final beats = <MentorBeat>[];
    beats.say(
      'Para cerrar esta primera clase completa: repasemos cómo termina, '
      'de verdad, una mano de póker.',
      role: MentorSayRole.intro,
    );
    beats.say(
      'Solo hay dos finales posibles. Si en cualquier calle todos menos '
      'uno se retiran, la mano termina ahí y ese jugador se lleva el bote '
      'sin mostrar nada. Si al menos dos llegan hasta el final del río, '
      'hay showdown y se compara.',
      role: MentorSayRole.explain,
    );
    beats.ask(
      'Repasemos las dos formas de ganar que ya viste: ¿cuáles son?',
      options: const [
        ExerciseChoice(
          label: 'Por cartas (showdown) o por fold (el rival se retira)',
          rating: ExerciseRating.best,
          feedback: 'Exacto — esas dos, y no hay una tercera. Toda mano '
              'termina de una de esas dos maneras.',
        ),
        ExerciseChoice(
          label: 'Solo mostrando la mejor mano al final',
          rating: ExerciseRating.poor,
          feedback: 'Esa es una sola de las dos formas. La otra —y muy '
              'frecuente— es que todos los demás se retiren antes de '
              'llegar a mostrar nada.',
        ),
      ],
    );
    beats.say(
      'Desde el preflop, ya conviene tener un plan de cómo querés que '
      'termine la mano: con una mano fuerte, llegar al showdown cobrando; '
      'con una floja, ganar antes porque el rival se va, o rendirte '
      'barato si no pasa eso.',
      role: MentorSayRole.observe,
    );
    beats.say(
      'Con esto cerramos el Nivel 1: ya sabés cómo se arma una mano '
      'completa, de punta a punta. En el próximo nivel vamos a aprender a '
      'compararlas — el ranking de manos.',
      role: MentorSayRole.bridge,
    );
    beats.say(
      'La mano termina por fold o por showdown. Tené siempre claro para '
      'cuál de las dos estás jugando.',
      role: MentorSayRole.keyIdea,
    );
    return MentorLesson('T049', beats);
  }
}
