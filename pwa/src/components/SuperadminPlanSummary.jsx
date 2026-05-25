/** Resumen de un plan para formularios superadmin (alta de org o detalle). */
export default function SuperadminPlanSummary({ plan }) {
  if (!plan) return null;
  return (
    <div className="mt-2 rounded-lg border border-lime-200 bg-lime-50/80 p-3 text-xs text-slate-700">
      <div className="font-semibold text-lime-900">{plan.name}</div>
      {plan.description ? <p className="mt-1 text-slate-600">{plan.description}</p> : null}
      <ul className="mt-2 list-inside list-disc space-y-0.5">
        <li>Modelo: {plan.billing_model_label || plan.billing_model}</li>
        {plan.billing_model === 'trial_days' && plan.trial_days != null ? (
          <li>Duración demo: {plan.trial_days} días desde alta o renovación</li>
        ) : null}
        {plan.billing_model === 'monthly_anchor' ? (
          <li>Vence el mismo día del mes siguiente al pago / renovación</li>
        ) : null}
        <li>
          Límites: {plan.max_farms} finca(s), {plan.max_lots_per_farm} lote(s)/finca,{' '}
          {plan.max_users_admin} admin(s), {plan.max_users_operario} operario(s)
        </li>
        <li>Precio referencia: ₡{Number(plan.price || 0).toLocaleString('es-CR')}</li>
      </ul>
    </div>
  );
}
