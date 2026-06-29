-- 008_strict_admin_rls.sql — Enforce admin-only writes via is_admin()

-- Helper function: checks if the authenticated user has Admin role
-- Uses auth.jwt() which is available in RLS context.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users_whitelist
    WHERE replace(phone_number, '+', '') =
          COALESCE(nullif(auth.jwt() ->> 'phone', ''), '')
    AND role = 'Admin'
  );
$$;

-- Recreate admin-write policies to use is_admin() instead of
-- auth.role() = 'authenticated' (which allows writes by any user).

DROP POLICY IF EXISTS "Admins can manage whitelist" ON users_whitelist;
CREATE POLICY "Admins can manage whitelist"
  ON users_whitelist FOR ALL
  USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can manage routes" ON routes;
CREATE POLICY "Admins can manage routes"
  ON routes FOR ALL
  USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can manage students" ON students;
CREATE POLICY "Admins can manage students"
  ON students FOR ALL
  USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can manage payments" ON payments;
CREATE POLICY "Admins can manage payments"
  ON payments FOR ALL
  USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can manage halts" ON halts;
CREATE POLICY "Admins can manage halts"
  ON halts FOR ALL
  USING (public.is_admin());
