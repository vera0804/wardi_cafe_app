import { useCallback, useEffect, useState } from 'react';
import SuperadminLayout from '../layouts/SuperadminLayout.jsx';
import {
  createSuperadminPlan,
  deactivateSuperadminPlan,
  fetchSuperadminPlanImpact,
  fetchSuperadminPlansAll,
  updateSuperadminPlan,
} from '../services/superadminApi.js';

const EMPTY_FORM = {
  name: '',
  billing_model: 'trial_days',
  trial_days: '30',
  description: '',
  max_farms: '1',
  max_lots_per_farm: '50',
  max_users_admin: '1',
  max_users_operario: '3',
  price: '0',
};

function PlanImpactPanel({ impact }) {
  if (!impact) return null;
  return (
    <div className="rounded-lg border border-amber-200 bg-amber-50 p-3 text-sm text-amber-950">
      <p>{impact.message}</p>
      {impact.active_clients?.length ? (
        <ul className="mt-2 max-h-40 list-inside list-disc overflow-y-auto text-xs">
          {impact.active_clients.map((c) => (
            <li key={c.id}>{c.name}</li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}

export default function SuperadminPlansPage() {
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [formOpen, setFormOpen] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [impact, setImpact] = useState(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [pendingAction, setPendingAction] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      setPlans(await fetchSuperadminPlansAll());
    } catch (e) {
      setError(e?.message || 'No se pudo cargar los planes.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  function openCreate() {
    setEditingId(null);
    setForm(EMPTY_FORM);
    setImpact(null);
    setConfirmOpen(false);
    setPendingAction(null);
    setFormOpen(true);
  }

  async function openEdit(plan) {
    setEditingId(plan.id);
    setForm({
      name: plan.name,
      billing_model: plan.billing_model,
      trial_days: plan.trial_days != null ? String(plan.trial_days) : '30',
      description: plan.description || '',
      max_farms: String(plan.max_farms),
      max_lots_per_farm: String(plan.max_lots_per_farm),
      max_users_admin: String(plan.max_users_admin),
      max_users_operario: String(plan.max_users_operario),
      price: String(plan.price ?? 0),
    });
    setConfirmOpen(false);
    setPendingAction(null);
    setFormOpen(true);
    try {
      setImpact(await fetchSuperadminPlanImpact(plan.id));
    } catch (e) {
      setError(e?.message || 'No se pudo cargar el impacto.');
      setImpact(null);
    }
  }

  function buildPayload(acknowledge = false) {
    const payload = {
      name: form.name.trim(),
      billing_model: form.billing_model,
      description: form.description.trim() || null,
      max_farms: Number(form.max_farms),
      max_lots_per_farm: Number(form.max_lots_per_farm),
      max_users_admin: Number(form.max_users_admin),
      max_users_operario: Number(form.max_users_operario),
      price: Number(form.price),
    };
    if (form.billing_model === 'trial_days') {
      payload.trial_days = Number(form.trial_days);
    }
    if (acknowledge) payload.acknowledge_affected_clients = true;
    return payload;
  }

  async function handleSaveFirstStep(e) {
    e.preventDefault();
    if (!editingId) {
      setSaving(true);
      setError('');
      try {
        await createSuperadminPlan(buildPayload());
        setFormOpen(false);
        await load();
      } catch (err) {
        setError(err?.message || 'No se pudo crear el plan.');
      } finally {
        setSaving(false);
      }
      return;
    }
    const n = impact?.active_client_count ?? 0;
    if (n > 0) {
      setPendingAction('save');
      setConfirmOpen(true);
      return;
    }
    await commitSave(false);
  }

  async function commitSave(acknowledge) {
    setSaving(true);
    setError('');
    try {
      await updateSuperadminPlan(editingId, buildPayload(acknowledge));
      setFormOpen(false);
      setConfirmOpen(false);
      setPendingAction(null);
      await load();
    } catch (err) {
      if (err?.code === 'PLAN_IMPACT_NOT_ACKNOWLEDGED' && err.impact) {
        setImpact(err.impact);
        setPendingAction('save');
        setConfirmOpen(true);
      } else {
        setError(err?.message || 'No se pudo guardar.');
      }
    } finally {
      setSaving(false);
    }
  }

  async function startDeactivate(plan) {
    setError('');
    try {
      const imp = await fetchSuperadminPlanImpact(plan.id);
      setImpact(imp);
      setEditingId(plan.id);
      if (imp.active_client_count > 0) {
        setPendingAction('deactivate');
        setConfirmOpen(true);
      } else {
        setSaving(true);
        await deactivateSuperadminPlan(plan.id, {});
        await load();
        setSaving(false);
      }
    } catch (e) {
      setError(e?.message || 'No se pudo inactivar.');
    }
  }

  async function commitDeactivate() {
    setSaving(true);
    setError('');
    try {
      await deactivateSuperadminPlan(editingId, { acknowledge_affected_clients: true });
      setConfirmOpen(false);
      setPendingAction(null);
      setEditingId(null);
      await load();
    } catch (err) {
      if (err?.code === 'PLAN_IMPACT_NOT_ACKNOWLEDGED' && err.impact) {
        setImpact(err.impact);
      } else {
        setError(err?.message || 'No se pudo inactivar.');
      }
    } finally {
      setSaving(false);
    }
  }

  return (
    <SuperadminLayout>
      {error ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-2 text-sm text-red-800">{error}</div>
      ) : null}

      <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-500">Catálogo de planes</h2>
          <button
            type="button"
            onClick={openCreate}
            className="rounded-lg bg-lime-700 px-4 py-2 text-sm font-medium text-white hover:bg-lime-800"
          >
            Nuevo plan
          </button>
        </div>

        {loading ? (
          <p className="mt-4 text-sm text-slate-500">Cargando…</p>
        ) : (
          <div className="mt-4 overflow-x-auto">
            <table className="w-full min-w-[640px] text-left text-sm">
              <thead>
                <tr className="border-b border-slate-200 text-xs uppercase text-slate-500">
                  <th className="py-2 pr-3">Plan</th>
                  <th className="py-2 pr-3">Facturación</th>
                  <th className="py-2 pr-3">Límites</th>
                  <th className="py-2 pr-3">Org. activas</th>
                  <th className="py-2 pr-3">Estado</th>
                  <th className="py-2">Acciones</th>
                </tr>
              </thead>
              <tbody>
                {plans.map((p) => (
                  <tr key={p.id} className="border-b border-slate-100">
                    <td className="py-3 pr-3 font-medium">{p.name}</td>
                    <td className="py-3 pr-3 text-slate-600">{p.billing_model_label}</td>
                    <td className="py-3 pr-3 text-xs text-slate-600">
                      {p.max_farms} fincas · {p.max_lots_per_farm} lotes · {p.max_users_admin}/
                      {p.max_users_operario} usuarios
                    </td>
                    <td className="py-3 pr-3">{p.active_client_count ?? 0}</td>
                    <td className="py-3 pr-3">
                      {p.is_active ? (
                        <span className="rounded bg-lime-100 px-2 py-0.5 text-xs text-lime-800">Activo</span>
                      ) : (
                        <span className="rounded bg-slate-200 px-2 py-0.5 text-xs text-slate-600">Inactivo</span>
                      )}
                    </td>
                    <td className="py-3">
                      <div className="flex flex-wrap gap-2">
                        <button
                          type="button"
                          className="text-lime-800 hover:underline"
                          onClick={() => openEdit(p)}
                        >
                          Editar
                        </button>
                        {p.is_active ? (
                          <button
                            type="button"
                            className="text-slate-600 hover:underline"
                            onClick={() => startDeactivate(p)}
                          >
                            Inactivar
                          </button>
                        ) : null}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {formOpen ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 p-4">
          <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl bg-white p-5 shadow-xl">
            <h3 className="text-lg font-semibold text-slate-800">
              {editingId ? 'Editar plan' : 'Nuevo plan'}
            </h3>
            {editingId && impact ? <div className="mt-3"><PlanImpactPanel impact={impact} /></div> : null}
            <form className="mt-4 grid gap-3" onSubmit={handleSaveFirstStep}>
              <label className="block text-sm">
                <span className="text-slate-600">Nombre</span>
                <input
                  required
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                  value={form.name}
                  onChange={(ev) => setForm((f) => ({ ...f, name: ev.target.value }))}
                />
              </label>
              <label className="block text-sm">
                <span className="text-slate-600">Modelo de facturación</span>
                <select
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                  value={form.billing_model}
                  onChange={(ev) => setForm((f) => ({ ...f, billing_model: ev.target.value }))}
                >
                  <option value="perpetual">Sin vencimiento (perpetual)</option>
                  <option value="trial_days">Demo / días fijos</option>
                  <option value="monthly_anchor">Mensual (día de pago)</option>
                </select>
              </label>
              {form.billing_model === 'trial_days' ? (
                <label className="block text-sm">
                  <span className="text-slate-600">Días de demo</span>
                  <input
                    type="number"
                    min={1}
                    required
                    className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                    value={form.trial_days}
                    onChange={(ev) => setForm((f) => ({ ...f, trial_days: ev.target.value }))}
                  />
                </label>
              ) : null}
              <label className="block text-sm sm:col-span-2">
                <span className="text-slate-600">Descripción</span>
                <textarea
                  rows={2}
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                  value={form.description}
                  onChange={(ev) => setForm((f) => ({ ...f, description: ev.target.value }))}
                />
              </label>
              <div className="grid grid-cols-2 gap-3">
                <label className="block text-sm">
                  <span className="text-slate-600">Máx. fincas</span>
                  <input
                    type="number"
                    min={1}
                    required
                    className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                    value={form.max_farms}
                    onChange={(ev) => setForm((f) => ({ ...f, max_farms: ev.target.value }))}
                  />
                </label>
                <label className="block text-sm">
                  <span className="text-slate-600">Lotes / finca</span>
                  <input
                    type="number"
                    min={1}
                    required
                    className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                    value={form.max_lots_per_farm}
                    onChange={(ev) => setForm((f) => ({ ...f, max_lots_per_farm: ev.target.value }))}
                  />
                </label>
                <label className="block text-sm">
                  <span className="text-slate-600">Admins</span>
                  <input
                    type="number"
                    min={1}
                    required
                    className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                    value={form.max_users_admin}
                    onChange={(ev) => setForm((f) => ({ ...f, max_users_admin: ev.target.value }))}
                  />
                </label>
                <label className="block text-sm">
                  <span className="text-slate-600">Operarios</span>
                  <input
                    type="number"
                    min={0}
                    required
                    className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                    value={form.max_users_operario}
                    onChange={(ev) => setForm((f) => ({ ...f, max_users_operario: ev.target.value }))}
                  />
                </label>
              </div>
              <label className="block text-sm">
                <span className="text-slate-600">Precio referencia (₡)</span>
                <input
                  type="number"
                  min={0}
                  step="0.01"
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                  value={form.price}
                  onChange={(ev) => setForm((f) => ({ ...f, price: ev.target.value }))}
                />
              </label>
              <div className="flex flex-wrap justify-end gap-2 pt-2">
                <button
                  type="button"
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm"
                  onClick={() => setFormOpen(false)}
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="rounded-lg bg-lime-700 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
                >
                  {saving
                    ? 'Guardando…'
                    : editingId && (impact?.active_client_count ?? 0) > 0
                      ? 'Revisar y guardar'
                      : 'Guardar'}
                </button>
              </div>
            </form>
          </div>
        </div>
      ) : null}

      {confirmOpen ? (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-slate-900/50 p-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-5 shadow-xl">
            <h3 className="text-lg font-semibold text-slate-800">Confirmar impacto</h3>
            <div className="mt-3">
              <PlanImpactPanel impact={impact} />
            </div>
            <div className="mt-4 flex flex-wrap justify-end gap-2">
              <button
                type="button"
                className="rounded-lg border border-slate-300 px-4 py-2 text-sm"
                onClick={() => {
                  setConfirmOpen(false);
                  setPendingAction(null);
                }}
              >
                Cancelar
              </button>
              <button
                type="button"
                disabled={saving}
                className="rounded-lg bg-amber-700 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
                onClick={() =>
                  pendingAction === 'deactivate' ? commitDeactivate() : commitSave(true)
                }
              >
                {saving
                  ? 'Procesando…'
                  : pendingAction === 'deactivate'
                    ? 'Sí, inactivar plan'
                    : 'Sí, guardar cambios'}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </SuperadminLayout>
  );
}
