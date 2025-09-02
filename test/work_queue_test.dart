import 'package:http_client/src/event_queue.dart';
import 'package:test/test.dart';

void main() {
  group('WorkQueue', () {
    setUp(
      () {},
    );

    tearDown(
      () {},
    );

    test('inner scheduling', () async {
      final queue = WorkQueue();
      final result = <String>[];

      Future<void> test([int index = 0]) async {
        result.add('inner-start-$index');
        await Future.delayed(Duration(milliseconds: 50));
        result.add('inner-end-$index');
      }

      final task1 = queue.schedule(() async {
        result.add('task-start-1');
        final innerResult = await queue.schedule(() => test(1));
        result.add('task-end-1');
        return innerResult;
      });
      final task2 = queue.schedule(() async {
        result.add('task-start-2');
        final innerResult = await queue.schedule(() => test(2));
        result.add('task-end-2');
        return innerResult;
      });

      await Future.wait([task1, task2]);
      expect(result, [
        'task-start-1',
        'inner-start-1',
        'inner-end-1',
        'task-end-1',
        'task-start-2',
        'inner-start-2',
        'inner-end-2',
        'task-end-2',
      ]);
    });

    test('nested scheduling', () async {
      final queue = WorkQueue();
      final result = <String>[];

      Future<void> test([int index = 0]) async {
        result.add('inner-start-$index');
        await Future.delayed(Duration(milliseconds: 50));
        result.add('inner-end-$index');
      }

      final task1 = queue.schedule(() async {
        result.add('task-start-1');
        final innerResult = await queue.schedule(() => test(1));
        result.add('task-end-1');
        return innerResult;
      });
      final task2 = queue.schedule(() async {
        result.add('task-start-2');
        final innerResult = await queue.schedule(() async {
          await queue.schedule(() async {
            await queue.schedule(() async {
              await queue.schedule(() async {
                result.add('Sub inner task 2 - level 3');
              });
              result.add('Sub inner task 2 - level 2');
            });
            result.add('Sub inner task 2 - level 1');
          });
          await test(2);
        });
        result.add('task-end-2');
        return innerResult;
      });

      await Future.wait([task1, task2]);
      print(result);
    });
  });
}
