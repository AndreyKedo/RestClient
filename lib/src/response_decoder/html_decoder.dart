part of 'response_decode.dart';

final class HtmlDecodeStrategy extends ResponseDecodeStrategy {
  const HtmlDecodeStrategy();

  @override
  FutureOr<RCResponse> decoder(Response response) async {
    final statusCode = response.statusCode;

    if (statusCode >= 400 && statusCode <= 500) {
      throw InternalServerException(statusCode: statusCode, message: response.reasonPhrase);
    }

    return RCResponse.from(response, {'data': response.body});
  }
}
