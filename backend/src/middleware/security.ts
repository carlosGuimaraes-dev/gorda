import { Request, Response, NextFunction } from "express";
import crypto from "crypto";

export function securityHeaders(req: Request, res: Response, next: NextFunction) {
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("Referrer-Policy", "no-referrer");
  res.setHeader("X-XSS-Protection", "0");
  res.setHeader("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none';");
  next();
}

export function requestId(req: Request, res: Response, next: NextFunction) {
  const id = crypto.randomUUID();
  res.setHeader("X-Request-Id", id);
  (req as Request & { requestId?: string }).requestId = id;
  next();
}
