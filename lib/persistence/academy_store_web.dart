import '../engine/academy/academy_store.dart';

/// En web el progreso vive solo en memoria (se pierde al recargar). Alcanza
/// para probar la app desde el navegador del celular; la persistencia real
/// es en móvil/desktop con [FileAcademyStore].
AcademyStore createAcademyStore() => InMemoryAcademyStore();
