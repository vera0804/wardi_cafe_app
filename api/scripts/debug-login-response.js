#!/usr/bin/env node
/* eslint-disable no-console */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const base = process.env.API_BASE || 'http://localhost:3000';
const email = process.argv[2];
const password = process.argv[3];

if (!email || !password) {
  console.error('Uso: node scripts/debug-login-response.js <email> <password>');
  process.exit(1);
}

async function main() {
  const jar = new Map();

  function storeCookies(res) {
    const raw = res.headers.getSetCookie?.() || [];
    for (const line of raw) {
      const part = line.split(';')[0];
      const eq = part.indexOf('=');
      if (eq > 0) jar.set(part.slice(0, eq), part.slice(eq + 1));
    }
  }

  function cookieHeader() {
    return [...jar.entries()].map(([k, v]) => `${k}=${v}`).join('; ');
  }

  const csrfRes = await fetch(`${base}/api/auth/csrf`, { redirect: 'manual' });
  storeCookies(csrfRes);
  const csrfBody = await csrfRes.json();
  const csrf = csrfBody?.csrfToken || jar.get('csrf_token') || '';

  const loginRes = await fetch(`${base}/api/auth/login`, {
    method: 'POST',
    redirect: 'manual',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      Cookie: cookieHeader(),
      'X-CSRF-Token': csrf,
    },
    body: JSON.stringify({ identifier: email, password }),
  });
  storeCookies(loginRes);
  const loginText = await loginRes.text();
  console.log('LOGIN status:', loginRes.status);
  console.log('LOGIN content-type:', loginRes.headers.get('content-type'));
  console.log('LOGIN body (first 500 chars):', loginText.slice(0, 500));
  try {
    const loginJson = JSON.parse(loginText);
    console.log('LOGIN keys:', Object.keys(loginJson));
    console.log('LOGIN id/email/role:', loginJson.id, loginJson.email, loginJson.role);
    if (loginJson.user) {
      console.log('LOGIN nested user keys:', Object.keys(loginJson.user));
    }
  } catch {
    console.log('LOGIN body is not JSON');
  }

  const meRes = await fetch(`${base}/api/auth/me`, {
    headers: { Accept: 'application/json', Cookie: cookieHeader() },
  });
  const meText = await meRes.text();
  console.log('\nME status:', meRes.status);
  console.log('ME body (first 500 chars):', meText.slice(0, 500));
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
