# Licencias de cliente (planes y vencimiento)

Este documento describe el modelo de **planes**, **vigencia de licencia por organización (cliente)**, el **cron** de cierre de sesiones y el comportamiento en **login** y **panel de inicio**.

## Resumen

| Componente | Ubicación |
|------------|-----------|
| Migración SQL | `database/migrations/20260521170000_client_license_plans.sql` |
| Cálculo de fechas | `api/src/lib/licenseDates.js` |
| Servicio licencias | `api/src/services/client-license.service.js` |
| Cron 23:59 | `api/src/jobs/license-expiry.cron.js` (arranque en `api/src/index.js`) |
| Alta / renovación superadmin | `api/src/services/superadmin.service.js`, rutas `/api/superadmin/*` |
| Login y sesión | `api/src/services/auth.service.js`, `api/src/middleware/auth.middleware.js` |
| UI superadmin | `pwa/src/pages/SuperadminClientsPage.jsx` |
| Pie de inicio (admin) | `pwa/src/layouts/DashboardShell.jsx` |
| Mensaje login | `pwa/src/pages/Login.jsx` — texto **«Licencia vencida»** |

## Esquema de base de datos

### Tabla `plans` (columnas nuevas)

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `billing_model` | `varchar(32)` | `perpetual`, `trial_days` o `monthly_anchor` |
| `trial_days` | `integer` | Días de demo cuando el modelo es `trial_days` |
| `description` | `text` | Texto visible al superadmin al elegir plan |

### Tabla `clients` (columnas nuevas)

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `license_starts_on` | `date` | Fecha de alta o última renovación |
| `license_expires_on` | `date` | Último día **inclusive** de vigencia |
| `billing_anchor_day` | `smallint` | Día del mes (1–28) para planes `monthly_anchor` |

### Estado del cliente

- `active`: puede operar si la fecha de hoy ≤ `license_expires_on` (o no hay vencimiento).
- `license_expired`: lo fija el cron al vencer; bloquea login y revoca sesiones.

Clientes existentes sin `license_expires_on` se consideran **sin vencimiento** hasta que se renueve o se cree uno nuevo con plan acotado.

## Modelos de facturación (`plans.billing_model`)

### `perpetual`

- No se guarda `license_expires_on` (NULL).
- Uso interno o planes sin caducidad.

### `trial_days` (demo)

- Vencimiento = `license_starts_on` + N días calendario.
- N = `trial_days` del plan, o `trial_days_override` al crear/renovar desde superadmin.
- Ejemplo: inicio `2026-05-01`, 30 días → vence `2026-05-31`.

### `monthly_anchor` (pago mensual)

- Vencimiento = **mismo día del mes siguiente** al inicio/renovación.
- El día se toma de `billing_anchor_day` del cliente (p. ej. 15) o del día de `license_starts_on` si no se indica.
- Si el mes siguiente no tiene ese día (p. ej. 31 → febrero), se usa el **último día del mes** (tope 28 en formularios).

Ejemplo: pago/renovación `2026-04-15`, ancla 15 → vence `2026-05-15`.

## Superadmin: crear y renovar

### Crear organización

`POST /api/superadmin/clients` (CSRF + sesión superadmin)

Campos relevantes:

- `plan_id` (obligatorio)
- `license_starts_on` (opcional, `YYYY-MM-DD`; por defecto hoy en zona configurada)
- `billing_anchor_day` (obligatorio lógico si el plan es `monthly_anchor`, 1–28)
- `trial_days_override` (opcional si el plan es `trial_days`)

La API calcula `license_expires_on` y persiste `billing_anchor_day` cuando aplica.

### Listar planes con características

`GET /api/superadmin/plans` devuelve límites (`max_farms`, `max_lots_per_farm`, usuarios), precio, `billing_model`, `trial_days`, `description` y etiqueta legible `billing_model_label`.

### Renovar licencia

`POST /api/superadmin/clients/:clientId/license/renew`

- Recalcula fechas desde `license_starts_on` (por defecto hoy).
- Pone `status = 'active'`.
- Opcional: cambiar `plan_id`, `billing_anchor_day`, `trial_days_override`.

En el PWA: botón **Renovar licencia** en la lista de organizaciones.

## Cron diario (23:59)

> Nota: en el requerimiento se mencionaba «cors»; la implementación es un **cron** dentro del proceso API (`node-cron`).

