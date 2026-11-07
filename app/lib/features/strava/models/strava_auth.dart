class StravaAuth {
  final String accessToken;
  final String refreshToken;
  final int expiresAt;
  final int athleteId;
  final List<String> scopes;

  const StravaAuth(
      {required this.accessToken,
      required this.refreshToken,
      required this.expiresAt,
      required this.athleteId,
      this.scopes = const []});

  static List<String> parseScopes(String? value) =>
      value?.split(RegExp(r'[,\s]+')).where((s) => s.isNotEmpty).toList() ?? [];

  factory StravaAuth.fromTokenResponse(Map<String, dynamic> json,
      {int? athleteId, List<String> scopes = const []}) {
    final access = json['access_token'] as String?;
    final refresh = json['refresh_token'] as String?;
    final expires = json['expires_at'] as int?;
    final athlete =
        athleteId ?? (json['athlete'] as Map<String, dynamic>?)?['id'] as int?;
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty ||
        expires == null ||
        expires <= 0 ||
        athlete == null ||
        athlete <= 0) {
      throw const FormatException('Invalid Strava credentials');
    }
    return StravaAuth(
        accessToken: access,
        refreshToken: refresh,
        expiresAt: expires,
        athleteId: athlete,
        scopes: List.unmodifiable(scopes));
  }

  factory StravaAuth.fromJson(Map<String, dynamic> json) => StravaAuth(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresAt: json['expiresAt'] as int? ?? 0,
      athleteId: json['athleteId'] as int? ?? 0,
      scopes: List<String>.from(json['scopes'] as List? ?? const []));

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt,
        'athleteId': athleteId,
        'scopes': scopes
      };

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiresAt;
}
