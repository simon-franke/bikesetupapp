const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createStravaHandlers } = require('./strava_handlers');
const tokens = { access_token: 'access', refresh_token: 'rotated', expires_at: 2000000000,
  athlete: { id: 42 } };
function response() {
  return { headers: {}, statusCode: 200,
    set(key, value) { this.headers[key] = value; return this; },
    status(code) { this.statusCode = code; return this; },
    send(body) { this.body = body; return this; },
    json(body) { this.body = body; return this; },
  };
}
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

test('native exchange uses server secret and exposes only required fields', async () => {
  const handlers = createStravaHandlers({ clientSecret: () => 'server-secret',
    fetchToken: async (_, request) => {
      const body = new URLSearchParams(request.body);
      assert.equal(body.get('client_secret'), 'server-secret');
      assert.equal(body.get('code'), 'one-use-code');
      assert.equal(body.get('grant_type'), 'authorization_code');
      return { ok: true, json: async () => ({ ...tokens, extra: 'private',
        athlete: { id: 42, firstname: 'Private' } }) };
    } });
  const res = response();
  await handlers.nativeExchange({ method: 'POST', body: {
    code: 'one-use-code', client_secret: 'untrusted', grant_type: 'refresh_token',
  } }, res);
  assert.deepEqual(res.body, tokens);
  assert.equal(res.headers['Cache-Control'], 'no-store');
});
test('native exchange rejects malformed requests without contacting Strava', async () => {
  let calls = 0;
  const handlers = createStravaHandlers({ clientSecret: () => 'secret',
    fetchToken: async () => { calls++; } });
  for (const req of [{ method: 'GET' }, { method: 'POST', body: {} },
    ...['', ' ', ['code'], 'x'.repeat(2049)].map(code => ({ method: 'POST', body: { code } }))]) {
    const res = response();
    await handlers.nativeExchange(req, res);
    assert.ok([400, 405].includes(res.statusCode));
  }
  assert.equal(calls, 0);
});
test('native exchange redacts upstream errors and rejects invalid tokens', async () => {
  for (const fetchToken of [
    async () => { throw new Error('sensitive secret'); },
    async () => ({ ok: false, status: 401 }),
    async () => ({ ok: true, json: async () => ({ ...tokens, access_token: '' }) }),
    async () => ({ ok: true, json: async () => ({ ...tokens, athlete: {} }) }),
  ]) {
    const handlers = createStravaHandlers({ clientSecret: () => 'secret', fetchToken });
    const res = response();
    await handlers.nativeExchange({ method: 'POST', body: { code: 'code' } }, res);
    assert.equal(res.statusCode, 502);
    assert.deepEqual(res.body, { error: 'Could not connect to Strava' });
  }
});
