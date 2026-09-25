import '../../concepts/concept_ids.dart';
import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos sobre la mesa — Nivel 4, checkpoint **4.6**
/// ("Manos grandes y nuts": reconocer escaleras, colores, fulls, los nuts
/// y un bluff catcher).
///
/// Mismo formato que `Level2Exercises` (showdown: mirar cartas del héroe,
/// del rival y el board, decidir quién gana) — reutilizado a propósito,
/// no una segunda arquitectura de contenido. Antes de esto, `4.6` no tenía
/// ningún ejercicio autorado (ni acá ni en `AcademyTableScripts`), así que
/// `AcademyController._buildItems()` caía a la lista vacía y el checkpoint
/// aprobaba solo con score 1.0 sin que el alumno respondiera nada — el
/// hueco de contenido que esto cierra.
class Level4Exercises {
  Level4Exercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '4.6': InteractiveExerciseSet([
      // Escalera vs pareja.
      _sd(['6h', '7d', '8c', '2s', 'Ks'], ['9c', 'Ts'], ['Ah', 'Kh'],
          heroWins: true, heroCat: 'escalera', rivalCat: 'pareja de reyes'),
      // Color vs trío.
      _sd(['2s', '6s', '9s', 'Kd', '3h'], ['As', 'Js'], ['Kh', 'Kc'],
          heroWins: true, heroCat: 'color', rivalCat: 'trío de reyes'),
      // Full house vs trío.
      _sd(['7d', '7h', '2c', '9s', '9h'], ['9c', '4d'], ['7c', 'Kd'],
          heroWins: true,
          heroCat: 'full house (nueves con sietes)',
          rivalCat: 'trío de sietes'),
      // Los nuts (póker) vs trío.
      _sd(['5c', '5d', '5h', '8s', '2h'], ['5s', 'Ah'], ['8d', '8c'],
          heroWins: true,
          heroCat: 'póker de cincos (los nuts acá)',
          rivalCat: 'trío de ochos'),
      // Bluff catcher: una pareja modesta le gana a una mano sin nada.
      _sd(['Kh', '9c', '4s', '2d', '7h'], ['Qc', 'Qd'], ['Jc', 'Ts'],
          heroWins: true,
          heroCat: 'pareja de damas (bluff catcher)',
          rivalCat: 'carta alta, sin nada'),
      // El héroe pierde: doble pareja no le alcanza contra una escalera.
      _sd(['4c', '5d', '6h', '9s', 'Kd'], ['Kc', '9c'], ['3h', '7c'],
          heroWins: false, heroCat: 'doble pareja', rivalCat: 'escalera'),
    ]),
  };

  static const _labels = TableBuilder.btnHero; // 0 = usuario, 3 = rival (UTG)
  static const _concept = ConceptIds.handRanking; // mismo skill que 2.1/2.2,
  // reforzado acá con manos más grandes — 4.6 no introduce un concepto
  // nuevo (`conceptos_clave` está vacío para este subnivel en el spec).

  static TableSnapshot _showdown(
    List<String> board,
    List<String> hero,
    List<String> rival,
  ) =>
      TableSnapshot(
        seats: TableBuilder.seats(
          labels: _labels,
          folded: const {5, 4, 2, 1},
          cards: {0: hero, 3: rival},
        ),
        board: board,
        potBb: 22,
        buttonSlot: 0,
      );

  static InteractiveTableExercise _sd(
    List<String> board,
    List<String> hero,
    List<String> rival, {
    required bool heroWins,
    required String heroCat,
    required String rivalCat,
  }) {
    final table = _showdown(board, hero, rival);
    final winnerAnchor =
        heroWins ? TableAnchor.heroCards : const TableAnchor.seat(3);

    final choices = <ExerciseChoice>[
      ExerciseChoice(
        label: '{me} · $heroCat',
        rating: heroWins ? ExerciseRating.best : ExerciseRating.poor,
        feedback: heroWins
            ? 'Sí: tu $heroCat le gana al $rivalCat de {UTG}.'
            : 'No: tu $heroCat pierde contra el $rivalCat de {UTG}.',
      ),
      ExerciseChoice(
        label: '{UTG} · $rivalCat',
        rating: heroWins ? ExerciseRating.poor : ExerciseRating.best,
        feedback: heroWins
            ? 'No: el $rivalCat de {UTG} está por debajo de tu $heroCat.'
            : 'Sí: el $rivalCat de {UTG} le gana a tu $heroCat.',
      ),
      const ExerciseChoice(
        label: 'EMPATE',
        rating: ExerciseRating.poor,
        feedback: 'No hay empate: las dos manos son de categorías '
            'distintas, así que una es claramente superior.',
      ),
    ];

    return InteractiveTableExercise(
      situation: table,
      concept: _concept,
      questionAnchor: TableAnchor.board,
      situationHighlight: const [
        TableAnchor.heroCards,
        TableAnchor.seat(3),
        TableAnchor.board,
      ],
      question: 'Mostraron las cartas en el river. ¿Quién gana el bote?',
      choices: choices,
      explanation: [
        ExerciseExplainStep(
          text: heroWins
              ? 'Vos tenés $heroCat; {UTG}, $rivalCat.'
              : '{UTG} tiene $rivalCat; vos, $heroCat.',
          anchor: winnerAnchor,
          highlight: [winnerAnchor],
        ),
        const ExerciseExplainStep(
          text: 'El orden de las categorías de mano es fijo — de mayor a '
              'menor: póker, full house, color, escalera, trío, doble '
              'pareja, pareja, carta alta.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }
}
