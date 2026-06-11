export default function ExpenseRegisterPlaceholder({ kind }) {
  return (
    <div className="rounded-lg border border-dashed border-slate-200 bg-slate-50/80 px-4 py-8 text-center text-sm text-slate-600">
      {kind === 'lote' ? (
        <p>Complete el gasto por finca en la ventana emergente. Si la cerró sin guardar, elija de nuevo esta pestaña o Historial.</p>
      ) : (
        <p>Complete el gasto por empresa en la ventana emergente. Si la cerró sin guardar, elija de nuevo esta pestaña o Historial.</p>
      )}
    </div>
  );
}
