-- 001_schema.sql — Smart School Bus Tracker

-- Users whitelist: phone → role mapping
CREATE TABLE users_whitelist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('Admin', 'Driver', 'Parent')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Bus routes + driver assignment
CREATE TABLE routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  driver_id UUID REFERENCES users_whitelist(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Students linked to parent + route
CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  parent_id UUID REFERENCES users_whitelist(id) ON DELETE CASCADE,
  route_id UUID REFERENCES routes(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Monthly payment ledger per student
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  month TEXT NOT NULL,
  paid BOOLEAN DEFAULT false,
  UNIQUE(student_id, month)
);

-- Live GPS pings from drivers
CREATE TABLE live_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  driver_id UUID REFERENCES users_whitelist(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  trip_active BOOLEAN DEFAULT true,
  recorded_at TIMESTAMPTZ DEFAULT now()
);

-- OTP codes for SMS verification
CREATE TABLE otp_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number TEXT NOT NULL,
  code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT now() + interval '5 minutes',
  used BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for OTP lookups
CREATE INDEX idx_otp_codes_phone ON otp_codes(phone_number);
CREATE INDEX idx_live_locations_route ON live_locations(route_id);
CREATE INDEX idx_students_parent ON students(parent_id);

-- Enable Row Level Security
ALTER TABLE users_whitelist ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE otp_codes ENABLE ROW LEVEL SECURITY;

-- RLS policies: authenticated users only
CREATE POLICY "Authenticated users can read whitelist"
  ON users_whitelist FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage whitelist"
  ON users_whitelist FOR ALL
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read routes"
  ON routes FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage routes"
  ON routes FOR ALL
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read students"
  ON students FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage students"
  ON students FOR ALL
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read payments"
  ON payments FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage payments"
  ON payments FOR ALL
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can read live locations"
  ON live_locations FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Drivers can insert their own location"
  ON live_locations FOR INSERT
  WITH CHECK (auth.uid() = driver_id);

CREATE POLICY "Drivers can update their own trip"
  ON live_locations FOR UPDATE
  USING (auth.uid() = driver_id);

-- Enable real-time for live locations
ALTER PUBLICATION supabase_realtime ADD TABLE live_locations;
