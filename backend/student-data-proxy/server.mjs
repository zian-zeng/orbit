import { createServer } from 'node:http';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { randomBytes } from 'node:crypto';

const port = Number(process.env.STUDENT_PROXY_PORT || 8787);
const host = process.env.STUDENT_PROXY_HOST || '127.0.0.1';
const dataDir = process.env.STUDENT_PROXY_DATA_DIR || '.data';
const storePath = join(dataDir, 'tokens.json');
const canvasBaseUrl =
  process.env.CANVAS_BASE_URL || 'https://umd.instructure.com';
const googleRedirectUri =
  process.env.GOOGLE_REDIRECT_URI ||
  `http://${host}:${port}/auth/google/callback`;
const campusRouteOrigin =
  process.env.CAMPUS_ROUTE_ORIGIN || 'McKeldin Library, College Park, MD';
const campusRouteDestination =
  process.env.CAMPUS_ROUTE_DESTINATION ||
  'University Health Center, College Park, MD';
const pendingStates = new Map();

const server = createServer(async (request, response) => {
  try {
    await route(request, response);
  } catch (error) {
    sendJson(response, 500, {
      error: 'proxy_error',
      message: error instanceof Error ? error.message : String(error),
    });
  }
});

server.listen(port, host, () => {
  console.log(`ORBIT student data proxy listening on http://${host}:${port}`);
});

async function route(request, response) {
  const url = new URL(request.url || '/', `http://${request.headers.host}`);
  if (request.method === 'OPTIONS') {
    sendCors(response, 204);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/health') {
    sendJson(response, 200, {
      ok: true,
      service: 'orbit-student-data-proxy',
      canvasBaseUrl,
      googleOAuthConfigured: hasGoogleOAuthConfig(),
      googleMapsConfigured: Boolean(process.env.GOOGLE_MAPS_API_KEY),
    });
    return;
  }

  if (request.method === 'GET' && url.pathname === '/auth/google/start') {
    await startGoogleOAuth(url, response);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/auth/google/callback') {
    await finishGoogleOAuth(url, response);
    return;
  }

  if (request.method === 'POST' && url.pathname === '/connect/canvas') {
    await connectCanvas(request, response);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/student/snapshot') {
    await studentSnapshot(url, response);
    return;
  }

  sendJson(response, 404, { error: 'not_found' });
}

async function startGoogleOAuth(url, response) {
  if (!hasGoogleOAuthConfig()) {
    sendJson(response, 503, {
      error: 'google_oauth_not_configured',
      message:
        'Set GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, and GOOGLE_REDIRECT_URI.',
    });
    return;
  }

  const userId = userIdFrom(url);
  const state = randomBytes(18).toString('base64url');
  pendingStates.set(state, { userId, createdAt: Date.now() });
  const authUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth');
  authUrl.searchParams.set('client_id', process.env.GOOGLE_CLIENT_ID);
  authUrl.searchParams.set('redirect_uri', googleRedirectUri);
  authUrl.searchParams.set('response_type', 'code');
  authUrl.searchParams.set('scope', 'https://www.googleapis.com/auth/calendar.readonly');
  authUrl.searchParams.set('access_type', 'offline');
  authUrl.searchParams.set('prompt', 'consent');
  authUrl.searchParams.set('state', state);
  response.writeHead(302, { Location: authUrl.toString() });
  response.end();
}

