# RiverLog Development Guide

## Prerequisites

- Go 1.21 or higher
- Node.js 18 or higher
- PostgreSQL 15 or higher
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
# DATABASE_URL=postgres://username:password@localhost:5432/riverlog_dev
# JWT_SECRET=your-super-secret-key-change-this
# PORT=8080

# Install dependencies
go mod download

# Run migrations
make migrate-up

# Start the server
make run
```

The API will be available at `http://localhost:8080`

### 4. Frontend Setup
```bash
cd frontend

# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Edit .env if needed (default should work)
# VITE_API_BASE_URL=http://localhost:8080

# Start development server
npm run dev
```

The frontend will be available at `http://localhost:5173`

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

### Frontend Commands
```bash
# Start dev server
npm run dev

# Run tests
npm test

# Build for production
npm run build

# Preview production build
npm run preview

# Lint
npm run lint
```

## Project Structure

### Backend
```
backend/
├── cmd/api/                 # Application entry point
├── internal/
│   ├── auth/               # Authentication logic
│   ├── trip/               # Trip business logic
│   ├── user/               # User business logic
│   ├── database/           # Database connection and queries
│   └── middleware/         # HTTP middleware
├── migrations/             # Database migrations
└── Makefile               # Development commands
```

### Frontend
```
frontend/
├── src/
│   ├── components/        # Reusable components
│   ├── pages/            # Page components
│   ├── context/          # React context (auth, etc)
│   ├── api/              # API client functions
│   └── App.jsx           # Root component
└── public/               # Static assets
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

### Frontend Tests
```bash
cd frontend
npm test

# With coverage
npm test -- --coverage
```

## Code Style

### Go

- Follow standard Go conventions
- Use `gofmt` for formatting (automatically done by `make fmt`)
- Use `golangci-lint` for linting
- Write tests for all business logic

### JavaScript/React

- Use ES6+ features
- Functional components with hooks
- Prettier for formatting
- ESLint for linting

## Environment Variables

### Backend (.env)
```bash
# Database
DATABASE_URL=postgres://user:pass@localhost:5432/riverlog_dev

# JWT
JWT_SECRET=your-super-secret-key-min-32-chars

# Server
PORT=8080
ENV=development

# Optional
LOG_LEVEL=info
```

### Frontend (.env)
```bash
VITE_API_BASE_URL=http://localhost:8080
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

### CORS Issues

Ensure backend CORS middleware allows `http://localhost:5173` in development.

### JWT Token Invalid

- Ensure `JWT_SECRET` is set in backend `.env`
- Token expires after 24 hours - login again

## Git Workflow

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make changes and commit: `git commit -m "Add feature"`
3. Push to remote: `git push origin feature/your-feature`
4. Create pull request
5. After review, merge to main

## Deployment

TBD - Will add deployment instructions once we choose a platform.

## Getting Help

- Check the [Technical Design](./TECHNICAL_DESIGN.md) for architecture details
- Check the [API Documentation](./API.md) for endpoint specs
- Open an issue on GitHub