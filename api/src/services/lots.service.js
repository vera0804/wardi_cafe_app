const { pool } = require('../db');
const { assertLotCapacityOnFarm } = require('./client-plan-limits.service');
const { formatLocationDisplay, resolveCrGeo } = require('./geo-cr.service');
const {
  getCanonicalFarmForClient,
  recalculateEmpresaAreaIfAuto,
} = require('./tenant-farm.service');

const LOT_SELECT = `
  SELECT l.id, l.farm_id, f.name AS farm_name, l.name, l.area_ha, l.plant_count,
         l.province_id, l.canton_id, l.district_id, l.community,
         p.name AS province_name,
         c.name AS canton_name,
         d.name AS district_name,
         l.is_active, l.deactivated_at, l.created_at, l.updated_at
  FROM lots l
  JOIN farms f ON f.id = l.farm_id
  LEFT JOIN provinces p ON p.id = l.province_id
  LEFT JOIN cantons c ON c.id = l.canton_id
  LEFT JOIN districts d ON d.id = l.district_id`;

function mapLotRow(row, varieties = []) {
  return {
    id: row.id,
    farm_id: row.farm_id,
    farm_name: row.farm_name,
    name: row.name,
    area_ha: row.area_ha,
    plant_count: row.plant_count,
    province_id: row.province_id,
    canton_id: row.canton_id,
    district_id: row.district_id,
    community: row.community,
    province_name: row.province_name,
    canton_name: row.canton_name,
    district_name: row.district_name,
    location_display: formatLocationDisplay({
      provinceName: row.province_name,
      cantonName: row.canton_name,
      districtName: row.district_name,
      community: row.community,
    }),
    is_active: row.is_active,
    deactivated_at: row.deactivated_at,
    created_at: row.created_at,
    updated_at: row.updated_at,
    varieties,
    variety_ids: varieties.map((v) => v.id),
  };
}

function normalizeName(value) {
  const cleanName = String(value || '').trim();
  if (!cleanName) {
    const err = new Error('El nombre de la finca es obligatorio.');
    err.status = 400;
    throw err;
  }
  return cleanName;
}

function normalizeArea(value, { required = false } = {}) {
  if (value === undefined && !required) return undefined;
  if (value === null || value === '') {
    if (required) {
      const err = new Error('El área (ha) es obligatoria.');
      err.status = 400;
      throw err;
    }
    return null;
  }
  const n = Number(value);
  if (!Number.isFinite(n) || n <= 0) {
    const err = new Error('El área (ha) debe ser un número mayor que 0.');
    err.status = 400;
    throw err;
  }
  return n;
}

function normalizePlantCount(value) {
  if (value === undefined) return undefined;
  if (value === null || value === '') return 0;
  const n = Number(value);
  if (!Number.isInteger(n) || n < 0) {
    const err = new Error('plant_count debe ser un entero mayor o igual a 0.');
    err.status = 400;
    throw err;
  }
  return n;
}

function normalizeVarietyIds(value) {
  if (value === undefined) return undefined;
  if (!Array.isArray(value)) {
    const err = new Error('variety_ids debe ser un arreglo.');
    err.status = 400;
    throw err;
  }
  const unique = [...new Set(value.map((id) => String(id || '').trim()).filter(Boolean))];
  return unique;
}

async function assertUniqueLotNameByClient({ db, clientId, name, excludeLotId = null }) {
  const cx = db || pool;
  const res = await cx.query(
    `SELECT id
     FROM lots
     WHERE client_id = $1
       AND lower(trim(name)) = lower(trim($2))
       AND ($3::uuid IS NULL OR id <> $3::uuid)
     LIMIT 1`,
    [clientId, name, excludeLotId]
  );
  if (res.rows[0]) {
    const err = new Error('Ya existe una finca con ese nombre.');
    err.status = 409;
    throw err;
  }
}

async function assertValidVarieties(varietyIds) {
  if (!varietyIds || varietyIds.length === 0) return;
  const res = await pool.query(
    `SELECT id
     FROM coffee_varieties
     WHERE id = ANY($1::uuid[])
       AND is_active = true`,
    [varietyIds]
  );
  if (res.rows.length !== varietyIds.length) {
    const err = new Error('Una o más variedades no son válidas o están inactivas.');
    err.status = 400;
    throw err;
  }
}

async function replaceLotVarieties({ db, lotId, userId, varietyIds }) {
  if (varietyIds === undefined) return;
  await db.query(`DELETE FROM lot_coffee_varieties WHERE lot_id = $1`, [lotId]);
  if (!varietyIds.length) return;
  await db.query(
    `INSERT INTO lot_coffee_varieties (lot_id, coffee_variety_id, created_by_user_id, updated_by_user_id)
     SELECT $1, v.id, $2, $2
     FROM unnest($3::uuid[]) AS v(id)`,
    [lotId, userId, varietyIds]
  );
}

