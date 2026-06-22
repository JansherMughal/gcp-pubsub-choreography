# GCP Manual Workarounds

**Why this exists:** Terraform automates most tasks, but some GCP features require manual intervention due to eventual consistency or timing issues. This document lists what to do if `terraform apply` fails on the first try.

---

## Manual Step: Grant Cloud Run Public Access

### If you see: 403 Forbidden or authentication error

After `terraform apply` completes, run:

```bash
gcloud run services add-iam-policy-binding orders-api \
  --region=us-central1 \
  --member="allUsers" \
  --role="roles/run.invoker"
```

**Why:** Terraform grants this via IAM, but GCP's IAM propagation can be delayed. This gcloud command handles the delay gracefully.

---

## Manual Step: Grant Artifact Registry Permissions

### If you see: "Unable to retrieve the repository metadata for gcf-artifacts"

After `terraform apply` completes, run:

```bash
PROJECT_NUMBER=$(gcloud projects describe YOUR_PROJECT_ID --format='value(projectNumber)')
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"
```

**Why:** Cloud Functions build process needs Artifact Registry access. Terraform automates this, but if builds fail immediately after apply, this gcloud command adds the permission with proper retry logic.

---

## Optional: SendGrid Email Integration

When you get a SendGrid account:

1. Get API key from https://sendgrid.com
2. Uncomment SendGrid code in `backend/services/notify_user/main.py`
3. Uncomment `sendgrid==6.11.*` in `backend/services/notify_user/requirements.txt`
4. Rebuild and redeploy:
   ```bash
   python build.py
   cd terraform
   terraform apply -var="sendgrid_api_key=SG.your_key_here"
   ```

---

## Troubleshooting Checklist

If `terraform apply` fails:

1. **Artifact Registry error** → Run the manual Artifact Registry command above
2. **403 Forbidden error** → Run the manual Cloud Run public access command above
3. **CORS errors** → Already fixed in code; just re-run `python build.py` and `terraform apply`
4. **Functions not deploying** → Check logs: `gcloud functions logs read orders-api --gen2 --limit=50`

If everything fails: Run both manual commands above, wait 30 seconds, re-run `terraform apply`.
