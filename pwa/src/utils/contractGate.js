import { resolveAppRole } from './userRole.js';

/**
 * Administrador debe aceptar términos salvo que la API indique explícitamente lo contrario.
 *
 * @param {{ role?: string, roleKey?: string, requiresContractAcceptance?: boolean } | null | undefined} user
 */
export function adminMustAcceptTerms(user) {
  if (resolveAppRole(user) !== 'admin') return false;
  return user?.requiresContractAcceptance !== false;
}
