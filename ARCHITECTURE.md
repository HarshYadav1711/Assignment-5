# Smart Trip Planner - System Architecture

## Table of Contents
1. [Overview](#overview)
2. [Backend Module Structure](#backend-module-structure)
3. [Database Schema](#database-schema)
4. [API Boundaries and Responsibilities](#api-boundaries-and-responsibilities)
5. [WebSocket Flow for Chat](#websocket-flow-for-chat)
6. [Offline-First Sync Strategy](#offline-first-sync-strategy)
7. [CI/CD Pipeline Overview](#cicd-pipeline-overview)

---

## Overview

### System Components
- **Backend**: Django + Django REST Framework + PostgreSQL
- **Frontend**: Flutter with BLoC architecture
- **Real-time Communication**: WebSockets (Django Channels)
- **Authentication**: JWT (JSON Web Tokens)
- **Containerization**: Docker
- **CI/CD**: GitHub Actions

### Core Features
- User authentication and authorization
- Trip creation and management
- Collaborative trip planning
- Real-time chat for trip discussions
- Offline-first data synchronization
- Multi-user collaboration on trips

---

## Backend Module Structure

### Directory Structure
```
backend/
├── config/                    # Django project configuration
│   ├── settings/
│   │   ├── base.py           # Base settings
│   │   ├── development.py    # Development settings
│   │   ├── production.py     # Production settings
│   │   └── testing.py        # Testing settings
│   ├── urls.py               # Root URL configuration
│   ├── wsgi.py               # WSGI application
│   └── asgi.py               # ASGI application (for WebSockets)
│
├── apps/
│   ├── accounts/             # User authentication & profiles
│   │   ├── models.py         # User, Profile models
│   │   ├── serializers.py    # User serializers
│   │   ├── views.py          # Auth views (login, register, profile)
│   │   ├── permissions.py    # Custom permissions
│   │   └── urls.py           # Account endpoints
│   │
│   ├── trips/                # Core trip management
│   │   ├── models.py         # Trip, Destination, Activity models
│   │   ├── serializers.py    # Trip serializers
│   │   ├── views.py          # Trip CRUD operations
│   │   ├── permissions.py    # Trip access permissions
│   │   └── urls.py           # Trip endpoints
│   │
│   ├── chat/                 # Real-time chat functionality
│   │   ├── models.py         # Message, ChatRoom models
│   │   ├── serializers.py    # Message serializers
│   │   ├── consumers.py      # WebSocket consumers
│   │   ├── routing.py        # WebSocket routing
│   │   └── urls.py           # Chat REST endpoints (history, etc.)
│   │
│   ├── sync/                 # Offline sync management
│   │   ├── models.py         # SyncLog, ConflictResolution models
│   │   ├── serializers.py    # Sync serializers
│   │   ├── views.py          # Sync endpoints
│   │   └── sync_handler.py   # Sync logic & conflict resolution
│   │
│   └── notifications/        # Push notifications
│       ├── models.py         # Notification model
│       ├── serializers.py    # Notification serializers
│       └── views.py          # Notification endpoints
│
├── common/                   # Shared utilities
│   ├── exceptions.py         # Custom exceptions
│   ├── pagination.py         # Custom pagination
│   ├── permissions.py        # Base permissions
│   ├── mixins.py             # Reusable mixins
│   └── utils.py              # Utility functions
│
├── middleware/               # Custom middleware
│   ├── jwt_auth.py           # JWT authentication middleware
│   └── request_logging.py    # Request logging
│
├── requirements/
│   ├── base.txt              # Base dependencies
│   ├── development.txt       # Dev dependencies
│   └── production.txt        # Production dependencies
│
├── docker/
│   ├── Dockerfile            # Backend Dockerfile
│   ├── docker-compose.yml    # Local development setup
│   └── docker-compose.prod.yml  # Production setup
│
├── tests/                    # Integration tests
│   ├── test_accounts.py
│   ├── test_trips.py
│   ├── test_chat.py
│   └── test_sync.py
│
├── manage.py
└── README.md
```

### Module Responsibilities

#### `accounts/`
- **Purpose**: User authentication, registration, profile management
- **Key Responsibilities**:
  - JWT token generation and validation
  - User registration and login
  - Profile CRUD operations
  - Password reset functionality
- **Dependencies**: None (base module)

#### `trips/`
- **Purpose**: Core business logic for trip planning
- **Key Responsibilities**:
  - Trip creation, update, deletion
  - Destination and activity management
  - Trip sharing and collaboration
  - Trip visibility (public/private)
- **Dependencies**: `accounts` (for user relationships)

#### `chat/`
- **Purpose**: Real-time messaging for trip discussions
- **Key Responsibilities**:
  - WebSocket connection management
  - Message broadcasting
  - Chat history persistence
  - Room-based messaging (one chat per trip)
- **Dependencies**: `trips` (chat rooms linked to trips), `accounts` (message authors)

#### `sync/`
- **Purpose**: Handle offline-first synchronization
- **Key Responsibilities**:
  - Track client sync state
  - Handle conflict resolution
  - Manage sync queues
  - Provide sync endpoints for bulk operations
- **Dependencies**: `trips`, `chat`, `accounts` (syncs all entities)

#### `notifications/`
- **Purpose**: Push notifications for trip updates
- **Key Responsibilities**:
  - Notification creation
  - Notification delivery
  - Read/unread status tracking
- **Dependencies**: `trips`, `chat`, `accounts`

---

## Database Schema

### Entity Relationship Diagram Overview
```
User (accounts)
  ├── Profile (1:1)
  ├── Trip (1:N) [as creator]
  ├── TripMember (N:M via TripMembership)
  ├── Message (1:N)
  └── Notification (1:N)

Trip (trips)
  ├── Destination (1:N)
  ├── Activity (1:N via Destination)
  ├── ChatRoom (1:1)
  ├── TripMembership (1:N)
  └── SyncLog (1:N)

ChatRoom (chat)
  └── Message (1:N)

Destination (trips)
  └── Activity (1:N)
```

### Detailed Models

#### 1. User & Profile (accounts app)

**User** (extends Django AbstractUser)
- `id`: UUID (Primary Key)
- `email`: EmailField (unique)
- `username`: CharField (unique)
- `password`: Hashed password
- `is_active`: Boolean
- `date_joined`: DateTime
- `last_login`: DateTime

**Profile**
- `id`: UUID (Primary Key)
- `user`: OneToOneField → User
- `first_name`: CharField
- `last_name`: CharField
- `avatar`: ImageField (optional)
- `bio`: TextField (optional)
- `created_at`: DateTime
- `updated_at`: DateTime

**Design Decisions**:
- Separate Profile model for extensibility
- UUID primary keys for security and distributed systems
- ImageField for avatar (can be migrated to cloud storage later)

---

#### 2. Trip Management (trips app)

**Trip**
- `id`: UUID (Primary Key)
- `title`: CharField (max_length=200)
- `description`: TextField (optional)
- `creator`: ForeignKey → User
- `start_date`: DateField
- `end_date`: DateField
- `status`: CharField (choices: 'draft', 'planned', 'active', 'completed', 'cancelled')
- `visibility`: CharField (choices: 'private', 'shared', 'public')
- `created_at`: DateTime
- `updated_at`: DateTime
- `last_synced_at`: DateTime (for sync tracking)

**Indexes**:
- `(creator, created_at)` - User's trips
- `(status, start_date)` - Trip filtering
- `last_synced_at` - Sync queries

**TripMembership**
- `id`: UUID (Primary Key)
- `trip`: ForeignKey → Trip
- `user`: ForeignKey → User
- `role`: CharField (choices: 'owner', 'editor', 'viewer')
- `joined_at`: DateTime
- `invited_by`: ForeignKey → User (optional)

**Unique Constraint**: `(trip, user)` - One membership per user per trip

**Destination**
- `id`: UUID (Primary Key)
- `trip`: ForeignKey → Trip
- `name`: CharField (max_length=200)
- `description`: TextField (optional)
- `location`: JSONField (lat, lng, address)
- `order`: IntegerField (for ordering within trip)
- `arrival_date`: DateField
- `departure_date`: DateField
- `created_at`: DateTime
- `updated_at`: DateTime

**Indexes**:
- `(trip, order)` - Ordered destinations
- `(trip, arrival_date)` - Date-based queries

**Activity**
- `id`: UUID (Primary Key)
- `destination`: ForeignKey → Destination
- `title`: CharField (max_length=200)
- `description`: TextField (optional)
- `activity_type`: CharField (choices: 'sightseeing', 'restaurant', 'hotel', 'transport', 'other')
- `start_time`: DateTime (optional)
- `end_time`: DateTime (optional)
- `cost`: DecimalField (optional)
- `order`: IntegerField (for ordering within destination)
- `created_at`: DateTime
- `updated_at`: DateTime

**Indexes**:
- `(destination, order)` - Ordered activities
- `(destination, start_time)` - Time-based queries

**Design Decisions**:
- Separate Destination and Activity for flexibility
- JSONField for location (allows flexible location data)
- Order fields for manual sorting
- Status field for trip lifecycle management
- Membership model for fine-grained access control

---

#### 3. Chat System (chat app)

**ChatRoom**
- `id`: UUID (Primary Key)
- `trip`: OneToOneField → Trip
- `created_at`: DateTime

**Message**
- `id`: UUID (Primary Key)
- `chat_room`: ForeignKey → ChatRoom
- `sender`: ForeignKey → User
- `content`: TextField
- `message_type`: CharField (choices: 'text', 'system', 'file')
- `created_at`: DateTime
- `updated_at`: DateTime
- `is_edited`: Boolean
- `reply_to`: ForeignKey → Message (self, optional, for threading)

**Indexes**:
- `(chat_room, created_at)` - Message history queries
- `sender` - User message queries

**Design Decisions**:
- One chat room per trip (simplifies access control)
- Message types for future extensibility (files, system messages)
- Reply-to field for message threading
- Timestamps for chronological ordering

---

#### 4. Sync System (sync app)

**SyncLog**
- `id`: UUID (Primary Key)
- `user`: ForeignKey → User
- `entity_type`: CharField (choices: 'trip', 'destination', 'activity', 'message')
- `entity_id`: UUIDField
- `action`: CharField (choices: 'create', 'update', 'delete')
- `client_timestamp`: DateTime (from client)
- `server_timestamp`: DateTime (server processing time)
- `client_id`: CharField (device/session identifier)
- `data`: JSONField (snapshot of entity at sync time)
- `resolved`: Boolean (conflict resolution status)

**Indexes**:
- `(user, entity_type, server_timestamp)` - User sync queries
- `(entity_type, entity_id, server_timestamp)` - Entity history
- `(user, resolved)` - Pending conflicts

**ConflictResolution**
- `id`: UUID (Primary Key)
- `sync_log`: ForeignKey → SyncLog
- `resolution_strategy`: CharField (choices: 'server_wins', 'client_wins', 'merge', 'manual')
- `resolved_by`: ForeignKey → User
- `resolved_at`: DateTime
- `notes`: TextField (optional)

**Design Decisions**:
- Separate sync log for audit trail
- Client timestamp tracking for conflict detection
- Client ID for multi-device support
- JSONField for flexible entity snapshots
- Conflict resolution tracking for debugging

---

#### 5. Notifications (notifications app)

**Notification**
- `id`: UUID (Primary Key)
- `user`: ForeignKey → User (recipient)
- `type`: CharField (choices: 'trip_invite', 'trip_update', 'message', 'activity_reminder')
- `title`: CharField
- `message`: TextField
- `related_trip`: ForeignKey → Trip (optional)
- `related_user`: ForeignKey → User (optional, e.g., who invited)
- `is_read`: Boolean
- `created_at`: DateTime

**Indexes**:
- `(user, is_read, created_at)` - User notification queries
- `(user, type)` - Filtered notifications

**Design Decisions**:
- Generic notification model for extensibility
- Foreign keys to related entities for context
- Read status for UI state management

---

### Database Relationships Summary

**One-to-One**:
- User ↔ Profile
- Trip ↔ ChatRoom

**One-to-Many**:
- User → Trip (creator)
- User → Message
- User → Notification
- Trip → Destination
- Trip → TripMembership
- Trip → SyncLog
- Destination → Activity
- ChatRoom → Message

**Many-to-Many**:
- User ↔ Trip (via TripMembership)

---

## API Boundaries and Responsibilities

### API Structure

```
/api/v1/
├── /auth/                    # Authentication endpoints
│   ├── POST /register/       # User registration
│   ├── POST /login/          # JWT token generation
│   ├── POST /refresh/        # Token refresh
│   └── POST /logout/         # Token invalidation
│
├── /users/                   # User management
│   ├── GET /me/              # Current user profile
│   ├── PUT /me/              # Update profile
│   ├── GET /{id}/            # User details (public)
│   └── GET /search/          # User search (for invitations)
│
├── /trips/                   # Trip management
│   ├── GET /                 # List trips (filtered by user)
│   ├── POST /                # Create trip
│   ├── GET /{id}/            # Trip details
│   ├── PUT /{id}/            # Update trip
│   ├── DELETE /{id}/         # Delete trip
│   ├── POST /{id}/members/   # Add member
│   ├── DELETE /{id}/members/{user_id}/  # Remove member
│   └── GET /{id}/members/    # List members
│
├── /destinations/            # Destination management
│   ├── GET /                 # List destinations (filtered by trip)
│   ├── POST /                # Create destination
│   ├── GET /{id}/            # Destination details
│   ├── PUT /{id}/            # Update destination
│   ├── DELETE /{id}/         # Delete destination
│   └── PUT /{id}/reorder/    # Update destination order
│
├── /activities/              # Activity management
│   ├── GET /                 # List activities (filtered by destination)
│   ├── POST /                # Create activity
│   ├── GET /{id}/            # Activity details
│   ├── PUT /{id}/            # Update activity
│   ├── DELETE /{id}/         # Delete activity
│   └── PUT /{id}/reorder/    # Update activity order
│
├── /chat/                    # Chat REST endpoints
│   ├── GET /rooms/{trip_id}/messages/  # Message history
│   ├── POST /rooms/{trip_id}/messages/ # Create message (fallback)
│   └── GET /rooms/{trip_id}/           # Chat room info
│
├── /sync/                    # Offline sync endpoints
│   ├── POST /push/           # Push local changes
│   ├── GET /pull/            # Pull server changes
│   ├── GET /status/          # Sync status
│   └── POST /resolve/        # Resolve conflicts
│
└── /notifications/           # Notifications
    ├── GET /                 # List notifications
    ├── PUT /{id}/read/       # Mark as read
    └── PUT /read-all/        # Mark all as read
```

### API Responsibilities

#### Authentication API (`/auth/`)
- **Boundary**: Handles all authentication flows
- **Responsibilities**:
  - User registration with validation
  - JWT token generation (access + refresh tokens)
  - Token refresh mechanism
  - Token blacklisting on logout
- **Security**: Rate limiting, password hashing, token expiration

#### User API (`/users/`)
- **Boundary**: User profile and public user data
- **Responsibilities**:
  - Profile CRUD operations
  - Public user information retrieval
  - User search for trip invitations
- **Permissions**: Users can only edit their own profile

#### Trip API (`/trips/`)
- **Boundary**: Trip lifecycle and membership
- **Responsibilities**:
  - Trip CRUD operations
  - Membership management (add/remove members)
  - Trip filtering and search
  - Access control based on membership
- **Permissions**: 
  - Owner: Full access
  - Editor: Can modify trip content
  - Viewer: Read-only

#### Destination API (`/destinations/`)
- **Boundary**: Destination management within trips
- **Responsibilities**:
  - Destination CRUD operations
  - Order management
  - Location data handling
- **Permissions**: Requires trip membership with editor/owner role

#### Activity API (`/activities/`)
- **Boundary**: Activity management within destinations
- **Responsibilities**:
  - Activity CRUD operations
  - Order management
  - Time and cost tracking
- **Permissions**: Requires trip membership with editor/owner role

#### Chat API (`/chat/`)
- **Boundary**: Chat history and room management
- **Responsibilities**:
  - Message history retrieval (pagination)
  - Fallback message creation (if WebSocket fails)
  - Chat room metadata
- **Note**: Real-time messaging handled via WebSocket

#### Sync API (`/sync/`)
- **Boundary**: Offline synchronization
- **Responsibilities**:
  - Accept client changes (push)
  - Provide server changes (pull)
  - Conflict detection and resolution
  - Sync status reporting
- **Strategy**: Last-write-wins with conflict markers

#### Notifications API (`/notifications/`)
- **Boundary**: Notification management
- **Responsibilities**:
  - Notification retrieval
  - Read status updates
  - Notification filtering
- **Permissions**: Users can only access their own notifications

### API Design Principles

1. **RESTful Conventions**: Use standard HTTP methods and status codes
2. **Versioning**: `/api/v1/` prefix for future compatibility
3. **Pagination**: All list endpoints support pagination
4. **Filtering**: Query parameters for filtering (e.g., `?trip_id=xxx`)
5. **Error Handling**: Consistent error response format
6. **Authentication**: JWT in Authorization header
7. **Rate Limiting**: Per-user rate limits on write operations

---

## WebSocket Flow for Chat

### Architecture

**Technology**: Django Channels with Redis as channel layer

**Connection Flow**:
```
Client → WebSocket Handshake → JWT Validation → Room Subscription → Active Connection
```

### WebSocket Endpoints

```
ws://api.example.com/ws/chat/{trip_id}/
```

### Message Flow

#### 1. Connection Establishment

**Client Request**:
```json
{
  "type": "websocket.connect",
  "headers": {
    "Authorization": "Bearer <jwt_token>"
  }
}
```

**Server Validation**:
- Extract JWT from query string or headers
- Validate token and extract user
- Verify user has access to trip (TripMembership check)
- Accept or reject connection

**Server Response** (Accept):
```json
{
  "type": "websocket.accept"
}
```

**Server Response** (Reject):
```json
{
  "type": "websocket.close",
  "code": 4001  // Unauthorized
}
```

#### 2. Room Subscription

**Client Message**:
```json
{
  "type": "subscribe",
  "trip_id": "uuid"
}
```

**Server Action**:
- Add user to channel group: `chat_trip_{trip_id}`
- Send recent message history (last 50 messages)
- Broadcast user join notification to room

**Server Response**:
```json
{
  "type": "subscription_success",
  "trip_id": "uuid",
  "recent_messages": [...]
}
```

#### 3. Sending Messages

**Client Message**:
```json
{
  "type": "chat_message",
  "content": "Hello, team!",
  "trip_id": "uuid"
}
```

**Server Processing**:
1. Validate message content (non-empty, length limits)
2. Create Message record in database
3. Serialize message with sender info
4. Broadcast to channel group: `chat_trip_{trip_id}`

**Server Broadcast** (to all subscribers):
```json
{
  "type": "chat_message",
  "message": {
    "id": "uuid",
    "sender": {
      "id": "uuid",
      "username": "john_doe",
      "avatar": "url"
    },
    "content": "Hello, team!",
    "created_at": "2024-01-15T10:30:00Z",
    "is_edited": false
  }
}
```

#### 4. Message Editing

**Client Message**:
```json
{
  "type": "edit_message",
  "message_id": "uuid",
  "content": "Updated message"
}
```

**Server Processing**:
1. Verify message ownership
2. Update Message record
3. Broadcast update to room

**Server Broadcast**:
```json
{
  "type": "message_edited",
  "message_id": "uuid",
  "content": "Updated message",
  "updated_at": "2024-01-15T10:35:00Z"
}
```

#### 5. Typing Indicators

**Client Message**:
```json
{
  "type": "typing",
  "trip_id": "uuid",
  "is_typing": true
}
```

**Server Broadcast** (to others in room):
```json
{
  "type": "user_typing",
  "user_id": "uuid",
  "username": "john_doe",
  "is_typing": true
}
```

#### 6. Disconnection

**Server Action**:
- Remove user from channel group
- Broadcast user leave notification (optional)
- Clean up connection state

### WebSocket Consumer Structure

**Consumer Responsibilities**:
- Handle connection lifecycle
- Validate JWT tokens
- Manage room subscriptions
- Process message types
- Broadcast to room groups
- Handle errors gracefully

**Error Handling**:
- Invalid token → Close connection (4001)
- No trip access → Close connection (4003)
- Invalid message format → Send error message
- Database errors → Log and notify client

### Channel Layer Configuration

**Redis Channel Layer**:
- Group names: `chat_trip_{trip_id}`
- Message persistence: Messages saved to DB immediately
- Scalability: Multiple server instances can share Redis

### Design Decisions

1. **One room per trip**: Simplifies access control and room management
2. **JWT in connection**: Validates user before accepting connection
3. **Message persistence**: All messages saved to DB for history
4. **Typing indicators**: Optional feature for better UX
5. **Recent history on join**: Loads last 50 messages for context
6. **Error codes**: Standard WebSocket close codes for different errors

---

## Offline-First Sync Strategy

### Core Principles

1. **Optimistic Updates**: Client updates UI immediately
2. **Queue-Based Sync**: Local changes queued for sync
3. **Conflict Resolution**: Last-write-wins with manual override option
4. **Incremental Sync**: Only sync changes since last sync
5. **Idempotent Operations**: Sync operations can be safely retried

### Sync Architecture

#### Client-Side (Flutter)

**Local Storage**:
- SQLite database (Hive/Drift) for offline data
- Sync queue table for pending changes
- Sync metadata table (last_sync_timestamp, sync_status)

**Data Flow**:
```
User Action → Local DB Update → Sync Queue Entry → Background Sync → Server
```

#### Server-Side

**Sync Endpoints**:
- `POST /sync/push/` - Client sends local changes
- `GET /sync/pull/` - Client requests server changes
- `GET /sync/status/` - Check sync status
- `POST /sync/resolve/` - Resolve conflicts

### Sync Flow

#### 1. Initial Sync (First Launch)

**Client Request** (`GET /sync/pull/`):
```json
{
  "last_sync_timestamp": null,
  "entity_types": ["trip", "destination", "activity", "message"]
}
```

**Server Response**:
```json
{
  "sync_timestamp": "2024-01-15T10:00:00Z",
  "trips": [...],
  "destinations": [...],
  "activities": [...],
  "messages": [...],
  "deleted": {
    "trips": ["uuid1", "uuid2"],
    "destinations": ["uuid3"]
  }
}
```

**Client Action**:
- Store all data in local DB
- Update last_sync_timestamp
- Mark sync as complete

#### 2. Incremental Sync (Subsequent Syncs)

**Client Request** (`GET /sync/pull/`):
```json
{
  "last_sync_timestamp": "2024-01-15T09:00:00Z",
  "entity_types": ["trip", "destination", "activity"]
}
```

**Server Processing**:
- Query entities updated since `last_sync_timestamp`
- Return only changed entities
- Include deleted entity IDs

**Client Action**:
- Merge server changes with local data
- Resolve conflicts if any
- Update last_sync_timestamp

#### 3. Push Local Changes

**Client Request** (`POST /sync/push/`):
```json
{
  "changes": [
    {
      "entity_type": "trip",
      "entity_id": "uuid",
      "action": "update",
      "client_timestamp": "2024-01-15T10:30:00Z",
      "data": {
        "title": "Updated Trip Title",
        "description": "..."
      }
    },
    {
      "entity_type": "destination",
      "entity_id": "new-uuid",
      "action": "create",
      "client_timestamp": "2024-01-15T10:31:00Z",
      "data": {
        "name": "Paris",
        "trip_id": "uuid",
        ...
      }
    }
  ],
  "client_id": "device-uuid"
}
```

**Server Processing**:
1. For each change:
   - Check if conflict exists (entity modified since client's last sync)
   - If conflict: Mark for resolution, don't apply
   - If no conflict: Apply change, create SyncLog entry
2. Return results

**Server Response**:
```json
{
  "applied": [
    {
      "entity_type": "trip",
      "entity_id": "uuid",
      "server_timestamp": "2024-01-15T10:35:00Z"
    }
  ],
  "conflicts": [
    {
      "entity_type": "destination",
      "entity_id": "conflict-uuid",
      "client_data": {...},
      "server_data": {...},
      "conflict_id": "conflict-uuid"
    }
  ],
  "errors": []
}
```

#### 4. Conflict Resolution

**Conflict Detection**:
- Server compares `client_timestamp` with entity's `updated_at`
- If server has newer update → Conflict detected

**Resolution Strategies**:

**a) Last-Write-Wins (Automatic)**:
- Client accepts server version
- Client updates local data

**b) Client-Wins (Manual)**:
- Client sends resolution request
- Server applies client version
- Other clients will receive update on next sync

**c) Merge (Manual)**:
- User manually merges changes
- Client sends merged version
- Server applies merged version

**Client Request** (`POST /sync/resolve/`):
```json
{
  "conflict_id": "uuid",
  "resolution_strategy": "client_wins",
  "resolved_data": {...}
}
```

### Sync Queue Management

#### Client-Side Queue

**Queue Entry Structure**:
- `id`: Local UUID
- `entity_type`: String
- `entity_id`: UUID
- `action`: create/update/delete
- `data`: JSON
- `client_timestamp`: DateTime
- `status`: pending/syncing/synced/failed
- `retry_count`: Integer

**Queue Processing**:
1. Background service checks queue periodically
2. If online: Process queue in batches
3. On success: Mark as synced, remove from queue
4. On failure: Increment retry_count, exponential backoff
5. Max retries: 5, then mark as failed (user can retry manually)

### Sync Metadata

**Client Metadata**:
- `last_sync_timestamp`: Last successful sync time
- `sync_status`: idle/syncing/error
- `pending_changes_count`: Number of queued changes
- `last_sync_error`: Error message if sync failed

**Server Metadata** (per user):
- `last_sync_timestamp`: Tracked in SyncLog
- `client_ids`: List of devices that synced
- `conflict_count`: Number of unresolved conflicts

### Design Decisions

1. **Timestamp-based sync**: Efficient for incremental updates
2. **Client timestamps**: Enables conflict detection
3. **Batch operations**: Reduces API calls
4. **Queue-based**: Handles network interruptions gracefully
5. **Conflict markers**: Allows user intervention when needed
6. **Idempotent operations**: Safe to retry failed syncs
7. **Soft deletes**: Track deletions separately for sync

---

## CI/CD Pipeline Overview

### Pipeline Structure

```
GitHub Repository
    ↓
GitHub Actions Trigger (push/PR)
    ↓
┌─────────────────────────────────────┐
│ 1. Code Quality Checks              │
│    - Linting (flake8, black)        │
│    - Type checking (mypy)           │
│    - Security scanning (bandit)      │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 2. Testing                          │
│    - Unit tests                     │
│    - Integration tests              │
│    - Coverage report                │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 3. Build                            │
│    - Docker image build             │
│    - Image tagging                  │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 4. Deployment                       │
│    - Staging (on PR merge)          │
│    - Production (on tag)            │
└─────────────────────────────────────┘
```

### GitHub Actions Workflows

#### 1. Pull Request Workflow (`.github/workflows/pr.yml`)

**Triggers**:
- Pull request opened/updated
- Push to feature branches

**Steps**:
1. **Checkout Code**
2. **Set up Python**
   - Python 3.11
   - Cache pip dependencies
3. **Install Dependencies**
   - Install from requirements files
4. **Code Quality**
   - Run flake8 linting
   - Run black formatting check
   - Run mypy type checking
   - Run bandit security scan
5. **Run Tests**
   - Run pytest with coverage
   - Generate coverage report
   - Upload coverage to Codecov
6. **Build Docker Image** (test build, not pushed)
7. **Comment PR** with test results

**Artifacts**: Test reports, coverage reports

---

#### 2. Main Branch Workflow (`.github/workflows/main.yml`)

**Triggers**:
- Push to `main` branch
- Pull request merged to `main`

**Steps**:
1. **Checkout Code**
2. **Set up Python**
3. **Install Dependencies**
4. **Run Tests** (full test suite)
5. **Build Docker Image**
   - Tag: `staging-{commit_sha}`
   - Tag: `staging-latest`
6. **Push to Container Registry**
   - Docker Hub or AWS ECR
7. **Deploy to Staging**
   - Update staging environment
   - Run database migrations
   - Health check
8. **Notify** (Slack/Email on failure)

---

#### 3. Production Release Workflow (`.github/workflows/release.yml`)

**Triggers**:
- Tag pushed: `v*` (e.g., `v1.0.0`)

**Steps**:
1. **Checkout Code**
2. **Set up Python**
3. **Install Dependencies**
4. **Run Full Test Suite**
5. **Build Production Docker Image**
   - Tag: `{version}` (e.g., `1.0.0`)
   - Tag: `latest`
6. **Push to Container Registry**
7. **Deploy to Production** (manual approval required)
   - Backup database
   - Run migrations
   - Deploy new containers
   - Health check
   - Rollback on failure
8. **Create GitHub Release**
   - Release notes
   - Attach artifacts

---

### Docker Build Strategy

**Multi-stage Dockerfile**:
```dockerfile
# Stage 1: Builder
FROM python:3.11-slim as builder
# Install dependencies, compile if needed

# Stage 2: Runtime
FROM python:3.11-slim
# Copy only runtime files
# Set up non-root user
# Expose ports
```

**Build Arguments**:
- `ENVIRONMENT`: development/staging/production
- `VERSION`: Git tag or commit SHA

**Image Tags**:
- `{registry}/smart-trip-planner:{version}`
- `{registry}/smart-trip-planner:latest`
- `{registry}/smart-trip-planner:staging-{sha}`

---

### Deployment Strategy

#### Staging Environment
- **Auto-deploy**: On merge to `main`
- **Database**: Separate staging DB
- **Rollback**: Automatic on health check failure
- **Notifications**: Slack channel for deployments

#### Production Environment
- **Manual Approval**: Required before deployment
- **Database**: Production DB with backups
- **Blue-Green Deployment**: Zero-downtime deployment
- **Rollback Plan**: Automated rollback on failure
- **Monitoring**: Health checks, error tracking (Sentry)

---

### Environment Configuration

**Secrets Management** (GitHub Secrets):
- `DJANGO_SECRET_KEY`
- `DATABASE_URL`
- `REDIS_URL`
- `JWT_SECRET_KEY`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `DOCKER_REGISTRY_TOKEN`

**Environment Variables**:
- Loaded from GitHub Secrets
- Injected at deployment time
- Never committed to repository

---

### Database Migrations

**Migration Strategy**:
1. Migrations run automatically on deployment
2. Pre-deployment: Backup database
3. Run migrations in transaction (if supported)
4. Post-deployment: Verify migration success
5. Rollback: Restore backup if migration fails

**Migration Commands**:
```bash
python manage.py migrate --check  # Check for pending migrations
python manage.py migrate          # Apply migrations
```

---

### Monitoring & Alerts

**Health Checks**:
- `/health/` endpoint (basic health)
- `/health/db/` endpoint (database connectivity)
- `/health/redis/` endpoint (Redis connectivity)

**Monitoring Tools**:
- Application logs: CloudWatch/ELK
- Error tracking: Sentry
- Performance: New Relic/DataDog
- Uptime: Pingdom/UptimeRobot

**Alert Conditions**:
- Deployment failure
- Health check failure
- High error rate
- Database connection issues

---

### Design Decisions

1. **Separate workflows**: PR, main, and release for different purposes
2. **Multi-stage Docker builds**: Smaller production images
3. **Staging auto-deploy**: Catch issues before production
4. **Production manual approval**: Safety gate for critical deployments
5. **Database backups**: Before every migration
6. **Health checks**: Automatic rollback on failure
7. **Secrets management**: GitHub Secrets for security
8. **Coverage tracking**: Ensure test coverage doesn't decrease

---

## Summary

This architecture provides:

1. **Modular Backend**: Clear separation of concerns with dedicated apps
2. **Scalable Database**: Well-indexed schema with proper relationships
3. **RESTful APIs**: Clear boundaries and responsibilities
4. **Real-time Chat**: WebSocket-based with room management
5. **Offline-First**: Robust sync strategy with conflict resolution
6. **CI/CD Pipeline**: Automated testing, building, and deployment

The system is designed for:
- **Maintainability**: Clear module boundaries and documentation
- **Scalability**: Indexed database, efficient queries, horizontal scaling support
- **Reliability**: Offline support, conflict resolution, error handling
- **Security**: JWT authentication, permission checks, input validation