async function finishGoogleOAuth(url, response) {
  const code = url.searchParams.get('code');
  const state = url.searchParams.get('state');
  const stateRecord = state ? pendingStates.get(state) : null;
  if (!code || !state || !stateRecord) {
    sendJson(response, 400, {
      error: 'invalid_google_callback',
      message: 'Missing code or OAuth state.',
    });
    return;
  }
  pendingStates.delete(state);

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code,
      client_id: process.env.GOOGLE_CLIENT_ID,
      client_secret: process.env.GOOGLE_CLIENT_SECRET,
      redirect_uri: googleRedirectUri,
      grant_type: 'authorization_code',
    }),
  });
  const tokenJson = await tokenResponse.json();
  if (!tokenResponse.ok) {
    sendJson(response, tokenResponse.status, {
      error: 'google_token_exchange_failed',
      details: tokenJson,
    });
    return;
  }

  const store = await readStore();
  store.google[stateRecord.userId] = {
    ...tokenJson,
    expiresAt: Date.now() + Number(tokenJson.expires_in || 3600) * 1000,
    connectedAt: new Date().toISOString(),
  };
  await writeStore(store);
  sendHtml(response, 200, '<h1>Google Calendar connected</h1><p>You can return to ORBIT.</p>');
}

async function connectCanvas(request, response) {
  const body = await readJsonBody(request);
  const userId = cleanId(body.userId || 'demo');
  const accessToken = String(body.accessToken || '').trim();
  if (!accessToken) {
    sendJson(response, 400, {
      error: 'missing_canvas_access_token',
      message: 'Provide a Canvas accessToken.',
    });
    return;
  }

  const store = await readStore();
  store.canvas[userId] = {
    baseUrl: String(body.baseUrl || canvasBaseUrl).replace(/\/$/, ''),
    accessToken,
    connectedAt: new Date().toISOString(),
  };
  await writeStore(store);
  sendJson(response, 200, {
    ok: true,
    userId,
    baseUrl: store.canvas[userId].baseUrl,
  });
}

async function studentSnapshot(url, response) {
  const store = await readStore();
  const userId = userIdFrom(url);
  const taskText = url.searchParams.get('taskText') || '';
  const preferenceTags = (url.searchParams.get('preferenceTags') || '')
    .split(',')
    .map((tag) => tag.trim().toLowerCase())
    .filter(Boolean);
  const sourceNotes = [];

  const [assignments, calendarEvents, routes, places] = await Promise.all([
    fetchCanvasAssignments(store.canvas[userId], sourceNotes),
    fetchGoogleCalendarEvents(store, userId, sourceNotes),
    fetchCampusRoutes(sourceNotes),
    fetchCampusPlaces(taskText, preferenceTags, sourceNotes),
  ]);

  sendJson(response, 200, {
    fetchedAt: new Date().toISOString(),
    assignments,
    calendarEvents,
    routes,
    places,
    sourceNotes,
  });
}

async function fetchCanvasAssignments(canvas, sourceNotes) {
  if (!canvas?.accessToken) {
    sourceNotes.push('Canvas proxy token not connected.');
    return [];
  }

  try {
    const coursesUrl = new URL('/api/v1/courses', canvas.baseUrl);
    coursesUrl.searchParams.set('enrollment_state', 'active');
    coursesUrl.searchParams.set('per_page', '50');
    const courses = await fetchJson(coursesUrl, {
      Authorization: `Bearer ${canvas.accessToken}`,
      Accept: 'application/json',
    });
    const assignments = [];
    for (const course of Array.isArray(courses) ? courses.slice(0, 8) : []) {
      if (!course?.id) continue;
      const assignmentsUrl = new URL(
        `/api/v1/courses/${course.id}/assignments`,
        canvas.baseUrl,
      );
      assignmentsUrl.searchParams.set('bucket', 'upcoming');
      assignmentsUrl.searchParams.set('order_by', 'due_at');
      assignmentsUrl.searchParams.set('per_page', '50');
      const items = await fetchJson(assignmentsUrl, {
        Authorization: `Bearer ${canvas.accessToken}`,
        Accept: 'application/json',
      });
      for (const item of Array.isArray(items) ? items : []) {
        assignments.push({
          id: String(item.id || ''),
          courseId: String(course.id),
          courseName: course.name || null,
          name: item.name || 'Untitled assignment',
          dueAt: item.due_at || null,
          pointsPossible: item.points_possible ?? null,
          htmlUrl: item.html_url || null,
        });
      }
    }
    assignments.sort((left, right) => {
      if (!left.dueAt && !right.dueAt) return left.name.localeCompare(right.name);
      if (!left.dueAt) return 1;
      if (!right.dueAt) return -1;
      return new Date(left.dueAt) - new Date(right.dueAt);
    });
    sourceNotes.push('Canvas loaded through the local student data proxy.');
    return assignments.slice(0, 40);
  } catch (error) {
    sourceNotes.push(`Canvas proxy fetch failed: ${messageOf(error)}`);
    return [];
  }
}

