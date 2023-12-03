import 'dart:convert';

import 'package:rest_client/src/utils/utils.dart';

import 'header.dart';
import 'jwt.dart';
import 'payload.dart';

base class JwtDecoder {
  const JwtDecoder();

  static JWT decode(String token) {
    const decoder = JwtDecoder();
    return JWT(decoder._decodeHeader(token), decoder._decodePayload(token), token);
  }

  static JWT? tryDecode(String token) {
    try {
      return decode(token);
    } catch (error) {
      return null;
    }
  }

  JwtPayload _decodePayload(String token) {
    final splitToken = token.split(".");
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
    final splitToken = token.split(".");
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

    final decodedSegment = JsonParser().strDecodeJsonSync(str);
    return decodedSegment;
  }
}
