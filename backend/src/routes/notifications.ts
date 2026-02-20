import { Router } from "express";
import { requireManager, requireTenant, TenantRequest } from "../middleware/tenant.js";
import { query } from "../db.js";
import crypto from "crypto";
import { env } from "../env.js";

const router = Router();
const rateLimitWindowMs = 60_000;
const rateLimitMax = 10;
const tenantSendTracker = new Map<string, { count: number; resetAt: number }>();
const metaGraphVersion = "v22.0";

type NotificationChannel = "whatsapp" | "email";

type InvoiceRow = {
  id: string;
  title: string;
  amount: number;
  currency: string;
  client_name: string | null;
  client_email: string | null;
  client_whatsapp_phone: string | null;
  client_phone: string | null;
};

type SendResult = {
  notificationId: string;
  channel: NotificationChannel;
  status: "sent" | "failed";
  providerMessageId: string | null;
  error?: string;
};

function checkRateLimit(tenantId: string): boolean {
  const now = Date.now();
  const entry = tenantSendTracker.get(tenantId);
  if (!entry || entry.resetAt < now) {
    tenantSendTracker.set(tenantId, { count: 1, resetAt: now + rateLimitWindowMs });
    return true;
  }
  if (entry.count >= rateLimitMax) {
    return false;
  }
  entry.count += 1;
  return true;
}

function parseChannels(value: unknown): NotificationChannel[] {
  if (!Array.isArray(value)) {
    return [];
  }
  const valid = value.filter((channel): channel is NotificationChannel => channel === "whatsapp" || channel === "email");
  return Array.from(new Set(valid));
}

function normalizePhone(phone: string): string {
  const trimmed = phone.trim();
  if (!trimmed) return "";
  if (trimmed.startsWith("+")) {
    const digits = trimmed.slice(1).replace(/\D/g, "");
    return digits ? `+${digits}` : "";
  }
  const digits = trimmed.replace(/\D/g, "");
  return digits ? `+${digits}` : "";
}

async function parseJsonBody(response: Response): Promise<Record<string, unknown>> {
  try {
    return (await response.json()) as Record<string, unknown>;
  } catch {
    return {};
  }
}

async function sendEmailNotification(
  toEmail: string,
  subject: string,
  text: string
): Promise<{ providerMessageId: string }> {
  if (!env.resendApiKey || !env.resendFrom) {
    throw new Error("Resend is not configured");
  }

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.resendApiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      from: env.resendFrom,
      to: [toEmail],
      subject,
      text
    })
  });

  const body = await parseJsonBody(response);
  if (!response.ok || typeof body.id !== "string") {
    const errorMessage = typeof body.message === "string" ? body.message : "Resend send failed";
    throw new Error(errorMessage);
  }

  return { providerMessageId: body.id };
}

async function sendWhatsAppNotification(toPhone: string, messageText: string): Promise<{ providerMessageId: string }> {
  if (!env.metaPhoneNumberId || !env.metaAccessToken) {
    throw new Error("Meta WhatsApp API is not configured");
  }
  const normalizedPhone = normalizePhone(toPhone);
  if (!normalizedPhone) {
    throw new Error("Invalid WhatsApp destination");
  }

  const url = `https://graph.facebook.com/${metaGraphVersion}/${env.metaPhoneNumberId}/messages`;
  const response = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${env.metaAccessToken}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      messaging_product: "whatsapp",
      to: normalizedPhone,
      type: "text",
      text: { body: messageText }
    })
  });

  const body = await parseJsonBody(response);
  const messages = Array.isArray(body.messages) ? body.messages : [];
  const providerMessageId = messages.length > 0 && typeof (messages[0] as Record<string, unknown>).id === "string"
    ? String((messages[0] as Record<string, unknown>).id)
    : "";

  if (!response.ok || !providerMessageId) {
    const error = body.error as Record<string, unknown> | undefined;
    const errorMessage = error && typeof error.message === "string" ? error.message : "WhatsApp send failed";
    throw new Error(errorMessage);
  }

  return { providerMessageId };
}

