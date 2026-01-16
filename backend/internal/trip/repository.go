package trip

import (
	"database/sql"
	"fmt"
	"strings"
	"time"
)

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

// Create creates a new trip
func (r *Repository) Create(userID int, req CreateTripRequest) (*Trip, error) {
	query := `
		INSERT INTO trips (
			user_id, section_id, trip_date, difficulty, flow, flow_unit,
			craft_type, duration_minutes, mileage, notes
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id, created_at, updated_at
	`

	var trip Trip
	trip.UserID = userID
	trip.SectionID = req.SectionID
	trip.TripDate = req.TripDate
	trip.Difficulty = req.Difficulty
	trip.Flow = req.Flow
	trip.FlowUnit = req.FlowUnit
	trip.CraftType = req.CraftType
	trip.DurationMinutes = req.DurationMinutes
	trip.Mileage = req.Mileage
	trip.Notes = req.Notes

	err := r.db.QueryRow(
		query,
		userID, req.SectionID, req.TripDate, req.Difficulty, req.Flow, req.FlowUnit,
		req.CraftType, req.DurationMinutes, req.Mileage, req.Notes,
	).Scan(&trip.ID, &trip.CreatedAt, &trip.UpdatedAt)

	if err != nil {
		return nil, err
	}

	// Fetch the complete trip with section/river info
	return r.GetByID(trip.ID, userID)
}

// List retrieves trips for a user with pagination
func (r *Repository) List(userID int, limit, offset int, sortBy, sortOrder string) ([]Trip, int, error) {
	// Get total count
	var total int
	countQuery := "SELECT COUNT(*) FROM trips WHERE user_id = $1"
	err := r.db.QueryRow(countQuery, userID).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// Validate sort parameters
	validSorts := map[string]bool{
		"trip_date":  true,
		"created_at": true,
		"river_name": true,
	}
	if !validSorts[sortBy] {
		sortBy = "trip_date"
	}
	if sortOrder != "asc" && sortOrder != "desc" {
		sortOrder = "desc"
	}

	// Build query
	query := fmt.Sprintf(`
		SELECT 
			t.id, t.user_id, t.section_id, r.name as river_name, 
			s.name as section_name, r.state, t.trip_date,
			t.difficulty, t.flow, t.flow_unit, t.craft_type,
			t.duration_minutes, t.mileage, t.notes, t.created_at, t.updated_at
		FROM trips t
		JOIN sections s ON t.section_id = s.id
		JOIN rivers r ON s.river_id = r.id
		WHERE t.user_id = $1
		ORDER BY %s %s
		LIMIT $2 OFFSET $3
	`, sortBy, sortOrder)

	rows, err := r.db.Query(query, userID, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var trips []Trip
	for rows.Next() {
		trip, err := scanTrip(rows)
		if err != nil {
			return nil, 0, err
		}
		trips = append(trips, *trip)
	}

	return trips, total, nil
}

// GetByID retrieves a trip by ID
func (r *Repository) GetByID(id, userID int) (*Trip, error) {
	query := `
		SELECT 
			t.id, t.user_id, t.section_id, r.name as river_name,
			s.name as section_name, r.state, t.trip_date,
			t.difficulty, t.flow, t.flow_unit, t.craft_type,
			t.duration_minutes, t.mileage, t.notes, t.created_at, t.updated_at
		FROM trips t
		JOIN sections s ON t.section_id = s.id
		JOIN rivers r ON s.river_id = r.id
		WHERE t.id = $1 AND t.user_id = $2
	`

	trip, err := scanTrip(r.db.QueryRow(query, id, userID))
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("trip not found")
	}
	if err != nil {
		return nil, err
	}

	return trip, nil
}

// Update updates a trip
func (r *Repository) Update(id, userID int, req UpdateTripRequest) (*Trip, error) {
	// Build dynamic update query
	var setClauses []string
	var args []interface{}
	argCount := 0

	if req.SectionID != nil {
		argCount++
		setClauses = append(setClauses, fmt.Sprintf("section_id = $%d", argCount))
		args = append(args, *req.SectionID)
	}
	if req.TripDate != nil {
		argCount++
		setClauses = append(setClauses, fmt.Sprintf("trip_date = $%d", argCount))
		args = append(args, *req.TripDate)
	}
	if req.Difficulty != nil {
		argCount++
		setClauses = append(setClauses, fmt.Sprintf("difficulty = $%d", argCount))
		args = append(args, *req.Difficulty)
	}
	if req.Flow != nil {
		argCount++
		setClauses = append(setClauses, fmt.Sprintf("flow = $%d", argCount))
		args = append(args, *req.Flow)
	}
	if req.FlowUnit != nil {
		argCount++
		setClauses = append(setClauses, fmt.Sprintf("flow_unit = $%d", argCount))
		args = append(args, *req.FlowUnit)
	}
	if req.CraftType != nil {
		argCount++
		setClauses = append(setClauses, fmt.Sprintf("craft_type = $%d", argCount))
		args = append(args, *req.CraftType)
	}
	if req.DurationMinutes != nil {
		argCount++
		setClauses = append(setClauses, fmt.Sprintf("duration_minutes = $%d", argCount))
		args = append(args, *req.DurationMinutes)
	}
	if req.Mileage != nil {
		argCount++
		setClauses = append(setClauses, fmt.Sprintf("mileage = $%d", argCount))
		args = append(args, *req.Mileage)
	}
	if req.Notes != nil {
		argCount++
		setClauses = append(setClauses, fmt.Sprintf("notes = $%d", argCount))
		args = append(args, *req.Notes)
	}

	if len(setClauses) == 0 {
		return r.GetByID(id, userID)
	}

	// Add updated_at
	argCount++
	setClauses = append(setClauses, fmt.Sprintf("updated_at = $%d", argCount))
	args = append(args, time.Now())

	// Add WHERE clause args
	argCount++
	args = append(args, id)
	argCount++
	args = append(args, userID)

	query := fmt.Sprintf(`
		UPDATE trips
		SET %s
		WHERE id = $%d AND user_id = $%d
	`, strings.Join(setClauses, ", "), argCount-1, argCount)

	_, err := r.db.Exec(query, args...)
	if err != nil {
		return nil, err
	}

	return r.GetByID(id, userID)
}

// Delete deletes a trip
func (r *Repository) Delete(id, userID int) error {
	query := "DELETE FROM trips WHERE id = $1 AND user_id = $2"
	result, err := r.db.Exec(query, id, userID)
	if err != nil {
		return err
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rows == 0 {
		return fmt.Errorf("trip not found")
	}

	return nil
}

// Helper function to scan a trip from a row
type scanner interface {
	Scan(dest ...interface{}) error
}

func scanTrip(row scanner) (*Trip, error) {
	var trip Trip
	err := row.Scan(
		&trip.ID,
		&trip.UserID,
		&trip.SectionID,
		&trip.RiverName,
		&trip.SectionName,
		&trip.State,
		&trip.TripDate,
		&trip.Difficulty,
		&trip.Flow,
		&trip.FlowUnit,
		&trip.CraftType,
		&trip.DurationMinutes,
		&trip.Mileage,
		&trip.Notes,
		&trip.CreatedAt,
		&trip.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &trip, nil
}