async function fetchGoogleCalendarEvents(store, userId, sourceNotes) {
  const token = await googleAccessToken(store, userId, sourceNotes);
  if (!token) return [];

  try {
    const now = new Date();
    const max = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    const eventsUrl = new URL(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events',
    );
    eventsUrl.searchParams.set('singleEvents', 'true');
    eventsUrl.searchParams.set('orderBy', 'startTime');
    eventsUrl.searchParams.set('timeMin', now.toISOString());
    eventsUrl.searchParams.set('timeMax', max.toISOString());
    eventsUrl.searchParams.set('maxResults', '40');
    const decoded = await fetchJson(eventsUrl, {
      Authorization: `Bearer ${token}`,
      Accept: 'application/json',
    });
    sourceNotes.push('Google Calendar loaded through the local student data proxy.');
    return (decoded.items || []).map((item) => ({
      id: String(item.id || ''),
      title: item.summary || 'Busy',
      start: item.start?.dateTime || item.start?.date || null,
      end: item.end?.dateTime || item.end?.date || null,
      location: item.location || null,
    }));
  } catch (error) {
    sourceNotes.push(`Google Calendar proxy fetch failed: ${messageOf(error)}`);
    return [];
  }
}

async function googleAccessToken(store, userId, sourceNotes) {
  const record = store.google[userId];
  if (!record?.access_token) {
    sourceNotes.push('Google Calendar proxy token not connected.');
    return null;
  }
  if (Date.now() < Number(record.expiresAt || 0) - 60_000) {
    return record.access_token;
  }
  if (!record.refresh_token || !hasGoogleOAuthConfig()) {
    sourceNotes.push('Google Calendar token expired and cannot be refreshed.');
    return null;
  }

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: process.env.GOOGLE_CLIENT_ID,
      client_secret: process.env.GOOGLE_CLIENT_SECRET,
      refresh_token: record.refresh_token,
      grant_type: 'refresh_token',
    }),
  });
  const tokenJson = await tokenResponse.json();
  if (!tokenResponse.ok) {
    sourceNotes.push('Google Calendar token refresh failed.');
    return null;
  }
  store.google[userId] = {
    ...record,
    ...tokenJson,
    refresh_token: tokenJson.refresh_token || record.refresh_token,
    expiresAt: Date.now() + Number(tokenJson.expires_in || 3600) * 1000,
  };
  await writeStore(store);
  return store.google[userId].access_token;
}

async function fetchCampusRoutes(sourceNotes) {
  const key = process.env.GOOGLE_MAPS_API_KEY;
  if (!key) {
    sourceNotes.push('Google Routes proxy key not configured.');
    return [];
  }
  try {
    const decoded = await fetchJson(
      'https://routes.googleapis.com/directions/v2:computeRoutes',
      {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': key,
        'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters',
      },
      {
        origin: { address: campusRouteOrigin },
        destination: { address: campusRouteDestination },
        travelMode: 'WALK',
        languageCode: 'en-US',
        units: 'IMPERIAL',
      },
    );
    const first = decoded.routes?.[0];
    if (!first) return [];
    sourceNotes.push('Google Routes loaded through the local student data proxy.');
    return [
      {
        origin: campusRouteOrigin,
        destination: campusRouteDestination,
        travelMode: 'walk',
        duration: first.duration || null,
        distanceMeters: first.distanceMeters || null,
      },
    ];
  } catch (error) {
    sourceNotes.push(`Google Routes proxy fetch failed: ${messageOf(error)}`);
    return [];
  }
}

