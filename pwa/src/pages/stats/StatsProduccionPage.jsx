import KpiCard from './KpiCard.jsx';
import StatsSectionShell from './StatsSectionShell.jsx';
import StatsAccessDenied from './StatsAccessDenied.jsx';
import { useStatsOverview } from './useStatsOverview.js';
import { crc, num, TableWrap } from './statsFormat.jsx';

function fmtPeriod(d) {
  if (d == null) return '—';
  return String(d).slice(0, 10);
}

function HarvestBars({ rows }) {
  const maxVal = Math.max(0.0001, ...rows.map((r) => Number(r.fanegas ?? r.kg ?? 0)));
  return (
    <div className="space-y-2">
      {rows.map((r) => {
        const v = Number(r.fanegas ?? r.kg ?? 0);
        const w = Math.max(3, Math.round((v / maxVal) * 100));
        return (
          <div key={String(r.period_start)} className="flex items-center gap-2 text-sm">
            <span className="w-28 shrink-0 text-stone-600 sm:w-32">{fmtPeriod(r.period_start)}</span>
            <div className="h-7 min-w-0 flex-1 rounded-md bg-stone-100">
              <div
                className="h-full rounded-md bg-gradient-to-r from-lime-600 to-lime-800/90"
                style={{ width: `${w}%` }}
              />
            </div>
            <span className="w-24 shrink-0 text-right tabular-nums text-stone-800">
              {num(v, 4)} fan.
            </span>
          </div>
        );
      })}
    </div>
  );
}

