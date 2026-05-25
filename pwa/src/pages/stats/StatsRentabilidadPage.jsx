import StatsSectionShell from './StatsSectionShell.jsx';
import StatsAccessDenied from './StatsAccessDenied.jsx';
import { useStatsOverview } from './useStatsOverview.js';
import {
  crc,
  num,
  TableWrap,
  fanegasOf,
  formatMarginPerFanega,
  marginPerFanegaCrc,
  marginToneClass,
} from './statsFormat.jsx';

function sortByMarginDesc(rows) {
  return [...rows].sort((a, b) => Number(b.margin_crc) - Number(a.margin_crc));
}

function sortByMarginPerFanegaDesc(rows) {
  return [...rows].sort((a, b) => (marginPerFanegaCrc(b) ?? -Infinity) - (marginPerFanegaCrc(a) ?? -Infinity));
}

export default function StatsRentabilidadPage() {
  const st = useStatsOverview({ includeLowStockInRequest: false });
  if (st.blocked) return <StatsAccessDenied />;

  const lots = st.data?.rentability_lots || [];
  const farms = st.data?.rentability_farms || [];
  const lotsRanked = sortByMarginDesc(lots);
  const farmsRanked = sortByMarginDesc(farms);
  const lotsByMarginPerFanega = sortByMarginPerFanegaDesc(
    lots.filter((r) => fanegasOf(r) > 0 && marginPerFanegaCrc(r) != null)
  );

  return (
    <StatsSectionShell
      title="Rentabilidad"
      description="Compara, por lote y por finca, el valor de tu café cosechado (fanegas × precio de cosecha) frente a los costos directos imputados al lote, y el margen que quedó en colones y por fanega."
      filtersProps={st.filtersProps}
      periodLine={st.periodLine}
    >
      {st.loading && !st.data ? <p className="text-sm text-stone-500">Cargando datos…</p> : null}
      {st.error ? (
        <div className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">{st.error}</div>
      ) : null}

      {st.data ? (
        <div className="space-y-10">
          <p className="rounded-lg border border-stone-200 bg-stone-50 px-4 py-3 text-sm text-stone-600">
            <strong className="text-stone-800">Ingreso</strong> = fanegas producidas × precio por fanega de la cosecha
            activa que cubre cada fecha (sin precio o sin cosecha → 0).{' '}
            <strong className="text-stone-800">Costo</strong> = gastos, labores, insumos, planilla y depreciación
            imputados al lote. <strong className="text-stone-800">Margen</strong> = ingreso − costo.
          </p>

          <section>
            <h2 className="mb-1 text-lg font-semibold text-stone-900">Costo total del lote vs producción</h2>
            <p className="mb-3 text-sm text-stone-600">
              Tabla base: producción real (cajuelas y fanegas), ingreso valorizado, costo directo y margen por lote.
            </p>
            {lots.length ? (
              <TableWrap>
                <thead className="border-b border-stone-200 bg-stone-50">
                  <tr>
                    <th className="p-3 text-left font-medium text-stone-700">Finca</th>
                    <th className="p-3 text-left font-medium text-stone-700">Lote</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Cajuelas</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Fanegas</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Ingreso</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Costo</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Margen</th>
                  </tr>
                </thead>
                <tbody>
                  {lots.map((r) => (
                    <tr key={r.lot_id} className="border-b border-stone-100 hover:bg-stone-50/80">
                      <td className="p-3 text-stone-800">{r.farm_name}</td>
                      <td className="p-3 text-stone-800">{r.lot_name}</td>
                      <td className="p-3 text-right tabular-nums">{num(r.cajuelas, 2)}</td>
                      <td className="p-3 text-right tabular-nums">{num(fanegasOf(r), 4)}</td>
                      <td className="p-3 text-right tabular-nums text-emerald-700">{crc(r.revenue_crc)}</td>
                      <td className="p-3 text-right tabular-nums text-rose-700">{crc(r.cost_crc)}</td>
                      <td className={`p-3 text-right font-medium tabular-nums ${marginToneClass(r.margin_crc)}`}>
                        {crc(r.margin_crc)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </TableWrap>
            ) : (
              <div className="rounded-xl border border-stone-200 bg-white p-8 text-center text-sm text-stone-500 shadow-sm">
                Sin filas en el periodo.
              </div>
            )}
          </section>

          <section>
            <h2 className="mb-1 text-lg font-semibold text-stone-900">Lotes más rentables (por margen CRC)</h2>
            <p className="mb-3 text-sm text-stone-600">Ordenados de mayor a menor margen (ingreso − costo directo).</p>
            {lotsRanked.length ? (
              <TableWrap>
                <thead className="border-b border-stone-200 bg-stone-50">
                  <tr>
                    <th className="p-3 text-left font-medium text-stone-700">Finca</th>
                    <th className="p-3 text-left font-medium text-stone-700">Lote</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Margen</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Margen/fanega</th>
                  </tr>
                </thead>
                <tbody>
                  {lotsRanked.map((r) => (
                    <tr key={r.lot_id} className="border-b border-stone-100 hover:bg-stone-50/80">
                      <td className="p-3 text-stone-800">{r.farm_name}</td>
                      <td className="p-3 text-stone-800">{r.lot_name}</td>
                      <td className={`p-3 text-right font-medium tabular-nums ${marginToneClass(r.margin_crc)}`}>
                        {crc(r.margin_crc)}
                      </td>
                      <td className="p-3 text-right tabular-nums text-stone-700">{formatMarginPerFanega(r)}</td>
                    </tr>
                  ))}
                </tbody>
              </TableWrap>
            ) : (
              <div className="rounded-xl border border-stone-200 bg-white p-8 text-center text-sm text-stone-500 shadow-sm">
                Sin datos de rentabilidad por lote.
              </div>
            )}
          </section>

          <section>
            <h2 className="mb-1 text-lg font-semibold text-stone-900">Fincas más rentables</h2>
            <p className="mb-3 text-sm text-stone-600">
              Suma de lotes por finca; margen/fanega = margen total de la finca ÷ fanegas totales de sus lotes.
            </p>
            {farmsRanked.length ? (
              <TableWrap>
                <thead className="border-b border-stone-200 bg-stone-50">
                  <tr>
                    <th className="p-3 text-left font-medium text-stone-700">Finca</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Fanegas</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Margen</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Margen/fanega</th>
                  </tr>
                </thead>
                <tbody>
                  {farmsRanked.map((r) => (
                    <tr key={r.farm_id || r.farm_name} className="border-b border-stone-100 hover:bg-stone-50/80">
                      <td className="p-3 text-stone-800">{r.farm_name}</td>
                      <td className="p-3 text-right tabular-nums">{num(fanegasOf(r), 4)}</td>
                      <td className={`p-3 text-right font-medium tabular-nums ${marginToneClass(r.margin_crc)}`}>
                        {crc(r.margin_crc)}
                      </td>
                      <td className="p-3 text-right tabular-nums text-stone-700">{formatMarginPerFanega(r)}</td>
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

          <section>
            <h2 className="mb-1 text-lg font-semibold text-stone-900">Margen por fanega producida (lote)</h2>
            <p className="mb-3 text-sm text-stone-600">
              Eficiencia unitaria: margen del lote ÷ fanegas producidas (solo lotes con producción en el periodo).
            </p>
            {lotsByMarginPerFanega.length ? (
              <TableWrap>
                <thead className="border-b border-stone-200 bg-stone-50">
                  <tr>
                    <th className="p-3 text-left font-medium text-stone-700">Finca</th>
                    <th className="p-3 text-left font-medium text-stone-700">Lote</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Fanegas</th>
                    <th className="p-3 text-right font-medium text-stone-700 tabular-nums">Margen/fanega</th>
                  </tr>
                </thead>
                <tbody>
                  {lotsByMarginPerFanega.map((r) => {
                    const mpf = marginPerFanegaCrc(r);
                    return (
                      <tr key={r.lot_id} className="border-b border-stone-100 hover:bg-stone-50/80">
                        <td className="p-3 text-stone-800">{r.farm_name}</td>
                        <td className="p-3 text-stone-800">{r.lot_name}</td>
                        <td className="p-3 text-right tabular-nums">{num(fanegasOf(r), 4)}</td>
                        <td className={`p-3 text-right tabular-nums font-medium ${marginToneClass(mpf)}`}>
                          {formatMarginPerFanega(r)}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </TableWrap>
            ) : (
              <div className="rounded-xl border border-stone-200 bg-white p-6 text-sm text-stone-500 shadow-sm">
                Sin fanegas producidas en el periodo para calcular margen por fanega.
              </div>
            )}
          </section>
        </div>
      ) : !st.loading && !st.error ? (
        <p className="text-sm text-stone-500">No hay datos para mostrar.</p>
      ) : null}
    </StatsSectionShell>
  );
}
