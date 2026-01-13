# RiverLog

A whitewater activity tracking application for logging and analyzing paddling trips.

## Features

- 🚣 Log whitewater trips with details (river, section, date, flow, difficulty)
- 📊 View and manage your paddling history
- 🔐 Secure authentication with JWT
- 📱 Clean, responsive interface

## Tech Stack

**Backend:**
- Go 1.21+
- PostgreSQL
- Chi router
- JWT authentication

**Frontend:**
- React 18
- Vite
- Tailwind CSS
- React Router

## Quick Start

### Prerequisites

- Go 1.21+
- Node.js 18+
- PostgreSQL 15+

### Installation

1. Clone the repo
```bash
git clone https://github.com/rhblitstein/riverlog.git
cd riverlog
```

2. Set up the database
```bash
createdb riverlog_dev
```

3. Start the backend
```bash
cd backend
cp .env.example .env
# Edit .env with your database credentials
go mod download
make migrate-up
make run
```

4. Start the frontend (in a new terminal)
```bash
cd frontend
npm install
npm run dev
```

5. Open http://localhost:5173

## Documentation

- [Technical Design](./docs/TECHNICAL_DESIGN.md) - Architecture and design decisions
- [API Documentation](./docs/API.md) - API endpoint specifications
- [Development Guide](./docs/DEVELOPMENT.md) - Setup and development workflow

## Development
```bash
# Backend
cd backend
make run        # Start server
make test       # Run tests
make migrate-up # Run migrations

# Frontend
cd frontend
npm run dev     # Start dev server
npm test        # Run tests
npm run build   # Build for production
```

## Project Status

🚧 **In Active Development** - MVP phase

Current focus:
- [ ] User authentication
- [ ] Trip CRUD operations
- [ ] Basic UI for trip logging and viewing

## Contributing

This is currently a personal project, but suggestions and feedback are welcome!

## License

MIT

## Author

Bec - [GitHub](https://github.com/rhblitstein)