async function getVarietiesByLotIds(lotIds) {
  if (!lotIds.length) return new Map();
  const res = await pool.query(
    `SELECT lcv.lot_id,
            cv.id,
            COALESCE(NULLIF(trim(cv.display_name), ''), cv.name) AS name
     FROM lot_coffee_varieties lcv
     JOIN coffee_varieties cv ON cv.id = lcv.coffee_variety_id
     WHERE lcv.lot_id = ANY($1::uuid[])
       AND lcv.is_active = true
     ORDER BY name ASC`,
    [lotIds]
  );
  const map = new Map();
  for (const row of res.rows) {
    if (!map.has(row.lot_id)) map.set(row.lot_id, []);
    map.get(row.lot_id).push({ id: row.id, name: row.name });
  }
  return map;
}

async function listLots({ clientId, farmId, includeInactive = false }) {
  const res = await pool.query(
    `${LOT_SELECT}
     WHERE l.client_id = $1
       AND ($2::uuid IS NULL OR l.farm_id = $2::uuid)
       AND ($3::boolean = true OR l.is_active = true)
     ORDER BY l.is_active DESC, l.name ASC`,
    [clientId, farmId || null, includeInactive]
  );
  const lots = res.rows;
  const byLot = await getVarietiesByLotIds(lots.map((l) => l.id));
  return lots.map((lot) => mapLotRow(lot, byLot.get(lot.id) || []));
}

async function getLotById({ lotId, clientId }) {
  const res = await pool.query(
    `${LOT_SELECT}
     WHERE l.id = $1 AND l.client_id = $2`,
    [lotId, clientId]
  );
  const lot = res.rows[0] || null;
  if (!lot) return null;
  const byLot = await getVarietiesByLotIds([lot.id]);
  return mapLotRow(lot, byLot.get(lot.id) || []);
}

async function resolveCanonicalFarmId({ db, clientId, farmId }) {
  const cx = db || pool;
  if (farmId) {
    const farmRes = await cx.query(
      `SELECT id FROM farms WHERE id = $1 AND client_id = $2 AND is_active = true`,
      [farmId, clientId]
    );
    if (!farmRes.rows[0]) {
      const err = new Error('La empresa no existe o está inactiva.');
      err.status = 409;
      throw err;
    }
    return farmRes.rows[0].id;
  }
  const canonical = await getCanonicalFarmForClient(clientId, { db: cx });
  if (!canonical) {
    const err = new Error('No hay ficha de empresa configurada. Contacte al administrador.');
    err.status = 409;
    throw err;
  }
  return canonical.id;
}

async function createLot({
  clientId,
  userId,
  farmId,
  name,
  areaHa,
  plantCount,
  varietyIds,
  provinceId,
  cantonId,
  districtId,
  community,
}) {
  const cleanName = normalizeName(name);
  const cleanArea = normalizeArea(areaHa);
  const cleanPlantCount = normalizePlantCount(plantCount);
  const cleanVarietyIds = normalizeVarietyIds(varietyIds) || [];

  const geo = await resolveCrGeo({
    provinceId,
    cantonId,
    districtId,
    community,
    requireProvince: true,
  });

  const db = await pool.connect();
  try {
    await db.query('BEGIN');
    const cleanFarmId = await resolveCanonicalFarmId({ db, clientId, farmId });

    await db.query(
      `SELECT id FROM farms WHERE id = $1 AND client_id = $2 FOR UPDATE`,
      [cleanFarmId, clientId]
    );

    await assertUniqueLotNameByClient({ db, clientId, name: cleanName });
    await assertValidVarieties(cleanVarietyIds);
    await assertLotCapacityOnFarm({ db, clientId, farmId: cleanFarmId, excludeLotId: null });

    const res = await db.query(
      `INSERT INTO lots (
         farm_id, name, area_ha, plant_count,
         province_id, canton_id, district_id, community,
         client_id, created_by_user_id, updated_by_user_id
       )
       VALUES ($1, $2, $3, COALESCE($4, 0), $5, $6, $7, $8, $9, $10, $10)
       RETURNING id`,
      [
        cleanFarmId,
        cleanName,
        cleanArea,
        cleanPlantCount,
        geo.provinceId,
        geo.cantonId,
        geo.districtId,
        geo.community,
        clientId,
        userId,
      ]
    );
    const lotId = res.rows[0].id;
    await replaceLotVarieties({ db, lotId, userId, varietyIds: cleanVarietyIds });
    await recalculateEmpresaAreaIfAuto(clientId, { db });
    await db.query('COMMIT');
    return getLotById({ lotId, clientId });
  } catch (e) {
    await db.query('ROLLBACK');
    if (e.code === '23505') {
      const err = new Error('Ya existe una finca con ese nombre.');
      err.status = 409;
      throw err;
    }
    throw e;
  } finally {
    db.release();
  }
}

