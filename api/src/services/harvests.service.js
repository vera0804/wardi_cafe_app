const { pool } = require('../db');

function round2(n) {
  return Math.round(Number(n) * 100) / 100;
}

function round4(n) {
  return Math.round(Number(n) * 10000) / 10000;
}

/** Normaliza fechas de PostgreSQL (Date o string) a YYYY-MM-DD. */
function toIsoDate(val) {
  if (val == null || val === '') return null;
  if (val instanceof Date) {
    if (Number.isNaN(val.getTime())) return null;
    return val.toISOString().slice(0, 10);
  }
  const s = String(val).trim();
  const m = /^(\d{4}-\d{2}-\d{2})/.exec(s);
  if (m) return m[1];
  const d = new Date(s);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString().slice(0, 10);
}

function addDays(isoDate, days) {
  const base = toIsoDate(isoDate);
  if (!base) {
    const err = new Error('Fecha inválida al calcular el periodo de cosecha.');
    err.status = 500;
    throw err;
  }
  const d = new Date(`${base}T12:00:00.000Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

function parseActive(value) {
  const v = String(value || '').trim().toLowerCase();
  if (!v || v === 'all') return undefined;
  if (v === 'true' || v === 'active') return true;
  if (v === 'false' || v === 'inactive') return false;
  const err = new Error('El filtro active debe ser true, false o all.');
  err.status = 400;
  throw err;
}

function resolvePriceFields(body) {
  const currency = String(body?.currency ?? 'CRC')
    .trim()
    .toUpperCase();
  if (currency !== 'CRC' && currency !== 'USD') {
    const err = new Error("currency debe ser 'CRC' o 'USD'.");
    err.status = 400;
    throw err;
  }
  const raw = body?.price_input;
  if (raw === undefined || raw === null || raw === '') {
    return {
      currency: 'CRC',
      price_per_fanega: null,
      price_per_fanega_usd: null,
      price_fx_rate: null,
    };
  }
  const priceInput = Number(raw);
  if (!Number.isFinite(priceInput) || priceInput < 0) {
    const err = new Error('price_input debe ser un número mayor o igual a 0.');
    err.status = 400;
    throw err;
  }
  if (currency === 'CRC') {
    return {
      currency: 'CRC',
      price_per_fanega: round2(priceInput),
      price_per_fanega_usd: null,
      price_fx_rate: null,
    };
  }
  const fx = Number(body.fx_rate);
  if (!Number.isFinite(fx) || fx <= 0) {
    const err = new Error('En moneda USD, fx_rate es obligatorio y debe ser mayor que 0.');
    err.status = 400;
    throw err;
  }
  const usd = round2(priceInput);
  const crc = round2(priceInput * fx);
  return {
    currency: 'USD',
    price_per_fanega: crc,
    price_per_fanega_usd: usd,
    price_fx_rate: round4(fx),
  };
}

function mapHarvestRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    start_date: toIsoDate(row.start_date),
    end_date: toIsoDate(row.end_date),
    price_per_fanega: row.price_per_fanega != null ? Number(row.price_per_fanega) : null,
    price_per_fanega_usd: row.price_per_fanega_usd != null ? Number(row.price_per_fanega_usd) : null,
    price_fx_rate: row.price_fx_rate != null ? Number(row.price_fx_rate) : null,
    currency: row.currency || 'CRC',
    is_active: row.is_active,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

async function getHarvestRow({ db, id, clientId }) {
  const res = await db.query(
    `SELECT *
     FROM harvests
     WHERE id = $1
       AND client_id = $2`,
    [id, clientId]
  );
  return res.rows[0] || null;
}

async function getLastHarvest({ db, clientId }) {
  const res = await db.query(
    `SELECT id, start_date, end_date
     FROM harvests
     WHERE client_id = $1
     ORDER BY end_date DESC
     LIMIT 1`,
    [clientId]
  );
  return res.rows[0] || null;
}

async function getPreviousHarvest({ db, clientId, beforeEndDate, excludeId = null }) {
  const res = await db.query(
    `SELECT id, start_date, end_date
     FROM harvests
     WHERE client_id = $1
       AND end_date < $2::date
       AND ($3::uuid IS NULL OR id <> $3::uuid)
     ORDER BY end_date DESC
     LIMIT 1`,
    [clientId, beforeEndDate, excludeId]
  );
  return res.rows[0] || null;
}

async function getNextHarvest({ db, clientId, afterEndDate, excludeId = null }) {
  const res = await db.query(
    `SELECT id, start_date, end_date
     FROM harvests
     WHERE client_id = $1
       AND start_date > $2::date
       AND ($3::uuid IS NULL OR id <> $3::uuid)
     ORDER BY start_date ASC
     LIMIT 1`,
    [clientId, afterEndDate, excludeId]
  );
  return res.rows[0] || null;
}

/** Primera cosecha del tenant con inicio estrictamente posterior a `afterDate`. */
async function getEarliestHarvestStartingAfter({ db, clientId, afterDate }) {
  const res = await db.query(
    `SELECT id, start_date, end_date
     FROM harvests
     WHERE client_id = $1
       AND start_date > $2::date
     ORDER BY start_date ASC
     LIMIT 1`,
    [clientId, afterDate]
  );
  return res.rows[0] || null;
}

async function listHarvests({ clientId, filters }) {
  const q = filters || {};
  const clauses = ['h.client_id = $1'];
  const values = [clientId];
  let idx = 2;

  if (q.active !== undefined) {
    clauses.push(`h.is_active = $${idx++}`);
    values.push(q.active);
  }
  if (q.year) {
    const y = Number(q.year);
    if (!Number.isInteger(y)) {
      const err = new Error('year debe ser un entero.');
      err.status = 400;
      throw err;
    }
    clauses.push(`h.start_date <= $${idx}::date`);
    values.push(`${y}-12-31`);
    clauses.push(`h.end_date >= $${idx + 1}::date`);
    values.push(`${y}-01-01`);
    idx += 2;
  }
  if (q.fromDate) {
    clauses.push(`h.end_date >= $${idx++}::date`);
    values.push(q.fromDate);
  }
  if (q.toDate) {
    clauses.push(`h.start_date <= $${idx++}::date`);
    values.push(q.toDate);
  }
  if (q.fromDate && q.toDate && q.fromDate > q.toDate) {
    const err = new Error('from_date no puede ser posterior a to_date.');
    err.status = 400;
    throw err;
  }

  const res = await pool.query(
    `SELECT h.*
     FROM harvests h
     WHERE ${clauses.join(' AND ')}
     ORDER BY h.start_date DESC`,
    values
  );
  return res.rows.map(mapHarvestRow);
}

async function getHarvestById({ id, clientId }) {
  const row = await getHarvestRow({ db: pool, id, clientId });
  return mapHarvestRow(row);
}

async function createHarvest({ clientId, userId, payload }) {
  const yearFrom = Number(payload.year_from);
  const yearTo = Number(payload.year_to);
  if (!Number.isInteger(yearFrom) || !Number.isInteger(yearTo)) {
    const err = new Error('year_from y year_to son obligatorios.');
    err.status = 400;
    throw err;
  }
  if (yearTo !== yearFrom + 1) {
    const err = new Error('El año final debe ser consecutivo al año inicial (año inicial + 1).');
    err.status = 400;
    throw err;
  }

  const price = resolvePriceFields(payload);
  const name = `Cosecha ${yearFrom} - ${yearTo}`;
  const nominalStart = `${yearFrom}-01-01`;
  const defaultEnd = `${yearTo}-12-31`;

  const db = await pool.connect();
  try {
    await db.query('BEGIN');

    const nextHarvest = await getEarliestHarvestStartingAfter({
      db,
      clientId,
      afterDate: nominalStart,
    });
    const nextStart = nextHarvest ? toIsoDate(nextHarvest.start_date) : null;
    if (nextHarvest && !nextStart) {
      const err = new Error(
        'La cosecha siguiente tiene una fecha de inicio inválida; corríjala antes de crear un periodo nuevo.'
      );
      err.status = 500;
      throw err;
    }

    const endDate = nextStart ? addDays(nextStart, -1) : defaultEnd;

    const previous = await getPreviousHarvest({
      db,
      clientId,
      beforeEndDate: endDate,
    });
    const prevEnd = previous ? toIsoDate(previous.end_date) : null;
    if (previous && !prevEnd) {
      const err = new Error(
        'La cosecha anterior tiene una fecha de fin inválida; corríjala antes de crear un periodo nuevo.'
      );
      err.status = 500;
      throw err;
    }

    const startDate = prevEnd ? addDays(prevEnd, 1) : nominalStart;

    if (startDate > endDate) {
      const err = new Error(
        nextStart
          ? `No hay espacio para «${name}»: la cosecha que inicia el ${nextStart} deja el tramo demasiado corto. Ajuste fechas de cosechas existentes o el año inicial.`
          : `Las fechas calculadas son inválidas (inicio ${startDate} posterior a fin ${endDate}).`
      );
      err.status = 400;
      throw err;
    }

    const insertRes = await db.query(
      `INSERT INTO harvests (
         name, start_date, end_date, price_per_fanega, price_per_fanega_usd,
         price_fx_rate, currency, client_id, created_by_user_id, updated_by_user_id
       )
       VALUES ($1, $2::date, $3::date, $4, $5, $6, $7, $8, $9, $9)
       RETURNING *`,
      [
        name,
        startDate,
        endDate,
        price.price_per_fanega,
        price.price_per_fanega_usd,
        price.price_fx_rate,
        price.currency,
        clientId,
        userId,
      ]
    );
    await db.query('COMMIT');
    return mapHarvestRow(insertRes.rows[0]);
  } catch (e) {
    await db.query('ROLLBACK');
    throw e;
  } finally {
    db.release();
  }
}

async function updateHarvest({ id, clientId, userId, payload }) {
  const db = await pool.connect();
  try {
    await db.query('BEGIN');
    const current = await getHarvestRow({ db, id, clientId });
    if (!current) {
      await db.query('ROLLBACK');
      return null;
    }

    const startDate =
      payload.start_date !== undefined
        ? toIsoDate(String(payload.start_date).trim())
        : toIsoDate(current.start_date);
    const endDate =
      payload.end_date !== undefined
        ? toIsoDate(String(payload.end_date).trim())
        : toIsoDate(current.end_date);
    if (!startDate || !endDate) {
      const err = new Error('start_date y end_date deben ser fechas válidas (YYYY-MM-DD).');
      err.status = 400;
      throw err;
    }
    if (endDate < startDate) {
      const err = new Error('end_date no puede ser anterior a start_date.');
      err.status = 400;
      throw err;
    }

    const hasPrice =
      payload.currency !== undefined ||
      payload.price_input !== undefined ||
      payload.fx_rate !== undefined;
    const price = hasPrice
      ? resolvePriceFields({
          currency: payload.currency ?? current.currency,
          price_input: payload.price_input,
          fx_rate: payload.fx_rate,
        })
      : {
          currency: current.currency,
          price_per_fanega: current.price_per_fanega,
          price_per_fanega_usd: current.price_per_fanega_usd,
          price_fx_rate: current.price_fx_rate,
        };

    const chainWarnings = [];

    if (payload.start_date !== undefined) {
      const prev = await getPreviousHarvest({
        db,
        clientId,
        beforeEndDate: startDate,
        excludeId: id,
      });
      if (prev) {
        const newPrevEnd = addDays(startDate, -1);
        if (toIsoDate(prev.end_date) !== newPrevEnd) {
          await db.query(
            `UPDATE harvests
             SET end_date = $2::date, updated_by_user_id = $3, updated_at = NOW()
             WHERE id = $1 AND client_id = $4`,
            [prev.id, newPrevEnd, userId, clientId]
          );
          chainWarnings.push('Se ajustó la fecha de fin de la cosecha anterior.');
        }
      }
    }

    if (payload.end_date !== undefined) {
      const next = await getNextHarvest({
        db,
        clientId,
        afterEndDate: endDate,
        excludeId: id,
      });
      if (next) {
        const newNextStart = addDays(endDate, 1);
        if (toIsoDate(next.start_date) !== newNextStart) {
          await db.query(
            `UPDATE harvests
             SET start_date = $2::date, updated_by_user_id = $3, updated_at = NOW()
             WHERE id = $1 AND client_id = $4`,
            [next.id, newNextStart, userId, clientId]
          );
          chainWarnings.push('Se ajustó la fecha de inicio de la cosecha siguiente.');
        }
      }
    }

    const updateRes = await db.query(
      `UPDATE harvests
       SET start_date = $2::date,
           end_date = $3::date,
           price_per_fanega = $4,
           price_per_fanega_usd = $5,
           price_fx_rate = $6,
           currency = $7,
           updated_by_user_id = $8,
           updated_at = NOW()
       WHERE id = $1
         AND client_id = $9
       RETURNING *`,
      [
        id,
        startDate,
        endDate,
        price.price_per_fanega,
        price.price_per_fanega_usd,
        price.price_fx_rate,
        price.currency,
        userId,
        clientId,
      ]
    );

    await db.query('COMMIT');
    return { harvest: mapHarvestRow(updateRes.rows[0]), chain_warnings: chainWarnings };
  } catch (e) {
    await db.query('ROLLBACK');
    throw e;
  } finally {
    db.release();
  }
}

async function setHarvestActive({ id, clientId, userId, isActive }) {
  const res = await pool.query(
    `UPDATE harvests
     SET is_active = $2,
         updated_by_user_id = $3,
         updated_at = NOW()
     WHERE id = $1
       AND client_id = $4
     RETURNING *`,
    [id, isActive, userId, clientId]
  );
  return mapHarvestRow(res.rows[0] || null);
}

module.exports = {
  parseActive,
  listHarvests,
  getHarvestById,
  createHarvest,
  updateHarvest,
  setHarvestActive,
};
