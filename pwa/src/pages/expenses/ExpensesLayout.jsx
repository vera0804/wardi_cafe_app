import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../auth/AuthContext.jsx';
import DashboardShell from '../../layouts/DashboardShell.jsx';
import { DASHBOARD_MENU_STORAGE_KEY } from '../../layouts/dashboardMenuData.js';
import BccrUsdReference from '../../shared/BccrUsdReference.jsx';

export default function ExpensesLayout() {
  const { user, signOut } = useAuth();
  const navigate = useNavigate();
  const path = useLocation().pathname;
  const isGeneralDetail = /^\/expenses\/general\/[^/]+$/.test(path);

  async function handleLogout() {
    await signOut();
    navigate('/login', { replace: true });
  }

  function onMenuItemClick(label) {
    if (label === 'Activos') {
      navigate('/admin/assets');
      return;
    }
    if (label === 'Gastos') {
      navigate('/expenses/historial');
      return;
    }
    try {
      sessionStorage.setItem(DASHBOARD_MENU_STORAGE_KEY, label);
    } catch {
      /* ignore */
    }
    navigate('/dashboard');
  }

  return (
    <DashboardShell
      user={user}
      highlightedMenu="Gastos"
      onMenuItemClick={onMenuItemClick}
      onLogout={handleLogout}
      mainClassName="min-h-[calc(100vh-53px)] bg-slate-100 p-6"
    >
      <section className="space-y-4 rounded-2xl border border-white/50 bg-white/90 p-5 text-slate-800 shadow">
        <header className="flex flex-col gap-3 border-b border-slate-200 pb-4 sm:flex-row sm:items-start sm:justify-between">
          <div className="min-w-0 flex-1">
            <h2 className="text-lg font-semibold text-lime-800">Gastos</h2>
            <p className="mt-1 text-sm text-slate-600">
              {isGeneralDetail
                ? 'Detalle del gasto por empresa y reparto entre fincas. Use «Volver» para regresar al historial.'
                : 'Registre gastos por finca o por empresa, y consulte el historial desde las pestañas.'}
            </p>
          </div>
          <BccrUsdReference className="shrink-0 sm:mt-0.5" />
        </header>
        <Outlet />
      </section>
    </DashboardShell>
  );
}
