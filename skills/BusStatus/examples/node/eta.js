#!/usr/bin/env node
/**
 * TDX Bus ETA example (Node 18+)
 *
 * Usage:
 *   TDX_CLIENT_ID=... TDX_CLIENT_SECRET=... node eta.js
 */

const TOKEN_URL =
  "https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token";

function requiredEnv(name) {
  const v = process.env[name];
  if (!v) {
    console.error(
      `Missing environment variable ${name}.\n` +
        "Set TDX_CLIENT_ID and TDX_CLIENT_SECRET before running."
    );
    process.exit(1);
  }
  return v;
}

function zhTwName(obj) {
  if (!obj) return "";
  if (typeof obj === "string") return obj;
  return obj.Zh_tw || obj.En || "";
}

const STOP_STATUS = {
  0: "正常",
  1: "尚未發車",
  2: "交管不停靠",
  3: "末班車已過",
  4: "今日未營運",
};

async function fetchToken({ clientId, clientSecret }) {
  const body = new URLSearchParams({
    grant_type: "client_credentials",
    client_id: clientId,
    client_secret: clientSecret,
  });

  const res = await fetch(TOKEN_URL, {
    method: "POST",
    headers: {
      "content-type": "application/x-www-form-urlencoded",
    },
    body,
  });

  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`Token request failed: HTTP ${res.status} ${res.statusText}\n${text}`);
  }

  const json = await res.json();
  if (!json.access_token) throw new Error("Token response missing access_token");
  return json.access_token;
}

async function fetchEta({ token }) {
  const url = new URL(
    "https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/NewTaipei"
  );
  url.searchParams.set("$top", "5");
  url.searchParams.set("$format", "JSON");

  const res = await fetch(url, {
    headers: {
      authorization: `Bearer ${token}`,
    },
  });

  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`ETA request failed: HTTP ${res.status} ${res.statusText}\n${text}`);
  }

  return res.json();
}

function pad(s, n) {
  s = String(s ?? "");
  return s.length >= n ? s.slice(0, n - 1) + "…" : s.padEnd(n);
}

(async () => {
  const clientId = requiredEnv("TDX_CLIENT_ID");
  const clientSecret = requiredEnv("TDX_CLIENT_SECRET");

  const token = await fetchToken({ clientId, clientSecret });
  const rows = await fetchEta({ token });

  console.log(
    [pad("Route", 10), pad("Stop", 16), pad("ETA(s)", 8), pad("StopStatus", 12)].join(
      "  "
    )
  );
  console.log("-".repeat(10 + 2 + 16 + 2 + 8 + 2 + 12));

  for (const r of rows) {
    const route = zhTwName(r.RouteName);
    const stop = zhTwName(r.StopName);
    const eta = r.EstimateTime == null ? "" : String(r.EstimateTime);
    const stopStatus =
      r.StopStatus == null
        ? ""
        : STOP_STATUS[r.StopStatus] ?? `未知(${r.StopStatus})`;

    console.log([pad(route, 10), pad(stop, 16), pad(eta, 8), pad(stopStatus, 12)].join("  "));
  }
})().catch((err) => {
  console.error(err?.stack || String(err));
  process.exit(1);
});
