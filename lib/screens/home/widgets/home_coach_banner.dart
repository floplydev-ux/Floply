import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/sala_verde/sala_verde_tokens.dart';
import 'home_feature_banner.dart';

class HomeCoachBanner extends StatelessWidget {
  const HomeCoachBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HomeFeatureBanner(
      accent: SalaVerdeColors.brass,
      title: AppStrings.coachTitle,
      description: AppStrings.coachDescription,
      onTap: onTap,
      backgroundImage: 'assets/images/home/coach_banner_bg.jpg',
      backgroundImageAlignment: Alignment.topCenter,
    );
  }
}
