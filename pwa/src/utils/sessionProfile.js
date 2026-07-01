import { resolveAppRole, unwrapApiProfile } from './userRole.js';

/**
 * @param {unknown} user
 */
export function normalizeSessionProfile(user) {
  const raw = unwrapApiProfile(user);
  if (!raw || typeof raw !== 'object') return null;
  const p = /** @type {Record<string, unknown>} */ (raw);
  const id = p.id != null ? String(p.id).trim() : '';
  const email = p.email != null ? String(p.email).trim() : '';
  const role = resolveAppRole(p);
  const fullName = p.fullName != null ? String(p.fullName).trim() : '';
  let firstName = p.firstName != null ? String(p.firstName).trim() : '';
  let lastName = p.lastName != null ? String(p.lastName).trim() : '';
  if (fullName && !firstName && !lastName) {
    const parts = fullName.split(/\s+/).filter(Boolean);
    firstName = parts[0] || '';
    lastName = parts.slice(1).join(' ');
  }
  return {
    ...p,
    id,
    email,
    role,
    roleKey: p.roleKey ?? p.role ?? role,
    fullName: fullName || [firstName, lastName].filter(Boolean).join(' ').trim(),
    clientId: p.clientId ?? p.client_id ?? null,
    clientName: p.clientName ?? p.client_name ?? null,
    firstName,
    lastName,
    requiresContractAcceptance:
      typeof p.requiresContractAcceptance === 'boolean' ? p.requiresContractAcceptance : undefined,
    contractVersion: p.contractVersion != null ? String(p.contractVersion) : undefined,
    previousContractVersion:
      p.previousContractVersion != null ? String(p.previousContractVersion) : null,
  };
}

/**
 * @param {unknown} data
 */
export function extractLoginProfile(data) {
  const normalized = normalizeSessionProfile(data);
  if (isSessionProfileComplete(normalized)) return normalized;
  return normalized;
}

/**
 * @param {unknown} data
 */
export function looksLikeHtmlApiResponse(data) {
  const msg =
    data && typeof data === 'object' ? String(/** @type {{ message?: string }} */ (data).message || '') : '';
  return msg.includes('<!DOCTYPE') || msg.includes('<html');
}

/**
 * @param {unknown} user
 */
export function isSessionProfileComplete(user) {
  const p = normalizeSessionProfile(user);
  return Boolean(p?.id && p?.email && resolveAppRole(p));
}
