import { createRemoteJWKSet, jwtVerify } from "jose";
import { env, requireEnv } from "../env.js";

const jwks = createRemoteJWKSet(new URL(requireEnv("CLERK_JWKS_URL", env.clerkJwksUrl)));
const issuer = requireEnv("CLERK_ISSUER", env.clerkIssuer);

export type ClerkAuth = {
  clerkUserId: string;
  email?: string;
  name?: string;
};

export async function verifyClerkToken(token: string): Promise<ClerkAuth> {
  const options: { issuer: string; audience?: string } = { issuer };
  if (env.clerkAudience) {
    options.audience = env.clerkAudience;
  }
  const { payload } = await jwtVerify(token, jwks, options);
  const sub = payload.sub;
  if (!sub) {
    throw new Error("Missing subject in token");
  }
  return {
    clerkUserId: sub,
    email: typeof payload.email === "string" ? payload.email : undefined,
    name: typeof payload.name === "string" ? payload.name : undefined
  };
}
