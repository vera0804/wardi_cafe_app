/**
 * @param {{ role?: string, requiresContractAcceptance?: boolean } | null | undefined} user
 */
export function adminMustAcceptTerms(user) {
  return String(user?.role || '').toLowerCase() === 'admin' && Boolean(user?.requiresContractAcceptance);
}
