# Estadísticas: filtro dual finca + lote obsoleto

| Campo | Valor |
|-------|--------|
| **Fecha cierre** | 2026-05-28 |
| **Área** | PWA + API |
| **Severidad** | media |
| **Estado** | resuelto |

## Síntoma

Tras adoptar el modelo **Empresa + Fincas**, el módulo de estadísticas seguía mostrando dos filtros territoriales:

1. **Finca** (tabla `farms`, empresa del tenant)
2. **Lote** (tabla `lots`, finca operativa)

Las tablas duplicaban agregados «por lote» y «por finca (farm)», confundiendo con la nomenclatura nueva donde solo existen **fincas operativas** (`lots`).

## Causa raíz

El módulo stats se diseñó con el modelo antiguo finca → lotes anidados. La UI y `parseDateRange` en API aceptaban `farm_id` y `lot_id`; muchas pantallas mostraban columnas Finca + Lote.

## Solución aplicada

1. **PWA**: un solo selector **Finca** que lista `/api/lots`; eliminado selector de empresa (`farms`).
2. **API**: `parseDateRange` ignora `farm_id`; filtra solo por `lot_id`.
3. **UI stats**: textos y tablas alineados a una columna **Finca** (`lot_name`); eliminadas secciones agregadas redundantes por `farm_id`.

### Archivos relevantes

- `pwa/src/pages/stats/StatsFiltersBar.jsx`
- `pwa/src/pages/stats/useStatsOverview.js`
- `pwa/src/services/statsApi.js`
- `pwa/src/pages/stats/*Page.jsx`, `statsFormat.jsx`
- `api/src/services/stats.service.js` (`parseDateRange`, `filters` en overview)

## Verificación

- [ ] En `/stats/*`, un solo filtro **Finca** con listado de fincas operativas.
- [ ] Al elegir finca, la línea de periodo muestra «Finca filtrada» (no «Lote filtrado»).
- [ ] Tablas de costos/rentabilidad/producción sin columna «Lote» duplicada.
- [ ] Request a overview solo envía `lot_id` (no `farm_id`).

## Prevención / notas

Los nombres de campos JSON (`rentability_lots`, `yield_by_lot`) siguen en API por compatibilidad; en UI se leen como fincas. Renombrar API sería cambio breaking opcional.
