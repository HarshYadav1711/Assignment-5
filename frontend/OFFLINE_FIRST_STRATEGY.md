# Offline-First Strategy for Flutter

## Overview

The Flutter app implements an offline-first architecture that allows users to work seamlessly without network connectivity. All data is cached locally and synced with the server when connectivity is restored.

---

## Core Principles

1. **Local-First**: All operations work with local database first
2. **Optimistic Updates**: UI updates immediately, syncs in background
3. **Queue-Based Sync**: Changes queued for sync when offline
4. **Conflict Resolution**: Last-write-wins with manual override option
5. **Incremental Sync**: Only sync changes since last sync

---

## Storage Choice: Hive vs Sqflite

### Hive (Recommended)

**Pros:**
- ✅ Fast key-value storage
- ✅ No SQL queries needed
- ✅ Type-safe with code generation
- ✅ Lightweight and simple
- ✅ Good for simple data structures

**Cons:**
- ❌ Limited query capabilities
- ❌ No complex relationships
- ❌ Manual indexing

**Best For:** Simple objects, caching, preferences

### Sqflite (Alternative)

**Pros:**
- ✅ Full SQL database
- ✅ Complex queries and relationships
- ✅ Better for relational data
- ✅ ACID transactions

**Cons:**
- ❌ More complex setup
- ❌ Requires SQL knowledge
- ❌ Heavier than Hive

**Best For:** Complex relational data, advanced queries

**Decision:** Use **Hive** for simplicity and performance. Can migrate to Sqflite if complex queries are needed.

---

## Architecture

### Data Flow

```
User Action
    ↓
Repository (checks local first)
    ↓
Local Database (Hive)
    ↓
UI Updates (optimistic)
    ↓
Sync Queue (if offline)
    ↓
Background Sync (when online)
    ↓
API Sync
```

### Components

1. **Local Database**: Hive boxes for each entity type
2. **Sync Queue**: Queue of pending changes
3. **Sync Manager**: Handles sync logic and conflict resolution
4. **Repository**: Abstracts local and remote data sources

---

## Sync Strategy

### 1. Initial Sync

**When:** App first launches or after logout/login

**Process:**
```
1. Check last_sync_timestamp in local storage
2. If null or very old → Full sync
3. Request all data from API
4. Save to local database
5. Update last_sync_timestamp
```

### 2. Incremental Sync

**When:** App launches, pull-to-refresh, or periodic sync

**Process:**
```
1. Get last_sync_timestamp
2. Request changes since timestamp from API
3. Merge with local data
4. Update last_sync_timestamp
```

### 3. Push Changes

**When:** Connectivity restored or periodic check

**Process:**
```
1. Check sync queue for pending changes
2. For each change:
   a. Send to API
   b. On success: Remove from queue
   c. On conflict: Mark for resolution
3. Update local data with server responses
```

### 4. Conflict Resolution

**When:** Server has newer version than client

**Strategies:**
1. **Last-Write-Wins**: Accept server version (default)
2. **Client-Wins**: Force client version (manual override)
3. **Merge**: Manual merge by user (future enhancement)

---

## Sync Queue Structure

### Queue Entry

```dart
class SyncQueueEntry {
  final String id;              // Unique queue entry ID
  final String entityType;      // 'trip', 'itinerary', 'poll', 'message'
  final String entityId;        // Entity UUID
  final String action;          // 'create', 'update', 'delete'
  final Map<String, dynamic> data;  // Entity data
  final DateTime clientTimestamp;   // When change was made
  final SyncStatus status;      // 'pending', 'syncing', 'synced', 'conflict', 'failed'
  final int retryCount;         // Number of retry attempts
  final String? conflictId;     // Conflict ID if conflict detected
}
```

### Queue Operations

- **Add**: When local change is made
- **Process**: Background service processes queue
- **Remove**: After successful sync
- **Retry**: On failure (max 5 retries)
- **Mark Conflict**: When conflict detected

---

## Conflict Detection

### Timestamp-Based

```
Conflict detected if:
  server.updated_at > client.client_timestamp
```

### Resolution Flow

```
1. Detect conflict (server has newer version)
2. Mark queue entry as 'conflict'
3. Store both client and server versions
4. Notify user (optional notification)
5. User can choose resolution strategy
6. Apply resolution
7. Remove from queue
```

---

## Implementation Structure

```
lib/
├── core/
│   └── storage/
│       ├── local_db.dart          # Hive database setup
│       ├── sync_queue.dart       # Sync queue management
│       └── sync_manager.dart     # Sync orchestration
│
├── data/
│   └── repositories/
│       ├── trip_repository.dart   # Offline-first repository
│       └── ...
```

---

## Trade-offs

### Hive vs Sqflite

| Aspect | Hive | Sqflite |
|--------|------|---------|
| **Performance** | Faster (key-value) | Slower (SQL overhead) |
| **Complexity** | Simple | More complex |
| **Queries** | Limited | Full SQL |
| **Relationships** | Manual | Foreign keys |
| **Best For** | Simple caching | Complex data |

**Decision:** Hive for this app (simple data structures, fast access)

### Optimistic Updates

**Pros:**
- ✅ Immediate UI feedback
- ✅ Better UX
- ✅ Works offline

**Cons:**
- ❌ May need to revert on error
- ❌ More complex state management
- ❌ Potential for inconsistencies

**Decision:** Use optimistic updates (benefits outweigh costs)

### Sync Frequency

**Options:**
1. **On App Launch**: Simple, but may miss changes
2. **Periodic (every 5 min)**: Good balance
3. **Push Notifications**: Best, but requires backend support
4. **Manual Refresh**: User control

**Decision:** Combine periodic + manual refresh

### Conflict Resolution

**Options:**
1. **Last-Write-Wins**: Simple, but may lose data
2. **Manual Resolution**: Better, but requires UI
3. **Merge Strategy**: Best, but complex

**Decision:** Last-write-wins with manual override option

---

## Performance Considerations

### Local Database

- **Hive**: ~0.1ms per read, ~1ms per write
- **Indexing**: Index frequently queried fields
- **Batch Operations**: Use batch writes for multiple items

### Sync Performance

- **Batch Sync**: Sync multiple changes in one request
- **Incremental Sync**: Only sync changes since last sync
- **Background Sync**: Don't block UI

### Memory Usage

- **Pagination**: Load data in pages
- **Lazy Loading**: Load details on demand
- **Cache Limits**: Limit cached data size

---

## Error Handling

### Network Errors

- **Offline**: Queue changes, show offline indicator
- **Timeout**: Retry with exponential backoff
- **Server Error**: Mark for retry, notify user

### Sync Errors

- **Conflict**: Mark for resolution
- **Validation Error**: Reject change, notify user
- **Unknown Error**: Log, retry, or mark as failed

---

## Summary

### Key Decisions

1. **Storage**: Hive (simple, fast)
2. **Sync Strategy**: Incremental with queue-based push
3. **Conflict Resolution**: Last-write-wins with manual override
4. **Updates**: Optimistic (immediate UI feedback)
5. **Sync Frequency**: Periodic + manual refresh

### Benefits

- ✅ Works completely offline
- ✅ Fast local access
- ✅ Seamless sync when online
- ✅ Good UX with optimistic updates
- ✅ Handles conflicts gracefully

### Trade-offs Accepted

- Simplicity over complex queries (Hive vs Sqflite)
- Immediate feedback over consistency (optimistic updates)
- Last-write-wins over complex merging (conflict resolution)

This strategy provides a robust offline-first experience while maintaining simplicity and performance.

