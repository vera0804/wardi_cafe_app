import { useEffect, useMemo, useState } from 'react';
import {
  createLotProduction,
  createLotProductionBulk,
  getLotProductionMeta,
  listLotProduction,
  setLotProductionActive,
  updateLotProduction,
} from '../services/lotProduction.js';
import { canWriteCoffeeProduction } from '../layouts/dashboardMenuData.js';

function today() {
  return new Date().toISOString().slice(0, 10);
}

function formatDateDisplay(iso) {
  const [y, m, d] = String(iso || '').split('-');
  if (!y || !m || !d) return iso;
  return `${d}/${m}/${y}`;
}

function formatNum(value, digits = 2) {
  const n = Number(value);
  if (!Number.isFinite(n)) return '—';
  return n.toLocaleString('es-CR', { minimumFractionDigits: 0, maximumFractionDigits: digits });
}

const BULK_DAY_ABBREV = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

function formatBulkDayLabel(isoDate) {
  const d = new Date(`${isoDate}T12:00:00`);
  return `${BULK_DAY_ABBREV[d.getDay()]} ${isoDate}`;
}

function buildBulkDateRange(fromDate, toDate) {
  if (!fromDate || !toDate || fromDate > toDate) return [];
  const out = [];
  let current = new Date(`${fromDate}T12:00:00`);
  const end = new Date(`${toDate}T12:00:00`);
  while (current <= end) {
    const y = current.getFullYear();
    const m = String(current.getMonth() + 1).padStart(2, '0');
    const day = String(current.getDate()).padStart(2, '0');
    out.push(`${y}-${m}-${day}`);
    current.setDate(current.getDate() + 1);
  }
  return out;
}

const DEFAULT_FORM = {
  farm_id: '',
  lot_id: '',
  prod_date: today(),
  from_date: today(),
  to_date: today(),
  is_bulk: false,
  cajuelas: '',
  notes: '',
};

