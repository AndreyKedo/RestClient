import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:developer';
import 'package:collection/collection.dart';
import 'package:http/http.dart';

import 'exception.dart';

part 'config.dart';
part 'event_queue.dart';
part 'http_request_task.dart';
part 'interceptor.dart';

/// {@template rest_client}
/// REST client
///
/// Simple REST client for easy use inside app project
/// Internal used HTTP dart library
/// {@endtemplate}
class RestClient extends BaseClient {
  RestClient([this.configuration = const ClientConfig()]);

  /// Client configuration.
  final ClientConfig configuration;

  late final _queue = SequentialTaskQueue(configuration.interceptors, debugLabel: 'Request Queue');

  late final Client _innerClient = configuration.clientFactory();

  /// Decodes [body] from JSON \ UTF8
  /// if status code >= 400 and <= 500 throw [InternalServerException], if 401 throw [UnauthorizedException]
  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    //Write configuration header inside request
    request.headers.addAll(configuration.headers);

    final response = await _queue.add(HttpRequestTask(_innerClient, configuration.interceptors, request));
    return resolveResponse(response);
  }

  /// Resolved response.
  ///
  /// You can override this method for change behavior.
  StreamedResponse resolveResponse(StreamedResponse response) {
    final StreamedResponse(statusCode: int code, reasonPhrase: String? reason) = response;
    if (code >= 400 && code <= 500) {
      if (code == 401) {
        throw UnauthorizedException(message: reason ?? 'Unauthenticated user');
      }
      if (code >= 500) {
        throw InternalServerException(statusCode: code, message: reason);
      }
    }
    return response;
  }

  @override
  void close() {
    _queue.close(force: true);
    _innerClient.close();
    super.close();
  }
}
