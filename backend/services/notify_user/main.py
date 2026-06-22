"""notify-user — reacts to order_accepted.

Sends the customer their order confirmation, then announces user_notified. Like
every other function it only knows its own trigger, its own job, and the event
it emits on completion.

Flow position:
    order_accepted  --(this fn)-->  user_notified
"""

from __future__ import annotations

import functions_framework
from flask import Request
from flask.typing import ResponseReturnValue

from shared import idempotency, orders
from shared.events import Event, parse_push, publish

_CONSUMER = "notify-user"
_db = orders.client()


@functions_framework.http
def handle_push(request: Request) -> ResponseReturnValue:
    """Handle an order_accepted event pushed from Pub/Sub."""
    event, message_id = parse_push(request.get_json(force=True))

    if not idempotency.claim(_db, consumer=_CONSUMER, event_id=event.id):
        return ("duplicate ignored", 200)

    order = orders.get_order(_db, event.order_id) or {}
    customer = order.get("customer", {})

    # In production: send the confirmation email via an email provider here.
    print(f"[notify-user] emailing {customer.get('email', 'unknown')} "
          f"confirmation for order {event.order_id} (msg={message_id})")

    out_evt = Event(
        type="user_notified",
        source="notify-user",
        order_id=event.order_id,
        data={"customer_email": customer.get("email")},
    )
    orders.append_event(
        _db, event.order_id,
        event_id=out_evt.id, event_type=out_evt.type, source=out_evt.source,
    )
    publish(out_evt)
    return ("ok", 200)
