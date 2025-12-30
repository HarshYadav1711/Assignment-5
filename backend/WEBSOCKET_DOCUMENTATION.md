# WebSocket Chat Implementation

## Overview

Real-time chat functionality is implemented using Django Channels with WebSocket connections. Messages are scoped per trip, authenticated via JWT, and persisted to PostgreSQL.

---

## Architecture

### Technology Stack
- **Django Channels**: WebSocket support for Django
- **Redis**: Channel layer for message broadcasting across server instances
- **JWT Authentication**: Token-based authentication for WebSocket connections
- **PostgreSQL**: Message persistence

### Connection Flow

```
Client → WebSocket Handshake → JWT Validation → Trip Access Check → Room Subscription → Active Connection
```

---

## WebSocket Endpoint

### Connection URL

```
ws://localhost:8000/ws/chat/{trip_id}/
```

**Example:**
```
ws://localhost:8000/ws/chat/550e8400-e29b-41d4-a716-446655440000/
```

### Authentication

JWT token must be provided in one of two ways:

1. **Query String** (recommended for WebSocket clients):
   ```
   ws://localhost:8000/ws/chat/{trip_id}/?token=<access_token>
   ```

2. **Authorization Header**:
   ```
   Authorization: Bearer <access_token>
   ```

---

## Message Types

### Client → Server Messages

#### 1. Send Chat Message

```json
{
  "type": "chat_message",
  "content": "Hello, team!",
  "message_type": "text",
  "reply_to": "uuid-of-message"  // Optional
}
```

**Response:** Server broadcasts to all room members (including sender)

#### 2. Edit Message

```json
{
  "type": "edit_message",
  "message_id": "uuid-of-message",
  "content": "Updated message content"
}
```

**Response:** Server broadcasts update to all room members

#### 3. Typing Indicator

```json
{
  "type": "typing",
  "is_typing": true
}
```

**Response:** Server broadcasts to other users (not sender)

---

### Server → Client Messages

#### 1. Chat Message

```json
{
  "type": "chat_message",
  "message": {
    "id": "uuid",
    "chat_room_id": "uuid",
    "sender": {
      "id": "uuid",
      "email": "user@example.com",
      "username": "johndoe",
      "full_name": "John Doe"
    },
    "content": "Hello, team!",
    "message_type": "text",
    "reply_to": {
      "id": "uuid",
      "content": "Original message...",
      "sender_email": "other@example.com"
    },
    "is_edited": false,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

#### 2. Message Edited

```json
{
  "type": "message_edited",
  "message": {
    "id": "uuid",
    "content": "Updated content",
    "is_edited": true,
    "updated_at": "2024-01-15T10:35:00Z"
  }
}
```

#### 3. Typing Indicator

```json
{
  "type": "typing",
  "user_id": "uuid",
  "user_email": "user@example.com",
  "is_typing": true
}
```

#### 4. Message History (on connect)

```json
{
  "type": "message_history",
  "messages": [
    {
      "id": "uuid",
      "sender": {...},
      "content": "Message 1",
      "created_at": "2024-01-15T10:00:00Z"
    },
    {
      "id": "uuid",
      "sender": {...},
      "content": "Message 2",
      "created_at": "2024-01-15T10:05:00Z"
    }
  ]
}
```

#### 5. Error

```json
{
  "type": "error",
  "message": "Error description"
}
```

---

## Connection States

### Successful Connection

1. Client initiates WebSocket handshake with JWT token
2. Server validates token and extracts user
3. Server checks user is collaborator of trip
4. Server creates/retrieves chat room
5. Server adds client to room group
6. Server accepts connection
7. Server sends recent message history (last 50 messages)

### Connection Rejection

**Unauthorized (4001):**
- Invalid or missing JWT token
- Token expired

**Forbidden (4003):**
- User is not a collaborator of the trip
- Trip does not exist

---

## Security Considerations

### 1. Authentication

- **JWT Token Validation**: All connections require valid JWT token
- **Token Extraction**: Supports both query string and header
- **Anonymous Rejection**: Unauthenticated connections are immediately closed

### 2. Authorization

- **Trip Access Check**: User must be a collaborator to connect
- **Message Ownership**: Only message sender can edit their messages
- **Room Isolation**: Messages are scoped to trip chat rooms

### 3. Input Validation

- **Content Length**: Maximum 10,000 characters per message
- **Empty Messages**: Rejected at consumer level
- **Message Type**: Validated against allowed types
- **Reply Validation**: Reply target must exist in same room

### 4. Rate Limiting

**Note**: Rate limiting should be implemented at:
- Application level (middleware)
- Infrastructure level (load balancer)
- Redis level (if using Redis for rate limiting)

### 5. Origin Validation

- **AllowedHostsOriginValidator**: Validates WebSocket origin
- **CORS Configuration**: Aligns with REST API CORS settings

---

## Message Persistence

### Database Storage

All messages are immediately persisted to PostgreSQL:

- **Table**: `chat_messages`
- **Indexes**: Optimized for chronological retrieval
- **Relationships**: Linked to chat room and sender
- **Soft Deletes**: Not implemented (messages deleted if user/trip deleted)

### Message History

- **On Connect**: Last 50 messages sent automatically
- **REST Fallback**: Use `/api/v1/chat/rooms/{id}/messages/` for paginated history

---

## Graceful Fallback

### When WebSocket is Unavailable

If WebSocket connections fail or are unavailable, clients should:

1. **Detect Connection Failure**
   - Monitor WebSocket connection state
   - Implement reconnection logic with exponential backoff

2. **Fallback to REST API**
   - Use `POST /api/v1/chat/messages/` to send messages
   - Use `GET /api/v1/chat/rooms/{trip_id}/messages/` to retrieve history
   - Poll for new messages if needed

3. **User Notification**
   - Display message: "Real-time chat unavailable. Using standard messaging."
   - Show connection status indicator

### Fallback Implementation Example

```javascript
// Pseudo-code for client-side fallback
class ChatClient {
  async connect(tripId, token) {
    try {
      this.ws = new WebSocket(`ws://api/ws/chat/${tripId}/?token=${token}`);
      this.ws.onopen = () => {
        this.isRealtime = true;
        this.showStatus('Connected (Real-time)');
      };
      this.ws.onerror = () => {
        this.fallbackToREST();
      };
    } catch (error) {
      this.fallbackToREST();
    }
  }
  
