part of 'rest_client_impl.dart';

/// {@nodoc}
final class HttpRequestTask extends EventQueueTask {
  HttpRequestTask(this.client, this.interceptors, super.request,);

  final Client client;
  final List<SendInterceptor> interceptors;

  static const debugName = 'REST client';

  @override
  Future<StreamedResponse> execute(BaseRequest request) async {
    final flow = Flow.begin();
    try {
      //Send
      final response = await Timeline.timeSync('$debugName: send', () async {
        final response = await client.send(request);
        return response;
      }, flow: Flow.end(flow.id));

      // Response interceptor
      for (var interceptor in interceptors) {
        await interceptor.onResponse(response, this);
      }
      //Resolve response
      return response;
    } catch (error, stackTrace) {
      for (var interceptor in interceptors) {
        await interceptor.onException(error, stackTrace);
      }
      if (error case ClientException(message: final message, uri: final uri)) {
        return Error.throwWithStackTrace(ConnectionException(message: message, uri: uri), stackTrace);
      }
      rethrow;
    }
  }
}