async function fetchCampusPlaces(taskText, preferenceTags, sourceNotes) {
  const key = process.env.GOOGLE_MAPS_API_KEY;
  if (!key) {
    sourceNotes.push('Google Places proxy key not configured.');
    return [];
  }
  const task = taskText.toLowerCase();
  const wantsPlace =
    /food|lunch|dinner|coffee|study|library|route|place|near|vegan/.test(task);
  if (!wantsPlace) {
    sourceNotes.push('Google Places skipped because the task is not location-based.');
    return [];
  }
  const vegan = preferenceTags.includes('vegan') || task.includes('vegan');
  const query = vegan
    ? 'vegan food near University of Maryland College Park'
    : `${taskText || 'student resources'} near University of Maryland College Park`;
  try {
    const decoded = await fetchJson(
      'https://places.googleapis.com/v1/places:searchText',
      {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': key,
        'X-Goog-FieldMask':
          'places.displayName,places.formattedAddress,places.googleMapsUri,places.servesVegetarianFood',
      },
      {
        textQuery: query,
        maxResultCount: 5,
        languageCode: 'en',
      },
    );
    sourceNotes.push('Google Places loaded through the local student data proxy.');
    return (decoded.places || []).map((place) => ({
      name: place.displayName?.text || 'Campus place',
      formattedAddress: place.formattedAddress || 'College Park, MD',
      reason: `Matched proxy query: ${query}`,
      googleMapsUri: place.googleMapsUri || null,
      servesVegetarianFood: place.servesVegetarianFood ?? null,
    }));
  } catch (error) {
    sourceNotes.push(`Google Places proxy fetch failed: ${messageOf(error)}`);
    return [];
  }
}

async function fetchJson(url, headers, body = null) {
  const response = await fetch(url, {
    method: body ? 'POST' : 'GET',
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  const decoded = text ? JSON.parse(text) : null;
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${text.slice(0, 180)}`);
  }
  return decoded;
}

async function readStore() {
  try {
    const text = await readFile(storePath, 'utf8');
    const parsed = JSON.parse(text);
    return {
      canvas: parsed.canvas || {},
      google: parsed.google || {},
    };
  } catch {
    return { canvas: {}, google: {} };
  }
}

async function writeStore(store) {
  await mkdir(dataDir, { recursive: true });
  await writeFile(storePath, JSON.stringify(store, null, 2));
}

async function readJsonBody(request) {
  const chunks = [];
  for await (const chunk of request) chunks.push(chunk);
  const text = Buffer.concat(chunks).toString('utf8').trim();
  return text ? JSON.parse(text) : {};
}

function userIdFrom(url) {
  return cleanId(url.searchParams.get('userId') || 'demo');
}

function cleanId(value) {
  return String(value).replace(/[^a-zA-Z0-9_.@-]/g, '').slice(0, 80) || 'demo';
}

function hasGoogleOAuthConfig() {
  return Boolean(
    process.env.GOOGLE_CLIENT_ID &&
      process.env.GOOGLE_CLIENT_SECRET &&
      googleRedirectUri,
  );
}

function sendCors(response, statusCode) {
  response.writeHead(statusCode, {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  });
  response.end();
}

function sendJson(response, statusCode, body) {
  response.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
  });
  response.end(JSON.stringify(body, null, 2));
}

function sendHtml(response, statusCode, html) {
  response.writeHead(statusCode, {
    'Content-Type': 'text/html; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
  });
  response.end(`<!doctype html><html><body>${html}</body></html>`);
}

function messageOf(error) {
  return error instanceof Error ? error.message : String(error);
}
