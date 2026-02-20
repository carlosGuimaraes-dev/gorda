# Development Guide - backend

## Prerequisites
- Node.js 20+ (ESM-compatible)
- npm
- PostgreSQL instance

## Setup
1. `cd backend`
2. `npm install`
3. Copy `.env.example` to `.env` and fill values:
   - `DATABASE_URL`
   - Clerk: `CLERK_ISSUER`, `CLERK_JWKS_URL`, optional `CLERK_AUDIENCE`
   - R2 + notification providers as needed

## Commands
- Dev server: `npm run dev`
- Build: `npm run build`
- Start built output: `npm run start`

## Runtime Notes
- API listens on `PORT` (default `3000`).
- All `/v1/*` routes require bearer token; tenant routes require `X-Tenant-Id`.

## Testing Status
- No automated test suite is currently wired in `package.json`.
- Recommended next step: add route-level integration tests and middleware auth tests.
