const { pool } = require('../db');
const config = require('../config');
const auditService = require('./audit.service');
const {
  computeLicenseExpiresOn,
  isLicenseValidOnDate,
  formatLicenseExpiryDisplay,
  todayIsoInTimeZone,
  normalizeBillingModel,
  resolveAnchorDay,
  ISO_DATE_RE,
  toIsoDateFromDb,
} = require('../lib/licenseDates');

function clientLicenseRowToMeta(row) {
  if (!row) return { valid: true, expiresOn: null, expiresOnDisplay: null };
  const today = todayIsoInTimeZone(config.licenseTimezone);
  const expiresOn = toIsoDateFromDb(row.license_expires_on);
  const status = String(row.status || '').trim().toLowerCase();
  const dateValid = isLicenseValidOnDate(expiresOn, today);
  const statusOk = status === 'active' || status === '';
  return {
    valid: statusOk && dateValid,
    expiresOn,
    expiresOnDisplay: formatLicenseExpiryDisplay(expiresOn),
    startsOn: toIsoDateFromDb(row.license_starts_on),
    status,
  };
}

function assertIsoDate(value, fieldLabel) {
  const s = String(value || '').trim();
  if (!s) return todayIsoInTimeZone(config.licenseTimezone);
  if (!ISO_DATE_RE.test(s)) {
    const err = new Error(`${fieldLabel} debe tener formato AAAA-MM-DD.`);
    err.status = 400;
    throw err;
  }
  return s;
}

async function fetchPlanForLicense(db, planId) {
  const res = await db.query(
    `SELECT id, name, billing_model, trial_days, max_farms, max_lots_per_farm,
            max_users_admin, max_users_operario, price, description, is_active
     FROM plans WHERE id = $1::uuid LIMIT 1`,
    [planId]
  );
  return res.rows[0] || null;
}

function buildLicenseFieldsFromPlan({
  planRow,
  licenseStartsOn,
  billingAnchorDay,
  trialDaysOverride,
}) {
  const startIso = assertIsoDate(licenseStartsOn, 'Fecha de inicio de licencia');
  const billingModel = normalizeBillingModel(planRow.billing_model);
  const anchor = resolveAnchorDay({
    billingModel,
    startIso,
    billingAnchorDay,
  });
  const expiresOn = computeLicenseExpiresOn({
    billingModel,
    trialDays: planRow.trial_days,
    startIso,
    anchorDay: anchor,
    trialDaysOverride,
  });
  return {
    license_starts_on: startIso,
    license_expires_on: expiresOn,
    billing_anchor_day: anchor,
  };
}

async function revokeAllSessionsForClient(clientId, { reason = 'license_expired' } = {}) {
  const res = await pool.query(
    `UPDATE sessions s
     SET revoked_at = NOW()
     WHERE s.revoked_at IS NULL
       AND (
         s.user_id IN (SELECT id FROM users WHERE client_id = $1::uuid)
         OR s.acting_client_id = $1::uuid
       )
     RETURNING s.id`,
    [clientId]
  );
  if (res.rowCount > 0) {
    await auditService.logSecurityEvent({
      eventType: 'license_sessions_revoked',
      userId: null,
      clientId,
      metadata: { revokedCount: res.rowCount, reason },
    });
  }
  return res.rowCount;
}

/**
 * Cron diario (23:59): clientes cuya licencia venció antes de hoy o status pendiente de cierre.
 */
async function processExpiredLicenses({ todayIso } = {}) {
  const today = todayIso || todayIsoInTimeZone(config.licenseTimezone);
  const res = await pool.query(
    `SELECT id, name, status, license_expires_on
     FROM clients
     WHERE license_expires_on IS NOT NULL
       AND license_expires_on <= $1::date
       AND lower(trim(coalesce(status, ''))) = 'active'`,
    [today]
  );
  let processed = 0;
  for (const row of res.rows) {
    await pool.query(
      `UPDATE clients SET status = 'license_expired' WHERE id = $1::uuid`,
      [row.id]
    );
    await revokeAllSessionsForClient(row.id, { reason: 'license_cron' });
    await auditService.logSecurityEvent({
      eventType: 'license_expired',
      userId: null,
      clientId: row.id,
      metadata: {
        clientName: row.name,
        licenseExpiresOn: row.license_expires_on,
        processedOn: today,
      },
    });
    processed += 1;
  }
  return { processed, today };
}

function isClientLicenseActive(clientRow) {
  return clientLicenseRowToMeta(clientRow).valid;
}

module.exports = {
  clientLicenseRowToMeta,
  buildLicenseFieldsFromPlan,
  fetchPlanForLicense,
  revokeAllSessionsForClient,
  processExpiredLicenses,
  isClientLicenseActive,
  formatLicenseExpiryDisplay,
};
