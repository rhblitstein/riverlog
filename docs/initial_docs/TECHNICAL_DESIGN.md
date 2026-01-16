# RiverLog Technical Design Document

## Overview

RiverLog is a mobile-first whitewater activity tracking application that allows boaters to log trips and view their paddling history from their iPhone. The application consists of a native iOS app built with SwiftUI and a backend API built with Go.

## Goals

- Provide a native iOS interface for logging whitewater trips on the go
- Enable users to track and view their paddling history
- Integrate real-time data from authoritative sources (future)
- Serve as a portfolio piece demonstrating mobile and backend development capabilities

## Technology Stack

### Backend (API)
- **Language**: Go 1.21+
- **Web Framework**: net/http with chi router
- **Database**: PostgreSQL 15+
- **Authentication**: JWT-based auth with bcrypt password hashing
- **Database Migrations**: golang-migrate

### Mobile App (iOS)
- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Minimum iOS Version**: iOS 16.0+
- **Networking**: URLSession with async/await
- **Data Persistence**: Keychain for token storage

### Infrastructure
- **API Deployment**: TBD (Railway, Fly.io, or similar)
- **Database Hosting**: Managed Postgres (provider TBD)
- **Version Control**: Git/GitHub

## Architecture

### High-Level Architecture
```
┌─────────────┐         ┌──────────────┐         ┌──────────────┐
│   SwiftUI   │  HTTP   │   Go API     │  SQL    │  PostgreSQL  │
│   iOS App   │ ◄─────► │   Server     │ ◄─────► │   Database   │
└─────────────┘         └──────────────┘         └──────────────┘
```

### API Design

RESTful API following standard conventions:

**Authentication Endpoints**
- `POST /api/v1/auth/register` - Create new user account
- `POST /api/v1/auth/login` - Login and receive JWT token
- `POST /api/v1/auth/refresh` - Refresh JWT token

**Trip Endpoints**
- `GET /api/v1/trips` - List user's trips (with pagination)
- `GET /api/v1/trips/:id` - Get specific trip details
- `POST /api/v1/trips` - Create new trip
- `PUT /api/v1/trips/:id` - Update trip
- `DELETE /api/v1/trips/:id` - Delete trip

**User Endpoints**
- `GET /api/v1/users/me` - Get current user profile
- `PUT /api/v1/users/me` - Update user profile

### Database Schema

#### users
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
```

#### trips
```sql
CREATE TABLE trips (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    river_name VARCHAR(255) NOT NULL,
    section_name VARCHAR(255) NOT NULL,
    trip_date DATE NOT NULL,
    difficulty VARCHAR(10),
    flow INTEGER,
    flow_unit VARCHAR(10) DEFAULT 'cfs',
    craft_type VARCHAR(50),
    duration_minutes INTEGER,
    mileage DECIMAL(5,2),
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trips_user_id ON trips(user_id);
CREATE INDEX idx_trips_trip_date ON trips(trip_date);
```

### Authentication Flow

1. User registers with email/password via iOS app
2. Password is hashed with bcrypt (cost factor 12) on the server
3. User logs in, receives JWT token with 24-hour expiration
4. JWT is stored securely in iOS Keychain
5. All API requests include JWT in Authorization header
6. Token can be refreshed before expiration

**JWT Structure:**
```json
{
    "sub": "user_id",
    "email": "user@example.com",
    "exp": 1234567890,
    "iat": 1234567890
}
```

## iOS App Structure

### Views
- **AuthView** - Login and registration
- **TripListView** - Main view showing all logged trips with stats
- **TripDetailView** - Detailed view of a single trip
- **TripFormView** - Form for creating/editing trips
- **ProfileView** - User profile and settings

### Models
- **User** - User account information
- **Trip** - Trip data model matching API schema
- **AuthToken** - JWT token wrapper

### Services
- **APIService** - HTTP client for API communication
- **AuthService** - Authentication state management
- **KeychainService** - Secure token storage

## Development Phases

### Phase 1: MVP (Current)
- [x] Backend API with authentication
- [x] Trip CRUD operations
- [x] Database schema and migrations
- [ ] iOS app with basic UI
- [ ] Login/registration flow
- [ ] Trip list and creation

### Phase 2: Core Features
- [ ] Trip editing and deletion
- [ ] Trip detail view with all fields
- [ ] User profile management
- [ ] Better error handling and validation
- [ ] Offline support (cache trips locally)

### Phase 3: Enhanced Features
- [ ] Photo uploads for trips
- [ ] Export trip data
- [ ] Statistics and analytics
- [ ] Dark mode support
- [ ] Push notifications

### Phase 4: Advanced Features
- [ ] USGS flow integration
- [ ] River/section database
- [ ] Social features (share trips)
- [ ] Apple Watch companion app

## Development Setup

### Prerequisites
- Go 1.21+
- PostgreSQL 15+
- Xcode 15+
- iOS device or simulator (iOS 16+)
- Git

### Backend Setup
```bash
cd backend
cp .env.example .env
# Edit .env with your database credentials
go mod download
make migrate-up
make run
```

### iOS App Setup
```bash
cd ios
open RiverLog.xcodeproj
# Update API base URL in Config.swift
# Build and run on simulator or device
```

### Environment Variables

**Backend (.env):**
```
DATABASE_URL=postgres://username:password@localhost:5432/riverlog_dev?sslmode=disable
JWT_SECRET=your-super-secret-key-change-this-min-32-chars
PORT=8080
ENV=development
LOG_LEVEL=info
```

## Security Considerations

- All passwords hashed with bcrypt
- JWT tokens for stateless auth
- HTTPS only in production
- SQL injection prevention via parameterized queries
- Rate limiting on auth endpoints
- Input validation on all endpoints
- CORS configuration for development/testing
- iOS Keychain for secure token storage
- App Transport Security enabled

## Performance Considerations

- Database indexes on user_id and trip_date
- Pagination for trip lists
- Connection pooling for database
- Gzip compression for API responses
- Image optimization for trip photos (future)
- Local caching on iOS for offline viewing

---

**Document Version:** 2.0  
**Last Updated:** 2026-01-13  
**Author:** Bec