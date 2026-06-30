# Superadmin: no se podían editar ni suspender organizaciones

| Campo | Valor |
|-------|--------|
| **Fecha cierre** | 2026-05-28 |
| **Área** | PWA + API |
| **Severidad** | media |
| **Estado** | resuelto |

## Síntoma

En `/superadmin/clients` solo existían:

- Crear organización
- Renovar licencia (sin cambiar plan desde UI)
- Entrar como tenant

No había forma de **renombrar**, **cambiar plan**, **suspender/reactivar** ni ver detalle de una org.

## Causa raíz

La consola superadmin se implementó en fase inicial (alta + renovación + impersonación). Faltaban endpoints y pantalla de detalle; `renewClientLicense` ya aceptaba `plan_id` en API pero la UI no lo exponía.

## Solución aplicada

1. **API**
   - `GET /api/superadmin/clients/:id` — detalle (plan, licencia, admin, conteos)
   - `PATCH /api/superadmin/clients/:id` — `{ name }`
   - `POST /api/superadmin/clients/:id/status` — `{ status: "active" | "suspended" }` (suspende revoca sesiones)
2. **PWA**: `SuperadminClientDetailPage` en `/superadmin/clients/:clientId` con edición, suspensión, renovación con selector de plan.
3. **Auth**: superadmin puede **Entrar** a orgs suspendidas o con licencia vencida (`setSessionActingClient` + `assertSessionClientLicense`).

### Archivos relevantes

- `api/src/services/superadmin.service.js`
- `api/src/routes/superadmin.routes.js`
- `api/src/services/auth.service.js`
- `pwa/src/pages/SuperadminClientDetailPage.jsx`
- `pwa/src/pages/SuperadminClientsPage.jsx`
- `pwa/src/services/superadminApi.js`
- `database/docs/PLANS.md` (rutas actualizadas)

## Verificación

- [ ] Listado → **Administrar** abre detalle.
- [ ] Guardar nombre persiste.
- [ ] Suspender cierra sesiones de usuarios del tenant.
- [ ] Renovar con otro plan actualiza `plan_id` y fechas.
- [ ] **Entrar** funciona con org suspendida (solo superadmin).

## Prevención / notas

Estado `license_expired` lo sigue poniendo el cron; no se asigna manualmente desde UI. Para reactivar org vencida: **Renovar licencia**.

No requirió migración SQL (usa columnas existentes en `clients`).
