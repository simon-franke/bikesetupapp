const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createStravaHandlers } = require('./strava_handlers');
const state = 'x'.repeat(43);
const tokens = { access_token: 'access', refresh_token: 'rotated', expires_at: 2000000000,
  athlete: { id: 42 } };
function response() {
  return { headers: {}, statusCode: 200,
    set(key, value) { this.headers[key] = value; return this; },
    status(code) { this.statusCode = code; return this; },
    send(body) { this.body = body; return this; },
    json(body) { this.body = body; return this; },
    redirect(code, url) { this.statusCode = code; this.url = new URL(url); },
  };
}
test('callback forwards state and granted scopes', async () => {
  const handlers = createStravaHandlers({ clientSecret: () => 'secret',
    fetchToken: async (_, request) => {
      const body = new URLSearchParams(request.body);
      assert.equal(body.get('client_secret'), 'secret');
      assert.equal(body.get('code'), 'code');
      return { ok: true, json: async () => ({ ...tokens }) };
    } });
  const res = response();
  await handlers.callback({ method: 'GET', query: { code: 'code', state,
    scope: 'activity:read_all' } }, res);
  assert.equal(res.url.searchParams.get('strava_state'), state);
  const payload = JSON.parse(Buffer.from(res.url.searchParams.get('strava_auth'), 'base64url'));
  assert.equal(payload.scope, 'activity:read_all');
  assert.equal(res.headers['Cache-Control'], 'no-store');
});
test('callback rejects missing state before exchanging tokens', async () => {
  let calls = 0;
  const handlers = createStravaHandlers({ clientSecret: () => 'secret',
    fetchToken: async () => { calls++; } });
  const res = response();
  await handlers.callback({ method: 'GET', query: { code: 'code' } }, res);
  assert.equal(res.statusCode, 400);
  assert.equal(calls, 0);
});
test('denial keeps state so the client can consume its pending request', async () => {
  const handlers = createStravaHandlers({ clientSecret: () => 'secret' });
  const res = response();
  await handlers.callback({ method: 'GET', query: { state, error: 'access_denied' } }, res);
  assert.equal(res.url.searchParams.get('strava_auth'), 'error');
  assert.equal(res.url.searchParams.get('strava_state'), state);
});
test('refresh exchanges server-side and returns only token fields', async () => {
  const handlers = createStravaHandlers({ clientSecret: () => 'secret',
    fetchToken: async (_, request) => {
      const body = new URLSearchParams(request.body);
      assert.equal(body.get('grant_type'), 'refresh_token');
      assert.equal(body.get('refresh_token'), 'old');
      assert.equal(body.get('client_secret'), 'secret');
      return { ok: true, json: async () => tokens };
    } });
  const res = response();
  await handlers.refresh({ method: 'POST', body: { refresh_token: 'old' } }, res);
  assert.deepEqual(res.body, { access_token: 'access', refresh_token: 'rotated',
    expires_at: 2000000000 });
});
test('refresh rejects invalid input and redacts upstream errors', async () => {
  const handlers = createStravaHandlers({ clientSecret: () => 'secret',
    fetchToken: async () => { throw new Error('sensitive token data'); } });
  for (const req of [{ method: 'GET' }, { method: 'POST', body: {} },
    { method: 'POST', body: { refresh_token: ['invalid'] } }]) {
    const res = response();
    await handlers.refresh(req, res);
    assert.ok([400, 405].includes(res.statusCode));
  }
  const res = response();
  await handlers.refresh({ method: 'POST', body: { refresh_token: 'old' } }, res);
  assert.equal(res.statusCode, 502);
  assert.ok(!JSON.stringify(res.body).includes('sensitive'));
});
