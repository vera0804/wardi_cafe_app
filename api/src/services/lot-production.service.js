const { pool } = require('../db');

const DUPLICATE_ACTIVE_MSG = 'Ya existe un registro activo para esta finca y fecha.';
const LOT_INVALID_MSG = 'Finca no encontrada, inactiva o no pertenece a tu organización.';

function normalizeText(value) {
  if (value == null) return null;
  const v = String(value).trim();
  return v || null;
}

function normalizeDate(value, { required = false, field = 'prod_date' } = {}) {
  if (value === undefined && !required) return undefined;
  const v = String(value || '').trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(v)) {
    const err = new Error(`${field} debe tener formato YYYY-MM-DD.`);
    err.status = 400;
    throw err;
  }
  return v;
}

function normalizeLotId(value, { required = false } = {}) {
  if (value === undefined && !required) return undefined;
  const v = String(value || '').trim();
  if (!v) {
    const err = new Error('lot_id es obligatorio.');
    err.status = 400;
    throw err;
  }
  return v;
}

function normalizeCajuelas(value) {
  const n = Number(value);
  if (!Number.isFinite(n) || n < 0) {
    const err = new Error('cajuelas debe ser un número mayor o igual a 0.');
    err.status = 400;
    throw err;
  }
  return n;
}

function assertDateRange(fromDate, toDate) {
  if (fromDate && toDate && fromDate > toDate) {
    const err = new Error('from_date no puede ser posterior a to_date.');
    err.status = 400;
    throw err;
  }
}

function mapDuplicateError(e) {
  if (e && e.code === '23505') {
    const err = new Error(DUPLICATE_ACTIVE_MSG);
    err.status = 409;
    throw err;
  }
  throw e;
}

async function getActiveLot({ db, lotId, clientId }) {
  const res = await db.query(
    `SELECT l.id, l.farm_id, l.is_active AS lot_active, f.is_active AS farm_active
     FROM lots l
     INNER JOIN farms f ON f.id = l.farm_id AND f.client_id = l.client_id
     WHERE l.id = $1
       AND l.client_id = $2`,
    [lotId, clientId]
  );
  const row = res.rows[0];
  if (!row || !row.lot_active || !row.farm_active) {
    const err = new Error(LOT_INVALID_MSG);
    err.status = 409;
    throw err;
  }
  return row;
}

async function assertNoDuplicateActive({ db, clientId, lotId, prodDate, excludeId = null }) {
  const res = await db.query(
    `SELECT id
     FROM coffee_lot_production
     WHERE client_id = $1
       AND lot_id = $2
       AND prod_date = $3::date
       AND is_active = true
       AND ($4::uuid IS NULL OR id <> $4::uuid)
     LIMIT 1`,
    [clientId, lotId, prodDate, excludeId]
  );
  if (res.rows[0]) {
    const err = new Error(DUPLICATE_ACTIVE_MSG);
    err.status = 409;
    throw err;
  }
}

const SELECT_ROW = `
  SELECT clp.id,
         clp.lot_id,
         clp.prod_date,
         clp.cajuelas,
         clp.fanegas,
         clp.notes,
         clp.is_active,
         clp.created_at,
         clp.updated_at,
         to_char(clp.prod_date, 'IYYY-"S"IW') AS work_week,
         l.name AS lot_name,
         f.id AS farm_id,
         f.name AS farm_name
  FROM coffee_lot_production clp
  INNER JOIN lots l ON l.id = clp.lot_id AND l.client_id = clp.client_id
  INNER JOIN farms f ON f.id = l.farm_id AND f.client_id = clp.client_id
`;

async function getByIdTx({ db, id, clientId }) {
  const res = await db.query(
    `${SELECT_ROW}
     WHERE clp.id = $1
       AND clp.client_id = $2`,
    [id, clientId]
  );
  return res.rows[0] || null;
}

async function getMeta({ clientId }) {
  const [farmsRes, lotsRes] = await Promise.all([
    pool.query(
      `SELECT id, name
       FROM farms
       WHERE client_id = $1
         AND is_active = true
       ORDER BY name ASC`,
      [clientId]
    ),
    pool.query(
      `SELECT l.id, l.name, l.farm_id
       FROM lots l
       INNER JOIN farms f ON f.id = l.farm_id AND f.client_id = l.client_id
       WHERE l.client_id = $1
         AND l.is_active = true
         AND f.is_active = true
       ORDER BY l.name ASC`,
      [clientId]
    ),
  ]);
  return { farms: farmsRes.rows, lots: lotsRes.rows };
}

