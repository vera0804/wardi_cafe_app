--
-- PostgreSQL database dump
--

\restrict bzoBXGZnOiGQlAWbzXYXyaddSl5XZKyWd7O9eFOC0xxT66fXjYjyl0co5P9F74K

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-05-25 17:13:16

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
-- SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 13 (class 2615 OID 54745)
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- TOC entry 7495 (class 0 OID 0)
-- Dependencies: 13
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


--
-- TOC entry 11 (class 2615 OID 54746)
-- Name: tiger; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS tiger;


--
-- TOC entry 12 (class 2615 OID 54747)
-- Name: topology; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS topology;


--
-- TOC entry 7496 (class 0 OID 0)
-- Dependencies: 12
-- Name: SCHEMA topology; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';


--
-- TOC entry 2 (class 3079 OID 54748)
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- TOC entry 7497 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- TOC entry 3 (class 3079 OID 54760)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 7498 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 4 (class 3079 OID 54798)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 7499 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- TOC entry 5 (class 3079 OID 55880)
-- Name: postgis_tiger_geocoder; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder WITH SCHEMA tiger;


--
-- TOC entry 7500 (class 0 OID 0)
-- Dependencies: 5
-- Name: EXTENSION postgis_tiger_geocoder; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis_tiger_geocoder IS 'PostGIS tiger geocoder and reverse geocoder';


--
-- TOC entry 6 (class 3079 OID 56313)
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- TOC entry 7501 (class 0 OID 0)
-- Dependencies: 6
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


--
-- TOC entry 7 (class 3079 OID 56501)
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- TOC entry 7502 (class 0 OID 0)
-- Dependencies: 7
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- TOC entry 2065 (class 1247 OID 56509)
-- Name: activity_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.activity_status AS ENUM (
    'pending',
    'completed',
    'cancelled'
);


--
-- TOC entry 2068 (class 1247 OID 56516)
-- Name: aguinaldo_statement_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.aguinaldo_statement_status AS ENUM (
    'calculado',
    'pagado',
    'cancelado'
);


--
-- TOC entry 2071 (class 1247 OID 56524)
-- Name: id_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.id_type AS ENUM (
    'nacional',
    'extranjero'
);


--
-- TOC entry 2074 (class 1247 OID 56530)
-- Name: movement_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.movement_type AS ENUM (
    'in',
    'out',
    'adjust'
);


--
-- TOC entry 2077 (class 1247 OID 56538)
-- Name: pay_unit; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.pay_unit AS ENUM (
    'mensual',
    'jornal',
    'hora',
    'caja',
    'tarea',
    'bolsas',
    'cajuela'
);


--
-- TOC entry 2080 (class 1247 OID 56552)
-- Name: payroll_slip_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payroll_slip_status AS ENUM (
    'calculada',
    'pagada',
    'cancelada'
);


--
-- TOC entry 2083 (class 1247 OID 56560)
-- Name: worker_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.worker_type AS ENUM (
    'fijo',
    'ocasional',
    'recolector'
);


--
-- TOC entry 453 (class 1255 OID 56567)
-- Name: allocate_general_expense_by_area(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.allocate_general_expense_by_area(p_general_expense_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_farm_id UUID;
  v_amount  NUMERIC(14,2);
  v_total_area NUMERIC(14,4);
  v_client_id UUID;
BEGIN
  SELECT farm_id, amount_crc, client_id
    INTO v_farm_id, v_amount, v_client_id
  FROM general_expenses
  WHERE id = p_general_expense_id
    AND is_active = TRUE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'general_expense not found or inactive: %', p_general_expense_id;
  END IF;

  IF v_client_id IS NULL THEN
    RAISE EXCEPTION 'general_expense % has no client_id; backfill client_id before allocating', p_general_expense_id;
  END IF;

  IF v_amount IS NULL OR v_amount < 0 THEN
    RAISE EXCEPTION 'general_expense amount_crc is invalid: %', v_amount;
  END IF;

  IF v_farm_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM farms f
      WHERE f.id = v_farm_id AND f.client_id = v_client_id AND f.is_active = true
    ) THEN
      RAISE EXCEPTION 'farm % does not belong to client % or is inactive', v_farm_id, v_client_id;
    END IF;
  END IF;

  IF v_farm_id IS NULL THEN
    SELECT COALESCE(SUM(area_ha), 0)
      INTO v_total_area
    FROM lots
    WHERE client_id = v_client_id
      AND area_ha > 0
      AND (is_active IS NULL OR is_active = TRUE);
  ELSE
    SELECT COALESCE(SUM(area_ha), 0)
      INTO v_total_area
    FROM lots
    WHERE farm_id = v_farm_id
      AND client_id = v_client_id
      AND area_ha > 0
      AND (is_active IS NULL OR is_active = TRUE);
  END IF;

  IF v_total_area <= 0 THEN
    RAISE EXCEPTION 'Total area_ha is 0. Cannot allocate.';
  END IF;

  DELETE FROM general_expense_allocations
  WHERE general_expense_id = p_general_expense_id;

  IF v_farm_id IS NULL THEN
    INSERT INTO general_expense_allocations
      (general_expense_id, lot_id, allocation_basis, allocation_pct, amount_allocated, created_at, updated_at)
    SELECT
      p_general_expense_id,
      l.id,
      'area_ha',
      ROUND((l.area_ha / v_total_area) * 100.0, 3),
      ROUND((l.area_ha / v_total_area) * v_amount, 2),
      NOW(), NOW()
    FROM lots l
    WHERE l.client_id = v_client_id
      AND l.area_ha > 0
      AND (l.is_active IS NULL OR l.is_active = TRUE);
  ELSE
    INSERT INTO general_expense_allocations
      (general_expense_id, lot_id, allocation_basis, allocation_pct, amount_allocated, created_at, updated_at)
    SELECT
      p_general_expense_id,
      l.id,
      'area_ha',
      ROUND((l.area_ha / v_total_area) * 100.0, 3),
      ROUND((l.area_ha / v_total_area) * v_amount, 2),
      NOW(), NOW()
    FROM lots l
    WHERE l.farm_id = v_farm_id
      AND l.client_id = v_client_id
      AND l.area_ha > 0
      AND (l.is_active IS NULL OR l.is_active = TRUE);
  END IF;

  WITH s AS (
    SELECT COALESCE(SUM(amount_allocated), 0) AS sum_alloc
    FROM general_expense_allocations
    WHERE general_expense_id = p_general_expense_id
  ),
  biggest AS (
    SELECT id
    FROM general_expense_allocations
    WHERE general_expense_id = p_general_expense_id
    ORDER BY amount_allocated DESC
    LIMIT 1
  )
  UPDATE general_expense_allocations a
  SET amount_allocated = a.amount_allocated + (v_amount - (SELECT sum_alloc FROM s)),
      updated_at = NOW()
  WHERE a.id = (SELECT id FROM biggest);

  UPDATE general_expenses
  SET updated_at = NOW()
  WHERE id = p_general_expense_id;

END;
$$;


--
-- TOC entry 1148 (class 1255 OID 56568)
-- Name: app_current_tenant_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.app_current_tenant_id() RETURNS uuid
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


--
-- TOC entry 7503 (class 0 OID 0)
-- Dependencies: 1148
-- Name: FUNCTION app_current_tenant_id(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.app_current_tenant_id() IS 'Lee el tenant actual desde GUC app.tenant_id (SET LOCAL dentro de cada transacción).';


--
-- TOC entry 676 (class 1255 OID 56569)
-- Name: generate_asset_plate(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_asset_plate() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    chars TEXT := 'abcdefghijklmnopqrstuvwxyz0123456789';
    result TEXT := 'CDC';
    i INT;
BEGIN
    FOR i IN 1..6 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;

    RETURN result;
END;
$$;


--
-- TOC entry 746 (class 1255 OID 56570)
-- Name: generate_unique_asset_plate(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_unique_asset_plate() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    chars TEXT := 'abcdefghijklmnopqrstuvwxyz0123456789';
    result TEXT;
    exists_plate BOOLEAN;
BEGIN
    LOOP
        result := 'CDC';

        FOR i IN 1..6 LOOP
            result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
        END LOOP;

        -- verificar si ya existe
        SELECT EXISTS (
            SELECT 1 FROM assets WHERE plate = result
        ) INTO exists_plate;

        -- si no existe, salir del loop
        EXIT WHEN NOT exists_plate;
    END LOOP;

    RETURN result;
END;
$$;


--
-- TOC entry 1134 (class 1255 OID 56571)
-- Name: generate_unique_asset_plate(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_unique_asset_plate(p_client_id uuid) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    chars TEXT := 'abcdefghijklmnopqrstuvwxyz0123456789';
    result TEXT;
    exists_plate BOOLEAN;
BEGIN
    LOOP
        result := 'W';
        FOR i IN 1..6 LOOP
            result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
        END LOOP;

        SELECT EXISTS (
            SELECT 1 FROM public.assets a
            WHERE a.client_id = p_client_id AND a.plate = result
        ) INTO exists_plate;

        EXIT WHEN NOT exists_plate;
    END LOOP;

    RETURN result;
END;
$$;


--
-- TOC entry 908 (class 1255 OID 56572)
-- Name: set_asset_plate(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_asset_plate() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.plate IS NULL OR length(trim(NEW.plate::text)) = 0 THEN
        NEW.plate := public.generate_unique_asset_plate(NEW.client_id);
    END IF;
    RETURN NEW;
END;
$$;


--
-- TOC entry 1330 (class 1255 OID 56573)
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


--
-- TOC entry 1001 (class 1255 OID 56574)
-- Name: trg_asset_categories_set_name_norm(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_asset_categories_set_name_norm() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.name_norm := lower(public.unaccent(trim(NEW.name::text)));
  RETURN NEW;
END;
$$;


--
-- TOC entry 899 (class 1255 OID 56575)
-- Name: trg_expense_categories_set_name_norm(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_expense_categories_set_name_norm() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.name_norm := lower(public.unaccent(trim(NEW.name::text)));
  RETURN NEW;
END;
$$;


--
-- TOC entry 1273 (class 1255 OID 56576)
-- Name: trg_general_expense_recalc(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_general_expense_recalc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    IF NEW.is_active = TRUE AND NEW.allocation_method = 'area_ha' THEN
      PERFORM allocate_general_expense_by_area(NEW.id);
    END IF;
    RETURN NEW;
  END IF;

  IF (TG_OP = 'UPDATE') THEN
    IF NEW.allocation_method = 'area_ha' THEN
      -- recalcular si cambió monto (CRC), finca, o activación
      IF (NEW.amount_crc IS DISTINCT FROM OLD.amount_crc)
         OR (NEW.farm_id IS DISTINCT FROM OLD.farm_id)
         OR (NEW.is_active IS DISTINCT FROM OLD.is_active) THEN
        IF NEW.is_active = TRUE THEN
          PERFORM allocate_general_expense_by_area(NEW.id);
        ELSE
          DELETE FROM general_expense_allocations WHERE general_expense_id = NEW.id;
        END IF;
      END IF;
    END IF;

    NEW.updated_at = NOW();
    RETURN NEW;
  END IF;

  RETURN NEW;
END $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 289 (class 1259 OID 56577)
-- Name: aguinaldo_statements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aguinaldo_statements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid NOT NULL,
    worker_id uuid NOT NULL,
    legal_period_from date NOT NULL,
    legal_period_to date NOT NULL,
    total_gross_from_slips numeric(14,2) DEFAULT 0 NOT NULL,
    slip_count integer DEFAULT 0 NOT NULL,
    aguinaldo_amount numeric(14,2) NOT NULL,
    contributing_slip_ids jsonb DEFAULT '[]'::jsonb NOT NULL,
    status public.aguinaldo_statement_status DEFAULT 'calculado'::public.aguinaldo_statement_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    CONSTRAINT aguinaldo_statements_amount_chk CHECK ((aguinaldo_amount >= (0)::numeric)),
    CONSTRAINT aguinaldo_statements_gross_chk CHECK ((total_gross_from_slips >= (0)::numeric)),
    CONSTRAINT aguinaldo_statements_period_chk CHECK ((legal_period_from < legal_period_to)),
    CONSTRAINT aguinaldo_statements_slip_count_chk CHECK ((slip_count >= 0))
);


--
-- TOC entry 290 (class 1259 OID 56605)
-- Name: asset_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    status character varying(10) DEFAULT 'activo'::character varying NOT NULL,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    client_id uuid NOT NULL,
    name_norm text NOT NULL,
    CONSTRAINT asset_categories_status_check CHECK (((status)::text = ANY (ARRAY[('activo'::character varying)::text, ('inactivo'::character varying)::text])))
);


--
-- TOC entry 291 (class 1259 OID 56622)
-- Name: asset_depreciation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_depreciation (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    asset_id uuid NOT NULL,
    period_year integer NOT NULL,
    period_month integer NOT NULL,
    depreciation_amount numeric(14,2) NOT NULL,
    accumulated_depreciation numeric(14,2) NOT NULL,
    book_value numeric(14,2) NOT NULL,
    status character varying(10) DEFAULT 'activo'::character varying NOT NULL,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    client_id uuid NOT NULL,
    CONSTRAINT asset_depreciation_accumulated_depreciation_check CHECK ((accumulated_depreciation >= (0)::numeric)),
    CONSTRAINT asset_depreciation_book_value_check CHECK ((book_value >= (0)::numeric)),
    CONSTRAINT asset_depreciation_depreciation_amount_check CHECK ((depreciation_amount >= (0)::numeric)),
    CONSTRAINT asset_depreciation_period_month_check CHECK (((period_month >= 1) AND (period_month <= 12))),
    CONSTRAINT asset_depreciation_period_year_check CHECK ((period_year >= 2000)),
    CONSTRAINT asset_depreciation_status_check CHECK (((status)::text = ANY (ARRAY[('activo'::character varying)::text, ('inactivo'::character varying)::text])))
);


--
-- TOC entry 292 (class 1259 OID 56646)
-- Name: assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    category_id uuid NOT NULL,
    alias character varying(100),
    brand character varying(100),
    model character varying(100),
    name character varying(150) NOT NULL,
    purchase_date date NOT NULL,
    purchase_cost numeric(14,2) NOT NULL,
    useful_life_years integer NOT NULL,
    salvage_value numeric(14,2) DEFAULT 0 NOT NULL,
    status character varying(10) DEFAULT 'activo'::character varying NOT NULL,
    observations text,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    purchase_cost_usd numeric(14,2),
    plate character varying(20) NOT NULL,
    client_id uuid NOT NULL,
    disposition_reason character varying(30),
    disposition_date date,
    disposition_notes text,
    CONSTRAINT assets_purchase_cost_check CHECK ((purchase_cost >= (0)::numeric)),
    CONSTRAINT assets_purchase_cost_usd_check CHECK (((purchase_cost_usd IS NULL) OR (purchase_cost_usd >= (0)::numeric))),
    CONSTRAINT assets_salvage_value_check CHECK ((salvage_value >= (0)::numeric)),
    CONSTRAINT assets_status_check CHECK (((status)::text = ANY (ARRAY[('activo'::character varying)::text, ('inactivo'::character varying)::text]))),
    CONSTRAINT assets_useful_life_years_check CHECK ((useful_life_years > 0)),
    CONSTRAINT chk_assets_disposition_reason CHECK (((disposition_reason IS NULL) OR ((disposition_reason)::text = ANY (ARRAY[('venta'::character varying)::text, ('donacion'::character varying)::text, ('perdida'::character varying)::text])))),
    CONSTRAINT chk_assets_salvage CHECK ((salvage_value <= purchase_cost))
);


--
-- TOC entry 294 (class 1259 OID 56689)
-- Name: calendar_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calendar_activities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    activity_date timestamp with time zone NOT NULL,
    farm_id uuid NOT NULL,
    lot_id uuid,
    labor_type_id uuid NOT NULL,
    status public.activity_status DEFAULT 'pending'::public.activity_status NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    client_id uuid NOT NULL
);


--
-- TOC entry 295 (class 1259 OID 56706)
-- Name: calibers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calibers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    client_id uuid NOT NULL
);


--
-- TOC entry 296 (class 1259 OID 56717)
-- Name: cantons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cantons (
    id integer NOT NULL,
    province_id integer NOT NULL,
    name character varying(100) NOT NULL,
    official_code character varying(10)
);


--
-- TOC entry 297 (class 1259 OID 56723)
-- Name: cantons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.cantons ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.cantons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 298 (class 1259 OID 56724)
-- Name: clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(150) NOT NULL,
    plan_id uuid,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    license_starts_on date,
    license_expires_on date,
    billing_anchor_day smallint
);


--
-- TOC entry 7504 (class 0 OID 0)
-- Dependencies: 298
-- Name: COLUMN clients.license_starts_on; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clients.license_starts_on IS 'Inicio de vigencia (creación o última renovación).';


--
-- TOC entry 7505 (class 0 OID 0)
-- Dependencies: 298
-- Name: COLUMN clients.license_expires_on; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clients.license_expires_on IS 'Último día inclusive de vigencia; el cron de medianoche revoca sesiones si hoy > esta fecha.';


--
-- TOC entry 7506 (class 0 OID 0)
-- Dependencies: 298
-- Name: COLUMN clients.billing_anchor_day; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clients.billing_anchor_day IS 'Día del mes (1-28) para renovación mensual cuando el plan usa monthly_anchor.';


--
-- TOC entry 344 (class 1259 OID 58686)
-- Name: coffee_lot_production; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coffee_lot_production (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid NOT NULL,
    lot_id uuid NOT NULL,
    prod_date date NOT NULL,
    cajuelas numeric(12,2) NOT NULL,
    fanegas numeric(14,4) GENERATED ALWAYS AS ((cajuelas / 20.0)) STORED,
    notes text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    CONSTRAINT coffee_lot_production_cajuelas_check CHECK ((cajuelas >= (0)::numeric))
);

ALTER TABLE ONLY public.coffee_lot_production FORCE ROW LEVEL SECURITY;


--
-- TOC entry 293 (class 1259 OID 56675)
-- Name: coffee_varieties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coffee_varieties (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    display_name text
);


--
-- TOC entry 299 (class 1259 OID 56732)
-- Name: districts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.districts (
    id integer NOT NULL,
    canton_id integer NOT NULL,
    name character varying(100) NOT NULL,
    official_code character varying(10)
);


--
-- TOC entry 300 (class 1259 OID 56738)
-- Name: districts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.districts ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.districts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 301 (class 1259 OID 56739)
-- Name: expense_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.expense_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid NOT NULL,
    name character varying(100) NOT NULL,
    name_norm text NOT NULL,
    status character varying(10) DEFAULT 'activo'::character varying NOT NULL,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT expense_categories_status_check CHECK (((status)::text = ANY (ARRAY[('activo'::character varying)::text, ('inactivo'::character varying)::text])))
);


--
-- TOC entry 302 (class 1259 OID 56756)
-- Name: expenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.expenses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lot_id uuid NOT NULL,
    harvest_id uuid,
    exp_date date NOT NULL,
    description text,
    amount numeric(14,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    currency text DEFAULT 'CRC'::text NOT NULL,
    fx_rate numeric(14,6),
    amount_input numeric(14,2),
    amount_crc numeric(14,2) NOT NULL,
    amount_usd numeric(14,2),
    client_id uuid NOT NULL,
    category_id uuid NOT NULL,
    CONSTRAINT expenses_amount_check CHECK ((amount >= (0)::numeric)),
    CONSTRAINT expenses_amount_usd_check CHECK (((amount_usd IS NULL) OR (amount_usd >= (0)::numeric))),
    CONSTRAINT expenses_currency_check CHECK ((currency = ANY (ARRAY['CRC'::text, 'USD'::text])))
);


--
-- TOC entry 303 (class 1259 OID 56780)
-- Name: farm_harvest_estimates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.farm_harvest_estimates (
    farm_id uuid NOT NULL,
    harvest_id uuid NOT NULL,
    estimated_cajuelas numeric(14,2),
    estimated_fanegas numeric(14,2),
    notes text,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    client_id uuid NOT NULL
);


--
-- TOC entry 304 (class 1259 OID 56792)
-- Name: farms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.farms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    location text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    deactivated_at timestamp with time zone,
    location_geom public.geometry(Point,4326),
    created_by_user_id uuid,
    updated_by_user_id uuid,
    geom public.geometry(Polygon,4326),
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    area_ha numeric(12,4),
    area_m2 numeric(14,2) GENERATED ALWAYS AS ((area_ha * (10000)::numeric)) STORED,
    labor_allocation_mode text DEFAULT 'area'::text NOT NULL,
    client_id uuid NOT NULL,
    province_id integer,
    canton_id integer,
    district_id integer,
    community text,
    CONSTRAINT farms_area_ha_check CHECK ((area_ha >= (0)::numeric)),
    CONSTRAINT farms_labor_allocation_mode_check CHECK ((labor_allocation_mode = ANY (ARRAY['area'::text, 'manual'::text])))
);


--
-- TOC entry 7507 (class 0 OID 0)
-- Dependencies: 304
-- Name: COLUMN farms.location; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.farms.location IS 'Texto libre legado; preferir province_id/canton_id/district_id/community.';


--
-- TOC entry 7508 (class 0 OID 0)
-- Dependencies: 304
-- Name: COLUMN farms.province_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.farms.province_id IS 'Provincia (Costa Rica); obligatoria al crear/editar en la aplicación.';


--
-- TOC entry 7509 (class 0 OID 0)
-- Dependencies: 304
-- Name: COLUMN farms.canton_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.farms.canton_id IS 'Cantón; opcional.';


--
-- TOC entry 7510 (class 0 OID 0)
-- Dependencies: 304
-- Name: COLUMN farms.district_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.farms.district_id IS 'Distrito; opcional.';


--
-- TOC entry 7511 (class 0 OID 0)
-- Dependencies: 304
-- Name: COLUMN farms.community; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.farms.community IS 'Poblado o comunidad; texto libre opcional.';


--
-- TOC entry 305 (class 1259 OID 56812)
-- Name: fixed_payroll; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fixed_payroll (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    worker_id uuid NOT NULL,
    period_id uuid NOT NULL,
    gross_salary numeric(14,2) NOT NULL,
    social_charges numeric(14,2) NOT NULL,
    other_costs numeric(14,2) DEFAULT 0 NOT NULL,
    total_cost numeric(14,2) GENERATED ALWAYS AS (((gross_salary + social_charges) + other_costs)) STORED,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    base_salary numeric(14,2) DEFAULT 0 NOT NULL,
    employer_ccss numeric(14,2) DEFAULT 0 NOT NULL,
    employer_other numeric(14,2) DEFAULT 0 NOT NULL,
    aguinaldo_provision numeric(14,2) DEFAULT 0 NOT NULL,
    other_provisions numeric(14,2) DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    employee_ccss numeric(14,2) DEFAULT 0 NOT NULL,
    net_salary numeric(14,2) DEFAULT 0 NOT NULL,
    ccss_total_to_pay numeric(14,2) DEFAULT 0 NOT NULL,
    alloc_mode text DEFAULT 'auto'::text NOT NULL,
    alloc_last_calculated_at timestamp with time zone,
    is_paid boolean DEFAULT false NOT NULL,
    CONSTRAINT fixed_payroll_alloc_mode_chk CHECK ((alloc_mode = ANY (ARRAY['auto'::text, 'manual'::text]))),
    CONSTRAINT fixed_payroll_ccss_total_to_pay_check CHECK ((ccss_total_to_pay >= (0)::numeric)),
    CONSTRAINT fixed_payroll_employee_ccss_check CHECK ((employee_ccss >= (0)::numeric)),
    CONSTRAINT fixed_payroll_gross_salary_check CHECK ((gross_salary >= (0)::numeric)),
    CONSTRAINT fixed_payroll_net_salary_check CHECK ((net_salary >= (0)::numeric)),
    CONSTRAINT fixed_payroll_other_costs_check CHECK ((other_costs >= (0)::numeric)),
    CONSTRAINT fixed_payroll_social_charges_check CHECK ((social_charges >= (0)::numeric))
);

ALTER TABLE ONLY public.fixed_payroll FORCE ROW LEVEL SECURITY;


--
-- TOC entry 306 (class 1259 OID 56859)
-- Name: fixed_payroll_allocations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fixed_payroll_allocations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fixed_payroll_id uuid NOT NULL,
    lot_id uuid NOT NULL,
    allocation_pct numeric(6,3),
    amount_allocated numeric(14,2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    CONSTRAINT fixed_payroll_allocations_check CHECK ((((allocation_pct IS NOT NULL) AND (amount_allocated IS NULL)) OR ((allocation_pct IS NULL) AND (amount_allocated IS NOT NULL))))
);

ALTER TABLE ONLY public.fixed_payroll_allocations FORCE ROW LEVEL SECURITY;


--
-- TOC entry 307 (class 1259 OID 56873)
-- Name: general_expense_allocations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.general_expense_allocations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    general_expense_id uuid NOT NULL,
    lot_id uuid NOT NULL,
    allocation_basis text DEFAULT 'area_ha'::text NOT NULL,
    allocation_pct numeric(6,3),
    amount_allocated numeric(14,2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT general_expense_allocations_allocation_basis_check CHECK ((allocation_basis = ANY (ARRAY['area_ha'::text, 'manual'::text]))),
    CONSTRAINT general_expense_allocations_check CHECK ((amount_allocated IS NOT NULL))
);


--
-- TOC entry 308 (class 1259 OID 56892)
-- Name: general_expenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.general_expenses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    farm_id uuid,
    harvest_id uuid,
    exp_date date NOT NULL,
    description text,
    amount numeric(14,2) NOT NULL,
    allocation_method text DEFAULT 'area_ha'::text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    currency text DEFAULT 'CRC'::text NOT NULL,
    fx_rate numeric(14,6),
    amount_input numeric(14,2),
    amount_crc numeric(14,2) NOT NULL,
    client_id uuid NOT NULL,
    category_id uuid NOT NULL,
    amount_usd numeric(14,2),
    CONSTRAINT general_expenses_allocation_method_check CHECK ((allocation_method = ANY (ARRAY['area_ha'::text, 'manual'::text]))),
    CONSTRAINT general_expenses_amount_check CHECK ((amount >= (0)::numeric)),
    CONSTRAINT general_expenses_currency_check CHECK ((currency = ANY (ARRAY['CRC'::text, 'USD'::text])))
);


--
-- TOC entry 309 (class 1259 OID 56917)
-- Name: harvests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.harvests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    created_by_user_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    price_per_fanega numeric(14,2),
    currency text DEFAULT 'CRC'::text,
    updated_by_user_id uuid,
    client_id uuid NOT NULL,
    price_per_fanega_usd numeric(14,2),
    price_fx_rate numeric(14,4),
    CONSTRAINT harvests_check CHECK ((end_date >= start_date))
);


--
-- TOC entry 310 (class 1259 OID 56936)
-- Name: inventory_brands; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_brands (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    client_id uuid NOT NULL,
    CONSTRAINT inventory_brands_name_not_blank CHECK ((length(TRIM(BOTH FROM name)) > 0))
);


--
-- TOC entry 311 (class 1259 OID 56952)
-- Name: inventory_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    CONSTRAINT inventory_categories_name_not_blank CHECK ((length(TRIM(BOTH FROM name)) > 0))
);


--
-- TOC entry 312 (class 1259 OID 56967)
-- Name: inventory_consumption_layers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_consumption_layers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    consumption_id uuid NOT NULL,
    layer_id uuid NOT NULL,
    qty_used numeric(14,3) NOT NULL,
    unit_cost numeric(14,2) NOT NULL,
    amount numeric(14,2) GENERATED ALWAYS AS ((qty_used * unit_cost)) STORED,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT inventory_consumption_layers_qty_used_check CHECK ((qty_used > (0)::numeric)),
    CONSTRAINT inventory_consumption_layers_unit_cost_check CHECK ((unit_cost >= (0)::numeric))
);


--
-- TOC entry 313 (class 1259 OID 56981)
-- Name: inventory_consumptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_consumptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lot_id uuid NOT NULL,
    harvest_id uuid,
    expense_id uuid,
    item_id uuid NOT NULL,
    cons_date date NOT NULL,
    qty numeric(14,3) NOT NULL,
    unit_cost_applied numeric(14,2) NOT NULL,
    amount numeric(14,2) GENERATED ALWAYS AS ((qty * unit_cost_applied)) STORED,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    mix_application_id uuid,
    application_group_id uuid,
    cost_scope text DEFAULT 'lot'::text NOT NULL,
    farm_id uuid,
    CONSTRAINT inventory_consumptions_cost_scope_consistency_chk CHECK (((cost_scope = ANY (ARRAY['lot'::text, 'farm'::text])) AND (((cost_scope = 'lot'::text) AND (farm_id IS NULL)) OR ((cost_scope = 'farm'::text) AND (farm_id IS NOT NULL))))),
    CONSTRAINT inventory_consumptions_qty_check CHECK ((qty > (0)::numeric)),
    CONSTRAINT inventory_consumptions_unit_cost_applied_check CHECK ((unit_cost_applied >= (0)::numeric))
);


--
-- TOC entry 314 (class 1259 OID 57005)
-- Name: inventory_item_ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_item_ingredients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid NOT NULL,
    ingredient_name text NOT NULL,
    concentration_value numeric(14,4),
    concentration_unit text,
    ingredient_role text,
    sort_order integer,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by_user_id uuid,
    updated_by_user_id uuid,
    CONSTRAINT inventory_item_ingredients_name_not_blank CHECK ((btrim(ingredient_name) <> ''::text))
);


--
-- TOC entry 315 (class 1259 OID 57019)
-- Name: inventory_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    unit text DEFAULT 'unidad'::text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    category_id uuid NOT NULL,
    brand_id uuid,
    client_id uuid NOT NULL
);


--
-- TOC entry 316 (class 1259 OID 57037)
-- Name: inventory_layers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_layers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid NOT NULL,
    movement_in_id uuid NOT NULL,
    layer_date date NOT NULL,
    qty_in numeric(14,3) NOT NULL,
    qty_remaining numeric(14,3) NOT NULL,
    unit_cost numeric(14,2) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    client_id uuid NOT NULL,
    CONSTRAINT inventory_layers_qty_in_check CHECK ((qty_in > (0)::numeric)),
    CONSTRAINT inventory_layers_qty_remaining_check CHECK ((qty_remaining >= (0)::numeric)),
    CONSTRAINT inventory_layers_unit_cost_check CHECK ((unit_cost >= (0)::numeric))
);


--
-- TOC entry 317 (class 1259 OID 57058)
-- Name: inventory_movement_layers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_movement_layers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    movement_id uuid NOT NULL,
    layer_id uuid NOT NULL,
    qty_used numeric(14,3) NOT NULL,
    unit_cost numeric(14,2) NOT NULL,
    amount numeric(14,2) GENERATED ALWAYS AS ((qty_used * unit_cost)) STORED,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT inventory_movement_layers_qty_used_check CHECK ((qty_used > (0)::numeric)),
    CONSTRAINT inventory_movement_layers_unit_cost_check CHECK ((unit_cost >= (0)::numeric))
);


--
-- TOC entry 318 (class 1259 OID 57072)
-- Name: inventory_movements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_movements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid NOT NULL,
    mov_date date NOT NULL,
    movement public.movement_type NOT NULL,
    qty numeric(14,3) NOT NULL,
    unit_cost numeric(14,2),
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    packages_qty numeric,
    package_cost numeric,
    pack_label text,
    pack_count numeric,
    pack_size numeric,
    pack_unit text,
    pack_cost numeric,
    total_cost numeric,
    currency text DEFAULT 'CRC'::text NOT NULL,
    fx_rate numeric(14,6),
    unit_cost_usd numeric(14,6),
    total_cost_usd numeric(14,2),
    client_id uuid NOT NULL,
    out_source_layer_id uuid,
    out_gross_total_crc numeric(14,2),
    out_refund_crc numeric(14,2),
    adjust_layer_id uuid,
    CONSTRAINT chk_inv_mov_currency CHECK ((currency = ANY (ARRAY['CRC'::text, 'USD'::text]))),
    CONSTRAINT chk_inv_mov_fx_rate CHECK ((((currency = 'CRC'::text) AND (fx_rate IS NULL)) OR ((currency = 'USD'::text) AND (fx_rate IS NOT NULL) AND (fx_rate > (0)::numeric)))),
    CONSTRAINT chk_inv_mov_out_refund_le_gross CHECK (((movement <> 'out'::public.movement_type) OR (out_gross_total_crc IS NULL) OR (out_refund_crc IS NULL) OR (out_refund_crc <= out_gross_total_crc))),
    CONSTRAINT chk_inv_mov_out_refund_nonneg CHECK (((out_refund_crc IS NULL) OR (out_refund_crc >= (0)::numeric))),
    CONSTRAINT chk_inv_mov_usd_cost_present CHECK (((currency = 'CRC'::text) OR ((currency = 'USD'::text) AND ((unit_cost_usd IS NOT NULL) OR (total_cost_usd IS NOT NULL))))),
    CONSTRAINT chk_inv_mov_usd_null_when_crc CHECK (((currency = 'USD'::text) OR ((unit_cost_usd IS NULL) AND (total_cost_usd IS NULL)))),
    CONSTRAINT chk_pack_cost_nonneg CHECK (((pack_cost IS NULL) OR (pack_cost >= (0)::numeric))),
    CONSTRAINT chk_pack_count_pos CHECK (((pack_count IS NULL) OR (pack_count > (0)::numeric))),
    CONSTRAINT chk_pack_size_pos CHECK (((pack_size IS NULL) OR (pack_size > (0)::numeric))),
    CONSTRAINT chk_total_cost_nonneg CHECK (((total_cost IS NULL) OR (total_cost >= (0)::numeric))),
    CONSTRAINT inventory_movements_qty_check CHECK ((qty >= (0)::numeric))
);


--
-- TOC entry 319 (class 1259 OID 57103)
-- Name: labor_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.labor_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lot_id uuid,
    worker_id uuid NOT NULL,
    labor_type_id uuid NOT NULL,
    work_date date NOT NULL,
    unit public.pay_unit NOT NULL,
    qty numeric(14,3) NOT NULL,
    rate_applied numeric(14,2) NOT NULL,
    amount numeric(14,2) GENERATED ALWAYS AS ((qty * rate_applied)) STORED,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    cost_scope text DEFAULT 'lot'::text NOT NULL,
    farm_id uuid,
    client_id uuid,
    CONSTRAINT labor_entries_qty_check CHECK ((qty > (0)::numeric)),
    CONSTRAINT labor_entries_rate_applied_check CHECK ((rate_applied >= (0)::numeric)),
    CONSTRAINT labor_entries_scope_chk CHECK ((((cost_scope = 'lot'::text) AND (lot_id IS NOT NULL) AND (farm_id IS NULL)) OR ((cost_scope = 'farm'::text) AND (farm_id IS NOT NULL) AND (lot_id IS NULL))))
);


--
-- TOC entry 320 (class 1259 OID 57128)
-- Name: labor_entry_allocations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.labor_entry_allocations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    labor_entry_id uuid NOT NULL,
    lot_id uuid NOT NULL,
    allocation_pct numeric(6,3),
    amount_allocated numeric(14,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_lea_amount CHECK ((amount_allocated >= (0)::numeric))
);


--
-- TOC entry 321 (class 1259 OID 57144)
-- Name: labor_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.labor_rates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    worker_type public.worker_type NOT NULL,
    labor_type_id uuid NOT NULL,
    unit public.pay_unit NOT NULL,
    rate_amount numeric(14,2) NOT NULL,
    valid_from date,
    valid_to date,
    harvest_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    CONSTRAINT labor_rates_rate_amount_check CHECK ((rate_amount >= (0)::numeric))
);


--
-- TOC entry 322 (class 1259 OID 57160)
-- Name: labor_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.labor_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid
);


--
-- TOC entry 323 (class 1259 OID 57174)
-- Name: lot_coffee_varieties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lot_coffee_varieties (
    lot_id uuid NOT NULL,
    coffee_variety_id uuid CONSTRAINT lot_coffee_varieties_variety_id_not_null NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid
);


