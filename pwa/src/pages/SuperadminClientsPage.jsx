import { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext.jsx';
import {
  createSuperadminClient,
  fetchSuperadminClients,
  fetchSuperadminPlans,
  renewSuperadminClientLicense,
  superadminEnterTenant,
} from '../services/superadminApi.js';
import PasswordPolicyHint from '../components/PasswordPolicyHint.jsx';
import SuperadminPlanSummary from '../components/SuperadminPlanSummary.jsx';
import SuperadminLayout from '../layouts/SuperadminLayout.jsx';
import { validatePasswordPolicy } from '../utils/passwordPolicy.js';

function todayIsoLocal() {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export default function SuperadminClientsPage() {
  const { setUser } = useAuth();
  const navigate = useNavigate();
  const [plans, setPlans] = useState([]);
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [creating, setCreating] = useState(false);
  const [renewingId, setRenewingId] = useState(null);
  const [form, setForm] = useState({
    client_name: '',
    plan_id: '',
    license_starts_on: todayIsoLocal(),
    billing_anchor_day: '',
    trial_days_override: '',
    admin_email: '',
    admin_password: '',
    admin_first_name: '',
    admin_last_name_1: '',
    admin_last_name_2: '',
  });

  const selectedPlan = useMemo(
    () => plans.find((p) => p.id === form.plan_id) || null,
    [plans, form.plan_id]
  );

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [p, c] = await Promise.all([fetchSuperadminPlans(), fetchSuperadminClients()]);
      setPlans(p);
      setClients(c);
      setForm((f) => {
        const next = { ...f };
        if (!f.plan_id && p[0]?.id) next.plan_id = p[0].id;
        if (!f.license_starts_on) next.license_starts_on = todayIsoLocal();
        if (p[0]?.billing_model === 'monthly_anchor' && !f.billing_anchor_day) {
          const day = new Date().getDate();
          next.billing_anchor_day = String(Math.min(28, day));
        }
        return next;
      });
    } catch (e) {
      setError(e?.message || 'No se pudo cargar.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  useEffect(() => {
    if (selectedPlan?.billing_model === 'monthly_anchor' && !form.billing_anchor_day) {
      const day = Math.min(28, new Date(form.license_starts_on || todayIsoLocal()).getDate() || 1);
      setForm((f) => ({ ...f, billing_anchor_day: String(day) }));
    }
  }, [selectedPlan?.billing_model, selectedPlan?.id, form.billing_anchor_day, form.license_starts_on]);

  async function handleEnter(clientId) {
    setError('');
    try {
      const profile = await superadminEnterTenant(clientId);
      setUser(profile);
      navigate('/dashboard', { replace: true });
    } catch (e) {
      setError(e?.message || 'No se pudo entrar a la organización.');
    }
  }

  async function handleRenew(client) {
    setError('');
    setRenewingId(client.id);
    try {
      await renewSuperadminClientLicense(client.id, {
        license_starts_on: todayIsoLocal(),
        billing_anchor_day:
          client.plan_billing_model === 'monthly_anchor'
            ? client.billing_anchor_day || Math.min(28, new Date().getDate())
            : undefined,
      });
      await load();
    } catch (e) {
      setError(e?.message || 'No se pudo renovar la licencia.');
    } finally {
      setRenewingId(null);
    }
  }

  async function handleCreate(e) {
    e.preventDefault();
    const policyErr = validatePasswordPolicy(form.admin_password);
    if (policyErr) {
      setError(policyErr);
      return;
    }
    setCreating(true);
    setError('');
    try {
      const payload = {
        client_name: form.client_name.trim(),
        plan_id: form.plan_id,
        license_starts_on: form.license_starts_on || todayIsoLocal(),
        admin_email: form.admin_email.trim(),
        admin_password: form.admin_password,
        admin_first_name: form.admin_first_name.trim(),
        admin_last_name_1: form.admin_last_name_1.trim(),
        admin_last_name_2: form.admin_last_name_2.trim() || undefined,
      };
      if (selectedPlan?.billing_model === 'monthly_anchor' && form.billing_anchor_day) {
        payload.billing_anchor_day = Number(form.billing_anchor_day);
      }
      if (selectedPlan?.billing_model === 'trial_days' && form.trial_days_override) {
        payload.trial_days_override = Number(form.trial_days_override);
      }
      await createSuperadminClient(payload);
      setForm((f) => ({
        ...f,
        client_name: '',
        admin_email: '',
        admin_password: '',
        admin_first_name: '',
        admin_last_name_1: '',
        admin_last_name_2: '',
        license_starts_on: todayIsoLocal(),
        trial_days_override: '',
      }));
      await load();
    } catch (e) {
      setError(e?.message || 'No se pudo crear la organización.');
    } finally {
      setCreating(false);
    }
  }

  return (
    <SuperadminLayout>
      {error ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-2 text-sm text-red-800">{error}</div>
      ) : null}

      <div className="space-y-8">
        <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-500">Nueva organización</h2>
          <form className="mt-4 grid gap-3 sm:grid-cols-2" onSubmit={handleCreate}>
            <label className="sm:col-span-2 block text-sm">
              <span className="text-slate-600">Nombre del cliente</span>
              <input
                required
                className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                value={form.client_name}
                onChange={(ev) => setForm((f) => ({ ...f, client_name: ev.target.value }))}
              />
            </label>
            <label className="block text-sm sm:col-span-2">
              <span className="text-slate-600">Plan</span>
              <select
                required
                className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                value={form.plan_id}
                onChange={(ev) => setForm((f) => ({ ...f, plan_id: ev.target.value }))}
              >
                {plans.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name} ({p.billing_model_label})
                  </option>
                ))}
              </select>
              <SuperadminPlanSummary plan={selectedPlan} />
            </label>
            <label className="block text-sm">
              <span className="text-slate-600">Inicio de licencia</span>
              <input
                type="date"
                required
                className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                value={form.license_starts_on}
                onChange={(ev) => setForm((f) => ({ ...f, license_starts_on: ev.target.value }))}
              />
            </label>
            {selectedPlan?.billing_model === 'monthly_anchor' ? (
              <label className="block text-sm">
                <span className="text-slate-600">Día de pago mensual (1-28)</span>
                <input
                  type="number"
                  min={1}
                  max={28}
                  required
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                  value={form.billing_anchor_day}
                  onChange={(ev) => setForm((f) => ({ ...f, billing_anchor_day: ev.target.value }))}
                />
              </label>
            ) : null}
            {selectedPlan?.billing_model === 'trial_days' ? (
              <label className="block text-sm">
                <span className="text-slate-600">
                  Días de demo (opcional; plan: {selectedPlan.trial_days ?? 30})
                </span>
                <input
                  type="number"
                  min={1}
                  max={365}
                  placeholder={String(selectedPlan.trial_days ?? 30)}
                  className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                  value={form.trial_days_override}
                  onChange={(ev) => setForm((f) => ({ ...f, trial_days_override: ev.target.value }))}
                />
              </label>
            ) : null}
            <label className="block text-sm">
              <span className="text-slate-600">Correo del administrador</span>
              <input
                required
                type="email"
                className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                value={form.admin_email}
                onChange={(ev) => setForm((f) => ({ ...f, admin_email: ev.target.value }))}
              />
            </label>
            <label className="block text-sm">
              <span className="text-slate-600">Contraseña inicial del administrador</span>
              <input
                required
                type="password"
                autoComplete="new-password"
                className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                value={form.admin_password}
                onChange={(ev) => setForm((f) => ({ ...f, admin_password: ev.target.value }))}
              />
              <PasswordPolicyHint className="mt-1" />
            </label>
            <label className="block text-sm">
              <span className="text-slate-600">Nombre</span>
              <input
                required
                className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                value={form.admin_first_name}
                onChange={(ev) => setForm((f) => ({ ...f, admin_first_name: ev.target.value }))}
              />
            </label>
            <label className="block text-sm">
              <span className="text-slate-600">Primer apellido</span>
              <input
                required
                className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                value={form.admin_last_name_1}
                onChange={(ev) => setForm((f) => ({ ...f, admin_last_name_1: ev.target.value }))}
              />
            </label>
            <label className="sm:col-span-2 block text-sm">
              <span className="text-slate-600">Segundo apellido (opcional)</span>
              <input
                className="mt-1 w-full rounded border border-slate-300 px-3 py-2"
                value={form.admin_last_name_2}
                onChange={(ev) => setForm((f) => ({ ...f, admin_last_name_2: ev.target.value }))}
              />
            </label>
            <div className="sm:col-span-2">
              <button
                type="submit"
                disabled={creating || !plans.length}
                className="rounded-lg bg-lime-700 px-4 py-2 text-sm font-medium text-white hover:bg-lime-800 disabled:opacity-60"
              >
                {creating ? 'Creando…' : 'Crear organización'}
              </button>
              {!plans.length ? (
                <p className="mt-2 text-xs text-amber-800">
                  No hay planes activos. Cree uno en la pestaña{' '}
                  <a href="/superadmin/plans" className="font-medium underline">
                    Planes
                  </a>
                  .
                </p>
              ) : null}
            </div>
          </form>
        </section>

        <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-500">Organizaciones</h2>
          {loading ? (
            <p className="mt-4 text-sm text-slate-500">Cargando…</p>
          ) : (
            <ul className="mt-4 divide-y divide-slate-100">
              {clients.map((c) => (
                <li key={c.id} className="flex flex-wrap items-center justify-between gap-2 py-3">
                  <div>
                    <div className="font-medium text-slate-800">{c.name}</div>
                    <div className="text-xs text-slate-500">
                      Plan: {c.plan_name || '—'} · Estado: {c.status || '—'}
                      {c.license_expires_on_display ? (
                        <> · Vence: {c.license_expires_on_display}</>
                      ) : (
                        <> · Sin vencimiento</>
                      )}
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <button
                      type="button"
                      disabled={renewingId === c.id}
                      className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm text-slate-700 hover:bg-slate-50 disabled:opacity-60"
                      onClick={() => handleRenew(c)}
                    >
                      {renewingId === c.id ? 'Renovando…' : 'Renovar licencia'}
                    </button>
                    <button
                      type="button"
                      className="rounded-lg border border-lime-700 px-3 py-1.5 text-sm font-medium text-lime-800 hover:bg-lime-50"
                      onClick={() => handleEnter(c.id)}
                    >
                      Entrar
                    </button>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>
    </SuperadminLayout>
  );
}
