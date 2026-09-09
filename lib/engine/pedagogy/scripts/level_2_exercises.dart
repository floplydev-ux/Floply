import '../../concepts/concept_ids.dart';
import '../table_exercise.dart';
import '../table_lesson.dart';
import 'table_builder.dart';

/// Ejercicios interactivos sobre la mesa — Nivel 2 (Ranking de manos).
///
/// El usuario mira un showdown real (sus cartas, las del rival y el board)
/// y decide **quién gana**. Concepto: `hand_ranking` (enseñado en 2.1).
class Level2Exercises {
  Level2Exercises._();

  static final Map<String, InteractiveExerciseSet> byId = {
    '2.1': InteractiveExerciseSet([
      _sd(['Jc', '9d', '5s', '3h', '2c'], ['Jd', 'Th'], ['9c', '9h'],
          heroWins: false, heroCat: 'pareja de jotas', rivalCat: 'trío'),
    ]),
    '2.2': InteractiveExerciseSet([
      _sd(['Kd', '9s', '4h', '2c', '7s'], ['Ah', 'Ac'], ['Qc', 'Jd'],
          heroWins: true, heroCat: 'pareja', rivalCat: 'carta alta'),
      _sd(['As', 'Ks', '7s', '4d', '2h'], ['3d', '3c'], ['Qs', 'Js'],
          heroWins: false, heroCat: 'pareja', rivalCat: 'color'),
      _sd(['Qd', 'Qs', '8h', '4c', '2d'], ['Qc', '5d'], ['8s', '4h'],
          heroWins: true, heroCat: 'trío', rivalCat: 'doble pareja'),
      _sd(['9d', '8c', '5h', '3s', 'Kd'], ['7s', '6d'], ['Kh', '2c'],
          heroWins: true, heroCat: 'escalera', rivalCat: 'pareja'),
      _sd(['8s', '8h', '3s', '3c', 'Ks'], ['As', 'Qs'], ['8c', '5d'],
          heroWins: false, heroCat: 'color', rivalCat: 'full'),
    ]),
    '2.3': InteractiveExerciseSet([
      _sd(['Ts', '6s', '6h', '3c', '3d'], ['Th', '9d'], ['As', '6c'],
          heroWins: false, heroCat: 'doble pareja', rivalCat: 'trío'),
      _sd(['Ah', 'Kh', 'Qh', '4s', '2d'], ['Jh', '7h'], ['Js', 'Tc'],
          heroWins: true, heroCat: 'color', rivalCat: 'escalera'),
      _sd(['8d', '7s', '5h', '3c', 'Kd'], ['8s', '8c'], ['9d', '6c'],
          heroWins: false, heroCat: 'trío', rivalCat: 'escalera'),
      _sd(['Jd', '9s', '4h', '4c', '2d'], ['Jc', '8d'], ['As', 'Kd'],
          heroWins: true, heroCat: 'doble pareja', rivalCat: 'pareja'),
      _sd(['Kd', 'Ks', '5h', '5c', '2d'], ['Kc', 'Qd'], ['5s', 'Ah'],
          heroWins: true, heroCat: 'full', rivalCat: 'trío'),
    ]),
    '2.4': InteractiveExerciseSet([
      _sd(['Ts', '9s', '8s', '4d', '2h'], ['Jc', 'Qc'], ['As', '7s'],
          heroWins: false, heroCat: 'escalera', rivalCat: 'color'),
      _sd(['Ad', '9h', '6s', '6c', 'Kd'], ['Ah', '9c'], ['6d', 'Ks'],
          heroWins: false, heroCat: 'doble pareja', rivalCat: 'trío'),
      _sd(['7d', '6s', '5h', '2c', 'Kd'], ['7s', '7c'], ['9d', '8c'],
          heroWins: false, heroCat: 'trío', rivalCat: 'escalera'),
      _sd(['Qs', 'Js', '8s', '8d', '3c'], ['As', 'Ks'], ['Qd', 'Qc'],
          heroWins: false, heroCat: 'color', rivalCat: 'full'),
      _sd(['9d', '9s', '9h', '4c', '4d'], ['4s', 'As'], ['9c', '2d'],
          heroWins: false, heroCat: 'full', rivalCat: 'póker'),
    ]),
    '2.5': InteractiveExerciseSet([
      _sd(['Kh', '9s', '4d', '2c', '7h'], ['Kd', 'Qs'], ['As', 'Jc'],
          heroWins: true, heroCat: 'pareja', rivalCat: 'carta alta'),
      _sd(['Ad', '7d', '3d', 'Kc', '2s'], ['As', 'Kh'], ['Jd', '8d'],
          heroWins: false, heroCat: 'pareja', rivalCat: 'color'),
      _sd(['6d', '5s', '4h', 'Kc', '2d'], ['8s', '7d'], ['Kd', '6c'],
          heroWins: true, heroCat: 'escalera', rivalCat: 'doble pareja'),
      _sd(['Ts', 'Td', '7s', '7d', 'Kd'], ['Tc', 'Ah'], ['Ad', 'Qd'],
          heroWins: true, heroCat: 'full', rivalCat: 'color'),
      _sd(['Jd', 'Js', '5h', '4c', '3d'], ['Jc', '9d'], ['6s', '2d'],
          heroWins: false, heroCat: 'trío', rivalCat: 'escalera'),
      _sd(['9d', '8s', '8h', '3c', '2d'], ['9c', '5d'], ['8d', 'Ah'],
          heroWins: false, heroCat: 'doble pareja', rivalCat: 'trío'),
    ]),
  };

  static const _labels = TableBuilder.btnHero; // 0 = usuario, 3 = rival (UTG)
  static const _rank = ConceptIds.handRanking;

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
        potBb: 14,
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
      concept: _rank,
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
          text: 'Primero decide la categoría de la mano; solo si empatan '
              'en categoría se mira la carta más alta.',
          anchor: TableAnchor.pot,
          dimOthers: false,
        ),
      ],
    );
  }
}
