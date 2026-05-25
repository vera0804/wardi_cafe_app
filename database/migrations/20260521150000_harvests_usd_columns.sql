-- Precio por fanega en USD y tipo de cambio en períodos de cosecha.

ALTER TABLE public.harvests
  ADD COLUMN IF NOT EXISTS price_per_fanega_usd numeric(14, 2),
  ADD COLUMN IF NOT EXISTS price_fx_rate numeric(14, 4);
