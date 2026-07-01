import {
  createContext,
  useContext,
  useMemo,
  useState,
  useCallback,
  useEffect,
} from 'react';
import { apiRequest } from '../services/api.js';
import { syncOfflineCacheContext } from '../offline/offlineCacheScope.js';
import {
  extractLoginProfile,
  isSessionProfileComplete,
  looksLikeHtmlApiResponse,
  normalizeSessionProfile,
} from '../utils/sessionProfile.js';
import { resolveAppRole } from '../utils/userRole.js';

const AuthContext = createContext(null);

async function ensureContractFields(profile) {
  const normalized = normalizeSessionProfile(profile);
  if (!normalized || resolveAppRole(normalized) !== 'admin') {
    return normalized;
  }
  try {
    const status = await apiRequest('/api/contracts/status');
    const merged = normalizeSessionProfile({ ...normalized, ...status });
    if (merged.requiresContractAcceptance === undefined) {
      merged.requiresContractAcceptance = true;
    }
    return merged;
  } catch {
    return normalizeSessionProfile({
      ...normalized,
      requiresContractAcceptance: true,
      contractVersion: normalized.contractVersion || '1.0',
      previousContractVersion: normalized.previousContractVersion ?? null,
    });
  }
}

async function loadSessionProfile() {
  await apiRequest('/api/auth/csrf');
  const profile = await apiRequest('/api/auth/me');
  const normalized = normalizeSessionProfile(profile);
  if (!isSessionProfileComplete(normalized)) {
    const err = new Error('Perfil de sesión inválido. Vuelva a iniciar sesión.');
    err.code = 'INVALID_SESSION_PROFILE';
    throw err;
  }
  return ensureContractFields(normalized);
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    syncOfflineCacheContext(user).catch(() => {});
  }, [user]);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const profile = await loadSessionProfile();
        if (!cancelled) {
          setUser(profile);
        }
      } catch (e) {
        if (!cancelled) {
          setUser(null);
          if (e?.code === 'INVALID_SESSION_PROFILE' && typeof navigator !== 'undefined' && 'serviceWorker' in navigator) {
            try {
              const regs = await navigator.serviceWorker.getRegistrations();
              await Promise.all(regs.map((r) => r.unregister()));
            } catch {
              /* ignore */
            }
          }
        }
      } finally {
        if (!cancelled) {
          setReady(true);
        }
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const login = useCallback(async (identifier, password) => {
    await apiRequest('/api/auth/csrf');
    const profile = await apiRequest('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ identifier, password }),
    });
    if (looksLikeHtmlApiResponse(profile)) {
      const err = new Error(
        'No se pudo contactar la API (respuesta HTML). Verifique que el servidor en el puerto 3000 esté en ejecución.',
      );
      err.code = 'INVALID_SESSION_PROFILE';
      throw err;
    }
    let normalized = extractLoginProfile(profile);
    if (!isSessionProfileComplete(normalized)) {
      try {
        normalized = await loadSessionProfile();
      } catch {
        const err = new Error(
          'No se pudo obtener el perfil tras iniciar sesión. Reinicie la API (npm run dev en api/) e intente de nuevo.',
        );
        err.code = 'INVALID_SESSION_PROFILE';
        throw err;
      }
    } else {
      normalized = await ensureContractFields(normalized);
    }
    if (String(normalized?.role || '').trim().toLowerCase() === 'admin' && normalized.requiresContractAcceptance === undefined) {
      normalized = { ...normalized, requiresContractAcceptance: true };
    }
    setUser(normalized);
    return normalized;
  }, []);

  const refreshProfile = useCallback(async () => {
    const profile = await loadSessionProfile();
    setUser(profile);
    return profile;
  }, []);

  const signOut = useCallback(async () => {
    try {
      await apiRequest('/api/auth/logout', { method: 'POST' });
    } catch {
      /* ignore */
    }
    setUser(null);
  }, []);

  const value = useMemo(
    () => ({ user, setUser, login, refreshProfile, signOut, ready }),
    [user, login, refreshProfile, signOut, ready],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth debe usarse dentro de AuthProvider');
  }
  return ctx;
}
