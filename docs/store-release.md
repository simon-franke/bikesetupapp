# Store submission prerequisites

The simplified account flow is implemented locally. Store approval is not guaranteed, and this is not yet a submission-ready release.

Before submitting:

- Choose the individual publisher's legal name and a public support email. Complete the privacy policy in `lib/features/auth/ui/privacy_page.dart`, including contact details, applicable rights and the actual retention/backup practices. The current text describes the implemented data flow; it is not a finalized legal policy.
- Deploy the `deleteAccount` Firebase Function and the updated Firestore rules together. Deletion requires a fresh sign-in, recursively deletes the user's Firestore tree, then removes Firebase Authentication. A server-only deletion marker prevents old/offline clients from recreating records. Do not delete these markers while corresponding tokens could still be valid.
- Publish a public privacy policy and an account-deletion request page separately from the native app. This repository does not include a web app or a hosted deletion request flow. Enter verified URLs in the store consoles.
- Verify Firebase Apple and Google providers, iOS Sign in with Apple capability, Android signing fingerprints and OAuth clients,. Apple code-flow credentials must be configured for token revocation. Test sign-in, cancellation, password reset, account creation and deletion using dedicated real accounts on iOS and Android. No live account was deleted during development.
- Complete Apple's App Privacy and Google's Data safety declarations for the actual Firebase/Strava data flows. Supply reviewer access to account-based functionality. Complete the store's required testing and signing steps.

Existing anonymous users retain access to their data and can save their account from Settings. New users are no longer offered an anonymous session. Strava remains optional and is configured only in Settings.

Official requirements:
- https://developer.apple.com/app-store/review/guidelines/ (login services, privacy, account deletion)
- https://developer.apple.com/support/offering-account-deletion-in-your-app/
- https://support.google.com/googleplay/android-developer/answer/13327111 (in-app and web deletion)
- https://support.google.com/googleplay/android-developer/answer/10144311 (privacy and user data)
