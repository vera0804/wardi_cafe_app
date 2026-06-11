const { pool } = require('../db');
const { formatLocationDisplay, resolveCrGeo, normalizeNullableText } = require('./geo-cr.service');
const {
  assertCanCreateFarm,
  assertEmpresaNotInactivated,
  recalculateEmpresaAreaIfAuto,
} = require('./tenant-farm.service');

const VALID_LABOR_MODES = new Set(['area', 'manual']);
const VALID_OWNER_ID_TYPES = new Set(['nacional', 'extranjero']);
const DEFAULT_LABOR_MODE = 'manual';

const FARM_SELECT = `
  SELECT f.id, f.name, f.area_ha, f.area_ha_manual, f.labor_allocation_mode,
         f.owner_name, f.owner_id_type, f.owner_id_number,
         f.legal_name, f.legal_id_number, f.phone, f.address,
         f.province_id, f.canton_id, f.district_id, f.community,
         p.name AS province_name,
         c.name AS canton_name,
         d.name AS district_name,
         f.is_active, f.deactivated_at, f.created_at, f.updated_at
  FROM farms f
  LEFT JOIN provinces p ON p.id = f.province_id
  LEFT JOIN cantons c ON c.id = f.canton_id
  LEFT JOIN districts d ON d.id = f.district_id`;

function mapFarmRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    area_ha: row.area_ha,
    area_ha_manual: row.area_ha_manual,
    labor_allocation_mode: row.labor_allocation_mode,
    owner_name: row.owner_name,
    owner_id_type: row.owner_id_type,
    owner_id_number: row.owner_id_number,
    legal_name: row.legal_name,
    legal_id_number: row.legal_id_number,
    phone: row.phone,
    address: row.address,
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
  };
}

function normalizeArea(value) {
  if (value === undefined) return undefined;
  if (value === null || value === '') return null;
  const n = Number(value);
  if (!Number.isFinite(n) || n < 0) {
    const err = new Error('El área (ha) debe ser un número mayor o igual a 0.');
    err.status = 400;
    throw err;
  }
  return n;
}

function normalizeLaborMode(value, { required = false } = {}) {
  if (value === undefined && !required) return undefined;
  const v = String(value || '').trim().toLowerCase();
  if (!VALID_LABOR_MODES.has(v)) {
    const err = new Error('labor_allocation_mode debe ser "area" o "manual".');
    err.status = 400;
    throw err;
  }
  return v;
}

function normalizeOwnerIdType(value) {
  if (value === undefined) return undefined;
  if (value === null || value === '') return null;
  const v = String(value).trim().toLowerCase();
  if (!VALID_OWNER_ID_TYPES.has(v)) {
    const err = new Error('owner_id_type debe ser "nacional" o "extranjero".');
    err.status = 400;
    throw err;
  }
  return v;
}

async function listFarms({ clientId, includeInactive = false }) {
  const res = await pool.query(
    `${FARM_SELECT}
     WHERE f.client_id = $1
       AND ($2::boolean = true OR f.is_active = true)
     ORDER BY f.is_active DESC, f.created_at ASC
     LIMIT 1`,
    [clientId, includeInactive]
  );
  return res.rows.map(mapFarmRow);
}

async function createFarm({
  clientId,
  userId,
  name,
  provinceId,
  cantonId,
  districtId,
  community,
  areaHa,
  laborAllocationMode,
}) {
  await assertCanCreateFarm(clientId);

  const cleanName = String(name || '').trim();
  if (!cleanName) {
    const err = new Error('El nombre de la empresa es obligatorio.');
    err.status = 400;
    throw err;
  }
  const cleanArea = areaHa === undefined ? 0 : normalizeArea(areaHa);
  const cleanMode =
    laborAllocationMode === undefined
      ? DEFAULT_LABOR_MODE
      : normalizeLaborMode(laborAllocationMode, { required: true });

  const geo = await resolveCrGeo({
    provinceId,
    cantonId,
    districtId,
    community,
    requireProvince: false,
  });

  const res = await pool.query(
    `INSERT INTO farms (
        name, province_id, canton_id, district_id, community,
        area_ha, area_ha_manual, labor_allocation_mode, client_id,
        created_by_user_id, updated_by_user_id
     )
     VALUES ($1, $2, $3, $4, $5, $6, false, $7, $8, $9, $9)
     RETURNING id`,
    [
      cleanName,
      geo.provinceId ?? null,
      geo.cantonId ?? null,
      geo.districtId ?? null,
      geo.community ?? null,
      cleanArea ?? 0,
      cleanMode,
      clientId,
      userId,
    ]
  );
  const farmId = res.rows[0]?.id;
  const loaded = await pool.query(`${FARM_SELECT} WHERE f.id = $1 AND f.client_id = $2`, [
    farmId,
    clientId,
  ]);
  return mapFarmRow(loaded.rows[0]);
}

