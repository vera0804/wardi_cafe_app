import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext.jsx';
import { acceptContract } from '../services/contractsApi.js';
import { adminMustAcceptTerms } from '../utils/contractGate.js';

const TERMS_SECTIONS = [
  {
    title: '1. Compromiso de confidencialidad y privacidad',
    subtitle: 'Tus datos son tuyos',
    paragraphs: [
      'Nos comprometemos a proteger la privacidad de tu finca. Toda la información específica que ingreses en la plataforma —incluyendo nombres, ubicaciones exactas de parcelas, registros financieros, nombres de trabajadores y planes de manejo— será tratada como estrictamente confidencial.',
      'No vendemos ni alquilamos datos: nunca comercializaremos ni revelaremos la información personal o comercial de tu finca a terceros (proveedores, competidores u otros actores del sector) sin tu autorización expresa.',
      'Seguridad: implementamos medidas técnicas y organizativas para que solo tú y los usuarios que autorices puedan acceder a la gestión de tu finca.',
    ],
  },
  {
    title: '2. Autorización para datos anónimos y agregados',
    subtitle: 'Inteligencia colectiva del sector',
    paragraphs: [
      'Al aceptar estos términos, autorizas a la plataforma a utilizar la información operativa y técnica de tu finca únicamente bajo los principios de anonimización y agregación.',
    ],
    bullets: [
      'Datos anónimos: se elimina cualquier rastro que permita identificarte a ti, a tu finca o a tu empresa.',
      'Datos agregados: tu información se combina con la de otros productores en conjuntos estadísticos que no permiten identificar a ningún participante.',
    ],
    footer:
      'Usaremos estos datos agregados para generar reportes estadísticos, tendencias de mercado y estudios del sector cafetalero: insumos más utilizados por zona y época, calendarios de labores frecuentes, proyecciones y alertas tempranas de manejo fitosanitario, entre otros.',
  },
  {
    title: '3. Propiedad intelectual de los reportes',
    paragraphs: [
      'Los datos crudos de tu finca te pertenecen. Sin embargo, los reportes globales, estadísticas, macrodatos y análisis resultantes de la agregación de datos de todos los usuarios serán propiedad exclusiva de la plataforma.',
    ],
  },
  {
    title: '4. Revocación del consentimiento',
    paragraphs: [
      'Puedes dejar de usar la plataforma en cualquier momento. Si solicitas el cierre de tu cuenta, tus datos personales e históricos individuales serán inactivados en nuestros servidores activos.',
      'Los datos operativos que ya hayan sido anonimizados e incorporados a reportes estadísticos históricos no podrán separarse ni eliminarse de forma individual, porque ya no guardan vínculo con tu identidad.',
    ],
  },
];

