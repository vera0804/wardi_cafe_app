#!/usr/bin/env node
/* eslint-disable no-console */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

async function main() {
  const base = process.env.API_BASE || 'http://localhost:3000';
  const email = process.argv[2] || 'admin@wardi.local';
  const password = process.argv[3] || 'admin123';

  const csrfRes = await fetch(`${base}/api/auth/csrf`, { credentials: 'include' });
  const csrfCookie = csrfRes.headers.get('set-cookie') || '';
  const csrf = /csrf_token=([^;]+)/.exec(csrfCookie)?.[1] || '';

  const loginRes = await fetch(`${base}/api/auth/login`, {
    method: 'POST',
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      Cookie: csrfCookie,
      'X-CSRF-Token': decodeURIComponent(csrf),
    },
    body: JSON.stringify({ identifier: email, password }),
  });
  const loginBody = await loginRes.json();
  const loginCookies = loginRes.headers.get('set-cookie') || csrfCookie;

  console.log('LOGIN', loginRes.status);
  console.log('role:', loginBody.role);
  console.log('requiresContractAcceptance:', loginBody.requiresContractAcceptance);
  console.log('contractVersion:', loginBody.contractVersion);
  console.log('clientId:', loginBody.clientId);

  const meRes = await fetch(`${base}/api/auth/me`, {
    credentials: 'include',
    headers: { Accept: 'application/json', Cookie: loginCookies },
  });
  const meBody = await meRes.json();
  console.log('\nME', meRes.status);
  console.log('requiresContractAcceptance:', meBody.requiresContractAcceptance);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
