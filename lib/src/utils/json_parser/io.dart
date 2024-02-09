import 'dart:async';
import 'dart:isolate';

import 'json_parser.dart';

JsonParser getParser() => IOJsonParser();

final class IOJsonParser with JsonCodecMixin implements JsonParser {
  static const IOJsonParser _internalSingleton = IOJsonParser._internal();
  factory IOJsonParser() => _internalSingleton;

  const IOJsonParser._internal();

  @override
  @pragma('vm:prefer-inline')
  Future<Map<String, Object?>> decode(String data, {String? debugPrint}) async {
    if (data.length > 1000) {
      return Isolate.run<Map<String, Object?>>(() => decodeString(data), debugName: debugPrint);
    }
    await Future<void>.delayed(Duration.zero);
    return decodeString(data);
  }

  @override
  @pragma('vm:prefer-inline')
  Future<String> encode(Map<String, Object?> data, {String? debugPrint}) async {
    if (data.length > 15) {
      // TODO(Andrey): need check depth
      return Isolate.run<String>(() => encodeObject(data), debugName: debugPrint);
    }

    await Future<void>.delayed(Duration.zero);
    return encodeObject(data);
  }
}
