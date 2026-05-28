-- Separa aporte patrono CCSS de otros aportes patrono (INS, etc.) en reglas y planillas.

ALTER TABLE public.payroll_nomina_contribution_rules
  ADD COLUMN IF NOT EXISTS employer_other_pct_of_gross numeric(8,4) NOT NULL DEFAULT 0;

COMMENT ON COLUMN public.payroll_nomina_contribution_rules.employer_pct_of_gross IS
  'Porcentaje CCSS del patrono sobre el salario bruto.';
COMMENT ON COLUMN public.payroll_nomina_contribution_rules.employer_other_pct_of_gross IS
  'Otros aportes del patrono (INS, etc.) sobre el salario bruto.';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'payroll_nomina_contribution_rules_employer_other_pct_chk'
  ) THEN
    ALTER TABLE public.payroll_nomina_contribution_rules
      ADD CONSTRAINT payroll_nomina_contribution_rules_employer_other_pct_chk
      CHECK (
        (employer_other_pct_of_gross >= (0)::numeric)
        AND (employer_other_pct_of_gross <= (100)::numeric)
      );
  END IF;
END $$;

ALTER TABLE public.payroll_slips
  ADD COLUMN IF NOT EXISTS employer_other_amount numeric(14,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS employer_other_pct_snapshot numeric(8,4);

COMMENT ON COLUMN public.payroll_slips.employer_ccss_amount IS
  'Monto CCSS patrono calculado sobre el bruto del periodo.';
COMMENT ON COLUMN public.payroll_slips.employer_other_amount IS
  'Otros aportes patrono (INS, etc.) calculados sobre el bruto del periodo.';
COMMENT ON COLUMN public.payroll_slips.employer_pct_snapshot IS
  'Porcentaje CCSS patrono (regla vigente al calcular).';
COMMENT ON COLUMN public.payroll_slips.employer_other_pct_snapshot IS
  'Porcentaje otros aportes patrono (regla vigente al calcular).';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'payroll_slips_employer_other_chk'
  ) THEN
    ALTER TABLE public.payroll_slips
      ADD CONSTRAINT payroll_slips_employer_other_chk
      CHECK ((employer_other_amount >= (0)::numeric));
  END IF;
END $$;
