class StravaAuth {
  final String accessToken;
  final String refreshToken;
  final int expiresAt;
  final int athleteId;

  const StravaAuth({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.athleteId,
  });

  factory StravaAuth.fromJson(Map<String, dynamic> json) {
    return StravaAuth(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresAt: json['expiresAt'] as int? ?? 0,
      athleteId: json['athleteId'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt,
      'athleteId': athleteId,
    };
  }

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiresAt;
}
