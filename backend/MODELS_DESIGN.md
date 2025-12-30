# Django Models Design Documentation

## Overview

This document explains the design decisions, indexing strategies, constraints, and optimizations for the Smart Trip Planner Django models. The models are optimized for **read-heavy workloads** with proper data integrity enforcement.

## Table of Contents

1. [Model Relationships](#model-relationships)
2. [Indexing Strategy](#indexing-strategy)
3. [Constraints and Data Integrity](#constraints-and-data-integrity)
4. [Cascading Rules](#cascading-rules)
5. [Read-Heavy Optimizations](#read-heavy-optimizations)
6. [Migration-Safe Design](#migration-safe-design)

---

## Model Relationships

### Entity Relationship Diagram

```
User (users.User)
  ├── Trip (1:N) [as creator]
  ├── Collaborator (N:M via Collaborator)
  ├── Poll (1:N) [as created_by]
  ├── Vote (1:N)
  └── ChatMessage (1:N) [as sender]

Trip (trips.Trip)
  ├── Collaborator (1:N)
  ├── Itinerary (1:N)
  ├── Poll (1:N)
  └── ChatRoom (1:1)

Itinerary (itineraries.Itinerary)
  └── ItineraryItem (1:N)

Poll (polls.Poll)
  ├── PollOption (1:N)
  └── Vote (1:N)

ChatRoom (chat.ChatRoom)
  └── ChatMessage (1:N)
```

### Key Relationships

1. **Trip → Collaborator**: Many-to-many via join table (one user can be in many trips, one trip has many users)
2. **Trip → ChatRoom**: One-to-one (one chat room per trip)
3. **Itinerary → ItineraryItem**: One-to-many (one itinerary has many items)
4. **Poll → PollOption → Vote**: Hierarchical (poll has options, options have votes)

---

## Indexing Strategy

### Index Types Used

1. **Single-field indexes**: On frequently queried fields
2. **Composite indexes**: For multi-field queries
3. **Partial indexes**: For conditional queries (PostgreSQL feature)
4. **Foreign key indexes**: Automatic on FK fields

### Index Design Principles

1. **Query Pattern Analysis**: Indexes match actual query patterns
2. **Read vs Write Balance**: More indexes help reads, slow writes slightly
3. **Selectivity**: Index fields with high selectivity (many distinct values)
4. **Order Matters**: Composite index field order matches query WHERE/ORDER BY

### Detailed Index Breakdown

#### Trip Model

| Index Name | Fields | Purpose | Query Pattern |
|------------|--------|---------|---------------|
| `trips_creator_created_idx` | `creator, -created_at` | User's trips list | `Trip.objects.filter(creator=user).order_by('-created_at')` |
| `trips_status_date_idx` | `status, start_date` | Filter by status and date | `Trip.objects.filter(status='active', start_date__gte=date)` |
| `trips_updated_idx` | `updated_at` | Sync queries | `Trip.objects.filter(updated_at__gte=timestamp)` |
| `trips_public_listing_idx` | `visibility, status, -created_at` | Public trips listing | `Trip.objects.filter(visibility='public', status='planned')` |

**Single-field indexes:**
- `title`: For search functionality
- `creator`: FK index (automatic)
- `status`: For filtering
- `start_date`: For date range queries
- `created_at`, `updated_at`: For ordering and sync

#### Collaborator Model

| Index Name | Fields | Purpose | Query Pattern |
|------------|--------|---------|---------------|
| `collab_trip_user_idx` | `trip, user` | Membership check | `Collaborator.objects.filter(trip=trip, user=user).exists()` |
| `collab_user_joined_idx` | `user, -joined_at` | User's memberships | `Collaborator.objects.filter(user=user).order_by('-joined_at')` |
| `collab_trip_role_idx` | `trip, role` | Role-based queries | `Collaborator.objects.filter(trip=trip, role='editor')` |
| `collab_user_role_idx` | `user, role, -joined_at` | User's trips by role | `Collaborator.objects.filter(user=user, role='owner')` |

**Why these indexes:**
- Most common query: "Is user X a member of trip Y?" → `(trip, user)` index
- User dashboard: "Show my trips" → `(user, -joined_at)` index
- Permission checks: "Get all editors" → `(trip, role)` index

#### ItineraryItem Model

| Index Name | Fields | Purpose | Query Pattern |
|------------|--------|---------|---------------|
| `item_itinerary_order_idx` | `itinerary, order` | Ordered items | `ItineraryItem.objects.filter(itinerary=itinerary).order_by('order')` |
| `item_itinerary_time_idx` | `itinerary, start_time` | Time-based queries | `ItineraryItem.objects.filter(itinerary=itinerary).order_by('start_time')` |
| `item_itinerary_order_time_idx` | `itinerary, order, start_time` | Combined sorting | Flexible sorting options |

**Why order field:**
- Allows manual reordering (drag-and-drop) without changing timestamps
- More flexible than time-only ordering
- Indexed for fast retrieval

#### Poll and Vote Models

| Index Name | Fields | Purpose | Query Pattern |
|------------|--------|---------|---------------|
| `poll_trip_created_idx` | `trip, -created_at` | Trip's polls | `Poll.objects.filter(trip=trip).order_by('-created_at')` |
| `poll_trip_active_idx` | `trip, is_active, -created_at` | Active polls | `Poll.objects.filter(trip=trip, is_active=True)` |
| `vote_poll_user_idx` | `poll, user` | Has user voted? | `Vote.objects.filter(poll=poll, user=user).exists()` |
| `vote_option_idx` | `option` | Vote counting | `Vote.objects.filter(option=option).count()` |

**Partial index on active polls:**
- Only indexes active polls (smaller index, faster queries)
- PostgreSQL feature: `condition=models.Q(is_active=True)`

#### ChatMessage Model

| Index Name | Fields | Purpose | Query Pattern |
|------------|--------|---------|---------------|
| `message_room_created_idx` | `chat_room, created_at` | Chronological messages | `ChatMessage.objects.filter(chat_room=room).order_by('created_at')` |
| `message_room_created_desc_idx` | `chat_room, -created_at` | Reverse chronological | `ChatMessage.objects.filter(chat_room=room).order_by('-created_at')` |
| `message_sender_created_idx` | `sender, -created_at` | User's messages | `ChatMessage.objects.filter(sender=user).order_by('-created_at')` |

**Why both ascending and descending:**
- Different UIs may need different orderings
- Database can use appropriate index for each query

---

## Constraints and Data Integrity

### Unique Constraints

1. **Collaborator**: `(trip, user)` - One membership per user per trip
2. **Itinerary**: `(trip, date)` - One itinerary per trip per date
3. **Vote**: `(poll, option, user)` - One vote per user per option

### Check Constraints

#### Trip Model
```python
# End date must be >= start date
models.CheckConstraint(
    check=models.Q(end_date__gte=models.F('start_date')) | 
          models.Q(start_date__isnull=True) | 
          models.Q(end_date__isnull=True),
    name='trips_valid_date_range'
)
```

**Why**: Prevents invalid date ranges at database level.

#### ItineraryItem Model
```python
# End time must be >= start time
models.CheckConstraint(
    check=models.Q(end_time__gte=models.F('start_time')) | 
          models.Q(start_time__isnull=True) | 
          models.Q(end_time__isnull=True),
    name='item_valid_time_range'
)

# Order must be non-negative
models.CheckConstraint(
    check=models.Q(order__gte=0),
    name='item_positive_order'
)
```

**Why**: Ensures valid time ranges and positive ordering.

#### PollOption Model
```python
# Order must be non-negative
models.CheckConstraint(
    check=models.Q(order__gte=0),
    name='option_positive_order'
)
```

### Model-Level Validation

All models implement `clean()` method for:
- Cross-field validation (e.g., end_date >= start_date)
- Business rule enforcement (e.g., poll must be active to vote)
- Referential integrity (e.g., option must belong to poll)

**Example:**
```python
def clean(self):
    """Model-level validation."""
    super().clean()
    if self.start_date and self.end_date:
        if self.end_date < self.start_date:
            raise ValidationError({
                'end_date': 'End date must be after or equal to start date.'
            })
```

---

## Cascading Rules

### CASCADE (Delete related objects)

Used when child objects have no meaning without parent:

- **Trip → Collaborator**: If trip deleted, all memberships deleted
- **Trip → Itinerary**: If trip deleted, all itineraries deleted
- **Trip → Poll**: If trip deleted, all polls deleted
- **Itinerary → ItineraryItem**: If itinerary deleted, all items deleted
- **Poll → PollOption**: If poll deleted, all options deleted
- **PollOption → Vote**: If option deleted, all votes for that option deleted
- **ChatRoom → ChatMessage**: If room deleted, all messages deleted

### SET_NULL (Preserve with null reference)

Used when child should persist but reference can be null:

- **Collaborator.invited_by**: If inviter deleted, keep membership but null reference
- **ChatMessage.reply_to**: If replied message deleted, keep reply but null reference

### CASCADE for User Deletion

**Decision**: When user deleted, cascade delete their:
- Created trips
- Collaborations
- Created polls
- Votes
- Chat messages

**Alternative Considered**: SET_NULL to preserve data
- **Rejected**: GDPR compliance - user deletion should remove their data
- **Trade-off**: Historical data lost, but privacy preserved

---

## Read-Heavy Optimizations

### 1. Select_Related and Prefetch_Related Hints

Models are designed to work well with:
```python
# Efficient: uses indexes and reduces queries
Trip.objects.select_related('creator').prefetch_related('collaborators__user')
```

### 2. Annotate for Aggregations

Instead of property methods that hit DB:
```python
# Efficient: single query with annotation
Poll.objects.annotate(
    total_votes=Count('votes'),
    option_count=Count('options')
)
```

### 3. Indexed Ordering Fields

- `order` fields indexed for fast sorting
- Composite indexes match common ORDER BY patterns

### 4. Partial Indexes

For frequently filtered queries:
```python
# Only indexes active polls (smaller, faster)
models.Index(
    fields=['trip', 'is_active', '-created_at'],
    condition=models.Q(is_active=True)
)
```

### 5. Denormalization Considerations

**Not implemented** (kept normalized):
- Vote counts: Calculated via annotation (trade-off: accuracy vs performance)
- Last message: Queried on-demand (trade-off: consistency vs speed)

**If needed later:**
- Add `last_message_id` to ChatRoom (denormalized)
- Add `vote_count` to PollOption (denormalized, updated via signals)

### 6. Query Optimization Examples

**Inefficient:**
```python
# N+1 queries
trips = Trip.objects.all()
for trip in trips:
    members = trip.collaborators.all()  # Query per trip
```

**Efficient:**
```python
# Single query with prefetch
trips = Trip.objects.prefetch_related('collaborators__user')
for trip in trips:
    members = trip.collaborators.all()  # Uses prefetched data
```

---

## Migration-Safe Design

### 1. UUID Primary Keys

- **Why**: No conflicts when generating IDs offline
- **Migration**: Can add UUID field alongside integer, migrate data, then switch

### 2. Nullable Foreign Keys

- **invited_by**, **reply_to**: Nullable for graceful degradation
- **Migration**: Can add field as nullable, populate, then make required if needed

### 3. Default Values

- All required fields have defaults or are nullable
- **Migration**: Can add fields with defaults, no data migration needed

### 4. Index Creation Strategy

**Safe approach:**
1. Create index CONCURRENTLY (PostgreSQL)
2. Add index in separate migration
3. Monitor performance before removing old indexes

**Example migration:**
```python
# Migration 0002_add_indexes.py
operations = [
    migrations.RunSQL(
        "CREATE INDEX CONCURRENTLY trips_creator_created_idx ON trips (creator_id, created_at DESC);",
        reverse_sql="DROP INDEX IF EXISTS trips_creator_created_idx;"
    ),
]
```

### 5. Constraint Addition

**Safe approach:**
1. Add constraint as NOT VALID (PostgreSQL)
2. Validate in background
3. Make constraint valid in next migration

**Example:**
```python
migrations.RunSQL(
    "ALTER TABLE trips ADD CONSTRAINT trips_valid_date_range "
    "CHECK (end_date >= start_date OR start_date IS NULL OR end_date IS NULL) NOT VALID;",
    reverse_sql="ALTER TABLE trips DROP CONSTRAINT IF EXISTS trips_valid_date_range;"
)
migrations.RunSQL(
    "ALTER TABLE trips VALIDATE CONSTRAINT trips_valid_date_range;"
)
```

### 6. Field Renaming

**Safe approach:**
1. Add new field
2. Migrate data
3. Update code to use new field
4. Remove old field

**Example:**
```python
# Step 1: Add new field
collaborator = models.ForeignKey(..., related_name='collaborators')

# Step 2: Data migration
def migrate_members_to_collaborators(apps, schema_editor):
    # Copy data from old to new field
    pass

# Step 3: Remove old field in later migration
```

### 7. Model Renaming

**Current**: `TripMember` → `Collaborator`
**Migration path:**
1. Create `Collaborator` model
2. Migrate data from `TripMember`
3. Update all references
4. Drop `TripMember` table

---

## Performance Considerations

### Write Performance

- **Indexes slow writes**: Each index must be updated on INSERT/UPDATE
- **Trade-off**: More indexes = faster reads, slower writes
- **For this app**: Read-heavy, so more indexes are beneficial

### Index Maintenance

- **Rebuild indexes**: Periodically with `REINDEX` (PostgreSQL)
- **Monitor index usage**: `pg_stat_user_indexes` to find unused indexes
- **Partial indexes**: Smaller, faster to maintain

### Query Patterns to Optimize

1. **User dashboard**: "My trips" → `(creator, -created_at)` index
2. **Trip detail**: "Trip members" → `(trip, user)` index
3. **Chat history**: "Recent messages" → `(chat_room, -created_at)` index
4. **Poll results**: "Vote counts" → `(option)` index on Vote

---

## Summary

### Key Design Principles

1. **Index for query patterns**: Match indexes to actual queries
2. **Enforce at database level**: Constraints prevent invalid data
3. **Cascade appropriately**: CASCADE for ownership, SET_NULL for optional refs
4. **Optimize for reads**: More indexes, annotations, select_related
5. **Migration-safe**: UUIDs, nullable fields, gradual migrations

### Trade-offs Made

1. **More indexes**: Faster reads, slightly slower writes ✅ (read-heavy app)
2. **Normalized data**: Consistency over denormalization ✅ (accuracy important)
3. **CASCADE on user delete**: Privacy over history ✅ (GDPR compliance)
4. **Model validation**: Application + database level ✅ (defense in depth)

---

## Next Steps

1. **Monitor query performance**: Use Django Debug Toolbar / django-silk
2. **Add database-level triggers**: For complex business rules if needed
3. **Consider materialized views**: For complex aggregations (PostgreSQL)
4. **Add database-level functions**: For vote counting if performance becomes issue

