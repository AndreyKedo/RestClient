import 'dart:convert';

import '../utils/utils.dart';

part 'header.dart';
part 'jwt_decoder.dart';
part 'payload.dart';

/// {@template jwt}
/// JWT object.
/// {@endtemplate}
final class JWT {
  final JwtHeader header;
  final JwtPayload playload;

  ///Source jwt string
  final String source;

  /// {@macro jwt}
  const JWT(this.header, this.playload, this.source);

  /// {@macro jwt_decoder.decode}
  static JWT decode(String token) => JwtDecoder.decode(token);

  /// {@macro jwt_decoder.try_decode}
  static JWT? tryDecode(String token) => JwtDecoder.tryDecode(token);

  ///true - invalid
  ///false - valid
  bool get isExpired {
    return DateTime.now().isAfter(expirationDate.subtract(const Duration(minutes: 5)));
  }

  DateTime get expirationDate {
    final expirationDate =
        DateTime.fromMillisecondsSinceEpoch(0).add(Duration(seconds: playload.expirationTime.toInt()));
    return expirationDate;
  }

  Duration get tokenTime {
    final issuedAtDate = DateTime.fromMillisecondsSinceEpoch(0).add(Duration(seconds: playload.issueAt.toInt()));
    return DateTime.now().difference(issuedAtDate);
  }

  Duration get remainingTime {
    return expirationDate.difference(DateTime.now());
  }

  @override
  int get hashCode => Object.hash(header, playload);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JWT && runtimeType == other.runtimeType && header == other.header && playload == other.playload;
}
