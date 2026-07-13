-- 012_fix_deprecated_rls.sql — Replace deprecated auth.role() with TO clause
--
-- auth.role() is deprecated and breaks silently if anonymous sign-ins are
-- ever enabled. The Supabase skill also flags SECURITY DEFINER in public
-- schema and missing WITH CHECK on UPDATE policies.

-- ---------------------------------------------------------------------------
-- Fix 1: Recreate SELECT policies using TO authenticated + USING (true)
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Authenticated users can read whitelist" ON users_whitelist;
CREATE POLICY "Authenticated users can read whitelist"
  ON users_whitelist FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can read routes" ON routes;
CREATE POLICY "Authenticated users can read routes"
  ON routes FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can read students" ON students;
CREATE POLICY "Authenticated users can read students"
  ON students FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can read payments" ON payments;
CREATE POLICY "Authenticated users can read payments"
  ON payments FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can read live locations" ON live_locations;
CREATE POLICY "Authenticated users can read live locations"
  ON live_locations FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can read halts" ON halts;
CREATE POLICY "Authenticated users can read halts"
  ON halts FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can read trip_halts" ON trip_halts;
CREATE POLICY "Authenticated users can read trip_halts"
  ON trip_halts FOR SELECT
  TO authenticated
  USING (true);

-- ---------------------------------------------------------------------------
-- Fix 2: Add WITH CHECK to live_locations UPDATE policy
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Drivers can update their own trip" ON live_locations;
CREATE POLICY "Drivers can update their own trip"
  ON live_locations FOR UPDATE
  TO authenticated
  USING (
    driver_id IN (
      SELECT id FROM users_whitelist
      WHERE replace(phone_number, '+', '') =
            COALESCE(nullif(auth.jwt() ->> 'phone', ''), '')
    )
  )
  WITH CHECK (
    driver_id IN (
      SELECT id FROM users_whitelist
      WHERE replace(phone_number, '+', '') =
            COALESCE(nullif(auth.jwt() ->> 'phone', ''), '')
    )
  );

-- ---------------------------------------------------------------------------
-- Fix 3: Change is_admin() from SECURITY DEFINER to SECURITY INVOKER
--
-- auth.jwt() is available in RLS context regardless of definer/invoker.
-- The function reads users_whitelist which has a SELECT policy for
-- authenticated users, so SECURITY INVOKER is safe and avoids the
-- "callable by all roles" risk of SECURITY DEFINER in public schema.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql STABLE SECURITY INVOKER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users_whitelist
    WHERE replace(phone_number, '+', '') =
          COALESCE(nullif(auth.jwt() ->> 'phone', ''), '')
    AND role = 'Admin'
  );
$$;
