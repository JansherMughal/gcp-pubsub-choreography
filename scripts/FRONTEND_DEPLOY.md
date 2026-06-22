# Frontend Deployment — GCP

Deploy the Food In UI (customer.html, restaurant.html) to Google Cloud Storage.

## Quick Start

```bash
# 1. Deploy Terraform (creates Cloud Storage bucket)
cd terraform
terraform apply
cd ..

# 2. Get the frontend URL and bucket name
cd terraform && terraform output && cd ..

# 3. Upload UI files via gsutil
chmod +x scripts/deploy-frontend.sh
./scripts/deploy-frontend.sh

# 4. Open the frontend URL in your browser
# Example: https://storage.googleapis.com/food-ordering-dev-1a2b3c4d
```

**Windows (PowerShell):**
```powershell
.\scripts\deploy-frontend.ps1
# Or just:
.\scripts\deploy-frontend.ps1
# (defaults to frontend/)
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│          Browser (Food In UI)                           │
│  customer.html, restaurant.html, js/, css/              │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ├─ Static assets ──→ Cloud Storage (public)
                       │                    gs://food-ordering-dev-...
                       │
                       └─ API calls ──→ /api/* ──→ Cloud Functions (orders-api)
                                                   https://your-region-function-url
```

### Key Features
- **Public read** — Cloud Storage bucket is publicly readable (via `allUsers` role)
- **CORS enabled** — Browsers can fetch `/api/*` endpoints from the same origin
- **Versioning** — Cloud Storage keeps old object versions for rollback
- **No caching issues** — Each deployment overwrites files, no CloudFront invalidation needed

---

## Configuration

### Update API URL in `frontend/js/config.js`

Before deploying, ensure your `config.js` points to your orders-api Cloud Function:

```javascript
const CONFIG = {
  backend: 'gcp',
  endpoints: {
    gcp: {
      api: 'https://us-central1-YOUR_PROJECT.cloudfunctions.net/orders-api',  // <-- Update this
    },
    // ...
  },
};
```

Get the URL from Terraform:
```bash
cd terraform && terraform output orders_api_url && cd ..
```

---

## Deployment Steps

### 1. Provision Cloud Storage Bucket

```bash
cd terraform
terraform apply

# See outputs:
terraform output frontend_bucket    # Bucket name
terraform output frontend_url       # Public URL
cd ..
```

### 2. Authenticate with Google Cloud

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### 3. Upload Files

**Linux/Mac:**
```bash
./scripts/deploy-frontend.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\deploy-frontend.ps1
```

The script:
- Uploads all files from `frontend/` to Cloud Storage
- Sets cache headers (1 hour for dynamic content)
- Prints the public frontend URL when done

### 4. Test the Frontend

Open the URL in a browser:
```
https://storage.googleapis.com/food-ordering-dev-XXXX
```

### 5. Place an Order

1. **Customer portal** opens at the frontend URL
2. Select a menu item from Food In
3. Click "Place Order"
4. Click the "Food In Kitchen →" button to open the restaurant portal
5. Watch events flow in both windows as the restaurant accepts and completes the order

---

## Troubleshooting

### 401 Unauthorized / Access Denied

**Problem:** `gcloud storage cp` fails with authentication error.

**Solution:**
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### Bucket name already exists

**Problem:** Deployment fails because the bucket name is globally unique and already claimed.

**Solution:** Terraform generates a random suffix for bucket uniqueness. If collision persists, try:
```bash
cd terraform && terraform destroy && terraform apply && cd ..
```

### Frontend shows "Cannot find API"

**Problem:** The customer/restaurant portals can't reach the orders-api backend.

**Solution:**
1. Open your browser's developer console (F12)
2. Look for network errors to the `/api/orders` endpoint
3. Update `frontend/js/config.js` with the correct `orders_api_url`:
   ```bash
   cd terraform && terraform output orders_api_url && cd ..
   ```
4. Re-upload:
   ```bash
   ./scripts/deploy-frontend.sh
   ```

### CORS errors (No 'Access-Control-Allow-Origin')

**Problem:** Browser blocks API requests with CORS error.

**Solution:** Cloud Storage bucket has CORS enabled in Terraform. If you still see errors:
1. Check that the CORS configuration was applied:
   ```bash
   gsutil cors get gs://food-ordering-dev-XXXX
   ```
2. If empty, re-apply Terraform:
   ```bash
   cd terraform && terraform apply && cd ..
   ```

---

## Cost Estimation

For a demo workload:

| Service          | Cost |
|---|---|
| Cloud Storage (1 GB) | ~$0.02 |
| Data transfer (egress) | Pay-as-you-go (~$0.12 / GB outside GCP) |
| **Monthly (typical)** | ~$1–5 |

To minimize costs:
- Keep the UI small (currently ~50 KB)
- Use local testing before deploying
- Delete the bucket after testing: `terraform destroy`

---

## Cleanup

Remove all resources:

```bash
cd terraform
terraform destroy
cd ..
```

This deletes:
- Cloud Storage bucket
- All uploaded files
- (Cloud Functions and other backend services remain for the orders-api)

---

## Next Steps

- **Customize the menu**: Edit `frontend/js/config.js` and add more food items
- **Change branding**: Modify `frontend/css/style.css` to change Food In colors/fonts
- **Add authentication**: Use Cloud Identity or Firebase Auth to protect the UI
- **Scale to production**: Add Cloud CDN for global distribution (if needed for latency)
