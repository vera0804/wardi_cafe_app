import { useEffect, useMemo, useState } from 'react';
import { isTenantAdmin } from '../../layouts/dashboardMenuData.js';
import FxRateUsdField from '../../shared/FxRateUsdField.jsx';
import {
  createHarvest,
  listHarvests,
  setHarvestActive,
  updateHarvest,
} from '../../services/harvests.js';

const DEFAULT_FILTERS = { active: 'active', year: '', from_date: '', to_date: '' };

function formatCrc(n) {
  if (n == null || !Number.isFinite(Number(n))) return '—';
  return Number(n).toLocaleString('es-CR', { style: 'currency', currency: 'CRC' });
}

function formatUsd(n) {
  if (n == null || !Number.isFinite(Number(n))) return '—';
  return Number(n).toLocaleString('en-US', { style: 'currency', currency: 'USD' });
}

function formatPriceCell(row) {
  if (row.price_per_fanega == null) return '—';
  if (row.currency === 'USD' && row.price_per_fanega_usd != null) {
    return `${formatUsd(row.price_per_fanega_usd)} → ${formatCrc(row.price_per_fanega)}`;
  }
  return formatCrc(row.price_per_fanega);
}

function pricePreview(currency, priceInput, fxRate) {
  const p = Number(priceInput);
  if (!Number.isFinite(p) || p <= 0) return null;
  if (currency === 'USD') {
    const fx = Number(fxRate);
    if (!Number.isFinite(fx) || fx <= 0) return null;
    return formatCrc(p * fx);
  }
  return formatCrc(p);
}

const EMPTY_CREATE = {
  year_from: String(new Date().getFullYear()),
  currency: 'CRC',
  price_input: '',
  fx_rate: '',
};

function buildPricePayload(form) {
  const body = { currency: form.currency };
  const raw = String(form.price_input ?? '').trim();
  if (!raw) return body;
  body.price_input = Number(raw);
  if (form.currency === 'USD') body.fx_rate = Number(form.fx_rate);
  return body;
}

