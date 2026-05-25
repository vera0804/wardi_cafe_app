const LOCALE = 'es-CR';

/** Número legible: sin decimales si son solo ceros; hasta `maxDigits` si hacen falta (ej. 1,5). */
export function num(n, maxDigits = 2) {
  if (n == null || Number.isNaN(Number(n))) return '—';
  return Number(n).toLocaleString(LOCALE, {
    minimumFractionDigits: 0,
    maximumFractionDigits: maxDigits,
  });
}

export function crc(n) {
  if (n == null || Number.isNaN(Number(n))) return '—';
  const x = Math.round(Number(n) * 100) / 100;
  return `₡${num(x, 2)}`;
}

/** Fanegas del periodo (compat. con campo legacy `kg` en JSON). */
export function fanegasOf(row) {
  const f = Number(row?.fanegas);
  if (Number.isFinite(f)) return f;
  const legacy = Number(row?.kg);
  return Number.isFinite(legacy) ? legacy : 0;
}

export function marginPerFanegaCrc(row) {
  if (row == null) return null;
  const fromApi = row.margin_per_fanega_crc;
  if (fromApi != null && Number.isFinite(Number(fromApi))) return Number(fromApi);
  const fanegas = fanegasOf(row);
  if (fanegas <= 0 || row.margin_crc == null || Number.isNaN(Number(row.margin_crc))) return null;
  return Number(row.margin_crc) / fanegas;
}

export function formatMarginPerFanega(row) {
  const v = marginPerFanegaCrc(row);
  return v != null ? crc(v) : '—';
}

export function marginToneClass(value) {
  return Number(value) >= 0 ? 'text-emerald-700' : 'text-red-700';
}

export function isCoffeeStats(data) {
  return String(data?.production_mode || '').toLowerCase() === 'cafe';
}

export function formatPeriodLine(data, { harvestLabel } = {}) {
  if (!data?.period) return null;
  let line = `Periodo aplicado: ${data.period.from} — ${data.period.to}`;
  if (data.filters?.farm_id) line += ' · Finca filtrada';
  if (data.filters?.lot_id) line += ' · Lote filtrado';
  if (harvestLabel) line += ` · Cosecha: ${harvestLabel}`;
  return line;
}

export function defaultDateRange() {
  const to = new Date();
  const from = new Date();
  from.setUTCDate(from.getUTCDate() - 89);
  return {
    from: from.toISOString().slice(0, 10),
    to: to.toISOString().slice(0, 10),
  };
}

export function TableWrap({ children }) {
  return (
    <div className="overflow-x-auto rounded-xl border border-stone-200 bg-white shadow-sm">
      <table className="w-full min-w-[720px] text-sm">{children}</table>
    </div>
  );
}
