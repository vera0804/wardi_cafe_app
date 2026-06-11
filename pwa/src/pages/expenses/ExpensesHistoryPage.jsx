import { useOutletContext } from 'react-router-dom';
import LotExpensesPage from './LotExpensesPage.jsx';
import GeneralExpensesPage from './GeneralExpensesPage.jsx';

export default function ExpensesHistoryPage() {
  const { listBump = 0 } = useOutletContext() || {};

  return (
    <div className="space-y-10">
      <section className="space-y-3">
        <h3 className="text-sm font-semibold uppercase tracking-wide text-slate-500">Gastos por finca</h3>
        <LotExpensesPage embedded refreshKey={listBump} />
      </section>
      <section className="space-y-3">
        <h3 className="text-sm font-semibold uppercase tracking-wide text-slate-500">Gastos por empresa</h3>
        <GeneralExpensesPage embedded refreshKey={listBump} />
      </section>
    </div>
  );
}
