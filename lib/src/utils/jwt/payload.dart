part of 'jwt.dart';

/// {@nodoc}
final class JwtPayload {
  const JwtPayload(this.issueAt, this.expirationTime, this.data);

  final num issueAt;
  final num expirationTime;
  final Map<String, Object?> data;

  factory JwtPayload.fromJson(final Map<String, Object?> json) {
    try {
      final {'iat': iat as int, 'exp': exp as int} = json;
      final copyJson = Map.of(json)..remove('iat')..remove('exp');
      return JwtPayload(iat, exp, copyJson);
    } catch (e, stackTrace) {
      return Error.throwWithStackTrace(const FormatException(' Error occurred during decoding JWTHeader', 'JwtDecoder'), stackTrace);
    }
   
  }

  @override
  int get hashCode => Object.hash(issueAt, expirationTime);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JwtPayload &&
          runtimeType == other.runtimeType &&
          issueAt == other.issueAt &&
          expirationTime == other.expirationTime &&
          data == other.data;
}