export default function ContractTermsPage() {
  const { user, ready, refreshProfile, signOut } = useAuth();
  const navigate = useNavigate();
  const [accepted, setAccepted] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!ready) return;
    if (!user) {
      navigate('/login', { replace: true });
      return;
    }
    if (!adminMustAcceptTerms(user)) {
      navigate('/dashboard', { replace: true });
    }
  }, [ready, user, navigate]);

  async function handleLogout() {
    await signOut();
    navigate('/login', { replace: true });
  }

  async function handleContinue(e) {
    e.preventDefault();
    if (!accepted) {
      setError('Debes marcar la casilla para continuar.');
      return;
    }
    setError('');
    setLoading(true);
    try {
      const version = user?.contractVersion || '1.0';
      await acceptContract(version);
      await refreshProfile();
      navigate('/dashboard', { replace: true });
    } catch (err) {
      setError(err?.message || 'No se pudo registrar la aceptación. Intenta de nuevo.');
    } finally {
      setLoading(false);
    }
  }

  if (!ready || !user || !adminMustAcceptTerms(user)) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-lime-50 text-sm text-lime-900">
        Cargando…
      </div>
    );
  }

  const versionLabel = user.contractVersion || '1.0';

  return (
    <div className="min-h-screen bg-gradient-to-b from-lime-50 via-amber-50/30 to-lime-100/80">
      <header className="border-b border-lime-200/80 bg-white/90 px-4 py-4 shadow-sm">
        <div className="mx-auto flex max-w-3xl items-center justify-between gap-4">
          <div className="flex min-w-0 items-center gap-3">
            <img src="/images/logo.png" alt="Wardi" className="h-10 w-auto shrink-0 object-contain" />
            <div className="min-w-0">
              <p className="truncate text-sm font-semibold text-lime-950">Términos y condiciones</p>
              <p className="truncate text-xs text-lime-800/80">Versión {versionLabel}</p>
            </div>
          </div>
          <button
            type="button"
            onClick={handleLogout}
            className="shrink-0 text-sm font-medium text-lime-800 underline decoration-lime-300 underline-offset-2 hover:text-lime-950"
          >
            Cerrar sesión
          </button>
        </div>
      </header>

      <main className="mx-auto max-w-3xl px-4 py-8">
        <div className="rounded-2xl border border-lime-200/80 bg-white/95 p-6 shadow-md shadow-lime-900/5 sm:p-8">
          <h1 className="text-xl font-semibold text-lime-950">Antes de continuar</h1>
          {user.previousContractVersion ? (
            <p className="mt-2 rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-sm leading-relaxed text-amber-950">
              Se publicó una nueva versión de los términos (v{versionLabel}). La organización había aceptado
              la versión {user.previousContractVersion}; debe aceptar la versión actual para volver a usar el
              panel.
            </p>
          ) : (
            <p className="mt-2 text-sm leading-relaxed text-lime-900/85">
              Como administrador de la organización, debes aceptar los siguientes términos para habilitar el
              panel de gestión. La aceptación queda registrada para toda la organización; otros administradores
              podrán ingresar sin repetir este paso.
            </p>
          )}

          <div className="mt-8 space-y-8">
            {TERMS_SECTIONS.map((section) => (
              <section key={section.title} className="space-y-3">
                <div>
                  <h2 className="text-base font-semibold text-lime-900">{section.title}</h2>
                  {section.subtitle ? (
                    <p className="mt-0.5 text-sm font-medium text-lime-800/90">{section.subtitle}</p>
                  ) : null}
                </div>
                {section.paragraphs?.map((p) => (
                  <p key={p} className="text-sm leading-relaxed text-slate-700">
                    {p}
                  </p>
                ))}
                {section.bullets ? (
                  <ul className="list-disc space-y-2 pl-5 text-sm leading-relaxed text-slate-700">
                    {section.bullets.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                ) : null}
                {section.footer ? (
                  <p className="text-sm leading-relaxed text-slate-700">{section.footer}</p>
                ) : null}
              </section>
            ))}
          </div>

          <form className="mt-10 space-y-4 border-t border-lime-100 pt-6" onSubmit={handleContinue}>
            <label className="flex cursor-pointer items-start gap-3 text-sm text-slate-800">
              <input
                type="checkbox"
                checked={accepted}
                onChange={(e) => {
                  setAccepted(e.target.checked);
                  if (e.target.checked) setError('');
                }}
                className="mt-0.5 shrink-0"
              />
              <span>
                He leído y acepto los términos y condiciones (versión {versionLabel}) en nombre de la
                organización.
              </span>
            </label>

            {error ? (
              <p role="alert" className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800">
                {error}
              </p>
            ) : null}

            <button
              type="submit"
              disabled={loading || !accepted}
              className="w-full rounded-lg bg-lime-700 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition enabled:hover:bg-lime-800 disabled:cursor-not-allowed disabled:opacity-60 sm:w-auto sm:min-w-[12rem]"
            >
              {loading ? 'Registrando…' : 'Continuar al panel'}
            </button>
          </form>
        </div>
      </main>
    </div>
  );
}
