'use strict';

const { pool } = require('../db');
const config = require('../config');

function roleNameNorm(role) {
  return String(role || '').trim().toLowerCase();
}

function getContractVersion() {
  return config.appContractVersion;
}

function contractGateAppliesToRole(role) {
  const r = roleNameNorm(role);
  return r === 'admin' || r === 'administrador';
}

/**
 * Versión activa aceptada para el cliente (puede no coincidir con la vigente en servidor).
 * @param {string | null | undefined} clientId
 * @returns {Promise<string | null>}
 */
async function getActiveAcceptedVersion(clientId) {
  const cid = clientId != null ? String(clientId).trim() : '';
  if (!cid) return null;
  const res = await pool.query(
    `SELECT version
     FROM app_contracts
     WHERE client_id = $1::uuid
       AND is_active = true
     ORDER BY accepted_at DESC
     LIMIT 1`,
    [cid]
  );
  const v = res.rows[0]?.version;
  return v != null ? String(v).trim() : null;
}

/**
 * @param {string | null | undefined} clientId
 */
async function hasActiveContract(clientId) {
  const cid = clientId != null ? String(clientId).trim() : '';
  if (!cid) return false;
  const currentVersion = getContractVersion();
  const res = await pool.query(
    `SELECT 1
     FROM app_contracts
     WHERE client_id = $1::uuid
       AND is_active = true
       AND version = $2
     LIMIT 1`,
    [cid, currentVersion]
  );
  return res.rowCount > 0;
}

/**
 * @param {string | null | undefined} clientId
 * @param {string | null | undefined} role
 */
async function requiresContractAcceptance(clientId, role) {
  if (!contractGateAppliesToRole(role)) return false;
  return !(await hasActiveContract(clientId));
}

/**
 * @param {string | null | undefined} clientId
 * @param {string | null | undefined} role
 */
async function getContractGateFields(clientId, role) {
  const contractVersion = getContractVersion();
  if (!contractGateAppliesToRole(role)) {
    return {
      contractVersion,
      requiresContractAcceptance: false,
      previousContractVersion: null,
    };
  }
  const cid = clientId != null ? String(clientId).trim() : '';
  let acceptedVersion = null;
  if (cid) {
    try {
      acceptedVersion = await getActiveAcceptedVersion(cid);
    } catch {
      acceptedVersion = null;
    }
  }
  let requires = true;
  if (cid) {
    try {
      requires = !(await hasActiveContract(cid));
    } catch {
      requires = true;
    }
  }
  const previousContractVersion =
    requires && acceptedVersion && acceptedVersion !== contractVersion ? acceptedVersion : null;
  return {
    contractVersion,
    requiresContractAcceptance: requires,
    previousContractVersion,
  };
}

/**
 * @param {Record<string, unknown>} user
 */
async function enrichUserProfile(user) {
  const fields = await getContractGateFields(
    user?.clientId != null ? String(user.clientId) : null,
    user?.role
  );
  return {
    ...user,
    ...fields,
  };
}

/**
 * @param {{ clientId: string, userId: string, version?: string }} params
 */
async function recordContractAcceptance({ clientId, userId, version }) {
  const cid = String(clientId || '').trim();
  const uid = String(userId || '').trim();
  const ver = String(version || getContractVersion()).trim();
  if (!cid || !uid) {
    const err = new Error('Organización o usuario no disponible.');
    err.status = 400;
    throw err;
  }
  if (!ver) {
    const err = new Error('Versión del contrato no válida.');
    err.status = 400;
    throw err;
  }
  if (ver !== getContractVersion()) {
    const err = new Error(
      `La versión enviada (${ver}) no coincide con la vigente (${getContractVersion()}).`
    );
    err.status = 400;
    throw err;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(
      `UPDATE app_contracts
       SET is_active = false
       WHERE client_id = $1::uuid`,
      [cid]
    );
    await client.query(
      `INSERT INTO app_contracts (client_id, version, accepted_by, is_active)
       VALUES ($1::uuid, $2, $3::uuid, true)
       ON CONFLICT (client_id, version)
       DO UPDATE SET
         is_active = true,
         accepted_by = EXCLUDED.accepted_by,
         accepted_at = now()`,
      [cid, ver, uid]
    );
    await client.query('COMMIT');
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

module.exports = {
  getContractVersion,
  contractGateAppliesToRole,
  getActiveAcceptedVersion,
  hasActiveContract,
  requiresContractAcceptance,
  getContractGateFields,
  enrichUserProfile,
  recordContractAcceptance,
};
