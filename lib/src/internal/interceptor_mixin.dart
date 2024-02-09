part of '../../rest_client.dart';

///Interceptor API Mixin
///
///JWT token handler implementation
base mixin _InterceptorAPI on _ClientBuilderAPI {
  final lock = Lock();
  Completer? _mutex;

  final Client refreshClient = Client();

  /// JWT refresh request
  Future<void> _refresh() async {
    if (session != null) {
      _mutex ??= Completer();
      try {
        final token = await _getToken;
        if (token != null) {
          if (token.isExpired) {
            final headers = await _headers;
            configuration.log(FineLogMessage(
                '''Token is invalid update...\nExpirationDate ${token.expirationDate}\nRemainingTime ${token.remainingTime}'''));
            final requestResult = await refreshClient.post(buildUri(path: session!.refreshTokenPath), headers: headers);
            final response = await resolveResponse(requestResult);

            await session!.setToken(response.data['access_token'] as String);
            configuration.log(FineLogMessage(
                '''Token update susses!\nExpirationDate ${token.expirationDate}\nRemainingTime ${token.remainingTime}'''));
          }
        }
      } on NetworkException {
        rethrow;
      } finally {
        _mutex?.complete();
        _mutex = null;
      }
    }
  }

  Future<Response> _send(BaseRequest request) async {
    final streamResponse = await _client.send(request);
    return Response.fromStream(streamResponse);
  }

  /// Send request
  ///
  /// Rethrow exception from [resolveResponse]
  /// if http client throw exception on wrapped [ConnectionException]
  Future<RCResponse> _sendRequest(BaseRequest request, {RequestBody? body, Map<String, String>? headers}) async {
    //Mutex
    if (lock.locked && _mutex != null) {
      await _mutex!.future;
    }

    try {
      //JWT Refresh
      await lock.synchronized(_refresh);

      //Headers
      final commonHeaders = await _headers;
      if (headers != null) {
        commonHeaders.addAll(headers);
      }
      request.headers.addAll(commonHeaders);

      //Body
      if (request is Request) {
        if (body != null) {
          switch (body) {
            case BytesBody(value: Uint8List val):
              request.bodyBytes = val;
            case JsonMapBody(value: Map<String, Object?> val):
              request.body = await JsonParser().encode(val, debugPrint: 'Json encode');
            case StringBody(value: String val):
              request.body = val;
          }
        }
      }

      //Request send block
      configuration.log(FineLogMessage('Send request... [${request.method}] ${request.url}'));
      final stopwatch = Stopwatch()..start();
      final Response response = await _send(request).whenComplete(stopwatch.stop);
      configuration.log(FineLogMessage(
          'Request [${request.method}] ${request.url}: execute time ${stopwatch.elapsedMilliseconds}ms'));

      //Resolve response
      return resolveResponse(response);
    } on NetworkException {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      // JsonParser() exception handle when body encode inside sendRequest()
      // Body parse handle exception
      configuration.log(ErrorLogMessage(error, stackTrace));
      Error.throwWithStackTrace(
        const RestClientException(message: 'Error occurred during decoding body'),
        stackTrace,
      );
    } on ClientException catch (error, stackTrace) {
      configuration.log(ErrorLogMessage(error, stackTrace));
      Error.throwWithStackTrace(ConnectionException(message: error.message, uri: error.uri), stackTrace);
    }
  }

  /// Decodes [body] from JSON \ UTF8
  /// if body nota parsed throw [RestClientException] with message "Error occurred during decoding"
  /// if status code >= 400 and <= 500 throw [InternalServerException], if 404 throw [UnauthorizedException]
  /// if api return error body throw [ApiErrorException]
  FutureOr<RCResponse> resolveResponse(Response response) async {
    final strategy = ResponseDecodeStrategy.fromHeaders(response.headers);

    //Log response
    if (response case Response(request: BaseRequest request, statusCode: int status)) {
      configuration.log(ResponseLogMessage(request.method, request.url, status));
    }

    return await strategy.decode(response);
  }

  @override
  void dispose() {
    refreshClient.close();
    super.dispose();
  }
}