export default function HarvestPeriodsSettingsSection({ user }) {
  const canWrite = isTenantAdmin(user);
  const [rows, setRows] = useState([]);
  const [filters, setFilters] = useState(DEFAULT_FILTERS);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [createError, setCreateError] = useState('');

  const [createOpen, setCreateOpen] = useState(false);
  const [createForm, setCreateForm] = useState(EMPTY_CREATE);

  const [editRow, setEditRow] = useState(null);
  const [editForm, setEditForm] = useState(null);
  const [chainWarnings, setChainWarnings] = useState([]);

  const createYearTo = useMemo(() => {
    const y = Number(createForm.year_from);
    return Number.isInteger(y) ? y + 1 : '';
  }, [createForm.year_from]);

  const createPreview = pricePreview(
    createForm.currency,
    createForm.price_input,
    createForm.fx_rate
  );
  const editPreview =
    editForm &&
    pricePreview(editForm.currency, editForm.price_input, editForm.fx_rate);

  async function refresh() {
    setLoading(true);
    setError('');
    try {
      const q = { active: filters.active };
      if (filters.year) q.year = filters.year;
      if (filters.from_date) q.from_date = filters.from_date;
      if (filters.to_date) q.to_date = filters.to_date;
      const data = await listHarvests(q);
      setRows(data || []);
    } catch (e) {
      setError(e?.message || 'No se pudieron cargar las cosechas.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
  }, [filters.active, filters.year, filters.from_date, filters.to_date, user?.clientId]);

  function openEdit(row) {
    setChainWarnings([]);
    setEditRow(row);
    setEditForm({
      start_date: row.start_date,
      end_date: row.end_date,
      currency: row.currency || 'CRC',
      price_input:
        row.currency === 'USD' && row.price_per_fanega_usd != null
          ? String(row.price_per_fanega_usd)
          : row.price_per_fanega != null
            ? String(row.price_per_fanega)
            : '',
      fx_rate: row.price_fx_rate != null ? String(row.price_fx_rate) : '',
    });
  }

  async function handleCreate(e) {
    e.preventDefault();
    if (!canWrite) return;
    const yearFrom = Number(createForm.year_from);
    const yearTo = yearFrom + 1;
    if (!Number.isInteger(yearFrom)) {
      setCreateError('Indique un año inicial válido.');
      return;
    }
    if (createForm.currency === 'USD' && String(createForm.price_input).trim()) {
      const fx = Number(createForm.fx_rate);
      if (!Number.isFinite(fx) || fx <= 0) {
        setCreateError('En moneda USD, el tipo de cambio es obligatorio si hay precio.');
        return;
      }
    }
    setSaving(true);
    setCreateError('');
    try {
      await createHarvest({
        year_from: yearFrom,
        year_to: yearTo,
        ...buildPricePayload(createForm),
      });
      setCreateOpen(false);
      setCreateForm(EMPTY_CREATE);
      setCreateError('');
      await refresh();
    } catch (e2) {
      setCreateError(e2?.message || 'No se pudo crear la cosecha.');
    } finally {
      setSaving(false);
    }
  }

  async function handleEditSave(e) {
    e.preventDefault();
    if (!canWrite || !editRow || !editForm) return;
    if (editForm.currency === 'USD' && String(editForm.price_input).trim()) {
      const fx = Number(editForm.fx_rate);
      if (!Number.isFinite(fx) || fx <= 0) {
        setError('En moneda USD, el tipo de cambio es obligatorio si hay precio.');
        return;
      }
    }
    setSaving(true);
    setError('');
    setChainWarnings([]);
    try {
      const result = await updateHarvest(editRow.id, {
        start_date: editForm.start_date,
        end_date: editForm.end_date,
        ...buildPricePayload(editForm),
      });
      setChainWarnings(result?.chain_warnings || []);
      if ((result?.chain_warnings || []).length === 0) {
        setEditRow(null);
        setEditForm(null);
      }
      await refresh();
    } catch (e2) {
      setError(e2?.message || 'No se pudo actualizar la cosecha.');
    } finally {
      setSaving(false);
    }
  }

  async function toggleActive(row) {
    if (!canWrite) return;
    setSaving(true);
    setError('');
    try {
      await setHarvestActive(row.id, !row.is_active);
      await refresh();
    } catch (e) {
      setError(e?.message || 'No se pudo cambiar el estado.');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:items-end">
        <label className="text-sm">
          <span className="text-slate-600">Estado</span>
          <select
            value={filters.active}
            onChange={(e) => setFilters((p) => ({ ...p, active: e.target.value }))}
            className="mt-1 block rounded border border-slate-300 bg-white px-2 py-1.5 text-sm"
          >
            <option value="active">Activas</option>
            <option value="false">Inactivas</option>
            <option value="all">Todas</option>
          </select>
        </label>
        <label className="text-sm">
          <span className="text-slate-600">Año</span>
          <input
            type="number"
            min="2000"
            max="2100"
            value={filters.year}
            onChange={(e) => setFilters((p) => ({ ...p, year: e.target.value }))}
            placeholder="Ej. 2025"
            className="mt-1 block w-28 rounded border border-slate-300 px-2 py-1.5 text-sm"
          />
        </label>
        <label className="text-sm">
          <span className="text-slate-600">Desde</span>
          <input
            type="date"
            value={filters.from_date}
            onChange={(e) => setFilters((p) => ({ ...p, from_date: e.target.value }))}
            className="mt-1 block rounded border border-slate-300 px-2 py-1.5 text-sm"
          />
        </label>
        <label className="text-sm">
          <span className="text-slate-600">Hasta</span>
          <input
            type="date"
            value={filters.to_date}
            onChange={(e) => setFilters((p) => ({ ...p, to_date: e.target.value }))}
            className="mt-1 block rounded border border-slate-300 px-2 py-1.5 text-sm"
          />
        </label>
      </div>

      {error ? (
        <p className="rounded border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800">{error}</p>
      ) : null}

      {canWrite ? (
        <button
          type="button"
          onClick={() => {
            setCreateError('');
            setCreateOpen(true);
          }}
          className="rounded bg-lime-700 px-4 py-2 text-sm font-semibold text-white"
        >
          Nueva cosecha
        </button>
      ) : (
        <p className="text-sm text-slate-500">Solo consulta: tu rol no puede crear ni editar períodos.</p>
      )}

      <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table className="min-w-full text-sm">
          <thead className="bg-slate-100 text-left">
            <tr>
              <th className="px-3 py-2">Nombre</th>
              <th className="px-3 py-2">Inicio</th>
              <th className="px-3 py-2">Fin</th>
              <th className="px-3 py-2">Precio / fanega</th>
              <th className="px-3 py-2">Estado</th>
              <th className="px-3 py-2 text-right">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={6} className="px-3 py-4 text-center text-slate-500">
                  Cargando…
                </td>
              </tr>
            ) : rows.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-3 py-4 text-center text-slate-500">
                  No hay cosechas con estos filtros.
                </td>
              </tr>
            ) : (
              rows.map((row) => (
                <tr key={row.id} className="border-t border-slate-100">
                  <td className="px-3 py-2 font-medium">{row.name}</td>
                  <td className="px-3 py-2">{row.start_date}</td>
                  <td className="px-3 py-2">{row.end_date}</td>
                  <td className="px-3 py-2">{formatPriceCell(row)}</td>
                  <td className="px-3 py-2">{row.is_active ? 'Activa' : 'Inactiva'}</td>
                  <td className="px-3 py-2">
                    <div className="flex justify-end gap-2">
                      <button
                        type="button"
                        onClick={() => openEdit(row)}
                        className="rounded border border-slate-300 px-2 py-1 text-xs"
                      >
                        Editar
                      </button>
                      {canWrite ? (
                        <button
                          type="button"
                          disabled={saving}
                          onClick={() => toggleActive(row)}
                          className={`rounded px-2 py-1 text-xs font-semibold ${
                            row.is_active
                              ? 'bg-rose-100 text-rose-700'
                              : 'bg-emerald-100 text-emerald-700'
                          }`}
                        >
                          {row.is_active ? 'Inactivar' : 'Activar'}
                        </button>
                      ) : null}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {createOpen ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <form
            onSubmit={handleCreate}
            className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl bg-white p-5 shadow-xl"
          >
            <h4 className="text-base font-semibold text-lime-800">Nueva cosecha</h4>
            <p className="mt-1 text-sm text-slate-600">
              El sistema generará el nombre y las fechas: inicio encadenado con la cosecha anterior (si hay) y fin el
              día anterior al inicio de la cosecha siguiente (si ya existe una posterior); si no hay siguiente, fin el
              31/12 del año final.
            </p>
            <div className="mt-4 grid gap-3">
              <label className="text-sm">
                Año inicial
                <input
                  required
                  type="number"
                  min="2000"
                  max="2098"
                  value={createForm.year_from}
                  onChange={(e) => setCreateForm((p) => ({ ...p, year_from: e.target.value }))}
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                />
              </label>
              <p className="text-sm text-slate-600">
                Año final: <strong>{createYearTo || '—'}</strong> (consecutivo al inicial)
              </p>
              <label className="text-sm">
                Moneda (precio opcional)
                <select
                  value={createForm.currency}
                  onChange={(e) => setCreateForm((p) => ({ ...p, currency: e.target.value }))}
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                >
                  <option value="CRC">CRC</option>
                  <option value="USD">USD</option>
                </select>
              </label>
              <label className="text-sm">
                Precio por fanega (opcional)
                <input
                  type="number"
                  min="0"
                  step="0.01"
                  value={createForm.price_input}
                  onChange={(e) => setCreateForm((p) => ({ ...p, price_input: e.target.value }))}
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                />
              </label>
              {createForm.currency === 'USD' ? (
                <FxRateUsdField
                  value={createForm.fx_rate}
                  onChange={(v) => setCreateForm((p) => ({ ...p, fx_rate: v }))}
                  required={!!String(createForm.price_input).trim()}
                />
              ) : null}
              {createPreview ? (
                <p className="text-sm text-slate-600">
                  Equivalente en colones: <strong>{createPreview}</strong>
                </p>
              ) : null}
            </div>
            {createError ? (
              <p
                role="alert"
                className="mt-4 rounded border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800"
              >
                {createError}
              </p>
            ) : null}
            <div className="mt-5 flex gap-2">
              <button
                type="submit"
                disabled={saving}
                className="rounded bg-lime-700 px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
              >
                {saving ? 'Guardando…' : 'Crear'}
              </button>
              <button
                type="button"
                onClick={() => {
                  setCreateOpen(false);
                  setCreateError('');
                }}
                className="rounded border border-slate-300 px-4 py-2 text-sm"
              >
                Cancelar
              </button>
            </div>
          </form>
        </div>
      ) : null}

      {editRow && editForm ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <form
            onSubmit={handleEditSave}
            className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl bg-white p-5 shadow-xl"
          >
            <h4 className="text-base font-semibold text-lime-800">Editar cosecha</h4>
            {chainWarnings.length ? (
              <div className="mt-2 space-y-1 rounded border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-900">
                <p>Al guardar fechas, el sistema puede ajustar cosechas vecinas:</p>
                {chainWarnings.map((w) => (
                  <p key={w} className="text-emerald-800">
                    {w}
                  </p>
                ))}
              </div>
            ) : null}
            <div className="mt-4 grid gap-3">
              <label className="text-sm">
                Nombre
                <input
                  readOnly
                  value={editRow.name}
                  className="mt-1 w-full rounded border border-slate-200 bg-slate-50 px-3 py-2 text-slate-600"
                />
              </label>
              <label className="text-sm">
                Fecha inicio
                <input
                  required
                  type="date"
                  disabled={!canWrite}
                  value={editForm.start_date}
                  onChange={(e) => setEditForm((p) => ({ ...p, start_date: e.target.value }))}
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2 disabled:bg-slate-50"
                />
              </label>
              <label className="text-sm">
                Fecha fin
                <input
                  required
                  type="date"
                  disabled={!canWrite}
                  value={editForm.end_date}
                  onChange={(e) => setEditForm((p) => ({ ...p, end_date: e.target.value }))}
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2 disabled:bg-slate-50"
                />
              </label>
              <label className="text-sm">
                Moneda
                <select
                  disabled={!canWrite}
                  value={editForm.currency}
                  onChange={(e) => setEditForm((p) => ({ ...p, currency: e.target.value }))}
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2 disabled:bg-slate-50"
                >
                  <option value="CRC">CRC</option>
                  <option value="USD">USD</option>
                </select>
              </label>
              <label className="text-sm">
                Precio por fanega
                <input
                  type="number"
                  min="0"
                  step="0.01"
                  disabled={!canWrite}
                  value={editForm.price_input}
                  onChange={(e) => setEditForm((p) => ({ ...p, price_input: e.target.value }))}
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2 disabled:bg-slate-50"
                />
              </label>
              {editForm.currency === 'USD' ? (
                <FxRateUsdField
                  value={editForm.fx_rate}
                  onChange={(v) => setEditForm((p) => ({ ...p, fx_rate: v }))}
                  required={!!String(editForm.price_input).trim()}
                />
              ) : null}
              {editPreview ? (
                <p className="text-sm text-slate-600">
                  Equivalente en colones: <strong>{editPreview}</strong>
                </p>
              ) : null}
            </div>
            <div className="mt-5 flex gap-2">
              {canWrite ? (
                <button
                  type="submit"
                  disabled={saving}
                  className="rounded bg-lime-700 px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
                >
                  {saving ? 'Guardando…' : 'Guardar'}
                </button>
              ) : null}
              <button
                type="button"
                onClick={() => {
                  setEditRow(null);
                  setEditForm(null);
                  setChainWarnings([]);
                }}
                className="rounded border border-slate-300 px-4 py-2 text-sm"
              >
                Cerrar
              </button>
            </div>
          </form>
        </div>
      ) : null}
    </div>
  );
}
