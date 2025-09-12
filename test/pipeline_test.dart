import 'dart:async';
import 'dart:math';

import 'package:http/http.dart';
import 'package:http_middleware_client/http_middleware_client.dart';
import 'package:test/test.dart';
import 'package:test/fake.dart';

class FaceClient extends Fake implements Client {
  final List<BaseRequest> requests = [];

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    requests.add(request);
    return Future.value(StreamedResponse(Stream.value([]), 200));
  }
}

class FakeMiddleware extends Fake implements Middleware {
  @override
  Handler call(Handler innerSend) {
    return innerSend;
  }
}

///Sync handler
Handler syncHandler([StreamedResponse? response]) => (r, c) {
      final syncCompleter = Completer<StreamedResponse>.sync();

      syncCompleter.complete(response ?? StreamedResponse(Stream.empty(), 200));

      return syncCompleter.future;
    };

void main() {
  group('HttpClient', () {
    late FaceClient fakeClient;

    setUp(() {
      fakeClient = FaceClient();
    });

    test('should initialize with default client and empty middlewares', () {
      final client = HttpMiddlewareClient();
      expect(client.pipeline.depth, equals(0));
    });

    test('should initialize with provided client and middlewares', () {
      final middleware = FakeMiddleware();
      final client = HttpMiddlewareClient(client: fakeClient, middlewares: [middleware]);
      expect(client.innerClient, equals(fakeClient));
      expect(client.pipeline.depth, equals(1));
      expect(client.middlewares, equals([middleware]));
    });

    test('should send request through client', () async {
      final client = HttpMiddlewareClient(client: fakeClient);
      final request = Request('GET', Uri.parse('https://example.com'));

      await client.send(request);

      expect(fakeClient.requests, hasLength(1));
      expect(fakeClient.requests.first.method, equals('GET'));
    });

    test('should close client and reset pipeline', () {
      final client = HttpMiddlewareClient();
      // Since close method is void, we just ensure no exception is thrown
      expect(() => client.close(), returnsNormally);
      expect(client.pipeline.depth, equals(0));
    });

    test('should pass context between middlewares', () async {
      final pipeline = SendPipeline();

      // Middleware 1: добавляет значение в контекст
      final middleware1 = Middleware.inline((request, context, handler) async {
        context['middleware1'] = 'value1';
        context['counter'] = 1;
        return handler(request, context);
      });

      // Middleware 2: читает и модифицирует контекст
      final middleware2 = Middleware.inline((request, context, handler) async {
        expect(context['middleware1'], 'value1');
        expect(context['counter'], 1);

        context['middleware2'] = 'value2';
        final counterValue = context['counter'] as int;
        context['counter'] = counterValue + 1;
        return handler(request, context);
      });

      // Обработчик: проверяет финальный контекст
      Future<StreamedResponse> handler(BaseRequest request, Map<String, Object?> context) async {
        expect(context['middleware1'], 'value1');
        expect(context['middleware2'], 'value2');
        expect(context['counter'], 2);
        return StreamedResponse(Stream.empty(), 200);
      }

      await pipeline.addMiddleware(middleware1).addMiddleware(middleware2).addHandler(handler)(
        Request(HttpMethod.get, Uri.parse('https://example.com')),
        {},
      );
    });

    test('One middleware instance', () async {
      int counter = 0;
      final middleware = Middleware.inline((request, context, handler) {
        counter++;
        return handler(request, context);
      });

      Future<StreamedResponse> handler(BaseRequest request, Map<String, Object?> context) {
        return Future.value(StreamedResponse(Stream.empty(), 200));
      }

      final pipeline = SendPipeline().addMiddleware(middleware).addMiddleware(middleware).addHandler(handler);

      final futures = <Future>[
        pipeline(Request(HttpMethod.get, Uri.parse('https://example.com')), {}),
        pipeline(Request(HttpMethod.get, Uri.parse('https://example.com')), {}),
      ];

      await Future.wait(futures);

      expect(counter, equals(4));
    });

    test('should apply middlewares in order', () async {
      final resultExcept = <String>[];
      final pipeline = SendPipeline();

      final middleware1 = Middleware.inline((r, c, handler) async {
        resultExcept.add('start_m1');
        final result = await handler(r, c);
        resultExcept.add('end_m1');
        return result;
      });

      final middleware2 = Middleware.inline((r, c, handler) async {
        resultExcept.add('start_m2');
        final result = await handler(r, c);
        resultExcept.add('end_m2');
        return result;
      });

      Future<StreamedResponse> handler(r, c) {
        final syncCompleter = Completer<StreamedResponse>.sync();
        resultExcept.add('start_request');
        syncCompleter.complete(StreamedResponse(Stream.empty(), 200));
        resultExcept.add('end_request');
        return syncCompleter.future;
      }

      await pipeline.addMiddleware(middleware1).addMiddleware(middleware2).addHandler(handler)(
        Request(HttpMethod.get, Uri.parse('https://example.com')),
        {},
      );

      expect(resultExcept, equals(['start_m1', 'start_m2', 'start_request', 'end_request', 'end_m2', 'end_m1']));
    });

    test('Middleware.inlineQueue should process requests sequentially', () async {
      final processedOrder = <int>[];

      final queueMiddleware = Middleware.inlineQueue((request, context, handler) async {
        final orderId = context['orderId'] as int;
        processedOrder.add(orderId);

        // Имитируем асинхронную работу
        await Future.delayed(Duration(milliseconds: 50));
        processedOrder.add(-orderId); // Помечаем завершение

        return handler(request, context);
      });

      final pipeline = SendPipeline().addMiddleware(queueMiddleware).addHandler(syncHandler());

      // Создаем несколько параллельных запросов
      await Future.wait([
        for (int i = 1; i <= 3; i++)
          pipeline(
            Request(HttpMethod.get, Uri.parse('https://example.com')),
            {'orderId': i},
          )
      ]);

      // Проверяем что обработка была последовательной:
      // сначала начинается и заканчивается 1, потом 2, потом 3
      expect(processedOrder, equals([1, -1, 2, -2, 3, -3]));
    });

    test('Middleware.inlineQueue should handle errors properly', () async {
      final queueMiddleware = Middleware.inlineQueue((request, context, handler) async {
        final shouldFail = context['shouldFail'] as bool? ?? false;
        if (shouldFail) {
          throw Exception('Test error');
        }
        return handler(request, context);
      });

      final pipeline = SendPipeline().addMiddleware(queueMiddleware).addHandler(syncHandler());

      // Запрос без ошибок
      await expectLater(
        pipeline(Request(HttpMethod.get, Uri.parse('https://example.com')), {}),
        completes,
      );

      // Запрос с ошибкой
      await expectLater(
        pipeline(Request(HttpMethod.get, Uri.parse('https://example.com')), {'shouldFail': true}),
        throwsA(isA<Exception>()),
      );
    });

    test('Middleware.inlineQueue should maintain order with different request types', () async {
      final executionOrder = <String>[];

      final queueMiddleware = Middleware.inlineQueue((request, context, handler) async {
        final requestId = context['requestId'] as String;
        executionOrder.add('start_$requestId');

        await Future.delayed(Duration(milliseconds: 30));

        executionOrder.add('end_$requestId');
        return handler(request, context);
      });

      final pipeline = SendPipeline().addMiddleware(queueMiddleware).addHandler(syncHandler());

      // Создаем запросы с разными ID
      final requestIds = ['A', 'B', 'C'];
      await Future.wait([
        for (final id in requestIds)
          pipeline(
            Request(HttpMethod.get, Uri.parse('https://example.com')),
            {'requestId': id},
          )
      ]);

      // Проверяем строгий порядок выполнения
      expect(executionOrder, equals(['start_A', 'end_A', 'start_B', 'end_B', 'start_C', 'end_C']));
    });

    test('Multiple Middleware.inlineQueue instances should work independently', () async {
      final queue1Events = <int>[];
      final queue2Events = <int>[];

      final queueMiddleware1 = Middleware.inlineQueue((request, context, handler) async {
        final id = context['id'] as int;
        queue1Events.add(id);
        await Future.delayed(Duration(milliseconds: 20));
        queue1Events.add(-id);
        return handler(request, context);
      });

      final queueMiddleware2 = Middleware.inlineQueue((request, context, handler) async {
        final id = context['id'] as int;
        queue2Events.add(id * 10);
        await Future.delayed(Duration(milliseconds: 10));
        queue2Events.add(-id * 10);
        return handler(request, context);
      });

      final pipeline =
          SendPipeline().addMiddleware(queueMiddleware1).addMiddleware(queueMiddleware2).addHandler(syncHandler());

      // Создаем параллельные запросы
      await Future.wait([
        for (int i = 1; i <= 2; i++)
          pipeline(
            Request(HttpMethod.get, Uri.parse('https://example.com')),
            {'id': i},
          )
      ]);

      // Обе очереди должны обработать запросы последовательно
      expect(queue1Events, equals([1, -1, 2, -2]));
      expect(queue2Events, equals([10, -10, 20, -20]));
    });

    test('Middleware.inlineQueue should continue processing after exception', () async {
      final processedRequests = <String>[];

      final queueMiddleware = Middleware.inlineQueue((request, context, handler) async {
        final requestId = context['requestId'] as String;

        if (requestId == 'error') {
          throw Exception('Expected error');
        }

        processedRequests.add(requestId);
        return handler(request, context);
      });

      final pipeline = SendPipeline().addMiddleware(queueMiddleware).addHandler(syncHandler());

      // Запрос с ошибкой
      await expectLater(
        pipeline(Request(HttpMethod.get, Uri.parse('https://example.com')), {'requestId': 'error'}),
        throwsA(isA<Exception>()),
      );

      // Нормальный запрос после ошибки
      await expectLater(
        pipeline(Request(HttpMethod.get, Uri.parse('https://example.com')), {'requestId': 'success'}),
        completes,
      );

      expect(processedRequests, equals(['success']));
    });

    test('Middleware.inlineQueue should handle nested queues correctly', () async {
      final generalPipelineEvents = <String>[];
      final outerQueueEvents = <String>[];
      final innerQueueEvents = <String>[];

      final innerQueue = Middleware.inlineQueue((request, context, handler) async {
        final id = context['innerId'] as String;
        final outerId = context['outerId'] as String;

        innerQueueEvents.add('start_$id');
        await Future.delayed(Duration(milliseconds: 10));
        innerQueueEvents.add('end_$id');
        generalPipelineEvents.add(outerId + id);
        return handler(request, context);
      });

      final outerQueue = Middleware.inlineQueue((request, context, handler) async {
        final id = context['outerId'] as String;
        final innerId = context['innerId'] as String;

        outerQueueEvents.add('start_$id');
        await Future.delayed(Duration(milliseconds: 20));
        outerQueueEvents.add('end_$id');
        generalPipelineEvents.add(id + innerId);
        return handler(request, context);
      });

      final pipeline = SendPipeline().addMiddleware(outerQueue).addMiddleware(innerQueue).addHandler(syncHandler());

      // Создаем параллельные запросы
      await Future.wait([
        pipeline(
          Request(HttpMethod.get, Uri.parse('https://example.com')),
          {'outerId': 'A', 'innerId': '1'},
        ),
        pipeline(
          Request(HttpMethod.get, Uri.parse('https://example.com')),
          {'outerId': 'B', 'innerId': '2'},
        ),
      ]);

      // Проверяем что обе очереди работают последовательно
      expect(outerQueueEvents, equals(['start_A', 'end_A', 'start_B', 'end_B']));
      expect(innerQueueEvents, equals(['start_1', 'end_1', 'start_2', 'end_2']));
      expect(generalPipelineEvents, equals(['A1', 'A1', 'B2', 'B2']));
    });

    test('Pipeline test', () async {
      var callDepth = 0;

      final queueMiddleware = Middleware.inlineQueue((request, context, handler) async {
        final callNumber = callDepth++;
        context['2_${callNumber + 1}'] = 'start';
        if (callNumber == 0) {
          await Future.delayed(Duration(milliseconds: Random().nextInt(300) + 200));
        }
        return handler(request, context);
      });

      final handler = SendPipeline()
          .addMiddleware(
            Middleware.inline(
              (request, context, handler) async {
                request.headers['first'] = 'middleware';

                final result = await handler(request, context);

                expect(request.headers, anyOf(containsPair('call0', 'true'), containsPair('call1', 'true')));
                return result;
              },
            ),
          )
          .addMiddleware(queueMiddleware)
          .addMiddleware(
            Middleware.inline(
              (request, context, handler) async {
                if (request.headers.containsKey('call0')) {
                  request.headers['call0'] = 'true';
                }

                if (request.headers.containsKey('call1')) {
                  request.headers['call1'] = 'true';
                }

                expect(request.headers['first'], isNotNull);

                return handler(request, context);
              },
            ),
          )
          .addHandler((request, context) {
            return Future.value(StreamedResponse(Stream.empty(), 200));
          });

      final list = <Future>[];
      for (var i = 0; i < 2; i++) {
        list.add(handler(
          Request(HttpMethod.get, Uri(scheme: 'https', host: 'example.com'))..headers['call$i'] = '',
          <String, Object?>{'call': i + 1},
        ));
      }

      await Future.wait(list);
    });
  });
}
