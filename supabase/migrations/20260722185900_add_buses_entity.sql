-- Migration to add buses entity
-- Provides 100% backward compatibility via Postgres triggers

-- 1. Create buses table
CREATE TABLE IF NOT EXISTS buses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  driver_id UUID REFERENCES users_whitelist(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE buses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read buses"
  ON buses FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage buses"
  ON buses FOR ALL
  USING (public.is_admin());

-- 2. Add bus_id to routes (keeping driver_id for backward compatibility)
ALTER TABLE routes ADD COLUMN IF NOT EXISTS bus_id UUID REFERENCES buses(id) ON DELETE SET NULL;

-- 3. Add bus_ids array to students (keeping route_id for backward compatibility)
ALTER TABLE students ADD COLUMN IF NOT EXISTS bus_ids UUID[] DEFAULT '{}'::uuid[];

-- 4. Create trigger to sync routes.driver_id with buses.driver_id
CREATE OR REPLACE FUNCTION sync_route_driver()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.bus_id IS NOT NULL THEN
    SELECT driver_id INTO NEW.driver_id FROM buses WHERE id = NEW.bus_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_route_driver ON routes;
CREATE TRIGGER trg_sync_route_driver
BEFORE INSERT OR UPDATE ON routes
FOR EACH ROW
EXECUTE FUNCTION sync_route_driver();

-- 5. Create trigger to cascade driver_id changes from buses to routes
CREATE OR REPLACE FUNCTION cascade_bus_driver_update()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.driver_id IS DISTINCT FROM OLD.driver_id THEN
    UPDATE routes SET driver_id = NEW.driver_id WHERE bus_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_cascade_bus_driver ON buses;
CREATE TRIGGER trg_cascade_bus_driver
AFTER UPDATE ON buses
FOR EACH ROW
EXECUTE FUNCTION cascade_bus_driver_update();

-- 6. Create trigger to sync students.route_id using the first bus provided in bus_ids
CREATE OR REPLACE FUNCTION sync_student_route_id()
RETURNS TRIGGER AS $$
DECLARE
  first_bus_id UUID;
  fallback_route_id UUID;
BEGIN
  -- If bus_ids is populated, try to find a route associated with the first bus
  IF NEW.bus_ids IS NOT NULL AND array_length(NEW.bus_ids, 1) > 0 THEN
    first_bus_id := NEW.bus_ids[1];
    SELECT id INTO fallback_route_id FROM routes WHERE bus_id = first_bus_id LIMIT 1;
    IF fallback_route_id IS NOT NULL THEN
      NEW.route_id := fallback_route_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_student_route ON students;
CREATE TRIGGER trg_sync_student_route
BEFORE INSERT OR UPDATE ON students
FOR EACH ROW
WHEN (pg_trigger_depth() = 0)
EXECUTE FUNCTION sync_student_route_id();