- **Horario por defecto:** `59 23 * * *` (23:59 cada día).
- **Zona horaria por defecto:** `America/Costa_Rica` (`LICENSE_TIMEZONE`).
- **Desactivar:** `LICENSE_CRON_ENABLED=0`.

### Qué hace el job

1. Busca clientes `active` con `license_expires_on <= hoy` (fecha en `LICENSE_TIMEZONE`).
2. Actualiza `status` a `license_expired`.
3. Revoca **todas** las sesiones de usuarios de ese `client_id` y sesiones con `acting_client_id` (superadmin dentro del tenant).
4. Registra eventos de auditoría `license_expired` y `license_sessions_revoked`.

Así, el último día de vigencia el usuario puede seguir con sesión hasta las 23:59; después del cron queda bloqueado.

## Login y sesiones activas

### Login

- Si el cliente está `license_expired` o la fecha de hoy es posterior a `license_expires_on`:
  - HTTP **403**
  - `{ "message": "Licencia vencida.", "code": "LICENSE_EXPIRED" }`
- El PWA muestra **«Licencia vencida»** (no credenciales genéricas).

### Requests autenticados (`requireAuth`)

- Misma comprobación sobre el tenant efectivo (usuario normal o superadmin con `acting_client_id`).
- Revoca cookie/sesión y responde 403 con `LICENSE_EXPIRED`.

### Superadmin sin organización seleccionada

- No aplica vencimiento de licencia de tenant.

## Panel de inicio (administradores)

En `GET /api/auth/me` (y tras login) el perfil incluye:

- `licenseExpiresOn`: `YYYY-MM-DD` o `null`
- `licenseExpiresOnDisplay`: `dd-mm-yyyy` para UI
- `licenseValid`: booleano

En el pie del dashboard (`DashboardShell`), si el usuario es **admin del tenant** (`isTenantAdmin`) y hay fecha de vencimiento, se muestra:

**Vencimiento de la licencia: dd-mm-yyyy**

## Variables de entorno (`api/.env`)

```env
# Zona horaria para «hoy» y cron de licencias (IANA)
LICENSE_TIMEZONE=America/Costa_Rica

# Expresión cron (node-cron). Por defecto 23:59 diario
LICENSE_CRON_SCHEDULE=59 23 * * *

# 0 = no registrar el job
LICENSE_CRON_ENABLED=1
```

## Aplicar la migración

Con usuario con permisos en `public` (p. ej. `postgres`):

```bash
cd api
set MIGRATION_DATABASE_URL=postgres://postgres:...@localhost:5432/wardi_cafe
npm run db:migrate
```

Verificación opcional:

```sql
SELECT name, billing_model, trial_days FROM plans;
SELECT name, license_starts_on, license_expires_on, status FROM clients;
```

## Definir planes en SQL (ejemplos)

```sql
-- Demo 30 días
UPDATE plans
SET billing_model = 'trial_days', trial_days = 30,
    description = 'Demostración 30 días desde alta o renovación.'
WHERE name = 'Plan Demo';

-- Mensual, día 15
INSERT INTO plans (name, billing_model, max_farms, max_lots_per_farm,
                   max_users_admin, max_users_operario, price, description)
VALUES (
  'Plan Mensual',
  'monthly_anchor',
  5, 100, 2, 10, 50000,
  'Renovación mensual; vence el mismo día del mes siguiente al pago.'
);
```

## Auditoría

Eventos registrados en el servicio de auditoría:

- `license_expired` — cron marcó cliente vencido
- `license_sessions_revoked` — sesiones cerradas por licencia
- `superadmin_license_renewed` — renovación manual
- `login_failed` con `metadata.reason = 'license_expired'` cuando aplica

## Pruebas manuales sugeridas

1. Migrar y confirmar columnas en `plans` y `clients`.
2. Crear cliente con Plan Demo → comprobar `license_expires_on` ≈ inicio + 30 días.
3. Login como admin del cliente → pie con vencimiento `dd-mm-yyyy`.
4. Forzar vencimiento (`UPDATE clients SET license_expires_on = CURRENT_DATE - 1`) y ejecutar lógica del cron o esperar 23:59 → login muestra «Licencia vencida».
5. Renovar desde superadmin → `status = active`, nueva fecha, login OK.
