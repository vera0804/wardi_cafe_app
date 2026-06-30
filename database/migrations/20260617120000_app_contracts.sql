-- Aceptación de términos y condiciones por organización (cliente).
-- Una fila activa por cliente desbloquea el panel para todos sus administradores.

CREATE TABLE IF NOT EXISTS public.app_contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL REFERENCES public.clients(id) ON DELETE CASCADE,
  version character varying(20) NOT NULL,
  accepted_at timestamptz NOT NULL DEFAULT now(),
  accepted_by uuid NOT NULL REFERENCES public.users(id),
  is_active boolean NOT NULL DEFAULT true
);

COMMENT ON TABLE public.app_contracts IS
  'Registro de aceptación de términos por organización; no almacena el texto legal.';
COMMENT ON COLUMN public.app_contracts.version IS
  'Versión del acuerdo aceptado (p. ej. 1.0), alineada con APP_CONTRACT_VERSION.';
COMMENT ON COLUMN public.app_contracts.is_active IS
  'Solo una aceptación activa por cliente; al re-aceptar se desactivan las demás.';

CREATE UNIQUE INDEX IF NOT EXISTS app_contracts_client_version_uidx
  ON public.app_contracts (client_id, version);

CREATE INDEX IF NOT EXISTS app_contracts_client_active_idx
  ON public.app_contracts (client_id)
  WHERE is_active = true;
