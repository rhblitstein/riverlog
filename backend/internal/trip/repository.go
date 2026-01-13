package trip

import (
	"database/sql"
	"errors"
	"fmt"
)

var (
	ErrTripNotFound = errors.New("trip not found")
)

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

// Helper function to convert sql.Null* to pointers
func scanTrip(rows interface{ Scan(...interface{}) error }) (*Trip, error) {
	var (
		difficulty      sql.NullString
		flow            sql.NullInt64
		flowUnit        sql.NullString
		craftType       sql.NullString
		durationMinutes sql.NullInt64
		mileage         sql.NullFloat64
		notes           sql.NullString
	)

	trip := &Trip{}
	err := rows.Scan(
		&trip.ID,
		&trip.UserID,
		&trip.RiverName,
		&trip.SectionName,
		&trip.TripDate,
		&difficulty,
		&flow,
		&flowUnit,
		&craftType,
		&durationMinutes,
		&mileage,
		&notes,
		&trip.CreatedAt,
		&trip.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	// Convert sql.Null* to pointers
	if difficulty.Valid {
		trip.Difficulty = &difficulty.String
	}
	if flow.Valid {
		val := int(flow.Int64)
		trip.Flow = &val
	}
	if flowUnit.Valid {
		trip.FlowUnit = &flowUnit.String
	}
	if craftType.Valid {
		trip.CraftType = &craftType.String
	}
	if durationMinutes.Valid {
		val := int(durationMinutes.Int64)
		trip.DurationMinutes = &val
	}
	if mileage.Valid {
		trip.Mileage = &mileage.Float64
	}
	if notes.Valid {
		trip.Notes = &notes.String
	}

	return trip, nil
}

// Create inserts a new trip
func (r *Repository) Create(userID int, req CreateTripRequest) (*Trip, error) {
	query := `
		INSERT INTO trips (
			user_id, river_name, section_name, trip_date, 
			difficulty, flow, flow_unit, craft_type, 
			duration_minutes, mileage, notes
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING id, user_id, river_name, section_name, trip_date,
			difficulty, flow, flow_unit, craft_type,
			duration_minutes, mileage, notes, created_at, updated_at
	`

	return scanTrip(r.db.QueryRow(
		query,
		userID,
		req.RiverName,
		req.SectionName,
		req.TripDate,
		req.Difficulty,
		req.Flow,
		req.FlowUnit,
		req.CraftType,
		req.DurationMinutes,
		req.Mileage,
		req.Notes,
	))
}

// List retrieves trips for a user with pagination
func (r *Repository) List(userID int, params ListTripsParams) ([]Trip, int, error) {
	// Get total count
	var total int
	countQuery := `SELECT COUNT(*) FROM trips WHERE user_id = $1`
	err := r.db.QueryRow(countQuery, userID).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// Determine sort order
	orderBy := "trip_date DESC"
	if params.Sort == "date_asc" {
		orderBy = "trip_date ASC"
	}

	query := fmt.Sprintf(`
		SELECT id, user_id, river_name, section_name, trip_date,
			difficulty, flow, flow_unit, craft_type,
			duration_minutes, mileage, notes, created_at, updated_at
		FROM trips
		WHERE user_id = $1
		ORDER BY %s
		LIMIT $2 OFFSET $3
	`, orderBy)

	rows, err := r.db.Query(query, userID, params.Limit, params.Offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	trips := []Trip{}
	for rows.Next() {
		trip, err := scanTrip(rows)
		if err != nil {
			return nil, 0, err
		}
		trips = append(trips, *trip)
	}

	return trips, total, nil
}

// GetByID retrieves a specific trip
func (r *Repository) GetByID(userID, tripID int) (*Trip, error) {
	query := `
		SELECT id, user_id, river_name, section_name, trip_date,
			difficulty, flow, flow_unit, craft_type,
			duration_minutes, mileage, notes, created_at, updated_at
		FROM trips
		WHERE id = $1 AND user_id = $2
	`

	trip, err := scanTrip(r.db.QueryRow(query, tripID, userID))
	if err == sql.ErrNoRows {
		return nil, ErrTripNotFound
	}
	return trip, err
}

// Update updates a trip
func (r *Repository) Update(userID, tripID int, req UpdateTripRequest) (*Trip, error) {
	// First check if trip exists and belongs to user
	_, err := r.GetByID(userID, tripID)
	if err != nil {
		return nil, err
	}

	query := `
		UPDATE trips
		SET 
			river_name = COALESCE($1, river_name),
			section_name = COALESCE($2, section_name),
			trip_date = COALESCE($3, trip_date),
			difficulty = COALESCE($4, difficulty),
			flow = COALESCE($5, flow),
			flow_unit = COALESCE($6, flow_unit),
			craft_type = COALESCE($7, craft_type),
			duration_minutes = COALESCE($8, duration_minutes),
			mileage = COALESCE($9, mileage),
			notes = COALESCE($10, notes),
			updated_at = NOW()
		WHERE id = $11 AND user_id = $12
		RETURNING id, user_id, river_name, section_name, trip_date,
			difficulty, flow, flow_unit, craft_type,
			duration_minutes, mileage, notes, created_at, updated_at
	`

	return scanTrip(r.db.QueryRow(
		query,
		req.RiverName,
		req.SectionName,
		req.TripDate,
		req.Difficulty,
		req.Flow,
		req.FlowUnit,
		req.CraftType,
		req.DurationMinutes,
		req.Mileage,
		req.Notes,
		tripID,
		userID,
	))
}

// Delete deletes a trip
func (r *Repository) Delete(userID, tripID int) error {
	query := `DELETE FROM trips WHERE id = $1 AND user_id = $2`

	result, err := r.db.Exec(query, tripID, userID)
	if err != nil {
		return err
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rows == 0 {
		return ErrTripNotFound
	}

	return nil
}
