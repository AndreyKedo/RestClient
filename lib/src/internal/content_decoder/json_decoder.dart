import 'dart:async';

import 'package:http/http.dart' show Response;
import 'package:rest_client/src/exception.dart';
import 'package:rest_client/src/response.dart';
import 'package:rest_client/src/utils/utils.dart';

import 'response_decode_strategy.dart';

final class JsonDecodeStrategy extends ResponseDecodeStrategy {
  const JsonDecodeStrategy();

  static final _jsonParser = JsonParser();

  @override
  FutureOr<RCResponse> decoder(Response response) async {
    final body = response.body;

    final result = await _jsonParser.strDecodeJson(body, useIsolate: body.length > 1000);

    final statusCode = response.statusCode;

    if (statusCode >= 400 && statusCode <= 500) {
      if (result case {'message': final String message}) {
        if (statusCode == 401) {
          throw UnauthorizedException(message: message);
        }
        if (statusCode == 500) {
          throw InternalServerException(statusCode: statusCode, message: message); // internal server exception
        }
      }
      // Code - status code (not used)
      // Message - backend error code
      // LocalizedMessage - human friendly message
      // {
      //   "code": "string",
      //   "message": "string",
      //   "localizedMessage": "string"
      // }
      if (result case {'message': final String code, "localizedMessage": final String message}) {
        throw ApiErrorException(
          RCResponse.from(response, result),
          statusCode,
          code,
          message: message,
        );
      }
    }

    //data - contains main content of response
    //format - { 'data': { } }
    if (result case {'data': final Map<String, Object?> data}) {
      return RCResponse.from(response, data);
    }

    return RCResponse.from(response, result);
  }
}
