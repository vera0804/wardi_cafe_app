-- Modelo Empresa (farms ×1) + Fincas operativas (lots ×N con ubicación).
-- Fusión: un cliente = una finca activa (empresa).

-- ---------------------------------------------------------------------------
-- farms: datos del dueño / empresa
-- ---------------------------------------------------------------------------
ALTER TABLE public.farms
  ADD COLUMN IF NOT EXISTS owner_name text,
  ADD COLUMN IF NOT EXISTS owner_id_type public.id_type,
  ADD COLUMN IF NOT EXISTS owner_id_number text,
  ADD COLUMN IF NOT EXISTS legal_name text,
  ADD COLUMN IF NOT EXISTS legal_id_number text,
  ADD COLUMN IF NOT EXISTS phone text,
  ADD COLUMN IF NOT EXISTS address text,
  ADD COLUMN IF NOT EXISTS area_ha_manual boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.farms.owner_name IS 'Nombre del dueño o representante de la empresa cafetalera.';
COMMENT ON COLUMN public.farms.legal_name IS 'Razón social (opcional).';
COMMENT ON COLUMN public.farms.legal_id_number IS 'Cédula jurídica (opcional).';
COMMENT ON COLUMN public.farms.address IS 'Dirección de persona u oficina (texto libre, opcional).';
COMMENT ON COLUMN public.farms.area_ha_manual IS 'true = area_ha editada manualmente; false = puede autosumar desde lots.';

-- ---------------------------------------------------------------------------
-- lots: ubicación por finca operativa
-- ---------------------------------------------------------------------------
ALTER TABLE public.lots
  ADD COLUMN IF NOT EXISTS province_id integer REFERENCES public.provinces(id),
  ADD COLUMN IF NOT EXISTS canton_id integer REFERENCES public.cantons(id),
  ADD COLUMN IF NOT EXISTS district_id integer REFERENCES public.districts(id),
  ADD COLUMN IF NOT EXISTS community text;

COMMENT ON COLUMN public.lots.province_id IS 'Provincia de la finca operativa (obligatoria en la aplicación).';

-- ---------------------------------------------------------------------------
-- Clientes sin finca: crear empresa con nombre del cliente
-- ---------------------------------------------------------------------------
INSERT INTO public.farms (name, client_id, labor_allocation_mode, area_ha_manual, is_active)
SELECT c.name, c.id, 'manual', false, true
FROM public.clients c
WHERE NOT EXISTS (
  SELECT 1 FROM public.farms f WHERE f.client_id = c.id AND f.is_active = true
);

-- ---------------------------------------------------------------------------
-- Fusionar múltiples fincas activas por cliente → conservar la más antigua
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  r RECORD;
  canonical_id uuid;
BEGIN
  FOR r IN
    SELECT client_id
    FROM public.farms
    WHERE is_active = true
    GROUP BY client_id
    HAVING COUNT(*) > 1
  LOOP
    SELECT id INTO canonical_id
    FROM public.farms
    WHERE client_id = r.client_id AND is_active = true
    ORDER BY created_at ASC, id ASC
    LIMIT 1;

    UPDATE public.lots
    SET farm_id = canonical_id, updated_at = NOW()
    WHERE farm_id IN (
      SELECT id FROM public.farms
      WHERE client_id = r.client_id AND is_active = true AND id <> canonical_id
    );

    UPDATE public.calendar_activities
    SET farm_id = canonical_id, updated_at = NOW()
    WHERE farm_id IN (
      SELECT id FROM public.farms
      WHERE client_id = r.client_id AND is_active = true AND id <> canonical_id
    );

    UPDATE public.general_expenses
    SET farm_id = canonical_id, updated_at = NOW()
    WHERE farm_id IN (
      SELECT id FROM public.farms
      WHERE client_id = r.client_id AND is_active = true AND id <> canonical_id
    );

    UPDATE public.farms
    SET is_active = false, deactivated_at = NOW(), updated_at = NOW()
    WHERE client_id = r.client_id AND is_active = true AND id <> canonical_id;
  END LOOP;
END $$;

-- Copiar ubicación de finca → lotes sin provincia (desde finca origen antes de fusión o canónica)
UPDATE public.lots l
SET
  province_id = COALESCE(l.province_id, f.province_id),
  canton_id = COALESCE(l.canton_id, f.canton_id),
  district_id = COALESCE(l.district_id, f.district_id),
  community = COALESCE(NULLIF(trim(l.community), ''), NULLIF(trim(f.community), '')),
  updated_at = NOW()
FROM public.farms f
WHERE l.farm_id = f.id
  AND l.province_id IS NULL
  AND f.province_id IS NOT NULL;

-- Sincronizar nombre empresa con cliente si está vacío o genérico
UPDATE public.farms f
SET name = c.name, updated_at = NOW()
FROM public.clients c
WHERE f.client_id = c.id
  AND f.is_active = true
  AND (f.name IS NULL OR trim(f.name) = '');

-- Planes: una empresa por cliente
UPDATE public.plans SET max_farms = 1 WHERE max_farms IS NULL OR max_farms > 1;
