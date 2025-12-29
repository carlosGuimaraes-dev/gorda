import { Request, Response, NextFunction } from "express";
import { verifyClerkToken, ClerkAuth } from "../auth/clerk.js";

export type AuthRequest = Request & { auth?: ClerkAuth };

export async function requireAuth(req: AuthRequest, res: Response, next: NextFunction) {
  const header = req.header("Authorization") ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : "";
  if (!token) {
    res.status(401).json({ error: { code: "UNAUTHORIZED", message: "Missing token" } });
    return;
  }
  try {
    req.auth = await verifyClerkToken(token);
    next();
  } catch (error) {
    res.status(401).json({ error: { code: "UNAUTHORIZED", message: "Invalid token" } });
  }
}
