import { useEffect, useState } from 'react';
import HarvestPeriodsSettingsSection from './HarvestPeriodsSettingsSection.jsx';
import HarvestEstimatesSettingsSection from './HarvestEstimatesSettingsSection.jsx';

export const HARVEST_SETTINGS_TAB_KEY = 'wardi.settings.harvestTab';

const TABS = [
  { id: 'periods', label: 'Periodos de cosecha' },
  { id: 'estimates', label: 'Estimaciones' },
];

export default function HarvestSettingsShell({ user }) {
  const [tab, setTab] = useState('periods');

  useEffect(() => {
    try {
      const saved = sessionStorage.getItem(HARVEST_SETTINGS_TAB_KEY);
      if (saved === 'periods' || saved === 'estimates') setTab(saved);
    } catch {
      /* ignore */
    }
  }, []);

  function selectTab(id) {
    setTab(id);
    try {
      sessionStorage.setItem(HARVEST_SETTINGS_TAB_KEY, id);
    } catch {
      /* ignore */
    }
  }

  return (
    <section className="mt-5 space-y-4 rounded-2xl border border-white/50 bg-white/90 p-5 text-slate-800 shadow">
      <header>
        <h3 className="text-base font-semibold text-lime-800">Definición de períodos de cosecha</h3>
        <p className="mt-1 text-sm text-slate-600">
          Define temporadas de cosecha (calendario y precio de referencia por fanega) y metas planificadas
          en cajuelas por lote. La producción diaria real se registra en Producción de café.
        </p>
      </header>

      <div className="flex flex-wrap gap-2 border-b border-slate-200 pb-2">
        {TABS.map((t) => (
          <button
            key={t.id}
            type="button"
            onClick={() => selectTab(t.id)}
            className={`rounded-lg px-4 py-2 text-sm font-semibold ${
              tab === t.id
                ? 'bg-lime-700 text-white'
                : 'border border-slate-300 bg-white text-slate-700 hover:bg-slate-50'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {tab === 'periods' ? (
        <HarvestPeriodsSettingsSection user={user} />
      ) : (
        <HarvestEstimatesSettingsSection user={user} />
      )}
    </section>
  );
}
