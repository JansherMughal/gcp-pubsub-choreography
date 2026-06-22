# Setup & Deployment Guide

Step-by-step instructions to deploy this project to your GCP account.

## Prerequisites

- GCP project with billing enabled
- `gcloud` CLI installed ([guide](https://cloud.google.com/sdk/docs/install))
- Python 3.12+
- Terraform 1.6+ ([install](https://www.terraform.io/downloads))
- Git

## Step 1: Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/gcp-pubsub-choreography.git
cd gcp-pubsub-choreography
```

## Step 2: Authenticate with GCP

```bash
gcloud auth application-default login
gcloud config set project YOUR_GCP_PROJECT_ID
```

## Step 3: Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars

# Edit with your editor
nano terraform.tfvars  # Linux/Mac
# or
notepad terraform.tfvars  # Windows
```

Set at minimum:
```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"  # or your preferred region
```

## Step 4: Initialize & Deploy

```bash
terraform init
terraform plan  # Review what will be created
terraform apply # Deploy (takes 5-10 minutes)
```

**Important:** After `terraform apply`, run the 2 manual commands below (Step 5). These handle eventual consistency delays in GCP's IAM system.

## Step 5: Manual GCP Setup (2 commands, ~2 minutes)

```bash
# 1. Grant Artifact Registry permissions
PROJECT_NUMBER=$(gcloud projects describe YOUR_PROJECT_ID --format='value(projectNumber)')
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"

# 2. Grant public access to API
gcloud run services add-iam-policy-binding orders-api \
  --region=us-central1 \
  --member="allUsers" \
  --role="roles/run.invoker"
```

**Why?** See [GCP_ISSUES.md](GCP_ISSUES.md) for details. (Short answer: GCP's IAM propagation has a slight delay)

## Step 6: Build & Deploy Application

```bash
cd ..  # Back to project root
python build.py  # Assemble function sources
```

## Step 7: Deploy Frontend

**Windows (PowerShell):**
```powershell
.\scripts\deploy-frontend.ps1
```

**Linux/Mac (Bash):**
```bash
bash scripts/deploy-frontend.sh
```

## Step 8: Get URLs & Test

```bash
cd terraform
terraform output orders_api_url   # API endpoint
terraform output frontend_url     # Frontend URL
```

Open the frontend URL in your browser:
- Fill in email
- Select menu item
- Click "Place Order"
- Click restaurant link
- Accept and complete order
- Watch events flow through both portals!

## Verification

Check that everything is working:

```bash
# Test API directly
curl -X GET $(cd terraform && terraform output -raw orders_api_url && cd ..)/orders/test

# Check logs
gcloud functions logs read orders-api --gen2 --limit=20
gcloud functions logs read notify-restaurant --gen2 --limit=20
gcloud functions logs read notify-user --gen2 --limit=20

# Check Firestore
gcloud firestore databases list
```

## Cleanup

To delete all resources (irreversible):

```bash
cd terraform
terraform destroy
```

Confirm by typing "yes" when prompted.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Artifact Registry build error | See [docs/GCP_ISSUES.md#issue-1](GCP_ISSUES.md#issue-1) |
| 403 Forbidden from API | See [docs/GCP_ISSUES.md#issue-2](GCP_ISSUES.md#issue-2) |
| CORS errors in browser | See [docs/GCP_ISSUES.md#issue-3](GCP_ISSUES.md#issue-3) |
| Frontend can't reach API | Check `frontend/js/config.js` has correct URL |

## Next Steps

- Explore the [ARCHITECTURE.md](ARCHITECTURE.md) to understand how it works
- Try adding a new domain event (pizza_burned, payment_failed, etc.)
- Set up [SendGrid](https://sendgrid.com) and uncomment email code
- Add monitoring alerts via [Cloud Monitoring](https://cloud.google.com/monitoring)

## Cost Control

Monitor your GCP billing:

```bash
# Set a budget alert (optional)
gcloud billing budgets create \
  --billing-account=YOUR_BILLING_ACCOUNT \
  --display-name="Choreography Demo Budget" \
  --budget-amount=10  # USD per month
```

Typical demo workload costs $3-6/month. Use `terraform destroy` to stop charges.
