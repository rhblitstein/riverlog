CREATE TABLE trips (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    river_name VARCHAR(255) NOT NULL,
    section_name VARCHAR(255) NOT NULL,
    trip_date DATE NOT NULL,
    difficulty VARCHAR(50),
    flow INTEGER,
    flow_unit VARCHAR(50) DEFAULT 'cfs',
    craft_type VARCHAR(50),
    duration_minutes INTEGER,
    mileage DECIMAL(5,2),
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trips_user_id ON trips(user_id);
CREATE INDEX idx_trips_trip_date ON trips(trip_date);