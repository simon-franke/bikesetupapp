const STRAVA_CLIENT_ID = '214695';
const STRAVA_TOKEN_URL = 'https://www.strava.com/oauth/token';

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

  return {
    async nativeExchange(req, res) {
      res.set('Cache-Control', 'no-store');
      if (req.method !== 'POST') return res.status(405).send('Method not allowed');
      const code = req.body?.code;
      if (typeof code !== 'string' || !code.trim() || code.length > 2048) {
        return res.status(400).json({ error: 'Invalid authorization code' });
      }
      try {
        const json = await exchange({ code, grant_type: 'authorization_code' });
        if (!Number.isInteger(json.athlete?.id) || json.athlete.id <= 0) {
          throw new Error('Invalid athlete');
        }
        res.json({ access_token: json.access_token, refresh_token: json.refresh_token,
          expires_at: json.expires_at, athlete: { id: json.athlete.id } });
      } catch (_) {
        res.status(502).json({ error: 'Could not connect to Strava' });
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
