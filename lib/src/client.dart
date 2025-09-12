import 'dart:async';
import 'package:http/http.dart';
import 'package:http_middleware_client/src/work_queue.dart';
import 'package:http_middleware_client/src/http_methods.dart';
import 'package:meta/meta.dart';

/// A function that handles an HTTP request and returns a streamed response.
///
/// [request] is the HTTP request to handle.
/// [context] is a map that can be used to pass data between middleware.
typedef Handler = Future<StreamedResponse> Function(BaseRequest request, Map<String, Object?> context);

/// A function that takes a handler and returns a new handler with middleware applied.
///
/// This is used to chain middleware together in a pipeline.
typedef MiddlewareCallback = Handler Function(Handler innerSend);

/// A function that handles an HTTP request with inline middleware.
///
/// [request] is the HTTP request to handle.
/// [context] is a map that can be used to pass data between middleware.
/// [handler] is the next handler in the chain.
typedef InlineMiddlewareCallback = Future<StreamedResponse> Function(
    BaseRequest request, Map<String, Object?> context, Handler handler);

/// An HTTP client that supports middleware for processing requests and responses.
///
/// Middleware can be used to modify requests before they are sent or to process
/// responses after they are received. They are executed in the order they are added.
///
/// Middleware can be used for various purposes such as:
/// - Adding authentication headers
/// - Logging requests and responses
/// - Handling errors globally
/// - Modifying requests or responses
///
/// Example:
/// ```dart
/// final client = HttpMiddlewareClient(
///   middlewares: [
///     Middleware.inline((request, context, handler) async {
///       // Add a custom header to the request
///       request.headers['X-Custom-Header'] = 'value';
///
///       // Send the request
///       final response = await handler(request, context);
///
///       // Process the response
///       if (response.statusCode == 401) {
///         // Handle unauthorized access
///       }
///
///       return response;
///     }),
///   ],
/// );
/// ```
class HttpMiddlewareClient extends BaseClient {
  /// Creates an HTTP client with optional middleware.
  ///
  /// [client] is the underlying HTTP client to use. If not provided, a default
  /// [Client] will be used.
  ///
  /// [middlewares] is a list of middleware to apply to requests. They are
  /// executed in the order they appear in the list.
  HttpMiddlewareClient({
    Client? client,
    List<Middleware>? middlewares,
  })  : innerClient = client ?? Client(),
        middlewares = middlewares ?? const [] {
    var pipeline = SendPipeline.empty;
    for (final middleware in this.middlewares) {
      pipeline = pipeline.addMiddleware(middleware);
    }
    _pipeline = pipeline;
  }

  /// The underlying HTTP client used to send requests.
  final Client innerClient;

  /// The list of middleware applied to requests.
  final List<Middleware> middlewares;

  SendPipeline _pipeline = SendPipeline.empty;

  @visibleForTesting
  SendPipeline get pipeline => _pipeline;

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    assert(() {
      HttpMethod.checkMethod(request.method);
      return true;
    }());

    final applySend = pipeline.addHandler((request, _) => innerClient.send(request));
    return applySend(request, {});
  }

  @override
  void close() {
    _pipeline = SendPipeline.empty;
    innerClient.close();
    super.close();
  }
}

/// A middleware that can process HTTP requests and responses.
///
/// Middleware can be used to modify requests before they are sent or to process
/// responses after they are received. They form a chain where each middleware
/// can choose to delegate to the next middleware or handle the request itself.
abstract class Middleware {
  const Middleware();

  /// Creates a middleware from an inline callback function.
  ///
  /// [handler] is a function that processes the request. If not provided,
  /// the request is passed through to the next middleware unchanged.
  const factory Middleware.inline([InlineMiddlewareCallback? handler]) = _InlineMiddleware;

  /// Creates a middleware that processes requests sequentially using a queue.
  ///
  /// This is useful for operations that must be performed in order, such as
  /// token refresh.
  ///
  /// [handler] is a function that processes the request.
  /// [queue] is the work queue to use. If not provided, a default [WorkQueue] is used.
  factory Middleware.inlineQueue([InlineMiddlewareCallback? handler, WorkQueueBase? queue]) = _InlineQueueMiddleware;

  Handler call(Handler innerSend);
}

/// A middleware that processes requests sequentially using a queue.
///
/// This abstract class can be extended to create middleware that needs to
/// process requests one at a time in the order they are received.
abstract class QueueMiddleware implements Middleware {
  /// Creates a queue middleware.
  ///
  /// [queue] is the work queue to use. If not provided, a default [WorkQueue] is used.
  QueueMiddleware([WorkQueueBase? queue]) : _queue = queue ?? WorkQueue();

  final WorkQueueBase _queue;

  @override
  Handler call(Handler innerSend) {
    Future<StreamedResponse> middleware(request, context) {
      return _queue.schedule<StreamedResponse>(() => handle(request, context, innerSend));
    }

    return middleware;
  }

  /// Handles a request.
  ///
  /// This method should be implemented by subclasses to process the request.
  ///
  /// [request] is the HTTP request to process.
  /// [context] is a map that can be used to pass data between middleware.
  /// [handler] is the next handler in the chain.
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

/// A pipeline of middleware that can process HTTP requests.
class SendPipeline {
  const SendPipeline([this.depth = 0]);

  @visibleForTesting
  final int depth;

  /// An empty pipeline.
  static const empty = SendPipeline(0);

  /// Adds middleware to the pipeline.
  ///
  /// Returns a new pipeline with the middleware added.
  SendPipeline addMiddleware(Middleware middleware) => _Pipeline(middleware, addHandler, depth + 1);

  @visibleForTesting
  Handler addHandler(Handler handler) => handler;
}

class _Pipeline extends SendPipeline {
  final Middleware _middleware;
  final MiddlewareCallback _parent;

  _Pipeline(this._middleware, this._parent, super.depth);

  @override
  Handler addHandler(Handler handler) => _parent(_middleware(handler));
}