export default function CoffeeProductionPage({ user }) {
  const [meta, setMeta] = useState({ farms: [], lots: [] });
  const [filters, setFilters] = useState({
    from_date: '',
    to_date: '',
    active: 'true',
    farm_id: '',
    lot_id: '',
  });
  const [rows, setRows] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState(DEFAULT_FORM);
  const [dailyCajuelasByDate, setDailyCajuelasByDate] = useState({});
  const [excludedBulkDates, setExcludedBulkDates] = useState(() => new Set());
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [listError, setListError] = useState('');
  const [modalError, setModalError] = useState('');

  const canWrite = canWriteCoffeeProduction(user);
  const isBulkCreate = form.is_bulk && !editingId;

  const filterLots = useMemo(() => {
    if (!filters.farm_id) return meta.lots;
    return meta.lots.filter((l) => l.farm_id === filters.farm_id);
  }, [meta.lots, filters.farm_id]);

  const formLots = useMemo(() => {
    if (!form.farm_id) return meta.lots;
    return meta.lots.filter((l) => l.farm_id === form.farm_id);
  }, [meta.lots, form.farm_id]);

  const bulkDates = useMemo(() => {
    if (!isBulkCreate) return [];
    return buildBulkDateRange(form.from_date, form.to_date);
  }, [isBulkCreate, form.from_date, form.to_date]);

  const bulkDatesIncluded = useMemo(
    () => bulkDates.filter((d) => !excludedBulkDates.has(d)),
    [bulkDates, excludedBulkDates]
  );

  useEffect(() => {
    if (!isBulkCreate || bulkDates.length === 0) return;
    setExcludedBulkDates((prev) => {
      const range = new Set(bulkDates);
      let changed = false;
      const next = new Set();
      for (const d of prev) {
        if (range.has(d)) next.add(d);
        else changed = true;
      }
      if (!changed && next.size === prev.size) return prev;
      return next;
    });
  }, [isBulkCreate, bulkDates]);

  useEffect(() => {
    (async () => {
      try {
        const data = await getLotProductionMeta();
        setMeta({ farms: data?.farms || [], lots: data?.lots || [] });
      } catch (e) {
        setListError(e?.message || 'No se pudo cargar catálogo de fincas y lotes.');
      }
    })();
  }, []);

  async function refresh() {
    setLoading(true);
    setListError('');
    try {
      const entries = await listLotProduction(filters);
      setRows(entries || []);
    } catch (e) {
      setListError(e?.message || 'No se pudo cargar producción de café.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
  }, [filters.from_date, filters.to_date, filters.active, filters.farm_id, filters.lot_id]);

  function setFilter(field, value) {
    setFilters((prev) => {
      const next = { ...prev, [field]: value };
      if (field === 'farm_id') next.lot_id = '';
      return next;
    });
  }

  function resetForm() {
    setForm({ ...DEFAULT_FORM, prod_date: today(), from_date: today(), to_date: today() });
    setEditingId(null);
    setDailyCajuelasByDate({});
    setExcludedBulkDates(new Set());
  }

  function openCreate() {
    resetForm();
    setModalError('');
    setShowModal(true);
  }

  function openEdit(row) {
    const farmId = meta.lots.find((l) => l.id === row.lot_id)?.farm_id || '';
    setEditingId(row.id);
    setForm({
      farm_id: farmId,
      lot_id: row.lot_id || '',
      prod_date: String(row.prod_date).slice(0, 10),
      from_date: today(),
      to_date: today(),
      is_bulk: false,
      cajuelas: String(row.cajuelas ?? ''),
      notes: row.notes || '',
    });
    setDailyCajuelasByDate({});
    setExcludedBulkDates(new Set());
    setModalError('');
    setShowModal(true);
  }

  function closeModal() {
    setShowModal(false);
    setModalError('');
    resetForm();
  }

  function onFormChange(field, value) {
    setForm((prev) => {
      const next = { ...prev, [field]: value };
      if (field === 'farm_id') next.lot_id = '';
      return next;
    });
    if (field === 'from_date' || field === 'to_date' || field === 'is_bulk' || field === 'cajuelas') {
      if (field === 'from_date' || field === 'to_date' || field === 'is_bulk') {
        setExcludedBulkDates(new Set());
      }
      if (field !== 'is_bulk') {
        setDailyCajuelasByDate({});
      }
    }
  }

  function setBulkDayIncluded(date, included) {
    setExcludedBulkDates((prev) => {
      const next = new Set(prev);
      if (included) next.delete(date);
      else next.add(date);
      return next;
    });
  }

  function includeAllBulkDays() {
    setExcludedBulkDates(new Set());
  }

  function excludeSundaysInBulk() {
    setExcludedBulkDates((prev) => {
      const next = new Set(prev);
      for (const d of bulkDates) {
        if (new Date(`${d}T12:00:00`).getDay() === 0) next.add(d);
      }
      return next;
    });
  }

  function excludeWeekendsInBulk() {
    setExcludedBulkDates((prev) => {
      const next = new Set(prev);
      for (const d of bulkDates) {
        const dow = new Date(`${d}T12:00:00`).getDay();
        if (dow === 0 || dow === 6) next.add(d);
      }
      return next;
    });
  }

  function cajuelasForDate(date) {
    const specific = dailyCajuelasByDate[date];
    if (specific === undefined || specific === null || specific === '') {
      return Number(form.cajuelas || 0);
    }
    return Number(specific || 0);
  }

  function validateForm() {
    if (!form.farm_id || !form.lot_id) return 'Seleccione finca y lote.';
    const baseCaj = Number(form.cajuelas);
    if (!isBulkCreate) {
      if (!form.prod_date) return 'Indique la fecha de producción.';
      if (!Number.isFinite(baseCaj) || baseCaj < 0) {
        return 'Las cajuelas deben ser un número mayor o igual a 0.';
      }
      return null;
    }
    if (!form.from_date || !form.to_date) return 'Indique el rango de fechas.';
    if (form.from_date > form.to_date) return 'Rango de fechas inválido.';
    if (bulkDatesIncluded.length === 0) {
      return 'Debe incluir al menos un día del rango para registrar.';
    }
    if (!Number.isFinite(baseCaj) || baseCaj < 0) {
      return 'Indique cajuelas por defecto o por cada día incluido.';
    }
    const hasInvalid = bulkDatesIncluded.some(
      (d) => !Number.isFinite(cajuelasForDate(d)) || cajuelasForDate(d) < 0
    );
    if (hasInvalid) return 'Cada día incluido debe tener cajuelas mayor o igual a 0.';
    return null;
  }

  async function handleSubmit(e) {
    e.preventDefault();
    if (!canWrite) return;
    const validation = validateForm();
    if (validation) {
      setModalError(validation);
      return;
    }
    setModalError('');
    setSaving(true);
    try {
      if (editingId) {
        await updateLotProduction(editingId, {
          lot_id: form.lot_id,
          prod_date: form.prod_date,
          cajuelas: Number(form.cajuelas),
          notes: form.notes || null,
        });
      } else if (isBulkCreate) {
        await createLotProductionBulk({
          lot_id: form.lot_id,
          from_date: form.from_date,
          to_date: form.to_date,
          notes: form.notes || null,
          daily_items: bulkDatesIncluded.map((d) => ({
            prod_date: d,
            cajuelas: cajuelasForDate(d),
          })),
        });
      } else {
        await createLotProduction({
          lot_id: form.lot_id,
          prod_date: form.prod_date,
          cajuelas: Number(form.cajuelas),
          notes: form.notes || null,
        });
      }
      closeModal();
      await refresh();
    } catch (err) {
      setModalError(err?.message || 'No se pudo guardar la producción.');
    } finally {
      setSaving(false);
    }
  }

  async function handleToggleActive(row) {
    if (!canWrite) return;
    setSaving(true);
    setListError('');
    try {
      await setLotProductionActive(row.id, !row.is_active);
      await refresh();
    } catch (err) {
      setListError(err?.message || 'No se pudo cambiar el estado.');
    } finally {
      setSaving(false);
    }
  }

  return (
    <section className="space-y-4 rounded-2xl border border-white/50 bg-white/90 p-5 text-slate-800 shadow">
      <header className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h3 className="text-base font-semibold text-lime-800">Producción de café</h3>
          <p className="text-sm text-slate-600">
            Registra cajuelas cosechadas por lote y fecha. Las fanegas se calculan automáticamente (÷ 20). Puedes cargar
            un rango de días y excluir los que no hubo cosecha.
          </p>
        </div>
        {canWrite ? (
          <button
            type="button"
            onClick={openCreate}
            className="rounded-lg bg-lime-700 px-4 py-2 text-sm font-semibold text-white"
          >
            Registrar producción
          </button>
        ) : null}
      </header>

      <div className="grid grid-cols-1 gap-3 rounded-xl border border-slate-200 bg-slate-50 p-3 sm:grid-cols-2 lg:grid-cols-5">
        <label className="flex flex-col gap-1 text-xs text-slate-600">
          Desde
          <input
            type="date"
            value={filters.from_date}
            onChange={(e) => setFilter('from_date', e.target.value)}
            className="rounded border border-slate-300 px-2 py-1.5 text-sm"
          />
        </label>
        <label className="flex flex-col gap-1 text-xs text-slate-600">
          Hasta
          <input
            type="date"
            value={filters.to_date}
            onChange={(e) => setFilter('to_date', e.target.value)}
            className="rounded border border-slate-300 px-2 py-1.5 text-sm"
          />
        </label>
        <label className="flex flex-col gap-1 text-xs text-slate-600">
          Estado
          <select
            value={filters.active}
            onChange={(e) => setFilter('active', e.target.value)}
            className="rounded border border-slate-300 px-2 py-1.5 text-sm"
          >
            <option value="true">Activos</option>
            <option value="false">Inactivos</option>
            <option value="all">Todos</option>
          </select>
        </label>
        <label className="flex flex-col gap-1 text-xs text-slate-600">
          Finca
          <select
            value={filters.farm_id}
            onChange={(e) => setFilter('farm_id', e.target.value)}
            className="rounded border border-slate-300 px-2 py-1.5 text-sm"
          >
            <option value="">Todas</option>
            {meta.farms.map((f) => (
              <option key={f.id} value={f.id}>
                {f.name}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-xs text-slate-600">
          Lote
          <select
            value={filters.lot_id}
            onChange={(e) => setFilter('lot_id', e.target.value)}
            className="rounded border border-slate-300 px-2 py-1.5 text-sm"
            disabled={!filters.farm_id && filterLots.length === meta.lots.length}
          >
            <option value="">Todos</option>
            {filterLots.map((l) => (
              <option key={l.id} value={l.id}>
                {l.name}
              </option>
            ))}
          </select>
        </label>
      </div>

      {listError ? (
        <p className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800">{listError}</p>
      ) : null}

      <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table className="min-w-full text-sm">
          <thead className="bg-slate-100 text-left">
            <tr>
              <th className="px-3 py-2">Fecha</th>
              <th className="px-3 py-2">Semana</th>
              <th className="px-3 py-2">Finca · Lote</th>
              <th className="px-3 py-2 text-right">Cajuelas</th>
              <th className="px-3 py-2 text-right">Fanegas</th>
              <th className="px-3 py-2">Notas</th>
              <th className="px-3 py-2">Estado</th>
              <th className="px-3 py-2 text-right">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={8} className="px-3 py-3 text-center text-slate-500">
                  Cargando…
                </td>
              </tr>
            ) : null}
            {!loading && rows.length === 0 ? (
              <tr>
                <td colSpan={8} className="px-3 py-3 text-center text-slate-500">
                  Sin registros.
                </td>
              </tr>
            ) : null}
            {!loading
              ? rows.map((r) => (
                  <tr key={r.id} className="border-t border-slate-100">
                    <td className="px-3 py-2 whitespace-nowrap">{formatDateDisplay(String(r.prod_date).slice(0, 10))}</td>
                    <td className="px-3 py-2 whitespace-nowrap">{r.work_week || '—'}</td>
                    <td className="px-3 py-2">
                      {r.farm_name ? `${r.farm_name} · ` : ''}
                      {r.lot_name || '—'}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums">{formatNum(r.cajuelas)}</td>
                    <td className="px-3 py-2 text-right tabular-nums">{formatNum(r.fanegas, 4)}</td>
                    <td className="max-w-[200px] truncate px-3 py-2 text-slate-600" title={r.notes || ''}>
                      {r.notes || '—'}
                    </td>
                    <td className="px-3 py-2">{r.is_active ? 'Activo' : 'Inactivo'}</td>
                    <td className="px-3 py-2">
                      <div className="flex justify-end gap-2">
                        {canWrite ? (
                          <>
                            <button
                              type="button"
                              onClick={() => openEdit(r)}
                              disabled={saving}
                              className="rounded border border-slate-300 px-2 py-1 text-xs"
                            >
                              Editar
                            </button>
                            <button
                              type="button"
                              onClick={() => handleToggleActive(r)}
                              disabled={saving}
                              className={`rounded px-2 py-1 text-xs font-semibold ${
                                r.is_active
                                  ? 'bg-rose-100 text-rose-700 hover:bg-rose-200'
                                  : 'bg-emerald-100 text-emerald-700 hover:bg-emerald-200'
                              }`}
                            >
                              {r.is_active ? 'Inactivar' : 'Activar'}
                            </button>
                          </>
                        ) : (
                          <span className="text-xs text-slate-500">Solo consulta</span>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              : null}
          </tbody>
        </table>
      </div>

      {showModal ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 p-4">
          <div className="max-h-[90vh] w-full max-w-4xl overflow-auto rounded-xl bg-white p-4 shadow-xl sm:p-5 text-slate-800">
            <div className="mb-3 flex items-center justify-between">
              <h4 className="text-base font-semibold text-lime-800">
                {editingId ? 'Editar producción' : 'Registrar producción'}
              </h4>
              <button type="button" onClick={closeModal} className="text-sm text-slate-500">
                Cerrar
              </button>
            </div>
            <form className="grid grid-cols-1 gap-3 md:grid-cols-2" onSubmit={handleSubmit}>
              <label className="block text-sm md:col-span-1">
                Finca
                <select
                  required
                  value={form.farm_id}
                  onChange={(e) => onFormChange('farm_id', e.target.value)}
                  disabled={saving}
                  className="mt-1 w-full rounded border border-slate-300 px-2 py-2 text-sm"
                >
                  <option value="">Seleccione finca</option>
                  {meta.farms.map((f) => (
                    <option key={f.id} value={f.id}>
                      {f.name}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block text-sm md:col-span-1">
                Lote
                <select
                  required
                  value={form.lot_id}
                  onChange={(e) => onFormChange('lot_id', e.target.value)}
                  disabled={saving || !form.farm_id}
                  className="mt-1 w-full rounded border border-slate-300 px-2 py-2 text-sm"
                >
                  <option value="">Seleccione lote</option>
                  {formLots.map((l) => (
                    <option key={l.id} value={l.id}>
                      {l.name}
                    </option>
                  ))}
                </select>
              </label>

              {!editingId ? (
                <label className="inline-flex items-center gap-2 text-sm md:col-span-2">
                  <input
                    type="checkbox"
                    checked={form.is_bulk}
                    onChange={(e) => onFormChange('is_bulk', e.target.checked)}
                    disabled={saving}
                    className="h-4 w-4 rounded border-slate-300"
                  />
                  Carga por rango de fechas
                </label>
              ) : null}

              {isBulkCreate ? (
                <div className="md:col-span-2 space-y-3">
                  <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                    <label className="block text-sm">
                      Desde *
                      <input
                        type="date"
                        required
                        value={form.from_date}
                        onChange={(e) => onFormChange('from_date', e.target.value)}
                        disabled={saving}
                        className="mt-1 w-full rounded border border-slate-300 px-2 py-2 text-sm"
                      />
                    </label>
                    <label className="block text-sm">
                      Hasta *
                      <input
                        type="date"
                        required
                        value={form.to_date}
                        onChange={(e) => onFormChange('to_date', e.target.value)}
                        disabled={saving}
                        className="mt-1 w-full rounded border border-slate-300 px-2 py-2 text-sm"
                      />
                    </label>
                  </div>
                  <label className="block text-sm">
                    Cajuelas por día (valor por defecto)
                    <input
                      type="number"
                      min="0"
                      step="0.01"
                      required
                      value={form.cajuelas}
                      onChange={(e) => onFormChange('cajuelas', e.target.value)}
                      disabled={saving}
                      className="mt-1 w-full rounded border border-slate-300 px-2 py-2 text-sm"
                    />
                    <span className="mt-1 block text-xs text-slate-500">
                      Se aplica a cada día incluido; puede ajustar por día abajo.
                    </span>
                  </label>
                  <div className="rounded border border-slate-200 bg-slate-50 p-3">
                    <div className="mb-2 flex flex-wrap items-center justify-between gap-2">
                      <h5 className="text-sm font-semibold text-slate-700">Días del rango</h5>
                      {bulkDates.length > 0 ? (
                        <span className="text-xs font-medium text-slate-600">
                          Se registrarán {bulkDatesIncluded.length} de {bulkDates.length} día(s)
                        </span>
                      ) : null}
                    </div>
                    {bulkDates.length > 0 ? (
                      <div className="mb-3 flex flex-wrap gap-2">
                        <button
                          type="button"
                          onClick={includeAllBulkDays}
                          disabled={saving || excludedBulkDates.size === 0}
                          className="rounded border border-slate-300 bg-white px-2 py-1 text-xs disabled:opacity-50"
                        >
                          Incluir todos
                        </button>
                        <button
                          type="button"
                          onClick={excludeSundaysInBulk}
                          disabled={saving}
                          className="rounded border border-slate-300 bg-white px-2 py-1 text-xs"
                        >
                          Excluir domingos
                        </button>
                        <button
                          type="button"
                          onClick={excludeWeekendsInBulk}
                          disabled={saving}
                          className="rounded border border-slate-300 bg-white px-2 py-1 text-xs"
                        >
                          Excluir sábados y domingos
                        </button>
                      </div>
                    ) : null}
                    {bulkDates.length === 0 ? (
                      <p className="text-sm text-slate-500">Selecciona un rango válido.</p>
                    ) : (
                      <div className="grid grid-cols-1 gap-2 sm:grid-cols-2 lg:grid-cols-3">
                        {bulkDates.map((d) => {
                          const included = !excludedBulkDates.has(d);
                          return (
                            <div
                              key={d}
                              className={`flex items-center gap-2 rounded border border-slate-200 bg-white px-2 py-1.5 text-sm ${
                                included ? '' : 'opacity-45'
                              }`}
                            >
                              <input
                                type="checkbox"
                                checked={included}
                                onChange={(e) => setBulkDayIncluded(d, e.target.checked)}
                                disabled={saving}
                                className="h-4 w-4 shrink-0 rounded border-slate-300"
                                aria-label={`Registrar ${formatBulkDayLabel(d)}`}
                              />
                              <span className={`min-w-0 flex-1 ${included ? 'text-slate-800' : 'text-slate-500'}`}>
                                {formatBulkDayLabel(d)}
                              </span>
                              {included ? (
                                <input
                                  type="number"
                                  min="0"
                                  step="0.01"
                                  value={dailyCajuelasByDate[d] ?? String(form.cajuelas || '')}
                                  onChange={(e) =>
                                    setDailyCajuelasByDate((prev) => ({ ...prev, [d]: e.target.value }))
                                  }
                                  disabled={saving}
                                  className="w-20 rounded border border-slate-300 px-2 py-1 text-right tabular-nums"
                                />
                              ) : null}
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                </div>
              ) : (
                <>
                  <label className="block text-sm md:col-span-1">
                    Fecha de producción
                    <input
                      type="date"
                      required
                      value={form.prod_date}
                      onChange={(e) => onFormChange('prod_date', e.target.value)}
                      disabled={saving}
                      className="mt-1 w-full rounded border border-slate-300 px-2 py-2 text-sm"
                    />
                  </label>
                  <label className="block text-sm md:col-span-1">
                    Cajuelas
                    <input
                      type="number"
                      min="0"
                      step="0.01"
                      required
                      value={form.cajuelas}
                      onChange={(e) => onFormChange('cajuelas', e.target.value)}
                      disabled={saving}
                      className="mt-1 w-full rounded border border-slate-300 px-2 py-2 text-sm"
                    />
                  </label>
                </>
              )}

              <label className="block text-sm md:col-span-2">
                Notas (opcional)
                <textarea
                  rows={3}
                  value={form.notes}
                  onChange={(e) => onFormChange('notes', e.target.value)}
                  disabled={saving}
                  className="mt-1 w-full rounded border border-slate-300 px-2 py-2 text-sm"
                />
              </label>
              {modalError ? (
                <p className="md:col-span-2 rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800">
                  {modalError}
                </p>
              ) : null}
              <div className="flex justify-end gap-2 pt-1 md:col-span-2">
                <button
                  type="button"
                  onClick={closeModal}
                  disabled={saving}
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="rounded-lg bg-lime-700 px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
                >
                  {saving
                    ? 'Guardando…'
                    : isBulkCreate && bulkDatesIncluded.length > 0
                      ? `Registrar ${bulkDatesIncluded.length} día${bulkDatesIncluded.length === 1 ? '' : 's'}`
                      : 'Guardar'}
                </button>
              </div>
            </form>
          </div>
        </div>
      ) : null}
    </section>
  );
}
