const { pool } = require('../db');
const { normalizeBillingModel } = require('../lib/licenseDates');

const PLAN_IMPACT_CODE = 'PLAN_IMPACT_NOT_ACKNOWLEDGED';

function billingModelLabel(billingModel) {
  const m = normalizeBillingModel(billingModel);
  if (m === 'trial_days') return 'Demo / días fijos';
  if (m === 'monthly_anchor') return 'Mensual (día de pago)';
  return 'Sin vencimiento';
}

function mapPlanRow(row) {
  if (!row) return null;
  const billingModel = normalizeBillingModel(row.billing_model);
  return {
    id: row.id,
    name: row.name,
    billing_model: billingModel,
    billing_model_label: billingModelLabel(billingModel),
    trial_days: row.trial_days,
    description: row.description,
    max_farms: row.max_farms,
    max_lots_per_farm: row.max_lots_per_farm,
    max_users_admin: row.max_users_admin,
    max_users_operario: row.max_users_operario,
    price: row.price != null ? Number(row.price) : 0,
    is_active: row.is_active !== false,
    active_client_count:
      row.active_client_count != null ? Number(row.active_client_count) : undefined,
    created_at: row.created_at,
  };
}

const PLAN_SELECT = `
  p.id, p.name, p.billing_model, p.trial_days, p.description,
  p.max_farms, p.max_lots_per_farm, p.max_users_admin, p.max_users_operario,
  p.price, p.is_active, p.created_at`;

async function fetchPlanRowById(planId, { db = pool } = {}) {
  const res = await db.query(
    `SELECT ${PLAN_SELECT},
            (SELECT COUNT(*)::int FROM clients c
             WHERE c.plan_id = p.id AND lower(trim(coalesce(c.status, ''))) = 'active'
            ) AS active_client_count
     FROM plans p
     WHERE p.id = $1::uuid
     LIMIT 1`,
    [planId]
  );
  return res.rows[0] || null;
}

async function listActivePlans() {
  const res = await pool.query(
    `SELECT ${PLAN_SELECT}
     FROM plans p
     WHERE p.is_active = true
     ORDER BY p.name ASC`
  );
  return res.rows.map(mapPlanRow);
}

async function listAllPlans() {
  const res = await pool.query(
    `SELECT ${PLAN_SELECT},
            (SELECT COUNT(*)::int FROM clients c
             WHERE c.plan_id = p.id AND lower(trim(coalesce(c.status, ''))) = 'active'
            ) AS active_client_count
     FROM plans p
     ORDER BY p.is_active DESC, p.name ASC`
  );
  return res.rows.map(mapPlanRow);
}

async function listActiveClientsOnPlan(planId) {
  const res = await pool.query(
    `SELECT id, name
     FROM clients
     WHERE plan_id = $1::uuid
       AND lower(trim(coalesce(status, ''))) = 'active'
     ORDER BY name ASC`,
    [planId]
  );
  return res.rows;
}

async function getPlanImpact(planId) {
  const plan = await fetchPlanRowById(planId);
  if (!plan) {
    const err = new Error('Plan no encontrado.');
    err.status = 404;
    throw err;
  }
  const activeClients = await listActiveClientsOnPlan(planId);
  const n = activeClients.length;
  return {
    plan_id: planId,
    plan_name: plan.name,
    active_client_count: n,
    message:
      n > 0
        ? `Hay ${n} organización(es) activa(s) con este plan. Si guardas los cambios, quedarán con la nueva configuración del plan (límites y facturación). Las fechas de licencia de cada cliente no se recalculan solas.`
        : 'Ninguna organización activa usa este plan.',
    active_clients: activeClients,
  };
}

function parseLimit(value, field, { min = 0, max = 100000 } = {}) {
  const n = Number(value);
  if (!Number.isFinite(n) || n < min || n > max) {
    const err = new Error(`${field} debe ser un número entre ${min} y ${max}.`);
    err.status = 400;
    throw err;
  }
  return Math.floor(n);
}

