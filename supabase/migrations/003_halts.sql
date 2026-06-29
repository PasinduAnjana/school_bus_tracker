-- 003_halts.sql — Route halts with location, ordering, and RLS

CREATE TABLE halts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  arrival_time TIME NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  stop_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_halts_route ON halts(route_id);

ALTER TABLE halts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read halts"
  ON halts FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage halts"
  ON halts FOR ALL
  USING (auth.role() = 'authenticated');

ALTER PUBLICATION supabase_realtime ADD TABLE halts;
