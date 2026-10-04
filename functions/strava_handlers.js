const STRAVA_CLIENT_ID = '214695';
const STRAVA_TOKEN_URL = 'https://www.strava.com/oauth/token';
const APP_BASE_URL = 'https://simon-franke.github.io/bikesetupapp/';

// The refresh token is a bearer credential. Never log it or include it in URLs.
function createStravaHandlers({ clientSecret, fetchToken = fetch }) {
  async function exchange(parameters) {
    const response = await fetchToken(STRAVA_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ client_id: STRAVA_CLIENT_ID,
        client_secret: clientSecret(), ...parameters }).toString(),
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) throw new Error(`Strava token exchange failed: ${response.status}`);
    const json = await response.json();
    if (typeof json.access_token !== 'string' || !json.access_token ||
        typeof json.refresh_token !== 'string' || !json.refresh_token ||
        !Number.isInteger(json.expires_at) || json.expires_at <= 0) {
      throw new Error('Invalid Strava token response');
    }
    return json;
  }

  function redirect(res, state, payload) {
    const url = new URL(APP_BASE_URL);
    url.searchParams.set('strava_auth', payload);
    url.searchParams.set('strava_state', state);
    res.set('Cache-Control', 'no-store');
    res.set('Referrer-Policy', 'no-referrer');
    res.redirect(302, url.toString());
  }

  return {
    async callback(req, res) {
      const { code, state, scope, error } = req.query;
      if (req.method !== 'GET') return res.status(405).send('Method not allowed');
      if (typeof state !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(state)) {
        return res.status(400).send('Invalid OAuth state');
      }
      if (error === 'access_denied') return redirect(res, state, 'error');
      if (typeof code !== 'string' || !code) {
        return res.status(400).send('Missing required parameter: code');
      }
      try {
        const json = await exchange({ code, grant_type: 'authorization_code' });
        // Granted scopes arrive on the OAuth redirect, not reliably in tokens.
        json.scope = typeof scope === 'string' ? scope : '';
        redirect(res, state, Buffer.from(JSON.stringify(json)).toString('base64url'));
      } catch (_) {
        redirect(res, state, 'error');
      }
    },
    async refresh(req, res) {
      res.set('Cache-Control', 'no-store');
      if (req.method !== 'POST') return res.status(405).send('Method not allowed');
      const refreshToken = req.body?.refresh_token;
      if (typeof refreshToken !== 'string' || !refreshToken || refreshToken.length > 2048) {
        return res.status(400).json({ error: 'Invalid refresh token' });
      }
      try {
        const json = await exchange({ refresh_token: refreshToken,
          grant_type: 'refresh_token' });
        res.json({ access_token: json.access_token, refresh_token: json.refresh_token,
          expires_at: json.expires_at });
      } catch (_) {
        res.status(502).json({ error: 'Could not renew Strava connection' });
      }
    },
  };
}
module.exports = { createStravaHandlers };
