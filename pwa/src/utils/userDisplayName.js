/**
 * Nombre visible del usuario en la interfaz (cabecera, pie de sesión).
 */
export function getUserDisplayName(user) {
  if (!user) return '';
  const full = String(user.fullName || '').trim();
  if (full) return full;
  const first = String(user.firstName || '').trim();
  const last = String(user.lastName || '').trim();
  const combined = [first, last].filter(Boolean).join(' ').trim();
  if (combined) return combined;
  return String(user.email || '').trim();
}