export default function StatsProduccionPage() {
  const st = useStatsOverview({ includeLowStockInRequest: false });
  if (st.blocked) return <StatsAccessDenied />;

  const cp = st.data?.cost_production;

  return (
    <StatsSectionShell
      title="Producción y rendimiento"
      description="Volumen en fanegas y cajuelas, ingresos valorizados por precio de cosecha, rendimiento por hectárea y curvas temporales."
      filtersProps={st.filtersProps}
      periodLine={st.periodLine}
    >
      {st.loading && !st.data ? <p className="text-sm text-stone-500">Cargando datos…</p> : null}
      {st.error ? (
        <div className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">{st.error}</div>
      ) : null}

      {cp ? (
        <div className="space-y-10">
          <section>
            <h2 className="mb-3 text-lg font-semibold text-stone-900">Costo y volumen</h2>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
              <KpiCard
                highlight
                title="Costo por fanega"
                value={cp.cost_per_fanega_crc != null ? crc(cp.cost_per_fanega_crc) : '—'}
                subtitle="Costos directos imputados ÷ fanegas del periodo"
              />
              <KpiCard
                title="Producción total"
                value={`${num(cp.total_fanegas ?? cp.total_kg, 4)} fanegas`}
                subtitle={`${num(cp.total_cajuelas, 2)} cajuelas`}
              />
              <KpiCard
                title="Ingresos (valor producción)"
                value={crc(cp.total_revenue_crc)}
                subtitle="Fanegas × precio por fanega de la cosecha activa"
              />
              <KpiCard
                title="Margen total"
                value={crc(cp.margin_total_crc)}
                subtitle="Ingresos − costos directos"
              />
            </div>
          </section>

          <section>
            <h2 className="mb-1 text-lg font-semibold text-stone-900">Comparación por lote</h2>
            <p className="mb-3 text-sm text-stone-600">Volumen e ingreso calculado por lote.</p>
            {st.data?.rentability_lots?.length ? (
              <TableWrap>
                <thead className="border-b border-stone-200 bg-stone-50">
                  <tr>
                    <th className="p-3 text-left font-medium text-stone-700">Finca</th>
                    <th className="p-3 text-left font-medium text-stone-700">Lote</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Cajuelas</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Fanegas</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Ingreso</th>
                  </tr>
                </thead>
                <tbody>
                  {st.data.rentability_lots.map((r) => (
                    <tr key={r.lot_id} className="border-b border-stone-100 hover:bg-stone-50/80">
                      <td className="p-3 text-stone-800">{r.farm_name}</td>
                      <td className="p-3 text-stone-800">{r.lot_name}</td>
                      <td className="p-3 text-right tabular-nums">{num(r.cajuelas, 2)}</td>
                      <td className="p-3 text-right tabular-nums">{num(r.fanegas, 4)}</td>
                      <td className="p-3 text-right tabular-nums text-emerald-800">{crc(r.revenue_crc)}</td>
                    </tr>
                  ))}
                </tbody>
              </TableWrap>
            ) : (
              <div className="rounded-xl border border-stone-200 bg-white p-8 text-center text-sm text-stone-500 shadow-sm">
                Sin producción por lote en el periodo.
              </div>
            )}
          </section>

          <section>
            <h2 className="mb-1 text-lg font-semibold text-stone-900">Comparación por finca</h2>
            {st.data?.rentability_farms?.length ? (
              <TableWrap>
                <thead className="border-b border-stone-200 bg-stone-50">
                  <tr>
                    <th className="p-3 text-left font-medium text-stone-700">Finca</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Cajuelas</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Fanegas</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Ingreso</th>
                  </tr>
                </thead>
                <tbody>
                  {st.data.rentability_farms.map((r) => (
                    <tr key={r.farm_id || r.farm_name} className="border-b border-stone-100 hover:bg-stone-50/80">
                      <td className="p-3 text-stone-800">{r.farm_name}</td>
                      <td className="p-3 text-right tabular-nums">{num(r.cajuelas, 2)}</td>
                      <td className="p-3 text-right tabular-nums">{num(r.fanegas, 4)}</td>
                      <td className="p-3 text-right tabular-nums text-emerald-800">{crc(r.revenue_crc)}</td>
                    </tr>
                  ))}
                </tbody>
              </TableWrap>
            ) : (
              <div className="rounded-xl border border-stone-200 bg-white p-8 text-center text-sm text-stone-500 shadow-sm">
                Sin datos por finca.
              </div>
            )}
          </section>

          <section className="grid grid-cols-1 gap-8 lg:grid-cols-2">
            <div>
              <h2 className="mb-1 text-lg font-semibold text-stone-900">Rendimiento por lote</h2>
              <p className="mb-3 text-sm text-stone-600">Fanegas por hectárea (requiere área en el lote).</p>
              {st.data?.yield_by_lot?.some((y) => y.fanegas_per_ha != null || y.kg_per_ha != null) ? (
                <TableWrap>
                  <thead className="border-b border-stone-200 bg-stone-50">
                    <tr>
                      <th className="p-3 text-left font-medium text-stone-700">Lote</th>
                      <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Fan.</th>
                      <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Ha</th>
                      <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Fan./Ha</th>
                    </tr>
                  </thead>
                  <tbody>
                    {st.data.yield_by_lot
                      .filter((y) => y.fanegas_per_ha != null || y.kg_per_ha != null)
                      .map((y) => (
                        <tr key={y.lot_id} className="border-b border-stone-100 hover:bg-stone-50/80">
                          <td className="p-3 text-stone-800">
                            {y.farm_name} — {y.lot_name}
                          </td>
                          <td className="p-3 text-right tabular-nums">{num(y.fanegas ?? y.kg, 4)}</td>
                          <td className="p-3 text-right tabular-nums">{num(y.area_ha, 2)}</td>
                          <td className="p-3 text-right font-medium tabular-nums text-lime-900">
                            {num(y.fanegas_per_ha ?? y.kg_per_ha, 4)}
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </TableWrap>
              ) : (
                <div className="rounded-xl border border-stone-200 bg-white p-6 text-sm text-stone-500 shadow-sm">
                  Sin lotes con área y producción en el periodo para calcular fanegas/Ha.
                </div>
              )}
            </div>
            <div>
              <h2 className="mb-1 text-lg font-semibold text-stone-900">Rendimiento por finca</h2>
              {st.data?.yield_by_farm?.some((y) => y.fanegas_per_ha != null || y.kg_per_ha != null) ? (
                <TableWrap>
                  <thead className="border-b border-stone-200 bg-stone-50">
                    <tr>
                      <th className="p-3 text-left font-medium text-stone-700">Finca</th>
                      <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Fan.</th>
                      <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Ha</th>
                      <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Fan./Ha</th>
                    </tr>
                  </thead>
                  <tbody>
                    {st.data.yield_by_farm
                      .filter((y) => y.fanegas_per_ha != null || y.kg_per_ha != null)
                      .map((y) => (
                        <tr key={y.farm_id || y.farm_name} className="border-b border-stone-100 hover:bg-stone-50/80">
                          <td className="p-3 text-stone-800">{y.farm_name}</td>
                          <td className="p-3 text-right tabular-nums">{num(y.fanegas ?? y.kg, 4)}</td>
                          <td className="p-3 text-right tabular-nums">{num(y.area_ha, 2)}</td>
                          <td className="p-3 text-right font-medium tabular-nums text-lime-900">
                            {num(y.fanegas_per_ha ?? y.kg_per_ha, 4)}
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </TableWrap>
              ) : (
                <div className="rounded-xl border border-stone-200 bg-white p-6 text-sm text-stone-500 shadow-sm">
                  Sin fincas con área acumulada y producción en el periodo.
                </div>
              )}
            </div>
          </section>

          <section className="grid grid-cols-1 gap-8 lg:grid-cols-2">
            <div>
              <h2 className="mb-1 text-lg font-semibold text-stone-900">Curva de cosecha (por semana)</h2>
              <p className="mb-3 text-sm text-stone-600">Fanegas por semana civil (inicio de semana).</p>
              {st.data?.harvest_weekly_kg?.length ? (
                <div className="rounded-xl border border-stone-200 bg-white p-4 shadow-sm">
                  <HarvestBars rows={st.data.harvest_weekly_kg} />
                </div>
              ) : (
                <div className="rounded-xl border border-stone-200 bg-white p-6 text-sm text-stone-500 shadow-sm">
                  Sin datos semanales en el periodo.
                </div>
              )}
            </div>
            <div>
              <h2 className="mb-1 text-lg font-semibold text-stone-900">Curva de cosecha (por mes)</h2>
              <p className="mb-3 text-sm text-stone-600">Fanegas agrupadas por mes calendario.</p>
              {st.data?.harvest_monthly_kg?.length ? (
                <div className="rounded-xl border border-stone-200 bg-white p-4 shadow-sm">
                  <HarvestBars rows={st.data.harvest_monthly_kg} />
                </div>
              ) : (
                <div className="rounded-xl border border-stone-200 bg-white p-6 text-sm text-stone-500 shadow-sm">
                  Sin datos mensuales en el periodo.
                </div>
              )}
            </div>
          </section>
        </div>
      ) : !st.loading && !st.error ? (
        <p className="text-sm text-stone-500">No hay datos para mostrar.</p>
      ) : null}
    </StatsSectionShell>
  );
}
