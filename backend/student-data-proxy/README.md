# ORBIT Student Data Proxy

This is a small local demo backend for the ORBIT desktop/web real-data path. It
keeps Canvas and Google tokens outside the Flutter client, fetches student
signals, and returns the same snapshot shape consumed by the multi-agent system.

It is dependency-free and uses Node's built-in `http` and `fetch` APIs.

## Run

```powershell
cd backend/student-data-proxy
node server.mjs
```

Default URL:

```text
http://127.0.0.1:8787
```

Configure the Flutter app:

```env
EXTERNAL_DATA_ENABLED=true
STUDENT_DATA_PROXY_URL=http://127.0.0.1:8787
STUDENT_DATA_PROXY_USER_ID=demo
```

Then turn on `Canvas/Google live data` in app Settings.

## Environment

```env
STUDENT_PROXY_PORT=8787
STUDENT_PROXY_DATA_DIR=.data
CANVAS_BASE_URL=https://umd.instructure.com
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URI=http://127.0.0.1:8787/auth/google/callback
GOOGLE_MAPS_API_KEY=
CAMPUS_ROUTE_ORIGIN=McKeldin Library, College Park, MD
CAMPUS_ROUTE_DESTINATION=University Health Center, College Park, MD
```

## Endpoints

- `GET /health`
- `GET /auth/google/start?userId=demo`
- `GET /auth/google/callback`
- `POST /connect/canvas`
- `GET /student/snapshot?userId=demo&taskText=food&preferenceTags=vegan`

Example Canvas connect:

```powershell
Invoke-RestMethod `
  -Uri http://127.0.0.1:8787/connect/canvas `
  -Method Post `
  -ContentType 'application/json' `
  -Body '{"userId":"demo","baseUrl":"https://umd.instructure.com","accessToken":"canvas-token"}'
```

## Production Notes

This service is a production-shaped demo scaffold, not a hardened production
secret store. A real deployment should add encrypted token storage, real auth,
CSRF protection for OAuth state, HTTPS, token revocation, audit logs, rate
limits, and per-user consent records.
