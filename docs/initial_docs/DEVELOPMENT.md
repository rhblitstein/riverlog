# RiverLog Development Guide

## Prerequisites

- Go 1.21 or higher
- PostgreSQL 15 or higher
- Xcode 15 or higher
- iOS 16.0+ (device or simulator)
- Git

## Initial Setup

### 1. Clone the Repository
```bash
git clone https://github.com/rhblitstein/riverlog.git
cd riverlog
```

### 2. Database Setup

Create a PostgreSQL database:
```bash
createdb riverlog_dev
```

### 3. Backend Setup
```bash
cd backend

# Copy environment template
cp .env.example .env

# Edit .env with your database credentials
# DATABASE_URL=postgres://username:password@localhost:5432/riverlog_dev?sslmode=disable
# JWT_SECRET=your-super-secret-key-change-this-min-32-chars
# PORT=8080

# Install dependencies
go mod download

# Run migrations
make migrate-up

# Start the server
make run
```

The API will be available at `http://localhost:8080`

### 4. iOS App Setup
```bash
cd ios

# Open project in Xcode
open RiverLog.xcodeproj

# Update Config.swift with your API base URL
# For simulator: http://localhost:8080
# For device: http://YOUR_COMPUTER_IP:8080

# Build and run
```

## Development Workflow

### Backend Commands (Makefile)
```bash
# Run the server
make run

# Run tests
make test

# Run migrations up
make migrate-up

# Run migrations down
make migrate-down

# Create a new migration
make migrate-create name=your_migration_name

# Run linter
make lint

# Format code
make fmt
```

### iOS Development

**Running on Simulator:**
- The API URL should be `http://localhost:8080`
- Simulator can access localhost directly

**Running on Physical Device:**
- Find your computer's local IP: `ifconfig | grep inet`
- Update Config.swift to use `http://YOUR_IP:8080`
- Ensure your phone and computer are on the same network
- Backend must be running

## Project Structure

### Backend
```
backend/
├── cmd/api/                 # Application entry point
├── internal/
│   ├── auth/               # Authentication logic (JWT, password hashing)
│   ├── trip/               # Trip business logic and handlers
│   ├── user/               # User business logic and handlers
│   ├── database/           # Database connection and queries
│   └── middleware/         # HTTP middleware (auth, CORS, logging)
├── migrations/             # Database migrations
└── Makefile               # Development commands
```

### iOS App
```
ios/
├── RiverLog/
│   ├── Models/            # Data models (User, Trip, etc.)
│   ├── Views/             # SwiftUI views
│   ├── Services/          # API client, auth service, keychain
│   ├── ViewModels/        # View models for MVVM
│   └── Utils/             # Helper utilities
└── RiverLog.xcodeproj
```

## Database Migrations

Migrations are managed using `golang-migrate`.

### Creating a Migration
```bash
cd backend
make migrate-create name=add_user_preferences
```

This creates two files:
- `migrations/XXX_add_user_preferences.up.sql`
- `migrations/XXX_add_user_preferences.down.sql`

### Running Migrations
```bash
# Apply all pending migrations
make migrate-up

# Rollback last migration
make migrate-down

# Rollback all migrations
make migrate-down-all
```

## Testing

### Backend Tests
```bash
cd backend
go test ./...

# With coverage
go test -cover ./...

# Specific package
go test ./internal/auth
```

### iOS Tests

Run tests in Xcode:
- `Cmd + U` to run all tests
- Or use the Test Navigator

## Code Style

### Go

- Follow standard Go conventions
- Use `gofmt` for formatting (automatically done by `make fmt`)
- Use `golangci-lint` for linting
- Write tests for all business logic

### Swift

- Follow Swift API Design Guidelines
- Use SwiftLint for linting
- Prefer SwiftUI over UIKit
- Use async/await for networking
- MVVM architecture

## Environment Variables

### Backend (.env)
```bash
# Database
DATABASE_URL=postgres://user:pass@localhost:5432/riverlog_dev?sslmode=disable

# JWT
JWT_SECRET=your-super-secret-key-min-32-chars

# Server
PORT=8080
ENV=development

# Optional
LOG_LEVEL=info
```

## API Testing

You can test the API with curl:
```bash
# Register
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Create trip (replace TOKEN with JWT from login)
curl -X POST http://localhost:8080/api/v1/trips \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"river_name":"Colorado River","section_name":"Shoshone","trip_date":"2026-01-13"}'
```

## Common Issues

### Database Connection Fails

- Ensure PostgreSQL is running: `pg_ctl status`
- Check database exists: `psql -l | grep riverlog`
- Verify credentials in `.env`

### Migrations Fail
```bash
# Check migration status
make migrate-version

# Force version (if needed, use carefully)
make migrate-force version=XXX
```

### iOS App Can't Connect to API

**On Simulator:**
- Ensure backend is running on `localhost:8080`
- Check Console for network errors

**On Physical Device:**
- Use your computer's IP address, not localhost
- Ensure both devices are on same network
- Check firewall isn't blocking port 8080

### JWT Token Invalid

- Ensure `JWT_SECRET` is set in backend `.env`
- Token expires after 24 hours - login again
- Check token is being stored in Keychain properly

## Git Workflow

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make changes and commit: `git commit -m "Add feature"`
3. Push to remote: `git push origin feature/your-feature`
4. Create pull request
5. After review, merge to main

## Deployment

### Backend Deployment

TBD - Will add deployment instructions once we choose a platform (Railway, Fly.io, etc.)

### iOS App Distribution

- TestFlight for beta testing
- App Store for production release
- Enterprise distribution if needed

## Getting Help

- Check the [Technical Design](./TECHNICAL_DESIGN.md) for architecture details
- Check the [API Documentation](./API.md) for endpoint specs
- Open an issue on GitHub