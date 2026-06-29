-- 007_drop_anon_policies.sql — Remove dev anon-read policies

DROP POLICY IF EXISTS "Allow anon reads on whitelist" ON users_whitelist;
DROP POLICY IF EXISTS "Allow anon reads on routes" ON routes;
DROP POLICY IF EXISTS "Allow anon reads on students" ON students;
DROP POLICY IF EXISTS "Allow anon reads on payments" ON payments;
DROP POLICY IF EXISTS "Allow anon reads on halts" ON halts;
DROP POLICY IF EXISTS "Allow anon reads on live_locations" ON live_locations;
