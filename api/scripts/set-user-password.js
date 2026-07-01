#!/usr/bin/env node
/* eslint-disable no-console */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const bcrypt = require('bcrypt');
const { pool } = require('../src/db');
const { bcryptCost } = require('../src/config');

const email = process.argv[2];
const newPassword = process.argv[3];

if (!email || !newPassword) {
  console.error('Uso: node scripts/set-user-password.js <email> <nueva-contraseña>');
  process.exit(1);
}

async function main() {
  const hash = await bcrypt.hash(newPassword, bcryptCost);
  const res = await pool.query(
    `UPDATE users
     SET password_hash = $1,
         failed_attempts = 0,
         locked_until = NULL,
         updated_at = now()
     WHERE lower(email) = lower($2)
     RETURNING email`,
    [hash, email]
  );
  if (res.rowCount === 0) {
    console.error('No se encontró usuario con ese correo.');
    process.exit(1);
  }
  console.log(`Contraseña actualizada para ${res.rows[0].email}`);
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
