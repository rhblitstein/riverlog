-- Restore old columns
ALTER TABLE trips ADD COLUMN river_name VARCHAR(255);
ALTER TABLE trips ADD COLUMN section_name VARCHAR(255);

-- Drop section_id
DROP INDEX IF EXISTS idx_trips_section_id;
ALTER TABLE trips DROP COLUMN section_id;