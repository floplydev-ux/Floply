import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Preferencias simples del usuario, persistidas en un archivo JSON local.
/// No requiere dependencias adicionales — usa `path_provider` ya existente.
class AppPrefs {
  AppPrefs._();

  static const _kTrainingCoinShown = 'training_coin_shown';
  static const _kToolsCoinShown = 'tools_coin_shown';
  static const _kCoachSessionActive = 'coach_session_active';

  static Map<String, dynamic>? _cache;

  static Future<File> _prefsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/floply_prefs.json');
  }

  static Future<Map<String, dynamic>> _load() async {
    if (_cache != null) return _cache!;
    try {
      final f = await _prefsFile();
      if (!await f.exists()) return _cache = {};
      return _cache = Map<String, dynamic>.from(
        jsonDecode(await f.readAsString()) as Map,
      );
    } catch (_) {
      return _cache = {};
    }
  }

  static Future<void> _save(Map<String, dynamic> prefs) async {
    _cache = prefs;
    try {
      final f = await _prefsFile();
      await f.writeAsString(jsonEncode(prefs));
    } catch (_) {}
  }

  static Future<bool> _getBool(String key) async {
    final prefs = await _load();
    return prefs[key] as bool? ?? false;
  }

  static Future<void> _setBool(String key, {required bool value}) async {
    final prefs = await _load();
    prefs[key] = value;
    await _save(prefs);
  }

  /// Si el usuario ya vio la hoja de "coin que se usa al entrenar" y
  /// marcó "no volver a mostrar".
  static Future<bool> get trainingCoinShown => _getBool(_kTrainingCoinShown);
  static Future<void> dismissTrainingCoin() =>
      _setBool(_kTrainingCoinShown, value: true);

  /// Si el usuario ya vio la hoja de "coin que se usa en Tools" y
  /// marcó "no volver a mostrar".
  static Future<bool> get toolsCoinShown => _getBool(_kToolsCoinShown);
  static Future<void> dismissToolsCoin() =>
      _setBool(_kToolsCoinShown, value: true);

  /// `true` mientras haya una sesión de Coach activa — persiste entre
  /// reinicios de la app para que el diálogo "Continuar/Nueva sesión"
  /// aparezca aunque el controlador no sobreviva en memoria.
  static Future<bool> get coachSessionActive =>
      _getBool(_kCoachSessionActive);
  static Future<void> setCoachSessionActive({required bool value}) =>
      _setBool(_kCoachSessionActive, value: value);
}
