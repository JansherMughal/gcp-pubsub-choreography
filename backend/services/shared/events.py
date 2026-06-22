"""Event envelope: the shared contract every service speaks.

In choreography no service knows who consumes its events, so the *shape* of an
event is the only coupling that exists. Keeping that shape in one place — and
keeping the payload deliberately thin (an id and references, not the whole
order) — is what lets bounded contexts evolve independently.
"""

from __future__ import annotations

import base64
import json
import os
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

from google.cloud import pubsub_v1

_publisher: pubsub_v1.PublisherClient | None = None


def _client() -> pubsub_v1.PublisherClient:
    """Lazily create a single publisher (ordering enabled) per instance."""
    global _publisher
    if _publisher is None:
        _publisher = pubsub_v1.PublisherClient(
            publisher_options=pubsub_v1.types.PublisherOptions(enable_message_ordering=True)
        )
    return _publisher


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


@dataclass(frozen=True)
class Event:
    """A domain event. `data` carries references (order_id, ...), not full state."""

    type: str
    source: str
    data: dict[str, Any]
    order_id: str
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    time: str = field(default_factory=_now_iso)

    def to_json(self) -> bytes:
        return json.dumps(
            {
                "id": self.id,
                "type": self.type,
                "source": self.source,
                "time": self.time,
                "order_id": self.order_id,
                "data": self.data,
            }
        ).encode("utf-8")


def publish(event: Event, *, topic: str | None = None) -> str:
    """Publish an event to its topic, keyed by order_id to preserve per-order order.

    `topic` defaults to the event type with underscores swapped for dashes
    (order_placed -> order-placed), matching the Terraform topic names.
    """
    project = os.environ["GCP_PROJECT"]
    topic_name = topic or event.type.replace("_", "-")
    topic_path = _client().topic_path(project, topic_name)

    future = _client().publish(
        topic_path,
        event.to_json(),
        # Ordering key: every event for one order is delivered in sequence, so a
        # consumer never sees order_completed before order_accepted.
        ordering_key=event.order_id,
        # Attributes are cheap to filter on without decoding the body.
        event_type=event.type,
        event_id=event.id,
        source=event.source,
    )
    return future.result()


def parse_push(request_json: dict[str, Any]) -> tuple[Event, str]:
    """Decode a Pub/Sub push request into (Event, message_id).

    Push envelope shape:
        {"message": {"data": <base64>, "attributes": {...}, "messageId": "..."}}
    """
    message = request_json["message"]
    message_id = message.get("messageId", "")
    payload = json.loads(base64.b64decode(message["data"]).decode("utf-8"))

    event = Event(
        id=payload["id"],
        type=payload["type"],
        source=payload["source"],
        time=payload["time"],
        order_id=payload["order_id"],
        data=payload["data"],
    )
    return event, message_id
