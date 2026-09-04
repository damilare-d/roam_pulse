/// A signed-in demo session. Deliberately minimal — the only thing that
/// matters today is "does a session exist." A JWT-backed session would
/// add an expiry and a refresh token here without changing
/// [AuthRepository]'s method signatures.
class AuthSession {
  const AuthSession({required this.sessionToken});

  final String sessionToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(sessionToken: json['sessionToken'] as String);
  }
}
