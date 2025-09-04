import 'dart:async';
import 'package:http/http.dart';
import 'package:http_middleware/src/work_queue.dart';
import 'package:http_middleware/src/http_methods.dart';
import 'package:meta/meta.dart';

typedef Handler = Future<StreamedResponse> Function(BaseRequest request, Map<String, Object?> context);

typedef MiddlewareCallback = Handler Function(Handler innerSend);

typedef InlineMiddlewareCallback = Future<StreamedResponse> Function(
    BaseRequest request, Map<String, Object?> context, Handler handler);

/// HTTP client.
///
/// Simple HTTP client for easy use inside app project
class HttpMiddlewareClient extends BaseClient {
  HttpMiddlewareClient({
    Client? client,
    List<Middleware>? middlewares,
  })  : client = client ?? Client(),
        middlewares = middlewares ?? const [] {
    SendPipeline pipeline = SendPipeline.empty;
    for (final middleware in this.middlewares) {
      pipeline = pipeline.addMiddleware(middleware);
    }
    _pipeline = pipeline;
  }

  /// Client configuration.
  final Client client;

  final List<Middleware> middlewares;

  SendPipeline _pipeline = SendPipeline.empty;

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    HttpMethod.checkMethod(request.method);

    final applySend = _pipeline.addHandler((request, _) => client.send(request));
    return applySend(request, {});
  }

  @override
  void close() {
    _pipeline = SendPipeline.empty;
    client.close();
    super.close();
  }
}

abstract class Middleware {
  const Middleware();

  const factory Middleware.inline([InlineMiddlewareCallback? handler]) = _InlineMiddleware;

  factory Middleware.inlineQueue([InlineMiddlewareCallback? handler, WorkQueueBase? queue]) = _InlineQueueMiddleware;

  Handler call(Handler innerSend);
}

abstract class QueueMiddleware implements Middleware {
  QueueMiddleware([WorkQueueBase? queue]) : _queue = queue ?? WorkQueue();

  final WorkQueueBase _queue;

  @override
  Handler call(Handler innerSend) {
    Future<StreamedResponse> middleware(request, context) {
      return _queue.schedule<StreamedResponse>(() => handle(request, context, innerSend));
    }

    return middleware;
  }

  Future<StreamedResponse> handle(BaseRequest request, Map<String, Object?> context, Handler handler);
}

final class _InlineQueueMiddleware extends QueueMiddleware {
  _InlineQueueMiddleware([this.handler, super.queue]);

  final InlineMiddlewareCallback? handler;

  @override
  Future<StreamedResponse> handle(BaseRequest request, Map<String, Object?> context, Handler inner) {
    return handler?.call(request, context, inner) ?? inner(request, context);
  }
}

final class _InlineMiddleware implements Middleware {
  const _InlineMiddleware([this.handler]);

  final InlineMiddlewareCallback? handler;

  @override
  Handler call(Handler innerSend) {
    Future<StreamedResponse> middleware(request, context) {
      return handler?.call(request, context, innerSend) ?? innerSend(request, context);
    }

    return middleware;
  }
}

class SendPipeline {
  const SendPipeline();

  static const empty = SendPipeline();

  SendPipeline addMiddleware(Middleware middleware) => _Pipeline(middleware, addHandler);

  @visibleForTesting
  Handler addHandler(Handler handler) => handler;
}

class _Pipeline extends SendPipeline {
  final Middleware _middleware;
  final MiddlewareCallback _parent;

  _Pipeline(this._middleware, this._parent);

  @override
  Handler addHandler(Handler handler) => _parent(_middleware(handler));
}
