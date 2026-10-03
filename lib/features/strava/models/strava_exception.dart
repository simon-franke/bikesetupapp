/// Thrown when the stored token lacks the `activity:read` scope (HTTP 403).
/// The user needs to re-connect Strava to grant the new permission.
class StravaInsufficientScopeException implements Exception {
  const StravaInsufficientScopeException();
}

/// A safe, actionable error that can be shown without logging credentials.
class StravaApiException implements Exception {
  final String message;
  final int? statusCode;
  const StravaApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
