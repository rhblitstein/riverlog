# RiverLog

A native iOS whitewater activity tracking application for logging and analyzing paddling trips.

## Features

- 🚣 Native iOS app for logging trips on the go
- 📊 View paddling history and statistics
- 🔐 Secure authentication with JWT
- 📱 Clean, mobile-first interface
- 💾 Cloud storage via Go backend API

## Tech Stack

**Backend (API):**
- Go 1.21+
- PostgreSQL
- Chi router
- JWT authentication

**iOS App:**
- Swift 5.9+
- SwiftUI
- iOS 16.0+
- URLSession with async/await

## Quick Start

### Prerequisites

- Go 1.21+
- PostgreSQL 15+
- Xcode 15+
- iOS device or simulator (iOS 16+)

### Backend Setup

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

The API will be available at `http://localhost:8080`

4. Build the iOS app
```bash
cd ios
open RiverLog.xcodeproj
# Update API base URL in Config.swift if needed
# Build and run on simulator or device
```

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

# iOS App
cd ios
open RiverLog.xcodeproj
# Build and run in Xcode
```

## Project Status

🚧 **In Active Development** - MVP phase

Current focus:
- [x] Backend API with authentication
- [x] Trip CRUD operations
- [ ] iOS app UI
- [ ] Login/registration flow
- [ ] Trip list and creation

## Contributing

This is currently a personal project, but suggestions and feedback are welcome!

## License

MIT

## Author

Bec - [GitHub](https://github.com/rhblitstein)