import { apiRequest } from './api.js';

function toQuery(params) {
  const qs = new URLSearchParams();
  Object.entries(params || {}).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') qs.set(k, String(v));
  });
  const str = qs.toString();
  return str ? `?${str}` : '';
}

export function getLotProductionMeta() {
  return apiRequest('/api/lot-production/meta');
}

export function listLotProduction(filters = {}) {
  return apiRequest(`/api/lot-production${toQuery(filters)}`);
}

export function getLotProductionById(id) {
  return apiRequest(`/api/lot-production/${id}`);
}

export function createLotProduction(payload) {
  return apiRequest('/api/lot-production', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function createLotProductionBulk(payload) {
  return apiRequest('/api/lot-production/bulk', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function updateLotProduction(id, payload) {
  return apiRequest(`/api/lot-production/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(payload),
  });
}

export function setLotProductionActive(id, isActive) {
  return apiRequest(`/api/lot-production/${id}/active`, {
    method: 'PATCH',
    body: JSON.stringify({ is_active: !!isActive }),
  });
}
