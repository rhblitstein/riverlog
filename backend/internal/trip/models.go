package trip

import (
	"time"
)

type Trip struct {
	ID              int       `json:"id"`
	UserID          int       `json:"user_id"`
	RiverName       string    `json:"river_name"`
	SectionName     string    `json:"section_name"`
	TripDate        string    `json:"trip_date"` // YYYY-MM-DD format
	Difficulty      *string   `json:"difficulty,omitempty"`
	Flow            *int      `json:"flow,omitempty"`
	FlowUnit        *string   `json:"flow_unit,omitempty"`
	CraftType       *string   `json:"craft_type,omitempty"`
	DurationMinutes *int      `json:"duration_minutes,omitempty"`
	Mileage         *float64  `json:"mileage,omitempty"`
	Notes           *string   `json:"notes,omitempty"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

type CreateTripRequest struct {
	RiverName       string   `json:"river_name"`
	SectionName     string   `json:"section_name"`
	TripDate        string   `json:"trip_date"`
	Difficulty      *string  `json:"difficulty,omitempty"`
	Flow            *int     `json:"flow,omitempty"`
	FlowUnit        *string  `json:"flow_unit,omitempty"`
	CraftType       *string  `json:"craft_type,omitempty"`
	DurationMinutes *int     `json:"duration_minutes,omitempty"`
	Mileage         *float64 `json:"mileage,omitempty"`
	Notes           *string  `json:"notes,omitempty"`
}

type UpdateTripRequest struct {
	RiverName       *string  `json:"river_name,omitempty"`
	SectionName     *string  `json:"section_name,omitempty"`
	TripDate        *string  `json:"trip_date,omitempty"`
	Difficulty      *string  `json:"difficulty,omitempty"`
	Flow            *int     `json:"flow,omitempty"`
	FlowUnit        *string  `json:"flow_unit,omitempty"`
	CraftType       *string  `json:"craft_type,omitempty"`
	DurationMinutes *int     `json:"duration_minutes,omitempty"`
	Mileage         *float64 `json:"mileage,omitempty"`
	Notes           *string  `json:"notes,omitempty"`
}

type ListTripsParams struct {
	Limit  int
	Offset int
	Sort   string // "date_desc" or "date_asc"
}
