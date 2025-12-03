import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';

/// Callback function type for creating task collections
typedef CollectionFactoryCallback = QueueProxy<TaskBase<Object?>> Function();

/// Callback function type for runnable tasks that return a Future
typedef RunnableCallback<T> = Future<T> Function();

/// Represents a scope for tasks within a specific zone.
/// Each task scope maintains its own queue of nested tasks.
@internal
class TaskScope {
  TaskScope({
    required this.task,
    required this.depth,
    required QueueProxy<TaskBase<Object?>> innerQueue,
  }) : _innerQueue = innerQueue;

  /// The main task associated with this scope
  final TaskBase<Object?> task;

  /// Queue for nested tasks within this scope
  final QueueProxy<TaskBase<Object?>> _innerQueue;

  final int depth;

  bool _isBusy = false;

  bool get hasAwaitedTask => _isBusy;

  /// Returns true if the inner queue is empty
  bool get isEmpty => _innerQueue.isEmpty;

  /// Adds a task to the inner queue
  void add(TaskBase<Object?> task) {
    _innerQueue.add(task);
  }

  TaskBase<Object?>? get first => _innerQueue.first;

  /// Removes and returns the first task from the inner queue
  TaskBase<Object?> removeFirst() => _innerQueue.removeFirst();

  void lock() => _isBusy = true;

  void unLock() => _isBusy = false;
}

/// Base class for work queues that manage asynchronous task execution
/// with support for nested task scheduling without deadlocks.
abstract class WorkQueueBase {
  /// Create WorkQueueBase
  WorkQueueBase(this.queueFactory) : _queue = queueFactory();

  /// Main queue for tasks
  final QueueProxy<TaskBase<Object?>> _queue;

  /// Factory for creating new task queues
  final CollectionFactoryCallback queueFactory;

  /// Flag indicating if the queue is currently processing tasks
  bool _isProcessing = false;

  /// Root zone reference for returning from nested zones
  Zone _root = Zone.current;

  /// Returns true if the queue is currently processing tasks
  bool get isProcessing => _isProcessing;

  /// Returns the number of pending tasks in the main queue
  int get tasksPending => _queue.length;

  /// Retrieves the parent task scope from the current or specified zone
  TaskScope? _getParentScope() {
    final context = Zone.current;
    return context[context.parent ?? _root] as TaskScope?;
  }

  /// Schedules a new task for execution
  Future<R> schedule<R>(RunnableCallback<R> callback);

  /// Enqueues a task either in the current scope or main queue
  @protected
  @visibleForTesting
  Future<R> enqueue<R>(TaskBase<R> task) {
    final parentScope = _getParentScope();
    // If we're inside a task scope, add to the nested queue
    if (parentScope != null) {
      parentScope.add(task);
      processNextTask();
      return task.future;
    } else {
      // Otherwise, add to the main queue
      _queue.add(task);
      scheduleTask();
      return task.future;
    }
  }

  /// Starts processing tasks if not already processing
  @protected
  @visibleForTesting
  void scheduleTask() {
    if (_isProcessing) return;
    _root = Zone.current;
    _isProcessing = true;
    processNextTask();
  }

  /// Processes the next task in the queue or current scope
  @protected
  void processNextTask() {
    final currentZone = Zone.current;
    final zoneScope = _getParentScope();

    // If we have a scope with tasks, process them first
    if (zoneScope != null && !zoneScope.isEmpty) {
      if (zoneScope.hasAwaitedTask) return;

      final task = zoneScope.removeFirst();
      final scope = TaskScope(task: task, depth: zoneScope.depth + 1, innerQueue: queueFactory());
      currentZone.fork(zoneValues: {currentZone: scope}).run(() {
        zoneScope.lock();
        task.execute().whenComplete(() async {
          // Critical: Use a zero-duration delay to yield to the event loop
          // This ensures all nested tasks complete before continuing
          await Future.delayed(Duration.zero);
          zoneScope.unLock();

          processNextTask();
        });
      });
      return;
    }

    // If scope is empty, return to root zone
    if (zoneScope != null) {
      currentZone.parent?.run(processNextTask);
      return;
    }

    // If no scope and main queue is empty, stop processing
    if (_queue.isEmpty) {
      _isProcessing = false;
      return;
    }

    // Get task from main queue and create a new scope for it
    final task = _queue.removeFirst();
    final values = {currentZone: TaskScope(task: task, depth: 0, innerQueue: queueFactory())};
    currentZone.fork(zoneValues: values).run(() {
      task.execute().whenComplete(() async {
        // Critical: Use a zero-duration delay to yield to the event loop
        // This ensures all nested tasks complete before continuing
        await Future.delayed(Duration.zero);
        (Zone.current.parent ?? _root).run(processNextTask);
      });
    });
  }

  /// Clears all pending tasks and waits for current tasks to complete
  Future<void> clear() async {
    _queue.clear();
    await Future.delayed(Duration.zero);
  }
}

/// Base class for all tasks that can be executed by a WorkQueue
abstract class TaskBase<T> {
  /// Create task base.
  TaskBase({required this.function});

  /// The function to execute when this task runs
  final RunnableCallback<T> function;

  /// Completer for tracking task completion
  final _completer = Completer<T>();

  /// Future that completes when this task finishes execution
  Future<T> get future => _completer.future;

  /// Executes the task function and handles completion
  Future<void> execute() async {
    if (_completer.isCompleted) return;
    try {
      final result = await function();
      await Future.delayed(Duration.zero);
      _completeWithResult(result);
    } catch (exception, stackTrace) {
      _completeWithError(exception, stackTrace);
    }
  }

  /// Completes the task with an error result
  void _completeWithError(Object exception, StackTrace stackTrace) {
    if (!_completer.isCompleted) {
      _completer.completeError(exception, stackTrace);
    }
  }

  /// Completes the task with a successful result
  void _completeWithResult(T result) {
    if (!_completer.isCompleted) {
      _completer.complete(result);
    }
  }
}

/// Concrete implementation of a work queue
class WorkQueue extends WorkQueueBase {
  WorkQueue() : super(_SequentialWorkQueue.new);

  @override
  Future<T> schedule<T>(RunnableCallback<T> callback) {
    return enqueue<T>(WorkQueueTask(function: callback));
  }
}

/// Concrete implementation of a task for WorkQueue
class WorkQueueTask<T> extends TaskBase<T> {
  WorkQueueTask({required super.function});
}

/// Interface for task queue implementations
abstract class QueueProxy<T> {
  /// Create proxy.
  const QueueProxy();

  /// Number of tasks in the queue
  int get length;

  /// Returns true if the queue is empty
  bool get isEmpty;

  /// Adds a task to the queue
  void add(T task);

  /// Removes and returns the first task from the queue
  T removeFirst();

  /// Removes and returns the last task from the queue
  T removeLast();

  /// Removes all tasks from the queue
  void clear();

  /// The first element of queue.
  T? get first;
}

/// Sequential implementation of a task queue
class _SequentialWorkQueue<T extends TaskBase> extends QueueProxy<T> {
  final _queue = Queue<T>();

  @override
  int get length => _queue.length;

  @override
  bool get isEmpty => _queue.isEmpty;

  @override
  void add(T task) => _queue.add(task);

  @override
  void clear() => _queue.clear();

  @override
  T removeFirst() => _queue.removeFirst();

  @override
  T removeLast() => _queue.removeLast();

  @override
  T? get first => _queue.firstOrNull;
}
