import { useEffect, useMemo, useState } from 'react';
import { isTenantAdmin } from '../../layouts/dashboardMenuData.js';
import {
  getHarvestEstimatesMeta,
  listHarvestEstimates,
  upsertHarvestEstimateLot,
} from '../../services/harvestEstimates.js';

function fmtNum(n, digits = 2) {
  if (n == null || !Number.isFinite(Number(n))) return '—';
  return Number(n).toLocaleString('es-CR', {
    minimumFractionDigits: 0,
    maximumFractionDigits: digits,
  });
}

function draftFanegas(draft, savedFanegas) {
  if (draft === '' || draft == null) {
    return savedFanegas != null ? fmtNum(savedFanegas, 4) : '—';
  }
  const c = Number(draft);
  if (!Number.isFinite(c) || c < 0) return '—';
  return fmtNum(c / 20, 4);
}

export default function HarvestEstimatesSettingsSection({ user }) {
  const canWrite = isTenantAdmin(user);
  const [meta, setMeta] = useState({ harvests: [], lots: [] });
  const [harvestId, setHarvestId] = useState('');
  const [rows, setRows] = useState([]);
  const [farmTotals, setFarmTotals] = useState([]);
  const [drafts, setDrafts] = useState({});
  const [loading, setLoading] = useState(false);
  const [savingLotId, setSavingLotId] = useState(null);
  const [error, setError] = useState('');

  const selectedHarvest = useMemo(
    () => meta.harvests?.find((h) => h.id === harvestId) || null,
    [meta.harvests, harvestId]
  );

  const rowsByFarm = useMemo(() => {
    const map = new Map();
    for (const r of rows) {
      const key = r.farm_id;
      if (!map.has(key)) {
        map.set(key, { farm_id: r.farm_id, farm_name: r.farm_name, lots: [] });
      }
      map.get(key).lots.push(r);
    }
    return [...map.values()];
  }, [rows]);

  async function loadMeta() {
    setLoading(true);
    setError('');
    try {
      const data = await getHarvestEstimatesMeta();
      const harvests = data?.harvests || [];
      setMeta({ harvests, lots: data?.lots || [] });
      if (harvests.length && !harvestId) {
        setHarvestId(harvests[0].id);
      } else if (!harvests.length) {
        setHarvestId('');
        setRows([]);
        setFarmTotals([]);
      }
    } catch (e) {
      setError(e?.message || 'No se pudo cargar el contexto de estimaciones.');
    } finally {
      setLoading(false);
    }
  }

  async function loadGrid(id) {
    if (!id) {
      setRows([]);
      setFarmTotals([]);
      return;
    }
    setLoading(true);
    setError('');
    try {
      const data = await listHarvestEstimates(id);
      setRows(data?.rows || []);
      setFarmTotals(data?.farm_totals || []);
      setDrafts({});
    } catch (e) {
      setError(e?.message || 'No se pudieron cargar estimaciones.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadMeta();
  }, [user?.clientId]);

  useEffect(() => {
    if (harvestId) loadGrid(harvestId);
  }, [harvestId]);

  function setDraft(lotId, value) {
    setDrafts((p) => ({ ...p, [lotId]: value }));
  }

  async function saveRow(row) {
    if (!canWrite || !harvestId) return;
    const hasDraft = Object.prototype.hasOwnProperty.call(drafts, row.lot_id);
    const raw = hasDraft
      ? drafts[row.lot_id]
      : row.estimated_cajuelas != null
        ? String(row.estimated_cajuelas)
        : '';
    if (raw === '' || raw == null) {
      setError('Indique cajuelas estimadas antes de guardar (use 0 si la meta es cero).');
      return;
    }
    const estimated_cajuelas = Number(raw);
    if (!Number.isFinite(estimated_cajuelas) || estimated_cajuelas < 0) {
      setError('Las cajuelas estimadas deben ser un número ≥ 0.');
      return;
    }
    setSavingLotId(row.lot_id);
    setError('');
    try {
      await upsertHarvestEstimateLot({
        harvest_id: harvestId,
        lot_id: row.lot_id,
        estimated_cajuelas,
      });
      setDrafts((p) => {
        const next = { ...p };
        delete next[row.lot_id];
        return next;
      });
      await loadGrid(harvestId);
    } catch (e) {
      setError(e?.message || 'No se pudo guardar la estimación.');
    } finally {
      setSavingLotId(null);
    }
  }

  if (!meta.harvests?.length) {
    return (
      <p className="rounded border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-900">
        No hay cosechas activas. Cree o reactive períodos en la pestaña Periodos de cosecha.
      </p>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-2 sm:flex-row sm:items-end">
        <label className="text-sm">
          <span className="font-medium text-slate-800">Cosecha</span>
          <select
            value={harvestId}
            onChange={(e) => setHarvestId(e.target.value)}
            className="mt-1 block min-w-[16rem] rounded border border-slate-300 bg-white px-2 py-1.5 text-sm"
          >
            {meta.harvests.map((h) => (
              <option key={h.id} value={h.id}>
                {h.name}
              </option>
            ))}
          </select>
        </label>
        {selectedHarvest ? (
          <p className="text-sm text-slate-600">
            Periodo: {String(selectedHarvest.start_date).slice(0, 10)} →{' '}
            {String(selectedHarvest.end_date).slice(0, 10)}
          </p>
        ) : null}
      </div>

      {!canWrite ? (
        <p className="text-sm text-slate-500">Solo consulta: tu rol no puede guardar estimaciones.</p>
      ) : null}

      {error ? (
        <p className="rounded border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800">{error}</p>
      ) : null}

      {farmTotals.length > 0 ? (
        <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
          <h4 className="border-b border-slate-100 bg-slate-50 px-3 py-2 text-sm font-semibold text-slate-800">
            Resumen por finca (solo lotes con estimación guardada)
          </h4>
          <table className="min-w-full text-sm">
            <thead className="bg-slate-100 text-left">
              <tr>
                <th className="px-3 py-2">Finca</th>
                <th className="px-3 py-2">Cajuelas est.</th>
                <th className="px-3 py-2">Fanegas est.</th>
                <th className="px-3 py-2">Lotes con meta</th>
              </tr>
            </thead>
            <tbody>
              {farmTotals.map((f) => (
                <tr key={f.farm_id} className="border-t border-slate-100">
                  <td className="px-3 py-2">{f.farm_name}</td>
                  <td className="px-3 py-2">{fmtNum(f.total_cajuelas)}</td>
                  <td className="px-3 py-2">{fmtNum(f.total_fanegas, 4)}</td>
                  <td className="px-3 py-2">{f.lots_with_estimate}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}

      {loading && !rows.length ? (
        <p className="text-sm text-slate-500">Cargando lotes…</p>
      ) : null}

      {rowsByFarm.map((farm) => (
        <div key={farm.farm_id} className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
          <h4 className="border-b border-slate-100 bg-slate-50 px-3 py-2 text-sm font-semibold text-lime-800">
            {farm.farm_name}
          </h4>
          <table className="min-w-full text-sm">
            <thead className="bg-slate-100 text-left">
              <tr>
                <th className="px-3 py-2">Lote</th>
                <th className="px-3 py-2">Cajuelas est.</th>
                <th className="px-3 py-2">Fanegas est.</th>
                {canWrite ? <th className="px-3 py-2 text-right">Acción</th> : null}
              </tr>
            </thead>
            <tbody>
              {farm.lots.map((row) => {
                const hasDraft = Object.prototype.hasOwnProperty.call(drafts, row.lot_id);
                const inputVal = hasDraft
                  ? drafts[row.lot_id]
                  : row.estimated_cajuelas != null
                    ? String(row.estimated_cajuelas)
                    : '';
                return (
                  <tr key={row.lot_id} className="border-t border-slate-100">
                    <td className="px-3 py-2">{row.lot_name}</td>
                    <td className="px-3 py-2">
                      <input
                        type="number"
                        min="0"
                        step="1"
                        disabled={!canWrite}
                        value={inputVal}
                        placeholder="—"
                        onChange={(e) => setDraft(row.lot_id, e.target.value)}
                        className="w-28 rounded border border-slate-300 px-2 py-1 disabled:bg-slate-50"
                      />
                    </td>
                    <td className="px-3 py-2 text-slate-600">
                      {draftFanegas(inputVal, row.estimated_fanegas)}
                    </td>
                    {canWrite ? (
                      <td className="px-3 py-2 text-right">
                        <button
                          type="button"
                          disabled={savingLotId === row.lot_id}
                          onClick={() => saveRow(row)}
                          className="rounded bg-lime-700 px-3 py-1 text-xs font-semibold text-white disabled:opacity-60"
                        >
                          {savingLotId === row.lot_id ? 'Guardando…' : 'Guardar'}
                        </button>
                      </td>
                    ) : null}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      ))}
    </div>
  );
}
