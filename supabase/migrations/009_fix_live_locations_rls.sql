-- 009_fix_live_locations_rls.sql — Fix driver policies for whitelist ID mismatch
--
-- auth.uid() returns the Supabase Auth user UUID (auth.users.id).
-- driver_id in live_locations references users_whitelist.id (a different UUID).
-- Replace auth.uid() checks with phone-based whitelist lookup.

DROP POLICY IF EXISTS "Drivers can insert their own location" ON live_locations;
CREATE POLICY "Drivers can insert their own location"
  ON live_locations FOR INSERT
  WITH CHECK (
    driver_id IN (
      SELECT id FROM users_whitelist
      WHERE replace(phone_number, '+', '') =
            COALESCE(nullif(auth.jwt() ->> 'phone', ''), '')
    )
  );

DROP POLICY IF EXISTS "Drivers can update their own trip" ON live_locations;
CREATE POLICY "Drivers can update their own trip"
  ON live_locations FOR UPDATE
  USING (
    driver_id IN (
      SELECT id FROM users_whitelist
      WHERE replace(phone_number, '+', '') =
            COALESCE(nullif(auth.jwt() ->> 'phone', ''), '')
    )
  );
