final class JwtPayload {
  const JwtPayload(this.issueAt, this.expirationTime);

  final num issueAt;
  final num expirationTime;

  factory JwtPayload.fromJson(Map<String, Object?> json) {
    if (json case {'iat': final num iat, 'exp': final num exp}) {
      return JwtPayload(iat, exp);
    }
    throw const FormatException(' Error occurred during decoding JWTHeader', 'JwtDecoder');
  }

  @override
  int get hashCode => Object.hash(issueAt, expirationTime);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JwtPayload &&
          runtimeType == other.runtimeType &&
          issueAt == other.issueAt &&
          expirationTime == other.expirationTime;
}