--
-- TOC entry 324 (class 1259 OID 57185)
-- Name: lot_harvests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lot_harvests (
    lot_id uuid NOT NULL,
    harvest_id uuid NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    estimated_cajuelas numeric(14,2),
    estimated_fanegas numeric(14,2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 325 (class 1259 OID 57240)
-- Name: lots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    farm_id uuid NOT NULL,
    name text NOT NULL,
    area_ha numeric(12,4),
    area_m2 numeric(14,2) GENERATED ALWAYS AS ((area_ha * (10000)::numeric)) STORED,
    plant_count integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    deactivated_at timestamp with time zone,
    geom public.geometry(Polygon,4326),
    created_by_user_id uuid,
    updated_by_user_id uuid,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    client_id uuid NOT NULL,
    CONSTRAINT lots_area_ha_check CHECK ((area_ha > (0)::numeric)),
    CONSTRAINT lots_plant_count_check CHECK ((plant_count >= 0))
);


--
-- TOC entry 326 (class 1259 OID 57260)
-- Name: mix_application_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mix_application_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    mix_application_id uuid NOT NULL,
    item_id uuid NOT NULL,
    dose_qty numeric(12,4) NOT NULL,
    dose_unit text NOT NULL,
    dose_qty_base numeric(12,6),
    created_by_user_id uuid,
    updated_by_user_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mix_application_items_dose_qty_check CHECK ((dose_qty > (0)::numeric))
);


--
-- TOC entry 327 (class 1259 OID 57278)
-- Name: mix_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mix_applications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lot_id uuid,
    harvest_id uuid,
    expense_id uuid,
    app_date date NOT NULL,
    containers_used numeric(12,4) NOT NULL,
    notes text,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    client_id uuid NOT NULL,
    farm_id uuid,
    cost_scope text DEFAULT 'lot'::text NOT NULL,
    CONSTRAINT mix_applications_containers_used_check CHECK ((containers_used > (0)::numeric)),
    CONSTRAINT mix_applications_scope_chk CHECK (((cost_scope = ANY (ARRAY['lot'::text, 'farm'::text])) AND (((cost_scope = 'lot'::text) AND (lot_id IS NOT NULL) AND (farm_id IS NULL)) OR ((cost_scope = 'farm'::text) AND (farm_id IS NOT NULL) AND (lot_id IS NULL)))))
);


--
-- TOC entry 328 (class 1259 OID 57298)
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_reset_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token_hash text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    attempts integer DEFAULT 0 NOT NULL,
    last_sent_at timestamp with time zone
);


--
-- TOC entry 329 (class 1259 OID 57312)
-- Name: payroll_employee_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payroll_employee_rates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    valid_from date NOT NULL,
    valid_to date,
    ccss_employee_rate numeric(6,4) NOT NULL,
    notes text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    created_by_user_id uuid,
    updated_by_user_id uuid,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 330 (class 1259 OID 57326)
-- Name: payroll_nomina_contribution_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payroll_nomina_contribution_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid NOT NULL,
    valid_from date NOT NULL,
    valid_to date,
    employer_pct_of_gross numeric(8,4) CONSTRAINT payroll_nomina_contribution_rule_employer_pct_of_gross_not_null NOT NULL,
    employee_pct_of_gross numeric(8,4) CONSTRAINT payroll_nomina_contribution_rule_employee_pct_of_gross_not_null NOT NULL,
    notes text,
    is_active boolean DEFAULT true NOT NULL,
    deactivated_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    CONSTRAINT payroll_nomina_contribution_rules_dates_chk CHECK (((valid_to IS NULL) OR (valid_from <= valid_to))),
    CONSTRAINT payroll_nomina_contribution_rules_employee_pct_chk CHECK (((employee_pct_of_gross >= (0)::numeric) AND (employee_pct_of_gross <= (100)::numeric))),
    CONSTRAINT payroll_nomina_contribution_rules_employer_pct_chk CHECK (((employer_pct_of_gross >= (0)::numeric) AND (employer_pct_of_gross <= (100)::numeric)))
);


--
-- TOC entry 331 (class 1259 OID 57346)
-- Name: payroll_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payroll_periods (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    period_month date NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid
);


--
-- TOC entry 332 (class 1259 OID 57358)
-- Name: payroll_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payroll_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    valid_from date NOT NULL,
    valid_to date,
    ccss_employer_rate numeric(8,6) NOT NULL,
    other_employer_rate numeric(8,6) DEFAULT 0 NOT NULL,
    aguinaldo_monthly_rate numeric(8,6) DEFAULT 0.083333 NOT NULL,
    notes text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    CONSTRAINT payroll_settings_aguinaldo_monthly_rate_check CHECK ((aguinaldo_monthly_rate >= (0)::numeric)),
    CONSTRAINT payroll_settings_ccss_employer_rate_check CHECK ((ccss_employer_rate >= (0)::numeric)),
    CONSTRAINT payroll_settings_other_employer_rate_check CHECK ((other_employer_rate >= (0)::numeric))
);


--
-- TOC entry 333 (class 1259 OID 57380)
-- Name: payroll_slip_lot_allocations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payroll_slip_lot_allocations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    payroll_slip_id uuid NOT NULL,
    lot_id uuid NOT NULL,
    allocation_pct numeric(10,6) NOT NULL,
    amount_allocated numeric(14,2) NOT NULL,
    CONSTRAINT payroll_slip_lot_allocations_amt_chk CHECK ((amount_allocated >= (0)::numeric)),
    CONSTRAINT payroll_slip_lot_allocations_pct_chk CHECK (((allocation_pct >= (0)::numeric) AND (allocation_pct <= (100)::numeric)))
);

ALTER TABLE ONLY public.payroll_slip_lot_allocations FORCE ROW LEVEL SECURITY;


--
-- TOC entry 334 (class 1259 OID 57391)
-- Name: payroll_slips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payroll_slips (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid NOT NULL,
    worker_id uuid NOT NULL,
    worker_kind text NOT NULL,
    period_from date NOT NULL,
    period_to date NOT NULL,
    receives_aguinaldo boolean DEFAULT false NOT NULL,
    declares_ccss boolean DEFAULT false NOT NULL,
    status public.payroll_slip_status DEFAULT 'calculada'::public.payroll_slip_status NOT NULL,
    gross_total numeric(14,2) NOT NULL,
    employer_ccss_amount numeric(14,2) DEFAULT 0 NOT NULL,
    employee_ccss_amount numeric(14,2) DEFAULT 0 NOT NULL,
    aguinaldo_provision numeric(14,2) DEFAULT 0 NOT NULL,
    total_employer_liability numeric(14,2) NOT NULL,
    employer_pct_snapshot numeric(8,4),
    employee_pct_snapshot numeric(8,4),
    nomina_rule_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    CONSTRAINT payroll_slips_aguinaldo_chk CHECK ((aguinaldo_provision >= (0)::numeric)),
    CONSTRAINT payroll_slips_employee_ccss_chk CHECK ((employee_ccss_amount >= (0)::numeric)),
    CONSTRAINT payroll_slips_employer_ccss_chk CHECK ((employer_ccss_amount >= (0)::numeric)),
    CONSTRAINT payroll_slips_gross_chk CHECK ((gross_total >= (0)::numeric)),
    CONSTRAINT payroll_slips_liability_chk CHECK ((total_employer_liability >= (0)::numeric)),
    CONSTRAINT payroll_slips_period_chk CHECK ((period_from <= period_to)),
    CONSTRAINT payroll_slips_worker_kind_chk CHECK ((worker_kind = ANY (ARRAY['fijo'::text, 'ocasional'::text, 'recolector'::text])))
);


--
-- TOC entry 335 (class 1259 OID 57428)
-- Name: plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    max_farms integer DEFAULT 1,
    price numeric(10,2) DEFAULT 0,
    created_at timestamp without time zone DEFAULT now(),
    max_lots_per_farm integer DEFAULT 50 NOT NULL,
    max_users_admin integer DEFAULT 1 NOT NULL,
    max_users_operario integer DEFAULT 3 NOT NULL,
    billing_model character varying(32) DEFAULT 'perpetual'::character varying NOT NULL,
    trial_days integer,
    description text,
    is_active boolean DEFAULT true NOT NULL
);


--
-- TOC entry 7512 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN plans.billing_model; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.plans.billing_model IS 'perpetual | trial_days | monthly_anchor — define cómo se calcula license_expires_on del cliente.';


--
-- TOC entry 7513 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN plans.trial_days; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.plans.trial_days IS 'Días de vigencia para billing_model = trial_days (p. ej. demo 30 días).';


--
-- TOC entry 7514 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN plans.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.plans.description IS 'Texto descriptivo del plan para superadmin.';


--
-- TOC entry 7515 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN plans.is_active; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.plans.is_active IS 'false = no aparece al crear organizaciones; clientes ya asignados siguen usando el plan.';


--
-- TOC entry 336 (class 1259 OID 57443)
-- Name: provinces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.provinces (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    official_code character varying(10)
);


--
-- TOC entry 337 (class 1259 OID 57448)
-- Name: provinces_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.provinces ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.provinces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 338 (class 1259 OID 57449)
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(50) NOT NULL
);


--
-- TOC entry 339 (class 1259 OID 57455)
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    filename text NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 340 (class 1259 OID 57463)
-- Name: security_audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.security_audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_type text NOT NULL,
    user_id uuid,
    client_id uuid,
    identifier_hash text,
    ip_address text,
    user_agent_hash text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 341 (class 1259 OID 57475)
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    session_token_hash text CONSTRAINT sessions_session_token_not_null NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    last_activity timestamp with time zone DEFAULT now() NOT NULL,
    ip_address text,
    user_agent text,
    previous_session_token_hash text,
    previous_token_expires_at timestamp with time zone,
    acting_client_id uuid
);


--
-- TOC entry 342 (class 1259 OID 57489)
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    first_name text NOT NULL,
    last_name_1 text NOT NULL,
    last_name_2 text,
    email text NOT NULL,
    phone_1 text,
    phone_2 text,
    id_type public.id_type NOT NULL,
    id_number text NOT NULL,
    password_hash text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    client_id uuid,
    role_id uuid NOT NULL,
    failed_attempts integer DEFAULT 0 NOT NULL,
    locked_until timestamp with time zone
);


--
-- TOC entry 343 (class 1259 OID 57511)
-- Name: workers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    worker_type public.worker_type NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    first_name text NOT NULL,
    last_name_1 text,
    last_name_2 text,
    id_type public.id_type NOT NULL,
    id_number text,
    phone text,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id uuid,
    updated_by_user_id uuid,
    client_id uuid
);