async function updateLot({
  lotId,
  clientId,
  userId,
  name,
  areaHa,
  plantCount,
  varietyIds,
  provinceId,
  cantonId,
  districtId,
  community,
}) {
  const current = await getLotById({ lotId, clientId });
  if (!current) return null;

  const nextName = name !== undefined ? normalizeName(name) : current.name;
  const nextArea = areaHa !== undefined ? normalizeArea(areaHa) : undefined;
  const nextPlantCount = plantCount !== undefined ? normalizePlantCount(plantCount) : undefined;
  const nextVarietyIds = normalizeVarietyIds(varietyIds);

  const fields = [];
  const values = [];
  let idx = 1;

  if (name !== undefined) {
    fields.push(`name = $${idx++}`);
    values.push(nextName);
  }
  if (areaHa !== undefined) {
    fields.push(`area_ha = $${idx++}`);
    values.push(nextArea);
  }
  if (plantCount !== undefined) {
    fields.push(`plant_count = $${idx++}`);
    values.push(nextPlantCount);
  }

  const geoTouched =
    provinceId !== undefined ||
    cantonId !== undefined ||
    districtId !== undefined ||
    community !== undefined;

  if (geoTouched) {
    const geo = await resolveCrGeo({
      provinceId: provinceId !== undefined ? provinceId : current.province_id,
      cantonId: cantonId !== undefined ? cantonId : current.canton_id,
      districtId: districtId !== undefined ? districtId : current.district_id,
      community: community !== undefined ? community : current.community,
      requireProvince: true,
    });
    fields.push(`province_id = $${idx++}`);
    values.push(geo.provinceId);
    fields.push(`canton_id = $${idx++}`);
    values.push(geo.cantonId);
    fields.push(`district_id = $${idx++}`);
    values.push(geo.districtId);
    fields.push(`community = $${idx++}`);
    values.push(geo.community);
  }

  const db = await pool.connect();
  try {
    await db.query('BEGIN');
    await assertUniqueLotNameByClient({
      db,
      clientId,
      name: nextName,
      excludeLotId: lotId,
    });
    if (nextVarietyIds !== undefined) {
      await assertValidVarieties(nextVarietyIds);
    }
    if (fields.length > 0) {
      fields.push(`updated_by_user_id = $${idx++}`);
      values.push(userId);
      fields.push(`updated_at = NOW()`);
      values.push(lotId);
      values.push(clientId);
      await db.query(
        `UPDATE lots
         SET ${fields.join(', ')}
         WHERE id = $${idx++}
           AND client_id = $${idx}`,
        values
      );
    }

    await replaceLotVarieties({ db, lotId, userId, varietyIds: nextVarietyIds });
    await recalculateEmpresaAreaIfAuto(clientId, { db });
    await db.query('COMMIT');
    return getLotById({ lotId, clientId });
  } catch (e) {
    await db.query('ROLLBACK');
    if (e.code === '23505') {
      const err = new Error('Ya existe una finca con ese nombre.');
      err.status = 409;
      throw err;
    }
    throw e;
  } finally {
    db.release();
  }
}

async function setLotActive({ lotId, clientId, userId, isActive }) {
  const want = !!isActive;
  const db = await pool.connect();
  try {
    await db.query('BEGIN');
    const lotRes = await db.query(
      `SELECT l.id, l.farm_id, l.is_active
       FROM lots l
       WHERE l.id = $1 AND l.client_id = $2
       FOR UPDATE`,
      [lotId, clientId]
    );
    const lotRow = lotRes.rows[0];
    if (!lotRow) {
      await db.query('ROLLBACK');
      return null;
    }

    if (want) {
      const farmRes = await db.query(
        `SELECT id FROM farms
         WHERE id = $1 AND client_id = $2 AND is_active = true
         FOR UPDATE`,
        [lotRow.farm_id, clientId]
      );
      if (!farmRes.rows[0]) {
        const err = new Error('No se puede activar la finca porque la empresa está inactiva.');
        err.status = 409;
        throw err;
      }
      await assertLotCapacityOnFarm({
        db,
        clientId,
        farmId: lotRow.farm_id,
        excludeLotId: lotId,
      });
    }

    const res = await db.query(
      `UPDATE lots
       SET is_active = $3,
           deactivated_at = CASE WHEN $3::boolean THEN NULL ELSE NOW() END,
           updated_by_user_id = $4,
           updated_at = NOW()
       WHERE id = $1 AND client_id = $2
       RETURNING id`,
      [lotId, clientId, want, userId]
    );
    if (!res.rows[0]) {
      await db.query('ROLLBACK');
      return null;
    }
    await recalculateEmpresaAreaIfAuto(clientId, { db });
    await db.query('COMMIT');
    return getLotById({ lotId, clientId });
  } catch (e) {
    await db.query('ROLLBACK');
    throw e;
  } finally {
    db.release();
  }
}

async function listActiveFarmsForLots({ clientId }) {
  const res = await pool.query(
    `SELECT id, name, labor_allocation_mode
     FROM farms
     WHERE client_id = $1 AND is_active = true
     ORDER BY created_at ASC
     LIMIT 1`,
    [clientId]
  );
  return res.rows;
}

async function listActiveVarieties() {
  const res = await pool.query(
    `SELECT id, COALESCE(NULLIF(trim(display_name), ''), name) AS name
     FROM coffee_varieties
     WHERE is_active = true
     ORDER BY name ASC`
  );
  return res.rows;
}

module.exports = {
  listLots,
  getLotById,
  createLot,
  updateLot,
  setLotActive,
  listActiveFarmsForLots,
  listActiveVarieties,
};
