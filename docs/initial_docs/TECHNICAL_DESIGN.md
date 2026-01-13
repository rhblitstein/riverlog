# RiverLog Technical Design Document

## Overview

RiverLog is a whitewater activity tracking application that allows boaters to manually log trips and view their paddling history.

## Goals

- Provide an intuitive interface for logging whitewater trips
- Enable users to track and view their paddling history
- Serve as a portfolio piece demonstrating full-stack development capabilities

## Technology Stack

### Backend
- **Language**: Go 1.21+
- **Web Framework**: net/http with chi router
- **Database**: PostgreSQL 15+
- **Authentication**: JWT-based auth with bcrypt password hashing
- **Database Migrations**: golang-migrate

### Frontend
- **Framework**: React 18+
- **Build Tool**: Vite
- **State Management**: React Context API
- **HTTP Client**: fetch API
- **Styling**: Tailwind CSS
- **Routing**: React Router

### Infrastructure
- **Deployment**: TBD (Railway, Fly.io, or similar)
- **Database Hosting**: Managed Postgres (provider TBD)
- **Version Control**: Git/GitHub

## Architecture

### High-Level Architecture
```
┌─────────────┐         ┌──────────────┐         ┌──────────────┐
│   React     │  HTTP   │   Go API     │  SQL    │  PostgreSQL  │
│   Frontend  │ ◄─────► │   Server     │ ◄─────► │   Database   │
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
```

#### trips
```sql
CREATE TABLE trips (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    river_name VARCHAR(255) NOT NULL,
    section_name VARCHAR(255) NOT NULL,
    trip_date DATE NOT NULL,
    difficulty VARCHAR(10), -- e.g., "III", "IV+", "V"
    flow INTEGER, -- flow value (CFS or feet depending on flow_unit)
    flow_unit VARCHAR(10) DEFAULT 'cfs', -- 'cfs' or 'feet'
    craft_type VARCHAR(50), -- 'kayak', 'raft', 'packraft', 'canoe', etc.
    duration_minutes INTEGER,
    mileage DECIMAL(5,2), -- miles paddled
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trips_user_id ON trips(user_id);
CREATE INDEX idx_trips_trip_date ON trips(trip_date);
```

### Authentication Flow

1. User registers with email/password
2. Password is hashed with bcrypt (cost factor 12)
3. User logs in, receives JWT token with 24-hour expiration
4. JWT contains user ID and email in claims
5. All protected endpoints validate JWT in Authorization header
6. Refresh token endpoint allows getting new JWT without re-login

**JWT Structure:**
```json
{
    "sub": "user_id",
    "email": "user@example.com",
    "exp": 1234567890,
    "iat": 1234567890
}
```

## Development Phases

### Phase 1: MVP
- [ ] Project setup (Go modules, React with Vite)
- [ ] Database schema and migrations
- [ ] User registration and login (JWT auth)
- [ ] Basic trip CRUD operations
- [ ] Simple trip list and detail views
- [ ] Deploy to production

## Development Setup

### Prerequisites
- Go 1.21+
- Node.js 18+
- PostgreSQL 15+
- Git

### Local Development

**Backend:**
```bash
cd backend
cp .env.example .env
go mod download
make migrate-up
make run
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```

### Environment Variables

**Backend (.env):**
```
DATABASE_URL=postgres://user:pass@localhost:5432/riverlog
JWT_SECRET=your-secret-key-here
PORT=8080
```

**Frontend (.env):**
```
VITE_API_BASE_URL=http://localhost:8080
```

## Security Considerations

- All passwords hashed with bcrypt
- JWT tokens for stateless auth
- HTTPS only in production
- SQL injection prevention via parameterized queries
- Rate limiting on auth endpoints
- Input validation on all endpoints
- CORS configuration for frontend domain only

## Performance Considerations

- Database indexes on user_id and trip_date
- Pagination for trip lists
- Connection pooling for database
- Gzip compression for API responses

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-13  
**Author:** Bec