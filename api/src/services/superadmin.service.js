const crypto = require('crypto');
const bcrypt = require('bcrypt');
const { pool } = require('../db');
const { assertPasswordPolicy } = require('../lib/passwordPolicy');
const {
  buildLicenseFieldsFromPlan,
  fetchPlanForLicense,
  revokeAllSessionsForClient,
} = require('./client-license.service');
const {
  formatLicenseExpiryDisplay,
  normalizeBillingModel,
  toIsoDateFromDb,
} = require('../lib/licenseDates');
const { listActivePlans } = require('./superadmin-plans.service');

const CLIENT_STATUS_LABELS = {
  active: 'Activa',
  suspended: 'Suspendida',
  license_expired: 'Licencia vencida',
};

function normalizeClientStatus(status) {
  const s = String(status || 'active').trim().toLowerCase();
  if (s === 'suspended') return 'suspended';
  if (s === 'license_expired') return 'license_expired';
  return 'active';
}

function clientStatusLabel(status) {
  return CLIENT_STATUS_LABELS[normalizeClientStatus(status)] || status || '—';
}

const BCRYPT_ROUNDS = 12;

function normalizeEmail(value) {
  const v = String(value || '').trim().toLowerCase();
  if (!v) {
    const err = new Error('El correo del administrador es obligatorio.');
    err.status = 400;
    throw err;
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v)) {
    const err = new Error('El correo no tiene un formato válido.');
    err.status = 400;
    throw err;
  }
  return v;
}

function normalizeName(value, field) {
  const v = String(value || '').trim();
  if (!v) {
    const err = new Error(`${field} es obligatorio.`);
    err.status = 400;
    throw err;
  }
  return v;
}

function mapClientRow(row) {
  const expiresOn = toIsoDateFromDb(row.license_expires_on);
  const startsOn = toIsoDateFromDb(row.license_starts_on);
  const status = normalizeClientStatus(row.status);
  return {
    id: row.id,
    name: row.name,
    status,
    status_label: clientStatusLabel(status),
    plan_id: row.plan_id,
    plan_name: row.plan_name,
    plan_billing_model: row.plan_billing_model
      ? normalizeBillingModel(row.plan_billing_model)
      : null,
    license_starts_on: startsOn,
    license_expires_on: expiresOn,
    license_expires_on_display: formatLicenseExpiryDisplay(expiresOn),
    billing_anchor_day: row.billing_anchor_day,
    created_at: row.created_at,
  };
}

function mapClientDetailRow(row) {
  const base = mapClientRow(row);
  return {
    ...base,
    plan: row.plan_id
      ? {
          id: row.plan_id,
          name: row.plan_name,
          billing_model: row.plan_billing_model
            ? normalizeBillingModel(row.plan_billing_model)
            : null,
          billing_model_label: row.plan_billing_model
            ? normalizeBillingModel(row.plan_billing_model) === 'trial_days'
              ? 'Demo / días fijos'
              : normalizeBillingModel(row.plan_billing_model) === 'monthly_anchor'
                ? 'Mensual (día de pago)'
                : 'Sin vencimiento'
            : null,
          trial_days: row.trial_days,
          description: row.description,
          max_farms: row.max_farms,
          max_lots_per_farm: row.max_lots_per_farm,
          max_users_admin: row.max_users_admin,
          max_users_operario: row.max_users_operario,
          price: row.price != null ? Number(row.price) : 0,
          is_active: row.plan_is_active !== false,
        }
      : null,
    admin_email: row.admin_email || null,
    active_users_count: row.active_users_count != null ? Number(row.active_users_count) : 0,
    active_lots_count: row.active_lots_count != null ? Number(row.active_lots_count) : 0,
  };
}

const CLIENT_DETAIL_SELECT = `
  SELECT c.id, c.name, c.status, c.plan_id, c.created_at,
         c.license_starts_on, c.license_expires_on, c.billing_anchor_day,
         p.name AS plan_name, p.billing_model AS plan_billing_model,
         p.trial_days, p.description, p.max_farms, p.max_lots_per_farm,
         p.max_users_admin, p.max_users_operario, p.price, p.is_active AS plan_is_active,
         (SELECT COUNT(*)::int FROM users u WHERE u.client_id = c.id AND u.is_active = true) AS active_users_count,
         (SELECT COUNT(*)::int FROM lots l WHERE l.client_id = c.id AND l.is_active = true) AS active_lots_count,
         (SELECT u.email FROM users u
          INNER JOIN roles r ON r.id = u.role_id
          WHERE u.client_id = c.id AND u.is_active = true AND lower(trim(r.name)) = 'admin'
          ORDER BY u.created_at ASC NULLS LAST LIMIT 1) AS admin_email
  FROM clients c
  LEFT JOIN plans p ON p.id = c.plan_id`;

