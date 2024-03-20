/*
* body.dart
* Request body.
* Dashkevich Andrey <dashkevich@ittest-team.ru>, 20 March 2024
*/

import 'dart:typed_data';

import 'package:collection/collection.dart';

sealed class RequestBody {
  const RequestBody();

  const factory RequestBody.bytes(Uint8List value) = BytesBody;
  const factory RequestBody.map(Map<String, Object?> value) = JsonMapBody;
  const factory RequestBody.string(String value) = StringBody;

  @override
  String toString() => 'RequestBody';
}

final class StringBody extends RequestBody {
  final String value;
  const StringBody(this.value);

  @override
  String toString() => 'BytesBody($value)';

  @override
  int get hashCode => Object.hash(value, toString());

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StringBody && runtimeType == other.runtimeType && value == other.value;
}

final class BytesBody extends RequestBody {
  final Uint8List value;
  const BytesBody(this.value);

  @override
  String toString() => 'BytesBody($value)';

  @override
  int get hashCode => Object.hash(value, toString());

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StringBody && runtimeType == other.runtimeType && value == other.value;
}

final class JsonMapBody extends RequestBody {
  final Map<String, Object?> value;
  const JsonMapBody(this.value);

  @override
  String toString() => 'JsonMapBody($value)';

  static const _equality = DeepCollectionEquality();

  @override
  int get hashCode => Object.hash(value, toString());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringBody && runtimeType == other.runtimeType && _equality.equals(value, other.value);
}
