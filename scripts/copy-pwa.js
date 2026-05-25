#!/usr/bin/env node
/**
 * Copia pwa/dist → api/public para despliegue único (Express + SPA).
 */
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const src = path.join(root, 'pwa', 'dist');
const dest = path.join(root, 'api', 'public');

if (!fs.existsSync(src)) {
  console.error('No existe pwa/dist. Ejecute primero: cd pwa && npm run build');
  process.exit(1);
}

fs.rmSync(dest, { recursive: true, force: true });
fs.mkdirSync(dest, { recursive: true });
fs.cpSync(src, dest, { recursive: true });
console.log('✓ PWA copiada a api/public');
