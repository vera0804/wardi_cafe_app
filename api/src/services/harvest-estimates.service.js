const { pool } = require('../db');

function round2(n) {
  return Math.round(Number(n) * 100) / 100;
}

function round4(n) {
  return Math.round(Number(n) * 10000) / 10000;
}

async function assertHarvestForClient({ db, harvestId, clientId }) {
  const res = await db.query(
    `SELECT id, name, start_date, end_date, is_active
     FROM harvests
     WHERE id = $1
       AND client_id = $2`,
    [harvestId, clientId]
  );
  const row = res.rows[0];
  if (!row) {
    const err = new Error('Cosecha no encontrada o no pertenece a tu organización.');
    err.status = 404;
    throw err;
  }
  return row;
}

async function assertLotForClient({ db, lotId, clientId }) {
  const res = await db.query(
    `SELECT l.id, l.name, l.farm_id, f.name AS farm_name
     FROM lots l
     INNER JOIN farms f ON f.id = l.farm_id AND f.client_id = l.client_id
     WHERE l.id = $1
       AND l.client_id = $2
       AND l.is_active = true
       AND f.is_active = true`,
    [lotId, clientId]
  );
  const row = res.rows[0];
  if (!row) {
    const err = new Error('Finca no encontrada, inactiva o no pertenece a tu organización.');
    err.status = 409;
    throw err;
  }
  return row;
}

async function getMeta({ clientId }) {
  const [harvestsRes, lotsRes] = await Promise.all([
    pool.query(
      `SELECT id, name, start_date, end_date
       FROM harvests
       WHERE client_id = $1
         AND is_active = true
       ORDER BY start_date DESC`,
      [clientId]
    ),
    pool.query(
      `SELECT l.id, l.name, l.farm_id, f.name AS farm_name
       FROM lots l
       INNER JOIN farms f ON f.id = l.farm_id AND f.client_id = l.client_id
       WHERE l.client_id = $1
         AND l.is_active = true
         AND f.is_active = true
       ORDER BY f.name ASC, l.name ASC`,
      [clientId]
    ),
  ]);
  return { harvests: harvestsRes.rows, lots: lotsRes.rows };
}

async function listByHarvest({ clientId, harvestId }) {
  await assertHarvestForClient({ db: pool, harvestId, clientId });

  const rowsRes = await pool.query(
    `SELECT l.id AS lot_id,
            l.name AS lot_name,
            f.id AS farm_id,
            f.name AS farm_name,
            lh.estimated_cajuelas,
            lh.estimated_fanegas
     FROM lots l
     INNER JOIN farms f ON f.id = l.farm_id AND f.client_id = l.client_id
     LEFT JOIN lot_harvests lh ON lh.lot_id = l.id AND lh.harvest_id = $2
     WHERE l.client_id = $1
       AND l.is_active = true
       AND f.is_active = true
     ORDER BY f.name ASC, l.name ASC`,
    [clientId, harvestId]
  );

  const totalsRes = await pool.query(
    `SELECT f.id AS farm_id,
            f.name AS farm_name,
            COUNT(lh.lot_id)::int AS lots_with_estimate,
            COALESCE(SUM(lh.estimated_cajuelas), 0)::numeric(14,2) AS total_cajuelas,
            COALESCE(SUM(lh.estimated_fanegas), 0)::numeric(14,4) AS total_fanegas
     FROM lots l
     INNER JOIN farms f ON f.id = l.farm_id AND f.client_id = l.client_id
     INNER JOIN lot_harvests lh ON lh.lot_id = l.id AND lh.harvest_id = $2
     WHERE l.client_id = $1
       AND l.is_active = true
       AND f.is_active = true
     GROUP BY f.id, f.name
     HAVING COUNT(lh.lot_id) > 0
     ORDER BY f.name ASC`,
    [clientId, harvestId]
  );

  return {
    rows: rowsRes.rows.map((r) => ({
      lot_id: r.lot_id,
      lot_name: r.lot_name,
      farm_id: r.farm_id,
      farm_name: r.farm_name,
      estimated_cajuelas:
        r.estimated_cajuelas != null ? Number(r.estimated_cajuelas) : null,
      estimated_fanegas: r.estimated_fanegas != null ? Number(r.estimated_fanegas) : null,
    })),
    farm_totals: totalsRes.rows.map((r) => ({
      farm_id: r.farm_id,
      farm_name: r.farm_name,
      lots_with_estimate: Number(r.lots_with_estimate || 0),
      total_cajuelas: round2(Number(r.total_cajuelas || 0)),
      total_fanegas: round4(Number(r.total_fanegas || 0)),
    })),
  };
}

async function upsertLotEstimate({ clientId, userId, payload }) {
  const harvestId = String(payload.harvest_id || '').trim();
  const lotId = String(payload.lot_id || '').trim();
  if (!harvestId || !lotId) {
    const err = new Error('harvest_id y lot_id son obligatorios.');
    err.status = 400;
    throw err;
  }
  const cajuelas = Number(payload.estimated_cajuelas);
  if (!Number.isFinite(cajuelas) || cajuelas < 0) {
    const err = new Error('estimated_cajuelas debe ser un número mayor o igual a 0.');
    err.status = 400;
    throw err;
  }
  const fanegas = round4(cajuelas / 20);

  const db = await pool.connect();
  try {
    await db.query('BEGIN');
    await assertHarvestForClient({ db, harvestId, clientId });
    await assertLotForClient({ db, lotId, clientId });

    const res = await db.query(
      `INSERT INTO lot_harvests (
         lot_id, harvest_id, estimated_cajuelas, estimated_fanegas,
         created_by_user_id, updated_by_user_id
       )
       VALUES ($1, $2, $3, $4, $5, $5)
       ON CONFLICT (lot_id, harvest_id) DO UPDATE SET
         estimated_cajuelas = EXCLUDED.estimated_cajuelas,
         estimated_fanegas = EXCLUDED.estimated_fanegas,
         updated_by_user_id = EXCLUDED.updated_by_user_id,
         updated_at = NOW()
       RETURNING lot_id, harvest_id, estimated_cajuelas, estimated_fanegas`,
      [lotId, harvestId, round2(cajuelas), fanegas, userId]
    );
    await db.query('COMMIT');
    const row = res.rows[0];
    return {
      lot_id: row.lot_id,
      harvest_id: row.harvest_id,
      estimated_cajuelas: Number(row.estimated_cajuelas),
      estimated_fanegas: Number(row.estimated_fanegas),
    };
  } catch (e) {
    await db.query('ROLLBACK');
    throw e;
  } finally {
    db.release();
  }
}

async function deleteLotEstimate({ clientId, harvestId, lotId }) {
  const res = await pool.query(
    `DELETE FROM lot_harvests lh
     USING harvests h, lots l
     WHERE lh.harvest_id = h.id
       AND lh.lot_id = l.id
       AND lh.harvest_id = $1
       AND lh.lot_id = $2
       AND h.client_id = $3
       AND l.client_id = $3
     RETURNING lh.lot_id`,
    [harvestId, lotId, clientId]
  );
  return res.rowCount > 0;
}

module.exports = {
  getMeta,
  listByHarvest,
  upsertLotEstimate,
  deleteLotEstimate,
};
