import 'dart:convert';

import 'io.dart' if (dart.library.html) 'web.dart';

abstract class JsonParser with JsonCodecMixin {
  factory JsonParser() => getParser();

  static const JsonCodec jsonCodec = JsonCodec(reviver: _reviver);

  static Object? _reviver(Object? key, Object? value) {
    if (value is List<dynamic>) return value.cast<Object>();
    if (value is Map<String, Object?>) return value.cast<String, Object?>();
    return value;
  }

  Future<Map<String, Object?>> decode(String data, {String? debugPrint});

  Future<String> encode(Map<String, Object?> data, {String? debugPrint});
}

mixin class JsonCodecMixin {
  String encodeObject(Map<String, Object?> obj) => JsonParser.jsonCodec.encode(obj);

  Map<String, Object?> decodeString(String json) => JsonParser.jsonCodec.decode(json) as Map<String, Object?>;
}
