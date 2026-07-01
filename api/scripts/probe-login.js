#!/usr/bin/env node
/* eslint-disable no-console */
const base = process.env.API_BASE || 'http://localhost:3000';
const email = process.argv[2] || 'admin@wardi.local';
const password = process.argv[3] || 'WardiPrueba2026!';

async function main() {
  const health = await fetch(`${base}/api/health`);
  console.log('HEALTH', health.status, await health.text());

  const jar = new Map();
  const store = (res) => {
    for (const line of res.headers.getSetCookie?.() || []) {
      const part = line.split(';')[0];
      const eq = part.indexOf('=');
      if (eq > 0) jar.set(part.slice(0, eq), part.slice(eq + 1));
    }
  };
  const cookies = () => [...jar.entries()].map(([k, v]) => `${k}=${v}`).join('; ');

  const csrfRes = await fetch(`${base}/api/auth/csrf`);
  store(csrfRes);
  const csrfBody = await csrfRes.json();
  const csrf = csrfBody.csrfToken || jar.get('csrf_token');

  const loginRes = await fetch(`${base}/api/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      Cookie: cookies(),
      'X-CSRF-Token': csrf,
    },
    body: JSON.stringify({ identifier: email, password }),
  });
  store(loginRes);
  const loginText = await loginRes.text();
  console.log('LOGIN', loginRes.status, loginText);
}

main().catch(console.error);
