import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext.jsx';

export default function SuperadminLayout({ children }) {
  const { user } = useAuth();
  const navigate = useNavigate();

  const tabClass = ({ isActive }) =>
    `rounded-lg px-4 py-2 text-sm font-medium transition ${
      isActive
        ? 'bg-lime-700 text-white'
        : 'border border-slate-300 bg-white text-slate-700 hover:bg-slate-50'
    }`;

  return (
    <div className="min-h-screen bg-slate-100 p-6 text-slate-900">
      <div className="mx-auto max-w-5xl space-y-6">
        <header className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <h1 className="text-xl font-semibold text-lime-900">Plataforma Wardi</h1>
            <p className="mt-1 text-sm text-slate-600">Gestión de organizaciones y catálogo de planes.</p>
          </div>
          {user && !user.needsTenantSelection ? (
            <button
              type="button"
              className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-800 hover:bg-slate-50"
              onClick={() => navigate('/dashboard', { replace: true })}
            >
              Ir al panel principal
            </button>
          ) : null}
        </header>

        <nav className="flex flex-wrap gap-2" aria-label="Secciones plataforma">
          <NavLink to="/superadmin/clients" className={tabClass}>
            Organizaciones
          </NavLink>
          <NavLink to="/superadmin/plans" className={tabClass}>
            Planes
          </NavLink>
        </nav>

        {children}
      </div>
    </div>
  );
}
