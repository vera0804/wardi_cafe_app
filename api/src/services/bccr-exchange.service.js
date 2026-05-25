/**
 * Tipo de cambio USD vía API REST pública del BCCR (SDDE), con caché en memoria y reintentos.
 * Variables: BCCR_API_URL (base HTTPS, host en lista blanca/DNS), BCCR_ALLOWED_HOSTS (opcional),
 * BCCR_TOKEN (Bearer), BCCR_INDICADOR_VENTA, BCCR_INDICADOR_COMPRA.
 */

const { validateBccrFetchTarget, buildBccrSeriesUrl } = require('../lib/bccrUrlSafety');

const CACHE_TTL_MS = 6 * 60 * 60 * 1000;
const FETCH_TIMEOUT_MS = 20_000;
const MAX_ATTEMPTS = 2;

/** @type {Map<string, { rate: number, storedAt: number, validUntil: number }>} */
const memoryCache = new Map();

function getBccrEnvOrThrow() {
  const url = process.env.BCCR_API_URL && String(process.env.BCCR_API_URL).trim();
  const token = process.env.BCCR_TOKEN && String(process.env.BCCR_TOKEN).trim();
  if (!url || !token) {
    const err = new Error(
      'Falta configuración BCCR: defina BCCR_API_URL y BCCR_TOKEN en el entorno del servidor.'
    );
    err.status = 500;
    throw err;
  }
  return { url, token };
}

function getIndicatorForKind(kind) {
  const v =
    kind === 'compra'
      ? process.env.BCCR_INDICADOR_COMPRA && String(process.env.BCCR_INDICADOR_COMPRA).trim()
      : process.env.BCCR_INDICADOR_VENTA && String(process.env.BCCR_INDICADOR_VENTA).trim();
  if (!v) {
    const err = new Error(
      kind === 'compra'
        ? 'Falta BCCR_INDICADOR_COMPRA en el entorno del servidor.'
        : 'Falta BCCR_INDICADOR_VENTA en el entorno del servidor.'
    );
    err.status = 500;
    throw err;
  }
  return v;
}

function cacheKey(date, kind) {
  return `${date}:${kind}`;
}

function readFreshCache(key) {
  const e = memoryCache.get(key);
  if (!e) return null;
  if (Date.now() < e.validUntil) {
    return { rate: e.rate, source: 'cache', stale: false, warning: null };
  }
  return null;
}

function readStaleCache(key) {
  const e = memoryCache.get(key);
  if (!e) return null;
  return {
    rate: e.rate,
    source: 'cache',
    stale: true,
    warning: 'Último valor conocido: el servicio del BCCR no respondió; revise la conexión o intente más tarde.',
  };
}

function writeCache(key, rate) {
  const now = Date.now();
  memoryCache.set(key, {
    rate,
    storedAt: now,
    validUntil: now + CACHE_TTL_MS,
  });
}

/**
 * @param {unknown} payload
 * @param {string} isoDate YYYY-MM-DD
 * @returns {number}
 */
function extractRateFromJson(payload, isoDate) {
  if (!payload || typeof payload !== 'object') {
    const err = new Error('Respuesta JSON inválida del BCCR.');
    err.status = 502;
    throw err;
  }

  const body = /** @type {{ estado?: boolean, mensaje?: string, datos?: unknown[] }} */ (payload);

  if (body.estado !== true) {
    const err = new Error(body.mensaje || 'El BCCR no devolvió una consulta exitosa.');
    err.status = 502;
    throw err;
  }

  const datos = body.datos;
  if (!Array.isArray(datos) || datos.length === 0) {
    const err = new Error('No hay datos de indicador en la respuesta del BCCR.');
    err.status = 502;
    throw err;
  }

  const first = datos[0];
  const series = first && typeof first === 'object' ? /** @type {{ series?: unknown[] }} */ (first).series : null;

  if (!Array.isArray(series) || series.length === 0) {
    const err = new Error('No hay serie de tipo de cambio para la fecha solicitada.');
    err.status = 502;
    throw err;
  }

  const match =
    series.find((row) => {
      if (!row || typeof row !== 'object') return false;
      const fecha = String(/** @type {{ fecha?: string }} */ (row).fecha || '').slice(0, 10);
      return fecha === isoDate;
    }) || series[series.length - 1];

  const rate = Number(
    match && typeof match === 'object'
      ? /** @type {{ valorDatoPorPeriodo?: number }} */ (match).valorDatoPorPeriodo
      : NaN
  );

  if (!Number.isFinite(rate) || rate <= 0) {
    const err = new Error('Valor de tipo de cambio inválido en la respuesta del BCCR.');
    err.status = 502;
    throw err;
  }

  return rate;
}

