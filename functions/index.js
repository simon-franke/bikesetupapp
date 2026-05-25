const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');

const stravaClientSecret = defineSecret('STRAVA_CLIENT_SECRET');

// Client ID is not secret — it's already bundled in the web app's .env asset.
const STRAVA_CLIENT_ID = '214695';
const STRAVA_TOKEN_URL = 'https://www.strava.com/oauth/token';
const APP_BASE_URL = 'https://simon-franke.github.io/bikesetupapp/';

/**
 * Strava OAuth callback proxy.
 *
 * Strava redirects here after the user authorises the app:
 *   GET /stravaCallback?code=<authorization_code>
 *
 * This function:
 *   1. Exchanges the code for access + refresh tokens (keeping the client
 *      secret server-side, never in the browser bundle).
 *   2. Base64url-encodes the raw Strava token response.
 *   3. Redirects the browser back to the Flutter web app with the encoded
 *      payload as a query param so the app can save it to secure storage.
 *
 * On any error the redirect target has ?strava_auth=error so the Flutter
 * app can surface a user-facing message.
 */
exports.stravaCallback = onRequest(
  { region: 'us-central1', secrets: [stravaClientSecret] },
  async (req, res) => {
    const code = req.query.code;

    // User denied access on Strava's page.
    if (req.query.error === 'access_denied') {
      res.redirect(302, `${APP_BASE_URL}?strava_auth=error`);
      return;
    }

    if (!code) {
      res.status(400).send('Missing required parameter: code');
      return;
    }

    try {
      const body = new URLSearchParams({
        client_id: STRAVA_CLIENT_ID,
        client_secret: stravaClientSecret.value(),
        code,
        grant_type: 'authorization_code',
      });

      const tokenRes = await fetch(STRAVA_TOKEN_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body.toString(),
      });

      if (!tokenRes.ok) {
        console.error('Strava token exchange failed:', tokenRes.status, await tokenRes.text());
        res.redirect(302, `${APP_BASE_URL}?strava_auth=error`);
        return;
      }

      const json = await tokenRes.json();

      // base64url encoding avoids +/= characters that need URL-encoding.
      // Node 16+ supports 'base64url' directly on Buffer.
      const encoded = Buffer.from(JSON.stringify(json)).toString('base64url');

      res.redirect(302, `${APP_BASE_URL}?strava_auth=${encoded}`);
    } catch (e) {
      console.error('stravaCallback error:', e);
      res.redirect(302, `${APP_BASE_URL}?strava_auth=error`);
    }
  },
);
