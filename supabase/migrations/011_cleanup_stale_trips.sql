-- 011_cleanup_stale_trips.sql — Auto-end trips when driver stops pinging
--
-- Scheduled every 5 minutes via pg_cron. Marks trips as inactive when the
-- last recorded_at timestamp is more than 10 minutes old (the Flutter app
-- pings every 20 seconds, so 10 minutes means the driver definitely left).

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION cleanup_stale_trips()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE live_locations
  SET trip_active = false
  WHERE trip_active = true
    AND recorded_at < now() - interval '10 minutes';
END;
$$;

SELECT cron.schedule(
  'cleanup-stale-trips',   -- job name
  '*/5 * * * *',          -- every 5 minutes
  'SELECT cleanup_stale_trips();'
);

CREATE INDEX IF NOT EXISTS idx_live_locations_trip_active
  ON live_locations(trip_active)
  WHERE trip_active = true;
