"""orders-api — the food-ordering bounded context's public surface.

Houses the article's three command functions (place / accept / complete) as
routes on one HTTP service. Each does its own small job — mutate order state —
then emits the matching domain event. It never calls notify-restaurant or
notify-user; those react to the events on their own. That is the whole point:
the orders API has no idea the rest of the flow exists.

    POST /orders                     -> create order, emit order_placed
    POST /orders/<order_id>/accept   -> mark accepted, emit order_accepted
    POST /orders/<order_id>/complete -> mark completed, emit order_completed
    GET  /orders/<order_id>          -> current status + event log (UI polling)
"""

from __future__ import annotations

import uuid

import functions_framework
from flask import Request, jsonify
from flask.typing import ResponseReturnValue

from flask import make_response

from shared import orders
from shared.events import Event, publish

_db = orders.client()


def _place_order(request: Request) -> ResponseReturnValue:
    body = request.get_json(silent=True) or {}
    order_id = body.get("order_id") or str(uuid.uuid4())

    order = orders.create_order(
        _db,
        order_id,
        {
            "customer": body.get("customer", {}),
            "restaurant_id": body.get("restaurant_id"),
            "items": body.get("items", []),
        },
    )

    evt = Event(
        type="order_placed",
        source="orders-api",
        order_id=order_id,
        data={"restaurant_id": order.get("restaurant_id")},
    )
    orders.append_event(_db, order_id, event_id=evt.id, event_type=evt.type, source=evt.source)
    publish(evt)
    response = jsonify({"order_id": order_id, "status": "PLACED"})
    response.headers["Access-Control-Allow-Origin"] = "*"
    return response, 201


def _accept_order(order_id: str) -> ResponseReturnValue:
    orders.set_status(_db, order_id, "ACCEPTED")
    evt = Event(type="order_accepted", source="orders-api", order_id=order_id, data={})
    orders.append_event(_db, order_id, event_id=evt.id, event_type=evt.type, source=evt.source)
    publish(evt)
    response = jsonify({"order_id": order_id, "status": "ACCEPTED"})
    response.headers["Access-Control-Allow-Origin"] = "*"
    return response, 200


def _complete_order(order_id: str) -> ResponseReturnValue:
    orders.set_status(_db, order_id, "COMPLETED")
    evt = Event(type="order_completed", source="orders-api", order_id=order_id, data={})
    orders.append_event(_db, order_id, event_id=evt.id, event_type=evt.type, source=evt.source)
    publish(evt)
    response = jsonify({"order_id": order_id, "status": "COMPLETED"})
    response.headers["Access-Control-Allow-Origin"] = "*"
    return response, 200


def _get_order(order_id: str) -> ResponseReturnValue:
    """Read-only status + event log — polled by the demo UI every 2 s."""
    doc = orders.get_order(_db, order_id)
    if doc is None:
        return jsonify({"error": "order not found"}), 404

    response = jsonify({
        "order_id": order_id,
        "status":   doc.get("status", "UNKNOWN"),
        "events":   doc.get("events", []),
    })
    # Allow the static UI (served on a different port) to call this endpoint.
    response.headers["Access-Control-Allow-Origin"] = "*"
    return response, 200


def _add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    return response


@functions_framework.http
def orders_api(request: Request) -> ResponseReturnValue:
    """Single HTTP entry point; dispatches by method + path segment."""
    parts = [p for p in request.path.split("/") if p]  # e.g. ["orders","123","accept"]

    if request.method == "OPTIONS":
        return _add_cors_headers(make_response("", 204)), 204

    if request.method == "POST" and parts == ["orders"]:
        return _place_order(request)

    if len(parts) == 2 and parts[0] == "orders":
        order_id = parts[1]
        if request.method == "GET":
            return _get_order(order_id)

    if request.method == "POST" and len(parts) == 3 and parts[0] == "orders":
        order_id, action = parts[1], parts[2]
        if action == "accept":
            return _accept_order(order_id)
        if action == "complete":
            return _complete_order(order_id)

    response = jsonify({"error": "not found"})
    return _add_cors_headers(response), 404
