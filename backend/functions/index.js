const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { createStravaHandlers } = require('./strava_handlers');

const stravaClientSecret = defineSecret('STRAVA_CLIENT_SECRET');
const handlers = createStravaHandlers({ clientSecret: () => stravaClientSecret.value() });
const options = { region: 'us-central1', secrets: [stravaClientSecret] };

exports.stravaRefresh = onRequest(options, handlers.refresh);

exports.stravaExchange = onRequest(options, handlers.nativeExchange);

const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { createAccountDeletionHandler } = require('./account_handlers');

initializeApp();

exports.deleteAccount = onRequest({
  region: 'us-central1',
  timeoutSeconds: 540,
  cors: ['https://simon-franke.github.io'],
}, createAccountDeletionHandler({ auth: getAuth(), firestore: getFirestore() }));
