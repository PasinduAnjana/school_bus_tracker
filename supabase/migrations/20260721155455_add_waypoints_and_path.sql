ALTER TABLE routes
ADD COLUMN waypoints JSONB,
ADD COLUMN encoded_path TEXT;
