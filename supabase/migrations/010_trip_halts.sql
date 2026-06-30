-- 010_trip_halts.sql — Persist halt completion status per trip

CREATE TABLE trip_halts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  live_location_id UUID NOT NULL REFERENCES live_locations(id) ON DELETE CASCADE,
  halt_id UUID NOT NULL REFERENCES halts(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(live_location_id, halt_id)
);

CREATE INDEX idx_trip_halts_live_location ON trip_halts(live_location_id);

ALTER TABLE trip_halts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read trip_halts"
  ON trip_halts FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Drivers can manage their trip halts"
  ON trip_halts FOR ALL
  USING (
    live_location_id IN (
      SELECT id FROM live_locations
      WHERE driver_id IN (
        SELECT id FROM users_whitelist
        WHERE replace(phone_number, '+', '') =
              COALESCE(nullif(auth.jwt() ->> 'phone', ''), '')
      )
    )
  );
