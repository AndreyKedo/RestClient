part of 'response_decode.dart';

final class JsonDecodeStrategy extends ResponseDecodeStrategy {
  const JsonDecodeStrategy();

  @override
  FutureOr<RCResponse> decoder(Response response) async {
    final body = response.body;

    final Map<String, Object?> result = await JsonParser().strDecodeJson(body, useIsolate: body.length > 1000);

    final statusCode = response.statusCode;

    if (statusCode >= 400 && statusCode <= 500) {
      if (result case {'message': final String message}) {
        if (statusCode == 401) {
          throw UnauthorizedException(message: message); // unauthorized exception
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
      if (result case {'code': final String code, 'message': final String message}) {
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
