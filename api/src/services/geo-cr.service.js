const { pool } = require('../db');

function normalizeNullableText(value) {
  if (value == null) return null;
  const v = String(value).trim();
  return v ? v : null;
}

function normalizeOptionalId(value) {
  if (value === undefined) return undefined;
  if (value === null || value === '') return null;
  const n = Number(value);
  if (!Number.isInteger(n) || n <= 0) {
    const err = new Error('Identificador geográfico inválido.');
    err.status = 400;
    throw err;
  }
  return n;
}

function formatLocationDisplay({ provinceName, cantonName, districtName, community }) {
  const parts = [provinceName, cantonName, districtName, community].filter(Boolean);
  return parts.length ? parts.join(', ') : null;
}

/**
 * Valida y normaliza provincia / cantón / distrito (jerarquía CR).
 */
async function resolveCrGeo({ provinceId, cantonId, districtId, community, requireProvince = false }) {
  const hasGeoInput =
    provinceId !== undefined ||
    cantonId !== undefined ||
    districtId !== undefined ||
    community !== undefined;

  if (!hasGeoInput) {
    return {
      provinceId: undefined,
      cantonId: undefined,
      districtId: undefined,
      community: undefined,
    };
  }

  let pid = provinceId === undefined ? undefined : normalizeOptionalId(provinceId);
  let cid = cantonId === undefined ? undefined : normalizeOptionalId(cantonId);
  let did = districtId === undefined ? undefined : normalizeOptionalId(districtId);
  const comm = community === undefined ? undefined : normalizeNullableText(community);

  if (requireProvince && (pid === undefined || pid === null)) {
    const err = new Error('La provincia es obligatoria.');
    err.status = 400;
    throw err;
  }

  if (pid != null) {
    const pRes = await pool.query(`SELECT id FROM provinces WHERE id = $1`, [pid]);
    if (!pRes.rows[0]) {
      const err = new Error('Provincia no encontrada.');
      err.status = 400;
      throw err;
    }
  }

  if (cid != null) {
    const cRes = await pool.query(`SELECT id, province_id FROM cantons WHERE id = $1`, [cid]);
    const canton = cRes.rows[0];
    if (!canton) {
      const err = new Error('Cantón no encontrado.');
      err.status = 400;
      throw err;
    }
    if (pid != null && canton.province_id !== pid) {
      const err = new Error('El cantón no pertenece a la provincia seleccionada.');
      err.status = 400;
      throw err;
    }
    if (pid == null) pid = canton.province_id;
  } else if (did != null) {
    const err = new Error('Debe seleccionar cantón para elegir un distrito.');
    err.status = 400;
    throw err;
  }

  if (did != null) {
    const dRes = await pool.query(`SELECT id, canton_id FROM districts WHERE id = $1`, [did]);
    const district = dRes.rows[0];
    if (!district) {
      const err = new Error('Distrito no encontrado.');
      err.status = 400;
      throw err;
    }
    if (cid != null && district.canton_id !== cid) {
      const err = new Error('El distrito no pertenece al cantón seleccionado.');
      err.status = 400;
      throw err;
    }
    if (cid == null) {
      const cRes = await pool.query(
        `SELECT id, province_id FROM cantons WHERE id = $1`,
        [district.canton_id]
      );
      cid = cRes.rows[0]?.id ?? null;
      if (pid == null && cRes.rows[0]) pid = cRes.rows[0].province_id;
    }
  }

  return {
    provinceId: pid,
    cantonId: cid,
    districtId: did,
    community: comm,
  };
}

module.exports = {
  normalizeNullableText,
  normalizeOptionalId,
  formatLocationDisplay,
  resolveCrGeo,
};
