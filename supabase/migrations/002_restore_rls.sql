-- 002_restore_rls.sql — Revert relaxed policies back to original
-- Run this in the Supabase SQL Editor.

-- Drop any relaxed policies created during troubleshooting
DROP POLICY IF EXISTS "Anyone can read whitelist" ON users_whitelist;
DROP POLICY IF EXISTS "Anyone can read routes" ON routes;
DROP POLICY IF EXISTS "Anyone can read students" ON students;
DROP POLICY IF EXISTS "Anyone can read payments" ON payments;
DROP POLICY IF EXISTS "Anyone can manage OTP" ON otp_codes;
DROP POLICY IF EXISTS "Anyone can manage live_locations" ON live_locations;

-- Re-create original policies (drop first to avoid duplicates)
DROP POLICY IF EXISTS "Authenticated users can read whitelist" ON users_whitelist;
CREATE POLICY "Authenticated users can read whitelist"
  ON users_whitelist FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Admins can manage whitelist" ON users_whitelist;
CREATE POLICY "Admins can manage whitelist"
  ON users_whitelist FOR ALL
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can read routes" ON routes;
CREATE POLICY "Authenticated users can read routes"
  ON routes FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Admins can manage routes" ON routes;
CREATE POLICY "Admins can manage routes"
  ON routes FOR ALL
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can read students" ON students;
CREATE POLICY "Authenticated users can read students"
  ON students FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Admins can manage students" ON students;
CREATE POLICY "Admins can manage students"
  ON students FOR ALL
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can read payments" ON payments;
CREATE POLICY "Authenticated users can read payments"
  ON payments FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Admins can manage payments" ON payments;
CREATE POLICY "Admins can manage payments"
  ON payments FOR ALL
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can read live locations" ON live_locations;
CREATE POLICY "Authenticated users can read live locations"
  ON live_locations FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Drivers can insert their own location" ON live_locations;
CREATE POLICY "Drivers can insert their own location"
  ON live_locations FOR INSERT
  WITH CHECK (auth.uid() = driver_id);

DROP POLICY IF EXISTS "Drivers can update their own trip" ON live_locations;
CREATE POLICY "Drivers can update their own trip"
  ON live_locations FOR UPDATE
  USING (auth.uid() = driver_id);
