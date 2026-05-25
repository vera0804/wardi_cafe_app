import { useEffect, useMemo, useState } from 'react';
import {
  createLotProduction,
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

const DEFAULT_FORM = {
  farm_id: '',
  lot_id: '',
  prod_date: today(),
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
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [listError, setListError] = useState('');
  const [modalError, setModalError] = useState('');

  const canWrite = canWriteCoffeeProduction(user);

  const filterLots = useMemo(() => {
    if (!filters.farm_id) return meta.lots;
    return meta.lots.filter((l) => l.farm_id === filters.farm_id);
  }, [meta.lots, filters.farm_id]);

  const formLots = useMemo(() => {
    if (!form.farm_id) return meta.lots;
    return meta.lots.filter((l) => l.farm_id === form.farm_id);
  }, [meta.lots, form.farm_id]);

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
    setForm({ ...DEFAULT_FORM, prod_date: today() });
    setEditingId(null);
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
      cajuelas: String(row.cajuelas ?? ''),
      notes: row.notes || '',
    });
    setModalError('');
    setShowModal(true);
  }

  function closeModal() {
    setShowModal(false);
    setModalError('');
    resetForm();
  }

  async function handleSubmit(e) {
    e.preventDefault();
    if (!canWrite) return;
    setModalError('');
    setSaving(true);
    const payload = {
      lot_id: form.lot_id,
      prod_date: form.prod_date,
      cajuelas: Number(form.cajuelas),
      notes: form.notes || null,
    };
    try {
      if (editingId) {
        await updateLotProduction(editingId, payload);
      } else {
        await createLotProduction(payload);
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
            Registra cajuelas cosechadas por lote y fecha. Las fanegas se calculan automáticamente (÷ 20).
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
          <div className="w-full max-w-lg overflow-auto rounded-xl bg-white p-4 text-slate-800 shadow-xl">
            <div className="mb-3 flex items-center justify-between">
              <h4 className="text-base font-semibold text-lime-800">
                {editingId ? 'Editar producción' : 'Registrar producción'}
              </h4>
              <button type="button" onClick={closeModal} className="text-sm text-slate-500">
                Cerrar
              </button>
            </div>
            <form className="space-y-3" onSubmit={handleSubmit}>
              <label className="block text-sm">
                Finca
                <select
                  required
                  value={form.farm_id}
                  onChange={(e) => setForm((p) => ({ ...p, farm_id: e.target.value, lot_id: '' }))}
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
              <label className="block text-sm">
                Lote
                <select
                  required
                  value={form.lot_id}
                  onChange={(e) => setForm((p) => ({ ...p, lot_id: e.target.value }))}
                  className="mt-1 w-full rounded border border-slate-300 px-2 py-2 text-sm"
                  disabled={!form.farm_id}
                >
                  <option value="">Seleccione lote</option>
                  {formLots.map((l) => (
                    <option key={l.id} value={l.id}>
                      {l.name}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block text-sm">
                Fecha de producción
                <input
                  type="date"
                  required
                  value={form.prod_date}
                  onChange={(e) => setForm((p) => ({ ...p, prod_date: e.target.value }))}
                  className="mt-1 w-full rounded border border-slate-300 px-2 py-2 text-sm"
                />
              </label>
              <label className="block text-sm">
                Cajuelas
                <input
                  type="number"
                  min="0"
                  step="0.01"
                  required
                  value={form.cajuelas}
                  onChange={(e) => setForm((p) => ({ ...p, cajuelas: e.target.value }))}
                  className="mt-1 w-full rounded border border-slate-300 px-2 py-2 text-sm"
                />
              </label>
              <label className="block text-sm">
                Notas (opcional)
                <textarea
                  rows={3}
                  value={form.notes}
                  onChange={(e) => setForm((p) => ({ ...p, notes: e.target.value }))}
                  className="mt-1 w-full rounded border border-slate-300 px-2 py-2 text-sm"
                />
              </label>
              {modalError ? (
                <p className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800">
                  {modalError}
                </p>
              ) : null}
              <div className="flex justify-end gap-2 pt-1">
                <button
                  type="button"
                  onClick={closeModal}
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="rounded-lg bg-lime-700 px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
                >
                  {saving ? 'Guardando…' : 'Guardar'}
                </button>
              </div>
            </form>
          </div>
        </div>
      ) : null}
    </section>
  );
}
