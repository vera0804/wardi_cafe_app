# Migración Empresa + Fincas: datos y entorno local

| Campo | Valor |
|-------|--------|
| **Fecha cierre** | 2026-05-29 |
| **Área** | BD + API + Dev local |
| **Severidad** | alta |
| **Estado** | resuelto (con notas) |

## Síntoma

Varios síntomas tras aplicar el modelo nuevo:

1. Menú antiguo **Fincas + Lotes** en puerto **3000** mientras **5173** mostraba la UI nueva.
2. Organizaciones aparecían inactivas o sin acceso tras migración.
3. `npm run db:migrate` fallaba desde shell (credenciales / URL incorrecta).
4. Confusión entre `DATABASE_URL` (`wardi_app`) y usuario `postgres` para migraciones.

## Causa raíz

- **3000** sirve PWA **compilada** en `api/public` (build antigua) + API; **5173** es Vite en caliente con código actual.
- Migración `20260529120000_empresa_fincas_model.sql` aplicada manualmente en pgAdmin; algunas filas quedaron con `is_active = false` en empresas (`farms`).
- `MIGRATION_DATABASE_URL` mal formateada o contraseña distinta a la del rol de app.

## Solución aplicada

1. **Migración manual** en pgAdmin + registro en `schema_migrations`.
2. **Reactivar empresas** afectadas (`farms.is_active = true` donde correspondía).
3. **Desarrollo**: usar `npm run dev:pwa` (5173) para UI nueva; o `npm run build` + reiniciar API para ver cambios en 3000.
4. **Variables**: `DATABASE_URL` → rol `wardi_app`; migraciones con URL de superusuario solo si el runner lo exige (documentar en `.env` local, sin commitear secretos).

### Archivos relevantes

- `database/migrations/20260529120000_empresa_fincas_model.sql`
- `api/src/services/tenant-farm.service.js`, `farms.service.js`, `lots.service.js`
- `pwa/src/layouts/dashboardMenuData.js` (Empresa + Fincas)

## Verificación

- [ ] Menú: **Empresa** + **Fincas** (no «Lotes») en build actual.
- [ ] `SELECT id, name, is_active FROM farms WHERE client_id = '…'` — empresa activa.
- [ ] Altas operativas solo con `cost_scope = 'lot'`.
- [ ] `schema_migrations` incluye `20260529120000_empresa_fincas_model.sql`.

## Prevención / notas

- Tras cambios PWA en producción/Railway: **`npm run build`** en el pipeline (ya documentado en `docs/DEPLOY-RAILWAY.md`).
- Cualquier corrección post-migración conviene registrar aquí con SQL exacto usado (sin credenciales).
- Si el runner de migraciones falla, preferir aplicar SQL en pgAdmin y **registrar** la versión en `schema_migrations` para no re-ejecutar.