async function listProductions({ clientId, filters }) {
  const q = filters || {};
  assertDateRange(q.fromDate, q.toDate);

  const clauses = ['clp.client_id = $1'];
  const values = [clientId];
  let idx = 2;

  if (q.fromDate) {
    clauses.push(`clp.prod_date >= $${idx++}::date`);
    values.push(q.fromDate);
  }
  if (q.toDate) {
    clauses.push(`clp.prod_date <= $${idx++}::date`);
    values.push(q.toDate);
  }
  if (q.farmId) {
    clauses.push(`l.farm_id = $${idx++}::uuid`);
    values.push(q.farmId);
  }
  if (q.lotId) {
    clauses.push(`clp.lot_id = $${idx++}::uuid`);
    values.push(q.lotId);
  }
  if (q.active !== undefined) {
    clauses.push(`clp.is_active = $${idx++}`);
    values.push(q.active);
  }

  const res = await pool.query(
    `${SELECT_ROW}
     WHERE ${clauses.join(' AND ')}
     ORDER BY clp.prod_date DESC, clp.created_at DESC`,
    values
  );
  return res.rows;
}

async function getProductionById({ id, clientId }) {
  return getByIdTx({ db: pool, id, clientId });
}

function buildDateRange(fromDate, toDate) {
  const start = new Date(`${fromDate}T00:00:00.000Z`);
  const end = new Date(`${toDate}T00:00:00.000Z`);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime()) || start > end) {
    const err = new Error('Rango de fechas inválido.');
    err.status = 400;
    throw err;
  }
  const out = [];
  const cur = new Date(start);
  while (cur <= end) {
    out.push(cur.toISOString().slice(0, 10));
    cur.setUTCDate(cur.getUTCDate() + 1);
  }
  return out;
}

function parseDailyProductionItems({ dailyItems, fromDate, toDate }) {
  const rangeSet = new Set(buildDateRange(fromDate, toDate));
  if (!Array.isArray(dailyItems) || dailyItems.length === 0) {
    const err = new Error('Debe indicar al menos un día en daily_items.');
    err.status = 400;
    throw err;
  }

  const itemsByDate = new Map();
  const seen = new Set();
  for (const item of dailyItems) {
    const d = normalizeDate(item?.prod_date, { required: true, field: 'daily_items.prod_date' });
    if (!rangeSet.has(d)) {
      const err = new Error(`La fecha ${d} está fuera del rango indicado (${fromDate} a ${toDate}).`);
      err.status = 400;
      throw err;
    }
    if (seen.has(d)) {
      const err = new Error(`Fecha duplicada en daily_items: ${d}.`);
      err.status = 400;
      throw err;
    }
    seen.add(d);
    const cajuelas = normalizeCajuelas(item?.cajuelas);
    itemsByDate.set(d, { cajuelas });
  }

  return { dates: [...itemsByDate.keys()].sort(), itemsByDate };
}

async function createProductionBulk({ clientId, userId, payload }) {
  const fromDate = normalizeDate(payload.from_date, { required: true, field: 'from_date' });
  const toDate = normalizeDate(payload.to_date, { required: true, field: 'to_date' });
  if (fromDate > toDate) {
    const err = new Error('from_date no puede ser posterior a to_date.');
    err.status = 400;
    throw err;
  }

  const lotId = normalizeLotId(payload.lot_id, { required: true });
  const notes = normalizeText(payload.notes);
  const { dates, itemsByDate } = parseDailyProductionItems({
    dailyItems: payload.daily_items,
    fromDate,
    toDate,
  });

  const db = await pool.connect();
  try {
    await db.query('BEGIN');
    await getActiveLot({ db, lotId, clientId });
    const created = [];
    for (const prodDate of dates) {
      const item = itemsByDate.get(prodDate);
      await assertNoDuplicateActive({ db, clientId, lotId, prodDate });
      const insertRes = await db.query(
        `INSERT INTO coffee_lot_production (
           client_id, lot_id, prod_date, cajuelas, notes,
           created_by_user_id, updated_by_user_id
         )
         VALUES ($1, $2, $3::date, $4, $5, $6, $6)
         RETURNING id`,
        [clientId, lotId, prodDate, item.cajuelas, notes, userId]
      );
      const row = await getByIdTx({ db, id: insertRes.rows[0].id, clientId });
      created.push(row);
    }
    await db.query('COMMIT');
    return created;
  } catch (e) {
    await db.query('ROLLBACK');
    mapDuplicateError(e);
  } finally {
    db.release();
  }
}

