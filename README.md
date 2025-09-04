# HttpMiddlewareClient

An Http client that uses middleware to handle requests.

Bonus: Has a JwtDecoder for decode JWT string token.

## Features

- Simple HTTP client wrapper with middleware support
- JWT token decoding utilities
- Middleware pipeline for request/response processing

## How use Middleware

Middleware is a middleware that intercepts and processes HTTP requests to their message. There are two types of middleware used in HttpMiddlewareClient:

- **Middleware.inline** - simple handler
- **Middleware.inlineQueue** - Asynchronous handler with execution queue

Middlewares are executed in the order they are added to the list. Each middleware must call handler(request, context) to pass control to the next handler.

```dart
final middlewares = [
  Middleware.inline((request, context, handler) {
    request.headers['X-Custom-Header'] = 'value';
    return handler(request, context);
  }),
  
  Middleware.inlineQueue((request, context, handler) async {
    final token = await fetchToken();
    request.headers['Authorization'] = 'Bearer $token';
    context['auth_token'] = token;
    return handler(request, context);
  })
];

final client = HttpMiddlewareClient(middlewares: middlewares);
```

You can also implement your middleware by inheriting from the Middleware class

```dart
final class UserAgentMiddleware extends Middleware {
  UserAgentMiddleware(this.source);

  final UserAgentSource source;

  @override
  Handler call(Handler innerSend) {
    Future<StreamedResponse> middleware(request, context) async {
      final userAgent = await source.getUserAgent();
      request.headers['User-agent'] = userAgent;
      return handle(request, context, innerSend);
    }

    return middleware;
  }

}
```

Each middleware can read/write data in the context — `Map<String, Object?>`, which is passed between handlers. This allows data to be passed between middleware.