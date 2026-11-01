const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { createStravaHandlers } = require('./strava_handlers');

const stravaClientSecret = defineSecret('STRAVA_CLIENT_SECRET');
const handlers = createStravaHandlers({ clientSecret: () => stravaClientSecret.value() });
const options = { region: 'us-central1', secrets: [stravaClientSecret] };

exports.stravaRefresh = onRequest(options, handlers.refresh);

exports.stravaExchange = onRequest(options, handlers.nativeExchange);
