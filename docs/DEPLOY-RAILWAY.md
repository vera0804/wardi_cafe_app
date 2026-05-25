# Despliegue en Railway (un solo servicio)

## Arquitectura

Un proceso Node (Express) en el puerto que Railway asigna (`PORT`):

| Ruta | Qué sirve |
|------|-----------|
| `/api/*` | API JSON (sesión, negocio) |
| Resto (`/login`, `/dashboard`, …) | SPA React (`api/public`, copia de `pwa/dist`) |

El navegador usa **un solo origen**; las peticiones van a rutas relativas `/api/...` (sin segundo dominio ni CORS cruzado si las variables de origen coinciden).

## Build y start en Railway

| Campo | Valor |
|-------|--------|
| **Build Command** | `npm run build` |
| **Start Command** | `npm start` |
| **Root Directory** | raíz del repo (donde está este `package.json`) |

### Qué hace `npm run build`

1. `npm run install:all` — dependencias de `api/` y `pwa/`
2. `npm run build --prefix pwa` — `vite build` → `pwa/dist`
3. `node scripts/copy-pwa.js` — copia `pwa/dist` → `api/public`

### Qué hace `npm start`

Ejecuta `node api/src/index.js` (Express con API + estáticos si existe `api/public`).

## Desarrollo local (dos procesos)

```bash
# Terminal 1
npm run dev:api

# Terminal 2
npm run dev:pwa
```

Vite en `:5173` hace proxy de `/api` → `http://localhost:3000`.

## Variables de entorno (Railway)

| Variable | Uso |
|----------|-----|
| `DATABASE_URL` | PostgreSQL (obligatoria) |
| `NODE_ENV` | `production` |
| `PORT` | Lo inyecta Railway (no fijar a mano) |
| `TRUST_PROXY` | `1` (recomendado detrás del proxy Railway) |
| `CORS_ORIGIN` | URL pública exacta, ej. `https://tu-app.up.railway.app` |
| `FRONTEND_URL` | La misma URL (enlaces de recuperación de contraseña) |

Opcional en build de la PWA (ya funciona sin ella si las rutas del cliente son `/api/...`):

- `VITE_API_URL` — déjela vacía o no la defina; el cliente usa rutas relativas `/api/...`.

## Comprobar en local como producción

```bash
npm run build
cd api
set NODE_ENV=production
npm start
```

Abrir `http://localhost:3000` (SPA) y `http://localhost:3000/api/health` (`{"ok":true}`).

## Problemas frecuentes

| Síntoma | Causa |
|---------|--------|
| `ECONNREFUSED` en dev con solo `npm run dev` en `pwa/` | Falta `npm run dev:api` en otra terminal |
| 404 al refrescar `/dashboard` en Railway sin build | No se ejecutó `npm run build` o falta `api/public` |
| Login / cookies fallan | `CORS_ORIGIN` distinto de la URL pública, o `TRUST_PROXY` sin activar |
