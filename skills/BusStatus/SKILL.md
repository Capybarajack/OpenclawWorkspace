---
name: bus-status
description: A practical playbook for using Taiwan TDX (tdx.transportdata.tw) Bus APIs to query real-time bus status (A1/A2) and ETA (N1), including auth/token caching, key endpoints, and OData query patterns.
---

# BusStatus (TDX Bus APIs)

Use this skill when you need **Taiwan TDX** bus information:

- **ETA / arrival prediction** (N1): `EstimatedTimeOfArrival`
- **Real-time vehicle dynamic** (A1): `RealTimeByFrequency`
- **Real-time near-stop events** (A2): `RealTimeNearStop`

This is written as an **operator runbook**: copy/paste commands, keep secrets out of repos.

## Auth (OIDC Client Credentials)

TDX uses OIDC **client_credentials** to obtain an access token.

- Token endpoint:
  - `https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token`
- Request:
  - Method: `POST`
  - Header: `content-type: application/x-www-form-urlencoded`
  - Body fields:
    - `grant_type=client_credentials`
    - `client_id=<YOUR_CLIENT_ID>`
    - `client_secret=<YOUR_CLIENT_SECRET>`

### Environment variables (recommended)

- `TDX_CLIENT_ID`
- `TDX_CLIENT_SECRET`

### Token caching (strongly recommended)

- Token endpoint has its own rate limit (commonly **20/min per IP**).
- The token response contains `expires_in` (often **86400 seconds**).
- Cache the token in memory (or a local file) and refresh it before expiry.

## Base URL(s) and required query params

For **Basic** services:

- Base server URL: `https://tdx.transportdata.tw/api/basic`

Most Bus endpoints in Swagger require:

- `?$format=JSON` (or `XML`)

Also supported (OData-style query options, not available on every endpoint):

- `$select`, `$filter`, `$orderby`, `$top`, `$skip`

## Quick start (curl)

### 1) Fetch access token

```bash
TOKEN=$(curl -s -X POST \
  'https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token' \
  -H 'content-type: application/x-www-form-urlencoded' \
  -d 'grant_type=client_credentials' \
  -d "client_id=${TDX_CLIENT_ID}" \
  -d "client_secret=${TDX_CLIENT_SECRET}" \
  | python -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
```

Notes:
- Keep `client_id`/`client_secret` out of shell history if you can.
- If you have `jq`, replace the Python one-liner with `jq -r .access_token`.

### 2) ETA (N1): EstimatedTimeOfArrival (City)

```bash
curl -s \
  -H "authorization: Bearer ${TOKEN}" \
  "https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/NewTaipei?$top=5&$format=JSON"
```

### 3) Real-time (A1): RealTimeByFrequency (City)

```bash
curl -s \
  -H "authorization: Bearer ${TOKEN}" \
  "https://tdx.transportdata.tw/api/basic/v2/Bus/RealTimeByFrequency/City/NewTaipei?$top=5&$format=JSON"
```

PowerShell note:
- In PowerShell, `$top` is a variable. Use single quotes or escape `$`.
  Example:
  ```powershell
  curl -H "authorization: Bearer $TOKEN" 'https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/NewTaipei?$top=5&$format=JSON'
  ```

## Key endpoints (Basic v2)

Commonly used ones:

- ETA:
  - `GET /v2/Bus/EstimatedTimeOfArrival/City/{City}`
  - `GET /v2/Bus/EstimatedTimeOfArrival/City/{City}/{RouteName}`
  - `GET /v2/Bus/EstimatedTimeOfArrival/InterCity`
- Real-time vehicle dynamic (A1):
  - `GET /v2/Bus/RealTimeByFrequency/City/{City}`
  - `GET /v2/Bus/RealTimeByFrequency/InterCity`
- Real-time near-stop events (A2):
  - `GET /v2/Bus/RealTimeNearStop/City/{City}`
  - `GET /v2/Bus/RealTimeNearStop/InterCity`
- Static lookup (helps you map ids / names):
  - `GET /v2/Bus/Route/City/{City}`
  - `GET /v2/Bus/Stop/City/{City}`
  - `GET /v2/Bus/StopOfRoute/City/{City}`
  - `GET /v2/Bus/Station/City/{City}`

## Common tasks (OData query patterns)

TDX supports OData-like query parameters on many endpoints.

### Filter by route name (RouteName/Zh_tw)

Example: ETA for a specific route name (city bus):

```bash
curl -s -H "authorization: Bearer ${TOKEN}" \
  "https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/NewTaipei?$filter=RouteName/Zh_tw%20eq%20'307'&$top=30&$format=JSON"
```

### Filter by StopUID

```bash
curl -s -H "authorization: Bearer ${TOKEN}" \
  "https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/NewTaipei?$filter=StopUID%20eq%20'NWT12345'&$format=JSON"
```

### Direction (0:去程, 1:返程)

```bash
curl -s -H "authorization: Bearer ${TOKEN}" \
  "https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/NewTaipei?$filter=RouteName/Zh_tw%20eq%20'307'%20and%20Direction%20eq%200&$format=JSON"
```

### Select only needed fields ($select)

Useful for smaller payloads:

```bash
curl -s -H "authorization: Bearer ${TOKEN}" \
  "https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/NewTaipei?$select=RouteName,StopName,EstimateTime,StopStatus,Direction,UpdateTime&$top=10&$format=JSON"
```

### Interpreting StopStatus and EstimateTime (ETA)

- `EstimateTime` is typically **seconds** to arrival.
- If `StopStatus != 0`, `EstimateTime` may be `null`.

## Status code cheat sheet

### BusStatus (A1/A2)

行車狀況 : [0:'正常',1:'車禍',2:'故障',3:'塞車',4:'緊急求援',5:'加油',90:'不明',91:'去回不明',98:'偏移路線',99:'非營運狀態',100:'客滿',101:'包車出租',255:'未知']

### StopStatus (ETA)

車輛狀態備註 : [0:'正常',1:'尚未發車',2:'交管不停靠',3:'末班車已過',4:'今日未營運']

## Where to download the official OpenAPI (OAS) JSON

The swagger UI is an SPA; the **real OpenAPI 3 JSON** can be downloaded via TDX web APIs.

1) Discover available service groups (includes Bus groups and version tags):

- `GET https://tdx.transportdata.tw/webapi/serviceCategory/ForSwagger`

2) Download the OpenAPI 3 JSON for a group:

- `GET https://tdx.transportdata.tw/webapi/File/Swagger/V3/<serviceGroupId>`

For **Bus (basic v2)**:

- `serviceGroupId`: `2998e851-81d0-40f5-b26d-77e2f5ac4118`
- `servers[0].url`: `https://tdx.transportdata.tw/api/basic`

Example:

```bash
curl -L -o tdx-bus-basic-v2-openapi.json \
  "https://tdx.transportdata.tw/webapi/File/Swagger/V3/2998e851-81d0-40f5-b26d-77e2f5ac4118"
```

## Guardrails

- Never commit `TDX_CLIENT_SECRET`.
- Prefer token caching; do not request a new token for every API call.
- If you need to share debug output, redact Authorization headers and secrets.
