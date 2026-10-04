// Non-web platforms use the custom-scheme OAuth flow.
Future<bool> handleStravaWebCallback({required String? userId}) async => false;
void rememberStravaWebAuth({required String userId, required String state}) {}
void clearPendingStravaWebAuth() {}
void openStravaAuthInTab(String url) {}
