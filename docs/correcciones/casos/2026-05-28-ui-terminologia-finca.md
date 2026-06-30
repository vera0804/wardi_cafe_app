# UI y mensajes API aún decían «lote» / «lotes»

| Campo | Valor |
|-------|--------|
| **Fecha cierre** | 2026-05-28 |
| **Área** | PWA + API (mensajes al usuario) |
| **Severidad** | baja |
| **Estado** | resuelto |

## Síntoma

Tras el cambio de modelo **Empresa + Fincas**, varias pantallas, meta tags y errores de API seguían usando «lote», «lotes» o filtros duales finca/lote en copy visible.

Ejemplos detectados:

- Planilla: «Prorrateo por lote», botón «Lotes»
- Cosecha: «Cargando lotes…», columna «Lote»
- Inventario: «capa (lote)» en movimientos (ambiguo con finca operativa)
- `index.html` / manifest PWA: «lotes» en la descripción
- Errores API: «Lote no encontrado…» en rutas usadas por `LotsPage` (fincas)

## Causa raíz

Refactor de producto incompleto en textos; rutas internas (`/registro/lote`, `lot_id`) se mantuvieron pero las etiquetas visibles no se actualizaron en bloque.

## Solución aplicada

Revisión con búsqueda `lote` en `pwa/` y mensajes `Error(...)` / `message:` en `api/src` expuestos al cliente.

- Operativo → **finca**
- Empresa (tenant) → **empresa** donde correspondía
- Inventario (capas FEFO) → **capa** sin «(lote)»

### Qué **no** se cambió (no visible)

- URLs: `/expenses/registro/lote`
- IDs internos: `reg-lote`, `kind === 'lote'`
- Nombres de componentes: `LotExpensesPage.jsx`
- Columnas/tablas SQL: `lots`, `lot_id`

### Archivos relevantes (muestra)

- `pwa/src/pages/payroll/PayrollCalculationPage.jsx`
- `pwa/src/pages/settings/HarvestEstimatesSettingsSection.jsx`
- `pwa/src/pages/InventoryMovementsTab.jsx`
- `pwa/index.html`, `pwa/vite.config.js`
- `api/src/routes/lots.routes.js`
- `api/src/services/stats.service.js` (notas del overview)
- Varios `*.service.js` con mensajes de validación

## Verificación

```bash
# Desde la raíz del repo — no debe haber "lote" en strings visibles de pwa (quedan rutas/código interno)
rg -i lote pwa/src --glob '*.jsx' --glob '*.js'
```

Revisar manualmente que los matches restantes sean rutas, props o comentarios, no texto de pantalla.

- [ ] Planilla, cosecha, stats, gastos muestran **finca**
- [ ] Errores al guardar finca dicen «Finca no encontrada…»

## Prevención / notas

Al tocar copy, usar glosario:

| BD / código | UI |
|-------------|-----|
| `farms` | Empresa |
| `lots` | Finca |
| `inventory_layers` | Capa (inventario) |

Plantilla de revisión: grep `lote` antes de merge en módulos operativos.
