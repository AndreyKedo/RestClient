import 'dart:async';
import 'package:http/http.dart';
import 'package:http_client/src/http_methods.dart';
import 'package:meta/meta.dart';

typedef Handler = Future<StreamedResponse> Function(BaseRequest request, Map<String, Object?> context);

typedef MiddlewareCallback = Handler Function(Handler innerSend);

typedef InlineMiddlewareCallback = Future<StreamedResponse> Function(
    BaseRequest request, Map<String, Object?> context, Handler handler);

abstract class Middleware {
  const Middleware();

  const factory Middleware.inline([InlineMiddlewareCallback? handler]) = _InlineMiddleware;

  Handler call(Handler innerSend);
}

final class _InlineMiddleware implements Middleware {
  const _InlineMiddleware([this.handler]);

  final InlineMiddlewareCallback? handler;

  @override
  Handler call(Handler innerSend) {
    if (handler != null) {
      return (request, context) => handler!(request, context, innerSend);
    }

    return innerSend;
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

/// {@template http_client}
/// HTTP client
///
/// Simple HTTP client for easy use inside app project
/// {@endtemplate}
class HttpClient extends BaseClient {
  HttpClient({
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

  /// Send.
  ///
  /// Send http request with [interceptors] if has.
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
