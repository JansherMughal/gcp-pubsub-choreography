// ---------------------------------------------------------------------------
// restaurant.js — Food In Kitchen: accept and complete incoming orders.
// ---------------------------------------------------------------------------

const $ = id => document.getElementById(id);

async function apiAction(orderId, action) {
  const btn = $(`btn-${action}`);
  btn.disabled    = true;
  btn.textContent = action === 'accept' ? 'Accepting…' : 'Completing…';

  try {
    const res = await fetch(`${CONFIG.api}/orders/${orderId}/${action}`, {
      method: 'POST',
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
    // Polling will pick up the new status automatically within 2 s.
  } catch (err) {
    alert(`Error: ${err.message}`);
    btn.disabled    = false;
    btn.textContent = action === 'accept' ? '✅ Accept Order' : '🏁 Mark as Ready';
  }
}

function updateRestaurantUI(data) {
  renderStatusBadge($('status-badge'), data.status);

  // Show ordered item from the events if not already set
  if (data.events && data.events.length) {
    const placed = data.events.find(e => e.type === 'order_placed');
    if (placed && data.items) setText('kitchen-item', data.items[0] || '—');
  }
  if (data.items && data.items.length) setText('kitchen-item', data.items[0]);

  appendEvents($('event-log'), data.events);

  // Button visibility driven by status
  hideEl('btn-accept');
  hideEl('btn-complete');

  if (data.status === 'PLACED') {
    showEl('btn-accept');
    $('btn-accept').disabled    = false;
    $('btn-accept').textContent = '✅ Accept Order';
  } else if (data.status === 'ACCEPTED') {
    showEl('btn-complete');
    $('btn-complete').disabled    = false;
    $('btn-complete').textContent = '🏁 Mark as Ready';
  } else if (CONFIG.terminalStatuses.includes(data.status)) {
    showEl('done-msg');
  }
}

// ---- Init ------------------------------------------------------------------

document.addEventListener('DOMContentLoaded', () => {
  const orderId = getOrderIdFromUrl();

  if (!orderId) {
    showEl('no-order-msg');
    return;
  }

  setText('order-id-display', orderId);
  showEl('order-section');
  hideEl('no-order-msg');

  resetEventLog();
  startPolling(orderId, (data) => {
    // Also surface order items from the DynamoDB/Firestore document.
    updateRestaurantUI(data);
  });

  $('btn-accept').addEventListener('click',   () => apiAction(orderId, 'accept'));
  $('btn-complete').addEventListener('click', () => apiAction(orderId, 'complete'));
});
