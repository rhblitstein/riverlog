-- Drop old text columns
ALTER TABLE trips DROP COLUMN river_name;
ALTER TABLE trips DROP COLUMN section_name;

-- Add section_id as required
ALTER TABLE trips ADD COLUMN section_id INTEGER NOT NULL REFERENCES sections(id) ON DELETE RESTRICT;

-- Create index
CREATE INDEX idx_trips_section_id ON trips(section_id);