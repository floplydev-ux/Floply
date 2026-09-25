import 'auth_provider_type.dart';

/// Estado de la cuenta. Separado de "¿está autenticado ahora?": una cuenta
/// puede existir y estar `active` mientras el dispositivo está en modo
/// invitado o recién cerró sesión.
enum AccountStatus { active, deleted }

/// Un método de acceso ya vinculado a la cuenta, con el identificador
/// estable de ese proveedor (nunca el email: Apple con "Ocultar mi
/// correo" no comparte uno real, y el email de Google puede cambiar).
class LinkedProvider {
  const LinkedProvider({
    required this.type,
    required this.providerUid,
    this.email,
    required this.linkedAt,
  });

  final AuthProviderType type;

  /// El id estable que da el proveedor (Google `sub`, Apple
  /// `userIdentifier`, o el uid de Firebase para el método de email). Es
  /// lo que identifica de verdad al método — nunca el email.
  final String providerUid;

  final String? email;
  final DateTime linkedAt;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'providerUid': providerUid,
        'email': email,
        'linkedAt': linkedAt.toIso8601String(),
      };

  factory LinkedProvider.fromJson(Map<String, dynamic> json) => LinkedProvider(
        type: AuthProviderType.values.byName(json['type'] as String),
        providerUid: json['providerUid'] as String,
        email: json['email'] as String?,
        linkedAt: DateTime.parse(json['linkedAt'] as String),
      );
}

/// La identidad de cuenta de Floply — la raíz de todos los datos futuros
/// del usuario (perfil, progreso, bankroll, suscripción…). El [id] es el
/// identificador principal y NUNCA cambia con el método de acceso: Google,
/// Apple y email son formas de autenticarse en esta misma identidad, no
/// identidades en sí mismas (ver [linkedProviders]).
class FloplyUser {
  const FloplyUser({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.displayName,
    this.username,
    this.email,
    this.photoUrl,
    this.customPhotoUrl,
    this.locale = 'en_US',
    this.country,
    this.onboardingCompleted = false,
    this.accountStatus = AccountStatus.active,
    this.linkedProviders = const [],
  });

  /// Id interno de Floply — clave primaria real. NUNCA el email, ni el id
  /// de Google, ni el de Apple (esos solo viven dentro de
  /// [linkedProviders]).
  final String id;

  final DateTime createdAt;
  final DateTime updatedAt;

  final String displayName;

  /// Handle público opcional (p. ej. para rankings/Practice Room a
  /// futuro). Nunca obligatorio para autenticarse.
  final String? username;

  /// Email "de perfil" a mostrar — puede no coincidir con el email de
  /// ningún proveedor puntual (p. ej. Apple con Hide My Email).
  final String? email;

  /// Copia del `photoURL` que dio el proveedor (Google/Apple) en el
  /// último login — se mantiene fresca en cada inicio de sesión, nunca
  /// editable a mano por el usuario. Para lo que se muestra en la UI usar
  /// [avatarUrl], no este campo directo.
  final String? photoUrl;

  /// Avatar propio de Floply, subido por el usuario — no implementado
  /// todavía (ver AUTH_SETUP.md), pero reservado para que cuando exista
  /// gane prioridad sobre la foto del proveedor sin tocar nada más.
  final String? customPhotoUrl;

  /// La foto a mostrar de verdad, con la prioridad pedida: avatar propio
  /// de Floply primero, si no la del proveedor (Google/Apple), si no
  /// ninguna — el widget de avatar decide el fallback visual.
  String? get avatarUrl => customPhotoUrl ?? photoUrl;

  /// BCP-47 (`es_AR`, `en_US`…). Nunca un valor fijo: la app es global.
  final String locale;

  final String? country;
  final bool onboardingCompleted;
  final AccountStatus accountStatus;
  final List<LinkedProvider> linkedProviders;

  bool hasProvider(AuthProviderType type) =>
      linkedProviders.any((p) => p.type == type);

  FloplyUser copyWith({
    String? displayName,
    String? username,
    String? email,
    String? photoUrl,
    String? customPhotoUrl,
    String? locale,
    String? country,
    bool? onboardingCompleted,
    AccountStatus? accountStatus,
    List<LinkedProvider>? linkedProviders,
    DateTime? updatedAt,
  }) {
    return FloplyUser(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      customPhotoUrl: customPhotoUrl ?? this.customPhotoUrl,
      locale: locale ?? this.locale,
      country: country ?? this.country,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      accountStatus: accountStatus ?? this.accountStatus,
      linkedProviders: linkedProviders ?? this.linkedProviders,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'displayName': displayName,
        'username': username,
        'email': email,
        'photoUrl': photoUrl,
        'customPhotoUrl': customPhotoUrl,
        'locale': locale,
        'country': country,
        'onboardingCompleted': onboardingCompleted,
        'accountStatus': accountStatus.name,
        'linkedProviders': linkedProviders.map((p) => p.toJson()).toList(),
      };

  factory FloplyUser.fromJson(Map<String, dynamic> json) => FloplyUser(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        displayName: json['displayName'] as String,
        username: json['username'] as String?,
        email: json['email'] as String?,
        photoUrl: json['photoUrl'] as String?,
        customPhotoUrl: json['customPhotoUrl'] as String?,
        locale: json['locale'] as String? ?? 'en_US',
        country: json['country'] as String?,
        onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
        accountStatus: AccountStatus.values.byName(
          json['accountStatus'] as String? ?? 'active',
        ),
        linkedProviders: (json['linkedProviders'] as List? ?? [])
            .map((p) => LinkedProvider.fromJson((p as Map).cast()))
            .toList(),
      );
}
