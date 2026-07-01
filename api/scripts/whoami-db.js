#!/usr/bin/env node
/* eslint-disable no-console */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const { pool } = require('../src/db');

function describeDatabaseUrl(url) {
  if (!url) return { configured: false };
  try {
    const u = new URL(url);
    return {
      configured: true,
      host: u.hostname,
      port: u.port || '5432',
      database: u.pathname.replace(/^\//, '') || '(default)',
      user: u.username || '(default)',
    };
  } catch {
    return { configured: true, raw: '(formato no URL estándar)' };
  }
}

async function main() {
  const info = describeDatabaseUrl(process.env.DATABASE_URL);
  console.log('=== Conexión API Wardi (api/.env) ===');
  console.log(info);

  const meta = await pool.query(`
    SELECT
      current_database() AS database,
      current_user AS db_user,
      inet_server_addr()::text AS server_ip,
      inet_server_port() AS server_port
  `);
  console.log('\n=== PostgreSQL (sesión activa) ===');
  console.table(meta.rows);

  const users = await pool.query(`
    SELECT u.email, r.name AS role
    FROM users u
    JOIN roles r ON r.id = u.role_id
    WHERE u.is_active
    ORDER BY u.email
    LIMIT 15
  `);
  console.log('\n=== Usuarios activos (muestra) ===');
  console.table(users.rows);

  const contracts = await pool.query(`
    SELECT to_regclass('public.app_contracts') AS app_contracts_table
  `);
  const count = await pool.query(`SELECT count(*)::int AS n FROM app_contracts`);
  console.log('\n=== Términos (app_contracts) ===');
  console.log('tabla:', contracts.rows[0]?.app_contracts_table || 'NO EXISTE');
  console.log('registros:', count.rows[0]?.n ?? '—');

  const clients = await pool.query(`
    SELECT id, name, status FROM clients ORDER BY created_at LIMIT 5
  `);
  console.log('\n=== Organizaciones (muestra) ===');
  console.table(clients.rows);
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error('Error al conectar:', e.message);
    process.exit(1);
  });
