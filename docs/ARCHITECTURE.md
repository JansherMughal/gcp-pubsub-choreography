# Architecture

## Pattern: Event-Driven Choreography

This example demonstrates choreography - a decentralized, event-driven architecture pattern where:
- No single orchestrator controls the flow
- Each service reacts independently to events
- Services communicate via Pub/Sub topics
- The overall flow emerges from loose coupling

---

## GCP Components

### 1. Cloud Functions (Compute)
- Gen 2 - Runs on Cloud Run, scale-to-zero
- orders-api: HTTP endpoint
- notify-restaurant: Reacts to order_placed
- notify-user: Reacts to order_accepted

### 2. Pub/Sub (Messaging)
- Five topics: order_placed, restaurant_notified, order_accepted, user_notified, order_completed
- Push subscriptions with dead-letter queues
- Message ordering by order_id

### 3. Firestore (State)
- Order documents with status
- Event audit log
- Idempotency tracking

### 4. Cloud Storage (Frontend)
- Static HTML/CSS/JS
- Public read access
- Versioning for rollback

### 5. Service Accounts (IAM)
- Per-function least-privilege
- Each publishes only to owned topics

---

## Key Patterns

1. **Idempotency**: Each handler tracks processed event IDs
2. **Dead-Letter Queues**: Failed events sent to DLQ topics
3. **Ordering Keys**: Events keyed by order_id for sequencing
4. **Thin Events**: Events carry minimal data; state in DB
5. **Least-Privilege**: IAM enforces event contracts

---

## Scaling

- Compute: Auto-scale 0 to thousands
- Messaging: Millions of messages/sec
- State: Firestore auto-scaling
- Frontend: Cloud Storage + CDN ready

---

See README.md for deployment instructions.
