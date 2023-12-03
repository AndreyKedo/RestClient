import 'dart:typed_data';

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
}

final class BytesBody extends RequestBody {
  final Uint8List value;
  const BytesBody(this.value);

  @override
  String toString() => 'BytesBody($value)';
}

final class JsonMapBody extends RequestBody {
  final Map<String, Object?> value;
  const JsonMapBody(this.value);

  @override
  String toString() => 'JsonMapBody($value)';
}
