import '../engine/academy/academy_store.dart';
import 'file_academy_store.dart';

/// En móvil / desktop: persiste en un archivo JSON local.
AcademyStore createAcademyStore() => FileAcademyStore();
