import 'package:http_middleware/src/work_queue.dart';
import 'package:test/test.dart';

const kDefaultDelay = Duration(milliseconds: 100);

void main() {
  group('WorkQueue', () {
    late WorkQueue queue;
    late List<String> executionLog;

    setUp(() {
      queue = WorkQueue();
      executionLog = [];
    });

    tearDown(() async {
      await queue.clear();
    });

    test('should execute tasks in order', () async {
      // Arrange
      final task1 = queue.schedule(() async {
        await Future.delayed(kDefaultDelay);
        executionLog.add('Task 1');
        return 1;
      });

      final task2 = queue.schedule(() async {
        await Future.delayed(kDefaultDelay);
        executionLog.add('Task 2');
        return 2;
      });

      // Act
      final results = await Future.wait([task1, task2]);

      // Assert
      expect(results, equals([1, 2]));
      expect(executionLog, equals(['Task 1', 'Task 2']));
    });

    test('should handle nested tasks correctly', () async {
      // Arrange & Act
      final result = await queue.schedule(() async {
        executionLog.add('Task 1 start');

        final nestedResult = await queue.schedule(() async {
          await Future.delayed(kDefaultDelay);
          executionLog.add('Nested task');
          return 'nested';
        });

        executionLog.add('Task 1 end');
        return 'main-$nestedResult';
      });

      // Assert
      expect(result, equals('main-nested'));
      expect(executionLog, equals(['Task 1 start', 'Nested task', 'Task 1 end']));
    });

    test('should handle multiple nested tasks', () async {
      // Arrange & Act
      final result = await queue.schedule(() async {
        executionLog.add('Task 1 start');

        final result1 = await queue.schedule(() async {
          await Future.delayed(kDefaultDelay);
          executionLog.add('Nested 1');
          return 1;
        });

        final result2 = await queue.schedule(() async {
          await Future.delayed(kDefaultDelay);
          executionLog.add('Nested 2');
          return 2;
        });

        executionLog.add('Task 1 end');
        await Future.delayed(kDefaultDelay);
        return result1 + result2;
      });

      // Assert
      expect(result, equals(3));
      expect(executionLog, equals(['Task 1 start', 'Nested 1', 'Nested 2', 'Task 1 end']));
    });

    test('should process tasks from different scopes correctly', () async {
      // Arrange
      final task1 = queue.schedule(() async {
        executionLog.add('Task 1 start');

        await queue.schedule(() async {
          await Future.delayed(kDefaultDelay);
          executionLog.add('Nested in Task 1');
        });

        executionLog.add('Task 1 end');
        await Future.delayed(kDefaultDelay);
        return 1;
      });

      final task2 = queue.schedule(() async {
        executionLog.add('Task 2 start');

        await queue.schedule(() async {
          await Future.delayed(kDefaultDelay);
          executionLog.add('Nested in Task 2');
        });

        executionLog.add('Task 2 end');
        await Future.delayed(kDefaultDelay);
        return 2;
      });

      // Act
      final results = await Future.wait([task1, task2]);

      // Assert
      expect(results, equals([1, 2]));
      expect(
        executionLog,
        equals(['Task 1 start', 'Nested in Task 1', 'Task 1 end', 'Task 2 start', 'Nested in Task 2', 'Task 2 end']),
      );
    });

    test('should handle errors in tasks', () async {
      // Arrange
      final task1 = queue.schedule(() async {
        await Future.delayed(kDefaultDelay);
        executionLog.add('Task 1');
        return 1;
      });

      final task2 = queue.schedule(() async {
        await Future.delayed(kDefaultDelay);
        executionLog.add('Task 2');
        throw Exception('Task failed');
      });

      final task3 = queue.schedule(() async {
        await Future.delayed(kDefaultDelay);
        executionLog.add('Task 3');
        return 3;
      });

      // Act & Assert
      expect(await task1, equals(1));
      expect(task2, throwsA(isA<Exception>()));
      expect(await task3, equals(3));

      // Task 3 should still execute even if Task 2 fails
      expect(executionLog, equals(['Task 1', 'Task 2', 'Task 3']));
    });

    test('should handle clear method correctly', () async {
      // Arrange
      final task1 = queue.schedule(() async {
        await Future.delayed(kDefaultDelay);
        executionLog.add('Task 1');
        return 1;
      });

      queue.schedule(() async {
        await Future.delayed(kDefaultDelay);
        executionLog.add('Task 2');
        return 2;
      });

      // Act
      await task1;
      await queue.clear();

      expect(executionLog, equals(['Task 1']));
      // Task 2 should be canceled by clear
      expect(executionLog, isNot(equals(['Task 2'])));

      // Schedule new tasks after clear
      final task3 = queue.schedule(() async {
        await Future.delayed(kDefaultDelay);
        executionLog.add('Task 3');
        return 3;
      });

      expect(await task3, equals(3));
      expect(executionLog, equals(['Task 1', 'Task 3']));
    });

    test('should return correct task count', () async {
      // Arrange
      expect(queue.tasksPending, equals(0));

      // Act
      final task1 = queue.schedule(() async {
        await Future.delayed(Duration.zero);
        return 1;
      });
      final task2 = queue.schedule(() async {
        await Future.delayed(Duration.zero);
        return 2;
      });

      // Assert
      await task1;
      expect(queue.tasksPending, equals(1));

      await task2;
      expect(queue.tasksPending, equals(0));
    });

    test('should handle complex nested scenarios', () async {
      // Arrange & Act
      final result = await queue.schedule(() async {
        executionLog.add('Level 1 start');

        final level2 = await queue.schedule(() async {
          executionLog.add('Level 2 start');

          final level3 = await queue.schedule(() async {
            await Future.delayed(kDefaultDelay);
            executionLog.add('Level 3');
            return 300;
          });

          executionLog.add('Level 2 end');
          await Future.delayed(kDefaultDelay);
          return level3 + 20;
        });

        executionLog.add('Level 1 end');
        await Future.delayed(kDefaultDelay);
        return level2 + 1;
      });

      // Assert
      expect(result, equals(321));
      expect(executionLog, equals(['Level 1 start', 'Level 2 start', 'Level 3', 'Level 2 end', 'Level 1 end']));
    });

    test('should process tasks after nested tasks complete', () async {
      // This test specifically verifies the fix for the execution order issue

      // Arrange
      final task1 = queue.schedule(() async {
        executionLog.add('Task 1 start');

        await queue.schedule(() async {
          await Future.delayed(kDefaultDelay);
          executionLog.add('Nested task');
        });

        await Future.delayed(kDefaultDelay);
        executionLog.add('Task 1 end');
      });

      final task2 = queue.schedule(() async {
        await Future.delayed(kDefaultDelay);
        executionLog.add('Task 2');
      });

      // Act
      await Future.wait([task1, task2]);

      // Assert - Task 1 should completely finish before Task 2 starts
      expect(executionLog, equals(['Task 1 start', 'Nested task', 'Task 1 end', 'Task 2']));
    });

    test('should handle delayed tasks correctly', () async {
      // Arrange
      final stopwatch = Stopwatch()..start();

      // Act
      await queue.schedule(() async {
        executionLog.add('Task with delay start');
        await Future.delayed(kDefaultDelay);
        executionLog.add('Task with delay end');
      });

      await queue.schedule(() async {
        executionLog.add('Immediate task');
      });

      // Assert
      expect(executionLog, equals(['Task with delay start', 'Task with delay end', 'Immediate task']));

      stopwatch.stop();
      // Should take at least 100ms due to the delay
      expect(stopwatch.elapsedMilliseconds >= 100, isTrue);
    });

    test('should handle isProcessing correctly', () async {
      // Initially not processing
      expect(queue.isProcessing, isFalse);

      // Schedule a task
      final task = queue.schedule(() async {
        await Future.delayed(kDefaultDelay);
        // Should be processing while task is running
        expect(queue.isProcessing, isTrue);
        return 1;
      });

      // Should be processing after scheduling
      expect(queue.isProcessing, isTrue);

      // Wait for task to complete
      await task;
      await Future.delayed(Duration.zero);

      // Should not be processing after all tasks complete
      expect(queue.isProcessing, isFalse);
    });
  });

  group('WorkQueue Edge Cases', () {
    late WorkQueue queue;
    late List<String> executionLog;

    setUp(() {
      queue = WorkQueue();
      executionLog = [];
    });

    tearDown(() async {
      await queue.clear();
    });

    test('should handle empty queue', () async {
      expect(queue.tasksPending, equals(0));
      expect(queue.isProcessing, isFalse);

      // Should not throw any exceptions
      await queue.clear();
    });

    test('should handle tasks that schedule multiple nested tasks', () async {
      final result = await queue.schedule(() async {
        executionLog.add('Parent start');

        final futures = <Future<int>>[];
        for (var i = 0; i < 3; i++) {
          futures.add(queue.schedule(() async {
            await Future.delayed(kDefaultDelay);
            executionLog.add('Child $i');
            return i;
          }));
        }

        final results = await Future.wait(futures);
        executionLog.add('Parent end');
        return results.reduce((a, b) => a + b);
      });

      expect(result, equals(3)); // 0 + 1 + 2 = 3
      expect(executionLog, equals(['Parent start', 'Child 0', 'Child 1', 'Child 2', 'Parent end']));
    });

    test('should handle tasks that return immediately', () async {
      final result = await queue.schedule(() {
        executionLog.add('Immediate return');
        return Future.value(42);
      });

      expect(result, equals(42));
      expect(executionLog, equals(['Immediate return']));
    });

    test('should handle mixed sync and async nested tasks', () async {
      await queue.schedule(() async {
        executionLog.add('Parent start');

        // Sync nested task
        await queue.schedule(() {
          executionLog.add('Sync nested');
          return Future.value(1);
        });

        // Async nested task
        await queue.schedule(() async {
          await Future.delayed(Duration(milliseconds: 100));
          executionLog.add('Async nested');
          return 2;
        });

        executionLog.add('Parent end');
      });

      expect(executionLog, equals(['Parent start', 'Sync nested', 'Async nested', 'Parent end']));
    });

    test('should handle rapid task scheduling', () async {
      // Schedule many tasks quickly
      final futures = <Future<int>>[];
      for (var i = 0; i < 10; i++) {
        futures.add(queue.schedule(() async => i));
      }

      final results = await Future.wait(futures);
      expect(results, equals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));
    });
  });
}
