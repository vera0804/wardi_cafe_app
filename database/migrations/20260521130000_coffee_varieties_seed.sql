-- Catálogo global de variedades de café (reemplaza variedades de aguacate).

DO $$
BEGIN
  IF to_regclass('public.avocado_varieties') IS NOT NULL
     AND to_regclass('public.coffee_varieties') IS NULL THEN
    ALTER TABLE public.avocado_varieties RENAME TO coffee_varieties;
  END IF;
  IF to_regclass('public.lot_avocado_varieties') IS NOT NULL
     AND to_regclass('public.lot_coffee_varieties') IS NULL THEN
    ALTER TABLE public.lot_avocado_varieties RENAME TO lot_coffee_varieties;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'lot_coffee_varieties'
      AND column_name = 'avocado_variety_id'
  ) THEN
    ALTER TABLE public.lot_coffee_varieties
      RENAME COLUMN avocado_variety_id TO coffee_variety_id;
  END IF;
END $$;

-- Renombrar FK legacy si aún apunta al nombre antiguo.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'lot_avocado_varieties_avocado_variety_id_fkey'
  ) THEN
    ALTER TABLE public.lot_coffee_varieties
      DROP CONSTRAINT lot_avocado_varieties_avocado_variety_id_fkey;
    ALTER TABLE public.lot_coffee_varieties
      ADD CONSTRAINT lot_coffee_varieties_coffee_variety_id_fkey
      FOREIGN KEY (coffee_variety_id) REFERENCES public.coffee_varieties(id) ON DELETE RESTRICT;
  END IF;
END $$;

-- Quitar vínculos lote ↔ variedad de aguacate (IDs distintos).
TRUNCATE TABLE public.lot_coffee_varieties;

-- Eliminar catálogo de aguacate.
DELETE FROM public.coffee_varieties;

INSERT INTO public.coffee_varieties (id, name, display_name, is_active) VALUES
  ('b1000001-0001-4001-8001-000000000001', 'caturra', 'Caturra', true),
  ('b1000001-0001-4001-8001-000000000002', 'catuai_amarillo', 'Catuaí Amarillo', true),
  ('b1000001-0001-4001-8001-000000000003', 'catuai_rojo', 'Catuaí Rojo', true),
  ('b1000001-0001-4001-8001-000000000004', 'catimor', 'Catimor', true),
  ('b1000001-0001-4001-8001-000000000005', 'villa_sarchi', 'Villa Sarchí', true),
  ('b1000001-0001-4001-8001-000000000006', 'obata', 'Obatá', true),
  ('b1000001-0001-4001-8001-000000000007', 'geisha', 'Geisha', true),
  ('b1000001-0001-4001-8001-000000000008', 'bourbon', 'Bourbon', true),
  ('b1000001-0001-4001-8001-000000000009', 'typica', 'Típica', true),
  ('b1000001-0001-4001-8001-00000000000a', 'maragogipe', 'Maragogipe', true),
  ('b1000001-0001-4001-8001-00000000000b', 'pacamara', 'Pacamara', true),
  ('b1000001-0001-4001-8001-00000000000c', 'costa_rica_95', 'Costa Rica 95', true),
  ('b1000001-0001-4001-8001-00000000000d', 'ihcafe_90', 'IHCAFE 90', true),
  ('b1000001-0001-4001-8001-00000000000e', 'sarchimor', 'Sarchimor', true),
  ('b1000001-0001-4001-8001-00000000000f', 'centroamericano', 'Centroamericano F1', true)
ON CONFLICT (name) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  is_active = true,
  updated_at = NOW();
