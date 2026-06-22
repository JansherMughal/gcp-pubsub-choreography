# ---------------------------------------------------------------------------
# deploy-frontend.ps1 — Upload Food In UI to Cloud Storage (Windows)
#
# Usage:
#   .\deploy-frontend.ps1
#
# Prerequisites:
#   - gcloud CLI installed and authenticated (gcloud auth login)
#   - Terraform deployed (terraform apply)
# ---------------------------------------------------------------------------

param([string]$UiDir = "frontend")

if (-not (Test-Path $UiDir)) {
    Write-Error "UI directory '$UiDir' does not exist"
    exit 1
}

# Get the bucket name from Terraform output
Push-Location terraform
$Bucket = $(terraform output -raw frontend_bucket 2>$null)
Pop-Location

if (-not $Bucket) {
    Write-Error "Could not get frontend_bucket from Terraform. Have you run 'terraform apply'?"
    exit 1
}

Write-Host "📦 Deploying Food In UI to gs://$Bucket" -ForegroundColor Green
Write-Host ""

# Upload only UI files to bucket root (without directory structure)
Write-Host "Uploading files..." -ForegroundColor Cyan
Push-Location $UiDir
gcloud storage cp --recursive --cache-control "public, max-age=3600" "*" "gs://$Bucket/"
Pop-Location

Write-Host ""
Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Frontend URL:" -ForegroundColor Cyan
Push-Location terraform
terraform output -raw frontend_url
Pop-Location
Write-Host ""
Write-Host "Tip: Open this URL in a browser to access the Food In ordering portal."
