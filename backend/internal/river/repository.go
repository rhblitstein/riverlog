package river

import (
	"database/sql"
	"fmt"
	"strings"
)

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

// ListRivers retrieves rivers with optional filtering
func (r *Repository) ListRivers(params ListRiversParams) ([]River, int, error) {
	var conditions []string
	var args []interface{}
	argCount := 0

	if params.State != "" {
		argCount++
		conditions = append(conditions, fmt.Sprintf("state = $%d", argCount))
		args = append(args, params.State)
	}

	if params.Search != "" {
		argCount++
		conditions = append(conditions, fmt.Sprintf("LOWER(name) LIKE $%d", argCount))
		args = append(args, "%"+strings.ToLower(params.Search)+"%")
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	// Get total count
	var total int
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM rivers %s", whereClause)
	err := r.db.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// Get rivers
	if params.Limit == 0 {
		params.Limit = 50
	}

	query := fmt.Sprintf(`
		SELECT id, name, state, created_at, updated_at
		FROM rivers
		%s
		ORDER BY name ASC
		LIMIT $%d OFFSET $%d
	`, whereClause, argCount+1, argCount+2)

	args = append(args, params.Limit, params.Offset)

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var rivers []River
	for rows.Next() {
		var river River
		err := rows.Scan(&river.ID, &river.Name, &river.State, &river.CreatedAt, &river.UpdatedAt)
		if err != nil {
			return nil, 0, err
		}
		rivers = append(rivers, river)
	}

	return rivers, total, nil
}

// ListSections retrieves sections with optional filtering
func (r *Repository) ListSections(params ListSectionsParams) ([]Section, int, error) {
	var conditions []string
	var args []interface{}
	argCount := 0

	if params.RiverID > 0 {
		argCount++
		conditions = append(conditions, fmt.Sprintf("s.river_id = $%d", argCount))
		args = append(args, params.RiverID)
	}

	if params.State != "" {
		argCount++
		conditions = append(conditions, fmt.Sprintf("r.state = $%d", argCount))
		args = append(args, params.State)
	}

	if params.Search != "" {
		argCount++
		conditions = append(conditions, fmt.Sprintf("(LOWER(s.name) LIKE $%d OR LOWER(r.name) LIKE $%d)", argCount, argCount))
		args = append(args, "%"+strings.ToLower(params.Search)+"%")
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = "WHERE " + strings.Join(conditions, " AND ")
	}

	// Get total count
	var total int
	countQuery := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM sections s
		JOIN rivers r ON s.river_id = r.id
		%s
	`, whereClause)
	err := r.db.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// Get sections
	if params.Limit == 0 {
		params.Limit = 50
	}

	query := fmt.Sprintf(`
		SELECT 
			s.id, s.river_id, r.name as river_name, r.state, s.name,
			s.class_rating, s.gradient, s.gradient_unit, s.mileage,
			s.put_in_name, s.take_out_name, s.gauge_name, s.gauge_id,
			s.flow_min, s.flow_max, s.flow_low, s.flow_high, s.flow_unit,
			s.aw_url, s.aw_id, s.created_at, s.updated_at
		FROM sections s
		JOIN rivers r ON s.river_id = r.id
		%s
		ORDER BY r.name ASC, s.name ASC
		LIMIT $%d OFFSET $%d
	`, whereClause, argCount+1, argCount+2)

	args = append(args, params.Limit, params.Offset)

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var sections []Section
	for rows.Next() {
		var section Section
		err := rows.Scan(
			&section.ID, &section.RiverID, &section.RiverName, &section.State, &section.Name,
			&section.ClassRating, &section.Gradient, &section.GradientUnit, &section.Mileage,
			&section.PutInName, &section.TakeOutName, &section.GaugeName, &section.GaugeID,
			&section.FlowMin, &section.FlowMax, &section.FlowLow, &section.FlowHigh, &section.FlowUnit,
			&section.AWURL, &section.AWID, &section.CreatedAt, &section.UpdatedAt,
		)
		if err != nil {
			return nil, 0, err
		}
		sections = append(sections, section)
	}

	return sections, total, nil
}

// GetSection retrieves a section by ID
func (r *Repository) GetSection(id int) (*Section, error) {
	query := `
		SELECT 
			s.id, s.river_id, r.name as river_name, r.state, s.name,
			s.class_rating, s.gradient, s.gradient_unit, s.mileage,
			s.put_in_name, s.take_out_name, s.gauge_name, s.gauge_id,
			s.flow_min, s.flow_max, s.flow_low, s.flow_high, s.flow_unit,
			s.aw_url, s.aw_id, s.created_at, s.updated_at
		FROM sections s
		JOIN rivers r ON s.river_id = r.id
		WHERE s.id = $1
	`

	var section Section
	err := r.db.QueryRow(query, id).Scan(
		&section.ID, &section.RiverID, &section.RiverName, &section.State, &section.Name,
		&section.ClassRating, &section.Gradient, &section.GradientUnit, &section.Mileage,
		&section.PutInName, &section.TakeOutName, &section.GaugeName, &section.GaugeID,
		&section.FlowMin, &section.FlowMax, &section.FlowLow, &section.FlowHigh, &section.FlowUnit,
		&section.AWURL, &section.AWID, &section.CreatedAt, &section.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("section not found")
	}
	if err != nil {
		return nil, err
	}

	return &section, nil
}