  fallbackToREST() {
    this.isRealtime = false;
    this.showStatus('Using standard messaging');
    // Use REST API for sending/receiving messages
  }
  
  async sendMessage(content) {
    if (this.isRealtime) {
      this.ws.send(JSON.stringify({
        type: 'chat_message',
        content: content
      }));
    } else {
      // Fallback to REST
      await fetch('/api/v1/chat/messages/', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          chat_room: this.chatRoomId,
          content: content
        })
      });
    }
  }
}
```

---

## Scalability Considerations

### Current Architecture

- **Single Server**: Works well for small to medium deployments
- **Redis Channel Layer**: Enables horizontal scaling
- **Database**: PostgreSQL handles message persistence

### Scaling Strategies

#### 1. Horizontal Scaling

**Multiple Server Instances:**
- All instances connect to same Redis channel layer
- Messages broadcast across all instances via Redis
- Load balancer distributes WebSocket connections

**Configuration:**
```python
# Each server instance uses same Redis
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            "hosts": [("redis-cluster.example.com", 6379)],
        },
    },
}
```

#### 2. Redis Clustering

**For High Traffic:**
- Use Redis Cluster for high availability
- Distributes channel groups across cluster nodes
- Automatic failover

#### 3. Database Optimization

**Read Replicas:**
- Use read replicas for message history queries
- Primary database for writes

**Connection Pooling:**
- Use PgBouncer or similar for connection pooling
- Reduces database connection overhead

#### 4. Message Queue (Future)

**For Very High Scale:**
- Consider message queue (RabbitMQ, Kafka) for message processing
- Separate message processing from WebSocket handling
- Enables better load distribution

### Performance Considerations

#### 1. Channel Layer Capacity

**Current Setting:**
```python
"capacity": 1500,  # Messages per channel
```

**Tuning:**
- Increase for high-traffic rooms
- Monitor Redis memory usage
- Adjust based on message frequency

#### 2. Message History

**Current:**
- Last 50 messages sent on connect
- Can be memory-intensive for many concurrent connections

**Optimization:**
- Reduce to 20-30 messages for high-traffic
- Use pagination for full history
- Cache recent messages in Redis

#### 3. Typing Indicators

**Current:**
- Broadcast to all room members
- Can generate high message volume

**Optimization:**
- Throttle typing indicators (max 1 per second per user)
- Use debouncing on client side
- Consider removing for very large rooms

### Monitoring

**Key Metrics to Monitor:**
- WebSocket connection count
- Message throughput (messages/second)
- Redis memory usage
- Database query performance
- Connection failure rate
- Message delivery latency

**Tools:**
- Django Channels monitoring
- Redis monitoring
- Application performance monitoring (APM)
- WebSocket connection tracking

---

## Testing

### Manual Testing

1. **Connect to WebSocket:**
   ```bash
   wscat -c "ws://localhost:8000/ws/chat/{trip_id}/?token={access_token}"
   ```

2. **Send Message:**
   ```json
   {"type": "chat_message", "content": "Hello!"}
   ```

3. **Verify:**
   - Message appears in database
   - Message broadcast to all connected clients
   - Message history sent on new connection

### Automated Testing

See `chat/tests.py` for WebSocket consumer tests.

---

## Troubleshooting

### Common Issues

1. **Connection Refused**
   - Check Redis is running
   - Verify CHANNEL_LAYERS configuration
   - Check ASGI application is properly configured

2. **Authentication Failures**
   - Verify JWT token is valid
   - Check token expiration
   - Ensure token is in query string or header

3. **Messages Not Broadcasting**
   - Check Redis connection
   - Verify room group names match
   - Check channel layer configuration

4. **High Memory Usage**
   - Monitor Redis memory
   - Reduce channel capacity
   - Implement message expiry

---

## Deployment Notes

### Production Checklist

- [ ] Redis configured and accessible
- [ ] CHANNEL_LAYERS properly configured
- [ ] ASGI application deployed (not WSGI)
- [ ] WebSocket proxy configured (nginx/uWSGI)
- [ ] JWT token validation working
- [ ] Origin validation enabled
- [ ] Rate limiting implemented
- [ ] Monitoring in place
- [ ] Fallback mechanism tested

### WebSocket Proxy Configuration (Nginx)

```nginx
location /ws/ {
    proxy_pass http://django_backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_read_timeout 86400;
}
```

---

## Summary

The WebSocket chat implementation provides:
- ✅ Real-time bidirectional communication
- ✅ JWT authentication
- ✅ Trip-scoped messaging
- ✅ Message persistence
- ✅ Graceful fallback to REST API
- ✅ Scalable architecture with Redis
- ✅ Security best practices

For production deployment, ensure proper monitoring, rate limiting, and fallback mechanisms are in place.

