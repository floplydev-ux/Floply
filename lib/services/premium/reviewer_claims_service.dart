import 'package:flutter/foundation.dart';

import '../../auth/auth_repository.dart';

/// Verifica si la cuenta autenticada tiene el Firebase Custom Claim
/// `reviewerPremium: true`, asignado exclusivamente vía Firebase Admin SDK
/// a la cuenta de Google Play Reviewer.
///
/// Este servicio es la única fuente de verdad para el carril reviewer dentro
/// de [PromoAwarePremiumService] — ninguna pantalla lo consulta directamente.
///
/// **Seguridad**: el claim vive en el ID token firmado por Firebase; el
/// cliente Flutter no puede establecerlo ni modificarlo. Solo el Admin SDK
/// (o Firebase Console → Custom Claims) puede hacerlo.
class ReviewerClaimsService extends ChangeNotifier {
  ReviewerClaimsService(this._auth);

  final AuthRepository _auth;
  bool _isReviewer = false;

  bool get isReviewer => _isReviewer;

  /// Debe llamarse cada vez que cambie el UID autenticado (login/logout).
  /// Fuerza un refresh del ID token para capturar claims recién asignados.
  Future<void> onUserChanged(String? uid) async {
    final was = _isReviewer;
    if (uid == null) {
      _isReviewer = false;
    } else {
      _isReviewer = await _auth.isReviewerAccount();
    }
    if (_isReviewer != was) notifyListeners();
  }
}
