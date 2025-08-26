import 'dart:math';

import 'package:http_client/http_client.dart';
import 'package:http_client/src/event_queue.dart';
import 'package:test/test.dart';

// call: 1; mw - 1
// call: 1; mw - 2;  start
// call: 2; mw - 1
// call: 1; mw - 2;  completed
// call: 1; mw - 3
// call: 2; mw - 2;  start
// call: 2; mw - 2;  completed
// call: 2; mw - 3

void main() {
  test('Pipeline test', () async {
    final queue = WorkQueue.main;
    var callDepth = 0;
    final handler = SendPipeline()
        .addMiddleware(
          Middleware.inline(
            (request, context, handler) {
              print('call: ${context['call']}; mw - 1');
              return handler(request, context);
            },
          ),
        )
        .addMiddleware(
          Middleware.inline(
            (request, context, handler) => queue.schedule(() async {
              final callNumber = callDepth++;
              context['2_${callNumber + 1}'] = 'start';
              print('call: ${callNumber + 1}; mw - 2;  start');
              if (callNumber == 0) {
                await Future.delayed(Duration(milliseconds: Random().nextInt(300) + 200));
              }
              print('call: ${callNumber + 1}; mw - 2;  completed');
              return handler(request, context);
            }),
          ),
        )
        .addMiddleware(
          Middleware.inline(
            (request, context, handler) async {
              print('call: ${context['call']}; mw - 3');
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
          print(request.headers);
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

  // test('SendPipeline middleware execution order', () async {
  //   final pipeline = SendPipeline();

  //   middleware1(Handler h) => (r, c) async {
  //         c['m1'] = true;
  //         return h(r, c);
  //       };

  //   middleware2(Handler h) => (r, c) async {
  //         c['m2'] = true;
  //         return h(r, c);
  //       };

  //   handler(r, c) async {
  //     expect(c['m1'], true);
  //     expect(c['m2'], true);
  //     return StreamedResponse(Stream.empty(), 200);
  //   }

  //   await pipeline.addMiddleware(middleware1).addMiddleware(middleware2).addHandler(handler)(
  //     Request(HttpMethod.get, Uri.parse('https://example.com')),
  //     {},
  //   );
  // });
}
