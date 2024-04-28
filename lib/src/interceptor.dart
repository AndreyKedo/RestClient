part of 'rest_client_impl.dart';

/// Interceptor interface.
abstract interface class SendInterceptor {
  /// Before request handler.
  ///
  /// Invoked and awaited before request. Not other request will be processed until [onRequest] is awaited.
  /// You can mutate [BaseRequest] before request send.
  FutureOr<void> onRequest(covariant BaseRequest request, QueueTaskHandler handler);

  /// After request handler.
  ///
  /// When request completed without exception this will be called.
  /// This handler is asynchrony.
  /// You can rejected task [QueueTaskHandler.reject].
  FutureOr<void> onResponse(covariant StreamedResponse response, QueueTaskHandler handler);

  /// If request ended with exception this handler will be called
  /// or if you throw exception in [onResponse].
  /// This handler is asynchrony.
  /// Throwed exception will be rise higher on call stack.
  FutureOr<void> onException(Object error, StackTrace stackTrace);
}

/// Default callback interceptor.
final class DefaultInterceptor implements SendInterceptor {
  final FutureOr<void> Function(BaseRequest request)? requestCall;
  final FutureOr<void> Function(StreamedResponse request)? responseCall;
  final FutureOr<void> Function(Object error, StackTrace stackTrace)? exceptionCall;

  DefaultInterceptor({this.requestCall, this.responseCall, this.exceptionCall});

  @override
  FutureOr<void> onRequest(covariant BaseRequest request, QueueTaskHandler handler) => requestCall?.call(request);

  @override
  FutureOr<void> onResponse(covariant StreamedResponse response, QueueTaskHandler handler) =>
      responseCall?.call(response);

  @override
  FutureOr<void> onException(Object error, StackTrace stackTrace) => exceptionCall?.call(error, stackTrace);
}