async function createProduction({ clientId, userId, payload }) {
  const lotId = normalizeLotId(payload.lot_id, { required: true });
  const prodDate = normalizeDate(payload.prod_date, { required: true });
  const cajuelas = normalizeCajuelas(payload.cajuelas);
  const notes = normalizeText(payload.notes);

  const db = await pool.connect();
  try {
    await db.query('BEGIN');
    await getActiveLot({ db, lotId, clientId });
    await assertNoDuplicateActive({ db, clientId, lotId, prodDate });
    const insertRes = await db.query(
      `INSERT INTO coffee_lot_production (
         client_id, lot_id, prod_date, cajuelas, notes,
         created_by_user_id, updated_by_user_id
       )
       VALUES ($1, $2, $3::date, $4, $5, $6, $6)
       RETURNING id`,
      [clientId, lotId, prodDate, cajuelas, notes, userId]
    );
    const row = await getByIdTx({ db, id: insertRes.rows[0].id, clientId });
    await db.query('COMMIT');
    return row;
  } catch (e) {
    await db.query('ROLLBACK');
    mapDuplicateError(e);
  } finally {
    db.release();
  }
}

async function updateProduction({ id, clientId, userId, payload }) {
  const db = await pool.connect();
  try {
    await db.query('BEGIN');
    const curRes = await db.query(
      `SELECT *
       FROM coffee_lot_production
       WHERE id = $1
         AND client_id = $2`,
      [id, clientId]
    );
    const current = curRes.rows[0];
    if (!current) {
      await db.query('ROLLBACK');
      return null;
    }

    const lotId = payload.lot_id !== undefined ? normalizeLotId(payload.lot_id, { required: true }) : current.lot_id;
    const prodDate =
      payload.prod_date !== undefined
        ? normalizeDate(payload.prod_date, { required: true })
        : String(current.prod_date).slice(0, 10);
    const cajuelas = payload.cajuelas !== undefined ? normalizeCajuelas(payload.cajuelas) : Number(current.cajuelas);
    const notes = payload.notes !== undefined ? normalizeText(payload.notes) : current.notes;

    await getActiveLot({ db, lotId, clientId });
    if (current.is_active) {
      await assertNoDuplicateActive({ db, clientId, lotId, prodDate, excludeId: id });
    }

    await db.query(
      `UPDATE coffee_lot_production
       SET lot_id = $2,
           prod_date = $3::date,
           cajuelas = $4,
           notes = $5,
           updated_by_user_id = $6,
           updated_at = NOW()
       WHERE id = $1
         AND client_id = $7`,
      [id, lotId, prodDate, cajuelas, notes, userId, clientId]
    );

    const row = await getByIdTx({ db, id, clientId });
    await db.query('COMMIT');
    return row;
  } catch (e) {
    await db.query('ROLLBACK');
    mapDuplicateError(e);
  } finally {
    db.release();
  }
}

async function setProductionActive({ id, clientId, userId, isActive }) {
  const db = await pool.connect();
  try {
    await db.query('BEGIN');
    const curRes = await db.query(
      `SELECT lot_id, prod_date, is_active
       FROM coffee_lot_production
       WHERE id = $1
         AND client_id = $2`,
      [id, clientId]
    );
    const existing = curRes.rows[0];
    if (!existing) {
      await db.query('ROLLBACK');
      return null;
    }

    const lotId = existing.lot_id;
    const prodDate = String(existing.prod_date).slice(0, 10);

    if (isActive) {
      await getActiveLot({ db, lotId, clientId });
      await assertNoDuplicateActive({
        db,
        clientId,
        lotId,
        prodDate,
        excludeId: id,
      });
    }

    await db.query(
      `UPDATE coffee_lot_production
       SET is_active = $2,
           updated_by_user_id = $3,
           updated_at = NOW()
       WHERE id = $1
         AND client_id = $4`,
      [id, isActive, userId, clientId]
    );

    const row = await getByIdTx({ db, id, clientId });
    await db.query('COMMIT');
    return row;
  } catch (e) {
    await db.query('ROLLBACK');
    mapDuplicateError(e);
  } finally {
    db.release();
  }
}

module.exports = {
  getMeta,
  listProductions,
  getProductionById,
  createProduction,
  createProductionBulk,
  updateProduction,
  setProductionActive,
};
