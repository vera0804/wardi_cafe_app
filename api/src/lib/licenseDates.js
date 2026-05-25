/**
 * Cálculo de fechas de licencia (solo fechas calendario YYYY-MM-DD, sin hora).
 */

const ISO_DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

function pad2(n) {
  return String(n).padStart(2, '0');
}

/** Normaliza valor `date` de PostgreSQL (Date, string ISO o timestamp). */
function toIsoDateFromDb(value) {
  if (value == null || value === '') return null;
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) return null;
    return value.toISOString().slice(0, 10);
  }
  const s = String(value).trim();
  const m = /^(\d{4}-\d{2}-\d{2})/.exec(s);
  if (m) return m[1];
  const d = new Date(s);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString().slice(0, 10);
}

function parseIsoDate(iso) {
  const s = String(iso || '').trim();
  if (!ISO_DATE_RE.test(s)) return null;
  const [y, m, d] = s.split('-').map(Number);
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return { y, m, d };
}

function toIsoDate({ y, m, d }) {
  return `${y}-${pad2(m)}-${pad2(d)}`;
}

function daysInMonth(year, month) {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

/** Fecha de hoy en zona horaria IANA (por defecto America/Costa_Rica). */
function todayIsoInTimeZone(timeZone = 'America/Costa_Rica') {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(new Date());
  const y = parts.find((p) => p.type === 'year')?.value;
  const m = parts.find((p) => p.type === 'month')?.value;
  const d = parts.find((p) => p.type === 'day')?.value;
  if (!y || !m || !d) return null;
  return `${y}-${m}-${d}`;
}

function addCalendarDays(isoStart, days) {
  const start = parseIsoDate(isoStart);
  if (!start || !Number.isFinite(days) || days < 0) return null;
  const dt = new Date(Date.UTC(start.y, start.m - 1, start.d));
  dt.setUTCDate(dt.getUTCDate() + days);
  return toIsoDate({
    y: dt.getUTCFullYear(),
    m: dt.getUTCMonth() + 1,
    d: dt.getUTCDate(),
  });
}

/**
 * Vencimiento mensual: mismo día del mes siguiente al inicio/renovación.
 * Si el día no existe (p. ej. 31 → febrero), se usa el último día del mes.
 */
function monthlyAnchorExpiry(isoStart, anchorDay) {
  const start = parseIsoDate(isoStart);
  if (!start) return null;
  const anchor = Math.min(28, Math.max(1, Number(anchorDay) || start.d));
  let month = start.m + 1;
  let year = start.y;
  if (month > 12) {
    month = 1;
    year += 1;
  }
  const dim = daysInMonth(year, month);
  const day = Math.min(anchor, dim);
  return toIsoDate({ y: year, m: month, d: day });
}

function normalizeBillingModel(value) {
  const v = String(value || '')
    .trim()
    .toLowerCase();
  if (v === 'trial_days' || v === 'monthly_anchor' || v === 'perpetual') return v;
  return 'perpetual';
}

/**
 * @param {{ billingModel: string, trialDays?: number|null, startIso: string, anchorDay?: number|null, trialDaysOverride?: number|null }}
 */
function computeLicenseExpiresOn({
  billingModel,
  trialDays,
  startIso,
  anchorDay,
  trialDaysOverride,
}) {
  const model = normalizeBillingModel(billingModel);
  const start = parseIsoDate(startIso);
  if (!start) return null;

  if (model === 'perpetual') return null;

  if (model === 'trial_days') {
    const days =
      trialDaysOverride != null && Number.isFinite(Number(trialDaysOverride))
        ? Math.max(1, Math.floor(Number(trialDaysOverride)))
        : Math.max(1, Math.floor(Number(trialDays) || 30));
    return addCalendarDays(startIso, days);
  }

  if (model === 'monthly_anchor') {
    const anchor =
      anchorDay != null && Number.isFinite(Number(anchorDay))
        ? Math.min(28, Math.max(1, Math.floor(Number(anchorDay))))
        : Math.min(28, start.d);
    return monthlyAnchorExpiry(startIso, anchor);
  }

  return null;
}

/** Vigente si no hay vencimiento o hoy <= vencimiento (inclusive). */
function isLicenseValidOnDate(licenseExpiresOn, todayIso) {
  if (!licenseExpiresOn) return true;
  const exp = parseIsoDate(licenseExpiresOn);
  const today = parseIsoDate(todayIso);
  if (!exp || !today) return true;
  if (today.y !== exp.y) return today.y < exp.y;
  if (today.m !== exp.m) return today.m < exp.m;
  return today.d <= exp.d;
}

/** dd-mm-yyyy para UI */
function formatLicenseExpiryDisplay(licenseExpiresOn) {
  const p = parseIsoDate(licenseExpiresOn);
  if (!p) return null;
  return `${pad2(p.d)}-${pad2(p.m)}-${p.y}`;
}

function resolveAnchorDay({ billingModel, startIso, billingAnchorDay }) {
  const model = normalizeBillingModel(billingModel);
  if (model !== 'monthly_anchor') return null;
  if (billingAnchorDay != null && Number.isFinite(Number(billingAnchorDay))) {
    return Math.min(28, Math.max(1, Math.floor(Number(billingAnchorDay))));
  }
  const start = parseIsoDate(startIso);
  return start ? Math.min(28, start.d) : 1;
}

module.exports = {
  ISO_DATE_RE,
  toIsoDateFromDb,
  parseIsoDate,
  todayIsoInTimeZone,
  addCalendarDays,
  monthlyAnchorExpiry,
  computeLicenseExpiresOn,
  isLicenseValidOnDate,
  formatLicenseExpiryDisplay,
  normalizeBillingModel,
  resolveAnchorDay,
};
