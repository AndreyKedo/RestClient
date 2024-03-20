import 'dart:async';

import 'package:http/http.dart' show Response;
import 'package:rest_client/src/response.dart';

import 'response_decode_strategy.dart';

final class FallbackDecodeStrategy extends ResponseDecodeStrategy {
  const FallbackDecodeStrategy();

  @override
  FutureOr<RCResponse> decoder(Response response) => RCResponse.from(response, {'data': response.body});
}
