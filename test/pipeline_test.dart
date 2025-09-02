import 'dart:math';

import 'package:http_client/http_client.dart';
import 'package:http_client/src/event_queue.dart';
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

void main() {
  group('HttpClient', () {
    late FaceClient fakeClient;

    setUp(() {
      fakeClient = FaceClient();
    });

    test('should initialize with default client and empty middlewares', () {
      final client = HttpClient();
      expect(client.client, isNotNull);
      expect(client.middlewares, isEmpty);
    });

    test('should initialize with provided client and middlewares', () {
      final middleware = FakeMiddleware();
      final client = HttpClient(client: fakeClient, middlewares: [middleware]);
      expect(client.client, equals(fakeClient));
      expect(client.middlewares, equals([middleware]));
    });

    test('should send request through client', () async {
      final client = HttpClient(client: fakeClient);
      final request = Request('GET', Uri.parse('https://example.com'));

      await client.send(request);

      expect(fakeClient.requests, hasLength(1));
      expect(fakeClient.requests.first.method, equals('GET'));
    });

    test('should close client and reset pipeline', () {
      final client = HttpClient();
      // Since close method is void, we just ensure no exception is thrown
      expect(() => client.close(), returnsNormally);
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

    test('Middleware.inlineQueue should process requests sequentially and pass context', () async {
      final results = <String>[];

      // Middleware с очередью, которая обрабатывает запросы последовательно
      final queueMiddleware = Middleware.inlineQueue((request, context, handler) async {
        var callNumber = context['callCounter'] as int;
        context['callCounter'] = ++callNumber;
        results.add('start_$callNumber');

        // Имитируем асинхронную работу
        await Future.delayed(Duration(milliseconds: 50));

        // Добавляем данные в контекст
        context['queue_result_$callNumber'] = 'processed_$callNumber';
        results.add('end_$callNumber');

        return handler(request, context);
      });

      // Обработчик, который проверяет контекст
      Future<StreamedResponse> handler(BaseRequest request, Map<String, Object?> context) {
        // Проверяем, что контекст содержит данные от middleware
        expect(context['queue_result_1'], 'processed_1');
        expect(context['queue_result_2'], 'processed_2');
        return Future.value(StreamedResponse(Stream.empty(), 200));
      }

      final pipeline = SendPipeline().addMiddleware(queueMiddleware).addMiddleware(queueMiddleware).addHandler(handler);

      // Создаем несколько параллельных запросов
      final futures = <Future>[
        pipeline(
          Request(HttpMethod.get, Uri.parse('https://example.com')),
          <String, Object>{
            'callCounter': 0,
          },
        ),
        pipeline(
          Request(HttpMethod.get, Uri.parse('https://example.com')),
          <String, Object>{
            'callCounter': 0,
          },
        ),
      ];

      await Future.wait(futures);

      expect(results, ['start_1', 'end_1', 'start_2', 'end_2']);
    });

    test('One middleware', () async {
      final middleware = Middleware.inline((request, context, handler) {
        var callCount = context['call'] as int;
        context['call'] = ++callCount;
        return handler(request, context);
      });

      Future<StreamedResponse> handler(BaseRequest request, Map<String, Object?> context) {
        return Future.value(StreamedResponse(Stream.empty(), 200));
      }

      final pipeline = SendPipeline().addMiddleware(middleware).addMiddleware(middleware).addHandler(handler);

      final futures = <Future>[
        pipeline(Request(HttpMethod.get, Uri.parse('https://example.com')), <String, Object>{'call': 0}),
        pipeline(Request(HttpMethod.get, Uri.parse('https://example.com')), <String, Object>{'call': 0}),
      ];

      await Future.wait(futures);
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
              (request, context, handler) {
                return handler(request, context);
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

                return handler(request, context);
              },
            ),
          )
          .addHandler((request, context) {
            expect(request.headers, anyOf(containsPair('call0', 'true'), containsPair('call1', 'true')));
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

    test('should apply middlewares in order', () async {
      final pipeline = SendPipeline();

      final middleware1 = Middleware.inline((r, c, handler) async {
        c['m1'] = true;
        return handler(r, c);
      });

      final middleware2 = Middleware.inline((r, c, handler) async {
        c['m2'] = true;
        return handler(r, c);
      });

      handler(r, c) async {
        expect(c['m1'], true);
        expect(c['m2'], true);
        return StreamedResponse(Stream.empty(), 200);
      }

      await pipeline.addMiddleware(middleware1).addMiddleware(middleware2).addHandler(handler)(
        Request(HttpMethod.get, Uri.parse('https://example.com')),
        {},
      );
    });
  });
}
