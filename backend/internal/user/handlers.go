package user

import (
	"encoding/json"
	"net/http"
	"os"

	"github.com/rhblitstein/riverlog/internal/auth"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

// Register handles user registration
func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate input
	if req.Email == "" || req.Password == "" {
		respondError(w, http.StatusBadRequest, "Email and password are required")
		return
	}

	// Hash password
	passwordHash, err := auth.HashPassword(req.Password)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Error processing password")
		return
	}

	// Create user
	user, err := h.repo.Create(req.Email, passwordHash, req.FirstName, req.LastName)
	if err != nil {
		if err == ErrDuplicateEmail {
			respondError(w, http.StatusConflict, "Email already exists")
			return
		}
		respondError(w, http.StatusInternalServerError, "Error creating user")
		return
	}

	respondJSON(w, http.StatusCreated, map[string]interface{}{
		"data":    user,
		"message": "User created successfully",
	})
}

// Login handles user login
func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Get user by email
	user, err := h.repo.GetByEmail(req.Email)
	if err != nil {
		if err == ErrUserNotFound {
			respondError(w, http.StatusUnauthorized, "Invalid credentials")
			return
		}
		respondError(w, http.StatusInternalServerError, "Error fetching user")
		return
	}

	// Check password
	if !auth.CheckPassword(req.Password, user.PasswordHash) {
		respondError(w, http.StatusUnauthorized, "Invalid credentials")
		return
	}

	// Generate JWT token
	jwtSecret := os.Getenv("JWT_SECRET")
	token, err := auth.GenerateToken(user.ID, user.Email, jwtSecret)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Error generating token")
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"data": LoginResponse{
			Token: token,
			User:  *user,
		},
	})
}

// GetMe retrieves the current user's profile
func (h *Handler) GetMe(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(int)

	user, err := h.repo.GetByID(userID)
	if err != nil {
		respondError(w, http.StatusNotFound, "User not found")
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"data": user,
	})
}

// UpdateMe updates the current user's profile
func (h *Handler) UpdateMe(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("userID").(int)

	var req UpdateUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	user, err := h.repo.Update(userID, req.FirstName, req.LastName)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Error updating user")
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"data": user,
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
