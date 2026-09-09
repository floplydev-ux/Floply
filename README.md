# Poker Trainer — Etapa 1: Home (Flutter + Dart)

Primera etapa del proyecto: **solo la pantalla de inicio (Home/Dashboard)**,
visual y sin backend, login, ejercicios ni navegación funcional.

## Cómo ejecutar

```bash
cd poker_trainer
flutter pub get
flutter run
```

Recomendado probar en un emulador Android o un teléfono físico. La pantalla
también debería verse correctamente en iOS ya que no se usó ningún código
específico de plataforma.

Para verificar rápidamente que no hay errores sin levantar un emulador:

```bash
flutter analyze
```

> **Nota:** este proyecto fue generado en un entorno sin Flutter/Dart SDK
> instalado y sin acceso a red, por lo que **no pude ejecutar
> `flutter pub get` / `flutter run` / `flutter analyze` para verificarlo yo
> mismo**. El código fue escrito y revisado a mano con cuidado (sin paquetes
> externos más allá de `cupertino_icons`, que ya viene en cualquier proyecto
> Flutter nuevo), pero por favor corré `flutter analyze` apenas lo abras y
> avisame si aparece algún error para corregirlo enseguida.

## Estructura

```
lib/
  main.dart                     # entry point
  app.dart                      # MaterialApp + tema, apunta a AppShell
  models/
    user_progress.dart          # modelo mock del progreso del usuario
    nav_destination.dart        # los 5 destinos (ícono+label), fuente única
  l10n/
    app_strings.dart            # todo el copy en español, centralizado
  theme/
    app_colors.dart             # paleta de colores
    app_theme.dart              # ThemeData Material 3 oscuro
  utils/
    coming_soon.dart            # snackbar "Próximamente" (para acciones sueltas)
    formatters.dart             # formato de números (separador de miles)
  widgets/
    pressable_scale.dart        # feedback táctil reutilizable
    glass_card.dart             # tarjeta base reutilizable
    user_header.dart            # avatar, nivel, XP, monedas, notificaciones
    progress_card.dart          # racha actual/mejor + escudo de nivel
    academy_card.dart           # tarjeta ACADEMIA (violeta)
    laboratory_card.dart        # tarjeta LABORATORIO (verde)
    stats_section.dart          # estadísticas rápidas (scrollable)
    weekly_challenge_card.dart  # desafío semanal
    bottom_navigation.dart      # barra inferior controlada (currentIndex + onTap)
  screens/
    root/
      app_shell.dart            # dueño de la pestaña activa; arma Home + placeholders
    home/
      home_screen.dart          # arma toda la Home + animación de entrada
    placeholder/
      coming_soon_screen.dart   # pantalla "Próximamente" reutilizable
```

## Navegación (nuevo)

Ya hay navegación real entre pestañas, aunque el contenido de 4 de
las 5 siga siendo un placeholder:

- `AppShell` (`lib/screens/root/app_shell.dart`) mantiene qué pestaña
  está activa con un `IndexedStack`, y arma la `AppBottomNavigation`
  compartida por todas las pantallas.
- Tocar **Academia**, **Laboratorio**, **Estadísticas** o **Perfil** en
  la barra inferior cambia de pestaña de verdad y muestra una pantalla
  `ComingSoonScreen` con estética consistente (no un blanco vacío).
- Los botones **CONTINUAR** (Academia) y **PRACTICAR AHORA**
  (Laboratorio) dentro de la Home también navegan a esas mismas
  pestañas, vía callbacks (`onGoToAcademy` / `onGoToLaboratory`) que
  bajan desde `AppShell` → `HomeScreen` → las tarjetas.
- Reemplazar un placeholder por la pantalla real es tan simple como
  intercambiar el `ComingSoonScreen` correspondiente en la lista
  `screens` de `AppShell` por el widget definitivo — nada más cambia.
- Los chips de monedas/diamantes y la campana de notificaciones siguen
  usando el snackbar de `showComingSoon`, porque no son pestañas sino
  funcionalidades sueltas (tienda, notificaciones) que todavía no
  tienen pantalla propia.

## Qué queda listo para conectar después

- **Datos**: todo sale de `UserProgress.mock()`. El día que haya backend,
  alcanza con reemplazar esa factory por una llamada real / un
  `fromJson`; ningún widget necesita cambiar porque todos reciben un
  `UserProgress` ya armado.
- **Navegación**: `AppBottomNavigation` ya tiene los 5 destinos definidos
  (Inicio, Academia, Laboratorio, Estadísticas, Perfil) con sus íconos y
  labels. Actualmente todos menos "Inicio" solo muestran un aviso de
  "Próximamente" (`showComingSoon`); ahí es donde se engancha la
  navegación real.
- **Botones "CONTINUAR" / "PRACTICAR AHORA"**: llaman a `showComingSoon`;
  ahí se conecta la navegación hacia Academia/Laboratorio reales.
- **Textos**: todos están centralizados en `AppStrings`
  (`lib/l10n/app_strings.dart`) en vez de estar hardcodeados en cada
  widget, para poder migrar a `intl` + archivos `.arb` sin tocar los
  widgets.
- **Iconos/monedas/notificaciones**: los chips de monedas y diamantes y
  la campana de notificaciones ya son tocables y muestran
  "Próximamente"; ahí se conecta la tienda y el centro de notificaciones.

## Qué NO se implementó (a propósito)

Login, backend, base de datos, sistema de ejercicios, algoritmo de póker,
compras, publicidad, sistema Premium, API, internacionalización real y
navegación funcional. Todo eso queda para etapas siguientes.
