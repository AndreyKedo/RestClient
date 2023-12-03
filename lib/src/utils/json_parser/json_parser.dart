import 'dart:convert';

import 'stub.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'web.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) 'io.dart';

abstract class JsonParser with SyncJsonCodecMixin {
  factory JsonParser() => getParser();

  static const JsonCodec jsonCodec = JsonCodec(reviver: _reviver);

  static Object? _reviver(Object? key, Object? value) {
    if (value is List<dynamic>) return value.cast<Object>();
    if (value is Map<String, Object?>) return value.cast<String, Object?>();
    return value;
  }

  Future<Map<String, Object?>> strDecodeJson(String data, {bool useIsolate = false, String? debugPrint});

  Future<String> objEncode(Map<String, Object?> data, {bool useIsolate = false, String? debugPrint});
}

mixin class SyncJsonCodecMixin {
  String objEncodeSync(Map<String, Object?> obj) => JsonParser.jsonCodec.encode(obj);

  Map<String, Object?> strDecodeJsonSync(String json) => JsonParser.jsonCodec.decode(json) as Map<String, Object?>;
}
