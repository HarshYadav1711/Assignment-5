# API Documentation

## Base URL
```
http://localhost:8000/api/v1/
```

## Authentication

All endpoints (except registration and login) require JWT authentication.

Include the token in the Authorization header:
```
Authorization: Bearer <access_token>
```

---

## Authentication Endpoints

### Register User

**POST** `/auth/register/`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123",
  "password_confirm": "securepassword123",
  "username": "johndoe",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Response:** `201 Created`
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "johndoe",
    "profile": {
      "first_name": "John",
      "last_name": "Doe"
    },
    "date_joined": "2024-01-15T10:00:00Z"
  },
  "tokens": {
    "refresh": "refresh_token",
    "access": "access_token"
  }
}
```

**Errors:**
- `400`: Password mismatch, validation errors
- `400`: Email already exists

---

### Login

**POST** `/auth/login/`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response:** `200 OK`
```json
{
  "access": "access_token",
  "refresh": "refresh_token",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "profile": {...}
  }
}
```

**Errors:**
- `401`: Invalid credentials

---

### Refresh Token

**POST** `/auth/refresh/`

**Request:**
```json
{
  "refresh": "refresh_token"
}
```

**Response:** `200 OK`
```json
{
  "access": "new_access_token"
}
```

---

## Trip Endpoints

### List Trips

**GET** `/trips/`

Returns trips where the user is a collaborator.

**Query Parameters:**
- `page`: Page number (default: 1)
- `page_size`: Items per page (default: 20)

**Response:** `200 OK`
```json
{
  "count": 10,
  "next": "http://localhost:8000/api/v1/trips/?page=2",
  "previous": null,
  "results": [
    {
      "id": "uuid",
      "title": "Summer Vacation",
      "description": "Trip to Europe",
      "creator": {
        "id": "uuid",
        "email": "creator@example.com"
      },
      "start_date": "2024-07-01",
      "end_date": "2024-07-15",
      "status": "planned",
      "visibility": "shared",
      "collaborator_count": 3,
      "user_role": "owner",
      "created_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

---

### Create Trip

**POST** `/trips/`

**Request:**
```json
{
  "title": "Summer Vacation",
  "description": "Trip to Europe",
  "start_date": "2024-07-01",
  "end_date": "2024-07-15",
  "status": "planned",
  "visibility": "shared"
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "title": "Summer Vacation",
  "creator": {...},
  "collaborators": [
    {
      "id": "uuid",
      "user": {...},
      "role": "owner"
    }
  ],
  "created_at": "2024-01-15T10:00:00Z"
}
```

**Errors:**
- `400`: Validation errors (e.g., end_date < start_date)
- `403`: Not authenticated

---

### Get Trip Details

**GET** `/trips/{id}/`

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "title": "Summer Vacation",
  "description": "Trip to Europe",
  "creator": {...},
  "collaborators": [...],
  "collaborator_count": 3,
  "user_role": "owner",
  "start_date": "2024-07-01",
  "end_date": "2024-07-15",
  "status": "planned",
  "visibility": "shared",
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-15T10:00:00Z"
}
```

**Errors:**
- `404`: Trip not found
- `403`: Not a collaborator

---

### Update Trip

**PUT/PATCH** `/trips/{id}/`

**Request:**
```json
{
  "title": "Updated Title",
  "status": "active"
}
```

**Response:** `200 OK` (updated trip object)

**Errors:**
- `403`: Not owner/editor
- `400`: Validation errors

---

### Delete Trip

**DELETE** `/trips/{id}/`

**Response:** `204 No Content`

**Errors:**
- `403`: Not owner

---

### Invite Collaborator

**POST** `/trips/{id}/invite/`

**Request:**
```json
{
  "email": "collaborator@example.com",
  "role": "editor",
  "message": "Join us on this amazing trip!"
}
```

**Response:** `201 Created` (if user exists)
```json
{
  "id": "uuid",
  "user": {...},
  "role": "editor",
  "joined_at": "2024-01-15T10:00:00Z"
}
```

**Response:** `202 Accepted` (if user doesn't exist)
```json
{
  "detail": "Invitation sent. User will need to register to join the trip.",
  "email": "collaborator@example.com"
}
```

**Errors:**
- `400`: User already a collaborator
- `403`: Not owner/editor
- `400`: Invalid email format

---

### List Collaborators

**GET** `/trips/{id}/collaborators/`

**Response:** `200 OK`
```json
[
  {
    "id": "uuid",
    "user": {...},
    "role": "owner",
    "joined_at": "2024-01-15T10:00:00Z",
    "invited_by_user": {...}
  }
]
```

---

### Remove Collaborator

**DELETE** `/trips/{id}/collaborators/{user_id}/`

**Response:** `204 No Content`

**Errors:**
- `400`: Cannot remove last owner
- `403`: Not owner (or not removing yourself)

---

## Itinerary Endpoints

### List Itineraries

**GET** `/itineraries/?trip_id={trip_id}`

**Response:** `200 OK`
```json
[
  {
    "id": "uuid",
    "trip": "uuid",
    "date": "2024-07-01",
    "title": "Day 1: Arrival",
    "notes": "Check-in at hotel",
    "items": [...],
    "item_count": 5,
    "created_at": "2024-01-15T10:00:00Z"
  }
]
```

---

### Create Itinerary

**POST** `/itineraries/`

**Request:**
```json
{
  "trip": "uuid",
  "date": "2024-07-01",
  "title": "Day 1: Arrival",
  "notes": "Check-in at hotel"
}
```

**Response:** `201 Created`

**Errors:**
- `400`: Date outside trip date range
- `400`: Duplicate date for trip
- `403`: Not owner/editor

---

### Reorder Items

**POST** `/itineraries/{id}/items/reorder/`

**Request:**
```json
{
  "item_ids": ["uuid1", "uuid2", "uuid3"]
}
```

Items will be reordered: first ID gets order=0, second gets order=1, etc.

**Response:** `200 OK`
```json
{
  "detail": "Items reordered successfully.",
  "items": [
    {
      "id": "uuid1",
      "title": "Item 1",
      "order": 0
    },
    {
      "id": "uuid2",
      "title": "Item 2",
      "order": 1
    }
  ]
}
```

**Errors:**
- `400`: Invalid item IDs (not all belong to itinerary)
- `400`: Duplicate item IDs
- `403`: Not owner/editor

---

## Poll Endpoints

### List Polls

**GET** `/polls/?trip_id={trip_id}&is_active=true`

**Query Parameters:**
- `trip_id`: Filter by trip
- `is_active`: Filter by active status (true/false)

**Response:** `200 OK`
```json
[
  {
    "id": "uuid",
    "trip": "uuid",
    "question": "Which restaurant should we visit?",
    "description": "Help us decide!",
    "created_by": {...},
    "is_active": true,
    "closes_at": "2024-07-01T18:00:00Z",
    "options": [
      {
        "id": "uuid",
        "text": "Restaurant A",
        "order": 0,
        "vote_count": 5,
        "user_voted": false
      }
    ],
    "total_votes": 10,
    "user_has_voted": true,
    "created_at": "2024-01-15T10:00:00Z"
  }
]
```

---

### Create Poll

**POST** `/polls/`

**Request:**
```json
{
  "trip": "uuid",
  "question": "Which restaurant should we visit?",
  "description": "Help us decide!",
  "is_active": true,
  "closes_at": "2024-07-01T18:00:00Z",
  "options": [
    "Restaurant A",
    "Restaurant B",
    "Restaurant C"
  ]
}
```

**Response:** `201 Created`

**Errors:**
- `400`: Less than 2 options
- `400`: Duplicate options
- `400`: closes_at in the past
- `403`: Not owner/editor

---

### Vote

**POST** `/polls/{id}/vote/`

**Request:**
```json
{
  "option_id": "uuid"
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "poll": "uuid",
  "option": "uuid",
  "created_at": "2024-01-15T10:00:00Z"
}
```

**Errors:**
- `400`: Already voted for this option
- `400`: Poll is inactive
- `400`: Poll has closed
- `400`: Option doesn't belong to poll

---

### Remove Vote

**DELETE** `/polls/{id}/vote/`

**Request:**
```json
{
  "option_id": "uuid"
}
```

**Response:** `204 No Content`

---

### Get Poll Results

**GET** `/polls/{id}/results/`

**Response:** `200 OK`
```json
{
  "poll_id": "uuid",
  "question": "Which restaurant should we visit?",
  "total_votes": 10,
  "options": [
    {
      "id": "uuid",
      "text": "Restaurant A",
      "order": 0,
      "vote_count": 5,
      "user_voted": true
    },
    {
      "id": "uuid",
      "text": "Restaurant B",
      "order": 1,
      "vote_count": 3,
      "user_voted": false
    }
  ]
}
```

---

## Error Responses

All errors follow this format:

```json
{
  "error": {
    "code": 400,
    "message": "Human-readable error message",
    "details": {
      "field_name": ["Specific field error"]
    }
  }
}
```

### Common Status Codes

- `200 OK`: Success
- `201 Created`: Resource created
- `204 No Content`: Success (no response body)
- `400 Bad Request`: Validation error
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Permission denied
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

---

## Edge Cases Handled

### Trip Management
- ✅ Cannot remove last owner
- ✅ End date must be >= start date
- ✅ User can remove themselves
- ✅ Duplicate collaborator invitations

### Itinerary Management
- ✅ Date must be within trip date range
- ✅ Duplicate dates for same trip
- ✅ Reorder validates all items belong to itinerary
- ✅ Auto-assign order for new items

### Poll Management
- ✅ Cannot vote on inactive poll
- ✅ Cannot vote on closed poll
- ✅ Cannot vote twice for same option
- ✅ Options must be unique
- ✅ Minimum 2 options required
- ✅ closes_at cannot be in past

### Email Invitations
- ✅ Handles existing users (immediate collaboration)
- ✅ Handles new users (invitation to register)
- ✅ Prevents duplicate invitations
- ✅ Email sending errors don't fail request

---

## Swagger/OpenAPI Documentation

Interactive API documentation available at:
- **Swagger UI**: `http://localhost:8000/api/docs/`
- **ReDoc**: `http://localhost:8000/api/redoc/`
- **OpenAPI Schema**: `http://localhost:8000/api/schema/`

---

## Pagination

List endpoints support pagination:
- Default page size: 20
- Query parameters: `?page=2&page_size=50`

Response format:
```json
{
  "count": 100,
  "next": "http://localhost:8000/api/v1/endpoint/?page=3",
  "previous": "http://localhost:8000/api/v1/endpoint/?page=1",
  "results": [...]
}
```

