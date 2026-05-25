-- Unidad de pago para labores: cajuela (cosecha de café).

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_enum e
    INNER JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'pay_unit'
      AND e.enumlabel = 'cajuela'
  ) THEN
    ALTER TYPE public.pay_unit ADD VALUE 'cajuela';
  END IF;
END $$;
