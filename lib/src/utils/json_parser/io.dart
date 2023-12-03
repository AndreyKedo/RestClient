import 'dart:async';
import 'dart:isolate';

import 'json_parser.dart';

final class IOJsonParser with SyncJsonCodecMixin implements JsonParser {
  static const IOJsonParser _internalSingleton = IOJsonParser._internal();
  factory IOJsonParser() => _internalSingleton;

  const IOJsonParser._internal();

  @override
  @pragma('vm:prefer-inline')
  Future<Map<String, Object?>> strDecodeJson(String data, {bool useIsolate = false, String? debugPrint}) async {
    if (useIsolate) {
      return Isolate.run<Map<String, Object?>>(() => strDecodeJsonSync(data), debugName: debugPrint);
    }
    await Future<void>.delayed(Duration.zero);
    return strDecodeJsonSync(data);
  }

  @override
  @pragma('vm:prefer-inline')
  Future<String> objEncode(Map<String, Object?> data, {bool useIsolate = false, String? debugPrint}) async {
    if (useIsolate) {
      return Isolate.run<String>(() => objEncodeSync(data), debugName: debugPrint);
    }

    await Future<void>.delayed(Duration.zero);
    return objEncodeSync(data);
  }
}

JsonParser getParser() => IOJsonParser();
