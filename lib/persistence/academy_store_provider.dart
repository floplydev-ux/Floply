import '../engine/academy/academy_store.dart';
import 'academy_store_web.dart'
    if (dart.library.io) 'academy_store_io.dart';

/// Devuelve el [AcademyStore] apropiado para la plataforma:
///  * móvil / desktop → archivo JSON local ([FileAcademyStore]);
///  * web → en memoria (para probar desde el navegador del celular).
AcademyStore defaultAcademyStore() => createAcademyStore();
