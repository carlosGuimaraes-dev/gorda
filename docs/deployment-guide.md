# Deployment Guide

## Backend Deployment (Node.js + TypeScript)

### Platform
- Target: Vercel (from project docs)

### Environment Variables
- Core: `PORT`, `DATABASE_URL`
- Auth: `CLERK_ISSUER`, `CLERK_JWKS_URL`, `CLERK_AUDIENCE`
- Storage: `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`
- Notifications:
  - Meta WhatsApp: `META_WABA_ID`, `META_PHONE_NUMBER_ID`, `META_ACCESS_TOKEN`
  - Email/Resend: `RESEND_API_KEY`, `RESEND_FROM`

### Database
- Apply migration SQL from `docs/backend-migrations.sql`
- Validate schema against `docs/backend-schema.sql`

### Post-deploy Checks
- `GET /health`
- Authenticated tenant listing `GET /v1/tenants`
- Push/pull sync smoke test
- Invoice send endpoint dry-run

## iOS Distribution
- Internal distribution target: TestFlight.
- Ensure environment endpoints/config are aligned with backend environment.
- Validate localization/currency behavior before release candidate builds.
