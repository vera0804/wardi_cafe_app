import { useMemo, useState } from 'react';
import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import { ExpenseRegisterGeneralModal, ExpenseRegisterLotModal } from './ExpenseRegisterModals.jsx';

const TAB_GUIDE = {
  historial: {
    title: 'Historial de gastos',
    body: 'Aquí consulta lo registrado: gastos que fueron a una finca en particular y gastos de empresa repartidos entre fincas. Use las pestañas de arriba para registrar uno nuevo.',
  },
  'reg-lote': {
    title: '¿Qué es un gasto por finca?',
    body: (
      <>
        Use esta opción cuando el gasto corresponde a <strong className="font-medium text-slate-800">una sola finca</strong>{' '}
        (por ejemplo mantenimiento de una finca, compra de insumo aplicado solo ahí o un pago puntual de esa finca). El{' '}
        <strong className="font-medium text-slate-800">monto completo</strong> queda imputado a la finca que elija.
      </>
    ),
  },
  'reg-gen': {
    title: '¿Qué es un gasto por empresa?',
    body: (
      <>
        Use esta opción para gastos de <strong className="font-medium text-slate-800">toda la empresa</strong> (administración,
        servicios generales, planilla compartida, etc.). El monto se{' '}
        <strong className="font-medium text-slate-800">reparte entre las fincas</strong> según el método configurado en
        Empresa: por hectáreas o asignación manual en el detalle del gasto.
      </>
    ),
  },
};

function TabGuide({ tabId }) {
  const guide = TAB_GUIDE[tabId];
  if (!guide) return null;
  return (
    <div className="mt-4 rounded-xl border border-lime-200/80 bg-lime-50/70 px-4 py-3 text-sm leading-relaxed text-slate-700">
      <p className="font-semibold text-lime-900">{guide.title}</p>
      <p className="mt-1">{guide.body}</p>
    </div>
  );
}

export default function ExpensesWorkspace() {
  const location = useLocation();
  const navigate = useNavigate();
  const [listBump, setListBump] = useState(0);

  const path = location.pathname;
  const tab = useMemo(() => {
    if (path.includes('/registro/lote')) return 'reg-lote';
    if (path.includes('/registro/general')) return 'reg-gen';
    return 'historial';
  }, [path]);

  const lotModalOpen = path.includes('/registro/lote');
  const genModalOpen = path.includes('/registro/general');

  function goHistorial() {
    navigate('/expenses/historial');
  }

  const tabs = [
    { id: 'historial', label: 'Historial', to: '/expenses/historial' },
    { id: 'reg-lote', label: 'Gasto por finca', to: '/expenses/registro/lote' },
    { id: 'reg-gen', label: 'Gasto por empresa', to: '/expenses/registro/general' },
  ];

  return (
    <>
      <div className="flex flex-wrap gap-2 rounded-xl border border-slate-200 bg-slate-50 p-2">
        {tabs.map((t) => (
          <button
            key={t.id}
            type="button"
            onClick={() => navigate(t.to)}
            className={`rounded-lg px-3 py-2 text-sm font-semibold transition ${
              tab === t.id ? 'bg-lime-700 text-white' : 'bg-white text-slate-700 hover:bg-lime-50'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      <TabGuide tabId={tab} />

      <div className="mt-4">
        <Outlet context={{ listBump, bumpLists: () => setListBump((n) => n + 1) }} />
      </div>

      <ExpenseRegisterLotModal
        open={lotModalOpen}
        onClose={goHistorial}
        onSaved={() => setListBump((n) => n + 1)}
      />
      <ExpenseRegisterGeneralModal
        open={genModalOpen}
        onClose={goHistorial}
        onSaved={() => setListBump((n) => n + 1)}
      />
    </>
  );
}
