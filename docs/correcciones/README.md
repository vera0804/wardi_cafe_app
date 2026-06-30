# Registro de correcciones

Bitácora de **problemas reales**, **síntomas**, **causa** y **solución** del proyecto Wardi Café. Complementa la documentación funcional (`database/docs/`, guías de despliegue, etc.) con el historial de incidentes y arreglos.

## Estructura

```
docs/correcciones/
├── README.md          ← este archivo (índice y reglas)
├── PLANTILLA.md       ← copiar al documentar un caso nuevo
└── casos/
    └── YYYY-MM-DD-tema-corto.md
```

### Convención de nombres

- Carpeta: `docs/correcciones/casos/`
- Archivo: `YYYY-MM-DD-tema-en-kebab-case.md`
- Un archivo = un problema (o un grupo muy relacionado resuelto en el mismo cambio).
- Fecha = día en que se **cerró** la corrección (no necesariamente cuando se detectó).

## Cómo registrar un caso nuevo

1. Copiar `PLANTILLA.md` a `casos/YYYY-MM-DD-tema.md`.
2. Completar todas las secciones; si falta información, dejar explícito «desconocido» o «pendiente».
3. Añadir una fila al **índice** de abajo (más reciente arriba).
4. Enlazar archivos de código con rutas relativas desde la raíz del repo (`pwa/src/...`, `api/src/...`).

## Índice de casos

| Fecha | Tema | Área | Archivo |
|-------|------|------|---------|
| 2026-05-28 | Terminología UI: «lote» → «finca» | PWA + API (mensajes) | [casos/2026-05-28-ui-terminologia-finca.md](casos/2026-05-28-ui-terminologia-finca.md) |
| 2026-05-28 | Superadmin: detalle y gestión de organizaciones | PWA + API | [casos/2026-05-28-superadmin-detalle-organizaciones.md](casos/2026-05-28-superadmin-detalle-organizaciones.md) |
| 2026-05-28 | Estadísticas: filtro único por finca | PWA + API | [casos/2026-05-28-estadisticas-filtro-finca.md](casos/2026-05-28-estadisticas-filtro-finca.md) |
| 2026-05-29 | Modelo Empresa + Fincas (migración y datos) | BD + API + PWA | [casos/2026-05-29-modelo-empresa-fincas.md](casos/2026-05-29-modelo-empresa-fincas.md) |

## Qué documentar aquí

**Sí**

- Bugs en producción o desarrollo y su fix.
- Comportamiento confuso que se aclaró con cambio de código o datos.
- Migraciones manuales, datos inconsistentes post-migración y cómo se repararon.
- Errores de configuración (env, build, licencias) con pasos de recuperación.

**No**

- Features nuevas sin incidente previo (usar `database/docs/` o README del módulo).
- Secretos, contraseñas ni datos personales de clientes.
- Copiar logs enteros con tokens o PII.

## Relación con otra documentación

| Ubicación | Contenido |
|-----------|-----------|
| `database/docs/` | Modelo de datos, planes, licencias (referencia estable) |
| `docs/DEPLOY-RAILWAY.md` | Despliegue |
| `docs/correcciones/` | **Qué falló y cómo se arregló** (evolutivo) |
