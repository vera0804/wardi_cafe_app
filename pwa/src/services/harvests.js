import { apiRequest } from './api.js';

function toQuery(params) {
  const qs = new URLSearchParams();
  Object.entries(params || {}).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') qs.set(k, String(v));
  });
  const str = qs.toString();
  return str ? `?${str}` : '';
}

export function listHarvests(filters = {}) {
  return apiRequest(`/api/harvests${toQuery(filters)}`);
}

export function getHarvest(id) {
  return apiRequest(`/api/harvests/${id}`);
}

export function createHarvest(payload) {
  return apiRequest('/api/harvests', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function updateHarvest(id, payload) {
  return apiRequest(`/api/harvests/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(payload),
  });
}

export function setHarvestActive(id, isActive) {
  return apiRequest(`/api/harvests/${id}/active`, {
    method: 'PATCH',
    body: JSON.stringify({ is_active: !!isActive }),
  });
}
