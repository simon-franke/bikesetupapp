// Stub implementation for non-web platforms.
// On mobile/desktop, there is no URL bar to inspect and no browser tab
// navigation — both functions are no-ops.

Future<bool> handleStravaWebCallback() async => false;

// ignore: avoid_print
void openStravaAuthInTab(String url) {}
