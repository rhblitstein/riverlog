package trip

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

// List retrieves all trips for the authenticated user
func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(int)

	// Parse query parameters
	limit := 20
	offset := 0
	sortBy := "trip_date"
	sortOrder := "desc"

	if l := r.URL.Query().Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	if o := r.URL.Query().Get("offset"); o != "" {
		if parsed, err := strconv.Atoi(o); err == nil && parsed >= 0 {
			offset = parsed
		}
	}

	if sb := r.URL.Query().Get("sort_by"); sb != "" {
		sortBy = sb
	}

	if so := r.URL.Query().Get("sort_order"); so != "" {
		sortOrder = so
	}

	trips, total, err := h.repo.List(userID, limit, offset, sortBy, sortOrder)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Error fetching trips")
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"data": map[string]interface{}{
			"trips":  trips,
			"total":  total,
			"limit":  limit,
			"offset": offset,
		},
	})
}

// Get retrieves a specific trip
func (h *Handler) Get(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(int)
	tripID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid trip ID")
		return
	}

	trip, err := h.repo.GetByID(tripID, userID)
	if err != nil {
		if err.Error() == "trip not found" {
			respondError(w, http.StatusNotFound, "Trip not found")
			return
		}
		respondError(w, http.StatusInternalServerError, "Error fetching trip")
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"data": trip,
	})
}

// Create creates a new trip
func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(int)

	var req CreateTripRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("Failed to decode request body: %v", err)
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate required fields
	if req.SectionID == 0 || req.TripDate == "" {
		log.Printf("Missing required fields: section_id=%d, trip_date=%s", req.SectionID, req.TripDate)
		respondError(w, http.StatusBadRequest, "section_id and trip_date are required")
		return
	}

	trip, err := h.repo.Create(userID, req)
	if err != nil {
		log.Printf("Failed to create trip: %v", err)
		respondError(w, http.StatusInternalServerError, "Error creating trip")
		return
	}

	respondJSON(w, http.StatusCreated, map[string]interface{}{
		"data": trip,
	})
}

// Update updates an existing trip
func (h *Handler) Update(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(int)
	tripID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid trip ID")
		return
	}

	var req UpdateTripRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	trip, err := h.repo.Update(tripID, userID, req)
	if err != nil {
		if err.Error() == "trip not found" {
			respondError(w, http.StatusNotFound, "Trip not found")
			return
		}
		respondError(w, http.StatusInternalServerError, "Error updating trip")
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"data": trip,
	})
}

// Delete deletes a trip
func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(int)
	tripID, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid trip ID")
		return
	}

	err = h.repo.Delete(tripID, userID)
	if err != nil {
		if err.Error() == "trip not found" {
			respondError(w, http.StatusNotFound, "Trip not found")
			return
		}
		respondError(w, http.StatusInternalServerError, "Error deleting trip")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// Helper functions
func respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func respondError(w http.ResponseWriter, status int, message string) {
	respondJSON(w, status, map[string]string{
		"error": message,
	})
}
