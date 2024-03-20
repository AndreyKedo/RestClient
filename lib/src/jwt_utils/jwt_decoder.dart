part of 'jwt.dart';

/// {@template jwt_decoder}
/// JWT Decoder.
/// {@endtemplate}
base class JwtDecoder {
  /// {@macro jwt_decoder}
  const JwtDecoder();

  static const decoder = JwtDecoder();

  /// {@template jwt_decoder.decode}
  /// JWT decode from string.
  /// {@endtemplate}
  static JWT decode(String token) {
    return JWT(decoder._decodeHeader(token), decoder._decodePayload(token), token);
  }

  /// {@template jwt_decoder.try_decode}
  /// Try decode JWT from string.
  /// If decode failed to returned null.
  /// {@endtemplate}
  static JWT? tryDecode(String token) {
    try {
      return decode(token);
    } catch (error) {
      return null;
    }
  }

  JwtPayload _decodePayload(String token) {
    final splitToken = token.split('.');
    if (splitToken.length != 3) {
      throw const FormatException('Invalid token', 'JwtDecoder');
    }
    try {
      final decodedPayload = _normalizeSegment(splitToken[1]);

      return JwtPayload.fromJson(decodedPayload);
    } catch (error) {
      throw const FormatException('Invalid payload', 'JwtDecoder');
    }
  }

  JwtHeader _decodeHeader(String token) {
    final splitToken = token.split('.');
    if (splitToken.length != 3) {
      throw const FormatException('Invalid token');
    }
    try {
      final decodedHeader = _normalizeSegment(splitToken[0]);
      return JwtHeader.fromJson(decodedHeader);
    } catch (error) {
      throw const FormatException('Invalid header', 'JwtDecoder');
    }
  }

  Map<String, Object?> _normalizeSegment(String segmentBase64) {
    final normalized = base64.normalize(segmentBase64);

    final str = utf8.decode(base64.decode(normalized));

    return JsonParser.jsonCodec.decode(str) as Map<String, Object?>;
  }
}
