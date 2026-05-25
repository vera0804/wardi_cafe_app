import { apiRequest } from './api.js';

function toQuery(params) {
  const qs = new URLSearchParams();
  Object.entries(params || {}).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') qs.set(k, String(v));
  });
  const str = qs.toString();
  return str ? `?${str}` : '';
}

export function getHarvestEstimatesMeta() {
  return apiRequest('/api/harvest-estimates/meta');
}

export function listHarvestEstimates(harvestId) {
  return apiRequest(`/api/harvest-estimates${toQuery({ harvest_id: harvestId })}`);
}

export function upsertHarvestEstimateLot(payload) {
  return apiRequest('/api/harvest-estimates/lot', {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
}