function parsePlanInput(body, { isCreate = false } = {}) {
  const name = String(body?.name || '').trim();
  if (!name) {
    const err = new Error('El nombre del plan es obligatorio.');
    err.status = 400;
    throw err;
  }
  if (name.length > 100) {
    const err = new Error('El nombre del plan no puede superar 100 caracteres.');
    err.status = 400;
    throw err;
  }

  const billingModel = normalizeBillingModel(body?.billing_model);
  if (isCreate && !body?.billing_model) {
    const err = new Error('Debe indicar el modelo de facturación.');
    err.status = 400;
    throw err;
  }

  let trialDays = null;
  if (billingModel === 'trial_days') {
    trialDays = parseLimit(body?.trial_days ?? 30, 'Días de demo', { min: 1, max: 3650 });
  } else if (body?.trial_days != null && body.trial_days !== '') {
    trialDays = parseLimit(body.trial_days, 'Días de demo', { min: 1, max: 3650 });
  }

  const priceRaw = body?.price;
  const price =
    priceRaw === '' || priceRaw == null
      ? 0
      : (() => {
          const p = Number(priceRaw);
          if (!Number.isFinite(p) || p < 0) {
            const err = new Error('El precio debe ser un número ≥ 0.');
            err.status = 400;
            throw err;
          }
          return p;
        })();

  const description =
    body?.description != null && String(body.description).trim()
      ? String(body.description).trim()
      : null;

  return {
    name,
    billing_model: billingModel,
    trial_days: trialDays,
    description,
    max_farms: 1,
    max_lots_per_farm: parseLimit(body?.max_lots_per_farm ?? 50, 'Fincas operativas', { min: 1 }),
    max_users_admin: parseLimit(body?.max_users_admin ?? 1, 'Usuarios admin', { min: 1 }),
    max_users_operario: parseLimit(body?.max_users_operario ?? 1, 'Usuarios operario', { min: 0 }),
    price,
  };
}

function assertImpactAcknowledged(impact, acknowledge) {
  if (impact.active_client_count > 0 && !acknowledge) {
    const err = new Error(
      'Debe confirmar el impacto en organizaciones activas antes de guardar.'
    );
    err.status = 409;
    err.code = PLAN_IMPACT_CODE;
    err.impact = impact;
    throw err;
  }
}

async function createPlan(body) {
  const input = parsePlanInput(body, { isCreate: true });
  const res = await pool.query(
    `INSERT INTO plans (
       name, billing_model, trial_days, description,
       max_farms, max_lots_per_farm, max_users_admin, max_users_operario,
       price, is_active
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, true)
     RETURNING id, name, billing_model, trial_days, description,
               max_farms, max_lots_per_farm, max_users_admin, max_users_operario,
               price, is_active, created_at`,
    [
      input.name,
      input.billing_model,
      input.trial_days,
      input.description,
      input.max_farms,
      input.max_lots_per_farm,
      input.max_users_admin,
      input.max_users_operario,
      input.price,
    ]
  );
  return mapPlanRow({ ...res.rows[0], active_client_count: 0 });
}

async function updatePlan(planId, body, { acknowledgeAffectedClients = false } = {}) {
  const id = String(planId || '').trim();
  const existing = await fetchPlanRowById(id);
  if (!existing) {
    const err = new Error('Plan no encontrado.');
    err.status = 404;
    throw err;
  }
  const impact = await getPlanImpact(id);
  assertImpactAcknowledged(impact, acknowledgeAffectedClients);

  const input = parsePlanInput({ ...existing, ...body });
  const res = await pool.query(
    `UPDATE plans SET
       name = $2,
       billing_model = $3,
       trial_days = $4,
       description = $5,
       max_farms = $6,
       max_lots_per_farm = $7,
       max_users_admin = $8,
       max_users_operario = $9,
       price = $10
     WHERE id = $1::uuid
     RETURNING id, name, billing_model, trial_days, description,
               max_farms, max_lots_per_farm, max_users_admin, max_users_operario,
               price, is_active, created_at`,
    [
      id,
      input.name,
      input.billing_model,
      input.trial_days,
      input.description,
      input.max_farms,
      input.max_lots_per_farm,
      input.max_users_admin,
      input.max_users_operario,
      input.price,
    ]
  );
  const row = await fetchPlanRowById(res.rows[0].id);
  return mapPlanRow(row);
}

async function deactivatePlan(planId, { acknowledgeAffectedClients = false } = {}) {
  const id = String(planId || '').trim();
  const existing = await fetchPlanRowById(id);
  if (!existing) {
    const err = new Error('Plan no encontrado.');
    err.status = 404;
    throw err;
  }
  if (!existing.is_active) {
    const err = new Error('El plan ya está inactivo.');
    err.status = 400;
    throw err;
  }
  const impact = await getPlanImpact(id);
  assertImpactAcknowledged(impact, acknowledgeAffectedClients);

  await pool.query(`UPDATE plans SET is_active = false WHERE id = $1::uuid`, [id]);
  const row = await fetchPlanRowById(id);
  return mapPlanRow(row);
}

module.exports = {
  PLAN_IMPACT_CODE,
  mapPlanRow,
  listActivePlans,
  listAllPlans,
  getPlanImpact,
  createPlan,
  updatePlan,
  deactivatePlan,
  fetchPlanRowById,
};
