"""Order state access — Firestore is the system of record.

Events announce *that* state changed; the authoritative order document lives
here. Consumers look up details by order_id rather than trusting a fat event
payload, which keeps event contracts small and stable.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from google.cloud import firestore

_ORDERS = "orders"


def client() -> firestore.Client:
    return firestore.Client()


def create_order(db: firestore.Client, order_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    doc = {
        "order_id": order_id,
        "status": "PLACED",
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
        **payload,
    }
    db.collection(_ORDERS).document(order_id).set(doc)
    return doc


def set_status(db: firestore.Client, order_id: str, status: str) -> None:
    db.collection(_ORDERS).document(order_id).update(
        {"status": status, "updated_at": datetime.now(timezone.utc)}
    )


def append_event(
    db: firestore.Client,
    order_id: str,
    *,
    event_id: str,
    event_type: str,
    source: str,
) -> None:
    """Append a domain event entry to the order's event log.

    The UI polls GET /orders/{id} and renders this list as the choreography
    event log — making the otherwise invisible event bus visible in the demo.
    """
    db.collection(_ORDERS).document(order_id).update({
        "events": firestore.ArrayUnion([{
            "event_id":  event_id,
            "type":      event_type,
            "source":    source,
            "timestamp": int(datetime.now(timezone.utc).timestamp()),
        }])
    })


def get_order(db: firestore.Client, order_id: str) -> dict[str, Any] | None:
    snapshot = db.collection(_ORDERS).document(order_id).get()
    return snapshot.to_dict() if snapshot.exists else None
