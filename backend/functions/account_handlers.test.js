const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createAccountDeletionHandler } = require('./account_handlers');
function fixture({ token = { uid: 'owner', auth_time: 1000 }, invalid = false, fail = false } = {}) {
  const calls = [];
  const handler = createAccountDeletionHandler({ now: () => 1100 * 1000,
    auth: { async verifyIdToken(value, checkRevoked) {
      assert.equal(value, 'verified-token'); assert.equal(checkRevoked, true);
      if (invalid) throw Error('private token details'); return token;
    }, async deleteUser(uid) { calls.push(['auth', uid]); } },
    firestore: { doc(path) { return { path, async set(value) { calls.push(['marker', path, value]); } }; },
      async recursiveDelete(ref) { calls.push(['data', ref.path]); if (fail) throw Error('private data'); } },
    logError: () => {},
  });
  const req = { method: 'POST', headers: { authorization: 'Bearer verified-token' }, body: { uid: 'victim', path: '/' } };
  const res = { statusCode: 200, set() {}, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } };
  return { calls, handler, req, res };
}
test('deletion uses verified ownership and blocks stale writes before recursive deletion', async () => {
  const f = fixture(); await f.handler(f.req, f.res);
  assert.equal(f.res.statusCode, 200);
  assert.deepEqual(f.calls.map(c => c.slice(0, 2)), [['marker', 'AccountDeletions/owner'], ['data', 'UserBikeSetup/owner'], ['auth', 'owner']]);
});
test('missing or invalid auth never deletes data', async () => {
  for (const invalid of [false, true]) {
    const f = fixture({ invalid }); if (!invalid) f.req.headers = {};
    await f.handler(f.req, f.res); assert.equal(f.res.statusCode, 401); assert.equal(f.calls.length, 0);
    assert.deepEqual(f.res.body, { error: 'unauthenticated' });
  }
});
test('stale, future, missing auth time and invalid UID are rejected', async () => {
  for (const token of [{uid:'owner',auth_time:1}, {uid:'owner',auth_time:99999}, {uid:'owner'}, {uid:'a/b',auth_time:1000}]) {
    const f = fixture({ token }); await f.handler(f.req, f.res); assert.equal(f.res.statusCode,401); assert.equal(f.calls.length,0);
  }
});
test('data deletion failure retains auth identity for retry and does not report success', async () => {
  const f = fixture({ fail: true }); await f.handler(f.req, f.res);
  assert.equal(f.res.statusCode,500); assert.deepEqual(f.res.body,{error:'deletion-failed'});
  assert.equal(f.calls.some(c => c[0] === 'auth'),false);
});
test('GET cannot delete an account', async () => {
  const f = fixture(); f.req.method = 'GET'; await f.handler(f.req, f.res);
  assert.equal(f.res.statusCode,405); assert.equal(f.calls.length,0);
});
