// ---------------------------------------------------------------------------
// customer.js — Customer portal: pick a dish, place order, watch it arrive.
// ---------------------------------------------------------------------------

const $ = id => document.getElementById(id);

// ---- Menu chips (single-select) -------------------------------------------

let _selectedItem = null;

function buildMenu() {
  const container = $('chip-container');
  CONFIG.menu.forEach(item => {
    const btn = document.createElement('button');
    btn.className     = 'chip';
    btn.dataset.item  = item.id;
    btn.textContent   = `${item.emoji} ${item.label}`;
    btn.type          = 'button';
    btn.addEventListener('click', () => selectChip(btn, item.label));
    container.appendChild(btn);
  });
  // Pre-select first item so the Place Order button is always ready.
  selectChip(container.firstChild, CONFIG.menu[0].label);
}

function selectChip(chipEl, label) {
  document.querySelectorAll('.chip').forEach(c => c.classList.remove('active'));
  chipEl.classList.add('active');
  _selectedItem = label;
}

// ---- Place order -----------------------------------------------------------

async function placeOrder() {
  if (!_selectedItem) { alert('Please select a menu item.'); return; }

  const btn   = $('btn-place');
  const email = $('inp-email').value.trim() || 'customer@example.com';

  btn.disabled    = true;
  btn.textContent = 'Placing…';

  try {
    const res = await fetch(`${CONFIG.api}/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        restaurant_id: CONFIG.restaurant.id,
        customer:      { email },
        items:         [_selectedItem],
      }),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}: ${await res.text()}`);
    const { order_id } = await res.json();

    setOrderIdInUrl(order_id);
    setText('order-id', order_id);
    setText('ordered-item', _selectedItem);

    // Set the restaurant portal link — user-initiated open avoids popup blocker.
    $('lnk-restaurant').href = `restaurant.html?order_id=${order_id}`;

    hideEl('place-section');
    showEl('order-section');

    resetEventLog();
    startPolling(order_id, updateCustomerUI);
  } catch (err) {
    alert('Error placing order: ' + err.message);
    btn.disabled    = false;
    btn.textContent = '🛒 Place Order';
  }
}

// ---- UI state machine ------------------------------------------------------

function updateCustomerUI(data) {
  renderStatusBadge($('status-badge'), data.status);
  appendEvents($('event-log'), data.events);

  // Show accepted state messaging
  if (data.status === 'ACCEPTED' || data.status === 'COMPLETED') {
    hideEl('waiting-msg');
    showEl('accepted-msg');
  }

  if (data.status === 'COMPLETED') {
    showEl('completed-section');
    hideEl('portal-hint-box');
  }
}

function resetAll() {
  stopPolling();
  resetEventLog();
  window.history.replaceState({}, '', window.location.pathname);
  hideEl('order-section');
  hideEl('completed-section');
  showEl('place-section');
  $('btn-place').disabled    = false;
  $('btn-place').textContent = '🛒 Place Order';
  $('event-log').innerHTML   = '';
  hideEl('accepted-msg');
  showEl('waiting-msg');
  showEl('portal-hint-box');
}

// ---- Init ------------------------------------------------------------------

document.addEventListener('DOMContentLoaded', () => {
  buildMenu();

  $('btn-place').addEventListener('click', placeOrder);
  $('btn-new-order').addEventListener('click', resetAll);

  // Resume if order_id already in URL (page refresh during active order).
  const existingId = getOrderIdFromUrl();
  if (existingId) {
    setText('order-id', existingId);
    setText('ordered-item', '…');
    $('lnk-restaurant').href = `restaurant.html?order_id=${existingId}`;
    hideEl('place-section');
    showEl('order-section');
    resetEventLog();
    startPolling(existingId, updateCustomerUI);
  }
});