async function updateFarm({
  farmId,
  clientId,
  userId,
  name,
  provinceId,
  cantonId,
  districtId,
  community,
  areaHa,
  areaHaManual,
  recalculateAreaFromLots,
  laborAllocationMode,
  ownerName,
  ownerIdType,
  ownerIdNumber,
  legalName,
  legalIdNumber,
  phone,
  address,
}) {
  const fields = [];
  const values = [];
  let idx = 1;

  if (name !== undefined) {
    const cleanName = String(name || '').trim();
    if (!cleanName) {
      const err = new Error('El nombre de la empresa es obligatorio.');
      err.status = 400;
      throw err;
    }
    fields.push(`name = $${idx++}`);
    values.push(cleanName);
  }

  const geoTouched =
    provinceId !== undefined ||
    cantonId !== undefined ||
    districtId !== undefined ||
    community !== undefined;

  if (geoTouched) {
    const geo = await resolveCrGeo({
      provinceId,
      cantonId,
      districtId,
      community,
      requireProvince: false,
    });
    fields.push(`province_id = $${idx++}`);
    values.push(geo.provinceId ?? null);
    fields.push(`canton_id = $${idx++}`);
    values.push(geo.cantonId ?? null);
    fields.push(`district_id = $${idx++}`);
    values.push(geo.districtId ?? null);
    fields.push(`community = $${idx++}`);
    values.push(geo.community ?? null);
  }

  if (recalculateAreaFromLots === true) {
    fields.push(`area_ha_manual = $${idx++}`);
    values.push(false);
  } else if (areaHaManual !== undefined) {
    fields.push(`area_ha_manual = $${idx++}`);
    values.push(!!areaHaManual);
  }

  if (areaHa !== undefined) {
    fields.push(`area_ha = $${idx++}`);
    values.push(normalizeArea(areaHa));
    if (areaHaManual === undefined && recalculateAreaFromLots !== true) {
      fields.push(`area_ha_manual = $${idx++}`);
      values.push(true);
    }
  }

  if (laborAllocationMode !== undefined) {
    fields.push(`labor_allocation_mode = $${idx++}`);
    values.push(normalizeLaborMode(laborAllocationMode, { required: true }));
  }

  if (ownerName !== undefined) {
    fields.push(`owner_name = $${idx++}`);
    values.push(normalizeNullableText(ownerName));
  }
  if (ownerIdType !== undefined) {
    fields.push(`owner_id_type = $${idx++}`);
    values.push(normalizeOwnerIdType(ownerIdType));
  }
  if (ownerIdNumber !== undefined) {
    fields.push(`owner_id_number = $${idx++}`);
    values.push(normalizeNullableText(ownerIdNumber));
  }
  if (legalName !== undefined) {
    fields.push(`legal_name = $${idx++}`);
    values.push(normalizeNullableText(legalName));
  }
  if (legalIdNumber !== undefined) {
    fields.push(`legal_id_number = $${idx++}`);
    values.push(normalizeNullableText(legalIdNumber));
  }
  if (phone !== undefined) {
    fields.push(`phone = $${idx++}`);
    values.push(normalizeNullableText(phone));
  }
  if (address !== undefined) {
    fields.push(`address = $${idx++}`);
    values.push(normalizeNullableText(address));
  }

  if (!fields.length) {
    const err = new Error('No hay cambios para actualizar.');
    err.status = 400;
    throw err;
  }

  fields.push(`updated_by_user_id = $${idx++}`);
  values.push(userId);
  fields.push(`updated_at = NOW()`);

  values.push(farmId);
  values.push(clientId);

  const res = await pool.query(
    `UPDATE farms
     SET ${fields.join(', ')}
     WHERE id = $${idx++}
       AND client_id = $${idx}
     RETURNING id`,
    values
  );

  if (!res.rows[0]) return null;

  if (recalculateAreaFromLots === true) {
    await recalculateEmpresaAreaIfAuto(clientId);
  }

  const loaded = await pool.query(`${FARM_SELECT} WHERE f.id = $1 AND f.client_id = $2`, [
    farmId,
    clientId,
  ]);
  return mapFarmRow(loaded.rows[0]);
}

async function inactivateFarm() {
  assertEmpresaNotInactivated();
}

async function activateFarm({ farmId, clientId, userId }) {
  const res = await pool.query(
    `UPDATE farms
     SET is_active = true,
         deactivated_at = NULL,
         updated_by_user_id = $3,
         updated_at = NOW()
     WHERE id = $1
       AND client_id = $2
       AND is_active = false
     RETURNING id`,
    [farmId, clientId, userId]
  );
  if (!res.rows[0]) return null;

  const loaded = await pool.query(`${FARM_SELECT} WHERE f.id = $1 AND f.client_id = $2`, [
    farmId,
    clientId,
  ]);
  return mapFarmRow(loaded.rows[0]);
}

module.exports = {
  listFarms,
  createFarm,
  updateFarm,
  inactivateFarm,
  activateFarm,
  formatFarmLocationDisplay: formatLocationDisplay,
};
