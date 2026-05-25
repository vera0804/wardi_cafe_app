-- RLS: producción de café (client_id directo) y tablas hijas de planilla sin client_id.
-- Requiere app.tenant_id (SET LOCAL) por request; coherente con requireEffectiveClient en la API.
-- payroll_periods / payroll_settings: calendario y parámetros globales (sin client_id) — fuera de este parche.

-- Función de sesión tenant (idempotente si ya existe por dump u otra migración).
CREATE OR REPLACE FUNCTION public.app_current_tenant_id() RETURNS uuid
    LANGUAGE plpgsql STABLE
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  raw text;
BEGIN
  BEGIN
    raw := current_setting('app.tenant_id', true);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  IF raw IS NULL THEN
    RETURN NULL;
  END IF;

  raw := btrim(raw);
  IF raw = '' THEN
    RETURN NULL;
  END IF;

  BEGIN
    RETURN raw::uuid;
  EXCEPTION
    WHEN invalid_text_representation THEN
      RETURN NULL;
  END;
END;
$$;

COMMENT ON FUNCTION public.app_current_tenant_id() IS
  'Lee el tenant actual desde GUC app.tenant_id (SET LOCAL dentro de cada transacción).';

-- ---------------------------------------------------------------------------
-- coffee_lot_production (columna client_id UUID)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'coffee_lot_production'
  ) THEN
    EXECUTE 'ALTER TABLE public.coffee_lot_production ENABLE ROW LEVEL SECURITY';
    EXECUTE 'ALTER TABLE public.coffee_lot_production FORCE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS wardi_tenant_isolation ON public.coffee_lot_production';
    EXECUTE $p$
      CREATE POLICY wardi_tenant_isolation ON public.coffee_lot_production
        USING (
          client_id IS NOT NULL
          AND public.app_current_tenant_id() IS NOT NULL
          AND client_id = public.app_current_tenant_id()
        )
        WITH CHECK (
          client_id IS NOT NULL
          AND public.app_current_tenant_id() IS NOT NULL
          AND client_id = public.app_current_tenant_id()
        )
    $p$;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- fixed_payroll → workers.client_id
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'fixed_payroll'
  ) THEN
    EXECUTE 'ALTER TABLE public.fixed_payroll ENABLE ROW LEVEL SECURITY';
    EXECUTE 'ALTER TABLE public.fixed_payroll FORCE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS wardi_tenant_via_worker ON public.fixed_payroll';
    EXECUTE $p$
      CREATE POLICY wardi_tenant_via_worker ON public.fixed_payroll
        USING (
          public.app_current_tenant_id() IS NOT NULL
          AND EXISTS (
            SELECT 1
            FROM public.workers w
            WHERE w.id = fixed_payroll.worker_id
              AND w.client_id = public.app_current_tenant_id()
          )
        )
        WITH CHECK (
          public.app_current_tenant_id() IS NOT NULL
          AND EXISTS (
            SELECT 1
            FROM public.workers w
            WHERE w.id = worker_id
              AND w.client_id = public.app_current_tenant_id()
          )
        )
    $p$;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- fixed_payroll_allocations → fixed_payroll + workers + lots
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'fixed_payroll_allocations'
  ) THEN
    EXECUTE 'ALTER TABLE public.fixed_payroll_allocations ENABLE ROW LEVEL SECURITY';
    EXECUTE 'ALTER TABLE public.fixed_payroll_allocations FORCE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS wardi_tenant_fixed_payroll_alloc ON public.fixed_payroll_allocations';
    EXECUTE $p$
      CREATE POLICY wardi_tenant_fixed_payroll_alloc ON public.fixed_payroll_allocations
        USING (
          public.app_current_tenant_id() IS NOT NULL
          AND EXISTS (
            SELECT 1
            FROM public.fixed_payroll fp
            INNER JOIN public.workers w ON w.id = fp.worker_id
            WHERE fp.id = fixed_payroll_allocations.fixed_payroll_id
              AND w.client_id = public.app_current_tenant_id()
          )
          AND EXISTS (
            SELECT 1
            FROM public.lots l
            WHERE l.id = fixed_payroll_allocations.lot_id
              AND l.client_id = public.app_current_tenant_id()
          )
        )
        WITH CHECK (
          public.app_current_tenant_id() IS NOT NULL
          AND EXISTS (
            SELECT 1
            FROM public.fixed_payroll fp
            INNER JOIN public.workers w ON w.id = fp.worker_id
            WHERE fp.id = fixed_payroll_id
              AND w.client_id = public.app_current_tenant_id()
          )
          AND EXISTS (
            SELECT 1
            FROM public.lots l
            WHERE l.id = lot_id
              AND l.client_id = public.app_current_tenant_id()
          )
        )
    $p$;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- payroll_slip_lot_allocations → payroll_slips.client_id + lots
-- (payroll_slips ya tiene wardi_tenant_isolation si aplicó la migración dinámica)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'payroll_slip_lot_allocations'
  ) THEN
    EXECUTE 'ALTER TABLE public.payroll_slip_lot_allocations ENABLE ROW LEVEL SECURITY';
    EXECUTE 'ALTER TABLE public.payroll_slip_lot_allocations FORCE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS wardi_tenant_payroll_slip_lot_alloc ON public.payroll_slip_lot_allocations';
    EXECUTE $p$
      CREATE POLICY wardi_tenant_payroll_slip_lot_alloc ON public.payroll_slip_lot_allocations
        USING (
          public.app_current_tenant_id() IS NOT NULL
          AND EXISTS (
            SELECT 1
            FROM public.payroll_slips ps
            WHERE ps.id = payroll_slip_lot_allocations.payroll_slip_id
              AND ps.client_id = public.app_current_tenant_id()
          )
          AND EXISTS (
            SELECT 1
            FROM public.lots l
            WHERE l.id = payroll_slip_lot_allocations.lot_id
              AND l.client_id = public.app_current_tenant_id()
          )
        )
        WITH CHECK (
          public.app_current_tenant_id() IS NOT NULL
          AND EXISTS (
            SELECT 1
            FROM public.payroll_slips ps
            WHERE ps.id = payroll_slip_id
              AND ps.client_id = public.app_current_tenant_id()
          )
          AND EXISTS (
            SELECT 1
            FROM public.lots l
            WHERE l.id = lot_id
              AND l.client_id = public.app_current_tenant_id()
          )
        )
    $p$;
  END IF;
END $$;