async function assertGlobalActiveEmailFree({ db, email, excludeUserId = null }) {
  const res = await db.query(
    `SELECT id FROM users
     WHERE lower(trim(email)) = lower(trim($1))
       AND is_active = true
       AND ($2::uuid IS NULL OR id <> $2::uuid)
     LIMIT 1`,
    [email, excludeUserId]
  );
  if (res.rows[0]) {
    const err = new Error('Ya existe otro usuario activo con este correo.');
    err.status = 409;
    throw err;
  }
}

async function listPlans() {
  return listActivePlans();
}

async function listClients() {
  const res = await pool.query(
    `${CLIENT_DETAIL_SELECT}
     ORDER BY c.name ASC`
  );
  return res.rows.map(mapClientRow);
}

async function getClientById(clientId) {
  const cid = String(clientId || '').trim();
  if (!cid) {
    const err = new Error('client_id es obligatorio.');
    err.status = 400;
    throw err;
  }
  const res = await pool.query(`${CLIENT_DETAIL_SELECT} WHERE c.id = $1::uuid`, [cid]);
  if (!res.rows[0]) {
    const err = new Error('Organización no encontrada.');
    err.status = 404;
    throw err;
  }
  return mapClientDetailRow(res.rows[0]);
}

async function updateClient({ clientId, name }) {
  const cid = String(clientId || '').trim();
  const n = String(name || '').trim();
  if (!n) {
    const err = new Error('El nombre de la organización es obligatorio.');
    err.status = 400;
    throw err;
  }
  const res = await pool.query(
    `UPDATE clients SET name = $2 WHERE id = $1::uuid RETURNING id`,
    [cid, n]
  );
  if (!res.rowCount) {
    const err = new Error('Organización no encontrada.');
    err.status = 404;
    throw err;
  }
  return getClientById(cid);
}

async function setClientStatus({ clientId, status }) {
  const cid = String(clientId || '').trim();
  const norm = normalizeClientStatus(status);
  if (norm !== 'active' && norm !== 'suspended') {
    const err = new Error('Estado no válido. Use active o suspended.');
    err.status = 400;
    throw err;
  }
  const res = await pool.query(`SELECT id, status FROM clients WHERE id = $1::uuid`, [cid]);
  if (!res.rows[0]) {
    const err = new Error('Organización no encontrada.');
    err.status = 404;
    throw err;
  }
  await pool.query(`UPDATE clients SET status = $2 WHERE id = $1::uuid`, [cid, norm]);
  if (norm === 'suspended') {
    await revokeAllSessionsForClient(cid, { reason: 'client_suspended' });
  }
  return getClientById(cid);
}

async function getRoleIdByName(db, roleNameNorm) {
  const res = await db.query(`SELECT id FROM roles WHERE lower(trim(name)) = $1 LIMIT 1`, [
    roleNameNorm,
  ]);
  return res.rows[0]?.id || null;
}

/**
 * Crea cliente + usuario administrador inicial (rol admin).
 */
