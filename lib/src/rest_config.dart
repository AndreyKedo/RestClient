typedef LoggerPrint = void Function(LoggerMessage message);

final class RestConfig {
  /// {@macro http_client.dart}
  const RestConfig(this.host,
      {this.logger, this.headers = const {'Accept': 'application/json', 'Content-Type': 'application/json'}});

  final Uri host;
  final Map<String, String> headers;

  final LoggerPrint? logger;

  void log(LoggerMessage value) => logger?.call(value);
}

sealed class LoggerMessage {
  const LoggerMessage();
}

final class FineLogMessage extends LoggerMessage {
  final String message;
  const FineLogMessage(this.message);

  @override
  String toString() => message;
}

final class ErrorLogMessage extends LoggerMessage {
  final Object error;
  final StackTrace stackTrace;
  const ErrorLogMessage(this.error, this.stackTrace);
}

final class ResponseLogMessage extends LoggerMessage {
  final String method;
  final Uri url;
  final int statusCode;
  const ResponseLogMessage(this.method, this.url, this.statusCode);

  @override
  String toString() => '[$method][$url] Status: $statusCode';
}
