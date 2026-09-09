# Changelog

Todas las versiones relevantes de este proyecto se registran acá.

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/)
y versionado según [Semantic Versioning](https://semver.org/lang/es/)
(`MAJOR.MINOR.PATCH`).

Convención de este proyecto:

- `0.x.0` — bloque funcional importante (p. ej. un nivel nuevo de la
  Academia).
- `0.x.y` — correcciones y cambios pequeños sobre ese bloque.
- `1.0.0` — primera versión completa destinada a release.

Regla de trabajo: no se empieza un bloque importante sin dejar antes una
versión estable con tag. Cada bloque termina con código funcionando,
tests en verde, `analyze` sin nuevos problemas, `build` OK, CHANGELOG
actualizado, commit y tag.

---

## [0.1.0] - 2026-09-09

### Estado

Primera versión estable de desarrollo.

### Incluye

- Identidad dinámica de jugadores.
- Nivel 1 completo.
- Nivel 2 completo.
- Teoría interactiva sobre mesa.
- Ejercicios interactivos sobre mesa.
- Showdowns reales con cartas y board.
- Sistema de nombres dinámicos para usuario y rivales.
- Validaciones responsive.
- Tests automatizados.

### Validación

- `flutter test`: 119/119
- `flutter analyze`: sin nuevos issues (43 `info` preexistentes en los
  widgets de la Home, no relacionados)
- `flutter build web`: OK

### Detalle

- **Academia (motor):** currículo de 5 niveles × 5 sub-niveles, progresión
  con desbloqueos, mastery por concepto, regla fundamental (solo se evalúa
  lo enseñado), persistencia local sin backend.
- **Mesa interactiva:** `PokerTableView` + `EducationalBubble` + sistema de
  pasos, highlights y anclas; posicionamiento fraccional (mobile-first,
  vertical). Reutilizada por teoría y ejercicios.
- **Nivel 1 (Fundamentos · reglas):** las 5 lecciones sobre la mesa —
  teoría interactiva (1.1 mano completa, 1.2 stack/ciegas/bote, 1.3
  calles y acciones) y ejercicios interactivos (1.1–1.5), incluida la
  evaluación.
- **Nivel 2 (Ranking de manos):** 2.1 teoría con 8 showdowns encadenados
  de la jerarquía; 2.1–2.5 ejercicios "¿quién gana?" sobre showdowns
  reales (board + las dos manos boca arriba), 22 situaciones, dificultad
  creciente.
- **Identidad de jugadores:** el usuario aparece con su nombre
  (`AppUser.current`); los rivales son personajes con nombre y avatar
  (`AcademyPlayers`: Nico, Sofi, Mateo, Lara, Bruno, Valen, Tomi, Mica,
  Fran, Agus). Los guiones no hardcodean nombres:
  `TableSnapshot.withCast` + plantillas `{me}` / `{BTN}` / … en los
  textos.
- **Ejercicios interactivos:** valoración no binaria (`best` /
  `acceptable` / `poor`), `strategyDependent` para decisiones que dependen
  del rango, `concept: null` para adelantos que no tocan el mastery.
- **Laboratorio:** práctica libre con el motor de ejercicios; sin cambios
  respecto de etapas anteriores.

### Nota

Esta versión **no** incluye todavía la personalización visual definitiva
de FLOPly (logo, colores, tipografías, splash, iconos, textos de marca).
El nombre "Floply" identifica el repositorio; el branding se hará más
adelante, una vez validada formalmente la identidad.

[0.1.0]: https://github.com/full710/Floply/releases/tag/v0.1.0
