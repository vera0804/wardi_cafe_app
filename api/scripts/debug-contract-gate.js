#!/usr/bin/env node
/* eslint-disable no-console */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const { pool } = require('../src/db');
const appContract = require('../src/services/appContract.service');
const config = require('../src/config');

async function main() {
  console.log('APP_CONTRACT_VERSION (config):', config.appContractVersion);

  const tbl = await pool.query(`SELECT to_regclass('public.app_contracts') AS tbl`);
  console.log('app_contracts table:', tbl.rows[0]?.tbl || 'MISSING');

  const mig = await pool.query(
    `SELECT filename, applied_at FROM schema_migrations WHERE filename LIKE '%app_contract%'`
  );
  console.log('migrations applied:', mig.rows);

  if (tbl.rows[0]?.tbl) {
    const contracts = await pool.query(
      `SELECT ac.client_id, c.name AS client_name, ac.version, ac.is_active, ac.accepted_at, u.email AS accepted_by_email
       FROM app_contracts ac
       LEFT JOIN clients c ON c.id = ac.client_id
       LEFT JOIN users u ON u.id = ac.accepted_by
       ORDER BY ac.accepted_at DESC`
    );
    console.log('\napp_contracts rows:', contracts.rows.length);
    for (const r of contracts.rows) {
      console.log(' -', r.client_name || r.client_id, '| v' + r.version, '| active:', r.is_active, '| by:', r.accepted_by_email);
    }
  }

  const users = await pool.query(
    `SELECT u.id, u.email, r.name AS role, u.client_id, c.name AS client_name
     FROM users u
     JOIN roles r ON r.id = u.role_id
     LEFT JOIN clients c ON c.id = u.client_id
     WHERE u.is_active = true
     ORDER BY r.name, u.email`
  );

  console.log('\nContract gate per active user:');
  for (const u of users.rows) {
    const fields = await appContract.getContractGateFields(u.client_id, u.role);
    console.log(
      ` - ${u.email} [${u.role}] client=${u.client_name || u.client_id || 'null'}`,
      '=> requires:', fields.requiresContractAcceptance,
      '| current v:', fields.contractVersion,
      fields.previousContractVersion ? `| prev v: ${fields.previousContractVersion}` : ''
    );
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
