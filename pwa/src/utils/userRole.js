/**
 * Rol normalizado de la app: admin | operario | superadmin | ''.
 * Soporta API Wardi ({ role: "admin" }) y API con { user: { roleKey: "administrador" } }.
 *
 * @param {unknown} user
 * @returns {'admin'|'operario'|'superadmin'|''}
 */
export function resolveAppRole(user) {
  if (!user || typeof user !== 'object') return '';
  const p = /** @type {Record<string, unknown>} */ (user);
  const raw = p.role ?? p.roleKey ?? p.role_name ?? p.roleName;
  const r = String(raw || '').trim().toLowerCase();
  if (r === 'admin' || r === 'administrador') return 'admin';
  if (r === 'operario') return 'operario';
  if (r === 'superadmin') return 'superadmin';
  return r;
}

/**
 * @param {unknown} data
 */
export function unwrapApiProfile(data) {
  if (!data || typeof data !== 'object') return data;
  const o = /** @type {Record<string, unknown>} */ (data);
  if (o.user && typeof o.user === 'object') return o.user;
  return data;
}

/**
 * @param {unknown} user
 */
export function isTenantAdminUser(user) {
  const role = resolveAppRole(user);
  if (role === 'admin') return true;
  if (role === 'superadmin' && user && typeof user === 'object') {
    const p = /** @type {{ actingClientId?: unknown }} */ (user);
    return p.actingClientId != null && String(p.actingClientId).trim() !== '';
  }
  return false;
}
