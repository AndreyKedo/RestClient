# HttpMiddlewareClient

An wrapper around package [http](https://pub.dev/packages/http) HTTP client that 
supports middleware for processing requests and responses.

This package provides an HTTP client that allows you to add middleware
to process requests before they are sent and responses after they are received.

Middleware can be used for various purposes such as:
- Adding authentication headers
- Logging requests and responses
- Handling errors globally
- Modifying requests or responses

## Features

- Middleware support for request/response processing
- Two types of middleware: inline and queued
- Context passing between middlewares
- Fully compatible with the http package

## How use Middleware

There are two types of middleware:

- **Middleware.inline** - Simple handler that processes requests asynchronously
- **Middleware.inlineQueue** - Handler with execution queue for sequential processing

Middlewares are executed in the order they are added to the list. Each middleware must call handler(request, context) to pass control to the next handler.

```dart
import 'package:http_middleware_client/http_middleware_client.dart';

  final middlewares = [
    Middleware.inline((request, context, handler) async {
      // Handle request
      request.headers['X-Custom-Header'] = 'value';

      final result = await handler(request, context);

      // Handle response
      if(result.headers['X-Custom-Header-Result'] == 'true'){
        notifyClients();
      }

      return result;
    }),
    
    // Token refresh
    Middleware.inlineQueue((request, context, handler) async {
      final token = await fetchToken();
      request.headers['Authorization'] = 'Bearer $token';
      context['auth_token'] = token;
      return handler(request, context);
    })
  ];

  final client = HttpMiddlewareClient(middlewares: middlewares);
  print(response.statusCode);
  client.close();
```

## Custom Middleware Implementation

You can also create custom middleware by extending the Middleware class:

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

Or extend QueueMiddleware for sequential processing:

```dart
class AuthMiddleware extends QueueMiddleware {
  @override
  Future<StreamedResponse> handle(
    BaseRequest request, 
    Map<String, Object?> context, 
    Handler handler,
  ) async {
    final token = await getAuthToken();
    request.headers['Authorization'] = 'Bearer $token';
    return handler(request, context);
  }
}
```

## Context Usage

Each middleware can read/write data in the context (Map<String, Object?>), which is passed between handlers:

```dart
Middleware.inline((request, context, handler) async {
  // Write to context
  context['start_time'] = DateTime.now();
  
  final response = await handler(request, context);
  
  // Read from context
  final startTime = context['start_time'] as DateTime;
  final duration = DateTime.now().difference(startTime);
  print('Request took ${duration.inMilliseconds}ms');
  
  return response;
});
```