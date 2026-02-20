import crypto from "crypto";
import { env } from "../env.js";

const defaultExpiresInSeconds = 900;

function toHex(buffer: Buffer): string {
  return buffer.toString("hex");
}

function sha256(value: string): string {
  return toHex(crypto.createHash("sha256").update(value, "utf8").digest());
}

function hmac(key: Buffer | string, value: string): Buffer {
  return crypto.createHmac("sha256", key).update(value, "utf8").digest();
}

function encodeRfc3986(value: string): string {
  return encodeURIComponent(value).replace(/[!'()*]/g, (char) => `%${char.charCodeAt(0).toString(16).toUpperCase()}`);
}

function buildCanonicalQuery(params: Record<string, string>): string {
  return Object.keys(params)
    .sort()
    .map((key) => `${encodeRfc3986(key)}=${encodeRfc3986(params[key])}`)
    .join("&");
}

function formatAwsDate(date: Date): { amzDate: string; dateStamp: string } {
  const iso = date.toISOString().replace(/[:-]|\.\d{3}/g, "");
  const amzDate = `${iso.slice(0, 8)}T${iso.slice(8, 14)}Z`;
  const dateStamp = amzDate.slice(0, 8);
  return { amzDate, dateStamp };
}

function getRegion(): string {
  return env.r2Region || "auto";
}

export function isR2Configured(): boolean {
  return Boolean(env.r2Endpoint && env.r2AccessKeyId && env.r2SecretAccessKey && env.r2Bucket);
}

function buildCanonicalUri(key: string, endpointPathname: string): string {
  const endpointSegments = endpointPathname.split("/").filter(Boolean).map(encodeRfc3986);
  const keySegments = key.split("/").filter(Boolean).map(encodeRfc3986);
  return `/${[...endpointSegments, encodeRfc3986(env.r2Bucket), ...keySegments].join("/")}`;
}

export function createPresignedR2Url(
  method: "GET" | "PUT" | "HEAD",
  key: string,
  expiresInSeconds = defaultExpiresInSeconds
): string {
  if (!isR2Configured()) {
    throw new Error("R2_NOT_CONFIGURED");
  }

  const endpoint = new URL(env.r2Endpoint);
  const host = endpoint.host;
  const now = new Date();
  const { amzDate, dateStamp } = formatAwsDate(now);
  const region = getRegion();
  const service = "s3";
  const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;

  const canonicalUri = buildCanonicalUri(key, endpoint.pathname);
  const signedHeaders = "host";
  const queryParams = {
    "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
    "X-Amz-Credential": `${env.r2AccessKeyId}/${credentialScope}`,
    "X-Amz-Date": amzDate,
    "X-Amz-Expires": String(expiresInSeconds),
    "X-Amz-SignedHeaders": signedHeaders
  };
  const canonicalQuery = buildCanonicalQuery(queryParams);
  const canonicalHeaders = `host:${host}\n`;
  const payloadHash = "UNSIGNED-PAYLOAD";
  const canonicalRequest = [method, canonicalUri, canonicalQuery, canonicalHeaders, signedHeaders, payloadHash].join("\n");

  const stringToSign = [
    "AWS4-HMAC-SHA256",
    amzDate,
    credentialScope,
    sha256(canonicalRequest)
  ].join("\n");

  const kDate = hmac(`AWS4${env.r2SecretAccessKey}`, dateStamp);
  const kRegion = hmac(kDate, region);
  const kService = hmac(kRegion, service);
  const kSigning = hmac(kService, "aws4_request");
  const signature = toHex(hmac(kSigning, stringToSign));

  const baseUrl = `${endpoint.protocol}//${host}${canonicalUri}`;
  return `${baseUrl}?${canonicalQuery}&X-Amz-Signature=${signature}`;
}

export async function verifyR2ObjectExists(key: string): Promise<boolean> {
  const presignedHeadUrl = createPresignedR2Url("HEAD", key, 60);
  const response = await fetch(presignedHeadUrl, { method: "HEAD" });
  return response.ok;
}
