package trip

import (
	"encoding/json"
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

	// Parse query params
	limitStr := r.URL.Query().Get("limit")
	offsetStr := r.URL.Query().Get("offset")
	sort := r.URL.Query().Get("sort")

	limit := 20
	if limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			limit = l
		}
	}

	offset := 0
	if offsetStr != "" {
		if o, err := strconv.Atoi(offsetStr); err == nil {
			offset = o
		}
	}

	if sort == "" {
		sort = "date_desc"
	}

	params := ListTripsParams{
		Limit:  limit,
		Offset: offset,
		Sort:   sort,
	}

	trips, total, err := h.repo.List(userID, params)
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
	tripIDStr := chi.URLParam(r, "id")

	tripID, err := strconv.Atoi(tripIDStr)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid trip ID")
		return
	}

	trip, err := h.repo.GetByID(userID, tripID)
	if err != nil {
		if err == ErrTripNotFound {
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
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate required fields
	if req.RiverName == "" || req.SectionName == "" || req.TripDate == "" {
		respondError(w, http.StatusBadRequest, "River name, section name, and trip date are required")
		return
	}

	trip, err := h.repo.Create(userID, req)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Error creating trip")
		return
	}

	respondJSON(w, http.StatusCreated, map[string]interface{}{
		"data":    trip,
		"message": "Trip created successfully",
	})
}

// Update updates an existing trip
func (h *Handler) Update(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(int)
	tripIDStr := chi.URLParam(r, "id")

	tripID, err := strconv.Atoi(tripIDStr)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid trip ID")
		return
	}

	var req UpdateTripRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	trip, err := h.repo.Update(userID, tripID, req)
	if err != nil {
		if err == ErrTripNotFound {
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
	tripIDStr := chi.URLParam(r, "id")

	tripID, err := strconv.Atoi(tripIDStr)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid trip ID")
		return
	}

	err = h.repo.Delete(userID, tripID)
	if err != nil {
		if err == ErrTripNotFound {
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
