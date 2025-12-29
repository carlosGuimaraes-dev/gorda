export const env = {
  port: parseInt(process.env.PORT ?? "3000", 10),
  databaseUrl: process.env.DATABASE_URL ?? "",
  clerkIssuer: process.env.CLERK_ISSUER ?? "",
  clerkJwksUrl: process.env.CLERK_JWKS_URL ?? "",
  clerkAudience: process.env.CLERK_AUDIENCE ?? "",
  r2Endpoint: process.env.R2_ENDPOINT ?? "",
  r2AccessKeyId: process.env.R2_ACCESS_KEY_ID ?? "",
  r2SecretAccessKey: process.env.R2_SECRET_ACCESS_KEY ?? "",
  r2Bucket: process.env.R2_BUCKET ?? "",
  metaWabaId: process.env.META_WABA_ID ?? "",
  metaPhoneNumberId: process.env.META_PHONE_NUMBER_ID ?? "",
  metaAccessToken: process.env.META_ACCESS_TOKEN ?? "",
  resendApiKey: process.env.RESEND_API_KEY ?? "",
  resendFrom: process.env.RESEND_FROM ?? ""
};

export function requireEnv(name: string, value: string): string {
  if (!value) {
    throw new Error(`Missing required env var: ${name}`);
  }
  return value;
}
