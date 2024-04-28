part of 'rest_client_impl.dart';

/// Task handler.
///
/// Simple task handler.
abstract interface class QueueTaskHandler {
  /// Check task execution state.
  bool get isCompleted;

  /// Reject task.
  ///
  /// Ended future with [error] and [stackTrace].
  void reject(Object error, [StackTrace? stackTrace]);
}

/// {@template sequential_task_queue}
/// An event queue is a queue of [EventCallback]s that are executed in order.
/// {@endtemplate}
/// {@nodoc}
class SequentialTaskQueue implements Sink<EventQueueTask> {
  /// {@macro sequential_task_queue}
  SequentialTaskQueue(this.interceptors, {String debugLabel = 'SequentialTaskQueue'}) : _debugLabel = debugLabel;

  final Queue<EventQueueTask> _queue = Queue<EventQueueTask>();
  final String _debugLabel;

  final List<SendInterceptor> interceptors;

  Future<void>? _processing;
  bool _closed = false;

  @override
  Future<StreamedResponse> add(final EventQueueTask event) {
    if (_closed) {
      throw StateError('EventQueue is closed');
    }
    for (var element in _queue) {
      if (element == event) {
        return element.future;
      }
    }
    _queue.add(event);
    unawaited(_openExecuteWindow());
    developer.Timeline.instantSync('$_debugLabel:add');
    return event.future;
  }

  @override
  Future<void> close({bool force = false}) async {
    _closed = true;
    if (force) {
      for (final task in _queue) {
        task.reject(
          StateError('StateQueue is closed'),
          StackTrace.current,
        );
      }
      _queue.clear();
    } else {
      await _processing;
    }
  }

  Future<void> _openExecuteWindow() {
    final processing = _processing;
    if (processing != null) {
      return processing;
    }
    final flow = developer.Flow.begin();
    developer.Timeline.instantSync('$_debugLabel:begin execute');
    final stopwatch = Stopwatch();
    return _processing = Future.doWhile(() async {
      if (_queue.isEmpty) {
        _processing = null;
        developer.Timeline.instantSync('$_debugLabel:end execute');
        developer.Flow.end(flow.id);
        stopwatch.stop();
        return false;
      }

      if (stopwatch.elapsedMilliseconds >= 13.0) {
        // ignore: inference_failure_on_instance_creation
        await Future.delayed(Duration.zero);
        stopwatch.reset();
      }

      final event = _queue.removeFirst();

      try {
        for (var interceptor in interceptors) {
          await interceptor.onRequest(event.request, event);
        }
      } catch (error, stackTrace) {
        event.reject(error, stackTrace);
        return true;
      }

      unawaited(developer.Timeline.timeSync(
        '$_debugLabel:request execute',
        event.call, //call and measure time
        flow: developer.Flow.step(flow.id),
      ));
      return true;
    });
  }
}

/// Queue task.
/// {@nodoc}
abstract base class EventQueueTask implements QueueTaskHandler {
  EventQueueTask(this.request) : _completer = Completer<StreamedResponse>();

  final BaseRequest request;
  final Completer<StreamedResponse> _completer;

  @override
  bool get isCompleted => _completer.isCompleted;

  Future<StreamedResponse> get future => _completer.future;

  /// Task computation.
  Future<StreamedResponse> execute(BaseRequest request);

  Future<void> call() =>
      runZonedGuarded<Future<void>>(() async {
        if (_completer.isCompleted) return;
        final result = await execute(request);
        if (_completer.isCompleted) return;
        _completer.complete(result);
      }, reject) ??
      Future.value();

  @override
  void reject(Object error, [StackTrace? stackTrace]) {
    if (_completer.isCompleted) return;

    _completer.completeError(error, stackTrace);
  }

  static const _equality = DeepCollectionEquality();

  @override
  int get hashCode => request.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other) || (other is SequentialTaskQueue && runtimeType == other.runtimeType)) {
      if (other
          case BaseRequest(
            method: final method,
            headers: final headers,
            contentLength: final contentLength,
            url: final url
          )) {
        return request.method == method &&
            _equality.equals(request.headers, headers) &&
            request.contentLength == contentLength &&
            request.url == url;
      }
    }
    return false;
  }
}
