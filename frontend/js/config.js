// ---------------------------------------------------------------------------
// config.js — GCP backend configuration
// Update API endpoint: terraform output orders_api_url (from Infrastructure/)
// ---------------------------------------------------------------------------

const CONFIG = {
  // GCP Cloud Function endpoint - get URL: terraform output -raw orders_api_url
  api: 'https://orders-api-s3v25d46tq-uc.a.run.app',  // Cloud Run URL for Gen 2 functions

  // ---------- Restaurant (single, fixed) ------------------------------------
  restaurant: {
    id:   'food-in',
    name: 'Food In',
  },

  // ---------- Menu ----------------------------------------------------------
  menu: [
    { id: 'burger',  label: 'Burger',  emoji: '🍔' },
    { id: 'pizza',   label: 'Pizza',   emoji: '🍕' },
    { id: 'pasta',   label: 'Pasta',   emoji: '🍝' },
    { id: 'salad',   label: 'Salad',   emoji: '🥗' },
    { id: 'tacos',   label: 'Tacos',   emoji: '🌮' },
    { id: 'sushi',   label: 'Sushi',   emoji: '🍣' },
  ],

  // ---------- Polling -------------------------------------------------------
  pollInterval:      2000,   // ms between polls
  terminalStatuses:  ['COMPLETED', 'CANCELLED', 'FAILED'],
};
