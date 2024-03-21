/*
* rest_client.dart
* RestClient.
* Dashkevich Andrey, 13 March 2024
*/

/// Rest client.
///
/// A simple lightweight wrapper around [http](https://pub.dev/packages/http).
///
///
/// ```dart
/// import 'dart:developer';
/// import 'package:rest_client/rest_client.dart';
///
/// final client = RestClient.client(RestConfig()); // Create client instance
/// final response = await client.get(Uri.https('example.example', 'api/echo')); // Create request and send, await [RCResponse]
/// log(response.toString()); // Print response
/// client.dispose(): // Dispose, closing connection.
/// ```
///
/// Package has simple utils library.
/// See [utils]({@macro utils}).
library rest_client;

import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:developer';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:http/http.dart';

import 'src/body.dart';
import 'src/exception.dart';
import 'src/http_methods.dart';
import 'src/internal/content_decoder/response_decode_strategy.dart';
import 'src/response.dart';
import 'utils.dart';

export 'package:http/http.dart'
    show BaseClient, BaseRequest, MultipartRequest, Request, StreamedRequest, StreamedResponse;

export 'src/exception.dart';
export 'src/http_methods.dart';
export 'src/response.dart';

part 'src/config.dart';
part 'src/internal/event_queue.dart';
part 'src/internal/http_request_task.dart';
part 'src/internal/interceptor.dart';
part 'src/internal/interceptor_mixin.dart';
part 'src/internal/request_methods_mixin.dart';
part 'src/internal/rest_client_impl.dart';
part 'src/internal/rest_methods_interface.dart';

/// {@template rest_client}
/// REST client
///
/// Simple REST client for easy use inside app project
/// Internal used HTTP dart library
/// {@endtemplate}
abstract base class RestClient implements _IRestMethods {
  RestClient(this.configuration);

  /// Create instance.
  factory RestClient.create(RestConfig configuration) => _HttpClient(configuration);

  /// Client configuration.
  final RestConfig configuration;

  /// Release resource and close client.
  void dispose();
}
