package river

import (
	"encoding/json"
	"net/http"
	"strconv"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

// ListRivers retrieves rivers
func (h *Handler) ListRivers(w http.ResponseWriter, r *http.Request) {
	params := ListRiversParams{
		State:  r.URL.Query().Get("state"),
		Search: r.URL.Query().Get("search"),
	}

	if limit := r.URL.Query().Get("limit"); limit != "" {
		if l, err := strconv.Atoi(limit); err == nil {
			params.Limit = l
		}
	}

	if offset := r.URL.Query().Get("offset"); offset != "" {
		if o, err := strconv.Atoi(offset); err == nil {
			params.Offset = o
		}
	}

	rivers, total, err := h.repo.ListRivers(params)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Error fetching rivers")
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"data": map[string]interface{}{
			"rivers": rivers,
			"total":  total,
		},
	})
}

// ListSections retrieves sections
func (h *Handler) ListSections(w http.ResponseWriter, r *http.Request) {
	params := ListSectionsParams{
		State:  r.URL.Query().Get("state"),
		Search: r.URL.Query().Get("search"),
	}

	if riverID := r.URL.Query().Get("river_id"); riverID != "" {
		if rid, err := strconv.Atoi(riverID); err == nil {
			params.RiverID = rid
		}
	}

	if limit := r.URL.Query().Get("limit"); limit != "" {
		if l, err := strconv.Atoi(limit); err == nil {
			params.Limit = l
		}
	}

	if offset := r.URL.Query().Get("offset"); offset != "" {
		if o, err := strconv.Atoi(offset); err == nil {
			params.Offset = o
		}
	}

	sections, total, err := h.repo.ListSections(params)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Error fetching sections")
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"data": map[string]interface{}{
			"sections": sections,
			"total":    total,
		},
	})
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
