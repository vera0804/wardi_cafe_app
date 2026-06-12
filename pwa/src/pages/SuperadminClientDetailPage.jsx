import { useCallback, useEffect, useMemo, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext.jsx';
import SuperadminLayout from '../layouts/SuperadminLayout.jsx';
import SuperadminPlanSummary from '../components/SuperadminPlanSummary.jsx';
import {
  fetchSuperadminClient,
  fetchSuperadminPlans,
  renewSuperadminClientLicense,
  setSuperadminClientStatus,
  superadminEnterTenant,
  updateSuperadminClient,
} from '../services/superadminApi.js';

function todayIsoLocal() {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function StatusBadge({ status, label }) {
  const norm = String(status || '').toLowerCase();
  const cls =
    norm === 'active'
      ? 'bg-lime-100 text-lime-800'
      : norm === 'suspended'
        ? 'bg-amber-100 text-amber-900'
        : 'bg-red-100 text-red-800';
  return (
    <span className={`rounded px-2 py-0.5 text-xs font-medium ${cls}`}>{label || status || '—'}</span>
  );
}

export default function SuperadminClientDetailPage() {
  const { clientId } = useParams();
  const navigate = useNavigate();
  const { setUser } = useAuth();
  const [client, setClient] = useState(null);
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [name, setName] = useState('');
  const [savingName, setSavingName] = useState(false);
  const [statusBusy, setStatusBusy] = useState(false);
  const [renewing, setRenewing] = useState(false);
  const [renewForm, setRenewForm] = useState({
    plan_id: '',
    license_starts_on: todayIsoLocal(),
    billing_anchor_day: '',
    trial_days_override: '',
  });

  const selectedRenewPlan = useMemo(
    () => plans.find((p) => p.id === renewForm.plan_id) || client?.plan || null,
    [plans, renewForm.plan_id, client?.plan]
  );

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [detail, planRows] = await Promise.all([
        fetchSuperadminClient(clientId),
        fetchSuperadminPlans(),
      ]);
      setClient(detail);
      setPlans(planRows);
      setName(detail.name || '');
      setRenewForm((f) => ({
        ...f,
        plan_id: detail.plan_id || '',
        license_starts_on: todayIsoLocal(),
        billing_anchor_day:
          detail.plan_billing_model === 'monthly_anchor'
            ? String(detail.billing_anchor_day || Math.min(28, new Date().getDate()))
            : '',
        trial_days_override: '',
      }));
    } catch (e) {
      setError(e?.message || 'No se pudo cargar la organización.');
      setClient(null);
    } finally {
      setLoading(false);
    }
  }, [clientId]);

  useEffect(() => {
    load();
  }, [load]);

  useEffect(() => {
    if (selectedRenewPlan?.billing_model === 'monthly_anchor' && !renewForm.billing_anchor_day) {
      const day = Math.min(28, new Date(renewForm.license_starts_on || todayIsoLocal()).getDate() || 1);
      setRenewForm((f) => ({ ...f, billing_anchor_day: String(day) }));
    }
  }, [selectedRenewPlan?.billing_model, selectedRenewPlan?.id, renewForm.billing_anchor_day, renewForm.license_starts_on]);

  async function handleSaveName(e) {
    e.preventDefault();
    setSavingName(true);
    setError('');
    try {
      const updated = await updateSuperadminClient(clientId, { name: name.trim() });
      setClient(updated);
      setName(updated.name);
    } catch (e) {
      setError(e?.message || 'No se pudo guardar el nombre.');
    } finally {
      setSavingName(false);
    }
  }

  async function handleStatusChange(nextStatus) {
    const msg =
      nextStatus === 'suspended'
        ? '¿Suspender esta organización? Se cerrarán todas las sesiones de sus usuarios.'
        : '¿Reactivar esta organización? Si la licencia está vencida, los usuarios seguirán bloqueados hasta renovar.';
    if (!window.confirm(msg)) return;
    setStatusBusy(true);
    setError('');
    try {
      const updated = await setSuperadminClientStatus(clientId, nextStatus);
      setClient(updated);
    } catch (e) {
      setError(e?.message || 'No se pudo cambiar el estado.');
    } finally {
      setStatusBusy(false);
    }
  }

  async function handleRenew(e) {
    e.preventDefault();
    setRenewing(true);
    setError('');
    try {
      const payload = {
        plan_id: renewForm.plan_id || client.plan_id,
        license_starts_on: renewForm.license_starts_on || todayIsoLocal(),
      };
      if (selectedRenewPlan?.billing_model === 'monthly_anchor' && renewForm.billing_anchor_day) {
        payload.billing_anchor_day = Number(renewForm.billing_anchor_day);
      }
      if (selectedRenewPlan?.billing_model === 'trial_days' && renewForm.trial_days_override) {
        payload.trial_days_override = Number(renewForm.trial_days_override);
      }
      const updated = await renewSuperadminClientLicense(clientId, payload);
      setClient(updated);
      setRenewForm((f) => ({
        ...f,
        plan_id: updated.plan_id || '',
        license_starts_on: todayIsoLocal(),
        trial_days_override: '',
      }));
    } catch (e) {
      setError(e?.message || 'No se pudo renovar la licencia.');
    } finally {
      setRenewing(false);
    }
  }

  async function handleEnter() {
    setError('');
    try {
      const profile = await superadminEnterTenant(clientId);
      setUser(profile);
      navigate('/dashboard', { replace: true });
    } catch (e) {
      setError(e?.message || 'No se pudo entrar a la organización.');
    }
  }

  const allPlansForRenew = useMemo(() => {
    const byId = new Map(plans.map((p) => [p.id, p]));
    if (client?.plan?.id && !byId.has(client.plan.id)) {
      byId.set(client.plan.id, { ...client.plan, billing_model_label: client.plan.billing_model_label });
    }
    return [...byId.values()];
  }, [plans, client?.plan]);

  return (
    <SuperadminLayout>
      <div className="mb-4">
        <Link to="/superadmin/clients" className="text-sm text-slate-500 hover:text-lime-800">
          ← Organizaciones
        </Link>
      </div>

      {error ? (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-2 text-sm text-red-800">{error}</div>
      ) : null}

      {loading ? (
        <p className="text-sm text-slate-500">Cargando…</p>
      ) : !client ? (
        <p className="text-sm text-slate-500">Organización no encontrada.</p>
      ) : (
        <div className="space-y-6">
          <header className="flex flex-wrap items-start justify-between gap-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <div>
              <h2 className="text-xl font-semibold text-slate-900">{client.name}</h2>
              <div className="mt-2 flex flex-wrap items-center gap-2 text-sm text-slate-600">
                <StatusBadge status={client.status} label={client.status_label} />
                <span>Plan: {client.plan_name || '—'}</span>
                {client.license_expires_on_display ? (
                  <span>Vence: {client.license_expires_on_display}</span>
                ) : (
                  <span>Sin vencimiento</span>
                )}
              </div>
              {client.admin_email ? (
                <p className="mt-1 text-xs text-slate-500">Admin: {client.admin_email}</p>
              ) : null}
              <p className="mt-1 text-xs text-slate-500">
                {client.active_users_count} usuario(s) activo(s) · {client.active_lots_count} finca(s) activa(s)
              </p>
            </div>
            <div className="flex flex-wrap gap-2">
              {client.status === 'active' ? (
                <button
                  type="button"
                  disabled={statusBusy}
                  className="rounded-lg border border-amber-300 px-3 py-1.5 text-sm text-amber-900 hover:bg-amber-50 disabled:opacity-60"
                  onClick={() => handleStatusChange('suspended')}
                >
                  {statusBusy ? 'Procesando…' : 'Suspender'}
                </button>
              ) : client.status === 'suspended' ? (
                <button
                  type="button"
                  disabled={statusBusy}
                  className="rounded-lg border border-lime-700 px-3 py-1.5 text-sm font-medium text-lime-800 hover:bg-lime-50 disabled:opacity-60"
                  onClick={() => handleStatusChange('active')}
                >
                  {statusBusy ? 'Procesando…' : 'Reactivar'}
                </button>
              ) : null}
              <button
                type="button"
                className="rounded-lg border border-lime-700 px-3 py-1.5 text-sm font-medium text-lime-800 hover:bg-lime-50"
                onClick={handleEnter}
              >
                Entrar
              </button>
            </div>
          </header>

          {client.status === 'license_expired' ? (
            <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-900">
              La licencia de esta organización está vencida. Renueve abajo para restaurar el acceso de los usuarios.
            </div>
          ) : null}

          <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <h3 className="text-sm font-semibold uppercase tracking-wide text-slate-500">Datos generales</h3>
            <form className="mt-4 flex flex-wrap items-end gap-3" onSubmit={handleSaveName}>
              <label className="block min-w-[16rem] flex-1 text-sm">
                <span className="text-slate-600">Nombre de la organización</span>
                <input
                  required
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                  value={name}
                  onChange={(ev) => setName(ev.target.value)}
                />
              </label>
              <button
                type="submit"
                disabled={savingName || name.trim() === client.name}
                className="rounded-lg bg-lime-700 px-4 py-2 text-sm font-medium text-white hover:bg-lime-800 disabled:opacity-60"
              >
                {savingName ? 'Guardando…' : 'Guardar nombre'}
              </button>
            </form>
          </section>

          <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <h3 className="text-sm font-semibold uppercase tracking-wide text-slate-500">Plan y licencia</h3>
            <p className="mt-2 text-sm text-slate-600">
              Renovar recalcula fechas, puede cambiar el plan y deja la organización en estado activo.
            </p>
            {client.plan ? (
              <div className="mt-3">
                <SuperadminPlanSummary plan={client.plan} />
              </div>
            ) : null}
            <form className="mt-4 grid gap-3 sm:grid-cols-2" onSubmit={handleRenew}>
              <label className="block text-sm sm:col-span-2">
                <span className="text-slate-600">Plan</span>
                <select
                  required
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                  value={renewForm.plan_id}
                  onChange={(ev) => setRenewForm((f) => ({ ...f, plan_id: ev.target.value }))}
                >
                  {allPlansForRenew.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name}
                      {p.is_active === false ? ' (inactivo)' : ''} ({p.billing_model_label || p.billing_model})
                    </option>
                  ))}
                </select>
                {selectedRenewPlan && selectedRenewPlan.id !== client.plan_id ? (
                  <SuperadminPlanSummary plan={selectedRenewPlan} />
                ) : null}
              </label>
              <label className="block text-sm">
                <span className="text-slate-600">Inicio de licencia</span>
                <input
                  type="date"
                  required
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                  value={renewForm.license_starts_on}
                  onChange={(ev) => setRenewForm((f) => ({ ...f, license_starts_on: ev.target.value }))}
                />
              </label>
              {selectedRenewPlan?.billing_model === 'monthly_anchor' ? (
                <label className="block text-sm">
                  <span className="text-slate-600">Día de pago mensual (1-28)</span>
                  <input
                    type="number"
                    min={1}
                    max={28}
                    required
                    className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                    value={renewForm.billing_anchor_day}
                    onChange={(ev) => setRenewForm((f) => ({ ...f, billing_anchor_day: ev.target.value }))}
                  />
                </label>
              ) : null}
              {selectedRenewPlan?.billing_model === 'trial_days' ? (
                <label className="block text-sm">
                  <span className="text-slate-600">
                    Días de demo (opcional; plan: {selectedRenewPlan.trial_days ?? 30})
                  </span>
                  <input
                    type="number"
                    min={1}
                    max={365}
                    placeholder={String(selectedRenewPlan.trial_days ?? 30)}
                    className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                    value={renewForm.trial_days_override}
                    onChange={(ev) => setRenewForm((f) => ({ ...f, trial_days_override: ev.target.value }))}
                  />
                </label>
              ) : null}
              <div className="sm:col-span-2">
                <button
                  type="submit"
                  disabled={renewing}
                  className="rounded-lg bg-lime-700 px-4 py-2 text-sm font-medium text-white hover:bg-lime-800 disabled:opacity-60"
                >
                  {renewing ? 'Renovando…' : 'Renovar licencia'}
                </button>
              </div>
            </form>
            <dl className="mt-4 grid gap-2 text-sm text-slate-600 sm:grid-cols-2">
              <div>
                <dt className="text-xs uppercase text-slate-400">Inicio vigente</dt>
                <dd>{client.license_starts_on || '—'}</dd>
              </div>
              <div>
                <dt className="text-xs uppercase text-slate-400">Vencimiento</dt>
                <dd>{client.license_expires_on_display || client.license_expires_on || 'Sin vencimiento'}</dd>
              </div>
            </dl>
          </section>
        </div>
      )}
    </SuperadminLayout>
  );
}
