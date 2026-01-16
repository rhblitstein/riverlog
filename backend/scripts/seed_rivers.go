package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq"
	"github.com/rhblitstein/riverlog/internal/database"
)

type SectionData struct {
	ID           string   `json:"id"`
	Name         string   `json:"name"`
	RiverName    string   `json:"riverName"`
	State        string   `json:"state"`
	ClassRating  string   `json:"classRating"`
	Gradient     *float64 `json:"gradient"`
	GradientUnit string   `json:"gradientUnit"`
	Mileage      *float64 `json:"mileage"`
	PutInName    string   `json:"putInName"`
	TakeOutName  string   `json:"takeOutName"`
	GaugeName    string   `json:"gaugeName"`
	GaugeID      string   `json:"gaugeID"`
	FlowMin      *float64 `json:"flowMin"`
	FlowMax      *float64 `json:"flowMax"`
	FlowLow      *float64 `json:"flowLow"`
	FlowHigh     *float64 `json:"flowHigh"`
	FlowUnit     string   `json:"flowUnit"`
	AWURL        string   `json:"awURL"`
}

func main() {
	// Load database URL from env
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		log.Fatal("DATABASE_URL environment variable is required")
	}

	// Connect to database
	db, err := database.New(databaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Read JSON file
	data, err := os.ReadFile("rivers_sections.json")
	if err != nil {
		log.Fatalf("Failed to read JSON file: %v", err)
	}

	var sections []SectionData
	if err := json.Unmarshal(data, &sections); err != nil {
		log.Fatalf("Failed to parse JSON: %v", err)
	}

	// Track rivers we've already inserted
	riverIDs := make(map[string]int)

	for _, section := range sections {
		// Get or create river
		riverKey := section.RiverName + "|" + section.State
		riverID, exists := riverIDs[riverKey]

		if !exists {
			// Insert river
			err := db.QueryRow(`
				INSERT INTO rivers (name, state)
				VALUES ($1, $2)
				ON CONFLICT (name, state) DO UPDATE SET name = EXCLUDED.name
				RETURNING id
			`, section.RiverName, section.State).Scan(&riverID)

			if err != nil {
				log.Printf("Failed to insert river %s: %v", section.RiverName, err)
				continue
			}

			riverIDs[riverKey] = riverID
		}

		// Insert section
		_, err := db.Exec(`
			INSERT INTO sections (
				river_id, name, class_rating, gradient, gradient_unit,
				mileage, put_in_name, take_out_name, gauge_name, gauge_id,
				flow_min, flow_max, flow_low, flow_high, flow_unit,
				aw_url, aw_id
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
			ON CONFLICT (river_id, name) DO NOTHING
		`,
			riverID, section.Name, section.ClassRating, section.Gradient, section.GradientUnit,
			section.Mileage, section.PutInName, section.TakeOutName, section.GaugeName, section.GaugeID,
			section.FlowMin, section.FlowMax, section.FlowLow, section.FlowHigh, section.FlowUnit,
			section.AWURL, section.ID,
		)

		if err != nil {
			log.Printf("Failed to insert section %s: %v", section.Name, err)
			continue
		}
	}

	fmt.Printf("Successfully seeded %d sections\n", len(sections))
}
