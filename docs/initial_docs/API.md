# RiverLog API Documentation

## Base URL

Development: `http://localhost:8080/api/v1`
Production: TBD

## Authentication

All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

## Response Format

### Success Response
```json
{
  "data": { ... },
  "message": "Success message (optional)"
}
```

### Error Response
```json
{
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

## Endpoints

### Authentication

#### Register User
```
POST /auth/register
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123",
  "first_name": "Bec",
  "last_name": "Smith"
}
```

**Response:** `201 Created`
```json
{
  "data": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "Bec",
    "last_name": "Smith",
    "created_at": "2026-01-13T10:00:00Z"
  },
  "message": "User created successfully"
}
```

**Errors:**
- `400` - Invalid request body or validation error
- `409` - Email already exists

---

#### Login
```
POST /auth/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response:** `200 OK`
```json
{
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "first_name": "Bec",
      "last_name": "Smith"
    }
  }
}
```

**Errors:**
- `400` - Invalid request body
- `401` - Invalid credentials

---

#### Refresh Token
```
POST /auth/refresh
```

**Headers:**
```
Authorization: Bearer <current_token>
```

**Response:** `200 OK`
```json
{
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Errors:**
- `401` - Invalid or expired token

---

### Users

#### Get Current User
```
GET /users/me
```

**Headers:**
```
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
{
  "data": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "Bec",
    "last_name": "Smith",
    "created_at": "2026-01-13T10:00:00Z",
    "updated_at": "2026-01-13T10:00:00Z"
  }
}
```

**Errors:**
- `401` - Unauthorized

---

#### Update Current User
```
PUT /users/me
```

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "first_name": "Rebecca",
  "last_name": "Smith"
}
```

**Response:** `200 OK`
```json
{
  "data": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "Rebecca",
    "last_name": "Smith",
    "updated_at": "2026-01-13T11:00:00Z"
  }
}
```

**Errors:**
- `401` - Unauthorized
- `400` - Invalid request body

---

### Trips

#### List Trips
```
GET /trips?limit=20&offset=0
```

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional, default: 20): Number of trips to return
- `offset` (optional, default: 0): Number of trips to skip
- `sort` (optional, default: "date_desc"): Sort order. Options: `date_desc`, `date_asc`

**Response:** `200 OK`
```json
{
  "data": {
    "trips": [
        {
        "id": 1,
        "user_id": 1,
        "river_name": "Poudre River",
        "section_name": "Upper Mishawaka",
        "trip_date": "2026-05-15",
        "difficulty": "IV",
        "flow": 450,
        "flow_unit": "cfs",
        "craft_type": "kayak",
        "duration_minutes": 120,
        "mileage": 3.5,
        "notes": "Great run, perfect flow",
        "created_at": "2026-05-15T18:00:00Z",
        "updated_at": "2026-05-15T18:00:00Z"
        }
    ],
    "total": 1,
    "limit": 20,
    "offset": 0
  }
}
```

**Errors:**
- `401` - Unauthorized

---

#### Get Trip
```
GET /trips/:id
```

**Headers:**
```
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
{
  "data": {
    "id": 1,
    "user_id": 1,
    "river_name": "Poudre River",
    "section_name": "Upper Mishawaka",
    "trip_date": "2026-05-15",
    "difficulty": "IV",
    "flow": 450,
    "flow_unit": "cfs",
    "craft_type": "kayak",
    "duration_minutes": 120,
    "mileage": 3.5,
    "notes": "Great run, perfect flow",
    "created_at": "2026-05-15T18:00:00Z",
    "updated_at": "2026-05-15T18:00:00Z"
    }
}
```

**Errors:**
- `401` - Unauthorized
- `404` - Trip not found or doesn't belong to user

---

#### Create Trip
```
POST /trips
```

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "river_name": "Poudre River",
  "section_name": "Upper Mishawaka",
  "trip_date": "2026-05-15",
  "difficulty": "IV",
  "flow": 450,
  "flow_unit": "cfs",
  "craft_type": "kayak",
  "duration_minutes": 120,
  "mileage": 3.5,
  "notes": "Great run, perfect flow"
}
```

**Required Fields:**
- `river_name`
- `section_name`
- `trip_date`

**Optional Fields:**
- `difficulty`
- `flow`
- `flow_unit` (default: "cfs")
- `craft_type`
- `duration_minutes`
- `mileage`
- `notes`

**Response:** `201 Created`
```json
{
  "data": {
    "id": 1,
    "user_id": 1,
    "river_name": "Poudre River",
    "section_name": "Upper Mishawaka",
    "trip_date": "2026-05-15",
    "difficulty": "IV",
    "flow": 450,
    "flow_unit": "cfs",
    "craft_type": "kayak",
    "duration_minutes": 120,
    "mileage": 3.5,
    "notes": "Great run, perfect flow",
    "created_at": "2026-05-15T18:00:00Z",
    "updated_at": "2026-05-15T18:00:00Z"
    },
  "message": "Trip created successfully"
}
```

**Errors:**
- `401` - Unauthorized
- `400` - Invalid request body or validation error

---

#### Update Trip
```
PUT /trips/:id
```

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:** (all fields optional)
```json
{
  "river_name": "Poudre River",
  "section_name": "Upper Mishawaka to Bridges",
  "difficulty": "IV+",
  "flow_cfs": 500,
  "notes": "Updated notes"
}
```

**Response:** `200 OK`
```json
{
  "data": {
    "id": 1,
    "user_id": 1,
    "river_name": "Poudre River",
    "section_name": "Upper Mishawaka",
    "trip_date": "2026-05-15",
    "difficulty": "IV",
    "flow": 450,
    "flow_unit": "cfs",
    "craft_type": "kayak",
    "duration_minutes": 120,
    "mileage": 3.5,
    "notes": "Great run, perfect flow",
    "created_at": "2026-05-15T18:00:00Z",
    "updated_at": "2026-05-15T18:00:00Z"
  }
}
```

**Errors:**
- `401` - Unauthorized
- `404` - Trip not found or doesn't belong to user
- `400` - Invalid request body

---

#### Delete Trip
```
DELETE /trips/:id
```

**Headers:**
```
Authorization: Bearer <token>
```

**Response:** `204 No Content`

**Errors:**
- `401` - Unauthorized
- `404` - Trip not found or doesn't belong to user

---

## Error Codes

| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Request body failed validation |
| `UNAUTHORIZED` | Missing or invalid authentication token |
| `NOT_FOUND` | Resource not found |
| `DUPLICATE_EMAIL` | Email already exists in system |
| `INVALID_CREDENTIALS` | Email or password is incorrect |
| `INTERNAL_ERROR` | Server error occurred |

## Rate Limiting

Auth endpoints are rate limited to 5 requests per minute per IP address.

Other endpoints are rate limited to 100 requests per minute per authenticated user.