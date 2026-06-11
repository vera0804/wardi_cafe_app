# Base de datos (PostgreSQL)

## Migraciones reproducibles

- **`20260521170000_client_license_plans.sql`** — planes con `billing_model` / `trial_days` / `description` y clientes con `license_starts_on`, `license_expires_on`, `billing_anchor_day`. Ver guía completa en [`docs/LICENSE.md`](docs/LICENSE.md).
- **`20260522120000_plans_is_active.sql`** — `plans.is_active` para catálogo editable (CRUD superadmin en `/superadmin/plans`). Ver [`docs/PLANS.md`](docs/PLANS.md).
- **`20260529120000_empresa_fincas_model.sql`** — modelo Empresa (`farms` ×1 con datos del dueño) + Fincas operativas (`lots` con ubicación CR); fusión de fincas duplicadas por cliente; auto-`max_farms = 1` en planes.
- `20260521130000_coffee_varieties_seed.sql` reemplaza el catálogo de variedades de aguacate por **15 variedades de café** habituales en Costa Rica y vacía los vínculos lote↔variedad (hay que reasignar variedades en **Lotes** tras migrar).
- Los archivos están en `database/migrations/` y se aplican **en orden léxico** (`*.sql`).
- El runner registra cada archivo ejecutado en `public.schema_migrations`.
- Ejecutar desde la raíz del monorepo (requiere haber ejecutado `npm install` en `./api` para `pg`):

```bash
set DATABASE_URL=postgres://...
node database/run-migrations.js
```

O con npm desde la raíz:

```bash
npm run db:migrate
```

## Historial antes del runner

Si ya aplicaste a mano `20260515150000_users_id_document_per_client.sql`, inserta el registro **una vez** antes de usar el runner, o deja que el archivo sea idempotentemente seguro (`IF NOT EXISTS` / `DROP IF EXISTS`). Si el SQL falla al repetirse, marca la fila:

```sql
INSERT INTO public.schema_migrations (filename)
VALUES ('20260515150000_users_id_document_per_client.sql')
ON CONFLICT DO NOTHING;
```

## Row Level Security (RLS)

1. **`20260718100000_app_tenant_session_function.sql`** define `public.app_current_tenant_id()` leyendo el GUC `app.tenant_id`.
2. **`20260718101000_rls_client_id_tables_dynamic.sql`** activa RLS en tablas públicas que tienen `client_id UUID`, excluyendo `sessions`, `users`, `clients`, `schema_migrations`.
3. **`20260521160000_rls_coffee_production_payroll.sql`** añade RLS en `coffee_lot_production` y tablas hijas de planilla sin `client_id`:
   - `fixed_payroll` (vía `workers.client_id`)
   - `fixed_payroll_allocations` (vía `fixed_payroll` + `lots.client_id`)
   - `payroll_slip_lot_allocations` (vía `payroll_slips.client_id` + `lots.client_id`)

Las tablas cuya columna `client_id` **no sea tipo UUID** no son incluidas automáticamente (necesitan políticas manuales o cambio de tipo antes de confiar en esta migración).

**Planilla sin RLS en este parche:** `payroll_periods` y `payroll_settings` (sin `client_id`; calendario/reglas compartidas). `payroll_slips` queda cubierta por la migración dinámica si ya se aplicó.

Los **superusuarios** ignoran RLS: el comportamiento actual de desarrollo típico (conexión `postgres`) no cambia.

Para aplicar políticas:

- Crear rol de aplicación **sin** SUPERUSER/BYPASSRLS.
- Dentro de **cada** transacción de negocio del tenant ejecutar:

  ```sql
  SELECT set_config('app.tenant_id', '<uuid-del-tenant>', true);
  ```

  El tercer parámetro `true` equivale a `SET LOCAL` (no contamina el pool de `pg`).
- Opcionalmente usar el helper `api/src/db/tenantTxn.js`:

  ```javascript
  const { withTenantTransaction } = require('./db/tenantTxn');
  await withTenantTransaction(clientId, (c) => c.query(`SELECT …`, [...]));
  ```

**Tablas especiales omitidas:**

- **`users`** / **`clients`**: requieren políticas distintas (superadmin, cambio de org); tratarlas en migración dedicada antes de usar un rol restrictivo global.

## Rol de aplicación + RLS en runtime (API)

1. Crear rol (una vez, como superuser):

   ```bash
   set MIGRATION_DATABASE_URL=postgres://postgres:...@localhost:5432/tu_db
   set PG_APP_PASSWORD=contraseña_larga_segura
   node database/setup-app-role.js
   ```

2. Aplicar migración de grants (si no corrió en `db:migrate`):

   ```bash
   npm run db:migrate
   ```

3. En **producción**, `api/.env` debe usar `DATABASE_URL` con `wardi_app` (no `postgres` superuser).

4. La API fija `app.tenant_id` automáticamente en cada request con organización activa (`requireEffectiveClient` → `bindTenantRlsContext`). Desactivar solo para depuración: `TENANT_RLS_REQUEST_SCOPE=0`.

5. Verificar:

   ```bash
   node database/verify-migrations.js
   ```

   Con `wardi_app` en `DATABASE_URL`, `is_superuser` debe ser **false** y RLS filtrará filas sin `client_id` coincidente.

### BCCR / SSRF (API)

Variables relevantes para `api/src/services/bccr-exchange.service.js` (REST JSON + Bearer, no SOAP):

| Variable             | Rol |
|----------------------|-----|
| `BCCR_API_URL`       | Base HTTPS del API público SDDE (ej. `https://apim.bccr.fi.cr/SDDE/api/Bccr.Ge.SDDE.Publico.Indicadores.API`). |
| `BCCR_TOKEN`         | Bearer token (header `Authorization`). |
| `BCCR_INDICADOR_COMPRA` / `BCCR_INDICADOR_VENTA` | Códigos 317 / 318 por defecto. |
| `BCCR_ALLOWED_HOSTS` | Lista separada por comas **opcional**. Si falta: `apim.bccr.fi.cr`. |
