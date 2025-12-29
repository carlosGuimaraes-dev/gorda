import express from "express";
import { securityHeaders, requestId } from "./middleware/security.js";
import { requireAuth } from "./middleware/auth.js";
import tenantsRouter from "./routes/tenants.js";
import syncRouter from "./routes/sync.js";
import conflictsRouter from "./routes/conflicts.js";
import auditRouter from "./routes/audit.js";
import attachmentsRouter from "./routes/attachments.js";
import notificationsRouter from "./routes/notifications.js";

const app = express();

app.disable("x-powered-by");
app.use(express.json({ limit: "1mb" }));
app.use(requestId);
app.use(securityHeaders);

app.get("/health", (_req, res) => {
  res.status(200).json({ ok: true });
});

app.use("/v1", requireAuth);
app.use("/v1/tenants", tenantsRouter);
app.use("/v1/sync", syncRouter);
app.use("/v1/attachments", attachmentsRouter);
app.use("/v1/invoices", notificationsRouter);
app.use("/v1/conflicts", conflictsRouter);
app.use("/v1/audit", auditRouter);

app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err);
  res.status(500).json({ error: { code: "INTERNAL", message: "Unexpected error" } });
});

export default app;
