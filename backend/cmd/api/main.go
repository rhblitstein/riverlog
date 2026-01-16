package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/rhblitstein/riverlog/internal/database"
	"github.com/rhblitstein/riverlog/internal/middleware"
	"github.com/rhblitstein/riverlog/internal/river"
	"github.com/rhblitstein/riverlog/internal/trip"
	"github.com/rhblitstein/riverlog/internal/user"
)

func main() {
	// Load environment variables
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		log.Fatal("DATABASE_URL environment variable is required")
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		log.Fatal("JWT_SECRET environment variable is required")
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Initialize database
	db, err := database.New(databaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Initialize repositories
	userRepo := user.NewRepository(db.DB)
	tripRepo := trip.NewRepository(db.DB)
	riverRepo := river.NewRepository(db.DB)
	riverHandler := river.NewHandler(riverRepo)

	// Initialize handlers
	userHandler := user.NewHandler(userRepo)
	tripHandler := trip.NewHandler(tripRepo)

	// Setup router
	r := chi.NewRouter()

	// Global middleware
	r.Use(chimiddleware.Logger)
	r.Use(chimiddleware.Recoverer)
	r.Use(chimiddleware.RequestID)
	r.Use(middleware.CORS)

	// Health check
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// API routes
	r.Route("/api/v1", func(r chi.Router) {
		// Public routes
		r.Post("/auth/register", userHandler.Register)
		r.Post("/auth/login", userHandler.Login)

		r.Get("/rivers", riverHandler.ListRivers)
		r.Get("/sections", riverHandler.ListSections)

		// Protected routes
		r.Group(func(r chi.Router) {
			r.Use(middleware.RequireAuth)

			// User routes
			r.Get("/users/me", userHandler.GetMe)
			r.Put("/users/me", userHandler.UpdateMe)

			// Trip routes
			r.Get("/trips", tripHandler.List)
			r.Post("/trips", tripHandler.Create)
			r.Get("/trips/{id}", tripHandler.Get)
			r.Put("/trips/{id}", tripHandler.Update)
			r.Delete("/trips/{id}", tripHandler.Delete)
		})
	})

	// Start server
	addr := fmt.Sprintf(":%s", port)
	log.Printf("Server starting on %s", addr)
	if err := http.ListenAndServe(addr, r); err != nil {
		log.Fatal(err)
	}
}
