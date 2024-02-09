part of 'response_decode.dart';

final class FallbackDecodeStrategy extends ResponseDecodeStrategy {
  const FallbackDecodeStrategy();

  @override
  FutureOr<RCResponse> decoder(Response response) => RCResponse.from(response, {'data': response.body});
}
