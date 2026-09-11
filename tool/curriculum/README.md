# Autoría del currículo de la Academia

Herramienta bootstrap. La **fuente de verdad** es
`assets/curriculum/curriculum_spec.json`; este script la (re)genera junto con
`lib/engine/pedagogy/curriculum_spec_data.g.dart`.

## Uso

```
cd tool/curriculum
PYTHONUTF8=1 python gen_curriculum.py
```

Escribe directo al repo (assets/ y lib/). Valida por stdout: cobertura de los
308 temas, 18 nuevas, DAG de prerrequisitos, dificultad monótona, vocabulario,
conceptos_clave y contenido redactado.

## Contenido redactado (PASO 4)

Un módulo `content_nX.py` por nivel expone `NX = {theory_id: {campos}}` con los
campos: que_es, por_que_importa, como_funciona, cuando_lo_uso, cuando_no,
ejemplo, error_comun, idea_clave (None = no aplica). `gen_curriculum.py` los
mergea y emite `contenido` + `estadoRedaccion:"listo"`.

- N1 «Cómo funciona una mano» → `content_n1.py` (25 teorías). Hecho.
- N2 «Ranking de manos» → `content_n2.py` (16 teorías). Hecho.
- N3 «La mesa: posiciones y dinero» → `content_n3.py` (22 teorías). Hecho.
- N4 «Leé tu mano y el board» → `content_n4.py` (37 teorías). Hecho.
  Sin `pasos_mesa` ni ejercicios propios (nivel nuevo, sin legacy que
  re-anclar) — pendiente el piloto visual N4 antes de redactar N5.
- N5..N13 → pendientes.

`_load_written_content()` en `gen_curriculum.py` carga `content_n1..content_n13`
automáticamente.

Ajustes de estructura aplicados vía generador (el JSON es el artefacto de
registro):
- `LEVELS`: 1.2 `items=[8,9,10]` → orden T008→T009→T010.
- `PREREQ_OVERRIDE`: `{"T006": ["T008"]}` — el ranking se ancla en el showdown,
  no en "ganar por fold" (que quedó última en 1.2 tras el reordenamiento).
