# Catálogo de planes (superadmin)

## Pantallas

| Ruta | Función |
|------|---------|
| `/superadmin/clients` | Organizaciones: alta con plan activo, renovar licencia, entrar como tenant |
| `/superadmin/plans` | CRUD de planes + aviso de impacto al editar/inactivar |

## API (`/api/superadmin`, sesión superadmin + CSRF en mutaciones)

| Método | Ruta | Uso |
|--------|------|-----|
| GET | `/plans` | Solo planes `is_active = true` (selector al crear org) |
| GET | `/plans/all` | Todos los planes + columna org. activas |
| GET | `/plans/:id/impact` | Lista de `clients` con `status = active` y ese `plan_id` |
| POST | `/plans` | Crear (`is_active = true`) |
| PATCH | `/plans/:id` | Editar; si hay orgs activas exige `acknowledge_affected_clients: true` |
| POST | `/plans/:id/deactivate` | `is_active = false`; misma confirmación |

Si falta confirmar: **409** `PLAN_IMPACT_NOT_ACKNOWLEDGED` + cuerpo `{ impact: { message, active_clients, ... } }`.

## Efectos al cambiar un plan

- **Límites** (`max_farms`, etc.): las orgs activas con ese `plan_id` los ven al instante (`client-plan-limits.service.js` lee el plan en cada validación).
- **Licencia** (`license_expires_on`): no se recalcula al editar el plan; solo en alta o **Renovar licencia** en Organizaciones.
- **Inactivar plan**: no aparece al crear orgs nuevas; las existentes conservan `plan_id` y su licencia.

## Migración

```bash
cd api
npm run db:migrate
```

Requiere `20260522120000_plans_is_active.sql` y, para licencias, `20260521170000_client_license_plans.sql`.
