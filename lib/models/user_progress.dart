/// Modelo de datos del progreso del usuario en la Home.
///
/// Por ahora se alimenta con [UserProgress.mock]. Cuando exista backend,
/// esta clase pasará a construirse a partir de la respuesta de la API
/// (por ejemplo con un `fromJson`), sin que las pantallas/widgets que la
/// consumen necesiten cambiar.
class UserProgress {
  final String name;
  final String rankTitle;
  final int level;
  final int xp;
  final int xpRequired;
  final int coins;
  final int diamonds;
  final int hasUnreadNotifications;

  final int currentStreakDays;
  final int bestStreakDays;
  final String motivationalQuote;

  final int academyLevel;
  final int academyMaxLevel;

  final String lastLabSessionName;
  final int lastLabSessionAccuracy;

  final int accuracyPercent;
  final int accuracyWeeklyDelta;
  final int rankingPosition;
  final int rankingTopPercent;
  final int exercisesCompleted;
  final int activeDaysThisWeek;

  final String weeklyChallengeDescription;
  final int weeklyChallengeProgress;
  final int weeklyChallengeGoal;
  final int weeklyChallengeRewardDiamonds;

  const UserProgress({
    required this.name,
    required this.rankTitle,
    required this.level,
    required this.xp,
    required this.xpRequired,
    required this.coins,
    required this.diamonds,
    required this.hasUnreadNotifications,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.motivationalQuote,
    required this.academyLevel,
    required this.academyMaxLevel,
    required this.lastLabSessionName,
    required this.lastLabSessionAccuracy,
    required this.accuracyPercent,
    required this.accuracyWeeklyDelta,
    required this.rankingPosition,
    required this.rankingTopPercent,
    required this.exercisesCompleted,
    required this.activeDaysThisWeek,
    required this.weeklyChallengeDescription,
    required this.weeklyChallengeProgress,
    required this.weeklyChallengeGoal,
    required this.weeklyChallengeRewardDiamonds,
  });

  double get xpProgress =>
      xpRequired == 0 ? 0 : (xp / xpRequired).clamp(0, 1).toDouble();

  double get academyProgress =>
      academyMaxLevel == 0 ? 0 : (academyLevel / academyMaxLevel).clamp(0, 1).toDouble();

  double get weeklyChallengeProgressRatio => weeklyChallengeGoal == 0
      ? 0
      : (weeklyChallengeProgress / weeklyChallengeGoal).clamp(0, 1).toDouble();

  /// Datos de ejemplo (mock) usados hasta que exista backend real.
  factory UserProgress.mock() => const UserProgress(
        name: 'Juan G.',
        rankTitle: 'Novato Estratégico',
        level: 17,
        xp: 2450,
        xpRequired: 3000,
        coins: 12450,
        diamonds: 320,
        hasUnreadNotifications: 1,
        currentStreakDays: 12,
        bestStreakDays: 28,
        motivationalQuote: 'La suerte favorece a los preparados.',
        academyLevel: 17,
        academyMaxLevel: 60,
        lastLabSessionName: '3-Bet vs BTN',
        lastLabSessionAccuracy: 86,
        accuracyPercent: 72,
        accuracyWeeklyDelta: 5,
        rankingPosition: 1248,
        rankingTopPercent: 15,
        exercisesCompleted: 1248,
        activeDaysThisWeek: 4,
        weeklyChallengeDescription: 'Completá 50 ejercicios en el Laboratorio',
        weeklyChallengeProgress: 32,
        weeklyChallengeGoal: 50,
        weeklyChallengeRewardDiamonds: 150,
      );
}
