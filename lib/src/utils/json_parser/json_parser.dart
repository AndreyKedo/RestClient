import 'dart:convert';

import 'vm.dart' if (dart.library.js_interop) 'js.dart';

/// {@template json_parser}
/// Json parser.
/// {@endtemplate}
abstract class JsonParser {
  factory JsonParser() => getParser();

  /// Default codec.
  static const JsonCodec jsonCodec = JsonCodec(reviver: _reviver);

  static Object? _reviver(Object? key, Object? value) {
    if (value is List<dynamic>) return List<Object>.from(value);
    if (value is Map<String, dynamic>) return Map<String, Object?>.from(value);
    return value;
  }

  /// Decode json string to [Map]
  /// [useIsolate] set true if you want use isolate.
  Future<Map<String, Object?>> strDecodeJson(String data, {bool useIsolate = false, String? debugPrint});

  /// Encode [Map] to JSON string.
  /// [useIsolate] set true if you want use isolate.
  Future<String> objEncode(Map<String, Object?> data, {bool useIsolate = false, String? debugPrint});
}
