import 'dart:async';

import 'json_parser.dart';

final class WebJsonParser with SyncJsonCodecMixin implements JsonParser {
  static const WebJsonParser _internalSingleton = WebJsonParser._internal();
  factory WebJsonParser() => _internalSingleton;
  const WebJsonParser._internal();

  @override
  @pragma('dart2js:tryInline')
  Future<Map<String, Object?>> strDecodeJson(String data, {bool useIsolate = false, String? debugPrint}) async {
    // From flutter/foundation/_isolates_web.dart
    //
    // To avoid blocking the UI immediately for an expensive function call, we
    // pump a single frame to allow the framework to complete the current set
    // of work.

    await Future<void>.delayed(Duration.zero);
    return strDecodeJson(data);
  }

  @override
  @pragma('dart2js:tryInline')
  Future<String> objEncode(Map<String, Object?> data, {bool useIsolate = false, String? debugPrint}) async {
    // From flutter/foundation/_isolates_web.dart
    //
    // To avoid blocking the UI immediately for an expensive function call, we
    // pump a single frame to allow the framework to complete the current set
    // of work.

    await Future<void>.delayed(Duration.zero);
    return objEncodeSync(data);
  }
}

JsonParser getParser() => WebJsonParser();
