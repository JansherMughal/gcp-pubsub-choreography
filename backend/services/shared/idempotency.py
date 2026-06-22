"""Idempotency guard for at-least-once delivery.

Pub/Sub may deliver the same event more than once (redelivery after a slow ack,
a crash, etc.). Handlers must therefore be safe to run twice. We record each
processed event id in a Firestore collection and use a *create-if-absent*
transaction as the claim: the first delivery wins and does the work, later
duplicates short-circuit.
"""

from __future__ import annotations

from datetime import datetime, timezone

from google.cloud import firestore

_PROCESSED = "processed_events"


def claim(db: firestore.Client, *, consumer: str, event_id: str) -> bool:
    """Atomically claim an event for a consumer.

    Returns True if this is the first time `consumer` has seen `event_id`
    (caller should process it), False if it was already handled (skip).
    """
    doc_ref = db.collection(_PROCESSED).document(f"{consumer}:{event_id}")

    @firestore.transactional
    def _txn(txn: firestore.Transaction) -> bool:
        snapshot = doc_ref.get(transaction=txn)
        if snapshot.exists:
            return False
        txn.set(
            doc_ref,
            {
                "consumer": consumer,
                "event_id": event_id,
                "processed_at": datetime.now(timezone.utc),
            },
        )
        return True

    return _txn(db.transaction())
