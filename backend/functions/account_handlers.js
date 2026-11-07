/** Only the verified token's owner can delete an account. No client paths/UIDs. */
function createAccountDeletionHandler({
  auth,
  firestore,
  now = () => Date.now(),
  logError = console.error,
}) {
  return async (req, res) => {
    res.set('Cache-Control', 'no-store');
    if (req.method !== 'POST') return res.status(405).json({ error: 'method-not-allowed' });

    const match = /^Bearer (\S+)$/.exec(req.headers.authorization || '');
    if (!match) return res.status(401).json({ error: 'unauthenticated' });

    let token;
    try {
      token = await auth.verifyIdToken(match[1], true);
    } catch (_) {
      return res.status(401).json({ error: 'unauthenticated' });
    }

    if (
      !token.uid ||
      token.uid.includes('/') ||
      !Number.isFinite(token.auth_time) ||
      (token.firebase?.sign_in_provider !== 'anonymous' &&
        now() / 1000 - token.auth_time > 300) ||
      token.auth_time > now() / 1000 + 60
    ) {
      return res.status(401).json({ error: 'reauthentication-required' });
    }

    try {
      // Keep this minimal tombstone: existing ID tokens/offline clients must not
      // recreate data after deletion. Firestore rules deny writes once it exists.
      await firestore.doc(`AccountDeletions/${token.uid}`).set({ requestedAt: new Date(now()) });
      await firestore.recursiveDelete(firestore.doc(`UserBikeSetup/${token.uid}`));
      await auth.deleteUser(token.uid);

      return res.status(200).json({ deleted: true });
    } catch (error) {
      // No tokens, email addresses, or raw upstream responses in logs/responses.
      logError('Account deletion failed', { code: error.code || 'unknown' });
      return res.status(500).json({ error: 'deletion-failed' });
    }
  };
}

module.exports = { createAccountDeletionHandler };
