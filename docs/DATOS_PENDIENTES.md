# FLOPly Legal — Datos pendientes de completar

Este archivo lista todos los campos marcados como `[COMPLETAR]` en los documentos legales.
Reemplazá cada placeholder con el dato real antes de publicar.

---

## 1. Nombre legal del desarrollador / empresa

**Aparece en:**
- `terminos.html` — Sección 01 (Introducción), Sección 21 (Propiedad Intelectual)
- `privacidad.html` — Sección 02 (Responsable del Servicio)

**Qué completar:**
El nombre legal completo de la persona física o empresa que desarrolla y distribuye FLOPly.
Ejemplo: "Juan Ignacio González" / "FLOPly SRL" / "Floply Studios Ltd."

---

## 2. Correo electrónico de contacto / soporte / privacidad

**Aparece en:**
- `terminos.html` — Sección 30 (Contacto)
- `privacidad.html` — Sección 02 (Responsable del Servicio), Sección 22 (Contacto)

**Qué completar:**
Una dirección de correo electrónico real donde los usuarios puedan enviar consultas legales,
solicitudes de privacidad o soporte. Puede ser la misma para ambos propósitos o diferente.
Ejemplo: `legal@floply.app` / `soporte@floply.app`

---

## 3. Domicilio legal

**Aparece en:**
- `privacidad.html` — Sección 02 (Responsable del Servicio)

**Qué completar:**
Dirección postal del desarrollador o empresa. Es un requisito en muchas jurisdicciones para
documentos de privacidad. Puede ser una dirección de empresa o la del desarrollador individual.
Si no querés publicar una dirección física, en algunos países es suficiente con el país de residencia.

---

## 4. Fecha de última actualización

**Aparece en:**
- `terminos.html` — Encabezado de la página
- `privacidad.html` — Encabezado de la página

**Qué completar:**
La fecha en que estos documentos entraron en vigencia o fueron actualizados por última vez.
Formato recomendado: "5 de octubre de 2026" o "2026-10-05"

---

## 5. Edad mínima de uso

**Aparece en:**
- `terminos.html` — Sección 03 (Aceptación de los Términos)
- `privacidad.html` — Sección 19 (Menores de Edad)

**Qué completar:**
La edad mínima requerida para usar FLOPly. Consideraciones:
- **13 años**: mínimo COPPA (EE. UU.)
- **14 años**: mínimo en España (LOPD-GDD)
- **16 años**: recomendado para suscripciones/compras en la UE
- **18 años**: si se considera que el contenido de poker requiere mayoría de edad

Google Play también aplica restricciones de contenido por edad según la calificación del contenido.
Si la app está clasificada como "Teen" (13+) o similar, usar ese valor como referencia.

---

## 6. Legislación aplicable y jurisdicción

**Aparece en:**
- `terminos.html` — Sección 29 (Legislación Aplicable y Jurisdicción)

**Qué completar:**
- El país/estado cuya ley rige los Términos. Ejemplo: "República Argentina", "España", "México"
- La ciudad o jurisdicción para resolución de conflictos. Ejemplo: "Ciudad Autónoma de Buenos Aires"

---

## 7. URL de la Política de Privacidad para Google Play Console

**No aparece en los documentos, pero es necesario para Google Play:**

Una vez que actives GitHub Pages y la web esté publicada, la URL de la Política de Privacidad será:

```
https://[tu-usuario].github.io/[nombre-del-repo]/privacidad.html
```

Esta URL debe ingresarse en:
- Google Play Console → Tu aplicación → Configuración de la aplicación → Política de privacidad
- RevenueCat Dashboard (si se requiere)
- Firebase Console (si se configura)

---

## 8. URL de los Términos y Condiciones (opcional para Google Play)

```
https://[tu-usuario].github.io/[nombre-del-repo]/terminos.html
```

---

## Notas adicionales

- **No se encontró email de soporte en el código fuente de la app.** Si existe, agregarlo también en la app (sección de Perfil / Configuración) para consistencia.
- **Edad mínima no definida en la app.** Definirla antes de publicar en Google Play (la calificación de contenido del dashboard de Play lo requiere).
- **No se encontró nombre de empresa en el código.** El desarrollador debe decidir si opera como persona física o jurídica antes de publicar.
- Los documentos están escritos en **español neutro** (sin regionalismos). Si la app tiene una región principal, podés ajustar el tono.
- Estos documentos **no reemplazan asesoramiento legal profesional**. Para distribución comercial con suscripciones reales, es recomendable que un abogado revise los documentos antes de publicarlos.
