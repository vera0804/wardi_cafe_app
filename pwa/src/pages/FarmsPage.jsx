import { useCallback, useEffect, useState } from 'react';
import { listFarms, updateFarm } from '../services/farms.js';
import { listCantons, listDistricts, listProvinces } from '../services/geo.js';

const DEFAULT_FORM = {
  name: '',
  owner_name: '',
  owner_id_type: 'nacional',
  owner_id_number: '',
  legal_name: '',
  legal_id_number: '',
  phone: '',
  address: '',
  province_id: '',
  canton_id: '',
  district_id: '',
  community: '',
  area_ha: '',
  labor_allocation_mode: 'manual',
};

function formatArea(value) {
  if (value == null || value === '') return '—';
  return Number(value).toFixed(2);
}

function displayText(value) {
  const s = value == null ? '' : String(value).trim();
  return s || '—';
}

function ownerIdTypeLabel(type) {
  if (type === 'extranjero') return 'Extranjero';
  if (type === 'nacional') return 'Nacional';
  return '—';
}

function allocationModeLabel(mode) {
  return mode === 'area' ? 'Por área (hectáreas)' : 'Manual';
}

function FichaRow({ label, value, wide = false }) {
  return (
    <div className={wide ? 'sm:col-span-2 lg:col-span-3' : ''}>
      <dt className="text-xs font-medium uppercase tracking-wide text-slate-500">{label}</dt>
      <dd className="mt-0.5 text-sm text-slate-800">{value}</dd>
    </div>
  );
}

function AllocationHelp({ mode }) {
  return (
    <p className="mt-3 text-sm leading-relaxed text-slate-600">
      Los <strong className="font-medium text-slate-700">gastos generales</strong> de la empresa y la{' '}
      <strong className="font-medium text-slate-700">planilla fija</strong> se reparten entre las fincas
      operativas.
      {mode === 'manual' ? (
        <>
          {' '}
          Con <strong className="font-medium text-slate-700">manual</strong>, usted indica a qué finca va cada gasto o
          cada parte de la planilla.
        </>
      ) : (
        <>
          {' '}
          Con <strong className="font-medium text-slate-700">por área</strong>, el sistema reparte en proporción a las
          hectáreas de cada finca (registre el área en Fincas y en esta ficha).
        </>
      )}
    </p>
  );
}

function FichaSection({ title, children }) {
  return (
    <section className="rounded-xl border border-slate-200 bg-white p-4">
      <h4 className="mb-3 text-sm font-semibold text-slate-700">{title}</h4>
      <dl className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">{children}</dl>
    </section>
  );
}