--
-- TOC entry 7434 (class 0 OID 56577)
-- Dependencies: 289
-- Data for Name: aguinaldo_statements; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.aguinaldo_statements (id, client_id, worker_id, legal_period_from, legal_period_to, total_gross_from_slips, slip_count, aguinaldo_amount, contributing_slip_ids, status, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('bad4d4d1-3fd4-4d77-a0c3-a613b8ac8df6', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '9a6e581e-6625-4400-a49b-dc06cf829223', '2025-12-01', '2026-11-30', 300000.00, 1, 25000.00, '["5dff1aa8-fc14-44e1-bebf-189a82909adb"]', 'calculado', '2026-05-13 10:52:15.520263-06', '2026-05-13 10:52:37.882771-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b');
INSERT INTO public.aguinaldo_statements (id, client_id, worker_id, legal_period_from, legal_period_to, total_gross_from_slips, slip_count, aguinaldo_amount, contributing_slip_ids, status, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('c1ac9df2-d8c9-4fdd-ba5d-8cc3a8c40a88', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '159d7239-8cd7-496e-9f8a-05c4507677ec', '2025-12-01', '2026-11-30', 66300.00, 1, 5525.00, '["15a86060-2913-4142-bfc3-756338797788"]', 'calculado', '2026-05-13 10:54:11.865919-06', '2026-05-13 10:54:11.865919-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b');


--
-- TOC entry 7435 (class 0 OID 56605)
-- Dependencies: 290
-- Data for Name: asset_categories; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.asset_categories (id, name, status, created_by, updated_by, created_at, updated_at, client_id, name_norm) VALUES ('79de9974-13d7-4b7c-bdbb-3f02567461b0', 'Vehiculo', 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:06:35.131751-06', '2026-05-12 12:29:51.956411-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'vehiculo');
INSERT INTO public.asset_categories (id, name, status, created_by, updated_by, created_at, updated_at, client_id, name_norm) VALUES ('89281521-9923-4680-af6d-6d254765e94b', 'Maquinaria', 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:30:15.461526-06', '2026-05-12 12:30:15.461526-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'maquinaria');


--
-- TOC entry 7436 (class 0 OID 56622)
-- Dependencies: 291
-- Data for Name: asset_depreciation; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('487f1ce4-63d7-4baa-aa63-e5413cf6ff59', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2026, 5, 125000.00, 125000.00, 7375000.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:26.57401-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('add0811f-c582-499a-9e8e-e25de866a110', '85147a71-b565-41d5-9239-1d41e2a3195a', 2026, 5, 1250.00, 1250.00, 13750.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:35:47.962618-06', '2026-05-12 12:35:47.962618-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('81504870-68c0-4f60-ad60-7f698f913373', '85147a71-b565-41d5-9239-1d41e2a3195a', 2026, 6, 1250.00, 2500.00, 12500.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:35:47.962618-06', '2026-05-12 12:35:47.962618-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('1ab13309-4a3f-4fe6-8b47-f6b887881f19', '85147a71-b565-41d5-9239-1d41e2a3195a', 2026, 7, 1250.00, 3750.00, 11250.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:35:47.962618-06', '2026-05-12 12:35:47.962618-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('22694388-f954-43ea-b3db-c4d5b829d9b1', '85147a71-b565-41d5-9239-1d41e2a3195a', 2026, 8, 1250.00, 5000.00, 10000.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:35:47.962618-06', '2026-05-12 12:35:47.962618-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('cc1983cb-b500-45c8-9fb5-9334fd6c6422', '85147a71-b565-41d5-9239-1d41e2a3195a', 2026, 9, 1250.00, 6250.00, 8750.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:35:47.962618-06', '2026-05-12 12:35:47.962618-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('230d444e-ad87-4a64-8530-c064b3e02d11', '85147a71-b565-41d5-9239-1d41e2a3195a', 2026, 10, 1250.00, 7500.00, 7500.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:35:47.962618-06', '2026-05-12 12:35:47.962618-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('3390c2cf-0348-4365-8859-c770c2459aec', '85147a71-b565-41d5-9239-1d41e2a3195a', 2026, 11, 1250.00, 8750.00, 6250.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:35:47.962618-06', '2026-05-12 12:35:47.962618-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('6e40a1f5-f1fb-436e-8eeb-67bccaa72ce1', '85147a71-b565-41d5-9239-1d41e2a3195a', 2026, 12, 1250.00, 10000.00, 5000.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:35:47.962618-06', '2026-05-12 12:35:47.962618-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('6a29c47d-eac3-479d-9bf7-4f0314feea7b', '85147a71-b565-41d5-9239-1d41e2a3195a', 2027, 1, 1250.00, 11250.00, 3750.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:35:47.962618-06', '2026-05-12 12:35:47.962618-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('27e8f4ed-16be-4e4b-afce-8dc0a21e3a01', '85147a71-b565-41d5-9239-1d41e2a3195a', 2027, 2, 1250.00, 12500.00, 2500.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:35:47.962618-06', '2026-05-12 12:35:47.962618-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('79aaa6fd-7e5e-4f1b-ab2c-98ff83b5c46d', '85147a71-b565-41d5-9239-1d41e2a3195a', 2027, 3, 1250.00, 13750.00, 1250.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:35:47.962618-06', '2026-05-12 12:35:47.962618-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('f4afde32-d791-4aa6-90c9-ce9b53b1ee2c', '85147a71-b565-41d5-9239-1d41e2a3195a', 2027, 4, 1250.00, 15000.00, 0.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:35:47.962618-06', '2026-05-12 12:35:47.962618-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('47157017-1092-4c95-9411-f7b607566396', 'a8395917-bc32-49d5-890f-0e88760a57b0', 2026, 5, 1250.00, 1250.00, 13750.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-14 06:46:20.497367-06', '2026-05-14 06:46:20.497367-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('a45af7ca-e535-4d20-8ba4-b7a9e461b71b', 'a8395917-bc32-49d5-890f-0e88760a57b0', 2026, 6, 1250.00, 2500.00, 12500.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-14 06:46:20.497367-06', '2026-05-14 06:46:20.497367-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('bb6b76c9-ee96-4f86-90f9-8f1fa0607466', 'a8395917-bc32-49d5-890f-0e88760a57b0', 2026, 7, 1250.00, 3750.00, 11250.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-14 06:46:20.497367-06', '2026-05-14 06:46:20.497367-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('9f4e083d-6ecb-4003-bd3d-2ba103808b1d', 'a8395917-bc32-49d5-890f-0e88760a57b0', 2026, 8, 1250.00, 5000.00, 10000.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-14 06:46:20.497367-06', '2026-05-14 06:46:20.497367-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('df95476a-f5a4-47e5-a731-09fb7b0d1b07', 'a8395917-bc32-49d5-890f-0e88760a57b0', 2026, 9, 1250.00, 6250.00, 8750.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-14 06:46:20.497367-06', '2026-05-14 06:46:20.497367-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('a525cb5f-c18b-4a85-909a-301381be2b6c', 'a8395917-bc32-49d5-890f-0e88760a57b0', 2026, 10, 1250.00, 7500.00, 7500.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-14 06:46:20.497367-06', '2026-05-14 06:46:20.497367-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('9fe68bc0-191e-4268-b9e1-3a648356e263', 'a8395917-bc32-49d5-890f-0e88760a57b0', 2026, 11, 1250.00, 8750.00, 6250.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-14 06:46:20.497367-06', '2026-05-14 06:46:20.497367-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('1b0fe228-670d-40d4-bd5b-d888f5ff3c2d', 'a8395917-bc32-49d5-890f-0e88760a57b0', 2026, 12, 1250.00, 10000.00, 5000.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-14 06:46:20.497367-06', '2026-05-14 06:46:20.497367-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('b9bd9bfc-3347-4f6b-89b0-c63c90428367', 'a8395917-bc32-49d5-890f-0e88760a57b0', 2027, 1, 1250.00, 11250.00, 3750.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-14 06:46:20.497367-06', '2026-05-14 06:46:20.497367-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('f163a89b-6c3f-4323-af2b-a5c28eb54ff7', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2026, 6, 125000.00, 250000.00, 7250000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('3af2e69b-c141-4db0-99b3-d260a8868ec6', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2026, 7, 125000.00, 375000.00, 7125000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('ee763284-9e2b-49e0-aece-ef09438fd67f', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2026, 8, 125000.00, 500000.00, 7000000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('8997ff96-9b78-4cff-9eb2-56a241c9ad27', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2026, 9, 125000.00, 625000.00, 6875000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('8a947aa0-015e-48a8-9d2b-3658f459b61f', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2026, 10, 125000.00, 750000.00, 6750000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('b1baaeda-3ae3-4383-b332-56190f618a58', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2026, 11, 125000.00, 875000.00, 6625000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('bee79db4-4c15-4af0-9987-ec99ef2ad0b1', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2026, 12, 125000.00, 1000000.00, 6500000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('8077fcdb-5af7-41ed-8a30-7c5c4e3289aa', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2027, 1, 125000.00, 1125000.00, 6375000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('5f968ee5-3eb1-4ff3-901d-f6249f40a906', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2027, 2, 125000.00, 1250000.00, 6250000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('13773c81-db3e-48f3-889a-e4e23193b63e', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2027, 3, 125000.00, 1375000.00, 6125000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('a714f658-a6da-4d1c-8b5a-3290f9e3bb7a', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2027, 4, 125000.00, 1500000.00, 6000000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('055d8d57-77e4-4ea3-8204-7dce4c67a834', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2027, 5, 125000.00, 1625000.00, 5875000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('14df2342-fddf-493c-b023-3dc6f394d1f5', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2027, 6, 125000.00, 1750000.00, 5750000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('e52f1c1d-3235-43eb-a98c-0b8957f10000', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2027, 7, 125000.00, 1875000.00, 5625000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('686dc4cb-1b66-4cf8-af9c-314cdb06bccc', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2027, 8, 125000.00, 2000000.00, 5500000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('31f3214e-85fd-473f-a9fe-29be1b1f73a4', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2027, 9, 125000.00, 2125000.00, 5375000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('8b892145-59de-43a2-ba3d-7e65af813171', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2027, 10, 125000.00, 2250000.00, 5250000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('f79f882b-1cd2-4dee-87a2-19bf8b83e6f5', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2027, 11, 125000.00, 2375000.00, 5125000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('083385e2-f996-4acc-8614-e1145ac3ceb2', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2027, 12, 125000.00, 2500000.00, 5000000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('a81ecf43-cd33-489b-ae3d-e9dccff1bfd2', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2028, 1, 125000.00, 2625000.00, 4875000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('d0b9afb7-c1fc-427e-9a11-88d50e5ae701', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2028, 2, 125000.00, 2750000.00, 4750000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('efed095c-cd22-4b8a-8ac5-6d4f4c6ba84e', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2028, 3, 125000.00, 2875000.00, 4625000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('7d3276e1-f9eb-484d-bd44-ab4a81f732f6', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2028, 4, 125000.00, 3000000.00, 4500000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('44b65b3a-8350-4989-b33f-4788628cb6d0', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2028, 5, 125000.00, 3125000.00, 4375000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('c2aeefb2-2e3d-480d-b42a-b48d99c90ae0', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2028, 6, 125000.00, 3250000.00, 4250000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('7ecf66e5-2b1b-4e51-8f99-cfc994a07480', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2028, 7, 125000.00, 3375000.00, 4125000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('422838a8-2553-43b9-bb40-ed8b4586f6bd', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2028, 8, 125000.00, 3500000.00, 4000000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('df340ae3-2fae-424d-92b4-bbe0b8b1be37', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2028, 9, 125000.00, 3625000.00, 3875000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('239229b0-0e9c-41db-b589-346dc18769e6', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2028, 10, 125000.00, 3750000.00, 3750000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('46d510a7-49e6-4d21-8a1d-7cca9cacef09', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2028, 11, 125000.00, 3875000.00, 3625000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('6f5e73a9-d086-4cda-8a9a-ca21ee6c3192', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2028, 12, 125000.00, 4000000.00, 3500000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('e2c6d41a-f7c4-4558-8910-ee808b3be09b', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2029, 1, 125000.00, 4125000.00, 3375000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('10dafcd2-22e2-47dd-b545-b7f241832b23', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2029, 2, 125000.00, 4250000.00, 3250000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('24433c75-9962-4c7c-95da-875debede5d0', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2029, 3, 125000.00, 4375000.00, 3125000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('01729c21-9c3d-4280-b618-9b78b7b467a4', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2029, 4, 125000.00, 4500000.00, 3000000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('a4d56bfd-0d29-4263-84ad-260baed09cce', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2029, 5, 125000.00, 4625000.00, 2875000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('1f091d3f-8594-4d0d-9c57-3ac9e7d7421d', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2029, 6, 125000.00, 4750000.00, 2750000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('38f0a6b6-3e09-47dc-94f0-d64f67af10ac', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2029, 7, 125000.00, 4875000.00, 2625000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('f8b2eead-f6fd-4413-a4dd-0e0889991cb3', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2029, 8, 125000.00, 5000000.00, 2500000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('223dbfd8-2bed-411f-ba21-cf7f3a82565e', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2029, 9, 125000.00, 5125000.00, 2375000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('cf4f01a5-f869-462a-bf9a-173ed6d1d9ec', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2029, 10, 125000.00, 5250000.00, 2250000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('88395183-841b-496b-a94c-208cb97935a0', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2029, 11, 125000.00, 5375000.00, 2125000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('720a638a-50b0-4dc2-8111-b6b6f89884d0', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2029, 12, 125000.00, 5500000.00, 2000000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('83f5ac68-78b9-49b7-a231-c3ec78cc7862', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2030, 1, 125000.00, 5625000.00, 1875000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('f07eedea-46ec-4251-a0b1-9dc52b4eb23a', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2030, 2, 125000.00, 5750000.00, 1750000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('11f13b18-169a-40b8-8f42-31e6652a0f43', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2030, 3, 125000.00, 5875000.00, 1625000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('5cf1fb9f-8991-44be-93d8-ee1f43412662', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2030, 4, 125000.00, 6000000.00, 1500000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('31612f42-f497-4a14-8749-1e18cd1bf475', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2030, 5, 125000.00, 6125000.00, 1375000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('90251263-5bdf-45c1-b5da-ab0e5ecd96c2', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2030, 6, 125000.00, 6250000.00, 1250000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('54d084c2-1560-48f2-a831-62382d7b53c8', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2030, 7, 125000.00, 6375000.00, 1125000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('de8e3c57-74e3-4e56-94a0-0b666174c896', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2030, 8, 125000.00, 6500000.00, 1000000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('3e253b67-a090-43e9-bfaf-d57d95c356b7', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2030, 9, 125000.00, 6625000.00, 875000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('f3a0672b-2073-4ef2-9e95-2a35544b2157', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2030, 10, 125000.00, 6750000.00, 750000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('173473eb-aced-4148-8e84-e43306a5fd3a', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2030, 11, 125000.00, 6875000.00, 625000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('43c28189-94d0-400c-a66c-6df6cd28ce16', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2030, 12, 125000.00, 7000000.00, 500000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('472d087b-30c6-499b-a27d-5a6787205320', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2031, 1, 125000.00, 7125000.00, 375000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('a120c40e-c02b-4d86-94ef-3ab455307378', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2031, 2, 125000.00, 7250000.00, 250000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('16a94a76-e7bb-4201-ab65-bebbed11a512', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2031, 3, 125000.00, 7375000.00, 125000.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('a653e643-5a88-4502-9299-b47d024362af', '56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', 2031, 4, 125000.00, 7500000.00, 0.00, 'inactivo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:12:26.57401-06', '2026-05-12 12:12:45.42785-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('5e8ea3b5-99a5-480e-a6a6-89278162b7ba', 'a8395917-bc32-49d5-890f-0e88760a57b0', 2027, 2, 1250.00, 12500.00, 2500.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-14 06:46:20.497367-06', '2026-05-14 06:46:20.497367-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('74552767-7a88-4041-9d3e-5e8504b5cdf3', 'a8395917-bc32-49d5-890f-0e88760a57b0', 2027, 3, 1250.00, 13750.00, 1250.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-14 06:46:20.497367-06', '2026-05-14 06:46:20.497367-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.asset_depreciation (id, asset_id, period_year, period_month, depreciation_amount, accumulated_depreciation, book_value, status, created_by, updated_by, created_at, updated_at, client_id) VALUES ('67022042-d9d0-4ecd-bc95-2abc3bba99c4', 'a8395917-bc32-49d5-890f-0e88760a57b0', 2027, 4, 1250.00, 15000.00, 0.00, 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-14 06:46:20.497367-06', '2026-05-14 06:46:20.497367-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');


--
-- TOC entry 7437 (class 0 OID 56646)
-- Dependencies: 292
-- Data for Name: assets; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.assets (id, category_id, alias, brand, model, name, purchase_date, purchase_cost, useful_life_years, salvage_value, status, observations, created_by, updated_by, created_at, updated_at, purchase_cost_usd, plate, client_id, disposition_reason, disposition_date, disposition_notes) VALUES ('56ddc772-dfe8-44e0-9c6e-c6d4c11e6639', '79de9974-13d7-4b7c-bdbb-3f02567461b0', NULL, NULL, NULL, 'Dimax', '2026-05-12', 7500000.00, 5, 0.00, 'inactivo', NULL, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:07:09.885978-06', '2026-05-12 12:12:45.42785-06', 15000.00, 'CDCpnzv5r', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'venta', '2026-05-12', NULL);
INSERT INTO public.assets (id, category_id, alias, brand, model, name, purchase_date, purchase_cost, useful_life_years, salvage_value, status, observations, created_by, updated_by, created_at, updated_at, purchase_cost_usd, plate, client_id, disposition_reason, disposition_date, disposition_notes) VALUES ('a8395917-bc32-49d5-890f-0e88760a57b0', '89281521-9923-4680-af6d-6d254765e94b', 'Palita', NULL, NULL, 'Pala', '2026-05-12', 15000.00, 1, 0.00, 'activo', NULL, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:30:48.276099-06', '2026-05-12 12:30:48.276099-06', NULL, '1562341', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL);
INSERT INTO public.assets (id, category_id, alias, brand, model, name, purchase_date, purchase_cost, useful_life_years, salvage_value, status, observations, created_by, updated_by, created_at, updated_at, purchase_cost_usd, plate, client_id, disposition_reason, disposition_date, disposition_notes) VALUES ('85147a71-b565-41d5-9239-1d41e2a3195a', '89281521-9923-4680-af6d-6d254765e94b', 'Palincito', NULL, NULL, 'Palin', '2026-05-12', 15000.00, 1, 0.00, 'activo', NULL, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 12:35:40.883098-06', '2026-05-12 12:35:40.883098-06', 30.00, 'Wtpzwc8', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL);
INSERT INTO public.assets (id, category_id, alias, brand, model, name, purchase_date, purchase_cost, useful_life_years, salvage_value, status, observations, created_by, updated_by, created_at, updated_at, purchase_cost_usd, plate, client_id, disposition_reason, disposition_date, disposition_notes) VALUES ('e3020e89-d2db-4085-ad81-d6de1f5d9208', '89281521-9923-4680-af6d-6d254765e94b', 'asd', 'sad', 'dsa', 'sd', '2026-05-21', 4551.00, 5, 0.00, 'activo', NULL, '089c211c-3f84-4bf4-ab24-ae82ae6be122', '089c211c-3f84-4bf4-ab24-ae82ae6be122', '2026-05-21 09:01:16.993283-06', '2026-05-21 09:01:16.993283-06', 10.00, 'Wcwa7sq', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL);


--
-- TOC entry 7439 (class 0 OID 56689)
-- Dependencies: 294
-- Data for Name: calendar_activities; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.calendar_activities (id, activity_date, farm_id, lot_id, labor_type_id, status, notes, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('492f7150-cf6e-4721-b702-40ba9e3025f2', '2026-05-12 06:00:00-06', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', 'e4a6683a-6494-4ef8-92e8-5a14a6fd33bd', 'pending', 'Programado', '2026-05-12 11:25:40.579678-06', '2026-05-12 11:26:39.503934-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calendar_activities (id, activity_date, farm_id, lot_id, labor_type_id, status, notes, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('d8b41b0e-dd42-40d1-bf3e-266fa142bae0', '2026-05-12 06:00:00-06', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', NULL, '316f7705-a5a0-4e66-ab4a-17d907b76972', 'completed', NULL, '2026-05-12 11:27:24.959638-06', '2026-05-12 11:27:37.329758-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calendar_activities (id, activity_date, farm_id, lot_id, labor_type_id, status, notes, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('8c3d3f10-6c86-4d6d-9311-2868fdafcbe9', '2026-05-12 06:00:00-06', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', 'd50de255-88cb-40cd-adbd-301d69c604d8', 'pending', NULL, '2026-05-12 11:27:48.621726-06', '2026-05-12 11:27:48.621726-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calendar_activities (id, activity_date, farm_id, lot_id, labor_type_id, status, notes, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('2e084b62-8375-4158-abc3-e7e9534c0e0c', '2026-05-13 06:00:00-06', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', NULL, '0a96e9e5-efe8-4723-a3f2-92b8eb9b246e', 'completed', NULL, '2026-05-13 09:28:05.13107-06', '2026-05-13 09:28:05.13107-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calendar_activities (id, activity_date, farm_id, lot_id, labor_type_id, status, notes, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('a65714df-bf12-46da-b1d2-35e463e4bb31', '2026-05-13 06:00:00-06', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', '7e889a3f-fff5-4744-bcaf-df9805babfce', 'completed', NULL, '2026-05-13 09:28:32.459075-06', '2026-05-13 09:28:32.459075-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calendar_activities (id, activity_date, farm_id, lot_id, labor_type_id, status, notes, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('9f992e15-0749-4f7f-8604-6230a7f9cf58', '2026-05-16 06:00:00-06', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', 'dfdbcdd9-9783-452e-b59d-e40dc1da77ff', 'completed', NULL, '2026-05-14 09:44:25.723539-06', '2026-05-14 09:44:25.723539-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calendar_activities (id, activity_date, farm_id, lot_id, labor_type_id, status, notes, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('be139999-a92a-44cb-b984-33fc1e491780', '2026-04-30 06:00:00-06', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', '3ca0ca83-ec50-4165-b677-6bddd4dffa21', 'completed', NULL, '2026-05-14 10:59:27.235423-06', '2026-05-14 10:59:27.235423-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');


--
-- TOC entry 7440 (class 0 OID 56706)
-- Dependencies: 295
-- Data for Name: calibers; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.calibers (id, name, description, is_active, client_id) VALUES ('42ec95ed-6c29-413d-9d56-bd2b7a16a0a4', 'Supremo', '+ 250 gramos', true, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calibers (id, name, description, is_active, client_id) VALUES ('52b401f3-7c9c-4f72-b285-db94a092d634', 'Super extra', '210 g a 250 g', true, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calibers (id, name, description, is_active, client_id) VALUES ('828433cf-ce51-40c9-ac81-7cc4d10801fb', 'Extra', '180 g a 210 g', true, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calibers (id, name, description, is_active, client_id) VALUES ('b3da043f-3d69-4225-83f2-7fddb825ce3c', 'Extra uno', '140 g a 180 g', true, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calibers (id, name, description, is_active, client_id) VALUES ('c1fe5415-cf29-4d8f-96ec-6bd1f896c493', 'Extra dos', '120 g a 140 g', true, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calibers (id, name, description, is_active, client_id) VALUES ('3ee29246-17f0-41f1-a065-afca8666bbaa', 'Tercera', '100 g a 120 g', true, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calibers (id, name, description, is_active, client_id) VALUES ('04731a16-25a0-4167-b845-b0d55a6d7405', 'Cuarta o canica', '- 100 gramos', true, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calibers (id, name, description, is_active, client_id) VALUES ('fc53a99e-034f-4002-966c-9604f1a2ef16', 'Mancha gruesa', 'De 150 gramos para arriba', true, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calibers (id, name, description, is_active, client_id) VALUES ('82568a83-046f-49c6-a216-5630f9aaae0a', 'Mancha pequeña', '100 g a 150 g', true, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calibers (id, name, description, is_active, client_id) VALUES ('cca86be6-4445-4cad-b083-e422deaa870b', 'Devolución o desechos', 'No califica', true, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.calibers (id, name, description, is_active, client_id) VALUES ('e1c6204d-c182-48cc-8cba-0664291a4b71', 'Prueba', NULL, true, '80ee1408-ed96-4301-8d6e-f891e5db8889');


--
-- TOC entry 7441 (class 0 OID 56717)
-- Dependencies: 296
-- Data for Name: cantons; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (1, 1, 'Alajuela', '201');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (2, 1, 'San Ramón', '202');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (3, 1, 'Grecia', '203');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (4, 1, 'San Mateo', '204');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (5, 1, 'Atenas', '205');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (6, 1, 'Naranjo', '206');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (7, 1, 'Palmares', '207');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (8, 1, 'Poás', '208');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (9, 1, 'Orotina', '209');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (10, 1, 'San Carlos', '210');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (11, 1, 'Zarcero', '211');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (12, 1, 'Sarchí', '212');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (13, 1, 'Upala', '213');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (14, 1, 'Los Chiles', '214');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (15, 1, 'Guatuso', '215');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (16, 1, 'Río Cuarto', '216');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (17, 2, 'San José', '101');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (18, 2, 'Escazú', '102');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (19, 2, 'Desamparados', '103');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (20, 2, 'Puriscal', '104');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (21, 2, 'Tarrazú', '105');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (22, 2, 'Aserrí', '106');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (23, 2, 'Mora', '107');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (24, 2, 'Goicoechea', '108');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (25, 2, 'Santa Ana', '109');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (26, 2, 'Alajuelita', '110');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (27, 2, 'Vásquez de Coronado', '111');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (28, 2, 'Acosta', '112');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (29, 2, 'Tibás', '113');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (30, 2, 'Moravia', '114');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (31, 2, 'Montes de Oca', '115');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (32, 2, 'Turrubares', '116');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (33, 2, 'Dota', '117');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (34, 2, 'Curridabat', '118');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (35, 2, 'Pérez Zeledón', '119');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (36, 2, 'León Cortés Castro', '120');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (37, 3, 'Cartago', '301');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (38, 3, 'Paraíso', '302');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (39, 3, 'La Unión', '303');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (40, 3, 'Jiménez', '304');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (41, 3, 'Turrialba', '305');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (42, 3, 'Alvarado', '306');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (43, 3, 'Oreamuno', '307');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (44, 3, 'El Guarco', '308');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (45, 4, 'Heredia', '401');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (46, 4, 'Barva', '402');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (47, 4, 'Santo Domingo', '403');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (48, 4, 'Santa Bárbara', '404');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (49, 4, 'San Rafael', '405');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (50, 4, 'San Isidro', '406');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (51, 4, 'Belén', '407');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (52, 4, 'Flores', '408');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (53, 4, 'San Pablo', '409');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (54, 4, 'Sarapiquí', '410');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (55, 5, 'Liberia', '501');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (56, 5, 'Nicoya', '502');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (57, 5, 'Santa Cruz', '503');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (58, 5, 'Bagaces', '504');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (59, 5, 'Carrillo', '505');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (60, 5, 'Cañas', '506');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (61, 5, 'Abangares', '507');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (62, 5, 'Tilarán', '508');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (63, 5, 'Nandayure', '509');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (64, 5, 'La Cruz', '510');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (65, 5, 'Hojancha', '511');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (66, 6, 'Puntarenas', '601');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (67, 6, 'Esparza', '602');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (68, 6, 'Buenos Aires', '603');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (69, 6, 'Montes de Oro', '604');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (70, 6, 'Osa', '605');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (71, 6, 'Quepos', '606');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (72, 6, 'Golfito', '607');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (73, 6, 'Coto Brus', '608');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (74, 6, 'Parrita', '609');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (75, 6, 'Corredores', '610');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (76, 6, 'Garabito', '611');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (77, 7, 'Limón', '701');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (78, 7, 'Pococí', '702');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (79, 7, 'Siquirres', '703');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (80, 7, 'Talamanca', '704');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (81, 7, 'Matina', '705');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (82, 7, 'Guácimo', '706');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (83, 6, 'Monteverde', '612');
INSERT INTO public.cantons (id, province_id, name, official_code) VALUES (84, 6, 'Puerto Jiménez', '613');


--
-- TOC entry 7443 (class 0 OID 56724)
-- Dependencies: 298
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.clients (id, name, plan_id, status, created_at, license_starts_on, license_expires_on, billing_anchor_day) VALUES ('a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'Concurrency Test Client', '94c80683-d16d-40c7-bef0-49668c608963', 'active', '2026-05-05 11:23:37.951979', NULL, NULL, NULL);
INSERT INTO public.clients (id, name, plan_id, status, created_at, license_starts_on, license_expires_on, billing_anchor_day) VALUES ('80ee1408-ed96-4301-8d6e-f891e5db8889', 'Prueba', '94c80683-d16d-40c7-bef0-49668c608963', 'active', '2026-05-07 09:41:01.881641', NULL, NULL, NULL);
INSERT INTO public.clients (id, name, plan_id, status, created_at, license_starts_on, license_expires_on, billing_anchor_day) VALUES ('08545840-e851-4753-97f0-eefc09236e90', 'Ricardo', '94c80683-d16d-40c7-bef0-49668c608963', 'active', '2026-05-14 11:58:15.437104', '2026-05-22', '2026-06-21', NULL);
INSERT INTO public.clients (id, name, plan_id, status, created_at, license_starts_on, license_expires_on, billing_anchor_day) VALUES ('24d16b37-51ad-47ce-8f9d-68695ebbc0d8', 'Ricardo', '94c80683-d16d-40c7-bef0-49668c608963', 'active', '2026-05-22 09:44:35.877309', '2026-05-22', '2026-06-21', NULL);


--
-- TOC entry 7489 (class 0 OID 58686)
-- Dependencies: 344
-- Data for Name: coffee_lot_production; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.coffee_lot_production (id, client_id, lot_id, prod_date, cajuelas, notes, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('5761cd5c-b599-4eae-bcd1-c1a44ee958a8', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', '2026-05-21', 30.00, NULL, true, '2026-05-21 10:00:42.925867-06', '2026-05-21 10:00:42.925867-06', '089c211c-3f84-4bf4-ab24-ae82ae6be122', '089c211c-3f84-4bf4-ab24-ae82ae6be122');


--
-- TOC entry 7438 (class 0 OID 56675)
-- Dependencies: 293
-- Data for Name: coffee_varieties; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-000000000001', 'caturra', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'Caturra');
INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-000000000002', 'catuai_amarillo', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'Catuaí Amarillo');
INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-000000000003', 'catuai_rojo', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'Catuaí Rojo');
INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-000000000004', 'catimor', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'Catimor');
INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-000000000005', 'villa_sarchi', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'Villa Sarchí');
INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-000000000006', 'obata', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'Obatá');
INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-000000000007', 'geisha', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'Geisha');
INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-000000000008', 'bourbon', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'Bourbon');
INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-000000000009', 'typica', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'Típica');
INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-00000000000a', 'maragogipe', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'Maragogipe');
INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-00000000000b', 'pacamara', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'Pacamara');
INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-00000000000c', 'costa_rica_95', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'Costa Rica 95');
INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-00000000000d', 'ihcafe_90', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'IHCAFE 90');
INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-00000000000e', 'sarchimor', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'Sarchimor');
INSERT INTO public.coffee_varieties (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, display_name) VALUES ('b1000001-0001-4001-8001-00000000000f', 'centroamericano', true, '2026-05-21 09:43:16.751926-06', '2026-05-21 09:43:16.751926-06', NULL, NULL, 'Centroamericano F1');


--
-- TOC entry 7444 (class 0 OID 56732)
-- Dependencies: 299
-- Data for Name: districts; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (1, 1, 'Alajuela', '20101');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (2, 1, 'San José', '20102');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (3, 1, 'Carrizal', '20103');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (4, 1, 'San Antonio', '20104');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (5, 1, 'Guácima', '20105');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (6, 1, 'San Isidro', '20106');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (7, 1, 'Sabanilla', '20107');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (8, 1, 'San Rafael', '20108');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (9, 1, 'Río Segundo', '20109');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (10, 1, 'Desamparados', '20110');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (11, 1, 'Turrúcares', '20111');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (12, 1, 'Tambor', '20112');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (13, 1, 'Garita', '20113');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (14, 1, 'Sarapiquí', '20114');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (15, 2, 'San Ramón', '20201');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (16, 2, 'Santiago', '20202');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (17, 2, 'San Juan', '20203');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (18, 2, 'Piedades Norte', '20204');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (19, 2, 'Piedades Sur', '20205');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (20, 2, 'San Rafael', '20206');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (21, 2, 'San Isidro', '20207');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (22, 2, 'Ángeles', '20208');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (23, 2, 'Alfaro', '20209');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (24, 2, 'Volio', '20210');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (25, 2, 'Concepción', '20211');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (26, 2, 'Zapotal', '20212');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (27, 2, 'Peñas Blancas', '20213');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (28, 3, 'Grecia', '20301');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (29, 3, 'San Isidro', '20302');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (30, 3, 'San José', '20303');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (31, 3, 'San Roque', '20304');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (32, 3, 'Tacares', '20305');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (33, 3, 'Puente de Piedra', '20306');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (34, 3, 'Bolívar', '20307');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (35, 4, 'San Mateo', '20401');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (36, 4, 'Desmonte', '20402');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (37, 4, 'Jesús María', '20403');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (38, 5, 'Atenas', '20501');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (39, 5, 'Jesús', '20502');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (40, 5, 'Mercedes', '20503');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (41, 5, 'San Isidro', '20504');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (42, 5, 'Concepción', '20505');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (43, 5, 'San José', '20506');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (44, 5, 'Santa Eulalia', '20507');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (45, 5, 'Escobal', '20508');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (46, 6, 'Naranjo', '20601');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (47, 6, 'San Miguel', '20602');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (48, 6, 'San José', '20603');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (49, 6, 'Cirrí Sur', '20604');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (50, 6, 'San Jerónimo', '20605');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (51, 6, 'San Juan', '20606');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (52, 6, 'El Rosario', '20607');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (53, 6, 'Palmitos', '20608');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (54, 7, 'Palmares', '20701');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (55, 7, 'Zaragoza', '20702');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (56, 7, 'Buenos Aires', '20703');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (57, 7, 'Santiago', '20704');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (58, 7, 'Candelaria', '20705');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (59, 7, 'Esquipulas', '20706');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (60, 7, 'La Granja', '20707');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (61, 8, 'San Pedro', '20801');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (62, 8, 'San Juan', '20802');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (63, 8, 'San Rafael', '20803');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (64, 8, 'Carrillos', '20804');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (65, 8, 'Sabana Redonda', '20805');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (66, 9, 'Orotina', '20901');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (67, 9, 'El Mastate', '20902');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (68, 9, 'Hacienda Vieja', '20903');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (69, 9, 'Coyolar', '20904');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (70, 9, 'La Ceiba', '20905');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (71, 10, 'Quesada', '21001');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (72, 10, 'Florencia', '21002');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (73, 10, 'Buenavista', '21003');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (74, 10, 'Aguas Zarcas', '21004');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (75, 10, 'Venecia', '21005');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (76, 10, 'Pital', '21006');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (77, 10, 'La Fortuna', '21007');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (78, 10, 'La Tigra', '21008');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (79, 10, 'La Palmera', '21009');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (80, 10, 'Venado', '21010');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (81, 10, 'Cutris', '21011');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (82, 10, 'Monterrey', '21012');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (83, 10, 'Pocosol', '21013');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (84, 11, 'Zarcero', '21101');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (85, 11, 'Laguna', '21102');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (86, 11, 'Tapezco', '21103');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (87, 11, 'Guadalupe', '21104');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (88, 11, 'Palmira', '21105');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (89, 11, 'Zapote', '21106');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (90, 11, 'Brisas', '21107');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (91, 12, 'Sarchí Norte', '21201');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (92, 12, 'Sarchí Sur', '21202');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (93, 12, 'Toro Amarillo', '21203');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (94, 12, 'San Pedro', '21204');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (95, 12, 'Rodríguez', '21205');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (96, 13, 'Upala', '21301');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (97, 13, 'Aguas Claras', '21302');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (98, 13, 'San José o Pizote', '21303');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (99, 13, 'Bijagua', '21304');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (100, 13, 'Delicias', '21305');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (101, 13, 'Dos Ríos', '21306');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (102, 13, 'Yolillal', '21307');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (103, 13, 'Canalete', '21308');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (104, 14, 'Los Chiles', '21401');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (105, 14, 'Caño Negro', '21402');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (106, 14, 'El Amparo', '21403');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (107, 14, 'San Jorge', '21404');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (108, 15, 'San Rafael', '21501');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (109, 15, 'Buenavista', '21502');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (110, 15, 'Cote', '21503');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (111, 15, 'Katira', '21504');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (112, 16, 'Río Cuarto', '21601');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (113, 16, 'Santa Rita', '21602');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (114, 16, 'Santa Isabel', '21603');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (115, 17, 'Carmen', '10101');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (116, 17, 'Merced', '10102');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (117, 17, 'Hospital', '10103');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (118, 17, 'Catedral', '10104');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (119, 17, 'Zapote', '10105');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (120, 17, 'San Francisco de Dos Ríos', '10106');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (121, 17, 'Uruca', '10107');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (122, 17, 'Mata Redonda', '10108');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (123, 17, 'Pavas', '10109');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (124, 17, 'Hatillo', '10110');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (125, 17, 'San Sebastián', '10111');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (126, 18, 'Escazú', '10201');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (127, 18, 'San Antonio', '10202');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (128, 18, 'San Rafael', '10203');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (129, 19, 'Desamparados', '10301');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (130, 19, 'San Miguel', '10302');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (131, 19, 'San Juan de Dios', '10303');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (132, 19, 'San Rafael Arriba', '10304');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (133, 19, 'San Antonio', '10305');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (134, 19, 'Frailes', '10306');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (135, 19, 'Patarrá', '10307');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (136, 19, 'San Cristóbal', '10308');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (137, 19, 'Rosario', '10309');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (138, 19, 'Damas', '10310');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (139, 19, 'San Rafael Abajo', '10311');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (140, 19, 'Gravilias', '10312');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (141, 19, 'Los Guido', '10313');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (142, 20, 'Santiago', '10401');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (143, 20, 'Mercedes Sur', '10402');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (144, 20, 'Barbacoas', '10403');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (145, 20, 'Grifo Alto', '10404');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (146, 20, 'San Rafael', '10405');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (147, 20, 'Candelarita', '10406');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (148, 20, 'Desamparaditos', '10407');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (149, 20, 'San Antonio', '10408');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (150, 20, 'Chires', '10409');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (151, 21, 'San Marcos', '10501');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (152, 21, 'San Lorenzo', '10502');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (153, 21, 'San Carlos', '10503');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (154, 22, 'Aserrí', '10601');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (155, 22, 'Tarbaca', '10602');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (156, 22, 'Vuelta de Jorco', '10603');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (157, 22, 'San Gabriel', '10604');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (158, 22, 'Legua', '10605');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (159, 22, 'Monterrey', '10606');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (160, 22, 'Salitrillos', '10607');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (161, 23, 'Colón', '10701');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (162, 23, 'Guayabo', '10702');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (163, 23, 'Tabarcia', '10703');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (164, 23, 'Piedras Negras', '10704');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (165, 23, 'Picagres', '10705');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (166, 23, 'Jaris', '10706');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (167, 23, 'Quitirrisí', '10707');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (168, 24, 'Guadalupe', '10801');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (169, 24, 'San Francisco', '10802');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (170, 24, 'Calle Blancos', '10803');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (171, 24, 'Mata de Plátano', '10804');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (172, 24, 'Ipís', '10805');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (173, 24, 'Rancho Redondo', '10806');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (174, 24, 'Purral', '10807');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (175, 25, 'Santa Ana', '10901');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (176, 25, 'Salitral', '10902');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (177, 25, 'Pozos', '10903');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (178, 25, 'Uruca', '10904');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (179, 25, 'Piedades', '10905');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (180, 25, 'Brasil', '10906');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (181, 26, 'Alajuelita', '11001');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (182, 26, 'San Josecito', '11002');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (183, 26, 'San Antonio', '11003');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (184, 26, 'Concepción', '11004');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (185, 26, 'San Felipe', '11005');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (186, 27, 'San Isidro', '11101');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (187, 27, 'San Rafael', '11102');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (188, 27, 'Dulce Nombre de Jesús', '11103');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (189, 27, 'Patalillo', '11104');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (190, 27, 'Cascajal', '11105');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (191, 28, 'San Ignacio', '11201');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (192, 28, 'Guaitil', '11202');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (193, 28, 'Palmichal', '11203');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (194, 28, 'Cangrejal', '11204');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (195, 28, 'Sabanillas', '11205');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (196, 29, 'San Juan', '11301');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (197, 29, 'Cinco Esquinas', '11302');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (198, 29, 'Anselmo Llorente', '11303');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (199, 29, 'León XIII', '11304');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (200, 29, 'Colima', '11305');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (201, 30, 'San Vicente', '11401');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (202, 30, 'San Jerónimo', '11402');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (203, 30, 'Trinidad', '11403');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (204, 31, 'San Pedro', '11501');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (205, 31, 'Sabanilla', '11502');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (206, 31, 'Mercedes', '11503');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (207, 31, 'San Rafael', '11504');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (208, 32, 'San Pablo', '11601');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (209, 32, 'San Pedro', '11602');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (210, 32, 'San Juan de Mata', '11603');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (211, 32, 'San Luis', '11604');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (212, 32, 'Carara', '11605');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (213, 33, 'Santa María', '11701');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (214, 33, 'Jardín', '11702');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (215, 33, 'Copey', '11703');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (216, 34, 'Curridabat', '11801');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (217, 34, 'Granadilla', '11802');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (218, 34, 'Sánchez', '11803');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (219, 34, 'Tirrases', '11804');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (220, 35, 'San Isidro de El General', '11901');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (221, 35, 'El General', '11902');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (222, 35, 'Daniel Flores', '11903');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (223, 35, 'Rivas', '11904');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (224, 35, 'San Pedro', '11905');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (225, 35, 'Platanares', '11906');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (226, 35, 'Pejibaye', '11907');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (227, 35, 'Cajón', '11908');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (228, 35, 'Barú', '11909');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (229, 35, 'Río Nuevo', '11910');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (230, 35, 'Páramo', '11911');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (231, 35, 'La Amistad', '11912');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (232, 36, 'San Pablo', '12001');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (233, 36, 'San Andrés', '12002');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (234, 36, 'Llano Bonito', '12003');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (235, 36, 'San Isidro', '12004');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (236, 36, 'Santa Cruz', '12005');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (237, 36, 'San Antonio', '12006');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (238, 37, 'Oriental', '30101');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (239, 37, 'Occidental', '30102');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (240, 37, 'Carmen', '30103');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (241, 37, 'San Nicolás', '30104');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (242, 37, 'Aguacaliente o San Francisco', '30105');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (243, 37, 'Guadalupe o Arenilla', '30106');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (244, 37, 'Corralillo', '30107');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (245, 37, 'Tierra Blanca', '30108');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (246, 37, 'Dulce Nombre', '30109');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (247, 37, 'Llano Grande', '30110');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (248, 37, 'Quebradilla', '30111');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (249, 38, 'Paraíso', '30201');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (250, 38, 'Santiago', '30202');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (251, 38, 'Orosi', '30203');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (252, 38, 'Cachí', '30204');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (253, 38, 'Llanos de Santa Lucía', '30205');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (254, 38, 'Birrisito', '30206');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (255, 39, 'Tres Ríos', '30301');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (256, 39, 'San Diego', '30302');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (257, 39, 'San Juan', '30303');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (258, 39, 'San Rafael', '30304');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (259, 39, 'Concepción', '30305');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (260, 39, 'Dulce Nombre', '30306');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (261, 39, 'San Ramón', '30307');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (262, 39, 'Río Azul', '30308');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (263, 40, 'Juan Viñas', '30401');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (264, 40, 'Tucurrique', '30402');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (265, 40, 'Pejibaye', '30403');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (266, 41, 'Turrialba', '30501');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (267, 41, 'La Suiza', '30502');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (268, 41, 'Peralta', '30503');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (269, 41, 'Santa Cruz', '30504');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (270, 41, 'Santa Teresita', '30505');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (271, 41, 'Pavones', '30506');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (272, 41, 'Tuis', '30507');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (273, 41, 'Tayutic', '30508');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (274, 41, 'Santa Rosa', '30509');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (275, 41, 'Tres Equis', '30510');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (276, 41, 'La Isabel', '30511');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (277, 41, 'Chirripó', '30512');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (278, 42, 'Pacayas', '30601');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (279, 42, 'Cervantes', '30602');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (280, 42, 'Capellades', '30603');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (281, 43, 'San Rafael', '30701');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (282, 43, 'Cot', '30702');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (283, 43, 'Potrero Cerrado', '30703');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (284, 43, 'Cipreses', '30704');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (285, 43, 'Santa Rosa', '30705');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (286, 44, 'El Tejar', '30801');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (287, 44, 'San Isidro', '30802');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (288, 44, 'Tobosi', '30803');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (289, 44, 'Patio de Agua', '30804');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (290, 45, 'Heredia', '40101');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (291, 45, 'Mercedes', '40102');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (292, 45, 'San Francisco', '40103');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (293, 45, 'Ulloa', '40104');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (294, 45, 'Varablanca', '40105');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (295, 46, 'Barva', '40201');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (296, 46, 'San Pedro', '40202');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (297, 46, 'San Pablo', '40203');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (298, 46, 'San Roque', '40204');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (299, 46, 'Santa Lucía', '40205');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (300, 46, 'San José de la Montaña', '40206');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (301, 47, 'Santo Domingo', '40301');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (302, 47, 'San Vicente', '40302');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (303, 47, 'San Miguel', '40303');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (304, 47, 'Paracito', '40304');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (305, 47, 'Santo Tomás', '40305');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (306, 47, 'Santa Rosa', '40306');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (307, 47, 'Tures', '40307');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (308, 47, 'Pará', '40308');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (309, 48, 'Santa Bárbara', '40401');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (310, 48, 'San Pedro', '40402');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (311, 48, 'San Juan', '40403');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (312, 48, 'Jesús', '40404');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (313, 48, 'Santo Domingo', '40405');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (314, 48, 'Purabá', '40406');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (315, 49, 'San Rafael', '40501');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (316, 49, 'San Josecito', '40502');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (317, 49, 'Santiago', '40503');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (318, 49, 'Ángeles', '40504');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (319, 49, 'Concepción', '40505');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (320, 50, 'San Isidro', '40601');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (321, 50, 'San José', '40602');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (322, 50, 'Concepción', '40603');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (323, 50, 'San Francisco', '40604');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (324, 51, 'San Antonio', '40701');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (325, 51, 'La Ribera', '40702');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (326, 51, 'La Asunción', '40703');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (327, 52, 'San Joaquín', '40801');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (328, 52, 'Barrantes', '40802');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (329, 52, 'Llorente', '40803');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (330, 53, 'San Pablo', '40901');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (331, 53, 'Rincón de Sabanilla', '40902');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (332, 54, 'Puerto Viejo', '41001');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (333, 54, 'La Virgen', '41002');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (334, 54, 'Las Horquetas', '41003');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (335, 54, 'Llanuras del Gaspar', '41004');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (336, 54, 'Cureña', '41005');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (337, 55, 'Liberia', '50101');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (338, 55, 'Cañas Dulces', '50102');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (339, 55, 'Mayorga', '50103');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (340, 55, 'Nacascolo', '50104');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (341, 55, 'Curubandé', '50105');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (342, 56, 'Nicoya', '50201');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (343, 56, 'Mansión', '50202');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (344, 56, 'San Antonio', '50203');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (345, 56, 'Quebrada Honda', '50204');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (346, 56, 'Sámara', '50205');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (347, 56, 'Nosara', '50206');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (348, 56, 'Belén de Nosarita', '50207');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (349, 57, 'Santa Cruz', '50301');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (350, 57, 'Bolsón', '50302');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (351, 57, 'Veintisiete de Abril', '50303');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (352, 57, 'Tempate', '50304');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (353, 57, 'Cartagena', '50305');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (354, 57, 'Cuajiniquil', '50306');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (355, 57, 'Diriá', '50307');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (356, 57, 'Cabo Velas', '50308');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (357, 57, 'Tamarindo', '50309');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (358, 58, 'Bagaces', '50401');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (359, 58, 'La Fortuna', '50402');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (360, 58, 'Mogote', '50403');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (361, 58, 'Río Naranjo', '50404');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (362, 59, 'Filadelfia', '50501');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (363, 59, 'Palmira', '50502');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (364, 59, 'Sardinal', '50503');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (365, 59, 'Belén', '50504');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (366, 60, 'Cañas', '50601');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (367, 60, 'Palmira', '50602');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (368, 60, 'San Miguel', '50603');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (369, 60, 'Bebedero', '50604');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (370, 60, 'Porozal', '50605');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (371, 61, 'Las Juntas', '50701');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (372, 61, 'Sierra', '50702');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (373, 61, 'San Juan', '50703');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (374, 61, 'Colorado', '50704');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (375, 62, 'Tilarán', '50801');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (376, 62, 'Quebrada Grande', '50802');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (377, 62, 'Tronadora', '50803');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (378, 62, 'Santa Rosa', '50804');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (379, 62, 'Líbano', '50805');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (380, 62, 'Tierras Morenas', '50806');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (381, 62, 'Arenal', '50807');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (382, 62, 'Cabeceras', '50808');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (383, 63, 'Carmona', '50901');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (384, 63, 'Santa Rita', '50902');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (385, 63, 'Zapotal', '50903');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (386, 63, 'San Pablo', '50904');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (387, 63, 'Porvenir', '50905');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (388, 63, 'Bejuco', '50906');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (389, 64, 'La Cruz', '51001');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (390, 64, 'Santa Cecilia', '51002');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (391, 64, 'La Garita', '51003');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (392, 64, 'Santa Elena', '51004');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (393, 65, 'Hojancha', '51101');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (394, 65, 'Monte Romo', '51102');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (395, 65, 'Puerto Carrillo', '51103');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (396, 65, 'Huacas', '51104');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (397, 65, 'Matambú', '51105');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (398, 66, 'Puntarenas', '60101');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (399, 66, 'Pitahaya', '60102');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (400, 66, 'Chomes', '60103');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (401, 66, 'Lepanto', '60104');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (402, 66, 'Paquera', '60105');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (403, 66, 'Manzanillo', '60106');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (404, 66, 'Guacimal', '60107');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (405, 66, 'Barranca', '60108');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (406, 66, 'Monte Verde', '60109');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (407, 66, 'Isla del Coco', '60110');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (408, 66, 'Cóbano', '60111');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (409, 66, 'Chacarita', '60112');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (410, 66, 'Chira', '60113');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (411, 66, 'Acapulco', '60114');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (412, 66, 'El Roble', '60115');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (413, 66, 'Arancibia', '60116');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (414, 67, 'Espíritu Santo', '60201');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (415, 67, 'San Juan Grande', '60202');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (416, 67, 'Macacona', '60203');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (417, 67, 'San Rafael', '60204');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (418, 67, 'San Jerónimo', '60205');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (419, 68, 'Buenos Aires', '60301');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (420, 68, 'Volcán', '60302');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (421, 68, 'Potrero Grande', '60303');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (422, 68, 'Boruca', '60304');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (423, 68, 'Pilas', '60305');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (424, 68, 'Colinas', '60306');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (425, 68, 'Chánguena', '60307');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (426, 68, 'Biolley', '60308');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (427, 68, 'Brunka', '60309');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (428, 69, 'Miramar', '60401');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (429, 69, 'La Unión', '60402');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (430, 69, 'San Isidro', '60403');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (431, 70, 'Puerto Cortés', '60501');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (432, 70, 'Palmar', '60502');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (433, 70, 'Sierpe', '60503');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (434, 70, 'Bahía Ballena', '60504');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (435, 70, 'Piedras Blancas', '60505');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (436, 70, 'Bahía Drake', '60506');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (437, 71, 'Quepos', '60601');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (438, 71, 'Savegre', '60602');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (439, 71, 'Naranjito', '60603');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (440, 72, 'Golfito', '60701');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (441, 72, 'Puerto Jiménez', '60702');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (442, 72, 'Guaycará', '60703');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (443, 72, 'Pavón', '60704');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (444, 73, 'San Vito', '60801');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (445, 73, 'Sabalito', '60802');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (446, 73, 'Aguabuena', '60803');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (447, 73, 'Limoncito', '60804');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (448, 73, 'Pittier', '60805');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (449, 73, 'Gutiérrez Braun', '60806');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (450, 74, 'Parrita', '60901');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (451, 75, 'Corredor', '61001');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (452, 75, 'La Cuesta', '61002');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (453, 75, 'Canoas', '61003');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (454, 75, 'Laurel', '61004');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (455, 76, 'Jacó', '61101');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (456, 76, 'Tárcoles', '61102');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (457, 77, 'Limón', '70101');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (458, 77, 'Valle La Estrella', '70102');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (459, 77, 'Río Blanco', '70103');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (460, 77, 'Matama', '70104');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (461, 78, 'Guápiles', '70201');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (462, 78, 'Jiménez', '70202');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (463, 78, 'Rita', '70203');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (464, 78, 'Roxana', '70204');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (465, 78, 'Cariari', '70205');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (466, 78, 'Colorado', '70206');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (467, 78, 'La Colonia', '70207');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (468, 79, 'Siquirres', '70301');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (469, 79, 'Pacuarito', '70302');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (470, 79, 'Florida', '70303');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (471, 79, 'Germania', '70304');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (472, 79, 'El Cairo', '70305');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (473, 79, 'Alegría', '70306');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (474, 79, 'Reventazón', '70307');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (475, 80, 'Bratsi', '70401');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (476, 80, 'Sixaola', '70402');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (477, 80, 'Cahuita', '70403');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (478, 80, 'Telire', '70404');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (479, 81, 'Matina', '70501');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (480, 81, 'Batán', '70502');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (481, 81, 'Carrandi', '70503');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (482, 82, 'Guácimo', '70601');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (483, 82, 'Mercedes', '70602');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (484, 82, 'Pocora', '70603');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (485, 82, 'Río Jiménez', '70604');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (486, 82, 'Duacarí', '70605');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (487, 83, 'Monteverde', '61201');
INSERT INTO public.districts (id, canton_id, name, official_code) VALUES (488, 84, 'Puerto Jiménez', '61301');


--
-- TOC entry 7446 (class 0 OID 56739)
-- Dependencies: 301
-- Data for Name: expense_categories; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.expense_categories (id, client_id, name, name_norm, status, created_by, updated_by, created_at, updated_at) VALUES ('df02d442-f1ac-492f-b0f0-00af1b00f6cc', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'Combustible', 'combustible', 'activo', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-12 15:00:29.153751-06', '2026-05-12 15:00:29.153751-06');


--
-- TOC entry 7447 (class 0 OID 56756)
-- Dependencies: 302
-- Data for Name: expenses; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.expenses (id, lot_id, harvest_id, exp_date, description, amount, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, currency, fx_rate, amount_input, amount_crc, amount_usd, client_id, category_id) VALUES ('dc44286d-bc0f-4d35-8a3b-7286c825b15c', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', NULL, '2026-05-12', 'Gasolina chapia', 7500.00, '2026-05-12 15:01:14.33538-06', true, '2026-05-12 15:01:14.33538-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'USD', 500.000000, 15.00, 7500.00, 15.00, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'df02d442-f1ac-492f-b0f0-00af1b00f6cc');
INSERT INTO public.expenses (id, lot_id, harvest_id, exp_date, description, amount, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, currency, fx_rate, amount_input, amount_crc, amount_usd, client_id, category_id) VALUES ('b878b97e-a568-4fde-8f9d-c65be5ff8fbf', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', NULL, '2026-05-21', NULL, 6826.50, '2026-05-21 09:00:32.116795-06', true, '2026-05-21 09:00:32.116795-06', '089c211c-3f84-4bf4-ab24-ae82ae6be122', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'USD', 455.100000, 15.00, 6826.50, 15.00, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'df02d442-f1ac-492f-b0f0-00af1b00f6cc');


--
-- TOC entry 7448 (class 0 OID 56780)
-- Dependencies: 303
-- Data for Name: farm_harvest_estimates; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 7449 (class 0 OID 56792)
-- Dependencies: 304
-- Data for Name: farms; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.farms (id, name, location, created_at, is_active, deactivated_at, location_geom, created_by_user_id, updated_by_user_id, geom, updated_at, area_ha, labor_allocation_mode, client_id, province_id, canton_id, district_id, community) VALUES ('6771d0bf-09c0-4b32-afd3-b3ed94bf85e7', 'Prueba', NULL, '2026-05-07 10:30:24.191258-06', true, NULL, NULL, '89e2b58e-057c-4f7b-908b-30d1086c076d', '89e2b58e-057c-4f7b-908b-30d1086c076d', NULL, '2026-05-07 10:30:24.191258-06', 0.0000, 'manual', '80ee1408-ed96-4301-8d6e-f891e5db8889', NULL, NULL, NULL, NULL);
INSERT INTO public.farms (id, name, location, created_at, is_active, deactivated_at, location_geom, created_by_user_id, updated_by_user_id, geom, updated_at, area_ha, labor_allocation_mode, client_id, province_id, canton_id, district_id, community) VALUES ('6fba7ade-b2e6-4195-be3b-86639c87f681', 'Prueba 2', 'Cartago', '2026-05-06 10:57:18.546695-06', false, '2026-05-15 06:23:01.22078-06', NULL, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, '2026-05-15 06:23:01.22078-06', 5.0000, 'manual', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);
INSERT INTO public.farms (id, name, location, created_at, is_active, deactivated_at, location_geom, created_by_user_id, updated_by_user_id, geom, updated_at, area_ha, labor_allocation_mode, client_id, province_id, canton_id, district_id, community) VALUES ('14cb1ab3-8cbf-40ca-b41c-1c2e4e5536ab', 'Vera', NULL, '2026-05-15 06:23:15.962751-06', true, NULL, NULL, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, '2026-05-15 06:23:15.962751-06', 0.0000, 'manual', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 3, 39, 256, 'fsf');
INSERT INTO public.farms (id, name, location, created_at, is_active, deactivated_at, location_geom, created_by_user_id, updated_by_user_id, geom, updated_at, area_ha, labor_allocation_mode, client_id, province_id, canton_id, district_id, community) VALUES ('b7642e09-5cfc-4625-b2f9-d093172ea0ff', 'El Cedral', 'Cartago', '2026-05-06 09:06:19.721724-06', true, NULL, NULL, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, '2026-05-21 11:55:05.837131-06', 5.0000, 'manual', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 3, 37, 244, NULL);


--
-- TOC entry 7450 (class 0 OID 56812)
-- Dependencies: 305
-- Data for Name: fixed_payroll; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 7451 (class 0 OID 56859)
-- Dependencies: 306
-- Data for Name: fixed_payroll_allocations; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 7452 (class 0 OID 56873)
-- Dependencies: 307
-- Data for Name: general_expense_allocations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.general_expense_allocations (id, general_expense_id, lot_id, allocation_basis, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('ecde889c-702b-42e0-926c-f51399008bdd', '6898e622-94ea-4057-bf8f-f62277efbd63', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', 'manual', 25.000, 1250.00, '2026-05-12 15:02:29.509529-06', '2026-05-13 09:00:07.483368-06', true);
INSERT INTO public.general_expense_allocations (id, general_expense_id, lot_id, allocation_basis, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('628a4a1a-84ab-4ca6-8055-d8eb068494c5', '6898e622-94ea-4057-bf8f-f62277efbd63', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', 'manual', 75.000, 3750.00, '2026-05-12 15:02:29.509529-06', '2026-05-13 09:00:10.495702-06', true);


--
-- TOC entry 7453 (class 0 OID 56892)
-- Dependencies: 308
-- Data for Name: general_expenses; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.general_expenses (id, farm_id, harvest_id, exp_date, description, amount, allocation_method, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, currency, fx_rate, amount_input, amount_crc, client_id, category_id, amount_usd) VALUES ('6898e622-94ea-4057-bf8f-f62277efbd63', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', NULL, '2026-05-12', NULL, 5000.00, 'manual', true, '2026-05-12 15:02:25.16339-06', '2026-05-12 15:02:25.16339-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'CRC', NULL, 5000.00, 5000.00, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'df02d442-f1ac-492f-b0f0-00af1b00f6cc', NULL);


--
-- TOC entry 7454 (class 0 OID 56917)
-- Dependencies: 309
-- Data for Name: harvests; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.harvests (id, name, start_date, end_date, created_by_user_id, created_at, is_active, updated_at, price_per_fanega, currency, updated_by_user_id, client_id, price_per_fanega_usd, price_fx_rate) VALUES ('667aa2bf-0489-403d-b25d-f3eb0908f79e', 'Cosecha 2025 - 2026', '2025-01-01', '2026-12-31', '089c211c-3f84-4bf4-ab24-ae82ae6be122', '2026-05-21 10:29:07.261923-06', true, '2026-05-21 10:29:07.261923-06', 50000.00, 'CRC', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL);
INSERT INTO public.harvests (id, name, start_date, end_date, created_by_user_id, created_at, is_active, updated_at, price_per_fanega, currency, updated_by_user_id, client_id, price_per_fanega_usd, price_fx_rate) VALUES ('99ec13df-4324-420c-904e-ea357c05d251', 'Cosecha 2026 - 2027', '2027-01-01', '2027-12-31', '089c211c-3f84-4bf4-ab24-ae82ae6be122', '2026-05-21 10:33:15.668974-06', true, '2026-05-21 10:33:15.668974-06', 10000.00, 'CRC', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL);


--
-- TOC entry 7455 (class 0 OID 56936)
-- Dependencies: 310
-- Data for Name: inventory_brands; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.inventory_brands (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('0bf47a7a-0257-4111-86d3-418cfacb0a94', 'Disagro', true, '2026-05-11 10:07:50.709106-06', '2026-05-11 10:07:50.709106-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_brands (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('66280bcd-d48d-47d4-8229-00dccf74bb9c', 'Enlasa', true, '2026-05-07 11:08:09.878289-06', '2026-05-07 11:08:09.878289-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_brands (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('faa33bf4-b44c-4112-9c9d-383ede7396ca', 'Yara', true, '2026-05-11 10:06:50.484531-06', '2026-05-11 10:06:50.484531-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_brands (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('c946dc92-57cf-48e3-913f-201a28f5921b', 'Bayern', true, '2026-05-07 11:03:44.092168-06', '2026-05-07 11:03:57.304783-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_brands (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('a46fa769-e499-424e-8216-6f47717e5b51', 'Bayer', true, '2026-05-14 06:51:59.781501-06', '2026-05-14 06:51:59.781501-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_brands (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('e455d50e-04cf-4ab6-854d-9b8c6d223e1b', 'Prueba', true, '2026-05-15 14:53:26.764556-06', '2026-05-15 14:53:26.764556-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');


--
-- TOC entry 7456 (class 0 OID 56952)
-- Dependencies: 311
-- Data for Name: inventory_categories; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('8ffe555d-5a44-4ea6-aa45-e07e47cfbeef', 'Adherente', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);
INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('5c1cce5b-fe3e-4c48-b362-6577bff69ce0', 'Bioinsumo', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);
INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('e2a22768-e648-4d9a-acd5-b31693c7dbe1', 'Coadyuvante', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);
INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('3374a907-871d-413d-adf6-bab6c9067433', 'Corrector', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);
INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('834e30f2-f770-4711-9220-0e5c4766f24c', 'Enmienda', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);
INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('95d7932f-0e74-4461-9682-4a3a94b03297', 'Fertilizante', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);
INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('666e4f2a-0517-4b9d-ad87-1a8ddcc4ce7a', 'Foliar', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);
INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('502d2604-d7ec-4d12-a1ae-760943b669ae', 'Fungicida', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);
INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('bec4771d-16f9-478c-b29a-bfe695d41bc2', 'Herbicida', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);
INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('1b046c38-9d2e-4ca4-a35e-47966d2ec998', 'Insecticida', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);
INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('33d4426b-6509-4d41-94f4-8060d75a47ce', 'Materia orgánica', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);
INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('8286e29d-8e60-477b-b5a7-5a90fae182db', 'Nematicida', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);
INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('24ed56f9-0f7a-4077-b887-04ff666fcf26', 'Otros', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);
INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('a3719857-0188-46aa-83d4-b113173e05c8', 'Plantas', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);
INSERT INTO public.inventory_categories (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('e115ed54-b524-4dab-b061-f6e9ef272111', 'Semillas', true, '2026-05-07 11:07:25.491887-06', '2026-05-07 11:07:25.491887-06', NULL, NULL);


--
-- TOC entry 7457 (class 0 OID 56967)
-- Dependencies: 312
-- Data for Name: inventory_consumption_layers; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.inventory_consumption_layers (id, consumption_id, layer_id, qty_used, unit_cost, created_at) VALUES ('9283f674-f99d-480a-ab86-c99b170dd782', '56a3f388-42b0-4435-8f6c-205067e94a2c', '205d653a-ecd5-4568-a997-7a625cb35c72', 0.050, 1000000.00, '2026-05-12 10:25:17.695005-06');
INSERT INTO public.inventory_consumption_layers (id, consumption_id, layer_id, qty_used, unit_cost, created_at) VALUES ('844bbf20-e1fb-4d0b-8600-f794366849b5', '56a3f388-42b0-4435-8f6c-205067e94a2c', '6f82ebe9-f16d-4bc6-9b78-eaadb8343d52', 0.050, 1690.50, '2026-05-12 10:25:17.695005-06');
INSERT INTO public.inventory_consumption_layers (id, consumption_id, layer_id, qty_used, unit_cost, created_at) VALUES ('6d18f2c7-44c8-4982-a4ec-d0b0b9fd763b', '9c3b7b7a-13b2-4147-9cdb-04b6b0cf92b9', 'b5215596-b96b-4faa-a788-86adad57cd91', 0.050, 50000.00, '2026-05-12 10:25:17.695005-06');
INSERT INTO public.inventory_consumption_layers (id, consumption_id, layer_id, qty_used, unit_cost, created_at) VALUES ('87310718-d74e-4773-84e1-cde40736d4e1', '02772aa5-f3d5-4733-a126-5894ed45fa37', '6f82ebe9-f16d-4bc6-9b78-eaadb8343d52', 1.000, 1690.50, '2026-05-12 10:36:39.335202-06');
INSERT INTO public.inventory_consumption_layers (id, consumption_id, layer_id, qty_used, unit_cost, created_at) VALUES ('2a252486-c69c-47f2-b05d-bfc2fe3a179d', '474b5b2f-7da0-4e69-bdf4-1ada51e48768', '6f82ebe9-f16d-4bc6-9b78-eaadb8343d52', 1.000, 1690.50, '2026-05-12 10:36:39.335202-06');
INSERT INTO public.inventory_consumption_layers (id, consumption_id, layer_id, qty_used, unit_cost, created_at) VALUES ('047e049f-b4ec-4126-93e6-a9007de1b6fe', '626c3b56-7aaf-45e9-b09b-cfb532a0407c', 'c95577ba-048b-4ac9-82db-99d24caf984e', 1.417, 250.00, '2026-05-12 10:38:14.779016-06');
INSERT INTO public.inventory_consumption_layers (id, consumption_id, layer_id, qty_used, unit_cost, created_at) VALUES ('483eb0f5-f5b2-40d6-9dd1-fe4a81849746', '309d1317-b417-42eb-be2f-253a264f0cef', '6f82ebe9-f16d-4bc6-9b78-eaadb8343d52', 2.218, 1690.50, '2026-05-12 10:38:14.779016-06');
INSERT INTO public.inventory_consumption_layers (id, consumption_id, layer_id, qty_used, unit_cost, created_at) VALUES ('5c6220ef-839c-4ab2-941d-3e8c76a417c4', 'cb6a8b10-cfc8-4370-8a10-019fe3e823c2', '6f82ebe9-f16d-4bc6-9b78-eaadb8343d52', 0.060, 1690.50, '2026-05-12 11:00:42.563606-06');
INSERT INTO public.inventory_consumption_layers (id, consumption_id, layer_id, qty_used, unit_cost, created_at) VALUES ('d7165968-ea2f-4c19-9ab1-39c042e93a30', '7000b3b8-df6c-4b77-a1ea-9f694147f8d3', '061cd708-8af4-48e8-8f49-f549bcb04cc6', 7.500, 10000.00, '2026-05-14 07:26:03.414761-06');
INSERT INTO public.inventory_consumption_layers (id, consumption_id, layer_id, qty_used, unit_cost, created_at) VALUES ('123e7d8e-b65c-401e-be18-df6ef8de41f0', '0e717f6e-3908-4c81-9b53-1d294349638b', '73e02751-1cec-4312-93bc-e902a29d1b4d', 2.000, 27500.00, '2026-05-14 07:26:03.414761-06');
INSERT INTO public.inventory_consumption_layers (id, consumption_id, layer_id, qty_used, unit_cost, created_at) VALUES ('7ac9fd9e-b983-48c7-8421-9170f90f0c8f', '7d978159-a938-462a-b383-917d51f4b47d', 'c587176b-fcdb-4feb-bf5d-f646648a8552', 10.000, 3750.00, '2026-05-14 07:26:03.414761-06');
INSERT INTO public.inventory_consumption_layers (id, consumption_id, layer_id, qty_used, unit_cost, created_at) VALUES ('088c05fe-69c4-4e1b-83ae-07e2b440ab07', 'f106169e-9f79-4a73-9f82-dfef1880b08b', 'c587176b-fcdb-4feb-bf5d-f646648a8552', 10.000, 3750.00, '2026-05-15 14:53:27.31547-06');


--
-- TOC entry 7458 (class 0 OID 56981)
-- Dependencies: 313
-- Data for Name: inventory_consumptions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.inventory_consumptions (id, lot_id, harvest_id, expense_id, item_id, cons_date, qty, unit_cost_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, mix_application_id, application_group_id, cost_scope, farm_id) VALUES ('56a3f388-42b0-4435-8f6c-205067e94a2c', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', NULL, NULL, '49e41293-45f7-4ef2-a8a2-639d39aa104a', '2026-05-12', 0.100, 500845.30, NULL, '2026-05-12 10:25:17.695005-06', true, '2026-05-12 10:25:17.695005-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '221f32a6-968b-4221-bf8d-05fd6f37c29a', NULL, 'lot', NULL);
INSERT INTO public.inventory_consumptions (id, lot_id, harvest_id, expense_id, item_id, cons_date, qty, unit_cost_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, mix_application_id, application_group_id, cost_scope, farm_id) VALUES ('9c3b7b7a-13b2-4147-9cdb-04b6b0cf92b9', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', NULL, NULL, '7f9b6417-43e0-45ff-98f7-4d81e2744504', '2026-05-12', 0.050, 50000.00, NULL, '2026-05-12 10:25:17.695005-06', true, '2026-05-12 10:25:17.695005-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '221f32a6-968b-4221-bf8d-05fd6f37c29a', NULL, 'lot', NULL);
INSERT INTO public.inventory_consumptions (id, lot_id, harvest_id, expense_id, item_id, cons_date, qty, unit_cost_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, mix_application_id, application_group_id, cost_scope, farm_id) VALUES ('02772aa5-f3d5-4733-a126-5894ed45fa37', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', NULL, NULL, '49e41293-45f7-4ef2-a8a2-639d39aa104a', '2026-05-12', 1.000, 1690.50, NULL, '2026-05-12 10:36:39.335202-06', true, '2026-05-12 10:36:39.335202-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, 'ba3066ca-29bc-4e21-8895-834e73a2f515', 'farm', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff');
INSERT INTO public.inventory_consumptions (id, lot_id, harvest_id, expense_id, item_id, cons_date, qty, unit_cost_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, mix_application_id, application_group_id, cost_scope, farm_id) VALUES ('474b5b2f-7da0-4e69-bdf4-1ada51e48768', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', NULL, NULL, '49e41293-45f7-4ef2-a8a2-639d39aa104a', '2026-05-12', 1.000, 1690.50, NULL, '2026-05-12 10:36:39.335202-06', true, '2026-05-12 10:36:39.335202-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, 'ba3066ca-29bc-4e21-8895-834e73a2f515', 'farm', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff');
INSERT INTO public.inventory_consumptions (id, lot_id, harvest_id, expense_id, item_id, cons_date, qty, unit_cost_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, mix_application_id, application_group_id, cost_scope, farm_id) VALUES ('626c3b56-7aaf-45e9-b09b-cfb532a0407c', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', NULL, NULL, 'ba167630-9910-4fb0-bdea-d1d2469e36bc', '2026-05-12', 1.417, 250.00, NULL, '2026-05-12 10:38:14.779016-06', false, '2026-05-12 10:39:46.393409-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '9b09d9c6-2af4-4143-b37b-47e80808c672', NULL, 'lot', NULL);
INSERT INTO public.inventory_consumptions (id, lot_id, harvest_id, expense_id, item_id, cons_date, qty, unit_cost_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, mix_application_id, application_group_id, cost_scope, farm_id) VALUES ('309d1317-b417-42eb-be2f-253a264f0cef', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', NULL, NULL, '49e41293-45f7-4ef2-a8a2-639d39aa104a', '2026-05-12', 2.218, 1690.50, NULL, '2026-05-12 10:38:14.779016-06', false, '2026-05-12 10:53:41.217256-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '9b09d9c6-2af4-4143-b37b-47e80808c672', NULL, 'lot', NULL);
INSERT INTO public.inventory_consumptions (id, lot_id, harvest_id, expense_id, item_id, cons_date, qty, unit_cost_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, mix_application_id, application_group_id, cost_scope, farm_id) VALUES ('cb6a8b10-cfc8-4370-8a10-019fe3e823c2', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', NULL, NULL, '49e41293-45f7-4ef2-a8a2-639d39aa104a', '2026-05-12', 0.060, 1690.50, NULL, '2026-05-12 11:00:42.563606-06', true, '2026-05-12 11:00:42.563606-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '03d2a876-1b59-431e-be8a-8bacc2419a19', NULL, 'lot', NULL);
INSERT INTO public.inventory_consumptions (id, lot_id, harvest_id, expense_id, item_id, cons_date, qty, unit_cost_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, mix_application_id, application_group_id, cost_scope, farm_id) VALUES ('7000b3b8-df6c-4b77-a1ea-9f694147f8d3', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', NULL, NULL, '717035cb-50f3-4f05-8690-df74143565e0', '2026-05-14', 7.500, 10000.00, NULL, '2026-05-14 07:26:03.414761-06', true, '2026-05-14 07:26:03.414761-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'bb9d425a-f584-4b5f-b575-39951dfe9c83', NULL, 'lot', NULL);
INSERT INTO public.inventory_consumptions (id, lot_id, harvest_id, expense_id, item_id, cons_date, qty, unit_cost_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, mix_application_id, application_group_id, cost_scope, farm_id) VALUES ('0e717f6e-3908-4c81-9b53-1d294349638b', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', NULL, NULL, '21dd3fae-f8a2-47e0-85d4-cb27e7a82759', '2026-05-14', 2.000, 27500.00, NULL, '2026-05-14 07:26:03.414761-06', true, '2026-05-14 07:26:03.414761-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'bb9d425a-f584-4b5f-b575-39951dfe9c83', NULL, 'lot', NULL);
INSERT INTO public.inventory_consumptions (id, lot_id, harvest_id, expense_id, item_id, cons_date, qty, unit_cost_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, mix_application_id, application_group_id, cost_scope, farm_id) VALUES ('7d978159-a938-462a-b383-917d51f4b47d', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', NULL, NULL, '61fc4607-0e9a-4149-8f43-ff404f0634c1', '2026-05-14', 10.000, 3750.00, NULL, '2026-05-14 07:26:03.414761-06', true, '2026-05-14 07:26:03.414761-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'bb9d425a-f584-4b5f-b575-39951dfe9c83', NULL, 'lot', NULL);
INSERT INTO public.inventory_consumptions (id, lot_id, harvest_id, expense_id, item_id, cons_date, qty, unit_cost_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, mix_application_id, application_group_id, cost_scope, farm_id) VALUES ('f106169e-9f79-4a73-9f82-dfef1880b08b', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', NULL, NULL, '61fc4607-0e9a-4149-8f43-ff404f0634c1', '2026-05-15', 10.000, 3750.00, NULL, '2026-05-15 14:53:27.31547-06', true, '2026-05-15 14:53:27.31547-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, 'lot', NULL);


--
-- TOC entry 7459 (class 0 OID 57005)
-- Dependencies: 314
-- Data for Name: inventory_item_ingredients; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 7460 (class 0 OID 57019)
-- Dependencies: 315
-- Data for Name: inventory_items; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.inventory_items (id, name, unit, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, category_id, brand_id, client_id) VALUES ('ba167630-9910-4fb0-bdea-d1d2469e36bc', 'Triplecal', 'kg', true, '2026-05-07 11:08:09.882176-06', '2026-05-07 11:08:09.882176-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '834e30f2-f770-4711-9220-0e5c4766f24c', '66280bcd-d48d-47d4-8229-00dccf74bb9c', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_items (id, name, unit, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, category_id, brand_id, client_id) VALUES ('03c2bb7e-8168-45a4-ae8e-2c691f55e685', 'Fertilizante Yara', 'kg', true, '2026-05-11 10:06:50.489985-06', '2026-05-11 10:06:50.489985-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '95d7932f-0e74-4461-9682-4a3a94b03297', 'faa33bf4-b44c-4112-9c9d-383ede7396ca', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_items (id, name, unit, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, category_id, brand_id, client_id) VALUES ('49e41293-45f7-4ef2-a8a2-639d39aa104a', 'Clorpirifos', 'litro', true, '2026-05-11 10:07:50.713601-06', '2026-05-11 10:07:50.713601-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '1b046c38-9d2e-4ca4-a35e-47966d2ec998', '0bf47a7a-0257-4111-86d3-418cfacb0a94', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_items (id, name, unit, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, category_id, brand_id, client_id) VALUES ('7f9b6417-43e0-45ff-98f7-4d81e2744504', 'Fertilizante Disagro', 'kg', true, '2026-05-11 10:42:02.996482-06', '2026-05-11 10:42:02.996482-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '95d7932f-0e74-4461-9682-4a3a94b03297', '0bf47a7a-0257-4111-86d3-418cfacb0a94', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_items (id, name, unit, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, category_id, brand_id, client_id) VALUES ('21dd3fae-f8a2-47e0-85d4-cb27e7a82759', 'Muralla', 'litro', true, '2026-05-14 06:51:59.78812-06', '2026-05-14 06:51:59.78812-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '1b046c38-9d2e-4ca4-a35e-47966d2ec998', 'a46fa769-e499-424e-8216-6f47717e5b51', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_items (id, name, unit, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, category_id, brand_id, client_id) VALUES ('717035cb-50f3-4f05-8690-df74143565e0', 'Antracol', 'kg', true, '2026-05-14 06:53:44.55583-06', '2026-05-14 06:53:44.55583-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '502d2604-d7ec-4d12-a1ae-760943b669ae', 'a46fa769-e499-424e-8216-6f47717e5b51', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_items (id, name, unit, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, category_id, brand_id, client_id) VALUES ('61fc4607-0e9a-4149-8f43-ff404f0634c1', 'Multifruto K + Mg', 'litro', true, '2026-05-14 07:00:54.927028-06', '2026-05-14 07:00:54.927028-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '666e4f2a-0517-4b9d-ad87-1a8ddcc4ce7a', '66280bcd-d48d-47d4-8229-00dccf74bb9c', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_items (id, name, unit, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, category_id, brand_id, client_id) VALUES ('e906d6e1-2c4e-40be-995f-86d435459fdf', 'Prueba', 'kg', true, '2026-05-15 14:53:27.000503-06', '2026-05-15 14:53:27.000503-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '3374a907-871d-413d-adf6-bab6c9067433', 'e455d50e-04cf-4ab6-854d-9b8c6d223e1b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_items (id, name, unit, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id, category_id, brand_id, client_id) VALUES ('475054eb-220d-4216-b8e7-c95f808d297a', 'Fertilizante foliar', 'litro', true, '2026-05-21 08:53:31.63184-06', '2026-05-21 08:53:31.63184-06', '089c211c-3f84-4bf4-ab24-ae82ae6be122', '089c211c-3f84-4bf4-ab24-ae82ae6be122', '95d7932f-0e74-4461-9682-4a3a94b03297', 'a46fa769-e499-424e-8216-6f47717e5b51', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');


--
-- TOC entry 7461 (class 0 OID 57037)
-- Dependencies: 316
-- Data for Name: inventory_layers; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.inventory_layers (id, item_id, movement_in_id, layer_date, qty_in, qty_remaining, unit_cost, is_active, created_at, updated_at, client_id) VALUES ('f7da3456-856b-408a-83d0-802df0d35c84', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', '51c25bae-59d9-4d8d-9a59-d0d16e9bab59', '2026-05-08', 10.000, 0.000, 250000.00, true, '2026-05-08 11:41:37.253149-06', '2026-05-08 12:16:58.931308-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_layers (id, item_id, movement_in_id, layer_date, qty_in, qty_remaining, unit_cost, is_active, created_at, updated_at, client_id) VALUES ('a807e5c4-205b-496c-a8ab-0135b245d9e3', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', '00a584b2-b871-47a9-bc34-51a4a4003bef', '2026-05-08', 10.000, 0.000, 1000.00, true, '2026-05-08 11:42:54.968857-06', '2026-05-08 12:16:58.931308-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_layers (id, item_id, movement_in_id, layer_date, qty_in, qty_remaining, unit_cost, is_active, created_at, updated_at, client_id) VALUES ('4ebbe837-3747-4571-ab7e-56f4f01a5234', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', '08f86881-b8c3-4cc6-a53e-56ddcf14cd1b', '2026-05-08', 10.000, 0.000, 2500.00, true, '2026-05-08 11:45:14.659033-06', '2026-05-08 12:16:58.931308-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_layers (id, item_id, movement_in_id, layer_date, qty_in, qty_remaining, unit_cost, is_active, created_at, updated_at, client_id) VALUES ('a04cd127-2d52-4248-9365-eb656ee1405d', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', '5fbbe097-f2a8-489e-a2b1-5a505e8bec2a', '2026-05-08', 500.000, 0.000, 0.30, true, '2026-05-08 11:56:51.240362-06', '2026-05-11 11:33:58.243616-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_layers (id, item_id, movement_in_id, layer_date, qty_in, qty_remaining, unit_cost, is_active, created_at, updated_at, client_id) VALUES ('205d653a-ecd5-4568-a997-7a625cb35c72', '49e41293-45f7-4ef2-a8a2-639d39aa104a', '40ee3275-fec8-41af-94cd-cddbf98f9f43', '2026-05-11', 0.050, 0.000, 1000000.00, true, '2026-05-11 10:13:43.503978-06', '2026-05-12 10:25:17.695005-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_layers (id, item_id, movement_in_id, layer_date, qty_in, qty_remaining, unit_cost, is_active, created_at, updated_at, client_id) VALUES ('b5215596-b96b-4faa-a788-86adad57cd91', '7f9b6417-43e0-45ff-98f7-4d81e2744504', 'dc91732c-a10a-4de5-b0ef-270f90b9d274', '2026-05-11', 0.100, 0.050, 50000.00, true, '2026-05-11 10:42:35.597327-06', '2026-05-12 10:25:17.695005-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_layers (id, item_id, movement_in_id, layer_date, qty_in, qty_remaining, unit_cost, is_active, created_at, updated_at, client_id) VALUES ('c95577ba-048b-4ac9-82db-99d24caf984e', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', 'e9322733-865c-4c58-a8e2-faacd55e8d78', '2026-05-08', 500.000, 100.000, 250.00, true, '2026-05-08 12:01:37.601069-06', '2026-05-12 10:39:46.393409-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_layers (id, item_id, movement_in_id, layer_date, qty_in, qty_remaining, unit_cost, is_active, created_at, updated_at, client_id) VALUES ('6f82ebe9-f16d-4bc6-9b78-eaadb8343d52', '49e41293-45f7-4ef2-a8a2-639d39aa104a', '6b8d30ca-7988-4c91-b1ca-913fb537eae6', '2026-05-11', 59.154, 57.044, 1690.50, true, '2026-05-11 10:29:35.125818-06', '2026-05-12 11:00:42.563606-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_layers (id, item_id, movement_in_id, layer_date, qty_in, qty_remaining, unit_cost, is_active, created_at, updated_at, client_id) VALUES ('061cd708-8af4-48e8-8f49-f549bcb04cc6', '717035cb-50f3-4f05-8690-df74143565e0', 'f8ff6c74-33f3-403f-aa42-ea8bbacd81f6', '2026-05-14', 7.500, 0.000, 10000.00, true, '2026-05-14 06:54:46.83352-06', '2026-05-14 07:26:03.414761-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_layers (id, item_id, movement_in_id, layer_date, qty_in, qty_remaining, unit_cost, is_active, created_at, updated_at, client_id) VALUES ('73e02751-1cec-4312-93bc-e902a29d1b4d', '21dd3fae-f8a2-47e0-85d4-cb27e7a82759', '639d4dde-0866-49f9-92ba-4ea6108f7c20', '2026-05-14', 10.000, 8.000, 27500.00, true, '2026-05-14 06:52:21.479806-06', '2026-05-14 07:26:03.414761-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_layers (id, item_id, movement_in_id, layer_date, qty_in, qty_remaining, unit_cost, is_active, created_at, updated_at, client_id) VALUES ('2e67c7f1-df71-4b1d-92a7-2f25e9e143dd', '61fc4607-0e9a-4149-8f43-ff404f0634c1', '37bb7551-92d0-4e84-a15e-a5490ac693c5', '2026-05-15', 20.000, 20.000, 1000.00, true, '2026-05-15 14:53:27.029463-06', '2026-05-15 14:53:27.029463-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.inventory_layers (id, item_id, movement_in_id, layer_date, qty_in, qty_remaining, unit_cost, is_active, created_at, updated_at, client_id) VALUES ('c587176b-fcdb-4feb-bf5d-f646648a8552', '61fc4607-0e9a-4149-8f43-ff404f0634c1', '355a6df3-9890-4caa-a462-a8a14a3d3b29', '2026-05-14', 60.000, 40.000, 3750.00, true, '2026-05-14 07:06:52.044169-06', '2026-05-15 14:53:27.31547-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');


--
-- TOC entry 7462 (class 0 OID 57058)
-- Dependencies: 317
-- Data for Name: inventory_movement_layers; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.inventory_movement_layers (id, movement_id, layer_id, qty_used, unit_cost, created_at) VALUES ('c2bb20ef-0083-45cc-940e-a0aad6cd87b9', '78f83f45-9e30-4999-bb3e-c049db60e931', 'f7da3456-856b-408a-83d0-802df0d35c84', 10.000, 250000.00, '2026-05-08 12:16:58.931308-06');
INSERT INTO public.inventory_movement_layers (id, movement_id, layer_id, qty_used, unit_cost, created_at) VALUES ('17e7533d-8695-4d85-8244-a6dde20f2e3f', '78f83f45-9e30-4999-bb3e-c049db60e931', 'a807e5c4-205b-496c-a8ab-0135b245d9e3', 10.000, 1000.00, '2026-05-08 12:16:58.931308-06');
INSERT INTO public.inventory_movement_layers (id, movement_id, layer_id, qty_used, unit_cost, created_at) VALUES ('ea30ab9d-0f2d-4887-b461-79182297b18d', '78f83f45-9e30-4999-bb3e-c049db60e931', '4ebbe837-3747-4571-ab7e-56f4f01a5234', 10.000, 2500.00, '2026-05-08 12:16:58.931308-06');
INSERT INTO public.inventory_movement_layers (id, movement_id, layer_id, qty_used, unit_cost, created_at) VALUES ('9f523b51-fbea-4bd2-b14b-b5478f779445', '78f83f45-9e30-4999-bb3e-c049db60e931', 'a04cd127-2d52-4248-9365-eb656ee1405d', 70.000, 0.30, '2026-05-08 12:16:58.931308-06');
INSERT INTO public.inventory_movement_layers (id, movement_id, layer_id, qty_used, unit_cost, created_at) VALUES ('d1dabf51-37df-42ea-ba67-796b2c93a5db', '8979d695-e12b-490a-b906-03e7413f6761', 'a04cd127-2d52-4248-9365-eb656ee1405d', 400.000, 0.30, '2026-05-11 11:14:41.174836-06');
INSERT INTO public.inventory_movement_layers (id, movement_id, layer_id, qty_used, unit_cost, created_at) VALUES ('77593fc1-5ba5-46e3-a965-8b6091971e96', '89f40e86-66cd-41bb-806e-c3956a091f7f', 'c95577ba-048b-4ac9-82db-99d24caf984e', 30.000, 250.00, '2026-05-11 11:24:04.703315-06');
INSERT INTO public.inventory_movement_layers (id, movement_id, layer_id, qty_used, unit_cost, created_at) VALUES ('ec3446fe-3b70-43be-b45c-989f04936c30', '1ddf5184-deaa-4dd3-8fda-1b34a6fd156f', 'a04cd127-2d52-4248-9365-eb656ee1405d', 30.000, 0.30, '2026-05-11 11:33:58.243616-06');
INSERT INTO public.inventory_movement_layers (id, movement_id, layer_id, qty_used, unit_cost, created_at) VALUES ('7810fe7e-c1e7-43e4-95fc-8fef871089fc', '1ddf5184-deaa-4dd3-8fda-1b34a6fd156f', 'c95577ba-048b-4ac9-82db-99d24caf984e', 370.000, 250.00, '2026-05-11 11:33:58.243616-06');


--
-- TOC entry 7463 (class 0 OID 57072)
-- Dependencies: 318
-- Data for Name: inventory_movements; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('51c25bae-59d9-4d8d-9a59-d0d16e9bab59', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', '2026-05-08', 'in', 10.000, 250000.00, NULL, '2026-05-08 11:41:37.253149-06', true, '2026-05-08 11:41:37.253149-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2500000, 'USD', 500.000000, 500.000000, 5000.00, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('00a584b2-b871-47a9-bc34-51a4a4003bef', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', '2026-05-08', 'in', 10.000, 1000.00, NULL, '2026-05-08 11:42:54.968857-06', true, '2026-05-08 11:42:54.968857-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 10000, 'CRC', NULL, NULL, NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('08f86881-b8c3-4cc6-a53e-56ddcf14cd1b', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', '2026-05-08', 'in', 10.000, 2500.00, NULL, '2026-05-08 11:45:14.659033-06', true, '2026-05-08 11:45:14.659033-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 25000, 'USD', 500.000000, 5.000000, 50.00, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('5fbbe097-f2a8-489e-a2b1-5a505e8bec2a', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', '2026-05-08', 'in', 500.000, 0.30, NULL, '2026-05-08 11:56:51.240362-06', true, '2026-05-08 11:56:51.240362-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, 'aaaa', 10, 50, 'kg', 15, 150, 'CRC', NULL, NULL, NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('e9322733-865c-4c58-a8e2-faacd55e8d78', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', '2026-05-08', 'in', 500.000, 250.00, NULL, '2026-05-08 12:01:37.601069-06', true, '2026-05-08 12:01:37.601069-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, 'aaa', 10, 50, 'kg', 25, 125000, 'USD', 500.000000, 0.500000, 250.00, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('78f83f45-9e30-4999-bb3e-c049db60e931', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', '2026-05-08', 'out', 100.000, 25350.21, NULL, '2026-05-08 12:16:58.931308-06', true, '2026-05-08 12:16:58.931308-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2535021, 'CRC', NULL, NULL, NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('40ee3275-fec8-41af-94cd-cddbf98f9f43', '49e41293-45f7-4ef2-a8a2-639d39aa104a', '2026-05-11', 'in', 0.050, 1000000.00, NULL, '2026-05-11 10:13:43.503978-06', true, '2026-05-11 10:13:43.503978-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, 'Botella', 5, 10, 'cc', 20, 50000, 'USD', 500.000000, 2000.000000, 100.00, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('6b8d30ca-7988-4c91-b1ca-913fb537eae6', '49e41293-45f7-4ef2-a8a2-639d39aa104a', '2026-05-11', 'in', 59.154, 1690.50, NULL, '2026-05-11 10:29:35.125818-06', true, '2026-05-11 10:29:35.125818-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, 'Botella', 10, 200, 'onza_liquida', 20, 100000, 'USD', 500.000000, 3.380000, 200.00, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('dc91732c-a10a-4de5-b0ef-270f90b9d274', '7f9b6417-43e0-45ff-98f7-4d81e2744504', '2026-05-11', 'in', 0.100, 50000.00, NULL, '2026-05-11 10:42:35.597327-06', true, '2026-05-11 10:43:00.745635-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, 'Bolsa', 10, 10, 'gramo', 500, 5000, 'CRC', NULL, NULL, NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('8979d695-e12b-490a-b906-03e7413f6761', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', '2026-05-11', 'out', 400.000, 0.05, 'Mal estado', '2026-05-11 11:14:41.174836-06', true, '2026-05-11 11:14:41.174836-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 20, 'CRC', NULL, NULL, NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'a04cd127-2d52-4248-9365-eb656ee1405d', 120.00, 100.00, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('89f40e86-66cd-41bb-806e-c3956a091f7f', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', '2026-05-11', 'out', 30.000, 250.00, 'Donación', '2026-05-11 11:24:04.703315-06', true, '2026-05-11 11:24:04.703315-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 7500, 'CRC', NULL, NULL, NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'c95577ba-048b-4ac9-82db-99d24caf984e', 7500.00, 0.00, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('1ddf5184-deaa-4dd3-8fda-1b34a6fd156f', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', '2026-05-11', 'adjust', 400.000, 231.27, NULL, '2026-05-11 11:33:58.243616-06', true, '2026-05-11 11:33:58.243616-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, 'Saco', 10, 10, 'kg', NULL, 92509, 'CRC', NULL, NULL, NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('639d4dde-0866-49f9-92ba-4ea6108f7c20', '21dd3fae-f8a2-47e0-85d4-cb27e7a82759', '2026-05-14', 'in', 10.000, 27500.00, NULL, '2026-05-14 06:52:21.479806-06', true, '2026-05-14 06:52:21.479806-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 275000, 'CRC', NULL, NULL, NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('f8ff6c74-33f3-403f-aa42-ea8bbacd81f6', '717035cb-50f3-4f05-8690-df74143565e0', '2026-05-14', 'in', 7.500, 10000.00, NULL, '2026-05-14 06:54:46.83352-06', true, '2026-05-14 06:54:46.83352-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, 'Bolsa', 10, 750, 'gramo', 7500, 75000, 'CRC', NULL, NULL, NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('355a6df3-9890-4caa-a462-a8a14a3d3b29', '61fc4607-0e9a-4149-8f43-ff404f0634c1', '2026-05-14', 'in', 60.000, 3750.00, NULL, '2026-05-14 07:06:52.044169-06', true, '2026-05-14 07:06:52.044169-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, 'Pichinga', 3, 20, 'litro', 75000, 225000, 'CRC', NULL, NULL, NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);
INSERT INTO public.inventory_movements (id, item_id, mov_date, movement, qty, unit_cost, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, packages_qty, package_cost, pack_label, pack_count, pack_size, pack_unit, pack_cost, total_cost, currency, fx_rate, unit_cost_usd, total_cost_usd, client_id, out_source_layer_id, out_gross_total_crc, out_refund_crc, adjust_layer_id) VALUES ('37bb7551-92d0-4e84-a15e-a5490ac693c5', '61fc4607-0e9a-4149-8f43-ff404f0634c1', '2026-05-15', 'in', 20.000, 1000.00, NULL, '2026-05-15 14:53:27.029463-06', true, '2026-05-15 14:53:27.029463-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 20000, 'CRC', NULL, NULL, NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, NULL, NULL, NULL);


--
-- TOC entry 7464 (class 0 OID 57103)
-- Dependencies: 319
-- Data for Name: labor_entries; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('1a3085ba-db81-46fe-9ca4-e45601321d16', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', '159d7239-8cd7-496e-9f8a-05c4507677ec', 'bf4b330a-0e5b-45de-a857-7615c0c44019', '2026-05-07', 'bolsas', 15.000, 200.00, NULL, '2026-05-06 10:35:58.437307-06', true, '2026-05-06 10:35:58.437307-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'lot', NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('c7c374f8-ff2f-4264-a167-2af6d9885b75', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', '159d7239-8cd7-496e-9f8a-05c4507677ec', 'bf4b330a-0e5b-45de-a857-7615c0c44019', '2026-05-08', 'bolsas', 15.000, 200.00, NULL, '2026-05-06 10:35:58.437307-06', true, '2026-05-06 10:35:58.437307-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'lot', NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('0a79e77e-4499-48b7-bbbf-dd7ebd37aac6', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', '159d7239-8cd7-496e-9f8a-05c4507677ec', 'bf4b330a-0e5b-45de-a857-7615c0c44019', '2026-05-09', 'bolsas', 14.000, 200.00, NULL, '2026-05-06 10:35:58.437307-06', true, '2026-05-06 10:35:58.437307-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'lot', NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('f6c046c3-49d6-4e64-bdb8-d113467599a5', NULL, '159d7239-8cd7-496e-9f8a-05c4507677ec', '3ca0ca83-ec50-4165-b677-6bddd4dffa21', '2026-05-04', 'jornal', 1.000, 1500.00, NULL, '2026-05-06 10:27:31.907364-06', true, '2026-05-06 10:27:31.907364-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'farm', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('f521bbbb-edc6-48d5-ac30-0d23d6221fe8', NULL, '159d7239-8cd7-496e-9f8a-05c4507677ec', '3ca0ca83-ec50-4165-b677-6bddd4dffa21', '2026-05-05', 'jornal', 1.000, 1500.00, NULL, '2026-05-06 10:27:31.907364-06', true, '2026-05-06 10:27:31.907364-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'farm', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('3cc62f17-e827-435a-bd24-4c726ccd18c8', NULL, '159d7239-8cd7-496e-9f8a-05c4507677ec', '3ca0ca83-ec50-4165-b677-6bddd4dffa21', '2026-05-06', 'jornal', 1.000, 1500.00, NULL, '2026-05-06 10:27:31.907364-06', true, '2026-05-06 10:27:31.907364-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'farm', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('5884ae52-9b9c-4a49-8fc2-5b07d9a19065', NULL, '159d7239-8cd7-496e-9f8a-05c4507677ec', '0e2cc7ca-2acc-4e23-bae5-bce6b2937575', '2026-05-04', 'caja', 5.000, 1500.00, NULL, '2026-05-06 10:51:05.611824-06', true, '2026-05-06 10:51:05.611824-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'farm', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('93ea9ac4-952a-41f5-975d-b72ff6c6fb46', NULL, '159d7239-8cd7-496e-9f8a-05c4507677ec', '0e2cc7ca-2acc-4e23-bae5-bce6b2937575', '2026-05-05', 'caja', 6.000, 1500.00, NULL, '2026-05-06 10:51:05.611824-06', true, '2026-05-06 10:51:05.611824-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'farm', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('50e4c862-2767-45bf-8e52-f9e1bd9a76d2', NULL, '159d7239-8cd7-496e-9f8a-05c4507677ec', '0e2cc7ca-2acc-4e23-bae5-bce6b2937575', '2026-05-06', 'caja', 8.000, 1500.00, NULL, '2026-05-06 10:51:05.611824-06', true, '2026-05-06 10:51:05.611824-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'farm', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('3e27a944-4df9-4dea-b2f8-e8061960892c', NULL, '7d8d4e67-56fe-4524-aa7e-e1ad23a6de2f', '70871119-f231-4ab2-a16b-528f6a1b5825', '2026-05-07', 'jornal', 1.000, 12000.00, NULL, '2026-05-07 10:31:13.712894-06', true, '2026-05-07 10:31:13.712894-06', '89e2b58e-057c-4f7b-908b-30d1086c076d', '89e2b58e-057c-4f7b-908b-30d1086c076d', 'farm', '6771d0bf-09c0-4b32-afd3-b3ed94bf85e7', '80ee1408-ed96-4301-8d6e-f891e5db8889');
INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('330a979b-8962-4b5f-8707-dbd4fd228291', NULL, '159d7239-8cd7-496e-9f8a-05c4507677ec', '316f7705-a5a0-4e66-ab4a-17d907b76972', '2026-05-12', 'jornal', 1.000, 12000.00, NULL, '2026-05-12 11:27:24.959638-06', true, '2026-05-12 11:27:24.959638-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'farm', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('b4de5ada-57c9-4872-b1b8-5104a567ce02', NULL, '9a6e581e-6625-4400-a49b-dc06cf829223', '0a96e9e5-efe8-4723-a3f2-92b8eb9b246e', '2026-05-13', 'hora', 10.000, 0.00, NULL, '2026-05-13 09:28:05.13107-06', true, '2026-05-13 09:28:05.13107-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'farm', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('69724cc2-e93a-4364-ba5f-9d534bd81c47', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', '159d7239-8cd7-496e-9f8a-05c4507677ec', '7e889a3f-fff5-4744-bcaf-df9805babfce', '2026-05-13', 'bolsas', 25.000, 500.00, NULL, '2026-05-13 09:28:32.459075-06', true, '2026-05-13 09:28:32.459075-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'lot', NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('cda2ed60-4be3-45a9-9b6d-26ed4e3122b6', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', '159d7239-8cd7-496e-9f8a-05c4507677ec', 'dfdbcdd9-9783-452e-b59d-e40dc1da77ff', '2026-05-16', 'jornal', 1.000, 12000.00, NULL, '2026-05-14 09:44:25.723539-06', true, '2026-05-14 09:44:25.723539-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'lot', NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.labor_entries (id, lot_id, worker_id, labor_type_id, work_date, unit, qty, rate_applied, notes, created_at, is_active, updated_at, created_by_user_id, updated_by_user_id, cost_scope, farm_id, client_id) VALUES ('c67cff63-e9f2-4d61-a485-b74b0852bc71', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', '9a6e581e-6625-4400-a49b-dc06cf829223', '3ca0ca83-ec50-4165-b677-6bddd4dffa21', '2026-04-30', 'jornal', 1.000, 0.00, NULL, '2026-05-14 10:59:27.235423-06', true, '2026-05-14 10:59:27.235423-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'lot', NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');


--
-- TOC entry 7465 (class 0 OID 57128)
-- Dependencies: 320
-- Data for Name: labor_entry_allocations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('4e651014-6c89-4f98-8e1c-7d6b8d2dd745', 'f6c046c3-49d6-4e64-bdb8-d113467599a5', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', 100.000, 1500.00, '2026-05-06 10:27:31.907364-06', '2026-05-06 10:27:31.907364-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('094c6112-74f7-458d-a425-4240a2afdec2', 'f6c046c3-49d6-4e64-bdb8-d113467599a5', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', 0.000, 0.00, '2026-05-06 10:27:31.907364-06', '2026-05-06 10:27:31.907364-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('d8d289b2-20a7-4ab6-b376-1736b822edd3', 'f521bbbb-edc6-48d5-ac30-0d23d6221fe8', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', 100.000, 1500.00, '2026-05-06 10:27:31.907364-06', '2026-05-06 10:27:31.907364-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('28b46a6a-1a23-44f7-9527-a5891ef35da2', 'f521bbbb-edc6-48d5-ac30-0d23d6221fe8', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', 0.000, 0.00, '2026-05-06 10:27:31.907364-06', '2026-05-06 10:27:31.907364-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('71584fcb-cce5-4c2e-9310-d8b5bf404a21', '3cc62f17-e827-435a-bd24-4c726ccd18c8', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', 100.000, 1500.00, '2026-05-06 10:27:31.907364-06', '2026-05-06 10:27:31.907364-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('0b1172bf-4967-4442-bff4-e357734cb759', '3cc62f17-e827-435a-bd24-4c726ccd18c8', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', 0.000, 0.00, '2026-05-06 10:27:31.907364-06', '2026-05-06 10:27:31.907364-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('a1740d3e-e096-44f5-bced-cc581b40db57', '5884ae52-9b9c-4a49-8fc2-5b07d9a19065', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', 10.000, 750.00, '2026-05-06 10:51:05.611824-06', '2026-05-06 10:51:05.611824-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('406df3e6-99af-4349-9169-143c7d7dc245', '5884ae52-9b9c-4a49-8fc2-5b07d9a19065', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', 90.000, 6750.00, '2026-05-06 10:51:05.611824-06', '2026-05-06 10:51:05.611824-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('aa03b123-2283-4a31-9936-76c90c82d7dd', '93ea9ac4-952a-41f5-975d-b72ff6c6fb46', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', 10.000, 900.00, '2026-05-06 10:51:05.611824-06', '2026-05-06 10:51:05.611824-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('a0304213-070f-4f63-aeec-cb3ab5a8a110', '93ea9ac4-952a-41f5-975d-b72ff6c6fb46', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', 90.000, 8100.00, '2026-05-06 10:51:05.611824-06', '2026-05-06 10:51:05.611824-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('9f7cdac5-ebbb-4e80-881c-7045fbcfbb73', '50e4c862-2767-45bf-8e52-f9e1bd9a76d2', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', 10.000, 1200.00, '2026-05-06 10:51:05.611824-06', '2026-05-06 10:51:05.611824-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('bb34e4f9-b306-48e3-b142-43802a02d218', '50e4c862-2767-45bf-8e52-f9e1bd9a76d2', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', 90.000, 10800.00, '2026-05-06 10:51:05.611824-06', '2026-05-06 10:51:05.611824-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('1515eef5-89a3-403e-a184-d350aa39c5e9', '3e27a944-4df9-4dea-b2f8-e8061960892c', '3cbfb9b8-96ab-40b7-a469-bce2754c12ef', 100.000, 12000.00, '2026-05-07 10:31:13.712894-06', '2026-05-07 10:31:13.712894-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('0a37b916-cc96-4b0a-b429-67c9abc358fd', '330a979b-8962-4b5f-8707-dbd4fd228291', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', 50.000, 6000.00, '2026-05-12 11:27:24.959638-06', '2026-05-12 11:27:24.959638-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('e3e025a5-786a-4811-8339-53facf9c4aac', '330a979b-8962-4b5f-8707-dbd4fd228291', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', 50.000, 6000.00, '2026-05-12 11:27:24.959638-06', '2026-05-12 11:27:24.959638-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('add7f487-fdd6-49eb-943c-754bd4c48a48', 'b4de5ada-57c9-4872-b1b8-5104a567ce02', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', 100.000, 0.00, '2026-05-13 09:28:05.13107-06', '2026-05-13 09:28:05.13107-06', true);
INSERT INTO public.labor_entry_allocations (id, labor_entry_id, lot_id, allocation_pct, amount_allocated, created_at, updated_at, is_active) VALUES ('0729038c-d04e-41db-990f-de0700f5eb27', 'b4de5ada-57c9-4872-b1b8-5104a567ce02', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', 0.000, 0.00, '2026-05-13 09:28:05.13107-06', '2026-05-13 09:28:05.13107-06', true);


--
-- TOC entry 7466 (class 0 OID 57144)
-- Dependencies: 321
-- Data for Name: labor_rates; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 7467 (class 0 OID 57160)
-- Dependencies: 322
-- Data for Name: labor_types; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('990523f3-0e9c-46e7-b1ac-e69c741e4b06', 'Preparación de suelo', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('d5c353b2-9f09-47f6-92e0-447448ffa387', 'Trazado y marcado', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('3ca0ca83-ec50-4165-b677-6bddd4dffa21', 'Ahoyado', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('78e62742-81ea-43b8-8f34-4b1ec1262a25', 'Siembra', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('a6415f67-19a8-46a1-a93c-f07ed87d4feb', 'Fertilización al suelo', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('32036c81-62c0-4fb6-8173-639a84c60cc4', 'Fertilización foliar', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('0a96e9e5-efe8-4723-a3f2-92b8eb9b246e', 'Aplicación de enmiendas', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('02b37d2f-271b-4a9c-baf8-188cc0931e00', 'Riego', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('70871119-f231-4ab2-a16b-528f6a1b5825', 'Mantenimiento de sistema de riego', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('dfdbcdd9-9783-452e-b59d-e40dc1da77ff', 'Poda de formación', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('03d72c70-34fa-407e-9b64-7334e17a1de5', 'Poda de mantenimiento', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('f8b70b03-9b27-4a5e-a70c-9c2ae48c3cf3', 'Poda sanitaria', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('e4a6683a-6494-4ef8-92e8-5a14a6fd33bd', 'Deschuponado', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('316f7705-a5a0-4e66-ab4a-17d907b76972', 'Aplicación de fungicidas', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('7e889a3f-fff5-4744-bcaf-df9805babfce', 'Aplicación de insecticidas', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('0e2cc7ca-2acc-4e23-bae5-bce6b2937575', 'Aplicación de herbicidas', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('44b6c802-d50d-4423-b038-9fa90c2ca855', 'Control manual de malezas', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('d50de255-88cb-40cd-adbd-301d69c604d8', 'Manejo de floración', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('ee010b5d-ac14-4c7e-a068-f6cb41ff2ea1', 'Raleo de fruta', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('3228b527-fc86-42fd-bb42-dfbe29dc90da', 'Cosecha', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('996f89cc-9c57-42d5-a8a6-28f5558b16b1', 'Selección de fruta', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('d7caba05-76b7-46f7-81fb-e5e29e04c34a', 'Lavado de fruta', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('4cf7c4bc-cc42-42f5-bceb-03183f64c0b0', 'Empaque', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('4e400580-ee0e-4bd1-b644-73d1a9647e74', 'Chapia', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('9a85b648-ef67-48e2-bde1-3c161fe273ec', 'Limpieza general', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('bf4b330a-0e5b-45de-a857-7615c0c44019', 'Mantenimiento de finca', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('bc6f28c0-3647-467f-8fc9-85ad43118bb0', 'Monitoreo de plagas', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('9c2dac95-9837-49c6-8b78-f3980ae93601', 'Monitoreo nutricional', true, '2026-05-06 10:16:53.291998-06', '2026-05-06 10:16:53.291998-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('9b71b942-0886-4223-ba48-d3de2285d35d', 'Llenado de bolsas', true, '2026-05-06 10:37:52.779472-06', '2026-05-06 10:37:52.779472-06', NULL, NULL);
INSERT INTO public.labor_types (id, name, is_active, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('226dea59-7590-493e-a543-eb95eaf11c9b', 'Recolección de café', true, '2026-05-21 09:33:48.721845-06', '2026-05-21 09:33:48.721845-06', NULL, NULL);


--
-- TOC entry 7468 (class 0 OID 57174)
-- Dependencies: 323
-- Data for Name: lot_coffee_varieties; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 7469 (class 0 OID 57185)
-- Dependencies: 324
-- Data for Name: lot_harvests; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 7470 (class 0 OID 57240)
-- Dependencies: 325
-- Data for Name: lots; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.lots (id, farm_id, name, area_ha, plant_count, created_at, is_active, deactivated_at, geom, created_by_user_id, updated_by_user_id, updated_at, client_id) VALUES ('b3f4dbf9-fb71-44d1-9c48-623ad1db5360', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', 'Lote de prueba', NULL, 0, '2026-05-06 09:38:23.236552-06', true, NULL, NULL, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-06 09:40:07.49666-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.lots (id, farm_id, name, area_ha, plant_count, created_at, is_active, deactivated_at, geom, created_by_user_id, updated_by_user_id, updated_at, client_id) VALUES ('6182d38d-bd26-4d7c-97e0-3932c8e779d9', 'b7642e09-5cfc-4625-b2f9-d093172ea0ff', 'Lote prueba 2', 7.0000, 15, '2026-05-06 09:43:53.505384-06', true, NULL, NULL, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', '2026-05-06 09:43:53.505384-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.lots (id, farm_id, name, area_ha, plant_count, created_at, is_active, deactivated_at, geom, created_by_user_id, updated_by_user_id, updated_at, client_id) VALUES ('3cbfb9b8-96ab-40b7-a469-bce2754c12ef', '6771d0bf-09c0-4b32-afd3-b3ed94bf85e7', 'Prueba', 5.0000, 0, '2026-05-07 10:30:34.027026-06', true, NULL, NULL, '89e2b58e-057c-4f7b-908b-30d1086c076d', '89e2b58e-057c-4f7b-908b-30d1086c076d', '2026-05-07 10:30:34.027026-06', '80ee1408-ed96-4301-8d6e-f891e5db8889');


--
-- TOC entry 7471 (class 0 OID 57260)
-- Dependencies: 326
-- Data for Name: mix_application_items; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.mix_application_items (id, mix_application_id, item_id, dose_qty, dose_unit, dose_qty_base, created_by_user_id, updated_by_user_id, is_active, created_at, updated_at) VALUES ('77972eb6-e731-4681-bcd9-7744e0c6bd78', '221f32a6-968b-4221-bf8d-05fd6f37c29a', '49e41293-45f7-4ef2-a8a2-639d39aa104a', 20.0000, 'cc', 0.020000, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', true, '2026-05-12 10:25:17.695005-06', '2026-05-12 10:25:17.695005-06');
INSERT INTO public.mix_application_items (id, mix_application_id, item_id, dose_qty, dose_unit, dose_qty_base, created_by_user_id, updated_by_user_id, is_active, created_at, updated_at) VALUES ('6d8fe3ba-ca1f-499e-9f23-e16a786e3764', '221f32a6-968b-4221-bf8d-05fd6f37c29a', '7f9b6417-43e0-45ff-98f7-4d81e2744504', 10.0000, 'g', 0.010000, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', true, '2026-05-12 10:25:17.695005-06', '2026-05-12 10:25:17.695005-06');
INSERT INTO public.mix_application_items (id, mix_application_id, item_id, dose_qty, dose_unit, dose_qty_base, created_by_user_id, updated_by_user_id, is_active, created_at, updated_at) VALUES ('24ddb184-3190-487f-8bb6-096cbf8e042a', '9b09d9c6-2af4-4143-b37b-47e80808c672', 'ba167630-9910-4fb0-bdea-d1d2469e36bc', 10.0000, 'onza_masa', 0.283495, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', true, '2026-05-12 10:38:14.779016-06', '2026-05-12 10:38:14.779016-06');
INSERT INTO public.mix_application_items (id, mix_application_id, item_id, dose_qty, dose_unit, dose_qty_base, created_by_user_id, updated_by_user_id, is_active, created_at, updated_at) VALUES ('26c5f4db-2e77-47a1-85cb-bf876c9dcfea', '9b09d9c6-2af4-4143-b37b-47e80808c672', '49e41293-45f7-4ef2-a8a2-639d39aa104a', 15.0000, 'onza_liquida', 0.443656, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', false, '2026-05-12 10:38:14.779016-06', '2026-05-12 10:53:41.217256-06');
INSERT INTO public.mix_application_items (id, mix_application_id, item_id, dose_qty, dose_unit, dose_qty_base, created_by_user_id, updated_by_user_id, is_active, created_at, updated_at) VALUES ('75748bfd-b3b7-4161-b6eb-ac07f7a03d28', '03d2a876-1b59-431e-be8a-8bacc2419a19', '49e41293-45f7-4ef2-a8a2-639d39aa104a', 10.0000, 'cc', 0.010000, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', true, '2026-05-12 11:00:42.563606-06', '2026-05-12 11:00:42.563606-06');
INSERT INTO public.mix_application_items (id, mix_application_id, item_id, dose_qty, dose_unit, dose_qty_base, created_by_user_id, updated_by_user_id, is_active, created_at, updated_at) VALUES ('9ba31da5-17ac-4ef1-9e1f-70016be60a60', 'bb9d425a-f584-4b5f-b575-39951dfe9c83', '717035cb-50f3-4f05-8690-df74143565e0', 750.0000, 'g', 0.750000, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', true, '2026-05-14 07:26:03.414761-06', '2026-05-14 07:26:03.414761-06');
INSERT INTO public.mix_application_items (id, mix_application_id, item_id, dose_qty, dose_unit, dose_qty_base, created_by_user_id, updated_by_user_id, is_active, created_at, updated_at) VALUES ('288c33ba-d086-4321-9b54-b3ca467f5019', 'bb9d425a-f584-4b5f-b575-39951dfe9c83', '21dd3fae-f8a2-47e0-85d4-cb27e7a82759', 200.0000, 'ml', 0.200000, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', true, '2026-05-14 07:26:03.414761-06', '2026-05-14 07:26:03.414761-06');
INSERT INTO public.mix_application_items (id, mix_application_id, item_id, dose_qty, dose_unit, dose_qty_base, created_by_user_id, updated_by_user_id, is_active, created_at, updated_at) VALUES ('93ade62d-5705-4963-a7b9-e449adc6e4f9', 'bb9d425a-f584-4b5f-b575-39951dfe9c83', '61fc4607-0e9a-4149-8f43-ff404f0634c1', 1.0000, 'litro', 1.000000, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', true, '2026-05-14 07:26:03.414761-06', '2026-05-14 07:26:03.414761-06');


--
-- TOC entry 7472 (class 0 OID 57278)
-- Dependencies: 327
-- Data for Name: mix_applications; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.mix_applications (id, lot_id, harvest_id, expense_id, app_date, containers_used, notes, created_by_user_id, updated_by_user_id, is_active, created_at, updated_at, client_id, farm_id, cost_scope) VALUES ('221f32a6-968b-4221-bf8d-05fd6f37c29a', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', NULL, NULL, '2026-05-12', 5.0000, NULL, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', true, '2026-05-12 10:25:17.695005-06', '2026-05-12 10:25:17.695005-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, 'lot');
INSERT INTO public.mix_applications (id, lot_id, harvest_id, expense_id, app_date, containers_used, notes, created_by_user_id, updated_by_user_id, is_active, created_at, updated_at, client_id, farm_id, cost_scope) VALUES ('9b09d9c6-2af4-4143-b37b-47e80808c672', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', NULL, NULL, '2026-05-12', 5.0000, NULL, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', true, '2026-05-12 10:38:14.779016-06', '2026-05-12 10:53:41.217256-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, 'lot');
INSERT INTO public.mix_applications (id, lot_id, harvest_id, expense_id, app_date, containers_used, notes, created_by_user_id, updated_by_user_id, is_active, created_at, updated_at, client_id, farm_id, cost_scope) VALUES ('03d2a876-1b59-431e-be8a-8bacc2419a19', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', NULL, NULL, '2026-05-12', 6.0000, NULL, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', true, '2026-05-12 11:00:42.563606-06', '2026-05-12 11:00:42.563606-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, 'lot');
INSERT INTO public.mix_applications (id, lot_id, harvest_id, expense_id, app_date, containers_used, notes, created_by_user_id, updated_by_user_id, is_active, created_at, updated_at, client_id, farm_id, cost_scope) VALUES ('bb9d425a-f584-4b5f-b575-39951dfe9c83', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', NULL, NULL, '2026-05-14', 10.0000, NULL, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', true, '2026-05-14 07:26:03.414761-06', '2026-05-14 07:26:03.414761-06', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, 'lot');


--
-- TOC entry 7473 (class 0 OID 57298)
-- Dependencies: 328
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.password_reset_tokens (id, user_id, token_hash, expires_at, used_at, created_at, created_by_user_id, attempts, last_sent_at) VALUES ('e1644867-6009-462a-9fef-39dfa0c6e719', '089c211c-3f84-4bf4-ab24-ae82ae6be122', '786f3b8d5055267852f50ad377c1660cb5ccf9cf2d455900e1fa2870f2e2c6fe', '2026-05-13 17:49:03.301-06', '2026-05-13 15:49:46.619347-06', '2026-05-13 15:49:03.302402-06', NULL, 0, NULL);
INSERT INTO public.password_reset_tokens (id, user_id, token_hash, expires_at, used_at, created_at, created_by_user_id, attempts, last_sent_at) VALUES ('f884fdcf-f5e7-452d-9023-8b8af08783ea', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a4b4fa98e057bf7667949b3fa01f1aa7c5e712e04144cf83de50cdb8ede1cfd4', '2026-05-13 18:00:22.948-06', '2026-05-13 16:01:35.886908-06', '2026-05-13 16:00:22.94999-06', NULL, 0, NULL);
INSERT INTO public.password_reset_tokens (id, user_id, token_hash, expires_at, used_at, created_at, created_by_user_id, attempts, last_sent_at) VALUES ('3f31d033-191b-4177-a373-a921472f4913', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'ae2197c7d5c252842a17b0847a9cc0681a9e1ab1b9fc8ba315d2e6651b5f221e', '2026-05-13 18:01:35.885-06', '2026-05-13 16:04:20.443221-06', '2026-05-13 16:01:35.886908-06', NULL, 0, NULL);
INSERT INTO public.password_reset_tokens (id, user_id, token_hash, expires_at, used_at, created_at, created_by_user_id, attempts, last_sent_at) VALUES ('ec0a6e83-7767-4bb2-9e38-59d0b5d43f02', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'fb47c001b7fefc580588bd358a9189af2011742df3473f9551ae0b5c552258b9', '2026-05-13 18:04:20.441-06', '2026-05-13 16:05:37.578503-06', '2026-05-13 16:04:20.443221-06', NULL, 0, NULL);
INSERT INTO public.password_reset_tokens (id, user_id, token_hash, expires_at, used_at, created_at, created_by_user_id, attempts, last_sent_at) VALUES ('6e7ddc92-800a-4df2-852f-27cd95ad8be2', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'd082f3e9189a28b456b3b9cf201ad86de6be04f965caa90f75b4d863e8f521e1', '2026-05-13 18:05:37.578-06', '2026-05-13 16:07:47.848426-06', '2026-05-13 16:05:37.578503-06', NULL, 0, NULL);
INSERT INTO public.password_reset_tokens (id, user_id, token_hash, expires_at, used_at, created_at, created_by_user_id, attempts, last_sent_at) VALUES ('3a210531-d444-428e-aa6a-cdacbb55545c', '089c211c-3f84-4bf4-ab24-ae82ae6be122', '0f078770ff4ec87ed6c34b48ac1930be74c963e05e1039b37e600878b5d15421', '2026-05-13 18:07:47.847-06', '2026-05-13 16:22:21.607516-06', '2026-05-13 16:07:47.848426-06', NULL, 0, NULL);
INSERT INTO public.password_reset_tokens (id, user_id, token_hash, expires_at, used_at, created_at, created_by_user_id, attempts, last_sent_at) VALUES ('745906a9-5a90-4e39-964b-cfc6a5a82e86', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'f9de31a0c8fa8a3d895751a7f9ee58cfe11da8174bc8dde8a5e809aef3045f65', '2026-05-13 18:22:21.606-06', NULL, '2026-05-13 16:22:21.607516-06', NULL, 0, NULL);


--
-- TOC entry 7474 (class 0 OID 57312)
-- Dependencies: 329
-- Data for Name: payroll_employee_rates; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 7475 (class 0 OID 57326)
-- Dependencies: 330
-- Data for Name: payroll_nomina_contribution_rules; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.payroll_nomina_contribution_rules (id, client_id, valid_from, valid_to, employer_pct_of_gross, employee_pct_of_gross, notes, is_active, deactivated_at, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('318e89e6-6ac9-4779-893e-bb88e1a10d1b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '2026-01-01', NULL, 26.8300, 10.8300, NULL, true, NULL, '2026-05-13 09:59:54.761911-06', '2026-05-13 09:59:54.761911-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b');


--
-- TOC entry 7476 (class 0 OID 57346)
-- Dependencies: 331
-- Data for Name: payroll_periods; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 7477 (class 0 OID 57358)
-- Dependencies: 332
-- Data for Name: payroll_settings; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 7478 (class 0 OID 57380)
-- Dependencies: 333
-- Data for Name: payroll_slip_lot_allocations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.payroll_slip_lot_allocations (id, payroll_slip_id, lot_id, allocation_pct, amount_allocated) VALUES ('6fb6fdfc-5fed-48db-993b-eb8f455d3117', '5dff1aa8-fc14-44e1-bebf-189a82909adb', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', 50.000000, 190245.00);
INSERT INTO public.payroll_slip_lot_allocations (id, payroll_slip_id, lot_id, allocation_pct, amount_allocated) VALUES ('1c5faa52-f4da-4643-8dda-5ecf7cacaa00', '5dff1aa8-fc14-44e1-bebf-189a82909adb', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', 50.000000, 190245.00);
INSERT INTO public.payroll_slip_lot_allocations (id, payroll_slip_id, lot_id, allocation_pct, amount_allocated) VALUES ('bf4c4b04-6dcc-40bd-864a-f18a6c6cb784', 'd634fdff-f486-4b5f-9220-0daabcb679fa', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', 73.380000, 61702.79);
INSERT INTO public.payroll_slip_lot_allocations (id, payroll_slip_id, lot_id, allocation_pct, amount_allocated) VALUES ('2e12e554-2ec0-43f9-911d-bc257bdac973', 'd634fdff-f486-4b5f-9220-0daabcb679fa', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', 26.620000, 22385.50);
INSERT INTO public.payroll_slip_lot_allocations (id, payroll_slip_id, lot_id, allocation_pct, amount_allocated) VALUES ('078cc1d8-02e9-455d-a8f8-5cb9885b1bf6', '15a86060-2913-4142-bfc3-756338797788', '6182d38d-bd26-4d7c-97e0-3932c8e779d9', 73.380000, 48650.00);
INSERT INTO public.payroll_slip_lot_allocations (id, payroll_slip_id, lot_id, allocation_pct, amount_allocated) VALUES ('842d70fa-47e0-448e-b8ef-a651257ef82f', '15a86060-2913-4142-bfc3-756338797788', 'b3f4dbf9-fb71-44d1-9c48-623ad1db5360', 26.620000, 17650.00);


--
-- TOC entry 7479 (class 0 OID 57391)
-- Dependencies: 334
-- Data for Name: payroll_slips; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.payroll_slips (id, client_id, worker_id, worker_kind, period_from, period_to, receives_aguinaldo, declares_ccss, status, gross_total, employer_ccss_amount, employee_ccss_amount, aguinaldo_provision, total_employer_liability, employer_pct_snapshot, employee_pct_snapshot, nomina_rule_id, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('d634fdff-f486-4b5f-9220-0daabcb679fa', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '159d7239-8cd7-496e-9f8a-05c4507677ec', 'ocasional', '2026-05-01', '2026-05-15', true, true, 'cancelada', 66300.00, 17788.29, 7180.29, 5525.00, 84088.29, 26.8300, 10.8300, '318e89e6-6ac9-4779-893e-bb88e1a10d1b', '2026-05-13 10:35:54.600113-06', '2026-05-13 10:36:21.210453-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b');
INSERT INTO public.payroll_slips (id, client_id, worker_id, worker_kind, period_from, period_to, receives_aguinaldo, declares_ccss, status, gross_total, employer_ccss_amount, employee_ccss_amount, aguinaldo_provision, total_employer_liability, employer_pct_snapshot, employee_pct_snapshot, nomina_rule_id, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('5dff1aa8-fc14-44e1-bebf-189a82909adb', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '9a6e581e-6625-4400-a49b-dc06cf829223', 'fijo', '2026-05-01', '2026-05-31', true, true, 'pagada', 300000.00, 80490.00, 32490.00, 25000.00, 380490.00, 26.8300, 10.8300, '318e89e6-6ac9-4779-893e-bb88e1a10d1b', '2026-05-13 10:35:19.394718-06', '2026-05-13 10:52:30.937735-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b');
INSERT INTO public.payroll_slips (id, client_id, worker_id, worker_kind, period_from, period_to, receives_aguinaldo, declares_ccss, status, gross_total, employer_ccss_amount, employee_ccss_amount, aguinaldo_provision, total_employer_liability, employer_pct_snapshot, employee_pct_snapshot, nomina_rule_id, created_at, updated_at, created_by_user_id, updated_by_user_id) VALUES ('15a86060-2913-4142-bfc3-756338797788', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '159d7239-8cd7-496e-9f8a-05c4507677ec', 'ocasional', '2026-05-01', '2026-05-15', false, false, 'pagada', 66300.00, 0.00, 0.00, 0.00, 66300.00, NULL, NULL, NULL, '2026-05-13 10:36:29.135561-06', '2026-05-13 10:54:05.887034-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b');


--
-- TOC entry 7480 (class 0 OID 57428)
-- Dependencies: 335
-- Data for Name: plans; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.plans (id, name, max_farms, price, created_at, max_lots_per_farm, max_users_admin, max_users_operario, billing_model, trial_days, description, is_active) VALUES ('94c80683-d16d-40c7-bef0-49668c608963', 'Plan Demo', 2, 0.00, '2026-05-05 11:45:51.899294', 10, 1, 2, 'trial_days', 31, 'Demostración: vigencia limitada desde la fecha de alta o renovación.', true);
INSERT INTO public.plans (id, name, max_farms, price, created_at, max_lots_per_farm, max_users_admin, max_users_operario, billing_model, trial_days, description, is_active) VALUES ('beb877f4-0456-4fc9-a1ee-e7d6d85ac238', 'Prueba', 2, 50000.00, '2026-05-22 10:41:49.019808', 10, 2, 3, 'monthly_anchor', NULL, NULL, true);


--
-- TOC entry 7481 (class 0 OID 57443)
-- Dependencies: 336
-- Data for Name: provinces; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.provinces (id, name, official_code) VALUES (1, 'Alajuela', '2');
INSERT INTO public.provinces (id, name, official_code) VALUES (2, 'San José', '1');
INSERT INTO public.provinces (id, name, official_code) VALUES (3, 'Cartago', '3');
INSERT INTO public.provinces (id, name, official_code) VALUES (4, 'Heredia', '4');
INSERT INTO public.provinces (id, name, official_code) VALUES (5, 'Guanacaste', '5');
INSERT INTO public.provinces (id, name, official_code) VALUES (6, 'Puntarenas', '6');
INSERT INTO public.provinces (id, name, official_code) VALUES (7, 'Limón', '7');


--
-- TOC entry 7483 (class 0 OID 57449)
-- Dependencies: 338
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.roles (id, name) VALUES ('02a6e105-c800-468a-b64b-64f89e9e103c', 'admin');
INSERT INTO public.roles (id, name) VALUES ('76c96941-2c29-4aa7-96cb-3e931ad36283', 'operario');
INSERT INTO public.roles (id, name) VALUES ('7ee10aa4-9da8-47be-81cf-497d20bba0dc', 'superadmin');


--
-- TOC entry 7484 (class 0 OID 57455)
-- Dependencies: 339
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.schema_migrations (filename, applied_at) VALUES ('20260718120000_grant_wardi_app_role.sql', '2026-05-18 09:28:33.032711-06');


--
-- TOC entry 7485 (class 0 OID 57463)
-- Dependencies: 340
-- Data for Name: security_audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('592cb751-ee3d-4b87-9a78-30506c484d07', 'login_failed', NULL, NULL, 'dd69f7721508a56965bd838c9aa732f4730ccb447d1772b77dcff37dc9066245', '::1', '8a65fe6e61267f5fe402d21cc3b238308bfda660899e708a5b36f2a6b465a503', '{"reason": "invalid_credentials"}', '2026-05-05 11:11:48.600463-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('2f2ddd4b-b1b4-447b-bdc0-cc9b6e3fd978', 'login_failed', NULL, NULL, 'dd69f7721508a56965bd838c9aa732f4730ccb447d1772b77dcff37dc9066245', '::1', '8a65fe6e61267f5fe402d21cc3b238308bfda660899e708a5b36f2a6b465a503', '{"reason": "invalid_credentials"}', '2026-05-05 11:12:28.716428-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('b56e520d-b087-44b5-a60f-f0bd3fc43c5a', 'login_failed', NULL, NULL, 'c01d91fd76a1a5f652a4fc52ea89d5205da03bdaf04fdf1d6543477ac6724884', '::1', '8a65fe6e61267f5fe402d21cc3b238308bfda660899e708a5b36f2a6b465a503', '{"reason": "invalid_credentials"}', '2026-05-05 11:13:10.999869-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('c849c906-2f9d-4541-b06f-c7f3b49720a1', 'login_failed', NULL, NULL, 'c01d91fd76a1a5f652a4fc52ea89d5205da03bdaf04fdf1d6543477ac6724884', '::1', '8a65fe6e61267f5fe402d21cc3b238308bfda660899e708a5b36f2a6b465a503', '{"reason": "invalid_credentials"}', '2026-05-05 11:13:11.397758-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('97bfd8bb-b1e3-41ce-bebb-05262082ea8c', 'login_failed', NULL, NULL, 'c01d91fd76a1a5f652a4fc52ea89d5205da03bdaf04fdf1d6543477ac6724884', '::1', '8a65fe6e61267f5fe402d21cc3b238308bfda660899e708a5b36f2a6b465a503', '{"reason": "invalid_credentials"}', '2026-05-05 11:13:11.748345-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('668c4268-9ce1-4835-96a2-c80bb928bdd7', 'login_failed', NULL, NULL, 'c01d91fd76a1a5f652a4fc52ea89d5205da03bdaf04fdf1d6543477ac6724884', '::1', '8a65fe6e61267f5fe402d21cc3b238308bfda660899e708a5b36f2a6b465a503', '{"reason": "invalid_credentials"}', '2026-05-05 11:13:12.098696-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('387e75d3-be22-4e46-b79f-70cafe34e93c', 'login_failed', NULL, NULL, 'c01d91fd76a1a5f652a4fc52ea89d5205da03bdaf04fdf1d6543477ac6724884', '::1', '8a65fe6e61267f5fe402d21cc3b238308bfda660899e708a5b36f2a6b465a503', '{"reason": "invalid_credentials"}', '2026-05-05 11:13:12.502074-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('2df5f026-4524-4f85-b28f-904e813afc0c', 'login_failed', NULL, NULL, 'c01d91fd76a1a5f652a4fc52ea89d5205da03bdaf04fdf1d6543477ac6724884', '::1', '8a65fe6e61267f5fe402d21cc3b238308bfda660899e708a5b36f2a6b465a503', '{"reason": "invalid_credentials"}', '2026-05-05 11:13:12.91892-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('82ce01ab-735f-4489-adea-8b40390acb97', 'login_failed', NULL, NULL, 'c01d91fd76a1a5f652a4fc52ea89d5205da03bdaf04fdf1d6543477ac6724884', '::1', '8a65fe6e61267f5fe402d21cc3b238308bfda660899e708a5b36f2a6b465a503', '{"reason": "invalid_credentials"}', '2026-05-05 11:13:13.269269-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('88e035ae-c93d-4d5e-a406-9324673acf5f', 'login_failed', NULL, NULL, 'c01d91fd76a1a5f652a4fc52ea89d5205da03bdaf04fdf1d6543477ac6724884', '::1', '8a65fe6e61267f5fe402d21cc3b238308bfda660899e708a5b36f2a6b465a503', '{"reason": "invalid_credentials"}', '2026-05-05 11:13:13.680104-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('1cd65582-401f-48db-9978-a0271b4614f2', 'login_failed', NULL, NULL, 'c01d91fd76a1a5f652a4fc52ea89d5205da03bdaf04fdf1d6543477ac6724884', '::1', '8a65fe6e61267f5fe402d21cc3b238308bfda660899e708a5b36f2a6b465a503', '{"reason": "invalid_credentials"}', '2026-05-05 11:13:14.022675-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('11f73807-0f6d-4036-aa85-1e521ea99ad4', 'login_failed', NULL, NULL, 'c01d91fd76a1a5f652a4fc52ea89d5205da03bdaf04fdf1d6543477ac6724884', '::1', '8a65fe6e61267f5fe402d21cc3b238308bfda660899e708a5b36f2a6b465a503', '{"reason": "invalid_credentials"}', '2026-05-05 11:13:14.372527-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('2c5178e5-8754-486a-b300-fb6657cdee32', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', 'c0936899f2a68365adcbc8785de304ea627bdfab8d78602a748663d236cf4db7', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-05 12:01:19.499828-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('72cf19e2-a78d-4a29-98b3-b1af39a3e813', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-05 12:08:57.648913-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('dc5d332d-708d-4340-ba02-0e2bc4da8b74', 'logout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-05 12:09:38.999082-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('516c4ccd-655e-4eb4-8ff8-18437dccfec3', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-05 12:11:16.264199-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('43cab38d-d940-4e7e-a5c4-8e1c5ea8f08a', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-05 18:19:05.396758-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('7e3a666e-4a09-4307-b8c2-28af8568147e', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-06 08:37:05.320713-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('e1f8567d-b613-4c9e-8611-09f0f5319f69', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-06 11:15:01.2693-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('c7840c48-5280-4e19-9778-a9f747fab0c4', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-06 11:51:07.820529-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('da6bba76-7ab4-4835-9c2f-bbc7efb5e1be', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-06 11:51:15.248059-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('7eff286e-9a46-49ae-81a4-e453d26683cb', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-06 12:49:05.122238-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('8668af4e-9458-4db0-9f55-65e64c0f271f', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-07 08:19:26.873329-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('e79e2878-fe1c-4707-a3ea-bb8f6851cf19', 'login_failed', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', '36947ce11e288bda6fa485ed5b51c523690c6752312c514195371d061e11bf5d', '::1', '387ae7aef0ff2cb88b68b8790a2f5eb8b677c19a765a3118517b46df17c55193', '{"reason": "invalid_credentials"}', '2026-05-07 09:46:31.900797-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('c1e2ba72-4386-4991-a180-2cb65690bd21', 'login_failed', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', '36947ce11e288bda6fa485ed5b51c523690c6752312c514195371d061e11bf5d', '::1', '387ae7aef0ff2cb88b68b8790a2f5eb8b677c19a765a3118517b46df17c55193', '{"reason": "invalid_credentials"}', '2026-05-07 09:46:49.667948-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('91be7d18-772f-4308-9c26-0488231fae0d', 'login_failed', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', '36947ce11e288bda6fa485ed5b51c523690c6752312c514195371d061e11bf5d', '::1', '9e52169b3b1bbc4537b1764d2a809f4de8629324c7677ef44f5422df5a14543a', '{"reason": "invalid_credentials"}', '2026-05-07 09:47:22.234618-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('f496f1a1-40d2-4051-abca-2b85caf40933', 'login_success', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', '36947ce11e288bda6fa485ed5b51c523690c6752312c514195371d061e11bf5d', '::1', '9e52169b3b1bbc4537b1764d2a809f4de8629324c7677ef44f5422df5a14543a', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-07 09:52:59.620973-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('6b6c4a11-bfe0-40bc-8665-48e79d97a787', 'session_fingerprint_mismatch', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', NULL, '::1', '545ea538461003efdc8c81c244531b003f6f26cfccf6c0073b3239fdedf49446', '{"checkIp": false, "checkUA": true, "ipMismatch": false, "uaMismatch": true}', '2026-05-07 09:54:28.765141-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('be30dc25-054b-402b-bfc3-310ddf7ea486', 'login_success', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', '36947ce11e288bda6fa485ed5b51c523690c6752312c514195371d061e11bf5d', '::1', '387ae7aef0ff2cb88b68b8790a2f5eb8b677c19a765a3118517b46df17c55193', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-07 09:58:42.091059-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('e972726e-9a58-4326-a3c1-4af62e7475d9', 'session_fingerprint_mismatch', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', NULL, '::1', '545ea538461003efdc8c81c244531b003f6f26cfccf6c0073b3239fdedf49446', '{"checkIp": false, "checkUA": true, "ipMismatch": false, "uaMismatch": true}', '2026-05-07 09:59:07.729115-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('a02b23d4-e143-4b97-942b-3dab1ff5ac88', 'logout', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', NULL, '::1', '9e52169b3b1bbc4537b1764d2a809f4de8629324c7677ef44f5422df5a14543a', '{}', '2026-05-07 10:02:09.369693-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('c87497ea-4895-4913-b7c2-7e17fc009d27', 'login_failed', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', '36947ce11e288bda6fa485ed5b51c523690c6752312c514195371d061e11bf5d', '::1', '9e52169b3b1bbc4537b1764d2a809f4de8629324c7677ef44f5422df5a14543a', '{"reason": "invalid_credentials"}', '2026-05-07 10:02:35.598028-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('9c1d43c6-fd18-4f5f-b349-6a60927c21d6', 'login_success', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', '36947ce11e288bda6fa485ed5b51c523690c6752312c514195371d061e11bf5d', '::1', '9e52169b3b1bbc4537b1764d2a809f4de8629324c7677ef44f5422df5a14543a', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-07 10:02:46.374265-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('d5c222bf-5785-40d1-895d-e0e580acccd3', 'session_fingerprint_mismatch', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', NULL, '::1', '545ea538461003efdc8c81c244531b003f6f26cfccf6c0073b3239fdedf49446', '{"checkIp": false, "checkUA": true, "ipMismatch": false, "uaMismatch": true}', '2026-05-07 10:03:07.849207-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('3c874bb6-bb9d-4025-ae89-c53fce6c54fc', 'login_failed', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', '36947ce11e288bda6fa485ed5b51c523690c6752312c514195371d061e11bf5d', '::1', '9e52169b3b1bbc4537b1764d2a809f4de8629324c7677ef44f5422df5a14543a', '{"reason": "invalid_credentials"}', '2026-05-07 10:11:13.92323-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('8fa6596a-f35f-4548-adc7-99c893010cbe', 'login_success', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', '36947ce11e288bda6fa485ed5b51c523690c6752312c514195371d061e11bf5d', '::1', '9e52169b3b1bbc4537b1764d2a809f4de8629324c7677ef44f5422df5a14543a', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-07 10:11:21.812783-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('41087fe1-ae60-4222-afbf-b03e831c8538', 'session_fingerprint_mismatch', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', NULL, '::1', '545ea538461003efdc8c81c244531b003f6f26cfccf6c0073b3239fdedf49446', '{"checkIp": false, "checkUA": true, "ipMismatch": false, "uaMismatch": true}', '2026-05-07 10:11:41.523324-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('cd6c0a6d-1733-4bd0-a4cf-2b06e00baa44', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '545ea538461003efdc8c81c244531b003f6f26cfccf6c0073b3239fdedf49446', '{"idleMs": 1800000}', '2026-05-07 10:14:13.016312-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('f1cf3d37-ae6a-4a73-a639-31b9ea6682cf', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-07 10:14:45.480639-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('64527c52-d2a1-4479-85d9-8d35b2b119c3', 'logout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-07 10:16:15.49007-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('c2362e62-9522-46e1-81e8-7fb1ac04d32b', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-07 10:16:22.899571-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('3f231a6f-8ef4-4e32-8bfc-1e3fc4497084', 'logout', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', NULL, '::1', '9e52169b3b1bbc4537b1764d2a809f4de8629324c7677ef44f5422df5a14543a', '{}', '2026-05-07 10:16:27.079929-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('afe421fb-84f1-46fe-a281-fd16747c3a57', 'login_success', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', '36947ce11e288bda6fa485ed5b51c523690c6752312c514195371d061e11bf5d', '::1', '9e52169b3b1bbc4537b1764d2a809f4de8629324c7677ef44f5422df5a14543a', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-07 10:16:49.588205-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('67cb1e2e-ef9f-48e7-a23b-0e6a562fcc98', 'logout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-07 10:22:36.458575-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('0f05521d-2cff-4dbd-a977-a41181fdd0eb', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-07 10:22:43.164753-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('38e96623-fd76-4822-8f0f-458929923d28', 'session_fingerprint_mismatch', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', NULL, '::1', '387ae7aef0ff2cb88b68b8790a2f5eb8b677c19a765a3118517b46df17c55193', '{"checkIp": false, "checkUA": true, "ipMismatch": false, "uaMismatch": true}', '2026-05-07 10:26:21.74635-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('0cf05807-9b16-4014-84ed-b044fbdd971f', 'login_success', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', '36947ce11e288bda6fa485ed5b51c523690c6752312c514195371d061e11bf5d', '::1', '387ae7aef0ff2cb88b68b8790a2f5eb8b677c19a765a3118517b46df17c55193', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-07 10:30:18.048844-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('e96a4156-7262-41ee-82f4-f8a965309709', 'session_fingerprint_mismatch', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', NULL, '::1', '9e52169b3b1bbc4537b1764d2a809f4de8629324c7677ef44f5422df5a14543a', '{"checkIp": false, "checkUA": true, "ipMismatch": false, "uaMismatch": true}', '2026-05-07 10:32:23.275874-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('80d51230-737d-4805-b1d8-2b2306bfe927', 'session_fingerprint_mismatch', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', NULL, '::1', '9e52169b3b1bbc4537b1764d2a809f4de8629324c7677ef44f5422df5a14543a', '{"checkIp": false, "checkUA": true, "ipMismatch": false, "uaMismatch": true}', '2026-05-07 10:32:23.276955-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('bcef86dc-5f5c-4474-b981-795ebc140520', 'login_success', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', '36947ce11e288bda6fa485ed5b51c523690c6752312c514195371d061e11bf5d', '::1', '9e52169b3b1bbc4537b1764d2a809f4de8629324c7677ef44f5422df5a14543a', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-07 10:32:44.009799-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('b2d2150b-4db3-4fe9-93aa-c00da7e0f3a2', 'login_success', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', '36947ce11e288bda6fa485ed5b51c523690c6752312c514195371d061e11bf5d', '::1', '387ae7aef0ff2cb88b68b8790a2f5eb8b677c19a765a3118517b46df17c55193', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-07 10:34:18.85238-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('5c583d98-ed63-4af5-8a23-bd2377193ba1', 'session_fingerprint_mismatch', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', NULL, '::1', '9e52169b3b1bbc4537b1764d2a809f4de8629324c7677ef44f5422df5a14543a', '{"checkIp": false, "checkUA": true, "ipMismatch": false, "uaMismatch": true}', '2026-05-07 10:34:34.606707-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('a078491f-f60a-4f10-98c6-d4409f613f89', 'login_success', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889', '36947ce11e288bda6fa485ed5b51c523690c6752312c514195371d061e11bf5d', '::1', '9e52169b3b1bbc4537b1764d2a809f4de8629324c7677ef44f5422df5a14543a', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-07 10:34:52.083182-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('e979097c-d9f5-47c6-963c-8fa1e677f169', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-07 11:48:51.702402-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('5294ddf6-c361-4544-b87e-b5adf12a856b', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-08 11:12:02.780949-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('314460f5-e21b-42a5-9141-65ab67caf4c8', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-08 11:12:15.682647-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('d1a62d90-3f37-4d73-8e19-2b64f3f7214c', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-11 10:06:07.745548-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('8aa73e91-8a92-4298-95f7-cd7dcd111cf8', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-12 10:19:47.873274-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('cd90d48d-77e3-4858-b6a4-6333744ebf7c', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-12 13:27:00.207433-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('744999ed-67e2-4714-b039-c9ed83e0455f', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-12 13:49:40.343076-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('190c338e-464d-4159-bfe2-bc5aa0217057', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-12 14:29:43.851218-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('cfc27a97-548f-4c31-8d70-a1839eaad91e', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-13 08:59:21.075561-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('f9ade617-951c-49a7-9530-11289c06decd', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-13 08:59:30.676609-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('db061201-e74a-442e-ad6c-31c41bc61064', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-13 10:34:19.484825-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('7e55e51a-0c57-4b68-8227-12694f095e3f', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-13 10:34:28.601839-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('b52a0380-8595-4bec-90bc-12b44ac0b405', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-13 11:53:50.320586-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('5cf69095-caa7-4d31-8d38-33080ececa09', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-13 11:54:30.685484-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('a54f2a47-b3e4-4e89-944a-b3a60f43172e', 'password_changed', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-13 12:18:51.091357-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('29153ecf-9977-4e76-b7d7-19016c03b76f', 'logout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-13 12:18:57.681031-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('9498f7d4-78ee-47c8-babe-f53a3d8161ca', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-13 12:19:04.195454-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('d18dbc37-4c5b-45cf-a2da-0a504b9a92f2', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-13 12:51:44.991326-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('176ee4b2-fa6d-4808-9aec-3d13cea26038', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-13 12:51:55.8423-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('2e7f6b3d-989e-42d0-be9c-8a3ab82885bc', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-13 13:42:24.715108-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('41ccc034-7a39-4664-ba03-af13978d008f', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-13 13:42:43.251699-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('4a4e46cd-36d5-43f0-943a-d17fd09cbc5a', 'logout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-13 15:48:35.904885-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('c2993793-a717-481a-aaaf-10a06f2143e1', 'login_success', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'f210e6bad979ed6b34a4c087ba9e4711784f46906f327dd47b29dfd6aee9c631', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "76c96941-2c29-4aa7-96cb-3e931ad36283"}', '2026-05-13 15:48:46.527946-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('2fd0883e-8bfe-44f9-82e9-aecc8eeeb4a4', 'logout', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-13 15:48:50.014919-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('9608a584-389c-41a8-b2c6-0a59ba414965', 'password_reset_requested', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'f210e6bad979ed6b34a4c087ba9e4711784f46906f327dd47b29dfd6aee9c631', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"via": "self_service"}', '2026-05-13 15:49:05.080835-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('d12d3f5d-696f-4b04-8bd4-8760470f8472', 'password_reset_completed', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '387ae7aef0ff2cb88b68b8790a2f5eb8b677c19a765a3118517b46df17c55193', '{}', '2026-05-13 15:49:47.664241-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('23631c95-44fb-474d-87c3-e2e156658b5c', 'login_success', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'f210e6bad979ed6b34a4c087ba9e4711784f46906f327dd47b29dfd6aee9c631', '::1', '387ae7aef0ff2cb88b68b8790a2f5eb8b677c19a765a3118517b46df17c55193', '{"roleId": "76c96941-2c29-4aa7-96cb-3e931ad36283"}', '2026-05-13 15:50:07.145096-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('1c417bf3-2ec5-45d3-8f50-166b9fd957ef', 'password_reset_requested', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'f210e6bad979ed6b34a4c087ba9e4711784f46906f327dd47b29dfd6aee9c631', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"via": "self_service"}', '2026-05-13 16:00:24.270439-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('93beddee-2e07-4ff5-b54f-5d94b4cea121', 'password_reset_requested', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'f210e6bad979ed6b34a4c087ba9e4711784f46906f327dd47b29dfd6aee9c631', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"via": "self_service"}', '2026-05-13 16:01:36.615735-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('9bb0840e-a61c-417b-93ed-0052941a32e9', 'password_reset_requested', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'f210e6bad979ed6b34a4c087ba9e4711784f46906f327dd47b29dfd6aee9c631', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"via": "self_service"}', '2026-05-13 16:04:21.411826-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('ac5f30f7-f796-4f35-8a69-4dcd9a8086fd', 'password_reset_requested', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'f210e6bad979ed6b34a4c087ba9e4711784f46906f327dd47b29dfd6aee9c631', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"via": "self_service"}', '2026-05-13 16:05:38.6301-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('a4de9f2a-f30c-47f3-96d3-a4ddebef77c6', 'password_reset_requested', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'f210e6bad979ed6b34a4c087ba9e4711784f46906f327dd47b29dfd6aee9c631', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"via": "self_service"}', '2026-05-13 16:07:48.671096-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('b15a695c-aaf4-4747-89c4-e6db9916241d', 'password_reset_requested', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'f210e6bad979ed6b34a4c087ba9e4711784f46906f327dd47b29dfd6aee9c631', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"via": "self_service"}', '2026-05-13 16:22:22.739193-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('bc8c90fd-ffce-4f61-abcf-a3f7f58f5ceb', 'login_failed', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"reason": "invalid_credentials"}', '2026-05-13 16:23:59.497838-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('de32490c-eb2f-4487-8f3b-7b0d7deda769', 'login_failed', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"reason": "invalid_credentials"}', '2026-05-13 16:24:08.640204-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('fe23285a-8590-414d-a3ea-b420f3dbceaf', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-13 16:24:15.495935-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('6c58b374-4fea-4842-9467-6ba75061dd93', 'login_success', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'f210e6bad979ed6b34a4c087ba9e4711784f46906f327dd47b29dfd6aee9c631', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "76c96941-2c29-4aa7-96cb-3e931ad36283"}', '2026-05-13 17:11:22.062764-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('31ac1d2d-9799-4c78-a78b-67c4806960fa', 'logout', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-13 17:16:10.918252-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('7414bf9c-ca61-498f-b151-a9e64fc449e5', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-13 17:16:19.15025-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('310e0ba2-1ea9-4db4-a11c-be2f7c7564a8', 'logout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-13 17:39:26.222405-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('eb30fc8c-c407-4c50-ac0b-1f3c13613372', 'login_success', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', 'f210e6bad979ed6b34a4c087ba9e4711784f46906f327dd47b29dfd6aee9c631', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "76c96941-2c29-4aa7-96cb-3e931ad36283"}', '2026-05-13 17:39:33.1404-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('0c9ff043-cbf1-44ad-8a90-35abe9c097dd', 'session_idle_timeout', '089c211c-3f84-4bf4-ab24-ae82ae6be122', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-14 06:39:42.12922-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('17db6f4a-2762-491c-ad1f-7f758a5ef006', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-14 06:40:19.806582-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('40a9e3b4-e5e1-4dd0-9ff5-859fd1bad781', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-14 08:23:01.789212-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('d2ca94a6-4081-40b6-91ff-cfcb4e5a2df8', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-14 08:23:13.942219-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('e1270e1c-08de-447f-a811-5156c1ef1ca1', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-14 09:14:17.72373-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('fccb738e-5a64-4c13-a7c2-fb78ddf875c2', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-14 09:14:17.728532-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('e1db8a14-d1b8-4043-a8cb-0cf983776efa', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-14 09:14:26.44506-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('34941056-89e8-47cd-a52a-8097b091ddd4', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-14 10:32:10.710139-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('81498b33-59a8-4b21-8a78-c023af962e1b', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-14 11:47:38.4764-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('4c5c7a7b-9833-4237-805b-4be68e83988f', 'logout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-14 11:48:22.141867-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('e669b3f3-4aa8-414d-a500-807ae21ce68f', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-14 11:48:29.510103-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('a7ac3c97-e1fd-40f6-9cb3-94a985b0b3dd', 'logout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-14 11:56:51.948327-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('6275573f-0fed-4979-86d9-431d338e29bc', 'login_success', '089c211c-3f84-4bf4-ab24-ae82ae6be122', NULL, 'f210e6bad979ed6b34a4c087ba9e4711784f46906f327dd47b29dfd6aee9c631', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "7ee10aa4-9da8-47be-81cf-497d20bba0dc"}', '2026-05-14 11:57:09.49694-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('e1b2ab74-c125-4d85-9d39-3b57bd5aa214', 'logout', '089c211c-3f84-4bf4-ab24-ae82ae6be122', NULL, NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-14 11:58:25.811372-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('66259516-4dfb-40c1-8667-7222e611adc9', 'login_success', '85fe6b9f-d12a-40c8-8b62-6b890ba5f481', '08545840-e851-4753-97f0-eefc09236e90', 'eab02e57ff437bb55ae29984389b01335b8a89b91d22fb02b7fc0ee53abe66e4', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-14 11:58:42.761565-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('25417709-167d-49d4-8d9a-6b217109076e', 'logout', '85fe6b9f-d12a-40c8-8b62-6b890ba5f481', '08545840-e851-4753-97f0-eefc09236e90', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-14 11:59:12.736805-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('87d3debe-ef30-4f40-82de-7fe8aa7cecaf', 'login_success', '089c211c-3f84-4bf4-ab24-ae82ae6be122', NULL, 'f210e6bad979ed6b34a4c087ba9e4711784f46906f327dd47b29dfd6aee9c631', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "7ee10aa4-9da8-47be-81cf-497d20bba0dc"}', '2026-05-14 11:59:21.515663-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('162618e5-aaa7-4f48-94fd-6cc5df9d7ca0', 'logout', '089c211c-3f84-4bf4-ab24-ae82ae6be122', NULL, NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-14 11:59:51.290832-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('b243af85-64a4-4029-a4f2-0f2ab9cbf533', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-14 11:59:58.267006-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('87f632b5-83f1-4c37-ad04-7d766763eb36', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-15 05:08:48.826969-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('ee17fc9f-3ec8-4cad-98ff-8557f8c6fdd5', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-15 05:09:01.807091-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('74cb0175-ded3-4a4e-88b4-a55df779ca35', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-15 06:20:48.473807-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('6529e547-8833-48d0-9a18-5cd28e58ee38', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-15 06:20:48.470236-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('5213306e-6fbe-4539-b8c2-cc22030d4091', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-15 06:21:03.722606-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('de211110-1389-47f5-a31b-b75ded35abfb', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-15 13:32:25.463337-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('a08d286c-cfb7-45bb-bf1b-719db8fa2d16', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-15 13:32:51.694861-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('e2479a04-949a-4e41-836a-0543ddbc955d', 'logout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-15 13:34:47.035181-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('0d2f68d4-9ef0-408e-be72-e54578aae256', 'login_success', '089c211c-3f84-4bf4-ab24-ae82ae6be122', NULL, 'f210e6bad979ed6b34a4c087ba9e4711784f46906f327dd47b29dfd6aee9c631', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "7ee10aa4-9da8-47be-81cf-497d20bba0dc"}', '2026-05-15 13:35:12.726178-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('57ebf0a0-1c6b-4908-9b49-691584d6a5bd', 'logout', '089c211c-3f84-4bf4-ab24-ae82ae6be122', NULL, NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-15 13:35:29.270886-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('0b541e3f-e7a9-4e4f-8a46-3ba0717415f4', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-15 13:35:36.659415-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('6bd0b09c-0f5d-45cb-a9e9-745601f0a3a4', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"idleMs": 1800000}', '2026-05-15 14:05:45.702074-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('2026923d-fee6-4cd4-83ca-d81029882225', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-15 14:11:26.949574-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('4e84647d-b4cb-4dd3-ab9b-b15c3f4279d3', 'logout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{}', '2026-05-15 14:32:10.365545-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('9aae3785-a870-4b44-9538-43c7529632b2', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '0bd344b0c35df6194768cf96fa21de8bf7729ee8f2bbb2e21eeba7b741b53119', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-15 14:32:17.777753-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('c7e35920-7f98-4f7b-8646-0779fa9995f5', 'session_idle_timeout', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', NULL, '::1', '2efe31d10f76c485332c7bf4dba8fe8272eb4cb7f5e35d544dc126eb3bf993be', '{"idleMs": 1800000}', '2026-05-15 16:37:39.644305-06');
INSERT INTO public.security_audit_logs (id, event_type, user_id, client_id, identifier_hash, ip_address, user_agent_hash, metadata, created_at) VALUES ('47af5f08-25ce-4924-922a-27fc244f8bfb', 'login_success', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '28006bc34ecf97c52aff308831604f61cb22cca6be485ae43b7134ed6d5be35a', '::1', '2efe31d10f76c485332c7bf4dba8fe8272eb4cb7f5e35d544dc126eb3bf993be', '{"roleId": "02a6e105-c800-468a-b64b-64f89e9e103c"}', '2026-05-15 16:37:48.530089-06');


--
-- TOC entry 7486 (class 0 OID 57475)
-- Dependencies: 341
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 6380 (class 0 OID 55117)
-- Dependencies: 228
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 7487 (class 0 OID 57489)
-- Dependencies: 342
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users (id, is_active, first_name, last_name_1, last_name_2, email, phone_1, phone_2, id_type, id_number, password_hash, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id, role_id, failed_attempts, locked_until) VALUES ('4b523322-cc8f-461e-958a-5bb78db26af7', true, 'Concurrency', 'Tester', NULL, 'concurrency-1778001818182@local.test', NULL, NULL, 'nacional', '1778001818182', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga311W', '2026-05-05 11:23:38.185089-06', '2026-05-13 11:55:43.726983-06', NULL, 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '76c96941-2c29-4aa7-96cb-3e931ad36283', 0, NULL);
INSERT INTO public.users (id, is_active, first_name, last_name_1, last_name_2, email, phone_1, phone_2, id_type, id_number, password_hash, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id, role_id, failed_attempts, locked_until) VALUES ('89e2b58e-057c-4f7b-908b-30d1086c076d', true, 'Administrador', 'Principal', 'Sistema', 'admin@wardi.local', '88888888', NULL, 'nacional', '123456780', '$2b$12$8CHw7r903bfTy.slI5cxE.pnzNmz5GFBG/sIvd.czIooKuQ8DCruC', '2026-05-07 09:45:41.160379-06', '2026-05-07 10:34:52.07959-06', NULL, NULL, '80ee1408-ed96-4301-8d6e-f891e5db8889', '02a6e105-c800-468a-b64b-64f89e9e103c', 0, NULL);
INSERT INTO public.users (id, is_active, first_name, last_name_1, last_name_2, email, phone_1, phone_2, id_type, id_number, password_hash, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id, role_id, failed_attempts, locked_until) VALUES ('e7eb16d3-0d33-4c20-90ec-18404aa0130b', true, 'Usuario', 'Demo', NULL, 'demo@wardi.local', NULL, NULL, 'nacional', '123456789', '$2b$12$TXg8H.j9tpQJNr6hVmu0fe7SkylPkn1yWcUz03muSU583c1Usiiyi', '2026-05-05 11:44:48.852164-06', '2026-05-21 11:49:42.552883-06', NULL, NULL, 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be', '02a6e105-c800-468a-b64b-64f89e9e103c', 0, NULL);
INSERT INTO public.users (id, is_active, first_name, last_name_1, last_name_2, email, phone_1, phone_2, id_type, id_number, password_hash, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id, role_id, failed_attempts, locked_until) VALUES ('cdd37998-50ad-4bdf-a50d-b0489e0d7a72', true, 'Ricardo', 'Rivera', 'Araya', 'crrivera27@gmail.com', NULL, NULL, 'extranjero', 'ADM-05b36428f2164f8fbdc2f5d3cf540140', '$2b$12$KgeRt6SItdFNjmaNhRMZZeEmbByny6SaOAhh1muxJXx5Da20jFp22', '2026-05-22 09:44:35.877309-06', '2026-05-22 09:46:51.283682-06', '089c211c-3f84-4bf4-ab24-ae82ae6be122', '089c211c-3f84-4bf4-ab24-ae82ae6be122', '24d16b37-51ad-47ce-8f9d-68695ebbc0d8', '02a6e105-c800-468a-b64b-64f89e9e103c', 0, NULL);
INSERT INTO public.users (id, is_active, first_name, last_name_1, last_name_2, email, phone_1, phone_2, id_type, id_number, password_hash, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id, role_id, failed_attempts, locked_until) VALUES ('089c211c-3f84-4bf4-ab24-ae82ae6be122', true, 'Vera', 'Tester', 'Navarro', 'vera2vn@gmail.com', NULL, NULL, 'nacional', '1778001818183', '$2b$12$YJYkUe1SgCZIlK6haEggqu/Lx83GnSXjNp3G1gOl5Zzk.n77LxEdC', '2026-05-13 11:56:04.671563-06', '2026-05-22 10:41:08.824598-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', NULL, '7ee10aa4-9da8-47be-81cf-497d20bba0dc', 0, NULL);


--
-- TOC entry 7488 (class 0 OID 57511)
-- Dependencies: 343
-- Data for Name: workers; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.workers (id, worker_type, is_active, first_name, last_name_1, last_name_2, id_type, id_number, phone, notes, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('159d7239-8cd7-496e-9f8a-05c4507677ec', 'ocasional', true, 'Juan', 'Pérez', NULL, 'nacional', '15263412', '15488', NULL, '2026-05-06 09:51:55.486998-06', '2026-05-06 10:11:32.13796-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.workers (id, worker_type, is_active, first_name, last_name_1, last_name_2, id_type, id_number, phone, notes, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('7d8d4e67-56fe-4524-aa7e-e1ad23a6de2f', 'fijo', true, 'juan', 'soto', NULL, 'nacional', NULL, NULL, NULL, '2026-05-07 10:30:50.022432-06', '2026-05-07 10:30:50.022432-06', '89e2b58e-057c-4f7b-908b-30d1086c076d', '89e2b58e-057c-4f7b-908b-30d1086c076d', '80ee1408-ed96-4301-8d6e-f891e5db8889');
INSERT INTO public.workers (id, worker_type, is_active, first_name, last_name_1, last_name_2, id_type, id_number, phone, notes, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('9a6e581e-6625-4400-a49b-dc06cf829223', 'fijo', true, 'Vera', 'Valverde', 'Navarro', 'nacional', NULL, NULL, NULL, '2026-05-13 09:27:17.003724-06', '2026-05-13 09:27:17.003724-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.workers (id, worker_type, is_active, first_name, last_name_1, last_name_2, id_type, id_number, phone, notes, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('132127c3-636f-409e-ab66-e6defd9e722c', 'ocasional', true, 'Prueba', NULL, NULL, 'extranjero', NULL, NULL, NULL, '2026-05-13 09:33:16.123307-06', '2026-05-13 09:33:16.123307-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');
INSERT INTO public.workers (id, worker_type, is_active, first_name, last_name_1, last_name_2, id_type, id_number, phone, notes, created_at, updated_at, created_by_user_id, updated_by_user_id, client_id) VALUES ('fa93548d-f275-43f4-85e5-e1e42110ce14', 'fijo', true, 'Prueba', NULL, NULL, 'nacional', NULL, NULL, NULL, '2026-05-15 14:53:27.6513-06', '2026-05-15 14:53:27.6513-06', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'e7eb16d3-0d33-4c20-90ec-18404aa0130b', 'a8f6dc31-bcc0-4d26-8d75-d91716ee74be');


--
-- TOC entry 6381 (class 0 OID 55886)
-- Dependencies: 233
-- Data for Name: geocode_settings; Type: TABLE DATA; Schema: tiger; Owner: -
--



--
-- TOC entry 6382 (class 0 OID 56247)
-- Dependencies: 278
-- Data for Name: pagc_gaz; Type: TABLE DATA; Schema: tiger; Owner: -
--



--
-- TOC entry 6383 (class 0 OID 56259)
-- Dependencies: 280
-- Data for Name: pagc_lex; Type: TABLE DATA; Schema: tiger; Owner: -
--



--
-- TOC entry 6384 (class 0 OID 56271)
-- Dependencies: 282
-- Data for Name: pagc_rules; Type: TABLE DATA; Schema: tiger; Owner: -
--



--
-- TOC entry 6386 (class 0 OID 56315)
-- Dependencies: 284
-- Data for Name: topology; Type: TABLE DATA; Schema: topology; Owner: -
--



--
-- TOC entry 6387 (class 0 OID 56334)
-- Dependencies: 285
-- Data for Name: layer; Type: TABLE DATA; Schema: topology; Owner: -
--



--
-- TOC entry 7516 (class 0 OID 0)
-- Dependencies: 297
-- Name: cantons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cantons_id_seq', 1, false);


--
-- TOC entry 7517 (class 0 OID 0)
-- Dependencies: 300
-- Name: districts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.districts_id_seq', 1, false);


--
-- TOC entry 7518 (class 0 OID 0)
-- Dependencies: 337
-- Name: provinces_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.provinces_id_seq', 1, false);


--
-- TOC entry 7519 (class 0 OID 0)
-- Dependencies: 283
-- Name: topology_id_seq; Type: SEQUENCE SET; Schema: topology; Owner: -
--

SELECT pg_catalog.setval('topology.topology_id_seq', 1, false);


--
-- TOC entry 6808 (class 2606 OID 57528)
-- Name: aguinaldo_statements aguinaldo_statements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aguinaldo_statements
    ADD CONSTRAINT aguinaldo_statements_pkey PRIMARY KEY (id);


--
-- TOC entry 6813 (class 2606 OID 57530)
-- Name: asset_categories asset_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_categories
    ADD CONSTRAINT asset_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 6817 (class 2606 OID 57532)
-- Name: asset_depreciation asset_depreciation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_depreciation
    ADD CONSTRAINT asset_depreciation_pkey PRIMARY KEY (id);


--
-- TOC entry 6821 (class 2606 OID 57534)
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- TOC entry 6828 (class 2606 OID 57536)
-- Name: calendar_activities calendar_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_activities
    ADD CONSTRAINT calendar_activities_pkey PRIMARY KEY (id);


--
-- TOC entry 6831 (class 2606 OID 57538)
-- Name: calibers calibers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calibers
    ADD CONSTRAINT calibers_pkey PRIMARY KEY (id);


--
-- TOC entry 6835 (class 2606 OID 57540)
-- Name: cantons cantons_official_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cantons
    ADD CONSTRAINT cantons_official_code_key UNIQUE (official_code);


--
-- TOC entry 6837 (class 2606 OID 57542)
-- Name: cantons cantons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cantons
    ADD CONSTRAINT cantons_pkey PRIMARY KEY (id);


--
-- TOC entry 6839 (class 2606 OID 57544)
-- Name: cantons cantons_province_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cantons
    ADD CONSTRAINT cantons_province_id_name_key UNIQUE (province_id, name);


--
-- TOC entry 6841 (class 2606 OID 57546)
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- TOC entry 7049 (class 2606 OID 58706)
-- Name: coffee_lot_production coffee_lot_production_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coffee_lot_production
    ADD CONSTRAINT coffee_lot_production_pkey PRIMARY KEY (id);


--
-- TOC entry 6824 (class 2606 OID 57548)
-- Name: coffee_varieties coffee_varieties_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coffee_varieties
    ADD CONSTRAINT coffee_varieties_name_key UNIQUE (name);


--
-- TOC entry 6826 (class 2606 OID 57550)
-- Name: coffee_varieties coffee_varieties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coffee_varieties
    ADD CONSTRAINT coffee_varieties_pkey PRIMARY KEY (id);


--
-- TOC entry 6843 (class 2606 OID 57552)
-- Name: districts districts_canton_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_canton_id_name_key UNIQUE (canton_id, name);


--
-- TOC entry 6845 (class 2606 OID 57554)
-- Name: districts districts_official_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_official_code_key UNIQUE (official_code);


--
-- TOC entry 6847 (class 2606 OID 57556)
-- Name: districts districts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_pkey PRIMARY KEY (id);


--
-- TOC entry 6849 (class 2606 OID 57558)
-- Name: expense_categories expense_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expense_categories
    ADD CONSTRAINT expense_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 6853 (class 2606 OID 57560)
-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (id);


--
-- TOC entry 6857 (class 2606 OID 57562)
-- Name: farm_harvest_estimates farm_harvest_estimates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farm_harvest_estimates
    ADD CONSTRAINT farm_harvest_estimates_pkey PRIMARY KEY (farm_id, harvest_id);


--
-- TOC entry 6861 (class 2606 OID 57564)
-- Name: farms farms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT farms_pkey PRIMARY KEY (id);


--
-- TOC entry 6870 (class 2606 OID 57566)
-- Name: fixed_payroll_allocations fixed_payroll_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_payroll_allocations
    ADD CONSTRAINT fixed_payroll_allocations_pkey PRIMARY KEY (id);


--
-- TOC entry 6867 (class 2606 OID 57568)
-- Name: fixed_payroll fixed_payroll_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_payroll
    ADD CONSTRAINT fixed_payroll_pkey PRIMARY KEY (id);


--
-- TOC entry 6873 (class 2606 OID 57570)
-- Name: general_expense_allocations general_expense_allocations_general_expense_id_lot_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.general_expense_allocations
    ADD CONSTRAINT general_expense_allocations_general_expense_id_lot_id_key UNIQUE (general_expense_id, lot_id);


--
-- TOC entry 6875 (class 2606 OID 57572)
-- Name: general_expense_allocations general_expense_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.general_expense_allocations
    ADD CONSTRAINT general_expense_allocations_pkey PRIMARY KEY (id);


--
-- TOC entry 6879 (class 2606 OID 57574)
-- Name: general_expenses general_expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.general_expenses
    ADD CONSTRAINT general_expenses_pkey PRIMARY KEY (id);


--
-- TOC entry 6885 (class 2606 OID 57576)
-- Name: harvests harvests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harvests
    ADD CONSTRAINT harvests_pkey PRIMARY KEY (id);


--
-- TOC entry 6888 (class 2606 OID 57578)
-- Name: inventory_brands inventory_brands_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_brands
    ADD CONSTRAINT inventory_brands_pkey PRIMARY KEY (id);


--
-- TOC entry 6894 (class 2606 OID 57580)
-- Name: inventory_categories inventory_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_categories
    ADD CONSTRAINT inventory_categories_pkey PRIMARY KEY (id);


--
-- TOC entry 6897 (class 2606 OID 57582)
-- Name: inventory_consumption_layers inventory_consumption_layers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_consumption_layers
    ADD CONSTRAINT inventory_consumption_layers_pkey PRIMARY KEY (id);


--
-- TOC entry 6900 (class 2606 OID 57584)
-- Name: inventory_consumptions inventory_consumptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_consumptions
    ADD CONSTRAINT inventory_consumptions_pkey PRIMARY KEY (id);


--
-- TOC entry 6905 (class 2606 OID 57586)
-- Name: inventory_item_ingredients inventory_item_ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_item_ingredients
    ADD CONSTRAINT inventory_item_ingredients_pkey PRIMARY KEY (id);


--
-- TOC entry 6911 (class 2606 OID 57588)
-- Name: inventory_items inventory_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_pkey PRIMARY KEY (id);


--
-- TOC entry 6916 (class 2606 OID 57590)
-- Name: inventory_layers inventory_layers_movement_in_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_layers
    ADD CONSTRAINT inventory_layers_movement_in_id_key UNIQUE (movement_in_id);


--
-- TOC entry 6918 (class 2606 OID 57592)
-- Name: inventory_layers inventory_layers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_layers
    ADD CONSTRAINT inventory_layers_pkey PRIMARY KEY (id);


--
-- TOC entry 6922 (class 2606 OID 57594)
-- Name: inventory_movement_layers inventory_movement_layers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movement_layers
    ADD CONSTRAINT inventory_movement_layers_pkey PRIMARY KEY (id);


--
-- TOC entry 6925 (class 2606 OID 57596)
-- Name: inventory_movements inventory_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movements
    ADD CONSTRAINT inventory_movements_pkey PRIMARY KEY (id);


--
-- TOC entry 6931 (class 2606 OID 57598)
-- Name: labor_entries labor_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_entries
    ADD CONSTRAINT labor_entries_pkey PRIMARY KEY (id);


--
-- TOC entry 6938 (class 2606 OID 57600)
-- Name: labor_entry_allocations labor_entry_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_entry_allocations
    ADD CONSTRAINT labor_entry_allocations_pkey PRIMARY KEY (id);


--
-- TOC entry 6943 (class 2606 OID 57602)
-- Name: labor_rates labor_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_rates
    ADD CONSTRAINT labor_rates_pkey PRIMARY KEY (id);


--
-- TOC entry 6945 (class 2606 OID 57604)
-- Name: labor_types labor_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_types
    ADD CONSTRAINT labor_types_name_key UNIQUE (name);


--
-- TOC entry 6947 (class 2606 OID 57606)
-- Name: labor_types labor_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_types
    ADD CONSTRAINT labor_types_pkey PRIMARY KEY (id);


--
-- TOC entry 6951 (class 2606 OID 57608)
-- Name: lot_coffee_varieties lot_coffee_varieties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lot_coffee_varieties
    ADD CONSTRAINT lot_coffee_varieties_pkey PRIMARY KEY (lot_id, coffee_variety_id);


--
-- TOC entry 6953 (class 2606 OID 57610)
-- Name: lot_harvests lot_harvests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lot_harvests
    ADD CONSTRAINT lot_harvests_pkey PRIMARY KEY (lot_id, harvest_id);


--
-- TOC entry 6957 (class 2606 OID 57618)
-- Name: lots lots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lots
    ADD CONSTRAINT lots_pkey PRIMARY KEY (id);


--
-- TOC entry 6961 (class 2606 OID 57620)
-- Name: mix_application_items mix_application_items_mix_application_id_item_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mix_application_items
    ADD CONSTRAINT mix_application_items_mix_application_id_item_id_key UNIQUE (mix_application_id, item_id);


--
-- TOC entry 6963 (class 2606 OID 57622)
-- Name: mix_application_items mix_application_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mix_application_items
    ADD CONSTRAINT mix_application_items_pkey PRIMARY KEY (id);


--
-- TOC entry 6967 (class 2606 OID 57624)
-- Name: mix_applications mix_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mix_applications
    ADD CONSTRAINT mix_applications_pkey PRIMARY KEY (id);


--
-- TOC entry 6974 (class 2606 OID 57626)
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 6981 (class 2606 OID 57628)
-- Name: payroll_employee_rates payroll_employee_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_employee_rates
    ADD CONSTRAINT payroll_employee_rates_pkey PRIMARY KEY (id);


--
-- TOC entry 6985 (class 2606 OID 57630)
-- Name: payroll_nomina_contribution_rules payroll_nomina_contribution_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_nomina_contribution_rules
    ADD CONSTRAINT payroll_nomina_contribution_rules_pkey PRIMARY KEY (id);


--
-- TOC entry 6987 (class 2606 OID 57632)
-- Name: payroll_periods payroll_periods_period_month_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_periods
    ADD CONSTRAINT payroll_periods_period_month_key UNIQUE (period_month);


--
-- TOC entry 6990 (class 2606 OID 57634)
-- Name: payroll_periods payroll_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_periods
    ADD CONSTRAINT payroll_periods_pkey PRIMARY KEY (id);


--
-- TOC entry 6995 (class 2606 OID 57636)
-- Name: payroll_settings payroll_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_settings
    ADD CONSTRAINT payroll_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 6998 (class 2606 OID 57638)
-- Name: payroll_slip_lot_allocations payroll_slip_lot_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_slip_lot_allocations
    ADD CONSTRAINT payroll_slip_lot_allocations_pkey PRIMARY KEY (id);


--
-- TOC entry 7004 (class 2606 OID 57640)
-- Name: payroll_slips payroll_slips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_slips
    ADD CONSTRAINT payroll_slips_pkey PRIMARY KEY (id);


--
-- TOC entry 7006 (class 2606 OID 57642)
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- TOC entry 7008 (class 2606 OID 57644)
-- Name: provinces provinces_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provinces
    ADD CONSTRAINT provinces_name_key UNIQUE (name);


--
-- TOC entry 7010 (class 2606 OID 57646)
-- Name: provinces provinces_official_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provinces
    ADD CONSTRAINT provinces_official_code_key UNIQUE (official_code);


--
-- TOC entry 7012 (class 2606 OID 57648)
-- Name: provinces provinces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provinces
    ADD CONSTRAINT provinces_pkey PRIMARY KEY (id);


--
-- TOC entry 7014 (class 2606 OID 57650)
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- TOC entry 7016 (class 2606 OID 57652)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 7018 (class 2606 OID 57654)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (filename);


--
-- TOC entry 7023 (class 2606 OID 57656)
-- Name: security_audit_logs security_audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_audit_logs
    ADD CONSTRAINT security_audit_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 7034 (class 2606 OID 57658)
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 7036 (class 2606 OID 57660)
-- Name: sessions sessions_session_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_session_token_key UNIQUE (session_token_hash);


--
-- TOC entry 6819 (class 2606 OID 57662)
-- Name: asset_depreciation uq_asset_depreciation_period; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_depreciation
    ADD CONSTRAINT uq_asset_depreciation_period UNIQUE (asset_id, period_year, period_month);


--
-- TOC entry 6891 (class 2606 OID 57664)
-- Name: inventory_brands uq_inventory_brands_id_client; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_brands
    ADD CONSTRAINT uq_inventory_brands_id_client UNIQUE (id, client_id);


--
-- TOC entry 6913 (class 2606 OID 57666)
-- Name: inventory_items uq_inventory_item_client; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT uq_inventory_item_client UNIQUE (id, client_id);


--
-- TOC entry 6941 (class 2606 OID 57668)
-- Name: labor_entry_allocations uq_lea_labor_lot; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_entry_allocations
    ADD CONSTRAINT uq_lea_labor_lot UNIQUE (labor_entry_id, lot_id);


--
-- TOC entry 7043 (class 2606 OID 57670)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 7047 (class 2606 OID 57672)
-- Name: workers workers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workers
    ADD CONSTRAINT workers_pkey PRIMARY KEY (id);


--
-- TOC entry 6858 (class 1259 OID 57673)
-- Name: farms_canton_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX farms_canton_id_idx ON public.farms USING btree (canton_id);


--
-- TOC entry 6859 (class 1259 OID 57674)
-- Name: farms_district_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX farms_district_id_idx ON public.farms USING btree (district_id);


--
-- TOC entry 6862 (class 1259 OID 57675)
-- Name: farms_province_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX farms_province_id_idx ON public.farms USING btree (province_id);


--
-- TOC entry 6809 (class 1259 OID 57676)
-- Name: idx_aguinaldo_client_period; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_aguinaldo_client_period ON public.aguinaldo_statements USING btree (client_id, legal_period_from, legal_period_to);


--
-- TOC entry 6810 (class 1259 OID 57677)
-- Name: idx_aguinaldo_client_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_aguinaldo_client_status ON public.aguinaldo_statements USING btree (client_id, status);


--
-- TOC entry 6871 (class 1259 OID 57678)
-- Name: idx_alloc_lot; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_alloc_lot ON public.fixed_payroll_allocations USING btree (lot_id);


--
-- TOC entry 6814 (class 1259 OID 57679)
-- Name: idx_asset_categories_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_asset_categories_client ON public.asset_categories USING btree (client_id);


--
-- TOC entry 6829 (class 1259 OID 57680)
-- Name: idx_calendar_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_client ON public.calendar_activities USING btree (client_id);


--
-- TOC entry 6832 (class 1259 OID 57681)
-- Name: idx_calibers_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calibers_client ON public.calibers USING btree (client_id);


--
-- TOC entry 7050 (class 1259 OID 58727)
-- Name: idx_coffee_lot_production_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_coffee_lot_production_client ON public.coffee_lot_production USING btree (client_id);


--
-- TOC entry 7051 (class 1259 OID 58728)
-- Name: idx_coffee_lot_production_lot_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_coffee_lot_production_lot_date ON public.coffee_lot_production USING btree (lot_id, prod_date);


--
-- TOC entry 7052 (class 1259 OID 58729)
-- Name: idx_coffee_lot_production_prod_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_coffee_lot_production_prod_date ON public.coffee_lot_production USING btree (client_id, prod_date);


--
-- TOC entry 6895 (class 1259 OID 57682)
-- Name: idx_cons_layers_consumption; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cons_layers_consumption ON public.inventory_consumption_layers USING btree (consumption_id);


--
-- TOC entry 6898 (class 1259 OID 57683)
-- Name: idx_cons_lot_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cons_lot_date ON public.inventory_consumptions USING btree (lot_id, cons_date);


--
-- TOC entry 6854 (class 1259 OID 57684)
-- Name: idx_exp_lot_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exp_lot_date ON public.expenses USING btree (lot_id, exp_date);


--
-- TOC entry 6850 (class 1259 OID 57685)
-- Name: idx_expense_categories_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_expense_categories_client ON public.expense_categories USING btree (client_id);


--
-- TOC entry 6855 (class 1259 OID 57686)
-- Name: idx_expenses_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_expenses_client ON public.expenses USING btree (client_id);


--
-- TOC entry 6863 (class 1259 OID 57687)
-- Name: idx_farms_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_farms_client ON public.farms USING btree (client_id);


--
-- TOC entry 6864 (class 1259 OID 57688)
-- Name: idx_farms_geom_gist; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_farms_geom_gist ON public.farms USING gist (geom);


--
-- TOC entry 6876 (class 1259 OID 57689)
-- Name: idx_gea_ge; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gea_ge ON public.general_expense_allocations USING btree (general_expense_id);


--
-- TOC entry 6877 (class 1259 OID 57690)
-- Name: idx_gea_lot; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gea_lot ON public.general_expense_allocations USING btree (lot_id);


--
-- TOC entry 6880 (class 1259 OID 57691)
-- Name: idx_general_expenses_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_general_expenses_client ON public.general_expenses USING btree (client_id);


--
-- TOC entry 6881 (class 1259 OID 57692)
-- Name: idx_general_expenses_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_general_expenses_date ON public.general_expenses USING btree (exp_date);


--
-- TOC entry 6882 (class 1259 OID 57693)
-- Name: idx_general_expenses_farm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_general_expenses_farm ON public.general_expenses USING btree (farm_id);


--
-- TOC entry 6883 (class 1259 OID 57694)
-- Name: idx_general_expenses_harvest; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_general_expenses_harvest ON public.general_expenses USING btree (harvest_id);


--
-- TOC entry 6886 (class 1259 OID 57695)
-- Name: idx_harvests_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_harvests_client ON public.harvests USING btree (client_id);


--
-- TOC entry 6919 (class 1259 OID 57696)
-- Name: idx_inv_mov_layers_layer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_mov_layers_layer ON public.inventory_movement_layers USING btree (layer_id);


--
-- TOC entry 6920 (class 1259 OID 57697)
-- Name: idx_inv_mov_layers_movement; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_mov_layers_movement ON public.inventory_movement_layers USING btree (movement_id);


--
-- TOC entry 6906 (class 1259 OID 57698)
-- Name: idx_inventory_items_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_items_client ON public.inventory_items USING btree (client_id);


--
-- TOC entry 6926 (class 1259 OID 57699)
-- Name: idx_labor_entries_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_labor_entries_client ON public.labor_entries USING btree (client_id);


--
-- TOC entry 6927 (class 1259 OID 57700)
-- Name: idx_labor_entries_farm_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_labor_entries_farm_id ON public.labor_entries USING btree (farm_id) WHERE (farm_id IS NOT NULL);


--
-- TOC entry 6928 (class 1259 OID 57701)
-- Name: idx_labor_lot_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_labor_lot_date ON public.labor_entries USING btree (lot_id, work_date);


--
-- TOC entry 6929 (class 1259 OID 57702)
-- Name: idx_labor_worker_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_labor_worker_date ON public.labor_entries USING btree (worker_id, work_date);


--
-- TOC entry 6948 (class 1259 OID 57703)
-- Name: idx_lav_lot; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lav_lot ON public.lot_coffee_varieties USING btree (lot_id);


--
-- TOC entry 6949 (class 1259 OID 57704)
-- Name: idx_lav_variety; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lav_variety ON public.lot_coffee_varieties USING btree (coffee_variety_id);


--
-- TOC entry 6914 (class 1259 OID 57705)
-- Name: idx_layers_item_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_layers_item_date ON public.inventory_layers USING btree (item_id, layer_date, created_at);


--
-- TOC entry 6935 (class 1259 OID 57706)
-- Name: idx_lea_labor_entry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lea_labor_entry ON public.labor_entry_allocations USING btree (labor_entry_id);


--
-- TOC entry 6936 (class 1259 OID 57707)
-- Name: idx_lea_lot; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lea_lot ON public.labor_entry_allocations USING btree (lot_id);


--
-- TOC entry 6954 (class 1259 OID 57712)
-- Name: idx_lots_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lots_client ON public.lots USING btree (client_id);


--
-- TOC entry 6955 (class 1259 OID 57713)
-- Name: idx_lots_farm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lots_farm ON public.lots USING btree (farm_id);


--
-- TOC entry 6923 (class 1259 OID 57716)
-- Name: idx_mov_item_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mov_item_date ON public.inventory_movements USING btree (item_id, mov_date);


--
-- TOC entry 6968 (class 1259 OID 57717)
-- Name: idx_password_reset_tokens_active_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_reset_tokens_active_hash ON public.password_reset_tokens USING btree (token_hash) WHERE (used_at IS NULL);


--
-- TOC entry 6969 (class 1259 OID 57718)
-- Name: idx_password_reset_tokens_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_reset_tokens_user_id ON public.password_reset_tokens USING btree (user_id);


--
-- TOC entry 6977 (class 1259 OID 57719)
-- Name: idx_payroll_employee_rates_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_employee_rates_created_by ON public.payroll_employee_rates USING btree (created_by_user_id);


--
-- TOC entry 6978 (class 1259 OID 57720)
-- Name: idx_payroll_employee_rates_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_employee_rates_updated_at ON public.payroll_employee_rates USING btree (updated_at);


--
-- TOC entry 6979 (class 1259 OID 57721)
-- Name: idx_payroll_employee_rates_updated_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_employee_rates_updated_by ON public.payroll_employee_rates USING btree (updated_by_user_id);


--
-- TOC entry 6982 (class 1259 OID 57722)
-- Name: idx_payroll_nomina_rules_client_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_nomina_rules_client_active ON public.payroll_nomina_contribution_rules USING btree (client_id, is_active);


--
-- TOC entry 6983 (class 1259 OID 57723)
-- Name: idx_payroll_nomina_rules_client_dates; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_nomina_rules_client_dates ON public.payroll_nomina_contribution_rules USING btree (client_id, valid_from, valid_to);


--
-- TOC entry 6991 (class 1259 OID 57724)
-- Name: idx_payroll_settings_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_settings_created_by ON public.payroll_settings USING btree (created_by_user_id);


--
-- TOC entry 6992 (class 1259 OID 57725)
-- Name: idx_payroll_settings_updated_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_settings_updated_by ON public.payroll_settings USING btree (updated_by_user_id);


--
-- TOC entry 6993 (class 1259 OID 57726)
-- Name: idx_payroll_settings_valid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_settings_valid ON public.payroll_settings USING btree (valid_from, valid_to);


--
-- TOC entry 6996 (class 1259 OID 57727)
-- Name: idx_payroll_slip_lot_slip; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_slip_lot_slip ON public.payroll_slip_lot_allocations USING btree (payroll_slip_id);


--
-- TOC entry 7000 (class 1259 OID 57728)
-- Name: idx_payroll_slips_client_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_slips_client_status ON public.payroll_slips USING btree (client_id, status);


--
-- TOC entry 7001 (class 1259 OID 57729)
-- Name: idx_payroll_slips_client_worker; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_slips_client_worker ON public.payroll_slips USING btree (client_id, worker_id);


--
-- TOC entry 7002 (class 1259 OID 57730)
-- Name: idx_payroll_slips_period; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_slips_period ON public.payroll_slips USING btree (client_id, period_from, period_to);


--
-- TOC entry 6970 (class 1259 OID 57732)
-- Name: idx_prt_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prt_expires_at ON public.password_reset_tokens USING btree (expires_at);


--
-- TOC entry 6971 (class 1259 OID 57733)
-- Name: idx_prt_used_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prt_used_at ON public.password_reset_tokens USING btree (used_at);


--
-- TOC entry 6972 (class 1259 OID 57734)
-- Name: idx_prt_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_prt_user_id ON public.password_reset_tokens USING btree (user_id);


--
-- TOC entry 7019 (class 1259 OID 57735)
-- Name: idx_security_audit_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_security_audit_logs_created_at ON public.security_audit_logs USING btree (created_at DESC);


--
-- TOC entry 7020 (class 1259 OID 57736)
-- Name: idx_security_audit_logs_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_security_audit_logs_event_type ON public.security_audit_logs USING btree (event_type);


--
-- TOC entry 7021 (class 1259 OID 57737)
-- Name: idx_security_audit_logs_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_security_audit_logs_user_id ON public.security_audit_logs USING btree (user_id);


--
-- TOC entry 7024 (class 1259 OID 57738)
-- Name: idx_sessions_acting_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_acting_client_id ON public.sessions USING btree (acting_client_id) WHERE (acting_client_id IS NOT NULL);


--
-- TOC entry 7025 (class 1259 OID 57739)
-- Name: idx_sessions_active_previous_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_active_previous_token ON public.sessions USING btree (previous_session_token_hash, previous_token_expires_at) WHERE ((revoked_at IS NULL) AND (previous_session_token_hash IS NOT NULL));


--
-- TOC entry 7026 (class 1259 OID 57740)
-- Name: idx_sessions_active_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_active_token ON public.sessions USING btree (session_token_hash, expires_at) WHERE (revoked_at IS NULL);


--
-- TOC entry 7027 (class 1259 OID 57741)
-- Name: idx_sessions_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_expires ON public.sessions USING btree (expires_at);


--
-- TOC entry 7028 (class 1259 OID 57742)
-- Name: idx_sessions_previous_token_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_previous_token_expires_at ON public.sessions USING btree (previous_token_expires_at);


--
-- TOC entry 7029 (class 1259 OID 57743)
-- Name: idx_sessions_previous_token_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_previous_token_hash ON public.sessions USING btree (previous_session_token_hash);


--
-- TOC entry 7030 (class 1259 OID 57744)
-- Name: idx_sessions_revoked_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_revoked_at ON public.sessions USING btree (revoked_at);


--
-- TOC entry 7031 (class 1259 OID 57745)
-- Name: idx_sessions_token_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_token_hash ON public.sessions USING btree (session_token_hash);


--
-- TOC entry 7032 (class 1259 OID 57746)
-- Name: idx_sessions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sessions_user_id ON public.sessions USING btree (user_id);


--
-- TOC entry 7037 (class 1259 OID 57747)
-- Name: idx_users_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_active ON public.users USING btree (is_active);


--
-- TOC entry 7038 (class 1259 OID 57748)
-- Name: idx_users_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_client ON public.users USING btree (client_id);


--
-- TOC entry 7039 (class 1259 OID 57749)
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- TOC entry 7044 (class 1259 OID 57750)
-- Name: idx_workers_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workers_client ON public.workers USING btree (client_id);


--
-- TOC entry 6892 (class 1259 OID 57751)
-- Name: inventory_categories_name_unique_ci; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX inventory_categories_name_unique_ci ON public.inventory_categories USING btree (lower(TRIM(BOTH FROM name)));


--
-- TOC entry 6903 (class 1259 OID 57752)
-- Name: inventory_item_ingredients_item_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inventory_item_ingredients_item_id_idx ON public.inventory_item_ingredients USING btree (item_id);


--
-- TOC entry 6907 (class 1259 OID 57753)
-- Name: inventory_items_brand_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inventory_items_brand_id_idx ON public.inventory_items USING btree (brand_id);


--
-- TOC entry 6908 (class 1259 OID 57754)
-- Name: inventory_items_category_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inventory_items_category_id_idx ON public.inventory_items USING btree (category_id);


--
-- TOC entry 6909 (class 1259 OID 57755)
-- Name: inventory_items_name_unit_brand_unique_ci; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX inventory_items_name_unit_brand_unique_ci ON public.inventory_items USING btree (lower(TRIM(BOTH FROM name)), lower(TRIM(BOTH FROM unit)), brand_id);


--
-- TOC entry 6901 (class 1259 OID 57756)
-- Name: ix_inv_cons_app_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inv_cons_app_group ON public.inventory_consumptions USING btree (application_group_id);


--
-- TOC entry 6902 (class 1259 OID 57757)
-- Name: ix_inv_cons_mix_app; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inv_cons_mix_app ON public.inventory_consumptions USING btree (mix_application_id);


--
-- TOC entry 6964 (class 1259 OID 57758)
-- Name: ix_mix_app_farm_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mix_app_farm_date ON public.mix_applications USING btree (farm_id, app_date DESC) WHERE (farm_id IS NOT NULL);


--
-- TOC entry 6959 (class 1259 OID 57759)
-- Name: ix_mix_app_items_app; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mix_app_items_app ON public.mix_application_items USING btree (mix_application_id);


--
-- TOC entry 6965 (class 1259 OID 57760)
-- Name: ix_mix_app_lot_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_mix_app_lot_date ON public.mix_applications USING btree (lot_id, app_date DESC) WHERE (lot_id IS NOT NULL);


--
-- TOC entry 6988 (class 1259 OID 57761)
-- Name: payroll_periods_period_month_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX payroll_periods_period_month_uidx ON public.payroll_periods USING btree (period_month);


--
-- TOC entry 6865 (class 1259 OID 57762)
-- Name: unique_farm_name_per_client; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_farm_name_per_client ON public.farms USING btree (client_id, name);


--
-- TOC entry 6958 (class 1259 OID 57763)
-- Name: unique_lot_name_per_farm_client_ci; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_lot_name_per_farm_client_ci ON public.lots USING btree (client_id, farm_id, lower(TRIM(BOTH FROM name)));


--
-- TOC entry 6815 (class 1259 OID 57764)
-- Name: uq_asset_categories_client_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_asset_categories_client_name ON public.asset_categories USING btree (client_id, name_norm);


--
-- TOC entry 6822 (class 1259 OID 57765)
-- Name: uq_assets_client_plate; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_assets_client_plate ON public.assets USING btree (client_id, plate);


--
-- TOC entry 6833 (class 1259 OID 57766)
-- Name: uq_calibers_client_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_calibers_client_name ON public.calibers USING btree (client_id, lower(TRIM(BOTH FROM name)));


--
-- TOC entry 7053 (class 1259 OID 58730)
-- Name: uq_coffee_lot_production_active_lot_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_coffee_lot_production_active_lot_date ON public.coffee_lot_production USING btree (client_id, lot_id, prod_date) WHERE (is_active = true);


--
-- TOC entry 6851 (class 1259 OID 57767)
-- Name: uq_expense_categories_client_name_norm; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_expense_categories_client_name_norm ON public.expense_categories USING btree (client_id, name_norm);


--
-- TOC entry 6889 (class 1259 OID 57768)
-- Name: uq_inventory_brands_client_name_ci; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_inventory_brands_client_name_ci ON public.inventory_brands USING btree (client_id, lower(TRIM(BOTH FROM name)));


--
-- TOC entry 6932 (class 1259 OID 57769)
-- Name: uq_labor_entries_active_farm_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_labor_entries_active_farm_key ON public.labor_entries USING btree (worker_id, farm_id, labor_type_id, unit, work_date) WHERE ((is_active = true) AND (cost_scope = 'farm'::text));


--
-- TOC entry 6933 (class 1259 OID 57770)
-- Name: uq_labor_entries_active_lot_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_labor_entries_active_lot_key ON public.labor_entries USING btree (worker_id, lot_id, labor_type_id, unit, work_date) WHERE ((is_active = true) AND (cost_scope = 'lot'::text));


--
-- TOC entry 6934 (class 1259 OID 57771)
-- Name: uq_labor_entries_one_jornal_per_day_global; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_labor_entries_one_jornal_per_day_global ON public.labor_entries USING btree (worker_id, work_date) WHERE ((is_active = true) AND (unit = 'jornal'::public.pay_unit));


--
-- TOC entry 6939 (class 1259 OID 57772)
-- Name: uq_labor_entry_allocations_entry_lot; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_labor_entry_allocations_entry_lot ON public.labor_entry_allocations USING btree (labor_entry_id, lot_id);


--
-- TOC entry 6975 (class 1259 OID 57774)
-- Name: uq_prt_one_active_per_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_prt_one_active_per_user ON public.password_reset_tokens USING btree (user_id) WHERE (used_at IS NULL);


--
-- TOC entry 6976 (class 1259 OID 57775)
-- Name: uq_prt_token_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_prt_token_hash ON public.password_reset_tokens USING btree (token_hash);


--
-- TOC entry 7040 (class 1259 OID 57776)
-- Name: uq_users_email_lower_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_users_email_lower_active ON public.users USING btree (lower(TRIM(BOTH FROM email))) WHERE (is_active = true);


--
-- TOC entry 7041 (class 1259 OID 57777)
-- Name: uq_users_id_doc_per_client; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_users_id_doc_per_client ON public.users USING btree (client_id, id_type, id_number);


--
-- TOC entry 7045 (class 1259 OID 57778)
-- Name: uq_worker_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_worker_id ON public.workers USING btree (id_type, id_number) WHERE (id_number IS NOT NULL);


--
-- TOC entry 6811 (class 1259 OID 57779)
-- Name: ux_aguinaldo_worker_legal_period; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_aguinaldo_worker_legal_period ON public.aguinaldo_statements USING btree (client_id, worker_id, legal_period_from, legal_period_to);


--
-- TOC entry 6868 (class 1259 OID 57780)
-- Name: ux_fixed_payroll_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_fixed_payroll_active ON public.fixed_payroll USING btree (worker_id, period_id) WHERE (is_active = true);


--
-- TOC entry 6999 (class 1259 OID 57782)
-- Name: ux_payroll_slip_lot; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_payroll_slip_lot ON public.payroll_slip_lot_allocations USING btree (payroll_slip_id, lot_id);


--
-- TOC entry 7226 (class 2620 OID 57784)
-- Name: general_expenses tr_general_expenses_recalc; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tr_general_expenses_recalc AFTER INSERT OR UPDATE ON public.general_expenses FOR EACH ROW EXECUTE FUNCTION public.trg_general_expense_recalc();


--
-- TOC entry 7219 (class 2620 OID 57785)
-- Name: asset_categories trg_asset_categories_set_name_norm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_asset_categories_set_name_norm BEFORE INSERT OR UPDATE OF name ON public.asset_categories FOR EACH ROW EXECUTE FUNCTION public.trg_asset_categories_set_name_norm();


--
-- TOC entry 7220 (class 2620 OID 57786)
-- Name: asset_categories trg_asset_categories_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_asset_categories_updated_at BEFORE UPDATE ON public.asset_categories FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 7221 (class 2620 OID 57787)
-- Name: asset_depreciation trg_asset_depreciation_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_asset_depreciation_updated_at BEFORE UPDATE ON public.asset_depreciation FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 7222 (class 2620 OID 57788)
-- Name: assets trg_assets_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_assets_updated_at BEFORE UPDATE ON public.assets FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 7224 (class 2620 OID 57789)
-- Name: calendar_activities trg_calendar_activities_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_calendar_activities_updated_at BEFORE UPDATE ON public.calendar_activities FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 7225 (class 2620 OID 57790)
-- Name: expense_categories trg_expense_categories_set_name_norm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_expense_categories_set_name_norm BEFORE INSERT OR UPDATE OF name ON public.expense_categories FOR EACH ROW EXECUTE FUNCTION public.trg_expense_categories_set_name_norm();


--
-- TOC entry 7223 (class 2620 OID 57791)
-- Name: assets trg_set_asset_plate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_asset_plate BEFORE INSERT ON public.assets FOR EACH ROW EXECUTE FUNCTION public.set_asset_plate();


--
-- TOC entry 7227 (class 2620 OID 57792)
-- Name: users trg_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 7054 (class 2606 OID 57793)
-- Name: aguinaldo_statements aguinaldo_statements_client_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aguinaldo_statements
    ADD CONSTRAINT aguinaldo_statements_client_fk FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- TOC entry 7055 (class 2606 OID 57798)
-- Name: aguinaldo_statements aguinaldo_statements_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aguinaldo_statements
    ADD CONSTRAINT aguinaldo_statements_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7056 (class 2606 OID 57803)
-- Name: aguinaldo_statements aguinaldo_statements_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aguinaldo_statements
    ADD CONSTRAINT aguinaldo_statements_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7057 (class 2606 OID 57808)
-- Name: aguinaldo_statements aguinaldo_statements_worker_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aguinaldo_statements
    ADD CONSTRAINT aguinaldo_statements_worker_fk FOREIGN KEY (worker_id) REFERENCES public.workers(id) ON DELETE RESTRICT;


--
-- TOC entry 7078 (class 2606 OID 57813)
-- Name: cantons cantons_province_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cantons
    ADD CONSTRAINT cantons_province_id_fkey FOREIGN KEY (province_id) REFERENCES public.provinces(id);


--
-- TOC entry 7215 (class 2606 OID 58707)
-- Name: coffee_lot_production coffee_lot_production_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coffee_lot_production
    ADD CONSTRAINT coffee_lot_production_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- TOC entry 7216 (class 2606 OID 58717)
-- Name: coffee_lot_production coffee_lot_production_created_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coffee_lot_production
    ADD CONSTRAINT coffee_lot_production_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7217 (class 2606 OID 58712)
-- Name: coffee_lot_production coffee_lot_production_lot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coffee_lot_production
    ADD CONSTRAINT coffee_lot_production_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES public.lots(id);


--
-- TOC entry 7218 (class 2606 OID 58722)
-- Name: coffee_lot_production coffee_lot_production_updated_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coffee_lot_production
    ADD CONSTRAINT coffee_lot_production_updated_by_user_id_fkey FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7069 (class 2606 OID 57818)
-- Name: coffee_varieties coffee_varieties_created_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coffee_varieties
    ADD CONSTRAINT coffee_varieties_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7070 (class 2606 OID 57823)
-- Name: coffee_varieties coffee_varieties_updated_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coffee_varieties
    ADD CONSTRAINT coffee_varieties_updated_by_user_id_fkey FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7080 (class 2606 OID 57828)
-- Name: districts districts_canton_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_canton_id_fkey FOREIGN KEY (canton_id) REFERENCES public.cantons(id);


--
-- TOC entry 7082 (class 2606 OID 57833)
-- Name: expenses expenses_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7083 (class 2606 OID 57838)
-- Name: expenses expenses_harvest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_harvest_id_fkey FOREIGN KEY (harvest_id) REFERENCES public.harvests(id) ON DELETE SET NULL;


--
-- TOC entry 7084 (class 2606 OID 57843)
-- Name: expenses expenses_lot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES public.lots(id) ON DELETE CASCADE;


--
-- TOC entry 7085 (class 2606 OID 57848)
-- Name: expenses expenses_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7088 (class 2606 OID 57853)
-- Name: farm_harvest_estimates farm_harvest_estimates_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farm_harvest_estimates
    ADD CONSTRAINT farm_harvest_estimates_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7089 (class 2606 OID 57858)
-- Name: farm_harvest_estimates farm_harvest_estimates_farm_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farm_harvest_estimates
    ADD CONSTRAINT farm_harvest_estimates_farm_fk FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE CASCADE;


--
-- TOC entry 7090 (class 2606 OID 57863)
-- Name: farm_harvest_estimates farm_harvest_estimates_harvest_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farm_harvest_estimates
    ADD CONSTRAINT farm_harvest_estimates_harvest_fk FOREIGN KEY (harvest_id) REFERENCES public.harvests(id) ON DELETE CASCADE;


--
-- TOC entry 7091 (class 2606 OID 57868)
-- Name: farm_harvest_estimates farm_harvest_estimates_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farm_harvest_estimates
    ADD CONSTRAINT farm_harvest_estimates_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7093 (class 2606 OID 57873)
-- Name: farms farms_canton_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT farms_canton_id_fkey FOREIGN KEY (canton_id) REFERENCES public.cantons(id);


--
-- TOC entry 7094 (class 2606 OID 57878)
-- Name: farms farms_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT farms_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7095 (class 2606 OID 57883)
-- Name: farms farms_district_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT farms_district_id_fkey FOREIGN KEY (district_id) REFERENCES public.districts(id);


--
-- TOC entry 7096 (class 2606 OID 57888)
-- Name: farms farms_province_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT farms_province_id_fkey FOREIGN KEY (province_id) REFERENCES public.provinces(id);


--
-- TOC entry 7097 (class 2606 OID 57893)
-- Name: farms farms_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT farms_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7103 (class 2606 OID 57898)
-- Name: fixed_payroll_allocations fixed_payroll_allocations_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_payroll_allocations
    ADD CONSTRAINT fixed_payroll_allocations_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7104 (class 2606 OID 57903)
-- Name: fixed_payroll_allocations fixed_payroll_allocations_fixed_payroll_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_payroll_allocations
    ADD CONSTRAINT fixed_payroll_allocations_fixed_payroll_id_fkey FOREIGN KEY (fixed_payroll_id) REFERENCES public.fixed_payroll(id) ON DELETE CASCADE;


--
-- TOC entry 7105 (class 2606 OID 57908)
-- Name: fixed_payroll_allocations fixed_payroll_allocations_lot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_payroll_allocations
    ADD CONSTRAINT fixed_payroll_allocations_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES public.lots(id) ON DELETE CASCADE;


--
-- TOC entry 7106 (class 2606 OID 57913)
-- Name: fixed_payroll_allocations fixed_payroll_allocations_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_payroll_allocations
    ADD CONSTRAINT fixed_payroll_allocations_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7099 (class 2606 OID 57918)
-- Name: fixed_payroll fixed_payroll_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_payroll
    ADD CONSTRAINT fixed_payroll_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7100 (class 2606 OID 57923)
-- Name: fixed_payroll fixed_payroll_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_payroll
    ADD CONSTRAINT fixed_payroll_period_id_fkey FOREIGN KEY (period_id) REFERENCES public.payroll_periods(id) ON DELETE CASCADE;


--
-- TOC entry 7101 (class 2606 OID 57928)
-- Name: fixed_payroll fixed_payroll_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_payroll
    ADD CONSTRAINT fixed_payroll_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7102 (class 2606 OID 57933)
-- Name: fixed_payroll fixed_payroll_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fixed_payroll
    ADD CONSTRAINT fixed_payroll_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES public.workers(id) ON DELETE RESTRICT;


--
-- TOC entry 7058 (class 2606 OID 57938)
-- Name: asset_categories fk_asset_categories_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_categories
    ADD CONSTRAINT fk_asset_categories_client FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- TOC entry 7059 (class 2606 OID 57943)
-- Name: asset_categories fk_asset_categories_created_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_categories
    ADD CONSTRAINT fk_asset_categories_created_by FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 7060 (class 2606 OID 57948)
-- Name: asset_categories fk_asset_categories_updated_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_categories
    ADD CONSTRAINT fk_asset_categories_updated_by FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 7061 (class 2606 OID 57953)
-- Name: asset_depreciation fk_asset_dep_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_depreciation
    ADD CONSTRAINT fk_asset_dep_client FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- TOC entry 7062 (class 2606 OID 57958)
-- Name: asset_depreciation fk_asset_depreciation_asset; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_depreciation
    ADD CONSTRAINT fk_asset_depreciation_asset FOREIGN KEY (asset_id) REFERENCES public.assets(id) ON DELETE CASCADE;


--
-- TOC entry 7063 (class 2606 OID 57963)
-- Name: asset_depreciation fk_asset_depreciation_created_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_depreciation
    ADD CONSTRAINT fk_asset_depreciation_created_by FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 7064 (class 2606 OID 57968)
-- Name: asset_depreciation fk_asset_depreciation_updated_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_depreciation
    ADD CONSTRAINT fk_asset_depreciation_updated_by FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 7065 (class 2606 OID 57973)
-- Name: assets fk_assets_category; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT fk_assets_category FOREIGN KEY (category_id) REFERENCES public.asset_categories(id);


--
-- TOC entry 7066 (class 2606 OID 57978)
-- Name: assets fk_assets_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT fk_assets_client FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- TOC entry 7067 (class 2606 OID 57983)
-- Name: assets fk_assets_created_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT fk_assets_created_by FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 7068 (class 2606 OID 57988)
-- Name: assets fk_assets_updated_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT fk_assets_updated_by FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 7071 (class 2606 OID 57993)
-- Name: calendar_activities fk_calendar_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_activities
    ADD CONSTRAINT fk_calendar_client FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- TOC entry 7072 (class 2606 OID 57998)
-- Name: calendar_activities fk_calendar_created_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_activities
    ADD CONSTRAINT fk_calendar_created_by FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7073 (class 2606 OID 58003)
-- Name: calendar_activities fk_calendar_farm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_activities
    ADD CONSTRAINT fk_calendar_farm FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE CASCADE;


--
-- TOC entry 7074 (class 2606 OID 58008)
-- Name: calendar_activities fk_calendar_labor_type; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_activities
    ADD CONSTRAINT fk_calendar_labor_type FOREIGN KEY (labor_type_id) REFERENCES public.labor_types(id) ON DELETE RESTRICT;


--
-- TOC entry 7075 (class 2606 OID 58013)
-- Name: calendar_activities fk_calendar_lot; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_activities
    ADD CONSTRAINT fk_calendar_lot FOREIGN KEY (lot_id) REFERENCES public.lots(id) ON DELETE CASCADE;


--
-- TOC entry 7076 (class 2606 OID 58018)
-- Name: calendar_activities fk_calendar_updated_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_activities
    ADD CONSTRAINT fk_calendar_updated_by FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7077 (class 2606 OID 58028)
-- Name: calibers fk_calibers_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calibers
    ADD CONSTRAINT fk_calibers_client FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- TOC entry 7079 (class 2606 OID 58033)
-- Name: clients fk_clients_plan; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT fk_clients_plan FOREIGN KEY (plan_id) REFERENCES public.plans(id);


--
-- TOC entry 7092 (class 2606 OID 58038)
-- Name: farm_harvest_estimates fk_estimates_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farm_harvest_estimates
    ADD CONSTRAINT fk_estimates_client FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- TOC entry 7081 (class 2606 OID 58043)
-- Name: expense_categories fk_expense_categories_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expense_categories
    ADD CONSTRAINT fk_expense_categories_client FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- TOC entry 7086 (class 2606 OID 58048)
-- Name: expenses fk_expenses_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT fk_expenses_client FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- TOC entry 7087 (class 2606 OID 58053)
-- Name: expenses fk_expenses_expense_category; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT fk_expenses_expense_category FOREIGN KEY (category_id) REFERENCES public.expense_categories(id) ON DELETE RESTRICT;


--
-- TOC entry 7098 (class 2606 OID 58058)
-- Name: farms fk_farms_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.farms
    ADD CONSTRAINT fk_farms_client FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- TOC entry 7109 (class 2606 OID 58063)
-- Name: general_expenses fk_general_expenses_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.general_expenses
    ADD CONSTRAINT fk_general_expenses_client FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE RESTRICT;


--
-- TOC entry 7110 (class 2606 OID 58068)
-- Name: general_expenses fk_general_expenses_expense_category; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.general_expenses
    ADD CONSTRAINT fk_general_expenses_expense_category FOREIGN KEY (category_id) REFERENCES public.expense_categories(id) ON DELETE RESTRICT;


--
-- TOC entry 7115 (class 2606 OID 58073)
-- Name: harvests fk_harvests_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harvests
    ADD CONSTRAINT fk_harvests_client FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- TOC entry 7125 (class 2606 OID 58078)
-- Name: inventory_consumptions fk_inv_cons_mix_app; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_consumptions
    ADD CONSTRAINT fk_inv_cons_mix_app FOREIGN KEY (mix_application_id) REFERENCES public.mix_applications(id) ON DELETE SET NULL;


--
-- TOC entry 7146 (class 2606 OID 58083)
-- Name: inventory_movements fk_inv_mov_adjust_layer; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movements
    ADD CONSTRAINT fk_inv_mov_adjust_layer FOREIGN KEY (adjust_layer_id) REFERENCES public.inventory_layers(id) ON DELETE SET NULL;


--
-- TOC entry 7147 (class 2606 OID 58088)
-- Name: inventory_movements fk_inv_mov_out_source_layer; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movements
    ADD CONSTRAINT fk_inv_mov_out_source_layer FOREIGN KEY (out_source_layer_id) REFERENCES public.inventory_layers(id) ON DELETE SET NULL;


--
-- TOC entry 7118 (class 2606 OID 58093)
-- Name: inventory_brands fk_inventory_brands_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_brands
    ADD CONSTRAINT fk_inventory_brands_client FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE RESTRICT;


--
-- TOC entry 7136 (class 2606 OID 58098)
-- Name: inventory_items fk_inventory_items_brand_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT fk_inventory_items_brand_client FOREIGN KEY (brand_id, client_id) REFERENCES public.inventory_brands(id, client_id) ON DELETE RESTRICT;


--
-- TOC entry 7137 (class 2606 OID 58103)
-- Name: inventory_items fk_inventory_items_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT fk_inventory_items_client FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- TOC entry 7141 (class 2606 OID 58108)
-- Name: inventory_layers fk_inventory_layers_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_layers
    ADD CONSTRAINT fk_inventory_layers_client FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- TOC entry 7148 (class 2606 OID 58113)
-- Name: inventory_movements fk_item_client_match; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movements
    ADD CONSTRAINT fk_item_client_match FOREIGN KEY (item_id, client_id) REFERENCES public.inventory_items(id, client_id);


--
-- TOC entry 7152 (class 2606 OID 58118)
-- Name: labor_entries fk_labor_entries_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_entries
    ADD CONSTRAINT fk_labor_entries_client FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- TOC entry 7159 (class 2606 OID 58123)
-- Name: labor_entry_allocations fk_lea_labor_entry; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_entry_allocations
    ADD CONSTRAINT fk_lea_labor_entry FOREIGN KEY (labor_entry_id) REFERENCES public.labor_entries(id) ON DELETE CASCADE;


--
-- TOC entry 7160 (class 2606 OID 58128)
-- Name: labor_entry_allocations fk_lea_lot; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_entry_allocations
    ADD CONSTRAINT fk_lea_lot FOREIGN KEY (lot_id) REFERENCES public.lots(id) ON DELETE CASCADE;


--
-- TOC entry 7175 (class 2606 OID 58148)
-- Name: lots fk_lots_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lots
    ADD CONSTRAINT fk_lots_client FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- TOC entry 7181 (class 2606 OID 58163)
-- Name: mix_applications fk_mix_app_expense; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mix_applications
    ADD CONSTRAINT fk_mix_app_expense FOREIGN KEY (expense_id) REFERENCES public.expenses(id) ON DELETE SET NULL;


--
-- TOC entry 7182 (class 2606 OID 58168)
-- Name: mix_applications fk_mix_app_harvest; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mix_applications
    ADD CONSTRAINT fk_mix_app_harvest FOREIGN KEY (harvest_id) REFERENCES public.harvests(id) ON DELETE SET NULL;


--
-- TOC entry 7179 (class 2606 OID 58173)
-- Name: mix_application_items fk_mix_app_items_app; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mix_application_items
    ADD CONSTRAINT fk_mix_app_items_app FOREIGN KEY (mix_application_id) REFERENCES public.mix_applications(id) ON DELETE CASCADE;


--
-- TOC entry 7180 (class 2606 OID 58178)
-- Name: mix_application_items fk_mix_app_items_item; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mix_application_items
    ADD CONSTRAINT fk_mix_app_items_item FOREIGN KEY (item_id) REFERENCES public.inventory_items(id) ON DELETE RESTRICT;


--
-- TOC entry 7183 (class 2606 OID 58183)
-- Name: mix_applications fk_mix_app_lot; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mix_applications
    ADD CONSTRAINT fk_mix_app_lot FOREIGN KEY (lot_id) REFERENCES public.lots(id) ON DELETE CASCADE;


--
-- TOC entry 7184 (class 2606 OID 58188)
-- Name: mix_applications fk_mix_applications_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mix_applications
    ADD CONSTRAINT fk_mix_applications_client FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- TOC entry 7208 (class 2606 OID 58193)
-- Name: users fk_users_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_client FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- TOC entry 7209 (class 2606 OID 58198)
-- Name: users fk_users_role; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- TOC entry 7212 (class 2606 OID 58203)
-- Name: workers fk_workers_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workers
    ADD CONSTRAINT fk_workers_client FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- TOC entry 7107 (class 2606 OID 58208)
-- Name: general_expense_allocations general_expense_allocations_general_expense_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.general_expense_allocations
    ADD CONSTRAINT general_expense_allocations_general_expense_id_fkey FOREIGN KEY (general_expense_id) REFERENCES public.general_expenses(id) ON DELETE CASCADE;


--
-- TOC entry 7108 (class 2606 OID 58213)
-- Name: general_expense_allocations general_expense_allocations_lot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.general_expense_allocations
    ADD CONSTRAINT general_expense_allocations_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES public.lots(id) ON DELETE CASCADE;


--
-- TOC entry 7111 (class 2606 OID 58218)
-- Name: general_expenses general_expenses_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.general_expenses
    ADD CONSTRAINT general_expenses_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id);


--
-- TOC entry 7112 (class 2606 OID 58223)
-- Name: general_expenses general_expenses_farm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.general_expenses
    ADD CONSTRAINT general_expenses_farm_id_fkey FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE SET NULL;


--
-- TOC entry 7113 (class 2606 OID 58228)
-- Name: general_expenses general_expenses_harvest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.general_expenses
    ADD CONSTRAINT general_expenses_harvest_id_fkey FOREIGN KEY (harvest_id) REFERENCES public.harvests(id) ON DELETE SET NULL;


--
-- TOC entry 7114 (class 2606 OID 58233)
-- Name: general_expenses general_expenses_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.general_expenses
    ADD CONSTRAINT general_expenses_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id);


--
-- TOC entry 7116 (class 2606 OID 58238)
-- Name: harvests harvests_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harvests
    ADD CONSTRAINT harvests_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7117 (class 2606 OID 58243)
-- Name: harvests harvests_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.harvests
    ADD CONSTRAINT harvests_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7119 (class 2606 OID 58248)
-- Name: inventory_brands inventory_brands_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_brands
    ADD CONSTRAINT inventory_brands_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7120 (class 2606 OID 58253)
-- Name: inventory_brands inventory_brands_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_brands
    ADD CONSTRAINT inventory_brands_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7121 (class 2606 OID 58258)
-- Name: inventory_categories inventory_categories_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_categories
    ADD CONSTRAINT inventory_categories_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7122 (class 2606 OID 58263)
-- Name: inventory_categories inventory_categories_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_categories
    ADD CONSTRAINT inventory_categories_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7123 (class 2606 OID 58268)
-- Name: inventory_consumption_layers inventory_consumption_layers_consumption_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_consumption_layers
    ADD CONSTRAINT inventory_consumption_layers_consumption_id_fkey FOREIGN KEY (consumption_id) REFERENCES public.inventory_consumptions(id) ON DELETE CASCADE;


--
-- TOC entry 7124 (class 2606 OID 58273)
-- Name: inventory_consumption_layers inventory_consumption_layers_layer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_consumption_layers
    ADD CONSTRAINT inventory_consumption_layers_layer_id_fkey FOREIGN KEY (layer_id) REFERENCES public.inventory_layers(id) ON DELETE RESTRICT;


--
-- TOC entry 7126 (class 2606 OID 58278)
-- Name: inventory_consumptions inventory_consumptions_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_consumptions
    ADD CONSTRAINT inventory_consumptions_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7127 (class 2606 OID 58283)
-- Name: inventory_consumptions inventory_consumptions_expense_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_consumptions
    ADD CONSTRAINT inventory_consumptions_expense_id_fkey FOREIGN KEY (expense_id) REFERENCES public.expenses(id) ON DELETE SET NULL;


--
-- TOC entry 7128 (class 2606 OID 58288)
-- Name: inventory_consumptions inventory_consumptions_farm_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_consumptions
    ADD CONSTRAINT inventory_consumptions_farm_fk FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE SET NULL;


--
-- TOC entry 7129 (class 2606 OID 58293)
-- Name: inventory_consumptions inventory_consumptions_harvest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_consumptions
    ADD CONSTRAINT inventory_consumptions_harvest_id_fkey FOREIGN KEY (harvest_id) REFERENCES public.harvests(id) ON DELETE SET NULL;


--
-- TOC entry 7130 (class 2606 OID 58298)
-- Name: inventory_consumptions inventory_consumptions_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_consumptions
    ADD CONSTRAINT inventory_consumptions_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.inventory_items(id) ON DELETE RESTRICT;


--
-- TOC entry 7131 (class 2606 OID 58303)
-- Name: inventory_consumptions inventory_consumptions_lot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_consumptions
    ADD CONSTRAINT inventory_consumptions_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES public.lots(id) ON DELETE CASCADE;


--
-- TOC entry 7132 (class 2606 OID 58308)
-- Name: inventory_consumptions inventory_consumptions_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_consumptions
    ADD CONSTRAINT inventory_consumptions_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7133 (class 2606 OID 58313)
-- Name: inventory_item_ingredients inventory_item_ingredients_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_item_ingredients
    ADD CONSTRAINT inventory_item_ingredients_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7134 (class 2606 OID 58318)
-- Name: inventory_item_ingredients inventory_item_ingredients_item_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_item_ingredients
    ADD CONSTRAINT inventory_item_ingredients_item_fk FOREIGN KEY (item_id) REFERENCES public.inventory_items(id) ON DELETE CASCADE;


--
-- TOC entry 7135 (class 2606 OID 58323)
-- Name: inventory_item_ingredients inventory_item_ingredients_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_item_ingredients
    ADD CONSTRAINT inventory_item_ingredients_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7138 (class 2606 OID 58328)
-- Name: inventory_items inventory_items_category_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_category_fk FOREIGN KEY (category_id) REFERENCES public.inventory_categories(id) ON DELETE RESTRICT;


--
-- TOC entry 7139 (class 2606 OID 58333)
-- Name: inventory_items inventory_items_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7140 (class 2606 OID 58338)
-- Name: inventory_items inventory_items_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7142 (class 2606 OID 58343)
-- Name: inventory_layers inventory_layers_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_layers
    ADD CONSTRAINT inventory_layers_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.inventory_items(id) ON DELETE RESTRICT;


--
-- TOC entry 7143 (class 2606 OID 58348)
-- Name: inventory_layers inventory_layers_movement_in_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_layers
    ADD CONSTRAINT inventory_layers_movement_in_id_fkey FOREIGN KEY (movement_in_id) REFERENCES public.inventory_movements(id) ON DELETE CASCADE;


--
-- TOC entry 7144 (class 2606 OID 58353)
-- Name: inventory_movement_layers inventory_movement_layers_layer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movement_layers
    ADD CONSTRAINT inventory_movement_layers_layer_id_fkey FOREIGN KEY (layer_id) REFERENCES public.inventory_layers(id) ON DELETE RESTRICT;


--
-- TOC entry 7145 (class 2606 OID 58358)
-- Name: inventory_movement_layers inventory_movement_layers_movement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movement_layers
    ADD CONSTRAINT inventory_movement_layers_movement_id_fkey FOREIGN KEY (movement_id) REFERENCES public.inventory_movements(id) ON DELETE CASCADE;


--
-- TOC entry 7149 (class 2606 OID 58363)
-- Name: inventory_movements inventory_movements_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movements
    ADD CONSTRAINT inventory_movements_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7150 (class 2606 OID 58368)
-- Name: inventory_movements inventory_movements_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movements
    ADD CONSTRAINT inventory_movements_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.inventory_items(id) ON DELETE RESTRICT;


--
-- TOC entry 7151 (class 2606 OID 58373)
-- Name: inventory_movements inventory_movements_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movements
    ADD CONSTRAINT inventory_movements_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7153 (class 2606 OID 58378)
-- Name: labor_entries labor_entries_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_entries
    ADD CONSTRAINT labor_entries_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7154 (class 2606 OID 58383)
-- Name: labor_entries labor_entries_farm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_entries
    ADD CONSTRAINT labor_entries_farm_id_fkey FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE CASCADE;


--
-- TOC entry 7155 (class 2606 OID 58388)
-- Name: labor_entries labor_entries_labor_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_entries
    ADD CONSTRAINT labor_entries_labor_type_id_fkey FOREIGN KEY (labor_type_id) REFERENCES public.labor_types(id) ON DELETE RESTRICT;


--
-- TOC entry 7156 (class 2606 OID 58393)
-- Name: labor_entries labor_entries_lot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_entries
    ADD CONSTRAINT labor_entries_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES public.lots(id) ON DELETE CASCADE;


--
-- TOC entry 7157 (class 2606 OID 58398)
-- Name: labor_entries labor_entries_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_entries
    ADD CONSTRAINT labor_entries_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7158 (class 2606 OID 58403)
-- Name: labor_entries labor_entries_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_entries
    ADD CONSTRAINT labor_entries_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES public.workers(id) ON DELETE RESTRICT;


--
-- TOC entry 7161 (class 2606 OID 58408)
-- Name: labor_rates labor_rates_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_rates
    ADD CONSTRAINT labor_rates_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7162 (class 2606 OID 58413)
-- Name: labor_rates labor_rates_harvest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_rates
    ADD CONSTRAINT labor_rates_harvest_id_fkey FOREIGN KEY (harvest_id) REFERENCES public.harvests(id) ON DELETE SET NULL;


--
-- TOC entry 7163 (class 2606 OID 58418)
-- Name: labor_rates labor_rates_labor_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_rates
    ADD CONSTRAINT labor_rates_labor_type_id_fkey FOREIGN KEY (labor_type_id) REFERENCES public.labor_types(id) ON DELETE CASCADE;


--
-- TOC entry 7164 (class 2606 OID 58423)
-- Name: labor_rates labor_rates_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_rates
    ADD CONSTRAINT labor_rates_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7165 (class 2606 OID 58428)
-- Name: labor_types labor_types_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_types
    ADD CONSTRAINT labor_types_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7166 (class 2606 OID 58433)
-- Name: labor_types labor_types_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_types
    ADD CONSTRAINT labor_types_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7167 (class 2606 OID 58733)
-- Name: lot_coffee_varieties lot_coffee_varieties_coffee_variety_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lot_coffee_varieties
    ADD CONSTRAINT lot_coffee_varieties_coffee_variety_id_fkey FOREIGN KEY (coffee_variety_id) REFERENCES public.coffee_varieties(id) ON DELETE RESTRICT;


--
-- TOC entry 7168 (class 2606 OID 58443)
-- Name: lot_coffee_varieties lot_coffee_varieties_created_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lot_coffee_varieties
    ADD CONSTRAINT lot_coffee_varieties_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7169 (class 2606 OID 58448)
-- Name: lot_coffee_varieties lot_coffee_varieties_lot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lot_coffee_varieties
    ADD CONSTRAINT lot_coffee_varieties_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES public.lots(id) ON DELETE CASCADE;


--
-- TOC entry 7170 (class 2606 OID 58453)
-- Name: lot_coffee_varieties lot_coffee_varieties_updated_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lot_coffee_varieties
    ADD CONSTRAINT lot_coffee_varieties_updated_by_user_id_fkey FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7171 (class 2606 OID 58458)
-- Name: lot_harvests lot_harvests_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lot_harvests
    ADD CONSTRAINT lot_harvests_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7172 (class 2606 OID 58463)
-- Name: lot_harvests lot_harvests_harvest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lot_harvests
    ADD CONSTRAINT lot_harvests_harvest_id_fkey FOREIGN KEY (harvest_id) REFERENCES public.harvests(id) ON DELETE CASCADE;


--
-- TOC entry 7173 (class 2606 OID 58468)
-- Name: lot_harvests lot_harvests_lot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lot_harvests
    ADD CONSTRAINT lot_harvests_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES public.lots(id) ON DELETE CASCADE;


--
-- TOC entry 7174 (class 2606 OID 58473)
-- Name: lot_harvests lot_harvests_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lot_harvests
    ADD CONSTRAINT lot_harvests_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7176 (class 2606 OID 58498)
-- Name: lots lots_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lots
    ADD CONSTRAINT lots_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7177 (class 2606 OID 58503)
-- Name: lots lots_farm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lots
    ADD CONSTRAINT lots_farm_id_fkey FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE CASCADE;


--
-- TOC entry 7178 (class 2606 OID 58508)
-- Name: lots lots_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lots
    ADD CONSTRAINT lots_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7185 (class 2606 OID 58513)
-- Name: mix_applications mix_applications_farm_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mix_applications
    ADD CONSTRAINT mix_applications_farm_fk FOREIGN KEY (farm_id) REFERENCES public.farms(id) ON DELETE RESTRICT;


--
-- TOC entry 7186 (class 2606 OID 58518)
-- Name: password_reset_tokens password_reset_tokens_created_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7187 (class 2606 OID 58523)
-- Name: password_reset_tokens password_reset_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 7188 (class 2606 OID 58528)
-- Name: payroll_employee_rates payroll_employee_rates_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_employee_rates
    ADD CONSTRAINT payroll_employee_rates_created_by_fkey FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7189 (class 2606 OID 58533)
-- Name: payroll_employee_rates payroll_employee_rates_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_employee_rates
    ADD CONSTRAINT payroll_employee_rates_updated_by_fkey FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7190 (class 2606 OID 58538)
-- Name: payroll_nomina_contribution_rules payroll_nomina_contribution_rules_client_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_nomina_contribution_rules
    ADD CONSTRAINT payroll_nomina_contribution_rules_client_fk FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- TOC entry 7191 (class 2606 OID 58543)
-- Name: payroll_nomina_contribution_rules payroll_nomina_contribution_rules_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_nomina_contribution_rules
    ADD CONSTRAINT payroll_nomina_contribution_rules_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7192 (class 2606 OID 58548)
-- Name: payroll_nomina_contribution_rules payroll_nomina_contribution_rules_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_nomina_contribution_rules
    ADD CONSTRAINT payroll_nomina_contribution_rules_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7193 (class 2606 OID 58553)
-- Name: payroll_periods payroll_periods_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_periods
    ADD CONSTRAINT payroll_periods_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7194 (class 2606 OID 58558)
-- Name: payroll_periods payroll_periods_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_periods
    ADD CONSTRAINT payroll_periods_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7195 (class 2606 OID 58563)
-- Name: payroll_settings payroll_settings_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_settings
    ADD CONSTRAINT payroll_settings_created_by_fkey FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7196 (class 2606 OID 58568)
-- Name: payroll_settings payroll_settings_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_settings
    ADD CONSTRAINT payroll_settings_updated_by_fkey FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7197 (class 2606 OID 58573)
-- Name: payroll_slip_lot_allocations payroll_slip_lot_allocations_lot_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_slip_lot_allocations
    ADD CONSTRAINT payroll_slip_lot_allocations_lot_fk FOREIGN KEY (lot_id) REFERENCES public.lots(id) ON DELETE RESTRICT;


--
-- TOC entry 7198 (class 2606 OID 58578)
-- Name: payroll_slip_lot_allocations payroll_slip_lot_allocations_slip_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_slip_lot_allocations
    ADD CONSTRAINT payroll_slip_lot_allocations_slip_fk FOREIGN KEY (payroll_slip_id) REFERENCES public.payroll_slips(id) ON DELETE CASCADE;


--
-- TOC entry 7199 (class 2606 OID 58583)
-- Name: payroll_slips payroll_slips_client_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_slips
    ADD CONSTRAINT payroll_slips_client_fk FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- TOC entry 7200 (class 2606 OID 58588)
-- Name: payroll_slips payroll_slips_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_slips
    ADD CONSTRAINT payroll_slips_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7201 (class 2606 OID 58593)
-- Name: payroll_slips payroll_slips_nomina_rule_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_slips
    ADD CONSTRAINT payroll_slips_nomina_rule_fk FOREIGN KEY (nomina_rule_id) REFERENCES public.payroll_nomina_contribution_rules(id) ON DELETE SET NULL;


--
-- TOC entry 7202 (class 2606 OID 58598)
-- Name: payroll_slips payroll_slips_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_slips
    ADD CONSTRAINT payroll_slips_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7203 (class 2606 OID 58603)
-- Name: payroll_slips payroll_slips_worker_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_slips
    ADD CONSTRAINT payroll_slips_worker_fk FOREIGN KEY (worker_id) REFERENCES public.workers(id) ON DELETE RESTRICT;


--
-- TOC entry 7204 (class 2606 OID 58608)
-- Name: sessions sessions_acting_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_acting_client_id_fkey FOREIGN KEY (acting_client_id) REFERENCES public.clients(id) ON DELETE SET NULL;


--
-- TOC entry 7205 (class 2606 OID 58613)
-- Name: sessions sessions_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7206 (class 2606 OID 58618)
-- Name: sessions sessions_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7207 (class 2606 OID 58623)
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 7210 (class 2606 OID 58628)
-- Name: users users_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7211 (class 2606 OID 58633)
-- Name: users users_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7213 (class 2606 OID 58638)
-- Name: workers workers_created_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workers
    ADD CONSTRAINT workers_created_by_fk FOREIGN KEY (created_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7214 (class 2606 OID 58643)
-- Name: workers workers_updated_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workers
    ADD CONSTRAINT workers_updated_by_fk FOREIGN KEY (updated_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 7380 (class 0 OID 56577)
-- Dependencies: 289
-- Name: aguinaldo_statements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.aguinaldo_statements ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7381 (class 0 OID 56605)
-- Dependencies: 290
-- Name: asset_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.asset_categories ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7382 (class 0 OID 56622)
-- Dependencies: 291
-- Name: asset_depreciation; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.asset_depreciation ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7383 (class 0 OID 56646)
-- Dependencies: 292
-- Name: assets; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.assets ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7384 (class 0 OID 56689)
-- Dependencies: 294
-- Name: calendar_activities; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.calendar_activities ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7385 (class 0 OID 56706)
-- Dependencies: 295
-- Name: calibers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.calibers ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7406 (class 0 OID 58686)
-- Dependencies: 344
-- Name: coffee_lot_production; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.coffee_lot_production ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7386 (class 0 OID 56739)
-- Dependencies: 301
-- Name: expense_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.expense_categories ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7387 (class 0 OID 56756)
-- Dependencies: 302
-- Name: expenses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7388 (class 0 OID 56780)
-- Dependencies: 303
-- Name: farm_harvest_estimates; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.farm_harvest_estimates ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7389 (class 0 OID 56792)
-- Dependencies: 304
-- Name: farms; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.farms ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7390 (class 0 OID 56812)
-- Dependencies: 305
-- Name: fixed_payroll; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.fixed_payroll ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7391 (class 0 OID 56859)
-- Dependencies: 306
-- Name: fixed_payroll_allocations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.fixed_payroll_allocations ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7392 (class 0 OID 56892)
-- Dependencies: 308
-- Name: general_expenses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.general_expenses ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7393 (class 0 OID 56917)
-- Dependencies: 309
-- Name: harvests; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.harvests ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7394 (class 0 OID 56936)
-- Dependencies: 310
-- Name: inventory_brands; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.inventory_brands ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7395 (class 0 OID 57019)
-- Dependencies: 315
-- Name: inventory_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7396 (class 0 OID 57037)
-- Dependencies: 316
-- Name: inventory_layers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.inventory_layers ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7397 (class 0 OID 57072)
-- Dependencies: 318
-- Name: inventory_movements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7398 (class 0 OID 57103)
-- Dependencies: 319
-- Name: labor_entries; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.labor_entries ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7399 (class 0 OID 57240)
-- Dependencies: 325
-- Name: lots; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lots ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7400 (class 0 OID 57278)
-- Dependencies: 327
-- Name: mix_applications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.mix_applications ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7401 (class 0 OID 57326)
-- Dependencies: 330
-- Name: payroll_nomina_contribution_rules; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payroll_nomina_contribution_rules ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7402 (class 0 OID 57380)
-- Dependencies: 333
-- Name: payroll_slip_lot_allocations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payroll_slip_lot_allocations ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7403 (class 0 OID 57391)
-- Dependencies: 334
-- Name: payroll_slips; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payroll_slips ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7404 (class 0 OID 57463)
-- Dependencies: 340
-- Name: security_audit_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.security_audit_logs ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 7432 (class 3256 OID 58746)
-- Name: fixed_payroll_allocations wardi_tenant_fixed_payroll_alloc; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_fixed_payroll_alloc ON public.fixed_payroll_allocations USING (((public.app_current_tenant_id() IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM (public.fixed_payroll fp
     JOIN public.workers w ON ((w.id = fp.worker_id)))
  WHERE ((fp.id = fixed_payroll_allocations.fixed_payroll_id) AND (w.client_id = public.app_current_tenant_id())))) AND (EXISTS ( SELECT 1
   FROM public.lots l
  WHERE ((l.id = fixed_payroll_allocations.lot_id) AND (l.client_id = public.app_current_tenant_id())))))) WITH CHECK (((public.app_current_tenant_id() IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM (public.fixed_payroll fp
     JOIN public.workers w ON ((w.id = fp.worker_id)))
  WHERE ((fp.id = fixed_payroll_allocations.fixed_payroll_id) AND (w.client_id = public.app_current_tenant_id())))) AND (EXISTS ( SELECT 1
   FROM public.lots l
  WHERE ((l.id = fixed_payroll_allocations.lot_id) AND (l.client_id = public.app_current_tenant_id()))))));


--
-- TOC entry 7407 (class 3256 OID 58648)
-- Name: aguinaldo_statements wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.aguinaldo_statements USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7408 (class 3256 OID 58649)
-- Name: asset_categories wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.asset_categories USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7409 (class 3256 OID 58650)
-- Name: asset_depreciation wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.asset_depreciation USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7410 (class 3256 OID 58651)
-- Name: assets wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.assets USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7411 (class 3256 OID 58652)
-- Name: calendar_activities wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.calendar_activities USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7412 (class 3256 OID 58653)
-- Name: calibers wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.calibers USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7430 (class 3256 OID 58743)
-- Name: coffee_lot_production wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.coffee_lot_production USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7413 (class 3256 OID 58654)
-- Name: expense_categories wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.expense_categories USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7414 (class 3256 OID 58655)
-- Name: expenses wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.expenses USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7415 (class 3256 OID 58656)
-- Name: farm_harvest_estimates wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.farm_harvest_estimates USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7416 (class 3256 OID 58657)
-- Name: farms wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.farms USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7417 (class 3256 OID 58658)
-- Name: general_expenses wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.general_expenses USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7418 (class 3256 OID 58659)
-- Name: harvests wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.harvests USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7419 (class 3256 OID 58660)
-- Name: inventory_brands wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.inventory_brands USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7420 (class 3256 OID 58661)
-- Name: inventory_items wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.inventory_items USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7421 (class 3256 OID 58662)
-- Name: inventory_layers wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.inventory_layers USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7422 (class 3256 OID 58663)
-- Name: inventory_movements wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.inventory_movements USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7423 (class 3256 OID 58664)
-- Name: labor_entries wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.labor_entries USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7424 (class 3256 OID 58666)
-- Name: lots wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.lots USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7425 (class 3256 OID 58667)
-- Name: mix_applications wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.mix_applications USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7426 (class 3256 OID 58668)
-- Name: payroll_nomina_contribution_rules wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.payroll_nomina_contribution_rules USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7427 (class 3256 OID 58669)
-- Name: payroll_slips wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.payroll_slips USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7428 (class 3256 OID 58670)
-- Name: security_audit_logs wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.security_audit_logs USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7429 (class 3256 OID 58671)
-- Name: workers wardi_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_isolation ON public.workers USING (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id()))) WITH CHECK (((client_id IS NOT NULL) AND (public.app_current_tenant_id() IS NOT NULL) AND (client_id = public.app_current_tenant_id())));


--
-- TOC entry 7433 (class 3256 OID 58749)
-- Name: payroll_slip_lot_allocations wardi_tenant_payroll_slip_lot_alloc; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_payroll_slip_lot_alloc ON public.payroll_slip_lot_allocations USING (((public.app_current_tenant_id() IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.payroll_slips ps
  WHERE ((ps.id = payroll_slip_lot_allocations.payroll_slip_id) AND (ps.client_id = public.app_current_tenant_id())))) AND (EXISTS ( SELECT 1
   FROM public.lots l
  WHERE ((l.id = payroll_slip_lot_allocations.lot_id) AND (l.client_id = public.app_current_tenant_id())))))) WITH CHECK (((public.app_current_tenant_id() IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.payroll_slips ps
  WHERE ((ps.id = payroll_slip_lot_allocations.payroll_slip_id) AND (ps.client_id = public.app_current_tenant_id())))) AND (EXISTS ( SELECT 1
   FROM public.lots l
  WHERE ((l.id = payroll_slip_lot_allocations.lot_id) AND (l.client_id = public.app_current_tenant_id()))))));


--
-- TOC entry 7431 (class 3256 OID 58744)
-- Name: fixed_payroll wardi_tenant_via_worker; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY wardi_tenant_via_worker ON public.fixed_payroll USING (((public.app_current_tenant_id() IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.workers w
  WHERE ((w.id = fixed_payroll.worker_id) AND (w.client_id = public.app_current_tenant_id())))))) WITH CHECK (((public.app_current_tenant_id() IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.workers w
  WHERE ((w.id = fixed_payroll.worker_id) AND (w.client_id = public.app_current_tenant_id()))))));


--
-- TOC entry 7405 (class 0 OID 57511)
-- Dependencies: 343
-- Name: workers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workers ENABLE ROW LEVEL SECURITY;

-- Completed on 2026-05-25 17:13:18

--
-- PostgreSQL database dump complete
--

\unrestrict bzoBXGZnOiGQlAWbzXYXyaddSl5XZKyWd7O9eFOC0xxT66fXjYjyl0co5P9F74K