async function createClientWithAdmin({
  clientName,
  planId,
  licenseStartsOn,
  billingAnchorDay,
  trialDaysOverride,
  adminEmail,
  adminPasswordPlain,
  adminFirstName,
  adminLastName1,
  adminLastName2,
  createdBySuperadminUserId,
}) {
  const name = String(clientName || '').trim();
  if (!name) {
    const err = new Error('El nombre de la organización es obligatorio.');
    err.status = 400;
    throw err;
  }
  const plan = String(planId || '').trim();
  if (!plan) {
    const err = new Error('Debe seleccionar un plan.');
    err.status = 400;
    throw err;
  }
  const email = normalizeEmail(adminEmail);
  const pwd = assertPasswordPolicy(adminPasswordPlain);
  const fn = normalizeName(adminFirstName, 'Nombre del administrador');
  const ln1 = normalizeName(adminLastName1, 'Primer apellido');
  const ln2 =
    adminLastName2 != null && String(adminLastName2).trim() ? String(adminLastName2).trim() : null;

  const db = await pool.connect();
  try {
    await db.query('BEGIN');
    const planRow = await fetchPlanForLicense(db, plan);
    if (!planRow) {
      const err = new Error('El plan indicado no existe.');
      err.status = 400;
      throw err;
    }
    if (planRow.is_active === false) {
      const err = new Error('El plan seleccionado está inactivo. Elija otro plan o reactive este plan.');
      err.status = 400;
      throw err;
    }
    const license = buildLicenseFieldsFromPlan({
      planRow,
      licenseStartsOn,
      billingAnchorDay,
      trialDaysOverride,
    });
    await assertGlobalActiveEmailFree({ db, email, excludeUserId: null });

    const insClient = await db.query(
      `INSERT INTO clients (
         name, plan_id, status,
         license_starts_on, license_expires_on, billing_anchor_day
       )
       VALUES ($1, $2::uuid, 'active', $3::date, $4::date, $5)
       RETURNING id, name, plan_id, status, license_starts_on, license_expires_on,
                 billing_anchor_day, created_at`,
      [
        name,
        plan,
        license.license_starts_on,
        license.license_expires_on,
        license.billing_anchor_day,
      ]
    );
    const client = insClient.rows[0];
    const adminRoleId = await getRoleIdByName(db, 'admin');
    if (!adminRoleId) {
      const err = new Error('Rol admin no configurado en el sistema.');
      err.status = 500;
      throw err;
    }
    const idNumber = `ADM-${crypto.randomUUID().replace(/-/g, '')}`;
    const hash = await bcrypt.hash(pwd, BCRYPT_ROUNDS);
    await db.query(
      `INSERT INTO users (
         is_active, first_name, last_name_1, last_name_2, email,
         phone_1, phone_2, id_type, id_number, password_hash,
         client_id, role_id, created_by_user_id, updated_by_user_id
       )
       VALUES (true, $1, $2, $3, $4, NULL, NULL, 'extranjero'::id_type, $5, $6, $7::uuid, $8::uuid, $9::uuid, $9::uuid)`,
      [fn, ln1, ln2, email, idNumber, hash, client.id, adminRoleId, createdBySuperadminUserId]
    );
    await db.query(
      `INSERT INTO farms (
         name, client_id, labor_allocation_mode, area_ha_manual,
         created_by_user_id, updated_by_user_id
       )
       VALUES ($1, $2, 'manual', false, $3, $3)`,
      [name, client.id, createdBySuperadminUserId]
    );
    await db.query('COMMIT');

    const list = await pool.query(
      `SELECT c.id, c.name, c.status, c.plan_id, c.created_at,
              c.license_starts_on, c.license_expires_on, c.billing_anchor_day,
              p.name AS plan_name, p.billing_model AS plan_billing_model
       FROM clients c
       LEFT JOIN plans p ON p.id = c.plan_id
       WHERE c.id = $1`,
      [client.id]
    );
    return mapClientRow(list.rows[0]);
  } catch (e) {
    await db.query('ROLLBACK');
    if (e.code === '23505') {
      const err = new Error('Conflicto de datos únicos (correo o identificación).');
      err.status = 409;
      throw err;
    }
    throw e;
  } finally {
    db.release();
  }
}

/**
 * Renueva licencia del cliente (nueva fecha inicio + recálculo de vencimiento).
 */
async function renewClientLicense({
  clientId,
  planId,
  licenseStartsOn,
  billingAnchorDay,
  trialDaysOverride,
}) {
  const cid = String(clientId || '').trim();
  if (!cid) {
    const err = new Error('client_id es obligatorio.');
    err.status = 400;
    throw err;
  }

  const db = await pool.connect();
  try {
    await db.query('BEGIN');
    const clientRes = await db.query(
      `SELECT id, plan_id FROM clients WHERE id = $1::uuid FOR UPDATE`,
      [cid]
    );
    const client = clientRes.rows[0];
    if (!client) {
      const err = new Error('Organización no encontrada.');
      err.status = 404;
      throw err;
    }
    const effectivePlanId = planId != null && String(planId).trim() ? String(planId).trim() : client.plan_id;
    const planRow = await fetchPlanForLicense(db, effectivePlanId);
    if (!planRow) {
      const err = new Error('Plan no encontrado.');
      err.status = 400;
      throw err;
    }
    if (
      planId != null &&
      String(planId).trim() &&
      String(planId).trim() !== String(client.plan_id) &&
      planRow.is_active === false
    ) {
      const err = new Error('El plan seleccionado está inactivo. Elija otro plan o reactive este plan.');
      err.status = 400;
      throw err;
    }
    const license = buildLicenseFieldsFromPlan({
      planRow,
      licenseStartsOn,
      billingAnchorDay,
      trialDaysOverride,
    });
    const upd = await db.query(
      `UPDATE clients
       SET plan_id = $2::uuid,
           status = 'active',
           license_starts_on = $3::date,
           license_expires_on = $4::date,
           billing_anchor_day = $5
       WHERE id = $1::uuid
       RETURNING id`,
      [
        cid,
        effectivePlanId,
        license.license_starts_on,
        license.license_expires_on,
        license.billing_anchor_day,
      ]
    );
    if (!upd.rowCount) {
      const err = new Error('No se pudo renovar la licencia.');
      err.status = 500;
      throw err;
    }
    await db.query('COMMIT');
    return getClientById(cid);
  } catch (e) {
    await db.query('ROLLBACK');
    throw e;
  } finally {
    db.release();
  }
}

module.exports = {
  listPlans,
  listClients,
  getClientById,
  updateClient,
  setClientStatus,
  createClientWithAdmin,
  renewClientLicense,
};
