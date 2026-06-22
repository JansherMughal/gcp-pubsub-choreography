// ---------------------------------------------------------------------------
// shared.js — polling engine, event log, status badge.
// Loaded by both customer.html and restaurant.html.
// ---------------------------------------------------------------------------

// ---- Polling ---------------------------------------------------------------

let _pollTimer     = null;
let _knownEventIds = new Set();  // deduplicates log entries across polls

/**
 * Start polling GET /orders/{orderId} every CONFIG.pollInterval ms.
 * Calls onUpdate(data) on each successful response.
 * Stops automatically when status is terminal.
 */
function startPolling(orderId, onUpdate) {
  stopPolling();

  async function poll() {
    try {
      const res = await fetch(`${CONFIG.api}/orders/${orderId}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      onUpdate(data);
      if (CONFIG.terminalStatuses.includes(data.status)) stopPolling();
    } catch (err) {
      console.error('[poll] error:', err);
    }
  }

  poll();
  _pollTimer = setInterval(poll, CONFIG.pollInterval);
}

function stopPolling() {
  if (_pollTimer) { clearInterval(_pollTimer); _pollTimer = null; }
}

// ---- Status badge ----------------------------------------------------------

const STATUS_META = {
  PLACED:    { label: '🕐 Order Placed',               cls: 'status-placed' },
  ACCEPTED:  { label: '👨‍🍳 Kitchen is preparing…',    cls: 'status-accepted' },
  COMPLETED: { label: '✅ Ready for pickup',            cls: 'status-completed' },
  FAILED:    { label: '❌ Order failed',                cls: 'status-failed' },
};

function renderStatusBadge(el, status) {
  const m = STATUS_META[status] || { label: status, cls: '' };
  el.textContent = m.label;
  el.className   = 'status-badge ' + m.cls;
}

// ---- Event log (chronological — oldest on top, tells the story) -----------

/**
 * Append new events from the events[] array to the log container.
 * Each event rendered exactly once, keyed by event_id.
 * Appended at the BOTTOM so the log reads top→bottom like a story.
 */
function appendEvents(logEl, events) {
  if (!events || !events.length) return;

  let added = 0;
  events.forEach(evt => {
    const key = evt.event_id || (evt.type + evt.timestamp);
    if (_knownEventIds.has(key)) return;
    _knownEventIds.add(key);

    const item = document.createElement('div');
    item.className = 'event-item new-event';
    item.innerHTML = `
      <span class="evt-time">${formatTime(evt.timestamp)}</span>
      <span class="evt-type">${evt.type}</span>
      <span class="evt-source">← ${evt.source}</span>`;
    logEl.appendChild(item);   // oldest-on-top: append to bottom

    // trigger CSS enter animation
    requestAnimationFrame(() => item.classList.remove('new-event'));
    added++;
  });

  // scroll to bottom to keep newest in view
  if (added > 0) logEl.parentElement.scrollTop = logEl.parentElement.scrollHeight;
}

function resetEventLog() {
  _knownEventIds.clear();
}

// ---- Helpers ---------------------------------------------------------------

function formatTime(ts) {
  if (!ts) return '—';
  const d = typeof ts === 'number' ? new Date(ts * 1000) : new Date(ts);
  return d.toLocaleTimeString();
}

function getOrderIdFromUrl() {
  return new URLSearchParams(window.location.search).get('order_id');
}

function setOrderIdInUrl(orderId) {
  const url = new URL(window.location.href);
  url.searchParams.set('order_id', orderId);
  window.history.replaceState({}, '', url);
}

function showEl(id)      { const el = document.getElementById(id); if (el) el.hidden = false; }
function hideEl(id)      { const el = document.getElementById(id); if (el) el.hidden = true; }
function setText(id, txt){ const el = document.getElementById(id); if (el) el.textContent = txt; }
