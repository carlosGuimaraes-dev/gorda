# Provider Integration Checklist (Meta WhatsApp + Resend)

## Meta WhatsApp Cloud API (Direct)
### Account & Access
- Create/verify Meta Business Manager
- Create WhatsApp Business Account (WABA)
- Add phone number (new, SMS/voice verification)
- Verify Business (required for production templates)
- Create Meta App (type: Business)
- Add product: WhatsApp
- Generate permanent access token (System User + token)
- Store secrets in Vercel env vars
  - `META_WABA_ID`, `META_PHONE_NUMBER_ID`, `META_ACCESS_TOKEN`, `META_APP_SECRET`

### Webhooks
- Configure webhook endpoint (HTTPS)
- Subscribe to `messages` events
- Verify webhook (challenge token)
- Validate webhook signatures

### Messaging Rules
- Use approved message templates for outbound (outside 24h window)
- Track 24h customer care window for session messages
- Implement opt-in requirement (store consent timestamps)
- Handle rate limits + retries (exponential backoff)

### Send Flow (Backend)
- Build message payloads per channel:
  - text-only invoice message
  - PDF attachment link (signed URL)
- Send via `/messages` endpoint
- Persist notification status (queued → sent → delivered/failed)

### Testing
- Use test phone numbers in dev
- Validate template approvals and rendering
- Verify link opening from WhatsApp

### Compliance
- Respect opt-in/opt-out
- Log delivery status and errors

---

## Resend (Email)
### Domain & Security
- Add sending domain in Resend
- Configure DNS records (SPF, DKIM)
- Optional DMARC for deliverability
- Create API key (dev + prod)
- Store in Vercel env vars
  - `RESEND_API_KEY`, `RESEND_FROM`

### Webhooks
- Configure webhook endpoint for delivered/bounced
- Verify webhook signatures
- Persist delivery status in notifications table

### Email Content
- Build standard invoice email template
- Include PDF signed URL
- Include dispute link

### Testing
- Send test emails to internal accounts
- Verify attachment link access
- Confirm HTML + plain text fallbacks

---

## Cross‑Cutting
- Secrets management in Vercel (separate dev/prod)
- Structured logging for provider calls
- Dead‑letter handling for failed sends
- Rate limiting for outbound sends
- Audit log entries for each send attempt

## Device‑Only iMessage/SMS
- Backend does not send SMS
- App opens `sms:` / Messages with prefilled text
- Track send attempts locally if needed
