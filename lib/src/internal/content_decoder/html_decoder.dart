import 'dart:async';

import 'package:http/http.dart' show Response;
import 'package:rest_client/src/exception.dart';
import 'package:rest_client/src/response.dart';

import 'response_decode_strategy.dart';

final class HtmlDecodeStrategy extends ResponseDecodeStrategy {
  const HtmlDecodeStrategy();

  @override
  FutureOr<RCResponse> decoder(Response response) async {
    final statusCode = response.statusCode;

    if (statusCode >= 400 && statusCode <= 500) {
      if (statusCode == 413) {
        throw InternalServerException(statusCode: statusCode, message: 'Exceeded the maximum allowed file size');
      }

      throw InternalServerException(statusCode: statusCode, message: response.reasonPhrase);
    }

    return RCResponse.from(response, {'data': response.body});
  }
}
