part of '../../rest_client.dart';

///Interceptor API Mixin
///
///JWT token handler implementation
base mixin _InterceptorAPI on _ClientBuilderAPI {
  late final queue = EventQueue(configuration.interceptors, debugLabel: 'REST RequestQueue');
  final jsonParser = JsonParser();

  /// Send request and returned [StreamedResponse]
  ///
  /// Wrapper token refreshing and
  ///
  /// Is low level method.
  /// [method] GET,POST,PATCH, PUT, DELETE.
  @override
  Future<StreamedResponse> send(BaseRequest request, {final RequestBody? body, final Map<String, String>? headers}) {
    //Write configuration header inside request
    request.headers.addAll({...?headers, ...configuration.headers});
    return queue.add(HttpRequestTask(this, request, body));
  }

  /// Decodes [body] from JSON \ UTF8
  /// if body nota parsed throw [RestClientException] with message "Error occurred during decoding"
  /// if status code >= 400 and <= 500 throw [InternalServerException], if 404 throw [UnauthorizedException]
  /// if api return error body throw [ApiErrorException]
  FutureOr<RCResponse> resolveResponse(Response response) async {
    final strategy = ResponseDecodeStrategy.fromHeaders(response.headers);

    try {
      final result = await strategy.decode(response);
      return result;
    } on NetworkException {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        const RestClientException(message: 'Error occurred during decoding body'),
        stackTrace,
      );
    }
  }

  @override
  void dispose() {
    queue.close();
    super.dispose();
  }
}
