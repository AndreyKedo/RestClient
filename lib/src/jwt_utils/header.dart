// {
//   "typ": "JWT",
//   "alg": "HS256"
// }

final class JwtHeader {
  const JwtHeader(this.type, this.algorithm);

  final String type;

  final String algorithm;

  factory JwtHeader.fromJson(Map<String, Object?> json) {
    if (json case {'typ': final String type, 'alg': final String alg}) {
      return JwtHeader(type, alg);
    }
    throw const FormatException(' Error occurred during decoding JWTHeader', 'JwtDecoder');
  }

  @override
  int get hashCode => Object.hash(type, algorithm);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JwtHeader && runtimeType == other.runtimeType && type == other.type && algorithm == other.algorithm;
}
