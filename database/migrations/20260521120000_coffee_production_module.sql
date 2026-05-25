-- Producción de café: tabla dedicada y retiro del modelo de aguacate (calibres / scope finca).

DROP TABLE IF EXISTS public.lot_production_details CASCADE;
DROP TABLE IF EXISTS public.lot_production_allocations CASCADE;
DROP TABLE IF EXISTS public.lot_production CASCADE;

CREATE TABLE public.coffee_lot_production (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid NOT NULL,
    lot_id uuid NOT NULL,
    prod_date date NOT NULL,
    cajuelas numeric(12, 2) NOT NULL,
    fanegas numeric(14, 4) GENERATED ALWAYS AS ((cajuelas / 20.0)) STORED,
    notes text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    CONSTRAINT coffee_lot_production_cajuelas_check CHECK ((cajuelas >= (0)::numeric)),
    CONSTRAINT coffee_lot_production_pkey PRIMARY KEY (id),
    CONSTRAINT coffee_lot_production_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id),
    CONSTRAINT coffee_lot_production_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES public.lots(id),
    CONSTRAINT coffee_lot_production_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT coffee_lot_production_updated_by_user_id_fkey FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL
);

CREATE INDEX idx_coffee_lot_production_client ON public.coffee_lot_production USING btree (client_id);
CREATE INDEX idx_coffee_lot_production_lot_date ON public.coffee_lot_production USING btree (lot_id, prod_date);
CREATE INDEX idx_coffee_lot_production_prod_date ON public.coffee_lot_production USING btree (client_id, prod_date);

CREATE UNIQUE INDEX uq_coffee_lot_production_active_lot_date
    ON public.coffee_lot_production (client_id, lot_id, prod_date)
    WHERE (is_active = true);

-- Variedades: nombres de tabla alineados con café (constraints legacy se conservan).
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
