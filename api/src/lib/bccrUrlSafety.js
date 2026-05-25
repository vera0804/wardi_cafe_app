'use strict';

const dns = require('dns/promises');
const net = require('net');
const { URL } = require('url');

const METADATA_IPV4 = new Set(['169.254.169.254']);

/** @returns {Set<string>} */
function allowedHostnamesFromEnv() {
  const raw = process.env.BCCR_ALLOWED_HOSTS;
  if (!raw || !String(raw).trim()) {
    return new Set(['apim.bccr.fi.cr']);
  }
  return new Set(
    String(raw)
      .split(',')
      .map((s) => s.trim().toLowerCase())
      .filter(Boolean)
  );
}

function isDangerousIpv4(ip) {
  if (!net.isIPv4(ip)) return true;
  if (METADATA_IPV4.has(ip)) return true;
  const oct = ip.split('.').map(Number);
  const [a, b] = oct;
  if (a === 127) return true;
  if (a === 10) return true;
  if (a === 0) return true;
  if (a === 169 && b === 254) return true;
  if (a === 192 && b === 168) return true;
  if (a === 172 && b >= 16 && b <= 31) return true;
  return false;
}

function isDangerousIpv6(ip) {
  const s = net.isIPv6(ip) ? ip.toLowerCase() : '';
  if (!s) return true;
  if (s === '::1') return true;
  if (s.startsWith('fe80:')) return true;
  /* unique local RFC4193 fc00::/7 — prefix fc or fd after optional :: trimming */
  if (s.startsWith('fc') || s.startsWith('fd')) return true;
  /* IPv4-mapped (::ffff:x.x.x.x) */
  const m = /^::ffff:(\d+\.\d+\.\d+\.\d+)$/.exec(s);
  if (m) return isDangerousIpv4(m[1]);
  return false;
}

async function assertHostnameResolvesSafely(hostname) {
  const v4list = [];
  const v6list = [];
  try {
    v4list.push(...(await dns.resolve4(hostname)));
  } catch {
    /* no A */
  }
  try {
    v6list.push(...(await dns.resolve6(hostname)));
  } catch {
    /* no AAAA */
  }
  if (v4list.length === 0 && v6list.length === 0) {
    let once = null;
    try {
      once = await dns.lookup(hostname, { all: false });
    } catch {
      once = null;
    }
    if (!once?.address) {
      throw new Error(`No se resolvió el host '${hostname}' por DNS.`);
    }
    if (once.family === 6) v6list.push(once.address);
    else v4list.push(once.address);
  }
  for (const addr of v4list) {
    if (isDangerousIpv4(addr)) {
      throw new Error(`Dirección IPv4 no permitida (SSRF): ${addr}`);
    }
  }
  for (const addr of v6list) {
    if (isDangerousIpv6(addr)) {
      throw new Error(`Dirección IPv6 no permitida (SSRF): ${addr}`);
    }
  }
}

/**
 * Valida una URL destinada al fetch servidor-a-servidor (mitigación SSRF).
 *
 * @param {string} rawUrl
 */
async function validateBccrFetchTarget(rawUrl) {
  let u;
  try {
    u = new URL(String(rawUrl).trim());
  } catch {
    throw Object.assign(new Error('BCCR_API_URL no es una URL válida.'), { status: 500 });
  }

  if (u.protocol !== 'https:') {
    throw Object.assign(new Error('BCCR_API_URL debe usar HTTPS.'), { status: 500 });
  }

  if (u.username || u.password) {
    throw Object.assign(new Error('BCCR_API_URL no puede incluir usuario/contraseña embebidos.'), { status: 500 });
  }

  const hostnameRaw = String(u.hostname || '').trim().toLowerCase();

  if (hostnameRaw.endsWith('.onion')) {
    throw Object.assign(new Error('BCCR_API_URL: host TOR no permitido.'), { status: 500 });
  }

  if (net.isIP(hostnameRaw)) {
    throw Object.assign(
      new Error('BCCR_API_URL no puede usar IP literal; use el nombre de host permitido.'),
      { status: 500 }
    );
  }

  const allow = allowedHostnamesFromEnv();
  if (!allow.has(hostnameRaw)) {
    throw Object.assign(
      new Error(
        `BCCR_API_URL: host '${hostnameRaw}' no está en la lista permitida.` +
          ' Ajuste BCCR_ALLOWED_HOSTS con el hostname correcto.'
      ),
      { status: 500 }
    );
  }

  try {
    await assertHostnameResolvesSafely(hostnameRaw);
  } catch (e) {
    const msg = String(e?.message || e);
    throw Object.assign(new Error(`BCCR_DNS:${msg}`), { status: 500 });
  }

  /* Base API sin barra final; credenciales van en Authorization, no en la URL */
  return u.href.replace(/\/+$/, '');
}

/**
 * @param {string} isoDate YYYY-MM-DD
 * @returns {string} yyyy/mm/dd (formato REST SDDE)
 */
function isoToBccrRestDate(isoDate) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(isoDate).trim());
  if (!m) {
    throw Object.assign(new Error('La fecha debe ser YYYY-MM-DD.'), { status: 400 });
  }
  return `${m[1]}/${m[2]}/${m[3]}`;
}

/**
 * Construye la URL de series bajo la base validada (mismo host, sin SSRF).
 *
 * @param {string} validatedBaseHref
 * @param {string} indicador Código numérico (317, 318, …)
 * @param {string} isoDate YYYY-MM-DD
 * @returns {string}
 */
function buildBccrSeriesUrl(validatedBaseHref, indicador, isoDate) {
  const code = String(indicador || '').trim();
  if (!/^\d+$/.test(code)) {
    throw Object.assign(new Error('Código de indicador BCCR inválido.'), { status: 500 });
  }

  const base = new URL(`${validatedBaseHref.replace(/\/+$/, '')}/`);
  const allow = allowedHostnamesFromEnv();
  const host = base.hostname.toLowerCase();
  if (!allow.has(host)) {
    throw Object.assign(
      new Error(`BCCR: host '${host}' no está en la lista permitida.`),
      { status: 500 }
    );
  }

  const u = new URL(`indicadoresEconomicos/${encodeURIComponent(code)}/series`, base);
  const fecha = isoToBccrRestDate(isoDate);
  u.searchParams.set('fechaInicio', fecha);
  u.searchParams.set('fechaFin', fecha);
  u.searchParams.set('idioma', 'ES');

  if (u.hostname.toLowerCase() !== host) {
    throw Object.assign(new Error('URL de series BCCR con host no permitido.'), { status: 500 });
  }

  return u.href;
}

module.exports = {
  validateBccrFetchTarget,
  buildBccrSeriesUrl,
  isoToBccrRestDate,
  allowedHostnamesFromEnv,
};
