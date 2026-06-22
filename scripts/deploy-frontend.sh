#!/bin/bash
# ---------------------------------------------------------------------------
# deploy-frontend.sh — Upload Food In UI to Cloud Storage
#
# Usage:
#   ./deploy-frontend.sh
#
# Prerequisites:
#   - gcloud CLI installed and authenticated (gcloud auth login)
#   - Terraform deployed (terraform apply)
# ---------------------------------------------------------------------------

set -e

UI_DIR="${1:-frontend}"
if [ ! -d "$UI_DIR" ]; then
  echo "Error: UI directory '$UI_DIR' does not exist"
  exit 1
fi

# Get the bucket name from Terraform output
BUCKET=$(cd terraform && terraform output -raw frontend_bucket 2>/dev/null || echo "")
if [ -z "$BUCKET" ]; then
  echo "Error: Could not get frontend_bucket from Terraform. Have you run 'terraform apply'?"
  exit 1
fi

echo "📦 Deploying Food In UI to gs://$BUCKET"
echo ""

# Upload all files with public-read ACL
echo "Uploading files..."
gsutil -h "Cache-Control:public, max-age=3600" -m cp -r "$UI_DIR"/* "gs://$BUCKET/"

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Frontend URL:"
cd terraform && terraform output -raw frontend_url
echo ""
echo "Tip: Open this URL in a browser to access the Food In ordering portal."
