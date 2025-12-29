# Backend API Contract (v1)

## Conventions
- Base URL: `https://api.<domain>/v1`
- Auth: `Authorization: Bearer <clerk_jwt>`
- Tenant selection: `X-Tenant-Id: <tenant_uuid>` (required for all tenant-bound routes)
- Timestamps: ISO-8601 UTC strings
- IDs: UUID v4
- Soft delete: `deleted_at` set, treated as delete in sync

## Standard Error Shape
```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid token",
    "details": {}
  }
}
```

## Auth & Tenant
### GET /v1/tenants
Returns tenants the user belongs to.

Response:
```json
{
  "tenants": [
    { "id": "uuid", "name": "AG Home Organizer", "role": "manager" }
  ]
}
```

### POST /v1/tenants
Create a new tenant (Manager becomes owner).

Request:
```json
{ "name": "AG Home Organizer" }
```

Response:
```json
{ "id": "uuid", "name": "AG Home Organizer" }
```

### POST /v1/tenants/:id/invite
Invite a user to a tenant (Manager only).

Request:
```json
{ "email": "user@domain.com", "role": "employee" }
```

Response:
```json
{ "inviteId": "uuid", "status": "sent" }
```

### POST /v1/tenants/:id/activate
Marks active tenant for device/session (optional). Used to bind deviceId to tenant.

Request:
```json
{ "deviceId": "uuid" }
```

Response:
```json
{ "ok": true }
```

## Sync
### POST /v1/sync/push
Push local changes. Server applies LWW (client wins) and logs conflicts.

Request:
```json
{
  "deviceId": "uuid",
  "clientTime": "2025-12-29T10:00:00Z",
  "changes": [
    {
      "op": "upsert",
      "entity": "client",
      "entityId": "uuid",
      "clientUpdatedAt": "2025-12-29T09:59:00Z",
      "payload": {
        "name": "John Doe",
        "phone": "+1 415 555 0100",
        "whatsappPhone": "+1 415 555 0101",
        "email": "john@doe.com",
        "address": "123 Main St",
        "propertyDetails": "Unit 2B",
        "accessNotes": "Call front desk",
        "preferredSchedule": "Morning"
      }
    }
  ]
}
```

Response:
```json
{
  "serverTime": "2025-12-29T10:00:01Z",
  "applied": ["uuid"],
  "conflicts": [
    {
      "entity": "client",
      "entityId": "uuid",
      "fields": ["email"],
      "summary": "Email updated on another device; client value kept",
      "serverUpdatedAt": "2025-12-29T09:59:30Z"
    }
  ]
}
```

### GET /v1/sync/pull?since=<timestamp>&limit=<n>
Pull server changes since cursor.

Response:
```json
{
  "serverTime": "2025-12-29T10:05:00Z",
  "changes": [
    {
      "op": "upsert",
      "entity": "finance_entry",
      "entityId": "uuid",
      "updatedAt": "2025-12-29T10:02:00Z",
      "payload": {
        "title": "Invoice - Dec",
        "amount": 320.0,
        "type": "receivable",
        "status": "pending",
        "currency": "USD",
        "clientId": "uuid",
        "kind": "invoiceClient",
        "dueDate": "2025-12-31",
        "isDisputed": false
      }
    }
  ],
  "nextCursor": "2025-12-29T10:05:00Z"
}
```

### GET /v1/conflicts?since=<timestamp>
Returns conflict log for tenant.

Response:
```json
{
  "conflicts": [
    {
      "id": "uuid",
      "entity": "client",
      "entityId": "uuid",
      "fields": ["email"],
      "summary": "Email updated on another device; client value kept",
      "createdAt": "2025-12-29T10:00:01Z"
    }
  ]
}
```

### GET /v1/audit?since=<timestamp>
Returns audit log for tenant.

Response:
```json
{
  "audit": [
    {
      "id": "uuid",
      "entity": "finance_entry",
      "entityId": "uuid",
      "action": "updated",
      "summary": "Finance entry updated: Invoice - Dec",
      "actor": "Carlos (Manager)",
      "createdAt": "2025-12-29T10:01:00Z"
    }
  ]
}
```

## Attachments (R2)
### POST /v1/attachments/presign
Request a signed upload URL.

Request:
```json
{
  "ownerType": "finance_entry",
  "ownerId": "uuid",
  "mimeType": "image/jpeg",
  "size": 245000
}
```

Response:
```json
{
  "attachmentId": "uuid",
  "uploadUrl": "https://r2...signed",
  "r2Key": "tenants/<tenantId>/attachments/<uuid>"
}
```

### POST /v1/attachments/complete
Confirm upload and attach to entity.

Request:
```json
{
  "attachmentId": "uuid",
  "r2Key": "tenants/<tenantId>/attachments/<uuid>",
  "ownerType": "finance_entry",
  "ownerId": "uuid"
}
```

Response:
```json
{ "ok": true }
```

### GET /v1/attachments/:id/presign
Request a signed download URL.

Response:
```json
{ "downloadUrl": "https://r2...signed" }
```

## Notifications
### POST /v1/invoices/:id/send
Send invoice via manager-selected channels (WhatsApp/SMS/Email).

Request:
```json
{
  "channels": ["whatsapp", "sms", "email"],
  "message": "Invoice for Dec. Please see PDF.",
  "includePdf": true
}
```

Response:
```json
{
  "status": "queued",
  "notificationIds": ["uuid", "uuid"]
}
```

## Entities & Payload Shapes (summary)
- client: name, contact, phone, whatsappPhone, email, address, propertyDetails, accessNotes, preferredSchedule
- employee: name, roleTitle, team, phone, hourlyRate, currency
- service_type: name, description, basePrice, currency
- task: title, date, startTime, endTime, status, assignedEmployeeId, clientId, address, notes, serviceTypeId
- finance_entry: title, amount, type, dueDate, status, method, currency, clientId, employeeId, kind, isDisputed, disputeReason

