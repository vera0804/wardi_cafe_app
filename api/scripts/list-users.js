#!/usr/bin/env node
/* eslint-disable no-console */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const { pool } = require('../src/db');

async function main() {
  const res = await pool.query(
    `SELECT u.email, r.name AS role, u.is_active,
            (u.locked_until IS NOT NULL AND u.locked_until > now()) AS locked
     FROM users u
     JOIN roles r ON r.id = u.role_id
     ORDER BY r.name, u.email`
  );
  console.table(res.rows);
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
