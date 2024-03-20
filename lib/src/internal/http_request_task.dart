part of '../../rest_client.dart';

/// {@nodoc}
final class HttpRequestTask extends EventQueueTask {
  HttpRequestTask(this._dispatcher, super.request, this.body);

  final _InterceptorAPI _dispatcher;
  final RequestBody? body;

  RestConfig get configuration => _dispatcher.configuration;
  Client get executor => _dispatcher._client;
  JsonParser get jsonParser => _dispatcher.jsonParser;

  static const debugName = 'REST client';

  @override
  Future<StreamedResponse> execute(BaseRequest request) async {
    final flow = Flow.begin();
    try {
      //Body
      if (request is Request) {
        switch (body) {
          case BytesBody(value: Uint8List val):
            request.bodyBytes = val;
          case JsonMapBody(value: Map<String, Object?> val):
            request.body = await Timeline.timeSync('$debugName: Json encode', () async {
              final jsonStr = await jsonParser.objEncode(val, useIsolate: true, debugPrint: 'Json encode');
              return jsonStr;
            }, flow: Flow.step(flow.id));
          case StringBody(value: String val):
            request.body = val;
          default:
        }
      }

      //Send
      final response = await Timeline.timeSync('$debugName: send', () async {
        final response = await executor.send(request);
        return response;
      }, flow: Flow.end(flow.id));

      // Response interceptor
      for (var interceptor in configuration.interceptors) {
        await interceptor.onResponse(response, this);
      }
      //Resolve response
      return response;
    } catch (error, stackTrace) {
      for (var interceptor in configuration.interceptors) {
        await interceptor.onException(error, stackTrace);
      }
      if (error is FormatException) {
        // JsonParser() exception handle when body encode inside sendRequest()
        // Body parse handle exception
        Error.throwWithStackTrace(
          const RestClientException(message: 'Error occurred during decoding body'),
          stackTrace,
        );
      }

      if (error is ClientException) {
        Error.throwWithStackTrace(ConnectionException(message: error.message, uri: error.uri), stackTrace);
      }
      rethrow;
    }
  }
}