/**
 * @param {number} status
 * @param {string} [bodySnippet]
 */
function errorFromBccrHttpStatus(status, bodySnippet) {
  const byStatus = {
    401: 'Token BCCR rechazado (401). Verifique BCCR_TOKEN.',
    403: 'Acceso denegado al API del BCCR (403).',
    429: 'Límite de consultas al BCCR excedido (429). Intente más tarde.',
    500: 'Error interno en el servicio del BCCR (500).',
    502: 'Puerta de enlace del BCCR no disponible (502).',
    503: 'Servicio del BCCR temporalmente no disponible (503).',
  };

  let message = byStatus[status] || `BCCR HTTP ${status}.`;
  if (bodySnippet) {
    const trimmed = bodySnippet.trim().slice(0, 200);
    if (trimmed) message = `${message} ${trimmed}`;
  }

  const err = new Error(message);
  err.status = status === 429 || status >= 500 ? 503 : 502;
  return err;
}

/**
 * @param {{ url: string, token: string }} params
 * @returns {Promise<unknown>}
 */
async function fetchBccrSeriesOnce({ url, token }) {
  const controller = new AbortController();
  const tid = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  try {
    const res = await fetch(url, {
      method: 'GET',
      redirect: 'manual',
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${token}`,
      },
      signal: controller.signal,
    });

    if (res.status >= 300 && res.status < 400) {
      const err = new Error(`BCCR rechazado: redirección HTTP ${res.status} (no permitida por SSRF)`);
      err.status = 502;
      throw err;
    }

    const text = await res.text();

    if (!res.ok) {
      throw errorFromBccrHttpStatus(res.status, text);
    }

    try {
      return JSON.parse(text);
    } catch {
      const err = new Error('El BCCR no devolvió JSON válido.');
      err.status = 502;
      throw err;
    }
  } finally {
    clearTimeout(tid);
  }
}

/**
 * @param {{ date: string, kind?: 'venta'|'compra' }} opts
 * @returns {Promise<{ date: string, kind: string, rate: number, source: 'bccr'|'cache', stale: boolean, warning: string | null }>}
 */
async function getUsdExchangeRate(opts) {
  const kind = opts.kind === 'compra' ? 'compra' : 'venta';
  const date = String(opts.date || '').slice(0, 10);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    const err = new Error('La fecha debe ser YYYY-MM-DD.');
    err.status = 400;
    throw err;
  }

  const key = cacheKey(date, kind);

  const fresh = readFreshCache(key);
  if (fresh) {
    return { date, kind, rate: fresh.rate, source: fresh.source, stale: false, warning: null };
  }

  const { url, token } = getBccrEnvOrThrow();
  const validatedBase = await validateBccrFetchTarget(url);
  const indicador = getIndicatorForKind(kind);
  const seriesUrl = buildBccrSeriesUrl(validatedBase, indicador, date);

  let lastErr = null;
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt += 1) {
    try {
      const json = await fetchBccrSeriesOnce({ url: seriesUrl, token });
      const rate = extractRateFromJson(json, date);
      writeCache(key, rate);
      return { date, kind, rate, source: 'bccr', stale: false, warning: null };
    } catch (e) {
      lastErr = e;
    }
  }

  const stale = readStaleCache(key);
  if (stale) {
    return { date, kind, rate: stale.rate, source: 'cache', stale: true, warning: stale.warning };
  }

  let msg = 'No se pudo obtener el tipo de cambio del BCCR.';
  let status = 503;

  if (lastErr) {
    if (lastErr.name === 'AbortError') {
      msg = 'Tiempo de espera agotado al consultar el BCCR.';
    } else if (lastErr.message) {
      msg = lastErr.message;
    }
    if (Number.isFinite(Number(lastErr.status))) {
      status = Number(lastErr.status);
    }
  }

  const err = new Error(msg);
  err.status = status;
  err.cause = lastErr;
  throw err;
}

module.exports = {
  getUsdExchangeRate,
  extractRateFromJson,
};
