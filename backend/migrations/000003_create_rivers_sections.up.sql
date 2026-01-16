CREATE TABLE rivers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    state VARCHAR(2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(name, state)
);

CREATE INDEX idx_rivers_name ON rivers(name);
CREATE INDEX idx_rivers_state ON rivers(state);

CREATE TABLE sections (
    id SERIAL PRIMARY KEY,
    river_id INTEGER NOT NULL REFERENCES rivers(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    class_rating VARCHAR(100),
    gradient DECIMAL(6,2),
    gradient_unit VARCHAR(10),
    mileage DECIMAL(6,2),
    put_in_name VARCHAR(255),
    take_out_name VARCHAR(255),
    gauge_name VARCHAR(255),
    gauge_id VARCHAR(50),
    flow_min DECIMAL(8,2),
    flow_max DECIMAL(8,2),
    flow_low DECIMAL(8,2),
    flow_high DECIMAL(8,2),
    flow_unit VARCHAR(50),
    aw_url TEXT,
    aw_id VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(river_id, name)
);

CREATE INDEX idx_sections_river_id ON sections(river_id);
CREATE INDEX idx_sections_name ON sections(name);
CREATE INDEX idx_sections_class_rating ON sections(class_rating);