/** Etiqueta de ubicación en listados (finca operativa = lot; histórico por empresa = farm). */
export function operationalLocationLabel(row) {
  if (!row) return '—';
  if (row.cost_scope === 'farm') {
    return row.farm_name ? `${row.farm_name} (hist.)` : 'Empresa (hist.)';
  }
  return row.lot_name || row.scope_name || '—';
}

/** Filtro opcional de registros históricos por empresa. */
export function matchesRecordTypeFilter(row, recordType) {
  if (!recordType) return true;
  if (recordType === 'lot') return row.cost_scope !== 'farm';
  if (recordType === 'legacy_empresa') return row.cost_scope === 'farm';
  return true;
}
