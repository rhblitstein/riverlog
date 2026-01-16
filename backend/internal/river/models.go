package river

import "time"

type River struct {
	ID        int       `json:"id"`
	Name      string    `json:"name"`
	State     string    `json:"state"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type Section struct {
	ID           int       `json:"id"`
	RiverID      int       `json:"river_id"`
	RiverName    string    `json:"river_name"`
	State        string    `json:"state"`
	Name         string    `json:"name"`
	ClassRating  *string   `json:"class_rating,omitempty"`
	Gradient     *float64  `json:"gradient,omitempty"`
	GradientUnit *string   `json:"gradient_unit,omitempty"`
	Mileage      *float64  `json:"mileage,omitempty"`
	PutInName    *string   `json:"put_in_name,omitempty"`
	TakeOutName  *string   `json:"take_out_name,omitempty"`
	GaugeName    *string   `json:"gauge_name,omitempty"`
	GaugeID      *string   `json:"gauge_id,omitempty"`
	FlowMin      *float64  `json:"flow_min,omitempty"`
	FlowMax      *float64  `json:"flow_max,omitempty"`
	FlowLow      *float64  `json:"flow_low,omitempty"`
	FlowHigh     *float64  `json:"flow_high,omitempty"`
	FlowUnit     *string   `json:"flow_unit,omitempty"`
	AWURL        *string   `json:"aw_url,omitempty"`
	AWID         *string   `json:"aw_id,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

type ListRiversParams struct {
	State  string
	Search string
	Limit  int
	Offset int
}

type ListSectionsParams struct {
	RiverID int
	State   string
	Search  string
	Limit   int
	Offset  int
}
