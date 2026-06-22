# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-06-22

### Added
- Initial public release: Event-driven choreography pattern on GCP
- Cloud Functions (Gen 2) for orders-api, notify-restaurant, notify-user
- Pub/Sub topics with dead-letter queues and ordering guarantees
- Firestore state storage with idempotency tracking
- Cloud Storage frontend (customer & restaurant portals)
- Terraform infrastructure as code with modules
- Comprehensive documentation
- Deployment scripts for PowerShell and Bash

### Tested
- Order placement to completion flow
- Browser-based customer and restaurant portals
- Event logging and audit trail
- CORS between Cloud Storage and Cloud Run
- Idempotency and duplicate event handling

### Documentation
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) — Pattern explanation
- [GCP_ISSUES.md](docs/GCP_ISSUES.md) — Manual workarounds
- [README.md](README.md) — Quick start

## Planned

### v1.1.0
- SendGrid email integration
- Cloud Monitoring alerts
- GitHub Actions CI/CD

### v2.0.0
- Multi-region deployment
- Payment integration
- Admin dashboard
