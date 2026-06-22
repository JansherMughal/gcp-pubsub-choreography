# GCP Pub/Sub Choreography Example

A production-ready reference implementation of **Event-Driven Choreography** on Google Cloud Platform.

**No central orchestrator.** Each Cloud Function reacts independently to Pub/Sub events, performs its job, and publishes the next event. The complete order flow emerges from loosely-coupled, autonomous services.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Python 3.12](https://img.shields.io/badge/Python-3.12-blue)
![Terraform](https://img.shields.io/badge/Terraform-1.6+-purple)
![GCP](https://img.shields.io/badge/GCP-Cloud%20Functions%202-red)

## The flow

```
Customer     ─── POST /orders ───────────────► ┌────────────┐   order_placed
                                               │            │ ─────────────────► [order-placed] ───► notify-restaurant
Restaurant   ─── POST /orders/{id}/accept ───► │            │                                              │
                                               │            │   order_accepted                             ▼
                                               │ orders-api │ ─────────────────► [order-accepted] ─► notify-user [restaurant-notified]
Restaurant   ─── POST /orders/{id}/complete ─► │            │                                              │
                                               └────────────┘   order_completed                            ▼
                                                      │ ───────────────────────► [order-completed]  [user-notified]
                                                      │
                                                      └─► (promo-code service, data lake, etc. subscribe here later)
```

Five events, one Pub/Sub **topic per event** — the topic name *is* the contract:

`order_placed` · `restaurant_notified` · `order_accepted` · `user_notified` · `order_completed`

## GCP Architecture

- **Compute:** Cloud Functions (gen2, runs on Cloud Run)
- **Messaging:** Pub/Sub (one topic per event type)
- **Push delivery:** Pub/Sub push subscriptions with dead-letter queues
- **State:** Firestore (order state + idempotency tracking)
- **API:** Cloud Function handling HTTP requests
- **Frontend:** Cloud Storage (static HTML/JS/CSS)

## Layout

```
gcp-pubsub-choreography/
├── README.md                 # This file
├── LICENSE                   # MIT License
├── CHANGELOG.md              # Version history
├── CONTRIBUTING.md           # How to contribute
├── .gitignore               # Git ignore rules
├── build.py                 # Assembles function sources + vendors shared lib
│
├── backend/services/        # Python Cloud Functions
│   ├── orders_api/          # HTTP: place/accept/complete (publishers)
│   │   ├── main.py
│   │   └── requirements.txt
│   ├── notify_restaurant/   # Pub/Sub push subscriber (order_placed)
│   │   ├── main.py
│   │   └── requirements.txt
│   ├── notify_user/         # Pub/Sub push subscriber (order_accepted)
│   │   ├── main.py
│   │   └── requirements.txt
│   └── shared/              # Event envelope, idempotency, Firestore
│       ├── __init__.py
│       ├── events.py
│       ├── idempotency.py
│       └── orders.py
│
├── frontend/                # Static UI (customer & restaurant portals)
│   ├── customer.html
│   ├── restaurant.html
│   ├── js/                  # JavaScript logic
│   │   ├── config.js
│   │   ├── customer.js
│   │   ├── restaurant.js
│   │   └── shared.js
│   └── css/
│       └── style.css
│
├── terraform/               # Infrastructure as Code (GCP resources)
│   ├── modules/
│   │   ├── pubsub_topic/    # One domain event per topic
│   │   ├── event_subscription/ # Push sub + DLQ + retry + ordering
│   │   ├── cloud_function/  # Gen 2 function from source zip
│   │   └── frontend/        # Cloud Storage bucket config
│   ├── *.tf files           # Terraform configuration
│   └── terraform.tfvars.example
│
├── scripts/                 # Deployment automation
│   ├── deploy-frontend.ps1  # PowerShell deployment (Windows)
│   ├── deploy-frontend.sh   # Bash deployment (Linux/Mac)
│   └── FRONTEND_DEPLOY.md   # Deployment guide
│
├── docs/                    # Comprehensive documentation
│   ├── ARCHITECTURE.md      # Pattern explanation & data model
│   ├── SETUP.md            # Step-by-step deployment guide
│   └── GCP_ISSUES.md       # Manual workarounds (2 gcloud commands)
│
└── examples/                # Sample requests & tests
    ├── README.md
    └── curl-test.sh         # API testing script
```

## Quick Start

### Prerequisites
- GCP project with billing enabled
- `gcloud` CLI ([install](https://cloud.google.com/sdk/docs/install))
- Python 3.12+
- Terraform 1.6+

### Step 1: Clone & Setup
```bash
git clone https://github.com/YOUR_USERNAME/gcp-pubsub-choreography.git
cd gcp-pubsub-choreography
```

### Step 2: Authenticate with GCP
```bash
gcloud auth application-default login
gcloud config set project YOUR_GCP_PROJECT_ID
```

### Step 3: Configure Terraform
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your project ID
# project_id = "your-gcp-project-id"
nano terraform.tfvars  # or use your editor
```

### Step 4: Deploy Infrastructure
```bash
terraform init
terraform apply

# Takes ~5-10 minutes to provision all resources
```

### Step 5: Build & Deploy Frontend
```bash
cd ..
python build.py

# Windows PowerShell:
.\scripts\deploy-frontend.ps1

# Linux/Mac:
bash scripts/deploy-frontend.sh
```

### Step 6: Get URLs & Test
```bash
# Get API and frontend URLs
cd terraform
terraform output orders_api_url      # API endpoint
terraform output frontend_url        # Frontend URL
```

Open the frontend URL in your browser and place an order!

---

## ⚠️ Important: Manual GCP Setup

After `terraform apply`, run these commands (see [docs/GCP_ISSUES.md](docs/GCP_ISSUES.md) for details):

```bash
# Grant Artifact Registry permissions
PROJECT_NUMBER=$(gcloud projects describe YOUR_PROJECT_ID --format='value(projectNumber)')
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"

# Grant public access to API
gcloud run services add-iam-policy-binding orders-api \
  --region=us-central1 \
  --member="allUsers" \
  --role="roles/run.invoker"
```

## Test the Choreography

### Via Browser
1. Open the frontend URL
2. **Customer:** Select a menu item and place an order
3. **Restaurant:** Click the restaurant link and accept/complete the order
4. Watch events flow through both portals in real time

### Via curl (Advanced)
```bash
API_URL=$(cd terraform && terraform output -raw orders_api_url && cd ..)

# 1. Place an order (emits order_placed)
ORDER_ID=$(curl -s -X POST "$API_URL/orders" \
  -H 'Content-Type: application/json' \
  -d '{"restaurant_id":"food-in","customer":{"email":"demo@example.com"},"items":["burger"]}' \
  | jq -r '.order_id')

echo "Order ID: $ORDER_ID"

# 2. Accept order (emits order_accepted)
curl -X POST "$API_URL/orders/$ORDER_ID/accept"

# 3. Complete order (emits order_completed)
curl -X POST "$API_URL/orders/$ORDER_ID/complete"

# 4. Check order status
curl -X GET "$API_URL/orders/$ORDER_ID" | jq '.events'
```

### Watch Live Logs
```bash
gcloud functions logs read orders-api --region us-central1 --gen2 --limit=50
gcloud functions logs read notify-restaurant --region us-central1 --gen2 --limit=50
gcloud functions logs read notify-user --region us-central1 --gen2 --limit=50

# Stream all logs
gcloud functions logs read --gen2 --since="10m ago" --limit=100
```

## How this honours the pattern (and guards its weaknesses)

The article's choreography *cons* are real; the validation council
(Gemini 2.5 Pro) flagged the GCP-specific ones, and they're addressed in code:

- **At-least-once delivery → idempotency.** Every handler claims the event id in
  Firestore (`backend/services/shared/idempotency.py`) before acting; duplicates are skipped.
- **Lost "poison pill" events → dead-letter.** Every subscription has its own DLQ
  topic + retry/backoff (`terraform/modules/event_subscription`). Alert on the DLQs
  (`terraform output dead_letter_topics`).
- **Out-of-order delivery → ordering keys.** Publishers key every event by
  `order_id`, so a consumer never sees `order_completed` before `order_accepted`.
- **Thin events, real state in DB.** Events carry `order_id` + references only;
  full order state lives in Firestore. This is what keeps services decoupled and
  stops the choreography from degenerating into a hidden orchestrator.
- **Least-privilege publishing.** IAM lets each function publish *only* to the
  topics it owns, keeping the event contracts honest.

## Documentation

- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — Deep dive into the choreography pattern, data model, and guarantees
- **[docs/GCP_ISSUES.md](docs/GCP_ISSUES.md)** — Known GCP issues and workarounds (manual fixes required after terraform apply)
- **[docs/SETUP.md](docs/SETUP.md)** — Detailed step-by-step deployment guide
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — How to contribute to this project

---

## Production Deployment

To run this in production:

1. **Separate GCP project** — Use a dedicated project for prod workload
2. **State backend** — Move Terraform state to Cloud Storage backend
3. **Monitoring** — Add Cloud Monitoring alerts on:
   - Dead-letter queue backlogs
   - Function error rates
   - End-to-end message latency
4. **Security** — Enable:
   - VPC Service Controls
   - Cloud Armor for DDoS protection
   - Firestore Security Rules
   - Cloud KMS encryption
5. **Backup** — Enable Firestore backups and test recovery
6. **Scaling** — Consider:
   - Multi-region deployment
   - Cloud CDN for frontend
   - Separate Cloud Run service for orders-api (if it grows)

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#production-checklist) for full checklist.

---

## Cleanup

To delete all resources (warning: irreversible):

```bash
cd terraform
terraform destroy
cd ..
```

This removes all GCP resources created by Terraform.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Build fails with Artifact Registry error | See [docs/GCP_ISSUES.md#issue-1](docs/GCP_ISSUES.md#issue-1-cloud-functions-build-fails--artifact-registry-permissions) |
| API returns 403 Forbidden | See [docs/GCP_ISSUES.md#issue-2](docs/GCP_ISSUES.md#issue-2-cloud-run-service-requires-authentication) |
| Frontend shows CORS error | See [docs/GCP_ISSUES.md#issue-3](docs/GCP_ISSUES.md#issue-3-cors-errors--browser-blocks-api-requests) |
| Frontend can't reach API | Check `frontend/js/config.js` has correct orders_api_url |
| Events not flowing | Check Pub/Sub subscription status in Google Cloud Console |
| High billing | Reduce max instances or enable firestore auto-scaling limits |

---

## Cost

Typical dev/demo workload (1,000 orders/month):
- Cloud Functions: $0.50
- Pub/Sub: $0.20
- Firestore: $2–5
- Storage: $0.02
- **Total: ~$3–6/month**

Enable budget alerts in GCP Console to avoid surprises.

---

## License

[MIT License](LICENSE) — Feel free to use this example for learning, teaching, and building!

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md).

⚠️ **Security:** Never commit GCP credentials, API keys, or secrets. Use `.gitignore` (already configured).

---

## Resources

- [Pub/Sub Ordering](https://cloud.google.com/pubsub/docs/ordering)
- [Cloud Functions Gen 2 Documentation](https://cloud.google.com/functions/docs/concepts/overview)
- [Firestore Pricing](https://cloud.google.com/firestore/pricing)
- [Event-Driven Architecture Patterns](https://aws.amazon.com/event-driven-architecture/)
- [Choreography vs. Orchestration](https://eda-visuals.boyney.io/visuals/choreography-vs-orchestration)
- [GCP Pub/Sub Concepts](https://cloud.google.com/pubsub/docs/concepts)
- [Cloud Functions Best Practices](https://cloud.google.com/functions/docs/bestpractices/retries)
```
