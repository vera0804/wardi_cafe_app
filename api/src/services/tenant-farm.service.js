const { pool } = require('../db');

/**
 * Finca canónica (empresa) activa del cliente.
 */
async function getCanonicalFarmForClient(clientId, { db } = {}) {
  const cx = db || pool;
  const res = await cx.query(
    `SELECT id, name, area_ha, area_ha_manual, is_active
     FROM farms
     WHERE client_id = $1 AND is_active = true
     ORDER BY created_at ASC, id ASC
     LIMIT 1`,
    [clientId]
  );
  return res.rows[0] || null;
}

async function assertCanCreateFarm(clientId) {
  const existing = await getCanonicalFarmForClient(clientId);
  if (existing) {
    const err = new Error(
      'Ya existe la ficha de empresa para este cliente. Edítela en el módulo Empresa.'
    );
    err.status = 409;
    throw err;
  }
}

async function assertEmpresaNotInactivated() {
  const err = new Error('No se puede inactivar la ficha de empresa del cliente.');
  err.status = 409;
  throw err;
}

/**
 * Si area_ha_manual = false, suma áreas de fincas (lots) activas con area_ha > 0.
 */
async function recalculateEmpresaAreaIfAuto(clientId, { db } = {}) {
  const cx = db || pool;
  const farmRes = await cx.query(
    `SELECT id, area_ha_manual
     FROM farms
     WHERE client_id = $1 AND is_active = true
     ORDER BY created_at ASC
     LIMIT 1`,
    [clientId]
  );
  const farm = farmRes.rows[0];
  if (!farm || farm.area_ha_manual) return;

  const sumRes = await cx.query(
    `SELECT COUNT(*)::int AS total,
            COUNT(*) FILTER (WHERE area_ha IS NOT NULL AND area_ha > 0)::int AS with_area,
            COALESCE(SUM(area_ha) FILTER (WHERE area_ha IS NOT NULL AND area_ha > 0), 0)::numeric AS sum_ha
     FROM lots
     WHERE client_id = $1 AND is_active = true`,
    [clientId]
  );
  const { total, with_area, sum_ha } = sumRes.rows[0] || {};
  if (!total || Number(total) === 0) return;
  if (Number(with_area) !== Number(total)) return;

  await cx.query(
    `UPDATE farms SET area_ha = $2, updated_at = NOW() WHERE id = $1`,
    [farm.id, sum_ha]
  );
}

async function createEmpresaFarmForClient({ db, clientId, name, userId }) {
  const cx = db || pool;
  const res = await cx.query(
    `INSERT INTO farms (
       name, client_id, labor_allocation_mode, area_ha_manual,
       created_by_user_id, updated_by_user_id
     )
     VALUES ($1, $2, 'manual', false, $3, $3)
     RETURNING id`,
    [name, clientId, userId]
  );
  return res.rows[0]?.id || null;
}

module.exports = {
  getCanonicalFarmForClient,
  assertCanCreateFarm,
  assertEmpresaNotInactivated,
  recalculateEmpresaAreaIfAuto,
  createEmpresaFarmForClient,
};