export default function FarmsPage({ user }) {
  const [empresa, setEmpresa] = useState(null);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [form, setForm] = useState(DEFAULT_FORM);
  const [provinces, setProvinces] = useState([]);
  const [cantons, setCantons] = useState([]);
  const [districts, setDistricts] = useState([]);
  const [geoLoading, setGeoLoading] = useState(false);
  const [editing, setEditing] = useState(false);

  const readOnly = false;

  function syncFormFromEmpresa(row) {
    if (!row) {
      setForm(DEFAULT_FORM);
      return;
    }
    setForm({
      name: row.name || '',
      owner_name: row.owner_name || '',
      owner_id_type: row.owner_id_type || 'nacional',
      owner_id_number: row.owner_id_number || '',
      legal_name: row.legal_name || '',
      legal_id_number: row.legal_id_number || '',
      phone: row.phone || '',
      address: row.address || '',
      province_id: row.province_id != null ? String(row.province_id) : '',
      canton_id: row.canton_id != null ? String(row.canton_id) : '',
      district_id: row.district_id != null ? String(row.district_id) : '',
      community: row.community || '',
      area_ha: row.area_ha != null ? String(row.area_ha) : '',
      labor_allocation_mode: row.labor_allocation_mode || 'manual',
    });
  }

  async function refresh() {
    setLoading(true);
    setError('');
    try {
      const rows = await listFarms();
      const row = Array.isArray(rows) && rows.length ? rows[0] : null;
      setEmpresa(row);
      if (row) {
        syncFormFromEmpresa(row);
        if (row.province_id) await loadCantons(row.province_id);
        if (row.canton_id) await loadDistricts(row.canton_id);
      }
    } catch (e) {
      setError(e?.message || 'No se pudo cargar la ficha de empresa.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
  }, []);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const rows = await listProvinces();
        if (!cancelled) setProvinces(Array.isArray(rows) ? rows : []);
      } catch {
        if (!cancelled) setProvinces([]);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const loadCantons = useCallback(async (provinceId) => {
    if (!provinceId) {
      setCantons([]);
      return;
    }
    setGeoLoading(true);
    try {
      const rows = await listCantons(provinceId);
      setCantons(Array.isArray(rows) ? rows : []);
    } catch {
      setCantons([]);
    } finally {
      setGeoLoading(false);
    }
  }, []);

  const loadDistricts = useCallback(async (cantonId) => {
    if (!cantonId) {
      setDistricts([]);
      return;
    }
    setGeoLoading(true);
    try {
      const rows = await listDistricts(cantonId);
      setDistricts(Array.isArray(rows) ? rows : []);
    } catch {
      setDistricts([]);
    } finally {
      setGeoLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!form.province_id) {
      setCantons([]);
      return;
    }
    loadCantons(form.province_id);
  }, [form.province_id, loadCantons]);

  useEffect(() => {
    if (!form.canton_id) {
      setDistricts([]);
      return;
    }
    loadDistricts(form.canton_id);
  }, [form.canton_id, loadDistricts]);

  function onChange(field, value) {
    setForm((prev) => {
      const next = { ...prev, [field]: value };
      if (field === 'province_id') {
        next.canton_id = '';
        next.district_id = '';
      }
      if (field === 'canton_id') {
        next.district_id = '';
      }
      return next;
    });
  }

  function validateForm() {
    if (!String(form.name || '').trim()) {
      return 'El nombre de la empresa es obligatorio.';
    }
    if (form.area_ha !== '' && Number(form.area_ha) < 0) {
      return 'El área (ha) debe ser mayor o igual a 0.';
    }
    return null;
  }

  function buildPayload({ recalculateAreaFromLots = false } = {}) {
    return {
      name: form.name.trim(),
      owner_name: form.owner_name.trim() || null,
      owner_id_type: form.owner_id_number.trim() ? form.owner_id_type : null,
      owner_id_number: form.owner_id_number.trim() || null,
      legal_name: form.legal_name.trim() || null,
      legal_id_number: form.legal_id_number.trim() || null,
      phone: form.phone.trim() || null,
      address: form.address.trim() || null,
      province_id: form.province_id ? Number(form.province_id) : null,
      canton_id: form.canton_id ? Number(form.canton_id) : null,
      district_id: form.district_id ? Number(form.district_id) : null,
      community: form.community.trim() || null,
      area_ha: form.area_ha === '' ? null : Number(form.area_ha),
      labor_allocation_mode: form.labor_allocation_mode,
      ...(recalculateAreaFromLots ? { recalculate_area_from_lots: true } : {}),
    };
  }

  async function handleSubmit(e) {
    e.preventDefault();
    if (readOnly || !empresa?.id) return;

    const validation = validateForm();
    if (validation) {
      setError(validation);
      return;
    }

    setSaving(true);
    setError('');
    try {
      await updateFarm(empresa.id, buildPayload());
      await refresh();
      setEditing(false);
    } catch (e) {
      setError(e?.message || 'No se pudo guardar la empresa.');
    } finally {
      setSaving(false);
    }
  }

  function startEditing() {
    setError('');
    syncFormFromEmpresa(empresa);
    setEditing(true);
  }

  function cancelEditing() {
    setError('');
    syncFormFromEmpresa(empresa);
    setEditing(false);
  }

  async function handleRecalculateArea() {
    if (!empresa?.id) return;
    setSaving(true);
    setError('');
    try {
      await updateFarm(empresa.id, buildPayload({ recalculateAreaFromLots: true }));
      await refresh();
    } catch (e) {
      setError(e?.message || 'No se pudo recalcular el área.');
    } finally {
      setSaving(false);
    }
  }

  if (loading && !empresa) {
    return (
      <section className="rounded-2xl border border-white/50 bg-white/90 p-5 text-slate-600 shadow">
        Cargando ficha de empresa…
      </section>
    );
  }

  if (!empresa) {
    return (
      <section className="rounded-2xl border border-amber-200 bg-amber-50 p-5 text-amber-950 shadow">
        <p className="font-medium">No hay ficha de empresa configurada.</p>
        <p className="mt-1 text-sm">Contacte al administrador de la plataforma.</p>
      </section>
    );
  }

  const hasLegal = Boolean(empresa.legal_name?.trim() || empresa.legal_id_number?.trim());
  const hasOfficeLocation = Boolean(
    empresa.address?.trim() || empresa.location_display?.trim()
  );

  return (
    <section className="space-y-4 rounded-2xl border border-white/50 bg-white/90 p-5 text-slate-800 shadow">
      <header className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h3 className="text-base font-semibold text-lime-800">Empresa</h3>
          <p className="text-sm text-slate-600">
            Datos de la empresa cafetalera y del dueño. Las fincas operativas se gestionan en el módulo
            Fincas.
          </p>
        </div>
        {!readOnly && !editing ? (
          <button
            type="button"
            onClick={startEditing}
            className="rounded-lg bg-lime-700 px-4 py-2 text-sm font-semibold text-white hover:bg-lime-800"
          >
            Editar
          </button>
        ) : null}
      </header>

      {error ? (
        <p className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800">
          {error}
        </p>
      ) : null}

      {!editing ? (
        <div className="space-y-4">
          <FichaSection title="Identificación">
            <FichaRow label="Nombre de la empresa" value={displayText(empresa.name)} wide />
          </FichaSection>

          <FichaSection title="Dueño">
            <FichaRow label="Nombre" value={displayText(empresa.owner_name)} wide />
            <FichaRow label="Tipo de cédula" value={ownerIdTypeLabel(empresa.owner_id_type)} />
            <FichaRow label="Cédula" value={displayText(empresa.owner_id_number)} />
            <FichaRow label="Teléfono" value={displayText(empresa.phone)} wide />
          </FichaSection>

          {hasLegal ? (
            <FichaSection title="Persona jurídica">
              <FichaRow label="Razón social" value={displayText(empresa.legal_name)} wide />
              <FichaRow label="Cédula jurídica" value={displayText(empresa.legal_id_number)} />
            </FichaSection>
          ) : null}

          {hasOfficeLocation ? (
            <FichaSection title="Dirección de oficina">
              <FichaRow label="Dirección" value={displayText(empresa.address)} wide />
              <FichaRow label="Ubicación" value={displayText(empresa.location_display)} wide />
            </FichaSection>
          ) : null}

          <section className="rounded-xl border border-slate-200 bg-white p-4">
            <h4 className="mb-3 text-sm font-semibold text-slate-700">Operación</h4>
            <dl className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              <FichaRow
                label="Área total (ha)"
                value={
                  empresa.area_ha_manual === false
                    ? `${formatArea(empresa.area_ha)} (autosuma desde fincas)`
                    : formatArea(empresa.area_ha)
                }
              />
              <FichaRow
                label="Método de asignación de costos"
                value={allocationModeLabel(empresa.labor_allocation_mode)}
              />
            </dl>
            <AllocationHelp mode={empresa.labor_allocation_mode} />
            {!readOnly ? (
              <div className="mt-4 flex flex-wrap gap-2 border-t border-slate-100 pt-4">
                <button
                  type="button"
                  onClick={handleRecalculateArea}
                  disabled={saving}
                  className="rounded-lg border border-slate-300 bg-slate-50 px-4 py-2 text-sm hover:bg-slate-100 disabled:opacity-60"
                >
                  {saving ? 'Procesando…' : 'Recalcular área desde fincas'}
                </button>
              </div>
            ) : null}
          </section>
        </div>
      ) : (
      <form
        onSubmit={handleSubmit}
        className="grid grid-cols-1 gap-3 rounded-xl border border-slate-200 bg-slate-50 p-4 lg:grid-cols-3"
      >
        <h4 className="text-sm font-semibold text-lime-800 lg:col-span-3">Editar empresa</h4>
        <h4 className="text-sm font-semibold text-slate-700 lg:col-span-3">Identificación</h4>
        <label className="text-sm lg:col-span-3">
          <span className="mb-1 block font-medium">Nombre de la empresa *</span>
          <input
            value={form.name}
            onChange={(e) => onChange('name', e.target.value)}
            disabled={readOnly || saving}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
          />
        </label>

        <h4 className="text-sm font-semibold text-slate-700 lg:col-span-3">Dueño</h4>
        <label className="text-sm lg:col-span-2">
          <span className="mb-1 block font-medium">Nombre del dueño</span>
          <input
            value={form.owner_name}
            onChange={(e) => onChange('owner_name', e.target.value)}
            disabled={readOnly || saving}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
          />
        </label>
        <label className="text-sm">
          <span className="mb-1 block font-medium">Tipo de cédula</span>
          <select
            value={form.owner_id_type}
            onChange={(e) => onChange('owner_id_type', e.target.value)}
            disabled={readOnly || saving}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
          >
            <option value="nacional">Nacional</option>
            <option value="extranjero">Extranjero</option>
          </select>
        </label>
        <label className="text-sm">
          <span className="mb-1 block font-medium">Cédula</span>
          <input
            value={form.owner_id_number}
            onChange={(e) => onChange('owner_id_number', e.target.value)}
            disabled={readOnly || saving}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
          />
        </label>
        <label className="text-sm lg:col-span-2">
          <span className="mb-1 block font-medium">Teléfono</span>
          <input
            value={form.phone}
            onChange={(e) => onChange('phone', e.target.value)}
            disabled={readOnly || saving}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
          />
        </label>

        <h4 className="text-sm font-semibold text-slate-700 lg:col-span-3">
          Persona jurídica (opcional)
        </h4>
        <label className="text-sm lg:col-span-2">
          <span className="mb-1 block font-medium">Razón social</span>
          <input
            value={form.legal_name}
            onChange={(e) => onChange('legal_name', e.target.value)}
            disabled={readOnly || saving}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
          />
        </label>
        <label className="text-sm">
          <span className="mb-1 block font-medium">Cédula jurídica</span>
          <input
            value={form.legal_id_number}
            onChange={(e) => onChange('legal_id_number', e.target.value)}
            disabled={readOnly || saving}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
          />
        </label>

        <h4 className="text-sm font-semibold text-slate-700 lg:col-span-3">
          Dirección de oficina (opcional)
        </h4>
        <label className="text-sm lg:col-span-3">
          <span className="mb-1 block font-medium">Dirección</span>
          <input
            value={form.address}
            onChange={(e) => onChange('address', e.target.value)}
            disabled={readOnly || saving}
            placeholder="Persona u oficina"
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
          />
        </label>
        <label className="text-sm">
          <span className="mb-1 block font-medium">Provincia</span>
          <select
            value={form.province_id}
            onChange={(e) => onChange('province_id', e.target.value)}
            disabled={readOnly || saving}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
          >
            <option value="">Opcional</option>
            {provinces.map((p) => (
              <option key={p.id} value={String(p.id)}>
                {p.name}
              </option>
            ))}
          </select>
        </label>
        <label className="text-sm">
          <span className="mb-1 block font-medium">Cantón</span>
          <select
            value={form.canton_id}
            onChange={(e) => onChange('canton_id', e.target.value)}
            disabled={readOnly || saving || !form.province_id || geoLoading}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 disabled:bg-slate-100"
          >
            <option value="">Opcional</option>
            {cantons.map((c) => (
              <option key={c.id} value={String(c.id)}>
                {c.name}
              </option>
            ))}
          </select>
        </label>
        <label className="text-sm">
          <span className="mb-1 block font-medium">Distrito</span>
          <select
            value={form.district_id}
            onChange={(e) => onChange('district_id', e.target.value)}
            disabled={readOnly || saving || !form.canton_id || geoLoading}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 disabled:bg-slate-100"
          >
            <option value="">Opcional</option>
            {districts.map((d) => (
              <option key={d.id} value={String(d.id)}>
                {d.name}
              </option>
            ))}
          </select>
        </label>
        <label className="text-sm lg:col-span-3">
          <span className="mb-1 block font-medium">Comunidad</span>
          <input
            value={form.community}
            onChange={(e) => onChange('community', e.target.value)}
            disabled={readOnly || saving}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
          />
        </label>

        <h4 className="text-sm font-semibold text-slate-700 lg:col-span-3">Operación</h4>
        <label className="text-sm">
          <span className="mb-1 block font-medium">Área total (ha)</span>
          <input
            type="number"
            step="0.0001"
            min="0"
            value={form.area_ha}
            onChange={(e) => onChange('area_ha', e.target.value)}
            disabled={readOnly || saving}
            placeholder="Vacío = autosuma desde fincas"
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
          />
        </label>
        <div className="space-y-2 lg:col-span-3">
          <label className="block text-sm">
            <span className="mb-1 block font-medium">Método de asignación de costos</span>
            <select
              value={form.labor_allocation_mode}
              onChange={(e) => onChange('labor_allocation_mode', e.target.value)}
              disabled={readOnly || saving}
              className="w-full max-w-md rounded-lg border border-slate-300 bg-white px-3 py-2"
            >
              <option value="manual">Manual</option>
              <option value="area">Por área (hectáreas)</option>
            </select>
          </label>
          <div className="rounded-lg border border-slate-200 bg-white px-3 py-2">
            <AllocationHelp mode={form.labor_allocation_mode} />
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-2 lg:col-span-3">
          <button
            type="submit"
            disabled={readOnly || saving}
            className="rounded-lg bg-lime-700 px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
          >
            {saving ? 'Guardando…' : 'Guardar cambios'}
          </button>
          <button
            type="button"
            onClick={cancelEditing}
            disabled={saving}
            className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm"
          >
            Cancelar
          </button>
          <button
            type="button"
            onClick={handleRecalculateArea}
            disabled={readOnly || saving}
            className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm"
          >
            Recalcular área desde fincas
          </button>
        </div>
      </form>
      )}
    </section>
  );
}