router.post("/:id/send", requireTenant, requireManager, async (req: TenantRequest, res) => {
  const tenantId = req.tenant!.id;
  if (!checkRateLimit(tenantId)) {
    res.status(429).json({ error: { code: "RATE_LIMIT", message: "Too many send attempts" } });
    return;
  }
  const invoiceId = req.params.id;
  const filtered = parseChannels(req.body?.channels);
  if (filtered.length === 0) {
    res.status(400).json({ error: { code: "INVALID_REQUEST", message: "channels must include whatsapp or email" } });
    return;
  }

  const invoiceRows = await query<InvoiceRow>(
    `SELECT f.id, f.title, f.amount, f.currency, f.client_name,
            c.email AS client_email, c.whatsapp_phone AS client_whatsapp_phone, c.phone AS client_phone
     FROM finance_entries f
     LEFT JOIN clients c ON c.id = f.client_id AND c.tenant_id = f.tenant_id
     WHERE f.id = $1
       AND f.tenant_id = $2
       AND f.kind = 'invoiceClient'
       AND f.deleted_at IS NULL
     LIMIT 1`,
    [invoiceId, tenantId]
  );
  const invoice = invoiceRows[0];
  if (!invoice) {
    res.status(404).json({ error: { code: "INVOICE_NOT_FOUND", message: "Invoice not found for tenant" } });
    return;
  }

  const rawMessage = typeof req.body?.message === "string" ? req.body.message.trim() : "";
  const baseMessage = rawMessage || `Invoice ${invoice.title} (${invoice.currency.toUpperCase()} ${invoice.amount})`;
  const includePdf = Boolean(req.body?.includePdf);
  const pdfUrl = typeof req.body?.pdfUrl === "string" ? req.body.pdfUrl.trim() : "";
  const messageText = includePdf && pdfUrl ? `${baseMessage}\n${pdfUrl}` : baseMessage;
  const emailSubject = `Invoice: ${invoice.title}`;

  const notificationIds: string[] = [];
  const results: SendResult[] = [];

  for (const channel of filtered) {
    const id = crypto.randomUUID();
    notificationIds.push(id);
    await query(
      "INSERT INTO notifications (id, tenant_id, entity, entity_id, channel, status) VALUES ($1, $2, $3, $4, $5, $6)",
      [id, tenantId, "finance_entry", invoiceId, channel, "queued"]
    );

    try {
      let providerMessageId = "";
      if (channel === "email") {
        const toEmail = invoice.client_email?.trim() ?? "";
        if (!toEmail) {
          throw new Error("Client email is missing");
        }
        const sendResult = await sendEmailNotification(toEmail, emailSubject, messageText);
        providerMessageId = sendResult.providerMessageId;
      } else {
        const destinationPhone = (invoice.client_whatsapp_phone ?? invoice.client_phone ?? "").trim();
        if (!destinationPhone) {
          throw new Error("Client WhatsApp/phone is missing");
        }
        const sendResult = await sendWhatsAppNotification(destinationPhone, messageText);
        providerMessageId = sendResult.providerMessageId;
      }

      await query(
        "UPDATE notifications SET status = 'sent', provider_message_id = $2 WHERE id = $1",
        [id, providerMessageId]
      );
      results.push({
        notificationId: id,
        channel,
        status: "sent",
        providerMessageId
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Provider send failed";
      await query(
        "UPDATE notifications SET status = 'failed', provider_message_id = $2 WHERE id = $1",
        [id, message.slice(0, 240)]
      );
      results.push({
        notificationId: id,
        channel,
        status: "failed",
        providerMessageId: null,
        error: message
      });
    }
  }

  const sentCount = results.filter((result) => result.status === "sent").length;
  const overallStatus = sentCount === results.length ? "sent" : sentCount === 0 ? "failed" : "partial";
  res.json({ status: overallStatus, notificationIds, results });
});

export default router;
