# Models Design Summary

## Model Changes

### Renamed Models (Breaking Changes)

The following models have been renamed for clarity. **Migration required**:

1. **TripMember → Collaborator**
   - More descriptive name
   - Same functionality
   - Related name: `collaborators` (was `members`)

2. **PollVote → Vote**
   - Shorter, clearer name
   - Same functionality
   - Table name: `votes` (was `poll_votes`)

3. **Message → ChatMessage**
   - More specific name (avoids conflicts)
   - Same functionality
   - Related name: `chat_messages` (was `messages`)
   - Table name: `chat_messages` (was `messages`)

### Migration Path

To apply these changes:

1. **Create new models** alongside old ones
2. **Data migration**: Copy data from old to new
3. **Update code**: Change all references
4. **Remove old models**: Drop old tables

**OR** (simpler for new projects):

1. Update all code references to new names
2. Run `makemigrations`
3. Apply migrations

---

## Key Optimizations

### Indexes Added

- **Composite indexes** for common query patterns
- **Partial indexes** for filtered queries (PostgreSQL)
- **Foreign key indexes** (automatic, but documented)

### Constraints Added

- **Unique constraints**: Prevent duplicate memberships, votes, etc.
- **Check constraints**: Validate date ranges, positive orders
- **Model validation**: `clean()` methods for business rules

### Cascading Rules

- **CASCADE**: Delete children when parent deleted (ownership)
- **SET_NULL**: Preserve children, null reference (optional relationships)

---

## Read-Heavy Optimizations

1. **Indexed ordering fields**: Fast sorting
2. **Composite indexes**: Match query patterns
3. **Annotate-friendly**: Models support efficient aggregations
4. **Select_related hints**: FK relationships optimized

---

## Next Steps

1. Update serializers, views, admin to use new model names
2. Run `python manage.py makemigrations`
3. Review migration files
4. Apply migrations: `python manage.py migrate`
5. Update tests

---

## Files Requiring Updates

- `trips/serializers.py`: Update `TripMember` → `Collaborator`
- `trips/views.py`: Update references
- `trips/admin.py`: Update admin registration
- `trips/permissions.py`: Update model reference
- `polls/serializers.py`: Update `PollVote` → `Vote`
- `polls/views.py`: Update references
- `polls/admin.py`: Update admin registration
- `chat/views.py`: Update `Message` → `ChatMessage`
- `itineraries/views.py`: Update `TripMember` → `Collaborator`
- `polls/views.py`: Update `TripMember` → `Collaborator`

