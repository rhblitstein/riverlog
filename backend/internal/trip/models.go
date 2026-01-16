package trip

import (
	"time"
)

type Trip struct {
	ID              int       `json:"id"`
	UserID          int       `json:"user_id"`
	SectionID       int       `json:"section_id"`
	RiverName       string    `json:"river_name"`   // From join
	SectionName     string    `json:"section_name"` // From join
	State           string    `json:"state"`        // From join
	TripDate        string    `json:"trip_date"`
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
	SectionID       int      `json:"section_id"`
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
	SectionID       *int     `json:"section_id,omitempty"`
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
