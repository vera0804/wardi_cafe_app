import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  createLot,
  getLotsMeta,
  listLots,
  setLotActive,
  updateLot,
} from '../services/lots.js';
import { listCantons, listDistricts, listProvinces } from '../services/geo.js';

const DEFAULT_FORM = {
  name: '',
  area_ha: '',
  plant_count: '0',
  variety_ids: [],
  province_id: '',
  canton_id: '',
  district_id: '',
  community: '',
};

function formatArea(value) {
  if (value == null) return '—';
  return Number(value).toFixed(2);
}

function locationLabel(lot) {
  if (lot?.location_display) return lot.location_display;
  const parts = [lot?.province_name, lot?.canton_name, lot?.district_name, lot?.community].filter(
    Boolean
  );
  return parts.length ? parts.join(', ') : '—';
}

export default function LotsPage({ user }) {
  const [lots, setLots] = useState([]);
  const [meta, setMeta] = useState({ varieties: [] });
  const [searchTerm, setSearchTerm] = useState('');
  const [includeInactive, setIncludeInactive] = useState(false);
  const [showVarietiesPicker, setShowVarietiesPicker] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [form, setForm] = useState(DEFAULT_FORM);
  const [editingId, setEditingId] = useState(null);
  const [provinces, setProvinces] = useState([]);
  const [cantons, setCantons] = useState([]);
  const [districts, setDistricts] = useState([]);
  const [geoLoading, setGeoLoading] = useState(false);

  const readOnly = false;

  const filteredLots = useMemo(() => {
    const term = String(searchTerm || '')
      .trim()
      .toLowerCase();
    if (!term) return lots;
    return lots.filter((lot) => {
      const byName = String(lot?.name || '')
        .toLowerCase()
        .includes(term);
      const byLoc = locationLabel(lot).toLowerCase().includes(term);
      return byName || byLoc;
    });
  }, [lots, searchTerm]);

  async function refresh() {
    setLoading(true);
    setError('');
    try {
      const data = await listLots({ includeInactive });
      setLots(data || []);
    } catch (e) {
      setError(e?.message || 'No se pudieron cargar las fincas.');
    } finally {
      setLoading(false);
    }
  }

  async function refreshMeta() {
    try {
      const data = await getLotsMeta();
      setMeta({ varieties: data?.varieties || [] });
    } catch (e) {
      setError(e?.message || 'No se pudieron cargar variedades.');
    }
  }

  useEffect(() => {
    refreshMeta();
  }, []);

  useEffect(() => {
    refresh();
  }, [includeInactive]);

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

  function resetForm() {
    setForm(DEFAULT_FORM);
    setEditingId(null);
    setShowVarietiesPicker(false);
    setShowForm(false);
    setCantons([]);
    setDistricts([]);
  }

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

  function onToggleVariety(varietyId) {
    setForm((prev) => {
      const exists = prev.variety_ids.includes(varietyId);
      return {
        ...prev,
        variety_ids: exists
          ? prev.variety_ids.filter((id) => id !== varietyId)
          : [...prev.variety_ids, varietyId],
      };
    });
  }

  function validateForm() {
    if (!String(form.name || '').trim()) {
      return 'El nombre de la finca es obligatorio.';
    }
    if (!String(form.province_id || '').trim()) {
      return 'La provincia es obligatoria.';
    }
    if (form.area_ha !== '' && Number(form.area_ha) <= 0) {
      return 'El área (ha) debe ser mayor que 0.';
    }
    if (
      form.plant_count !== '' &&
      (!Number.isInteger(Number(form.plant_count)) || Number(form.plant_count) < 0)
    ) {
      return 'La cantidad de plantas debe ser un entero mayor o igual a 0.';
    }
    return null;
  }

  async function handleSubmit(e) {
    e.preventDefault();
    if (readOnly) return;

    const validation = validateForm();
    if (validation) {
      setError(validation);
      return;
    }

    const payload = {
      name: form.name.trim(),
      area_ha: form.area_ha === '' ? null : Number(form.area_ha),
      plant_count: form.plant_count === '' ? 0 : Number(form.plant_count),
      variety_ids: form.variety_ids,
      province_id: Number(form.province_id),
      canton_id: form.canton_id ? Number(form.canton_id) : null,
      district_id: form.district_id ? Number(form.district_id) : null,
      community: form.community.trim() || null,
    };

    setSaving(true);
    setError('');
    try {
      if (editingId) {
        await updateLot(editingId, payload);
      } else {
        await createLot(payload);
      }
      resetForm();
      await refresh();
    } catch (e) {
      setError(e?.message || 'No se pudo guardar la finca.');
    } finally {
      setSaving(false);
    }
  }

  async function handleToggleActive(lot) {
    if (readOnly) return;
    setSaving(true);
    setError('');
    try {
      await setLotActive(lot.id, !lot.is_active);
      await refresh();
    } catch (e) {
      setError(e?.message || 'No se pudo actualizar el estado de la finca.');
    } finally {
      setSaving(false);
    }
  }

  async function startEdit(lot) {
    setEditingId(lot.id);
    setShowForm(true);
    setShowVarietiesPicker(true);
    setForm({
      name: lot.name || '',
      area_ha: lot.area_ha ?? '',
      plant_count: lot.plant_count ?? 0,
      variety_ids: Array.isArray(lot.variety_ids) ? lot.variety_ids : [],
      province_id: lot.province_id != null ? String(lot.province_id) : '',
      canton_id: lot.canton_id != null ? String(lot.canton_id) : '',
      district_id: lot.district_id != null ? String(lot.district_id) : '',
      community: lot.community || '',
    });
    if (lot.province_id) await loadCantons(lot.province_id);
    if (lot.canton_id) await loadDistricts(lot.canton_id);
  }

  return (
    <section className="space-y-4 rounded-2xl border border-white/50 bg-white/90 p-5 text-slate-800 shadow">
      <header className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h3 className="text-base font-semibold text-lime-800">Fincas</h3>
          <p className="text-sm text-slate-600">
            Gestiona las fincas operativas de la empresa. Cada finca tiene su propia ubicación.
          </p>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
          <label className="inline-flex items-center gap-2 text-sm text-slate-700">
            <input
              type="checkbox"
              checked={includeInactive}
              onChange={(e) => setIncludeInactive(e.target.checked)}
              className="h-4 w-4 rounded border-slate-300"
            />
            Mostrar inactivas
          </label>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Filtrar por nombre o ubicación"
            className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm"
          />
        </div>
      </header>

      {error ? (
        <p className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800">
          {error}
        </p>
      ) : null}

      <div className="flex flex-wrap items-center gap-2">
        {!readOnly ? (
          <button
            type="button"
            onClick={() => {
              if (!showForm) {
                setEditingId(null);
                setForm(DEFAULT_FORM);
                setShowVarietiesPicker(false);
              }
              setShowForm((v) => !v);
            }}
            disabled={saving}
            className="rounded-lg bg-lime-700 px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
          >
            {showForm ? 'Ocultar formulario' : 'Crear finca'}
          </button>
        ) : (
          <p className="text-sm text-slate-600">Tu rol tiene acceso de solo lectura.</p>
        )}
      </div>

      {showForm ? (
        <form onSubmit={handleSubmit} className="space-y-3 rounded-xl border border-slate-200 bg-slate-50 p-4">
          <div className="grid grid-cols-1 gap-3 lg:grid-cols-4">
            <label className="text-sm lg:col-span-2">
              <span className="mb-1 block font-medium">Nombre *</span>
              <input
                value={form.name}
                onChange={(e) => onChange('name', e.target.value)}
                disabled={readOnly || saving}
                className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
              />
            </label>

            <label className="text-sm">
              <span className="mb-1 block font-medium">Provincia *</span>
              <select
                value={form.province_id}
                onChange={(e) => onChange('province_id', e.target.value)}
                disabled={readOnly || saving}
                className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
              >
                <option value="">Seleccione provincia</option>
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

            <label className="text-sm lg:col-span-2">
              <span className="mb-1 block font-medium">Comunidad</span>
              <input
                value={form.community}
                onChange={(e) => onChange('community', e.target.value)}
                disabled={readOnly || saving}
                className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
              />
            </label>

            <label className="text-sm">
              <span className="mb-1 block font-medium">Área (ha)</span>
              <input
                type="number"
                step="0.0001"
                min="0.0001"
                value={form.area_ha}
                onChange={(e) => onChange('area_ha', e.target.value)}
                disabled={readOnly || saving}
                className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
              />
            </label>

            <label className="text-sm">
              <span className="mb-1 block font-medium">Cantidad de plantas</span>
              <input
                type="number"
                step="1"
                min="0"
                value={form.plant_count}
                onChange={(e) => onChange('plant_count', e.target.value)}
                disabled={readOnly || saving}
                className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2"
              />
            </label>
          </div>

          <fieldset className="rounded-lg border border-slate-200 bg-white p-3">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <legend className="px-1 text-sm font-medium text-slate-700">Variedades (opcional)</legend>
              <button
                type="button"
                onClick={() => setShowVarietiesPicker((v) => !v)}
                className="rounded border border-slate-300 bg-white px-2 py-1 text-xs"
              >
                {showVarietiesPicker ? 'Ocultar variedades' : 'Seleccionar variedades'}
              </button>
            </div>
            {!showVarietiesPicker ? (
              <p className="mt-2 text-sm text-slate-500">
                {form.variety_ids.length > 0
                  ? `${form.variety_ids.length} variedades seleccionadas.`
                  : 'Sin variedades seleccionadas.'}
              </p>
            ) : meta.varieties.length === 0 ? (
              <p className="mt-2 text-sm text-slate-500">No hay variedades activas para seleccionar.</p>
            ) : (
              <div className="mt-2 grid grid-cols-1 gap-2 sm:grid-cols-2 lg:grid-cols-3">
                {meta.varieties.map((variety) => (
                  <label key={variety.id} className="inline-flex items-center gap-2 text-sm">
                    <input
                      type="checkbox"
                      checked={form.variety_ids.includes(variety.id)}
                      onChange={() => onToggleVariety(variety.id)}
                      disabled={readOnly || saving}
                      className="h-4 w-4 rounded border-slate-300"
                    />
                    {variety.name}
                  </label>
                ))}
              </div>
            )}
          </fieldset>

          <div className="flex flex-wrap items-center gap-2">
            <button
              type="submit"
              disabled={readOnly || saving}
              className="rounded-lg bg-lime-700 px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
            >
              {editingId ? 'Guardar cambios' : 'Crear finca'}
            </button>
            <button
              type="button"
              onClick={resetForm}
              disabled={saving}
              className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm"
            >
              Cancelar
            </button>
          </div>
        </form>
      ) : null}

      <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table className="min-w-full text-sm">
          <thead className="bg-slate-100 text-slate-700">
            <tr>
              <th className="px-3 py-2 text-left">Finca</th>
              <th className="px-3 py-2 text-left">Ubicación</th>
              <th className="px-3 py-2 text-left">Área (ha)</th>
              <th className="px-3 py-2 text-left">Plantas</th>
              <th className="px-3 py-2 text-left">Variedades</th>
              <th className="px-3 py-2 text-left">Estado</th>
              <th className="px-3 py-2 text-left">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={7} className="px-3 py-4 text-center text-slate-500">
                  Cargando fincas...
                </td>
              </tr>
            ) : filteredLots.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-3 py-4 text-center text-slate-500">
                  No hay fincas que coincidan con el filtro.
                </td>
              </tr>
            ) : (
              filteredLots.map((lot) => (
                <tr key={lot.id} className="border-t border-slate-200">
                  <td className="px-3 py-2 font-medium">{lot.name}</td>
                  <td className="px-3 py-2">{locationLabel(lot)}</td>
                  <td className="px-3 py-2">{formatArea(lot.area_ha)}</td>
                  <td className="px-3 py-2">{lot.plant_count ?? 0}</td>
                  <td className="px-3 py-2">
                    {Array.isArray(lot.varieties) && lot.varieties.length
                      ? lot.varieties.map((v) => v.name).join(', ')
                      : '—'}
                  </td>
                  <td className="px-3 py-2">
                    <span
                      className={`rounded-full px-2 py-0.5 text-xs font-semibold ${
                        lot.is_active ? 'bg-lime-100 text-lime-800' : 'bg-slate-200 text-slate-700'
                      }`}
                    >
                      {lot.is_active ? 'Activa' : 'Inactiva'}
                    </span>
                  </td>
                  <td className="px-3 py-2">
                    <div className="flex flex-wrap gap-2">
                      <button
                        type="button"
                        onClick={() => startEdit(lot)}
                        disabled={readOnly || saving}
                        className="rounded border border-slate-300 bg-white px-2 py-1 text-xs"
                      >
                        Editar
                      </button>
                      <button
                        type="button"
                        onClick={() => handleToggleActive(lot)}
                        disabled={readOnly || saving}
                        className="rounded border border-slate-300 bg-white px-2 py-1 text-xs"
                      >
                        {lot.is_active ? 'Inactivar' : 'Activar'}
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
